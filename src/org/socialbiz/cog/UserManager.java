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

package org.socialbiz.cog;

import java.io.File;
import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;
import java.util.Vector;

import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.w3c.dom.Document;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;

public class UserManager
{
    public static int loadCount = 0;
    public static int modCount = 0;
    public static int saveCount = 0;
    
    private static Hashtable<String, UserProfile> userHashByUID = new Hashtable<String, UserProfile>();
    private static Hashtable<String, UserProfile> userHashByKey = new Hashtable<String, UserProfile>();
    private static Vector<UserProfile> allUsers = new Vector<UserProfile>();

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
        userHashByUID = new Hashtable<String, UserProfile>();
        userHashByKey = new Hashtable<String, UserProfile>();
        allUsers      = new Vector<UserProfile>();
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
        
        jsonFileName = new File(userFolder, "UserProfs.json");
        if(!jsonFileName.exists()) {
            throw new Exception("File for "+jsonFileName+" is MISSING.   Create an empty file in order to run Weaver server.");

            /*File xmlFileName = new File(userFolder, "UserProfiles.xml");
            convertXMLtoJSON(xmlFileName);
            if(!jsonFileName.exists()) {
                throw new Exception("Conversion of user profiles to JSON format failed somehow.");
            }
            */
        }
        
        //clear out any left over evidence of an earlier initialization
        allUsers = new Vector<UserProfile>();

        //need to make sure all the same information is in the JSON file....
        readJSONFile();
        
