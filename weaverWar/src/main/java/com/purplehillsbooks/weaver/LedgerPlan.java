package com.purplehillsbooks.weaver;

import com.purplehillsbooks.json.JSONObject;

public class LedgerPlan {

    public long startDate;
    public long endDate;
    public String planName;
    
    
    public JSONObject generateJson() throws Exception {
        JSONObject jo = new JSONObject();
        jo.put("startDate", startDate);
        jo.put("year", Ledger.getYear(startDate));
        jo.put("month", Ledger.getMonth(startDate));
        jo.put("endDate", endDate);
        jo.put("planName", planName);
        return jo;
    }

}
