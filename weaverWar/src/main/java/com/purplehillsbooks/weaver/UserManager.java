/*
 * Copyright 2013 Keith D Swenson
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Contributors Include: Shamim Quader, Sameer Pradhan, Kumar Raja, Jim Farris,
 * Sandia Yang, CY Chen, Rajiv Onat, Neal Wang, Dennis Tam, Shikha Srivastava,
 * Anamika Chaudhari, Ajay Kakkar, Rajeev Rastogi
 */

package com.purplehillsbooks.weaver;

import java.io.File;
import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;
import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.weaver.mail.OptOutAddr;
import com.purplehillsbooks.weaver.mail.OptOutSuperAdmin;

import org.w3c.dom.Document;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;

public class UserManager
{
    public static int loadCount = 0;
    public static int modCount = 0;
    public static int saveCount = 0;

    private static Hashtable<String, UserProfile> userHashByKey = new Hashtable<String, UserProfile>();
    private static List<UserProfile> allUsers = new ArrayList<UserProfile>();
    
    //these two together allow us to 'correct' old email addresses in the files
    private static Hashtable<String, String> anyIdToKeyMap = new Hashtable<String, String>();
    private static Hashtable<String, String> keyToEmailMap = new Hashtable<String, String>();

    private static boolean initialized = false;

    private static File     jsonFileName;

    //TODO: get rid of this static
    private static Cognoscenti cog;

    /**
    * Set all static values back to their initial states, so that
    * garbage collection can be done, and subsequently, the
    * class will be reinitialized.
    *
    * Note -- All of the methods that read or write these
    * variables should be synchronized because the XML DOM
    * is not entirely thread-safe.  This user list tends to be
    * accessed from many requests.  Also, this user list does
    * not tend to talk to any other classes or do anything
    * other than this list of users, so it is relatively safe.
    */
    public static synchronized void clearAllStaticVars() {
        userHashByKey = new Hashtable<String, UserProfile>();
        allUsers      = new ArrayList<UserProfile>();
        initialized   = false;
    }


    /**
     * Converting this from a pure static class to a singleton class
     * that is constructed and managed by the Cognoscenti class.
     * The members will be static for a while, but the goal is to
     * eliminate all static variables.
     */
    public UserManager(Cognoscenti _cog) {
        cog = _cog;
    }

    public static UserManager getStaticUserManager() {
        return cog.getUserManager();
    }

    public synchronized void loadUpUserProfilesInMemory(Cognoscenti cog) throws Exception {
        //check to see if this has already been loaded, if so, there is nothing to do
        if (initialized) {
            return;
        }

        File userFolder = cog.getConfig().getUserFolderOrFail();
        if (!userFolder.exists()) {
            throw WeaverException.newBasic("The user folder does not exist.  To protect against errors you need to create the folder: %s",
                userFolder.getAbsolutePath());
        }

        jsonFileName = new File(userFolder, "UserProfs.json");

        //clear out any left over evidence of an earlier initialization
        allUsers = new ArrayList<UserProfile>();

        //need to make sure all the same information is in the JSON file....
        readJSONFile();

        refreshHashtables();
        initialized = true;
    }


