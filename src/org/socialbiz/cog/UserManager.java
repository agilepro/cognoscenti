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
import java.io.FileInputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;
import java.util.Vector;

import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.w3c.dom.Document;
import org.workcast.json.JSONArray;

public class UserManager
{
    private static Hashtable<String, UserProfile> userHashByUID = new Hashtable<String, UserProfile>();
    private static Hashtable<String, UserProfile> userHashByKey = new Hashtable<String, UserProfile>();
    private static Vector<UserProfile> allUsers = new Vector<UserProfile>();

    private static boolean initialized = false;

    private static DOMFile  profileFile;

    //TODO: get rid of this static
    private static Cognoscenti cog;
    //TODO: get rid of need to initialized this static
    public static void init(Cognoscenti _cog) {
        cog = _cog;
    }

    /**
    * Set all static values back to their initial states, so that
    * garbage collection can be done, and subsequently, the
    * class will be reinitialized.
    */
    public synchronized static void clearAllStaticVars()
    {
        userHashByUID = new Hashtable<String, UserProfile>();
        userHashByKey = new Hashtable<String, UserProfile>();
        allUsers      = new Vector<UserProfile>();
        initialized   = false;
        profileFile   = null;
    }


    public synchronized static void loadUpUserProfilesInMemory(Cognoscenti cog)
        throws Exception
    {
        //check to see if this has already been loaded, if so, there is nothing to do
        if (initialized) {
            return;
        }

        File userFolder = cog.getConfig().getUserFolderOrFail();
        File newPlace = new File(userFolder, "UserProfiles.xml");

        //check to see if the file is there
        if (!newPlace.exists())  {
            //it might be in the old position.
            File oldPlace = cog.getConfig().getFile("UserProfiles.xml");
            if (oldPlace.exists()) {
                DOMFile.moveFile(oldPlace, newPlace);
            }
        }

        //clear out any left over evidence of an earlier initialization
        allUsers = new Vector<UserProfile>();

        Document userDoc = null;
        if(!newPlace.exists())
        {
            // create the user profile file.
            userDoc = DOMUtils.createDocument("userprofiles");
            profileFile = new DOMFile(newPlace, userDoc);
            writeUserProfilesToFile();
        }
        else
        {
            InputStream is = new FileInputStream(newPlace);
            userDoc = DOMUtils.convertInputStreamToDocument(is, false, false);
        }
        profileFile = new DOMFile(newPlace, userDoc);

        //there was some kind of but that allowed multiple entries to be created
        //with the same unique key, and that causes all sorts of problems.
        //This code will check and make sure that every Key value is unique.
        //if a duplicate is found (which might happen when someone edits this
        //file externally, then a new unique key is substituted.  This is OK
        //because the openid is ID that is stored in pages.  It does change the
        //URL for that user, but we have no choice ... some other user has that URL.
        Hashtable<String, String> guaranteeUnique = new Hashtable<String, String>();
        Vector<UserProfile> profiles = profileFile.getChildren("userprofile", UserProfile.class);
        for (UserProfile up : profiles) {
            String upKey = up.getKey();
            if (guaranteeUnique.containsKey(upKey)) {
                upKey = IdGenerator.generateKey();
                up.setKey(upKey);
            }

            guaranteeUnique.put(upKey, upKey);
            allUsers.add(up);
        }
        refreshHashtables();
        if (profileFile == null) {
            throw new ProgramLogicError("ended up with profileFile null.!?!?!");
        }

        initialized = true;
    }


    public static void reloadUserProfiles(Cognoscenti cog) throws Exception
    {
        clearAllStaticVars();
        loadUpUserProfilesInMemory(cog);
    }

    public static void refreshHashtables()
    {
        userHashByUID = new Hashtable<String, UserProfile>();
        userHashByKey = new Hashtable<String, UserProfile>();

        for (UserProfile up : allUsers)
        {
            for (IDRecord idrec : up.getIdList())
            {
                String idval = idrec.getLoginId();
                if (idval!=null)
                {
                    userHashByUID.put(idval, up);
                }
            }
            userHashByKey.put(up.getKey(), up);
        }
    }