        refreshHashtables();
        initialized = true;
    }
    

    private void readJSONFile() throws Exception  {
        
        if(!jsonFileName.exists()) {
            throw new JSONException("Not able to create the user profile file: {0}", jsonFileName);
        }
        
       
        JSONObject userFile = JSONObject.readFromFile(jsonFileName);
        loadCount++;
        
        JSONArray users = userFile.getJSONArray("users");
        
        Hashtable<String,UserProfile> keyProfMap = new Hashtable<String,UserProfile>();
        Hashtable<String,UserProfile> idProfMap = new Hashtable<String,UserProfile>();
        ArrayList<String> idsToRemove = new ArrayList<String>();
        Vector<UserProfile> readUsers = new Vector<UserProfile>();
        
        for (int i=0; i<users.length(); i++) {
            UserProfile up = new UserProfile(users.getJSONObject(i));
            String key = up.getKey();
            UserProfile other = keyProfMap.get(key);
            if (other!=null) {
                System.out.println("USER MANAGER FOUND duplicate user key to DELETE: "+key+", "+up.getUniversalId());
                //this is a big problem.  Two records with the same KEY.  That can
                //only happen because of a bug.  Just drop this!

                //after transferring any additional global ids that are not already on
                //other objects.
                for (String oneId : up.getAllIds()) {
                    UserProfile other2 = idProfMap.get(oneId);
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
                other = idProfMap.get(oneId);
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
                System.out.println("USER MANAGER REMOVING USER COMPLETELY: "+up.getKey());
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
    
    
    /**
     * This will be retired some day...
     *
    private void convertXMLtoJSON(File xmlFileName) throws Exception  {
        if(!xmlFileName.exists()) {
            throw new JSONException("Can't find the new or the old user profiles. ({0}) giving up.", xmlFileName);
        }
        
        InputStream is = new FileInputStream(xmlFileName);
        Document userDoc = DOMUtils.convertInputStreamToDocument(is, false, false);
        DOMFile profileFile = new DOMFile(xmlFileName, userDoc);
        loadCount++;

        //there was some kind of bug that allowed multiple entries to be created
        //with the same unique key, and that causes all sorts of problems.
        //This code will check and make sure that every Key value is unique.
        //if a duplicate is found (which might happen when someone edits this
        //file externally, then a new unique key is substituted.  This is OK
        //because the openid is ID that is stored in pages.  It does change the
        //URL for that user, but we have no choice ... some other user has that URL.
        Hashtable<String, String> guaranteeUnique = new Hashtable<String, String>();
        List<UserProfileXML> profiles = profileFile.getChildren("userprofile", UserProfileXML.class);
        for (UserProfileXML upXML : profiles) {
            
            UserProfile up = new UserProfile(upXML);
            String upKey = up.getKey();
            if (guaranteeUnique.containsKey(upKey)) {
                upKey = IdGenerator.generateKey();
                up.setKey(upKey);
            }

            guaranteeUnique.put(upKey, upKey);
            allUsers.add(up);
        }
        
        this.saveUserProfiles();
    }
    */


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

   

    private synchronized void refreshHashtables() {
        Hashtable<String, UserProfile> readHashByUID = new Hashtable<String, UserProfile>();
        Hashtable<String, UserProfile> readHashByKey = new Hashtable<String, UserProfile>();

        for (UserProfile up : allUsers) {
            for (String idval : up.getAllIds()) {
                readHashByUID.put(idval, up);
            }
            readHashByKey.put(up.getKey(), up);
        }
        userHashByUID = readHashByUID;
        userHashByKey = readHashByKey;
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
            throw new NGException("nugen.exception.user.profile.not.exist", new Object[]{key});
        }
        return up;
    }

    /**
    * Given an id, may be openid or email address, this will attempt
    * to find the existing user profile that has that id.  If it can not
    * find one that is existing, it will return null.
    *
    * Should ONLY fid by confirmed IDs, not by any proposed IDs.
    *
    public static UserProfile findUserByAnyId(String anyId)
    {
        //here is how we find the singleton....
        UserManager userManager = cog.getUserManager();
        return userManager.lookupUserByAnyId(anyId);
    }
    */
        
        
    public synchronized UserProfile lookupUserByAnyId(String anyId) {
        //return null if a bogus value passed.
        //fixed bug 12/20/2010 that was finding people with nullstring names
        if (anyId==null || anyId.length()==0)
        {
            return null;
        }

        //first, try hashtable since that might be fast
        UserProfile up = userHashByUID.get(anyId);
        if (up!=null)
        {
            //this should always be true at this point
            if (up.hasAnyId(anyId))
            {
                return up;
            }

            //if it gets here, then the hash table is messed up.
            //rather than throw exception ... just regenerate
            //the hash table, then drop into slow search.
            refreshHashtables();
        }

        //second, walk through users the slow way
        for (UserProfile up2 : allUsers)
        {
            if (up2.hasAnyId(anyId))
            {
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
        if (lookupUserByAnyId(newId)!=null) {
            throw new ProgramLogicError("Can not create a new user profile using an address that some other profile already has: "+newId);
        }

        UserProfile up = new UserProfile(newId);
        allUsers.add(up);
        refreshHashtables();
        return up;
    }


    public synchronized List<UserProfile> getAllUserProfiles() {
        Vector<UserProfile> res = new Vector<UserProfile>();
        for (UserProfile up : allUsers) {
            res.add(up);
        }
        return res;
    }
    public synchronized List<AddressListEntry> getAllUsers() {
        Vector<AddressListEntry> res = new Vector<AddressListEntry>();
        for (UserProfile up : allUsers) {
            res.add(new AddressListEntry(up));
        }
        return res;
    }

    /**
    * returns users that have profiles, and also users who have microprofile
    */
    public synchronized List<AddressListEntry> getAllPossibleUsers() throws Exception {
        Vector<AddressListEntry> res = new Vector<AddressListEntry>();
        Hashtable<String,String> repeatCheck = new Hashtable<String,String>();
        for (UserProfile up : allUsers) {
            if (up.getDisabled()) {
                //skip disabled user accounts
                continue;
            }
            String uid = up.getUniversalId();
            if (!repeatCheck.containsKey(uid)) {
                res.add(new AddressListEntry(up));
                repeatCheck.put(uid,uid);
            }
        }
        for (AddressListEntry one : MicroProfileMgr.getAllProfileIds()) {
            String uid = one.getUniversalId();
            if (!repeatCheck.containsKey(uid)) {
                res.add( one );
                repeatCheck.put(uid,uid);
            }
        }
        return res;
    }




    /**
    * Read through the user profile file, find all the users that are
    * disabled, and remove them from the user profile list.
    */
    public synchronized void removeDisabledUsers() throws Exception {
        Vector<UserProfile> cache = new Vector<UserProfile>();
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
    public Vector<OptOutAddr> getSuperAdminMailList(AuthRequest ar) throws Exception {
        Vector<OptOutAddr> sendTo = new Vector<OptOutAddr>();
        for (UserProfile superAdmin : getAllSuperAdmins(ar)) {
            AddressListEntry ale = new AddressListEntry(superAdmin.getPreferredEmail());
            if (ale.isWellFormed()) {
                sendTo.add(new OptOutSuperAdmin(ale));
            }
        }
        if (sendTo.size() == 0) {
            throw new NGException("nugen.exceptionhandling.account.no.super.admin", null);
        }
        return sendTo;
    }

    public synchronized UserPage findOrCreateUserPage(String userKey)  throws Exception {
        if (userKey==null || userKey.length()==0) {
            throw new NGException("nugen.exception.cant.create.user.page",null);
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
        Vector<AddressListEntry> ret = new  Vector<AddressListEntry>();
        if (userIdList == null || userIdList.length() == 0) {
            return ret;
        }

        List<String> st = UtilityMethods.splitString(userIdList, ',');
        for (String listItem : st)  {
            AddressListEntry ale = new AddressListEntry(listItem);
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
