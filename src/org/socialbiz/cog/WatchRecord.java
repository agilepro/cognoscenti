package org.socialbiz.cog;

public class WatchRecord {
    
    public String pageKey;
    public long   lastSeen;
    
    public WatchRecord(String key, long seen) {
        pageKey = key;
        lastSeen = seen;
    }

}