    private void readJSONFile() throws Exception  {

        JSONObject userFile;
        if (jsonFileName.exists() && jsonFileName.length()>0) {
            userFile = JSONObject.readFromFile(jsonFileName);
        }
        else {
            userFile = new JSONObject();
        }

        loadCount++;

        JSONArray users = userFile.requireJSONArray("users");

        Hashtable<String,UserProfile> keyProfMap = new Hashtable<String,UserProfile>();
        Hashtable<String,UserProfile> idProfMap = new Hashtable<String,UserProfile>();
        List<String> idsToRemove = new ArrayList<String>();
        List<UserProfile> readUsers = new ArrayList<UserProfile>();

        for (int i=0; i<users.length(); i++) {
            UserProfile up = new UserProfile(users.getJSONObject(i));
            String uid = up.getUniversalId();
            if (uid==null) {
                System.out.println("USER ELIMINATION: user ("+up.getKey()+") does not have any universal id");
                continue;
            }
            int atPos = uid.indexOf("@");
            if (atPos<0) {
                System.out.println("USER ELIMINATION: user ("+up.getKey()+") universal id is not email: "+uid);
                continue;
            }
            String key = up.getKey();
            UserProfile other = keyProfMap.get(key);
            if (other!=null) {
                System.out.println("USER MANAGER FOUND duplicate user key to DELETE: "+key+", "+up.getUniversalId());
                //this is a big problem.  Two records with the same KEY.  That can
                //only happen because of a bug.  Just drop this!

                //after transferring any additional global ids that are not already on
                //other objects.
                for (String oneId : up.getAllIds()) {
                    UserProfile other2 = idProfMap.get(oneId.toLowerCase());
                    if (other2==null) {
                        System.out.println("USER MANAGER Copied one UID: "+key+", "+oneId);
                        other.addId(oneId);
                        idProfMap.put(oneId, other);
                    }
                }

                if (up.getLastLogin()>other.getLastLogin()) {
                    other.setLastLogin(up.getLastLogin(), up.getLastLoginId());
                    other.setName(up.getName());
                }
                else if (other.getName()==null || other.getName().length()==0) {
                    other.setName(up.getName());
                }
                continue;
            }
            idsToRemove.clear();
            for (String oneId : up.getAllIds()) {
                other = idProfMap.get(oneId.toLowerCase());
                if (other!=null) {
                    //if we find any profile that already had that address,
                    //then the prior one gets to keep it, and it must be removed
                    //from here
                    idsToRemove.add(oneId);
                }
                else {
                    idProfMap.put(oneId, up);
                }
            }
            for (String removableId : idsToRemove) {
                System.out.println("USER MANAGER REMOVING one global ID: "+up.getKey()+", "+up.getUniversalId()+", "+removableId);
                up.removeId(removableId);
            }
            if (up.getAllIds().size()==0) {
                //there are no more unique global ids, so drop this one the floor.
                System.out.println("USER ELIMINATION: no email id at all: "+up.getKey());
                continue;
            }
            //we get here it means that this has unique key and unique global ids.
            //so we can safely retain this.
            keyProfMap.put(key, up);
            readUsers.add(up);
        }

        //now it is all there, assign the result collection
        allUsers = readUsers;
    }


    public void assureSiteAndWorkspace(Cognoscenti cog) throws Exception {
        for (UserProfile user : allUsers) {
            user.assureSiteAndWorkspace(cog);
        }
    }


    public static synchronized void writeUserProfilesToFile() throws Exception {
        cog.getUserManager().saveUserProfiles();
    }

    public synchronized void saveUserProfiles() throws Exception {

        JSONObject userFile = new JSONObject();
        JSONArray  userArray = new JSONArray();
        for (UserProfile uprof : allUsers) {
            userArray.put(uprof.getSecretJSON());
        }
        userFile.put("users", userArray);
        userFile.put("lastUpdate", System.currentTimeMillis());
        userFile.writeToFile(jsonFileName);

        saveCount++;
    }