    /**
    * The user "key" is the 9 character unique hash value given them by system
    */
    public static UserProfile getUserProfileByKey(String key)
    {
        if (key == null)
        {
            throw new RuntimeException("getUserProfileByKey requires a non-null key as a parameter");
        }
        return userHashByKey.get(key);
    }
    public static UserProfile getUserProfileOrFail(String key)
        throws Exception
    {
        UserProfile up = getUserProfileByKey(key);
        if (up == null)
        {
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
    */
    public static UserProfile findUserByAnyId(String anyId)
    {
        //return null if a bogus value passed.
        //fixed bug 12/20/2010 hat was finging people with nullstring names
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

    public static UserProfile findUserByAnyIdOrFail(String anyId){
        UserProfile up = findUserByAnyId(anyId);
        if (up == null)
        {
            throw new RuntimeException("Can not find a user profile for the id: "+anyId);
        }
        return up;
    }

    public static UserProfile createUserWithId(String guid, String newId)
        throws Exception
    {
        //lets make sure that no other profile has that id first,
        //to avoid any complicated situations.
        if (guid!=null && UserManager.getUserProfileByKey(guid)!=null) {
            throw new ProgramLogicError("Can not create a new user profile using a key/guid that some other profile already has: "+guid);
        }
        if (UserManager.findUserByAnyId(newId)!=null) {
            throw new ProgramLogicError("Can not create a new user profile using an address that some other profile already has: "+newId);
        }

        UserProfile up = createUserProfile(guid);
        up.addId(newId);
        return up;
    }

    public static UserProfile createUserProfile(String guid) throws Exception {
        if (profileFile==null) {
            throw new ProgramLogicError("profileFile is null when it shoudl not be.  May not have been initialized correctly.");
        }
        UserProfile nu = profileFile.createChild("userprofile", UserProfile.class);
        if (guid!=null) {
            nu.setKey(guid);
        }
        allUsers.add(nu);
        refreshHashtables();
        return nu;
    }


    static public String getUserFullNameList() {
        if (userHashByUID == null) {
            return "";
        }
        StringBuffer sb = new StringBuffer();
        boolean addComma = false;
        for (String oid : userHashByUID.keySet()) {
            UserProfile up = userHashByUID.get(oid);
            if (addComma) {
                sb.append(",");
            }
            sb.append("\"");
            sb.append(up.getName());
            sb.append("<");
            sb.append(oid);
            sb.append(">");
            sb.append("\"");
            addComma = true;
        }
        String str = sb.toString();
        return str;
    }

    public static UserProfile[] getAllUserProfiles() throws Exception
    {
        UserProfile[] ups = new UserProfile[allUsers.size()];
        allUsers.copyInto(ups);
        return ups;
    }
    public static List<AddressListEntry> getAllUsers() {
        Vector<AddressListEntry> res = new Vector<AddressListEntry>();
        for (UserProfile up : allUsers) {
            res.add(new AddressListEntry(up));
        }
        return res;
    }

    public synchronized static void writeUserProfilesToFile() throws Exception {
        if (profileFile==null) {
            throw new NGException("nugen.exception.write.user.profile.info.fail",null);
        }
        profileFile.save();
    }


    public static String getShortNameByUserId(String userId) {
        if(userHashByUID != null) {
            UserProfile up = findUserByAnyId(userId);
            if(up != null) {
                return up.getName();
            }
        }
        return userId;
    }


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
        StringBuffer sb = new StringBuffer();
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

    /**
    * Read through the user profile file, find all the users that are
    * disabled, and remove them from the user profile list.
    */
    public static synchronized void removeDisabledUsers(Cognoscenti cog)
        throws Exception
    {
        Vector<UserProfile> toBeRemoved = new Vector<UserProfile>();
        for (UserProfile up : allUsers)
        {
            if (up.getDisabled())
            {
                toBeRemoved.add(up);
            }
        }
        for (UserProfile up : toBeRemoved)
        {
            profileFile.removeChild(up);
            allUsers.remove(up);
        }
        writeUserProfilesToFile();
    }

    static public String getUserFullNameList(String matchKey) throws Exception
    {
        StringBuffer sb = new StringBuffer();
        boolean addComma = false;
        for (UserProfile up : allUsers)
        {
             if (addComma)
             {
                 sb.append(",");
             }
             if(up.getName().toLowerCase().contains(matchKey.toLowerCase())){
                sb.append(up.getName());
                sb.append("<");
                sb.append(up.getUniversalId());
                sb.append(">");
                addComma = true;
            }else{
                addComma = false;
            }
        }
        return sb.toString();
    }

    public static String getKeyByUserId(String userId)
    {
        if(userHashByUID != null)
        {
            UserProfile up = findUserByAnyId(userId);
            if(up != null)
            {
                return up.getKey();
            }
        }
        return userId;
    }



    public static List<UserProfile> getAllSuperAdmins(AuthRequest ar) throws Exception{

     UserProfile[] allProfiles=  getAllUserProfiles();
     List<UserProfile> allAdmins = new ArrayList<UserProfile>();
     for(int i=0; i<allProfiles.length; i++){
         if(ar.isSuperAdmin( allProfiles[i].getKey() )){
             allAdmins.add( allProfiles[i] );
         }
     }
     return allAdmins;

    }

    public static  UserProfile getSuperAdmin(AuthRequest ar) throws Exception{
        UserProfile superAdmin = null;
        String superAdminKey = ar.getSystemProperty("superAdmin");
        if (superAdminKey == null)
        {
            //if the superAdmin not defined, then NOBODY is super admin
            return null;
        }
        superAdmin = findUserByAnyId(superAdminKey);

        return superAdmin;
    }

    /**
     * get a list of email assignees for all server super admin users.
     */
    public static Vector<OptOutAddr> getSuperAdminMailList(AuthRequest ar)
            throws Exception {
        Vector<OptOutAddr> sendTo = new Vector<OptOutAddr>();
        for (UserProfile superAdmin : getAllSuperAdmins(ar)) {
            sendTo.add(new OptOutSuperAdmin(new AddressListEntry(superAdmin.getPreferredEmail())));
        }
        if (sendTo.size() == 0) {
            throw new NGException("nugen.exceptionhandling.account.no.super.admin", null);
        }
        return sendTo;
    }

    public static JSONArray getUniqueUsersJSON() throws Exception {
        JSONArray allPeople = new JSONArray();
        Hashtable<String,String> repeatCheck = new Hashtable<String,String>();
        for (AddressListEntry one : UserManager.getAllUsers()) {
            String uid = one.getUniversalId();
            if (!repeatCheck.containsKey(uid)) {
                allPeople.put( one.getJSON() );
                repeatCheck.put(uid,uid);
            }
        }
        for (AddressListEntry one : MicroProfileMgr.getAllProfileIds()) {
            String uid = one.getUniversalId();
            if (!repeatCheck.containsKey(uid)) {
                allPeople.put( one.getJSON() );
                repeatCheck.put(uid,uid);
            }
        }
        return allPeople;
    }

    public static UserPage findOrCreateUserPage(String userKey)
            throws Exception
        {
            if (userKey==null || userKey.length()==0)
            {
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

}
