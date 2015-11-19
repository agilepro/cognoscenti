package org.socialbiz.cog.mail;

import org.workcast.json.JSONObject;
import org.workcast.json.JSONArray;

public class JSONWrapper {

    JSONObject kernel;

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
}
