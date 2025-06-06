package com.purplehillsbooks.weaver;

import java.io.File;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.TimeZone;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.weaver.exception.WeaverException;


/**
 * The ledge keeps track of the money used and spent on each site.
 * 
 * First is a list of agreed upon plans.  Usually a site will only have a single
 * plan, and that is valid from starting through to the current date.
 * But if the site ever changes plans, a new entry will be made with a set
 * of valid dates.  When calculating fees, the latest plan is used, but the old
 * ones are there for reference.
 * 
 * Then is a list of charges made.  this includes all the details necessary to 
 */
public class Ledger {

    public static final String PLAN_TYPE_TRIAL          = "Trial";
    public static final String PLAN_TYPE_GRASS_ROOTS    = "GrassRoots";
    public static final String PLAN_TYPE_SMALL_BUSINESS = "SmallBusiness";
    public static final String PLAN_TYPE_BUSINESS       = "Business";
    public static final String PLAN_TYPE_UNLIMITED      = "Unlimited";

    public static final int LAST_POSSIBLE_YEAR = getYear(System.currentTimeMillis()) + 1;
        
    public List<LedgerCharge> charges = new ArrayList<>();
    public List<LedgerPayment> payments = new ArrayList<>();
    
    public static Ledger readLedger(File folder) throws Exception {
        File ledgerFilePath = new File(folder, "ledger.json");
        return JsonUtil.loadOrCreateJsonFile(ledgerFilePath, Ledger.class);
    }
    public void saveLedger(File folder) throws Exception {
        File ledgerFilePath = new File(folder, "ledger.json");
        JsonUtil.saveJsonFile(ledgerFilePath, this);
    }

    private Ledger() {
    }
    
    public static int getYear(long timestamp) {
        Calendar calendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        calendar.setTimeInMillis(timestamp);
        return calendar.get(Calendar.YEAR);        
    }
    /**
     * Note that MONTH is 1-12 and NOT the Java standard
     */
    public static int getMonth(long timestamp) {
        Calendar calendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        calendar.setTimeInMillis(timestamp);
        return calendar.get(Calendar.MONTH)+1;        
    }
    public static int getDay(long timestamp) {
        Calendar calendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        calendar.setTimeInMillis(timestamp);
        return calendar.get(Calendar.DAY_OF_MONTH);        
    }
    /**
     * Note that MONTH is 1-12 and NOT the Java standard
     */
    public static long getTimestamp(int year, int month, int day) {
        Calendar calendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        calendar.clear();
        calendar.set(year, month-1, day, 0, 0, 0);
        if (calendar.get(Calendar.HOUR_OF_DAY) > 0) {
            throw new RuntimeException("The hour is set to: "+calendar.get(Calendar.HOUR_OF_DAY));
        }
        if (calendar.get(Calendar.MINUTE) > 0) {
            throw new RuntimeException("The minute is set to: "+calendar.get(Calendar.MINUTE));
        }
        if (calendar.get(Calendar.SECOND) > 0) {
            throw new RuntimeException("The second is set to: "+calendar.get(Calendar.SECOND));
        }
        if (calendar.get(Calendar.MILLISECOND) > 0) {
            throw new RuntimeException("The milliseconds is set to: "+calendar.get(Calendar.MILLISECOND));
        }
        return calendar.getTimeInMillis();
    }
    public static long getFirstOfMonth(long timestamp) {
        int year = getYear(timestamp);
        int month = getMonth(timestamp);
        return getTimestamp(year, month, 1);
    }
    public static long getBeginningOfDay(long timestamp) {
        int year = getYear(timestamp);
        int month = getMonth(timestamp);
        int day = getDay(timestamp);
        return getTimestamp(year, month, day);
    }
    public static long getNextMonth(long timestamp) {
        int year = getYear(timestamp);
        int month = getMonth(timestamp);
        if (month >= 12) {
            year++;
            month = 1;
        }
        else {
            month++;
        }
        return getTimestamp(year, month, 1);
    }
    
