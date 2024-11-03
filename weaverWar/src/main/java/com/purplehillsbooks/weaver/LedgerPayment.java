package com.purplehillsbooks.weaver;

import com.purplehillsbooks.json.JSONObject;

public class LedgerPayment {

    public long payDate;
    public double payAmount;
    public String detail;
    
    
    public JSONObject generateJson() throws Exception {
        JSONObject jo = new JSONObject();
        jo.put("payDate", payDate);
        jo.put("year", Ledger.getYear(payDate));
        jo.put("month", Ledger.getMonth(payDate));
        jo.put("day", Ledger.getDay(payDate));
        jo.put("amount", payAmount);
        if (detail==null || detail.isEmpty()) {
            detail = "UNKNOWN DETAIL";
        }
        jo.put("detail", detail);
        return jo;
    }

}
