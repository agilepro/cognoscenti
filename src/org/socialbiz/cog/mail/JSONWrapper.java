package org.socialbiz.cog.mail;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;

/**
 * This is a base class for other JSONObject wrapper classes, that is 
 * a Java class that stores all its information as JSON objects.
 * 
 * It provides a way to 'create on demand' an array, testing for whether
 * the array exists, and creating it if not.
 *
 */
public class JSONWrapper {

    protected JSONObject kernel;

    public JSONWrapper(JSONObject _kernel) {
        kernel = _kernel;
    }

    public JSONArray getRequiredArray(String key) throws Exception {
        if (kernel.has(key)) {
            return kernel.getJSONArray(key);
        }
        else {
            JSONArray t = new JSONArray();
            kernel.put(key, t);
            return t;
        }
    }
    
    /**
     * If the incoming object has a value for the ket, the value will 
     * be transferred and stored.   If not value then the original 
     * value will remain unchanged.
     * 
     * @return true if the incoming object had a value to set
     * @param jo is the new object with values to be stored
     */
    protected boolean copyStringToKernel(JSONObject jo, String key) throws Exception {
        if (jo.has(key)) {
            kernel.put(key, jo.getString(key));
            return true;
        }
        return false;
    }
    protected boolean copyBooleanToKernel(JSONObject jo, String key) throws Exception {
        if (jo.has(key)) {
            kernel.put(key, jo.getBoolean(key));
            return true;
        }
        return false;
    }
    protected boolean copyArrayToKernel(JSONObject jo, String key) throws Exception {
        if (jo.has(key)) {
            kernel.put(key, jo.getJSONArray(key));
            return true;
        }
        return false;
    }
    protected boolean copyIntToKernel(JSONObject jo, String key) throws Exception {
        if (jo.has(key)) {
            kernel.put(key, jo.getInt(key));
            return true;
        }
        return false;
    }
    protected boolean copyLongToKernel(JSONObject jo, String key) throws Exception {
        if (jo.has(key)) {
            kernel.put(key, jo.getLong(key));
            return true;
        }
        return false;
    }

    protected void extractString(JSONObject jo, String key) throws Exception {
        if (kernel.has(key)) {
            jo.put(key, kernel.getString(key));
        }
    }
    protected void extractBoolean(JSONObject jo, String key) throws Exception {
        if (kernel.has(key)) {
            jo.put(key, kernel.getBoolean(key));
        }
    }
    protected void extractArray(JSONObject jo, String key) throws Exception {
        if (kernel.has(key)) {
            jo.put(key, kernel.getJSONArray(key));
        }
    }
    protected void extractInt(JSONObject jo, String key) throws Exception {
        if (kernel.has(key)) {
            jo.put(key, kernel.getInt(key));
        }
    }
    protected void extractLong(JSONObject jo, String key) throws Exception {
        if (kernel.has(key)) {
            jo.put(key, kernel.getLong(key));
        }
    }

    public JSONObject getJSON() {
        return kernel;
    }
    
    

}