    public static List<Long> getAllMonthsInRange(long startDate, long endDate) throws Exception {
        if (startDate > endDate) {
            throw WeaverException.newBasic("end date must be after the start date");
        }
        long timestamp = getFirstOfMonth(startDate);
        List<Long> res = new ArrayList<>();
        int guard = 100;
        while (timestamp <= endDate) {
            res.add(timestamp);
            long nextMonth = getNextMonth(timestamp);
            if (timestamp >= nextMonth) {
                throw WeaverException.newBasic("getNextMonth(%s) returned %s", timestamp, nextMonth);
            }
            timestamp = nextMonth;
            if (guard-- < 0) {
                return res;
            }
        }
        return res;
    }
    
    private void sortAndCleanPlans() {
        Collections.sort(charges, new ChargeSorter());
        Collections.sort(payments, new PaymentSorter());    
    }


    

    /* 
     * sorts the SiteLedgerCharg in chrono order by year and month
     */
    private class ChargeSorter implements Comparator<LedgerCharge> {

        @Override
        public int compare(LedgerCharge arg0, LedgerCharge arg1) {
            if (arg0.year == arg1.year) {
                return (int) (arg0.month - arg1.month);
            }
            else {
                return (int) (arg0.year - arg1.year);
            }
        }
    }
    /* 
     * sorts the SiteLedgerPayment in chrono order by payment date
     */
    private class PaymentSorter implements Comparator<LedgerPayment> {

        @Override
        public int compare(LedgerPayment arg0, LedgerPayment arg1) {
            long difference = (arg0.payDate - arg1.payDate);
            if (difference < 0) {
                return -1;
            } 
            else {
                return 1;
            }
        }
    }
    
    private void removePayment(long timestamp) {
        timestamp = getBeginningOfDay(timestamp);
        List<LedgerPayment> newList = new ArrayList<>();
        for (LedgerPayment onePay : payments) {
            if (onePay.payDate != timestamp) {
                newList.add(onePay);
            }
        }
        payments = newList;
    }
    public void createPayment(long timestamp, double amount, String detail) throws Exception {
        if (detail== null || detail.isEmpty()) {
            throw WeaverException.newBasic("'detail' is missing.  Please always include detail with a payment");
        }
        timestamp = getBeginningOfDay(timestamp);
        if (amount == 0) {
            removePayment(timestamp);
            return;
        }
        LedgerPayment payRec = null;
        for (LedgerPayment onePay : payments) {
            if (onePay.payDate == timestamp) {
                payRec = onePay;
            }
        }
        if (payRec == null) {
            payRec = new LedgerPayment();
            payRec.payDate = timestamp;
            payments.add(payRec);
            sortAndCleanPlans();
        }
        payRec.payAmount = amount;
        payRec.detail = detail;
    }
    
    public List<LedgerPayment> getPaymentsInRange(long start, long end) {
        List<LedgerPayment> ret = new ArrayList<LedgerPayment>();
        for (LedgerPayment onePay : payments) {
            if (onePay.payDate >= start && onePay.payDate < end) {
                ret.add(onePay);
            }
        }
        return ret;
    }

    public double getBalance() throws Exception {
        double balance = 0;
        for (LedgerCharge oneCharge : charges) {
            balance += oneCharge.amount;
        }
        for (LedgerPayment onePayment : payments) {
            balance -= onePayment.payAmount;
        }
        return balance;
    }

    
    public JSONArray getInfoForAllMonths() throws Exception {
        JSONArray ja = new JSONArray();
        
        long today = System.currentTimeMillis();
        long startDate = today;

        // find the first charge to set beginning of range
        for (LedgerCharge charge : charges) {
            long chargeDate = charge.getTimestamp();
            if (chargeDate < startDate) {
                startDate = chargeDate;
            }
        }

        double balance = 0;
        int guard = 100;
        for( long monthBegin : getAllMonthsInRange(startDate, today)) {
            long followingMonth = getNextMonth(monthBegin);
            int year = getYear(monthBegin);
            int month = getMonth(monthBegin);
            JSONObject jo = new JSONObject();
            jo.put("firstOfMonth", monthBegin);
            jo.put("year",  year);
            jo.put("month",  month);
            
            LedgerCharge charge = getChargesOrNull(year, month);
            if (charge != null) {
                jo.put("chargeAmt", charge.amount);
                balance += charge.amount;
            }
            
            JSONArray pays = new JSONArray();
            for (LedgerPayment onePay : getPaymentsInRange(monthBegin, followingMonth)) {
                pays.put(onePay.generateJson());
                balance -= onePay.payAmount;
            }
            jo.put("payments", pays);
            jo.put("balance", balance);
            ja.put(jo);
            
            if (guard-- < 0) {
                return ja;
            }
        }
        return ja;
    }

