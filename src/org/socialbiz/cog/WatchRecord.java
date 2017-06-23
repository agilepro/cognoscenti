package org.socialbiz.cog;

import org.workcast.json.JSONObject;

public class WatchRecord {
    
    public String pageKey;
    public long   lastSeen;
    
    public WatchRecord(String key, long seen) {
        pageKey = key;
        lastSeen = seen;
    }

    public WatchRecord(JSONObject input) throws Exception {
        pageKey = input.getString("key");
        lastSeen = input.getLong("lastSeen");
    }

    public JSONObject getJSON() throws Exception {
        JSONObject watchRec = new JSONObject();
        watchRec.put("key",pageKey);
        watchRec.put("lastSeen",lastSeen);
        return watchRec;
    }
    
}
