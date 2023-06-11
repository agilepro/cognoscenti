package com.purplehillsbooks.weaver;

import java.io.File;
import java.util.List;
import com.purplehillsbooks.json.JSONObject;


/**
 * The ledge keeps track of the money used and spent on each site.
 * 
 * First is a list of agreed upon plans.  Usually a site will only have a single
 * plan, and that is valid from starting through to the current date.
 * But if the site ever changes plans, a new entry will be made with a set
 * of valid dates.  When calculating fees, the latest plan is used, but the old
 * ones are there for reference.
 * 
 * Then is a list of charges made.  this includes all the details necessary to 
 */
public class SiteUsers {

    JSONObject kernel;
    
    private SiteUsers(JSONObject jo) {
        kernel = jo;
    }
    

    public static SiteUsers readUsers(File folder) throws Exception {
        File usersFilePath = new File(folder, "users.json");
        JSONObject jo = JSONObject.readFileIfExists(usersFilePath);
        return new SiteUsers(jo);
    }
    public void writeUsers(File folder) throws Exception {
        File ledgerFilePath = new File(folder, "ledger.json");
        kernel.writeToFile(ledgerFilePath);
    }
    
    public List<String> getAllUserKeys() {
        return kernel.sortedKeySet();
    }
    public JSONObject getUser(String userKey) throws Exception {
        return kernel.requireJSONObject(userKey);
    }
    public JSONObject getJson() {
        return kernel;
    }
    
    
    public boolean isReadOnly(String userKey) throws Exception {
        JSONObject userInfo = kernel.requireJSONObject(userKey);
        return userInfo.optBoolean("readOnly", false);
    }
    public void setReadOnly(String userKey, boolean readOnly) throws Exception {
        JSONObject userInfo = kernel.requireJSONObject(userKey);
        userInfo.put("readOnly", readOnly);
    }
    
    
    public boolean hasProfile(String userKey) throws Exception {
        JSONObject userInfo = kernel.requireJSONObject(userKey);
        return userInfo.optBoolean("hasProfile", false);
    }
    public void setHasProfile(String userKey, boolean hasIt) throws Exception {
        JSONObject userInfo = kernel.requireJSONObject(userKey);
        userInfo.put("hasProfile", hasIt);
    }
    
    
    public String getName(String userKey) throws Exception {
        JSONObject userInfo = kernel.requireJSONObject(userKey);
        return userInfo.getString("name");
    }
    public void setName(String userKey, String userName) throws Exception {
        JSONObject userInfo = kernel.requireJSONObject(userKey);
        userInfo.put("name", userName);
    }
    
    
    public void updateUserMap(JSONObject delta) throws Exception {
        for (String userKey : delta.keySet()) {
            JSONObject userDelta = delta.getJSONObject(userKey);
            JSONObject userInfo = kernel.requireJSONObject(userKey);

            //if nothing is mentioned about readOnly then it will be false
            if (userDelta.has("readOnly")) {
                userInfo.put("readOnly", userDelta.getBoolean("readOnly"));
            }
            if (userDelta.has("name")) {
                userInfo.put("name", userDelta.getString("name"));
            }
        }
    }

}
