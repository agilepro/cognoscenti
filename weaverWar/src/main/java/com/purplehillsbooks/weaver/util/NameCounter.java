package com.purplehillsbooks.weaver.util;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.List;

import com.purplehillsbooks.json.JSONObject;

@SuppressWarnings("serial")
public class NameCounter extends Hashtable<String,Integer>
{

    public
    NameCounter() {
        super();
    }


    public List<String> getSortedKeys()
        throws Exception
    {
        try {
            ArrayList<String> sortedKeys = new ArrayList<String>();
            Enumeration<String> unsorted = keys();
            while (unsorted.hasMoreElements()) {
                sortedKeys.add(unsorted.nextElement());
            }
            Collections.sort(sortedKeys);
            return sortedKeys;
        }
        catch (Exception e) {
            throw new Exception("Failure creating a sorted Enumeration object", e);
        }
    }



    public void decrement(String key) {
        if (containsKey(key)) {
            Integer i = get(key);
            if (i == null) {
                throw new RuntimeException("Strange, map should contain an element for (" + key
                        + ") but got a null back.");
            }
            int ival = i.intValue();
            if (ival <= 1) {
                remove(key);
            }
            else {
                put(key, new Integer(ival - 1));
            }
        }
    }

    public void increment(String key) {
        if (containsKey(key)) {
            Integer i = get(key);
            if (i == null) {
                throw new RuntimeException("Strange, map should contain an element for (" + key
                        + ") but got a null back.");
            }
            put(key, new Integer(i.intValue() + 1));
        }
        else {
            put(key, new Integer(1));
        }
    }
    
    public void modifyCount(String key, int delta) {
        if (containsKey(key)) {
            Integer i = get(key);
            put(key, new Integer(i.intValue() + delta));
        }
        else {
            put(key, new Integer(delta));
        }
    }
    
    public int getCount(String key) {
        Integer val = get(key);
        if (val==null) {
            return 0;
        }
        return val.intValue();
    }
    
    public void addAllCounts(NameCounter other) {
        for (String key : other.keySet()) {
            int val = other.getCount(key);
            modifyCount(key, val);
        }
    }
    
    public JSONObject getJSON() throws Exception {
        JSONObject jo = new JSONObject();
        for (String key : keySet()) {
            jo.put(key, getCount(key));
        }
        return jo;
    }
    
    /**
     * This has the effect of adding the statistics from the JSONObject
     * into the current object.  If this is the first time it is called
     * then the resulting statistics will be equal to the JSONObject, 
     * however if you call it a second time it will be double values
     * and if called on a non-clean object it will be the sum of the
     * earlier values with the new values.
     */
    public void fromJSON(JSONObject jo) throws Exception {
        for (String key : jo.keySet()) {
            int val = jo.getInt(key);
            modifyCount(key, val);
        }
    }

}