    public void assertValid(int year, int month) throws Exception {
        if (year < 2020) {
            throw WeaverException.newBasic("No charges are allowed of years less than 2020, value %d not allowed", year);
        }
        if (year > LAST_POSSIBLE_YEAR) {
            throw WeaverException.newBasic("No charges are allowed of years greater than %d, value %d not allowed", LAST_POSSIBLE_YEAR, year);
        }
        if (month < 1 || month > 12) {
            throw WeaverException.newBasic("Month value (%d) not a valid month value (1 thru 12)", month);
        }        
    }

    /**
     * find the charges for a given year and month.
     * Month is defined in the standard Java way 0 - 11
     */
    public LedgerCharge getChargesOrNull(int year, int month) throws Exception {
        assertValid(year, month);
        for (LedgerCharge aCharge : charges) {
            if (year != aCharge.year) {
                continue;
            }
            if (month != aCharge.month) {
                continue;
            }
            return aCharge;
        }
        return null;
    }
    /**
     * find the charge for a given year and month.
     * Month is defined in the standard Java way 0 - 11
     */
    public LedgerCharge getOrCreateCharge(int year, int month) throws Exception {
        assertValid(year, month);
        LedgerCharge charge = getChargesOrNull(year, month);
        if (charge == null) {
            charge = new LedgerCharge();
            charge.year = year;
            charge.month = month;
            charges.add(charge);
            sortAndCleanPlans();
        }
        return charge;
    }
    /**
     * find the charge for a given year and month.
     * Month is defined in the standard Java way 0 - 11
     */
    public void removeCharge(int year, int month) throws Exception {
        assertValid(year, month);
        List<LedgerCharge> newList = new ArrayList<>();
        for (LedgerCharge aCharge : charges) {
            if (year != aCharge.year || month != aCharge.month) {
                newList.add(aCharge);
            }
        }
        charges = newList;
    }


    public void setChargeAmt(int year, int month, double thisCharge) throws Exception {
        assertValid(year, month);
        if (thisCharge == 0) {
            removeCharge(year, month);
        }
        else {
            LedgerCharge aCharge = getOrCreateCharge(year, month);
            aCharge.amount = thisCharge;
        }
    }    
    public double getChargeAmt(int year, int month, double thisCharge) throws Exception {
        assertValid(year, month);
        for (LedgerCharge aCharge : charges) {
            if (year != aCharge.year) {
                continue;
            }
            if (month != aCharge.month) {
                continue;
            }
            return aCharge.amount;
        }
        return 0;
    }    
    
    public static void calculateChargesAllSites(Cognoscenti cog) throws Exception {
        Calendar calendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        calendar.setTimeInMillis(System.currentTimeMillis());
        int year = calendar.get(Calendar.YEAR);
        int month = calendar.get(Calendar.MONTH);
        
        for (NGPageIndex ngpi : cog.getAllSites()) {
            NGBook site = ngpi.getSite();
            site.recalculateStats(cog);
            File sitefolder = site.getFilePath().getParentFile();
            Ledger ledger = readLedger(sitefolder);
            LedgerCharge chargeMonth = ledger.getOrCreateCharge(year, month);
            double chargeAmt = 10.0;

            chargeMonth.amount =  chargeAmt;
            // SiteUsers siteUser = site.getUserMap();
            
        }
    }
    
    
    public JSONObject generateJson() throws Exception {
        JSONObject jo = new JSONObject();
        JSONArray ja = new JSONArray();
        double balance = 0;

        ja = new JSONArray();
        for (LedgerCharge oneCharge : charges) {
            ja.put(oneCharge.generateJson());
            balance += oneCharge.amount;
        }
        jo.put("charges", ja);

        ja = new JSONArray();
        for (LedgerPayment onePayment : payments) {
            ja.put(onePayment.generateJson());
            balance -= onePayment.payAmount;
        }
        jo.put("payments", ja);

        // balance is calculated every time.
        jo.put("balance", balance);
        return jo;
    }

}
