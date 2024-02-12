package com.purplehillsbooks.weaver.util;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Hashtable;
import java.util.List;
import java.util.Set;

public class StringCounter {

    public Hashtable<String,Integer> guts;

    public StringCounter() {
        guts = new Hashtable<String,Integer>();
    }

    public int increment(String sVal) {
        Integer iVal = guts.get(sVal);
        if (iVal==null) {
            iVal = Integer.valueOf(1);
        }
        else {
            iVal = Integer.valueOf(iVal.intValue()+1);
        }
        guts.put(sVal, iVal);
        return iVal.intValue();
    }

    public int getCount(String sVal) {
        Integer iVal = guts.get(sVal);
        if (iVal==null) {
            return 0;
        }
        return iVal.intValue();
    }
    public int setCount(String sVal, int count) {
        return guts.put(sVal, Integer.valueOf(count));
    }

    public Set<String> keySet() {
        return guts.keySet();
    }
    public List<String> sortedKeyList() {
        List<String> res = new ArrayList<String>();
        for (String key : guts.keySet() ) {
            res.add(key);
        }
        Collections.sort(res);
        return res;
    }

}
