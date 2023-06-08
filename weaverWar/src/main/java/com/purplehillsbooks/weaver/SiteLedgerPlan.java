package com.purplehillsbooks.weaver;

import com.purplehillsbooks.json.JSONObject;

public class SiteLedgerPlan {

    public long startDate;
    public long endDate;
    public String planName;
    
    
    public JSONObject getJson() throws Exception {
        JSONObject jo = new JSONObject();
        jo.put("startDate", startDate);
        jo.put("endDate", endDate);
        jo.put("planName", planName);
        return jo;
    }

}
