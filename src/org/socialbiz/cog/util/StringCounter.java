package org.socialbiz.cog.util;

import java.util.Hashtable;
import java.util.Set;

public class StringCounter {

    private Hashtable<String,Integer> guts;

    public StringCounter() {
        guts = new Hashtable<String,Integer>();
    }

    public void increment(String sVal) {
        Integer iVal = guts.get(sVal);
        if (iVal==null) {
            guts.put(sVal, new Integer(1));
        }
        else {
            guts.put(sVal, new Integer(iVal.intValue()+1));
        }
    }

    public int getCount(String sVal) {
        return guts.get(sVal).intValue();
    }

    public Set<String> keySet() {
        return guts.keySet();
    }

}
