package com.purplehillsbooks.weaver;

import java.io.File;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

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
    
    public File folder;

    private JSONObject kernel;
    
    private SiteUsers(JSONObject jo) {
        kernel = jo;
    }
    

    public static SiteUsers readUsers(File folder) throws Exception {
        File usersFilePath = new File(folder, "users.json");
        System.out.println("SITEUSERS: Reading: "+usersFilePath.getAbsolutePath());
        JSONObject jo = JSONObject.readFileIfExists(usersFilePath);
        SiteUsers su = new SiteUsers(jo);
        su.folder = folder;
        su.patchUpUserKeys();
        return su;
    }
    public void writeUsers(File folder) throws Exception {
        File ledgerFilePath = new File(folder, "users.json");
        System.out.println("USERMAP: updating file at "+ledgerFilePath.getAbsolutePath());
        kernel.writeToFile(ledgerFilePath);
    }
    
    /**
     * we used to allow users without a profile, and therefor without a key.
     * However, we want to move so that ALL users have a key, and therefor
     * we can hide their email address.  This method goes and creates profiles
     * for all the users so they have keys.
     */
    private void patchUpUserKeys() throws Exception {
        JSONObject newKernel = new JSONObject();
        for (String key : kernel.keySet()) {
            JSONObject record = kernel.getJSONObject(key);
            UserProfile user = UserManager.lookupUserByAnyId(key);
            if (user == null) {
                // if this file was moved from another server, the internal key might be different
                // so look up by email address if you can
                user = UserManager.lookupUserByAnyId(record.getString("email"));
            }
            if (user == null) {
                // user does not have a profile.  We don't create that here
                continue;
            }
            if (!key.equals(user.getKey())) {
                // this should disappear after all the sites are converted
                System.out.println("     moving site user entry from ("+key+") to ("+user.getKey()+")");
            }
            key = user.getKey();
            record.put("hasProfile", user.hasLoggedIn());
            record.put("info", user.getFullJSON());
            record.put("lastAccess", user.getLastLogin());
            newKernel.put(key, record);
        }
        kernel = newKernel;
    }
    
    public List<String> getAllUserKeys() {
        List<String> ret = new ArrayList<>();
        for (String id : kernel.sortedKeySet()) {
            ret.add(id);
        }
        return ret;
    }
    
    public Set<String> listAccessibleUserKeys() throws Exception {
        Set<String> newMap = new HashSet<String>();
        for (String userId : kernel.sortedKeySet()) {
            UserProfile uProf = UserManager.lookupUserByAnyId(userId);
            if (uProf==null) {
                // a user without a profile can not update
                continue;
            }
            if (!isUnpaid(uProf)) {
                newMap.add(uProf.getKey());
            }
        }
        return newMap;
    }
    
    
    public JSONObject getJson() throws Exception {
        return UtilityMethods.deepCopy(kernel);
    }
    
    public int countUpdateUsers() throws Exception {
        int count = 0;
        for (String key : kernel.keySet()) {
            JSONObject rec = kernel.getJSONObject(key);
            if ( rec.optBoolean("hasProfile") && !rec.optBoolean("readOnly")) {
                count++;
            }
        }
        return count;
    }
    public int countUnpaidUsers() throws Exception {
        int count = 0;
        for (String key : kernel.keySet()) {
            JSONObject rec = kernel.getJSONObject(key);
            if ( !rec.optBoolean("hasProfile") || rec.optBoolean("readOnly")) {
                count++;
            }
        }
        return count;
    }
    
    public boolean isUnpaid(UserProfile uProf) throws Exception {
        if (uProf == null || !uProf.hasLoggedIn()) {
            return true;
        }
        JSONObject userInfo = kernel.requireJSONObject(uProf.getKey());
        return userInfo.optBoolean("readOnly", false);
    }
    public void setUnpaid(UserProfile uProf, boolean unpaid) throws Exception {
        JSONObject userInfo = kernel.requireJSONObject(uProf.getKey());
        userInfo.put("readOnly", unpaid);
    }
    
    public void keepTheseUsers(List<UserProfile> allUsers) throws Exception {
        int beforeSize = kernel.length();
        JSONObject newKernel = new JSONObject();
        for (UserProfile uProf : allUsers) {
            JSONObject userData = kernel.requireJSONObject(uProf.getKey());
            
            userData.put("email", uProf.getPreferredEmail());
            userData.put("lastAccess", uProf.getLastLogin());
            userData.put("hasProfile",  true);
            if (!userData.has("name")) {
                userData.put("name", uProf.getName());
            }
            userData.put("info", uProf.getFullJSON());
            
            newKernel.put(uProf.getKey(), userData);
        }
        
        System.out.println("KEEP USERS RESULT: entries changed from "+beforeSize+" to "+newKernel.length());
        kernel = newKernel;
    }
    
    public void updateUserMap(JSONObject delta) throws Exception {
        
        for (String userKey : delta.keySet()) {
            JSONObject userDelta = delta.getJSONObject(userKey);
            
            // see if there is a better ID for this user, a key for instance, and if the 
            // user map info is under the old key, move it to the new place
            UserProfile uProf = UserManager.lookupUserByAnyId(userKey);
            if (uProf != null) {
                String alternate = uProf.getKey();
                if (!alternate.equals(userKey) && !kernel.has(alternate) && kernel.has(userKey)) {
                    kernel.put(alternate, kernel.getJSONObject(userKey));
                    kernel.remove(userKey);
                    userKey = alternate;
                }
            }
            
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
