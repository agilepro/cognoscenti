package com.purplehillsbooks.weaver.mail;

import com.purplehillsbooks.json.JSONObject;

/**
 * Hold the address of a recipient along with the REASON that the person
 * is receiving the email, so that we can generate a line of output that
 * has a link to Opt out such emailing in the future.
 *
 */
public class ContextualAddress extends JSONWrapper {

    public ContextualAddress(JSONObject _kernel) {
        super(_kernel);
    }

    public String getEmail() throws Exception {
        return kernel.getString("email");
    }
    public void setEmail(String val) throws Exception {
        kernel.put("email", val);
    }

    public String getUnsubscribe() throws Exception {
        return kernel.getString("Unsubscribe");
    }
    public void setUnsubscribe(String val) throws Exception {
        kernel.put("Unsubscribe", val);
    }


}
