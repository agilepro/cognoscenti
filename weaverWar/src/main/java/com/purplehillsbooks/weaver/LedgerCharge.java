package com.purplehillsbooks.weaver;

import com.purplehillsbooks.json.JSONObject;

public class LedgerCharge {

    public int month;
    public int year;
    public double amount;
    
    
    
    public JSONObject generateJson() throws Exception {
        JSONObject jo = new JSONObject();
        jo.put("year", year);
        jo.put("month", month);
        jo.put("amount", amount);
        return jo;
    }
}
