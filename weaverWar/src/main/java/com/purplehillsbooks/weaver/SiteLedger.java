package com.purplehillsbooks.weaver;

import java.io.File;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.TimeZone;

import com.fasterxml.jackson.databind.ObjectMapper;


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
public class SiteLedger {

    public static final String PLAN_TYPE_TRIAL          = "Trial";
    public static final String PLAN_TYPE_GRASS_ROOTS    = "GrassRoots";
    public static final String PLAN_TYPE_SMALL_BUSINESS = "SmallBusiness";
    public static final String PLAN_TYPE_BUSINESS       = "Business";
    public static final String PLAN_TYPE_UNLIMITED      = "Unlimited";
    
    private static final ObjectMapper mapper = new ObjectMapper();
        
    List<SiteLedgerPlan> plans = new ArrayList<>();
    List<SiteLedgerCharge> charges = new ArrayList<>();
    
    public static SiteLedger readLedger(File folder) throws Exception {
        File ledgerFilePath = new File(folder, "ledger.json");
        SiteLedger ledger = mapper.readValue(ledgerFilePath, SiteLedger.class);
        return ledger;
    }
    public void saveLedger(File folder) throws Exception {
        File ledgerFilePath = new File(folder, "ledger.json");
        mapper.writeValue(ledgerFilePath, this);
    }

    private SiteLedger() {
    }

    /**
     * This returns a TRIAL plan with the start date set 
     * to the first of the current month
     */
    private SiteLedgerPlan getDefaultPlan() throws Exception {
        SiteLedgerPlan defPlan = new SiteLedgerPlan();
        defPlan.planName = PLAN_TYPE_TRIAL;
        Calendar calendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        calendar.setTimeInMillis(System.currentTimeMillis());
        int year = calendar.get(Calendar.YEAR);
        int month = calendar.get(Calendar.MONTH);
        calendar.set(year, month, 1);
        defPlan.startDate = calendar.getTimeInMillis();
        return defPlan;
    }
    
    public static int getYear(long timestamp) {
        Calendar calendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        calendar.setTimeInMillis(timestamp);
        return calendar.get(Calendar.YEAR);        
    }
    public static int getMonth(long timestamp) {
        Calendar calendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        calendar.setTimeInMillis(timestamp);
        return calendar.get(Calendar.MONTH);        
    }
    public static long getFirstOfMonth(int year, int month) {
        Calendar calendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        calendar.set(year, month, 1);
        return calendar.getTimeInMillis();
    }
    
    
    private SiteLedgerPlan getPlanForMonth(long timestamp) throws Exception {
        SiteLedgerPlan latest;
        if (plans.size()==0) {
            latest = getDefaultPlan();
            plans.add(latest);
            return latest;
        }

        for (SiteLedgerPlan another : plans) {
            if (another.startDate <= timestamp) {
                if (another.endDate<=0 || another.endDate > timestamp) {
                    return another;
                }
            }
        }
        return null;
    }
    
    /**
     * find the charges for a given year and month.
     * Month is defined in the standard Java way 0 - 11
     */
    public SiteLedgerCharge getChargesOrNull(int year, int month) throws Exception {
        for (SiteLedgerCharge aCharge : charges) {
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
     * find the charges for a given year and month.
     * Month is defined in the standard Java way 0 - 11
     */
    public SiteLedgerCharge requiredCharges(int year, int month) throws Exception {
        SiteLedgerCharge charge = getChargesOrNull(year, month);
        if (charge == null) {
            charge = new SiteLedgerCharge();
            charge.year = year;
            charge.month = month;
            charges.add(charge);
        }
        return charge;
    }
    
    public static void calculateChargesAllSites(Cognoscenti cog) throws Exception {
        Calendar calendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        calendar.setTimeInMillis(System.currentTimeMillis());
        int year = calendar.get(Calendar.YEAR);
        int month = calendar.get(Calendar.MONTH);
        
        for (NGPageIndex ngpi : cog.getAllSites()) {
            NGBook site = ngpi.getSite();
            WorkspaceStats stats = site.recalculateStats(cog);
            File sitefolder = site.getFilePath().getParentFile();
            SiteLedger ledger = readLedger(sitefolder);
            SiteLedgerCharge chargeMonth = ledger.requiredCharges(year, month);
            SiteLedgerPlan plan = null; //ledger.getCurrentPlan();
            double chargeAmt = 10.0;
            
            if (PLAN_TYPE_TRIAL.contentEquals(plan.planName)) {
                chargeAmt = 0;
            }
            else if (PLAN_TYPE_GRASS_ROOTS.contentEquals(plan.planName)) {
                chargeAmt = 10;
            }
            else if (PLAN_TYPE_SMALL_BUSINESS.contentEquals(plan.planName)) {
                chargeAmt = 20;
            }
            else if (PLAN_TYPE_BUSINESS.contentEquals(plan.planName)) {
                chargeAmt = 40;
            }
            else if (PLAN_TYPE_UNLIMITED.contentEquals(plan.planName)) {
                chargeAmt = 10;
            }
            chargeMonth.amount =  chargeAmt;
            SiteUsers siteUser = site.getUserMap();
            
        }
    }
}
