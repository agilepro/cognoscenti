package com.purplehillsbooks.weaver;

import java.io.File;
import java.io.PrintWriter;
import java.io.Writer;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import com.purplehillsbooks.json.JSONArray;
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
        JSONObject jo = JSONObject.readFileIfExists(usersFilePath);
        SiteUsers su = new SiteUsers(jo);
        su.folder = folder;
        System.out.println("Read File, now checking structure of SiteUsers: "+folder.getAbsolutePath());
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
        System.out.println("SITEUSERS: patched kernel BEFORE");
        showKernel(kernel);
        JSONObject newKernel = new JSONObject();
        for (String key : kernel.keySet()) {
            JSONObject record = kernel.getJSONObject(key);
            UserProfile user = UserManager.lookupUserByAnyId(key);
            if (user == null) {
                continue;
            }
            key = user.getKey();
            record.put("hasProfile", user.hasLoggedIn());
            record.put("info", user.getFullJSON());
            record.put("lastAccess", user.getLastLogin());
            newKernel.put(key, record);
        }
        kernel = newKernel;
        System.out.println("SITEUSERS: patched kernel AFTER");
        showKernel(kernel);
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
            if (!isReadOnly(uProf)) {
                newMap.add(uProf.getKey());
            }
        }
        return newMap;
    }
    
    
    public JSONObject getJson() throws Exception {
        //File usersFilePath = new File(folder, "users.json");
        //JSONObject jo = JSONObject.readFileIfExists(usersFilePath);
        System.out.println("SITEUSERS: requested getJson() "+folder.getAbsolutePath());
        showKernel(kernel);
        return UtilityMethods.deepCopy(kernel);
    }
    private void showKernel(JSONObject jo) throws Exception {
        Writer w = new PrintWriter(System.out);
        jo.write(w, 4, 2);
        w.flush();
        System.out.println("\n------------------------------------");
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
    public int countReadOnlyUsers() throws Exception {
        int count = 0;
        for (String key : kernel.keySet()) {
            JSONObject rec = kernel.getJSONObject(key);
            if ( !rec.optBoolean("hasProfile") || rec.optBoolean("readOnly")) {
                count++;
            }
        }
        return count;
    }
    
    public boolean isReadOnly(UserProfile uProf) throws Exception {
        //UserProfile uProf = UserManager.lookupUserByAnyId(userKey);
        if (uProf == null || !uProf.hasLoggedIn()) {
            return true;
        }
        JSONObject userInfo = kernel.requireJSONObject(uProf.getKey());
        return userInfo.optBoolean("readOnly", false);
    }
    public void setReadOnly(UserProfile uProf, boolean readOnly) throws Exception {
        JSONObject userInfo = kernel.requireJSONObject(uProf.getKey());
        userInfo.put("readOnly", readOnly);
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
