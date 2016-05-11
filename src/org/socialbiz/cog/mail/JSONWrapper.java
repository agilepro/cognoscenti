package org.socialbiz.cog.mail;

import org.workcast.json.JSONObject;
import org.workcast.json.JSONArray;

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

    public JSONObject getJSON() {
        return kernel;
    }


}