    public static synchronized void refreshHashtables() {
        //this should be rare, maybe only once per server start.
        //if happening more times, we want that reported in the log
        System.out.println("USERS: Scanning all users for all keys and ids");
        
        //do this in a thread-safe manner
        Hashtable<String, UserProfile> readHashByKey = new Hashtable<String, UserProfile>();
        Hashtable<String, String> anyIdToKeyMapTemp = new Hashtable<String, String>();
        Hashtable<String, String> keyToEmailMapTemp = new Hashtable<String, String>();

        for (UserProfile up : allUsers) {
            String key = up.getKey();
            String preferredEmail = up.getPreferredEmail();
            if (preferredEmail==null) {
                //users can exist without an email address when one user takes over the email
                //address of another user, leaving the other without an address.
                //that user should be deleted from the list of all users, but some
                //lists of users might still be in memory.
                //So -- just ignore users without email at this point to avoid NPE
                System.out.println("USERS: Ignoring user found without an email address: "+key);
                continue;
            }
            readHashByKey.put(key, up);
            keyToEmailMapTemp.put(key, preferredEmail);
            anyIdToKeyMapTemp.put(key, key);
            for (String idval : up.getAllIds()) {
                String idValLC = idval.toLowerCase();
                String otherKey = anyIdToKeyMapTemp.get(idValLC);
                if (otherKey!=null && !otherKey.equals(key)) {
                    UserProfile otherProfile = readHashByKey.get(otherKey);
                    try {
                        System.out.println("USERS: two users claim the same email address ("+idval+")");
                        System.out.println("USER1: "+up.getJSON().toString(2));
                        System.out.println("USER2: "+otherProfile.getJSON().toString(2));
                    }
                    catch(Exception e) {
                        JSONException.traceException(e, "USERS: failed to report problem with email address ("+idval+")");
                    }
                }
                anyIdToKeyMapTemp.put(idValLC, key);
            }
        }
        userHashByKey = readHashByKey;
        anyIdToKeyMap = anyIdToKeyMapTemp;
        keyToEmailMap = keyToEmailMapTemp;
    }
    
    
    
    public static String getCorrectedEmail(String sourceId) {
        if (sourceId==null) {
            return null;
        }
        String key = anyIdToKeyMap.get(sourceId.toLowerCase());
        if (key==null) {
            return sourceId;
        }
        String preferredEmail = keyToEmailMap.get(key);
        if (preferredEmail==null) {
            return sourceId;
        }
        return preferredEmail;
    }


    /**
    * The user "key" is the 9 character unique hash value given them by system
    */
    public static synchronized UserProfile getUserProfileByKey(String key) {
        if (key == null) {
            throw new RuntimeException("getUserProfileByKey requires a non-null key as a parameter");
        }
        return userHashByKey.get(key);
    }
    public static synchronized UserProfile getUserProfileOrFail(String key) throws Exception {
        UserProfile up = getUserProfileByKey(key);
        if (up == null) {
            throw WeaverException.newBasic("Can not find a user profile for the key: %s", key);
        }
        return up;
    }

    public static synchronized UserProfile lookupUserByAnyId(String anyId) {
        //return null if a bogus value passed.
        //fixed bug 12/20/2010 that was finding people with nullstring names
        if (anyId==null || anyId.length()==0)
        {
            return null;
        }

        //first, try hashtable since that might be fast
        String key = anyIdToKeyMap.get(anyId.toLowerCase());
        if (key!=null) {
            UserProfile up = userHashByKey.get(key);
            if (up!=null) {
                //this should always be true at this point
                if (up.hasAnyId(anyId)) {
                    return up;
                }
    
                //if it gets here, then the hash table is messed up.
                //rather than throw exception ... just regenerate
                //the hash table, then drop into slow search.
                refreshHashtables();
            }
        }

        //second, walk through users the slow way
        for (UserProfile up2 : allUsers) {
            if (up2.hasAnyId(anyId)) {
                return up2;
            }
        }

        //did not find one, return null
        return null;
    }

    public synchronized UserProfile findUserByAnyIdOrFail(String anyId){
        UserProfile up = lookupUserByAnyId(anyId);
        if (up == null) {
            throw new RuntimeException("Can not find a user profile for the id: "+anyId);
        }
        return up;
    }

    public synchronized UserProfile createUserWithId(String newId) throws Exception {
        System.out.println("GLOBAL USERS: adding a user with id: "+newId);
        if (lookupUserByAnyId(newId)!=null) {
            throw WeaverException.newBasic("Can not create a new user profile using an address that some other profile already has: "+newId);
        }

        UserProfile up = new UserProfile(newId);
        allUsers.add(up);
        refreshHashtables();
        return up;
    }


