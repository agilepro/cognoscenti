package com.purplehillsbooks.weaver;

import com.purplehillsbooks.json.JSONObject;

public class SiteLedgerCharge {

    int month;
    int year;
    public double amount;
    
    
    
    public JSONObject getJson() throws Exception {
        JSONObject jo = new JSONObject();
        jo.put("year", year);
        jo.put("month", month);
        jo.put("amount", amount);
        return jo;
    }
}