    public synchronized List<UserProfile> getAllUserProfiles() {
        ArrayList<UserProfile> res = new ArrayList<UserProfile>();
        for (UserProfile up : allUsers) {
            res.add(up);
        }
        return res;
    }
    public synchronized List<AddressListEntry> getAllUsers() {
        ArrayList<AddressListEntry> res = new ArrayList<AddressListEntry>();
        for (UserProfile up : allUsers) {
            res.add(up.getAddressListEntry());
        }
        return res;
    }




    /**
    * Read through the user profile file, find all the users that are
    * disabled, and remove them from the user profile list.
    */
    public synchronized void removeDisabledUsers() throws Exception {
        ArrayList<UserProfile> cache = new ArrayList<UserProfile>();
        for (UserProfile up : allUsers) {
            if (!up.getDisabled()) {
                cache.add(up);
            }
        }
        allUsers = cache;
        saveUserProfiles();
    }



    public List<UserProfile> getAllSuperAdmins(AuthRequest ar) throws Exception{
        List<UserProfile> allProfiles=  ar.getCogInstance().getUserManager().getAllUserProfiles();
        List<UserProfile> allAdmins = new ArrayList<UserProfile>();
        for(UserProfile up : allProfiles){
            if(ar.isSuperAdmin( up.getKey() )){
                allAdmins.add( up );
            }
        }
        return allAdmins;
    }

    /**
     * get a list of email assignees for all server super admin users.
     */
    public List<OptOutAddr> getSuperAdminMailList(AuthRequest ar) throws Exception {
        ArrayList<OptOutAddr> sendTo = new ArrayList<OptOutAddr>();
        for (UserProfile superAdmin : getAllSuperAdmins(ar)) {
            AddressListEntry ale = AddressListEntry.findOrCreate(superAdmin.getPreferredEmail());
            if (ale.isWellFormed()) {
                sendTo.add(new OptOutSuperAdmin(ale));
            }
        }
        if (sendTo.size() == 0) {
            throw WeaverException.newBasic("Either there is no Super Admin in the System or system doesn't have profile for super admin.");
        }
        return sendTo;
    }

    public synchronized UserPage findOrCreateUserPage(String userKey)  throws Exception {
        if (userKey==null || userKey.length()==0) {
            throw WeaverException.newBasic("Program logic error: findOrCreateUserPage needs a non-null user key");
        }
        File userFolder = cog.getConfig().getUserFolderOrFail();
        File newPlace = new File(userFolder, userKey+".user");

        //check to see if the file is there
        if (!newPlace.exists())  {
            //it might be in the old position.
            File oldPlace = cog.getConfig().getFile(userKey+".user");
            if (oldPlace.exists()) {
                UserPage.moveFile(oldPlace, newPlace);
            }
        }
        Document newDoc = UserPage.readOrCreateFile(newPlace, "user");
        return new UserPage(newPlace, newDoc, userKey);
    }



    //////////////////////// Static Helpers ////////////////////////////

    /**
     * Some parts of the program are given a list of email addresses or other id values.
     * This will take the list, parse it, and return a list of AddressListEntry objects.
     */
    public static List<AddressListEntry> convertAddressList(String userIdList) throws Exception {
        ArrayList<AddressListEntry> ret = new  ArrayList<AddressListEntry>();
        if (userIdList == null || userIdList.length() == 0) {
            return ret;
        }

        List<String> st = UtilityMethods.splitString(userIdList, ',');
        for (String listItem : st)  {
            AddressListEntry ale = AddressListEntry.findOrCreate(listItem);
            ret.add(ale);
        }
        return ret;
    }

    /**
     * Given a list of AddressListObjects, this will make a nicely coma delimited list
     * of the names of those users.
     */
    public static String getUserNamesAsList(List<AddressListEntry> userProfiles) throws Exception {
        StringBuilder sb = new StringBuilder();
        boolean needsComma = false;
        for (AddressListEntry listItem : userProfiles)  {
            if (needsComma) {
                sb.append(", ");
            }
            sb.append(listItem.getName());
            needsComma = true;
        }
        return sb.toString();
    }

}
