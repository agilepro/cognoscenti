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

import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.TimeZone;
import com.purplehillsbooks.weaver.exception.ProgramLogicError;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;

public class UserProfile implements UserRef
{
    public static final String defaultTimeZone = "America/Los_Angeles";

    private String userKey = "";
    private String name = "";
    private String description;
    private String licenseToken;
    private long   lastLogin;
    private String lastLoginId;
    private long   lastUpdated;
    private long   notifyTime;
    private String accessCode;
    private long   accessCodeModTime;
    private int    notifyPeriod;
    private boolean disabled;
    private List<String> emailAddresses = null;
    private String timeZone = "America/Los_Angeles";
    private JSONObject wsSettings = new JSONObject();
    private boolean isFacilitator = false;
    public boolean useNewUI = false;

    public UserProfile(String preferredEmail) throws Exception {
        userKey = IdGenerator.generateKey();
        emailAddresses = new ArrayList<String>();
        emailAddresses.add(preferredEmail);

        //make sure that this profile has a license token
        getLicenseToken();
    }


    public static boolean looksLikeEmail(String possibleEmail) {
        return (possibleEmail.indexOf('@')>0 && possibleEmail.indexOf('/')<0);
    }
    


    public UserProfile(JSONObject fullJO) throws Exception {

        if (fullJO.has("key"))  {
            userKey = fullJO.getString("key");
        }
        else {
            userKey = IdGenerator.generateKey();
        }

        List<String> newEmail = new ArrayList<String>();
        if (fullJO.has("ids")) {
            for (String possibleEmail: fullJO.getJSONArray("ids").getStringList()) {
                //we ONLY include things that looks like email address.
                //check could be better, but this elminates the old OpenID
                if (looksLikeEmail(possibleEmail)) {
                    newEmail.add(possibleEmail);
                }
            }
        }
        emailAddresses = newEmail;

        licenseToken  = fullJO.getString("licenseToken");

        lastLogin     = fullJO.optLong("lastLogin",0);
        lastLoginId   = fullJO.optString("lastLoginId",null);
        lastUpdated   = fullJO.optLong("lastUpdated",0);
        notifyTime    = fullJO.optLong("notifyTime",0);
        accessCode    = fullJO.optString("accessCode",null);
        accessCodeModTime = fullJO.optLong("accessCodeModTime",0);
        isFacilitator = fullJO.optBoolean("isFacilitator", false);
        useNewUI      = fullJO.optBoolean("useNewUI", false);

        if (!fullJO.has("wsSettings")) {
            convertOldWSSettings(fullJO);
        }
        wsSettings = fullJO.getJSONObject("wsSettings");

        updateFromJSON(fullJO);

        //make sure that this profile has a license token
        getLicenseToken();
        defaultName();
    }
    
    private void defaultName() {
        //give them a name if they don't have one.
        if (name == null || name.length()==0) {
            String email = getUniversalId();
            int atPos = email.indexOf("@");
            if (atPos>0) {
                name = email.substring(0, atPos).toUpperCase();
            }
        }
    }


    /**
     * The purpose of this is to search for references to workspaces
     * that only have the workspace key, and replace them with references
     * with the site key and the workspace key.
     */
    public void assureSiteAndWorkspace(Cognoscenti cog) throws Exception {
        List<String> checkList = new ArrayList<String>();
        for (String oldKey : wsSettings.keySet()) {
            if (oldKey.indexOf("|")<0) {
                checkList.add(oldKey);
            }
            else {
                NGPageIndex ws = cog.getWSByCombinedKey(oldKey);
                if (ws==null) {
                    checkList.add(oldKey);
                }
            }
        }
        for (String oldKey : checkList) {
            if (oldKey.indexOf("|")<0) {
                //looks like this is an old key, correct it
                JSONObject jo = wsSettings.getJSONObject(oldKey);
                wsSettings.remove(oldKey);
                NGPageIndex ws = cog.lookForWSBySimpleKeyOnly(oldKey);
                if (ws!=null) {
                    wsSettings.put(ws.wsSiteKey+"|"+ws.containerKey, jo);
                }
            }
            else {
                //if we can't find a workspace with this key, remove it
                NGPageIndex ws = cog.getWSByCombinedKey(oldKey);
                if (ws==null) {
                    wsSettings.remove(oldKey);
                }
            }
        }

        //now clear up the entries
        for (String currentKey : wsSettings.keySet()) {
            JSONObject jo = wsSettings.getJSONObject(currentKey);
            if (jo.has("serverTime")) {
                jo.remove("serverTime");
            }
            if (jo.has("isNotify") && !jo.getBoolean("isNotify")) {
                jo.remove("isNotify");
            }
            if (jo.has("isTemplate")) {
                //this is removed, so always clean up
                jo.remove("isTemplate");
            }
            if (jo.has("isWatching") && !jo.getBoolean("isWatching")) {
                jo.remove("isWatching");
            }
        }
    }



    /**
     * This is a schema migration used to be:
     *
     * "notifyList": ["ws", "ws"],
     * "templateList": ["ws", "ws"],
     * "watchList": [ {
     *    "key": "ws",
     *    "lastSeen": 1453902246029
     *  }]
     *
     *  Many of these were "bare" workspace ids and need to be
     *  converted to site|ws combo ids
     *
     *  result is a single association:
     *
     *  wsSettings: {
     *     "ws": {
     *        notify: true,
     *        template: true,   //THIS REMOVED
     *        watch: true,
     *        reviewTime: 1453902246029
     *      }
     *  }
     *
     * @param fullJO
     */
    private void convertOldWSSettings(JSONObject fullJO) throws Exception {

        if (fullJO.has("wsSettings")) {
            throw new Exception("program logic error: convertOldWSSettings should be called only on objects with wsSettings");
        }
        System.out.println("FOUND USER WITH OLD DATA: wsSettings is the old way somehow -- this should no longer be happening.");
        wsSettings = new JSONObject();

        if (fullJO.has("watchList")) {
            JSONArray watchList = fullJO.getJSONArray("watchList");
            for (int i=0; i<watchList.length(); i++) {
                JSONObject oneWatch = watchList.getJSONObject(i);
                String siteWorkspaceCombo = oneWatch.getString("key");
                JSONObject settingObj = assureSettingsRelaxed(siteWorkspaceCombo);
                settingObj.put("isWatching", true);
                if (oneWatch.has("lastSeen")) {
                    settingObj.put("reviewTime", oneWatch.getLong("lastSeen"));
                }
            }
            fullJO.remove("watchList");
        }
        if (fullJO.has("notifyList")) {
            JSONArray notifyList = fullJO.getJSONArray("notifyList");
            for (int i=0; i<notifyList.length(); i++) {
                String siteWorkspaceCombo = notifyList.getString(i);
                JSONObject settingObj = assureSettingsRelaxed(siteWorkspaceCombo);
                settingObj.put("isNotify", true);
            }
            fullJO.remove("notifyList");
        }
        if (fullJO.has("templateList")) {
            fullJO.remove("templateList");
        }

        fullJO.put("wsSettings", wsSettings);
    }

    private JSONObject assureSettingsRelaxed(String siteWorkspaceCombo) throws Exception {
        if (wsSettings.has(siteWorkspaceCombo)) {
            return wsSettings.getJSONObject(siteWorkspaceCombo);
        }
        JSONObject settingObj =  new JSONObject();
        wsSettings.put(siteWorkspaceCombo,settingObj);
        return settingObj;
    }

    private JSONObject assureSettings(String siteWorkspaceCombo) throws Exception {
        if (siteWorkspaceCombo.indexOf("|")<0) {
            throw new Exception("User profile workspace settings requires a combined key of the form: (site) | (workspace), got: "+siteWorkspaceCombo);
        }
        if (wsSettings.has(siteWorkspaceCombo)) {
            return wsSettings.getJSONObject(siteWorkspaceCombo);
        }
        JSONObject settingObj =  new JSONObject();
        wsSettings.put(siteWorkspaceCombo,settingObj);
        return settingObj;
    }




    public List<String> getAllIds() {
        List<String> retVal = new ArrayList<String> ();
        for (String anId : emailAddresses) {
            retVal.add(anId);
        }
        return retVal;
    }



    /**
    * This should be unique and internal, so .... not
    * sure why it would ever need to be set.
    */
    public void setKey(String nkey) {
        userKey = nkey;
    }

    /**
    * The key is a unique identifier on this server for a particular user.
    * Never forget that this is NOT a global identifier that is useful on
    * any other server.  The email address, and open id, are global identifiers
    * that can be transferred across servers, but the KEY is a key only on this
    * server.
    */
    public String getKey() {
        return userKey;
    }

    public void setName(String newName) {
        if (newName == null || newName.length()==0) {
            defaultName();
        }
        else {
            name = newName;
        }
    }
    public String getName() {
        if (name==null || name.length()==0) {
            defaultName();
        }
        return name;
    }


    public void setDescription(String newDesc) {
        description = newDesc;
    }
    public String getDescription() {
        return description;
    }

    /**
    * Gives this user the specified ID (either email or OpenId).
    * Note: only do this when the ID have been verified as belonging
    * to this user!   This method will search for other users with that
    * ID, and remove that id from those other users.
    */
    public void addId(String newEmailAddress) throws Exception {
        if (newEmailAddress.indexOf(" ")>=0) {
            throw new ProgramLogicError("an email with a space in it was passed to UserProfile.addID: ("+newEmailAddress+")");
        }
        if (!looksLikeEmail(newEmailAddress)) {
            throw new ProgramLogicError("Attempt to set non-email address on user: ("+newEmailAddress+").   Only email addresses are allowed");
        }

        //check if this user already has the ID, and do nothing if true
        for (String idval : emailAddresses) {
            if (newEmailAddress.equalsIgnoreCase(idval)) {
                //nothing to do, there is already an ID in there
                return;
            }
        }

        //search all users for others that might have it
        for(UserProfile otherUser : UserManager.getStaticUserManager().getAllUserProfiles()) {
            
            if (otherUser.getKey().equals(getKey())) {
                //we found ourselves!   Skip this user from list
                continue;
            }
            if (!otherUser.hasAnyId(newEmailAddress)) {
                //ignore users that do not have this email address
                continue;
            }

            //found at least one on this user, remove it.
            otherUser.removeId(newEmailAddress);
        }
        emailAddresses.add(newEmailAddress);
        
        //refresh the tables that find user profiles by name and email
        UserManager.refreshHashtables();
    }

    /**
    * Removes the id from the profile.
    * If no ID like that exists, then it does nothing, no error.
    * If duplicates exist, removes all of them.
    * If newId equals preferred Email then it clears that.
    * NOTE: this can leave the profile without any id.
    */
    public void removeId(String newId) throws Exception {
        ArrayList<String> cache = new ArrayList<String>();
        for (String possible : emailAddresses) {
            if (!possible.equalsIgnoreCase(newId)) {
                cache.add(possible);
            }
        }
        emailAddresses = cache;
    }

    public void setLastLogin(long newLastLogin, String loginId) {
        lastLogin = newLastLogin;
        lastLoginId = loginId;
    }

    public long getLastLogin() {
        return lastLogin;
    }

    /**
    * Since a user can log in wiht more than one id, this records the
    * id that was used for the last actual login, so that this can be
    * used as a prompt for logging in (stored in cookies).
    */
    public String getLastLoginId() {
        return UserManager.getCorrectedEmail(lastLoginId);
    }

    public void setLastUpdated(long newLastUpdated) {
        lastUpdated = newLastUpdated;
    }

    public long getLastUpdated() {
        return lastUpdated;
    }


    /*
     * A user can choose how many days between reminder emails.
     * Typically 1= 1 day,   7= 1 week,  30= about a month
     * Notification email is not sent unless it is needed.
     * Then, when time to send, it makes sure that it has not
     * sent any email within that time period to that user,
     * and waits until it has been that long.  Of course,
     * The first email is on the first day that they need
     * notification if it has been a long time.
     */
    public void setNotificationPeriod(int period) {
        notifyPeriod = period;
    }
    public int getNotificationPeriod() {
        if (notifyPeriod<=0) {
            notifyPeriod=1;
        }
        return notifyPeriod;
    }



    public void setNotificationTime(long time) {
        notifyTime = time;
    }
    public long getNotificationTime() {
        return notifyTime;
    }


    /**
    * The license token is a randomly generated value that controls API
    * access to the user's information.  It is, so to speak, a password
    * for use in the API.  The user should be able to reset this token
    * on demand, which then requires all user-licensed links to be
    * refreshed.
    *
    * If you generate a new token, don't forget to save user profiles
    */
    public void genNewLicenseToken() {
        licenseToken = IdGenerator.generateKey();
    }
    public String getLicenseToken() {
        if (licenseToken==null || licenseToken.length()==0) {
            licenseToken = IdGenerator.generateKey();
        }
        return licenseToken;
    }


    /**
    * returns true if this user profile contains the specified id
    * and that ID is confirmed.
    * Unconfirmed ids DO NOT count for this purpose.
    * Until an ID is confirmed, the user does not really HAVE it.
    * Caution: functions confirming IDs need to be careful to
    * not use this function in the wrong situation.
    *
    * Required by interface UserRef
    */
    public boolean hasAnyId(String testId) {
        for (String idval : emailAddresses) {
            if (testId.equalsIgnoreCase(idval)) {
                return true;
            }
        }

        //also test the full name.  If a full name has been entered into an
        //id spot, it should work as well.  They might, of course, change their name
        //but also they might change their email address, so assigning by name is
        //no worse than by email or openid.
        //
        //This should not cause any problems because nobody has a name that is
        //exactly like someone else's email address.  If someone purposefully tries
        //to name themselves as someone else's email address, they will be chosen only
        //if there is nobody else with that email address.
        if (testId.equalsIgnoreCase(name)) {
            return true;
        }

        //also test the internal randomly generated key. Nobody has a key that is
        //exactly like someone else's email address.  If someone purposefully tries
        //to name themselves as someone else key, they will be chosen only
        //if there is nobody else with that email address.
        if (testId.equalsIgnoreCase(userKey)) {
            return true;
        }

        return false;
    }


    /**
    * Required by interface UserRef
    */
    public boolean equals(UserRef other)
    {
        //first test one way
        if (hasAnyId(other.getUniversalId()))
        {
            return true;
        }
        //then test the other way
        return other.hasAnyId(getUniversalId());
    }


    public AddressListEntry getAddressListEntry() {
        return new AddressListEntry(this);
    }



    /**
    * Universal ID is normally the "preferred" email address of a particular user.
    * If the user profile does not have an email address, then the open id is used.
    * However, all user profiles are *supposed* to have email addresses.
    */
    public String getUniversalId()
    {
        String usable = getPreferredEmail();
        if (usable==null || usable.length()==0) {
            // not sure what to do here.  Profile is not valid without any ids
            // but key should work in most places it is needed.  Not universal
            // but it is unique on this site at least
            return getKey();
        }
        return usable;
    }

    /**
     * Make a link to this to provide information about the person
     */
    public String getLinkUrl() throws Exception {
        return "v/FindPerson.htm?uid="+URLEncoder.encode(getKey(), "UTF-8");
    }

    /**
    * Writes the name of the user.
    * Makes it a link if you are logged in and if
    * this is not a static site.
    */
    public void writeLink(AuthRequest ar) throws Exception {
        boolean makeItALink = ar.isLoggedIn() && !ar.isStaticSite();
        writeLinkInternal(ar, makeItALink);
    }

    /**
    * Writes the name of the user as a link regardless of whether
    * user is logged in or not
    */
    public void writeLinkAlways(AuthRequest ar) throws Exception {
        writeLinkInternal(ar, true);
    }


    private void writeLinkInternal(AuthRequest ar, boolean makeItALink) throws Exception {
        String cleanName = getName();
        if (cleanName==null || cleanName.length()==0) {
            //if they don't have a name, use their email address or openid (if no email address)
            cleanName = getUniversalId();
        }
        if (cleanName==null || cleanName.length()==0) {
            //if they don't have an email address, use their key
            cleanName = getKey();
        }
        if (cleanName.length()>28) {
            cleanName = cleanName.substring(0,28);
        }
        String olink = "v/FindPerson.htm?uid="+URLEncoder.encode(getKey(), "UTF-8");
        if (makeItALink) {
            ar.write("<a href=\"");
            ar.write(ar.retPath);
            ar.write(olink);
            ar.write("\" title=\"access the profile of this user, if one exists\">");
            ar.write("<span class=\"red\">");
            ar.writeHtml(cleanName);
            ar.write("</span>");
            ar.write("</a>");
        }
        else {
            ar.writeHtml(cleanName);
        }
    }

    public void setDisabled(boolean val) {
        disabled = val;
    }

    public boolean getDisabled() {
        return disabled;
    }




    //////////////////// PERSONAL WORKSPACE SETTINGS /////////////////

    public boolean isWatch(String siteWorkspaceCombo)  throws Exception  {
        JSONObject setting = assureSettings(siteWorkspaceCombo);
        if (setting.has("isWatching")) {
            return setting.getBoolean("isWatching");
        }
        return false;
    }


    /**
    * If the user is watching this page, then this returns the
    * time that the page was last seen, otherwise returns
    * zero if the user does not have a subscription.
    */
    public long watchTime(String siteWorkspaceCombo) throws Exception {
        JSONObject setting = assureSettings(siteWorkspaceCombo);
        if (setting.has("reviewTime")) {
            return setting.getLong("reviewTime");
        }
        return 0;
    }

    /**
    * Returns a vector of WatchRecord objects.
    * Do not modify this vector externally, just read only.
    */
    public List<WatchRecord> getWatchList()  throws Exception {
        List<WatchRecord> watchList = new ArrayList<WatchRecord>();
        for(String siteWorkspaceCombo : wsSettings.keySet()) {
            JSONObject setting = wsSettings.getJSONObject(siteWorkspaceCombo);
            if (setting.has("isWatching") && setting.getBoolean("isWatching")) {
                watchList.add(new WatchRecord(siteWorkspaceCombo, setting.optLong("reviewTime", 0)));
            }
        }
        return watchList;
    }



    /**
    * Create or update a watch on a page.
    * the page key specifies the page.
    * The long value is the time of "last seen" which will be
    * used to determine if the page has changed since that time.
    */
    public void setWatch(String siteWorkspaceCombo) throws Exception {
        JSONObject setting = assureSettings(siteWorkspaceCombo);
        setting.put("isWatching", true);
    }

    public void setReviewTime(String siteWorkspaceCombo, long reviewTime) throws Exception {
        JSONObject setting = assureSettings(siteWorkspaceCombo);
        setting.put("isWatching", true);
        setting.put("reviewTime", reviewTime);
    }

    /**
    * Create a watch on a page.
    * if none exists at this time.
    */
    public void assureWatch(String siteWorkspaceCombo) throws Exception {
        if (siteWorkspaceCombo.indexOf("|")<0) {
            throw new Exception("assureWatch requires a combined key of the form: (site) | (workspace)");
        }
        if (!isWatch(siteWorkspaceCombo)) {
            setReviewTime( siteWorkspaceCombo, System.currentTimeMillis());
        }
    }

    /**
    * Get rid of any watch of the specified page -- if there is any.
    */
    public void clearWatch(String siteWorkspaceCombo)  throws Exception {
        JSONObject setting = assureSettings(siteWorkspaceCombo);
        setting.remove("isWatching");
        setting.remove("reviewTime");
    }


    /**
     * Returns a vector of keys of pages in the notify list.
     * Do not modify this vector externally, just read only.
     */
     public List<String> getNotificationList() throws Exception {
         List<String> notifyList = new ArrayList<String>();
         for(String siteWorkspaceCombo : wsSettings.keySet()) {
             JSONObject setting = wsSettings.getJSONObject(siteWorkspaceCombo);
             if (setting.has("isNotify") && setting.getBoolean("isNotify")) {
                 notifyList.add(siteWorkspaceCombo);
             }
         }
         return notifyList;
     }


     /**
     * Create or update a notification on a page.
     * the page key specifies the page.
     * The long value is the time of "last seen" which will be
     * used to determine if the page has changed since that time.
     */
    public boolean isNotifiedForProject(String siteWorkspaceCombo) throws Exception {
        JSONObject setting = assureSettings(siteWorkspaceCombo);
        if (setting.has("isNotify")) {
            return setting.getBoolean("isNotify");
        }
        return false;
    }
    public void setNotification(String siteWorkspaceCombo) throws Exception {
        JSONObject setting = assureSettings(siteWorkspaceCombo);
        setting.put("isNotify", true);
    }
    public void clearNotification(String siteWorkspaceCombo) throws Exception {
        JSONObject setting = assureSettings(siteWorkspaceCombo);
        setting.remove("isNotify");
    }
    public void setNotification(String siteWorkspaceCombo, boolean val) throws Exception {
        if (val) {
            setNotification(siteWorkspaceCombo);
        }
        else {
            clearNotification(siteWorkspaceCombo);
        }
    }

    


    /**
    * Preferred email is where all the notifications to this user will be sent.
    * Should be set to a valid email address that has already been proven
    * to belong to the user.  (Don't let the user just type in any email
    * address here!)
    */
    public String getPreferredEmail() {
        //return the first email address ... if there is one
        for (String idval : emailAddresses) {
            //an at sign in there, and no slashes, could be an email address
            if (idval.indexOf("@")>=0 && idval.indexOf("/")<0) {
                return idval;
            }
        }
        return null;
    }
    public void setPreferredEmail(String newAddress) {
        ArrayList<String> newList = new ArrayList<String>();
        newList.add(newAddress);
        for (String idval : emailAddresses) {
            if (!idval.equalsIgnoreCase(newAddress)) {
                newList.add(idval);
            }
        }
        emailAddresses = newList;
    }



    public String getImage() {
        return (this.getKey()+".jpg").toLowerCase();
    }

    /*
    * The purpose of this function is to be able to find all the users with
    * a given fragment.  As people enter a name, we want to look up quickly
    * all the users that have that string as part of their name or address.
    * This method is how you ask a user object if their name, or one of their
    * addresses matches the search string.
    */
    public boolean hasAddressMatchingFrag(String frag){
        if (name.toLowerCase().contains(frag)) {
            return true;
        }
        for (String idval : emailAddresses) {
            if(idval.toLowerCase().contains(frag)){
                return true;
            }
        }
        return false;
    }

    public void setAccessCode(String newAccessCode) throws Exception {
        accessCode = newAccessCode;
        accessCodeModTime = System.currentTimeMillis();
    }

    public String getAccessCode()throws Exception
    {
        long max_days = 1;
        long days_diff = UtilityMethods.getDurationInDays(System.currentTimeMillis(),accessCodeModTime);
        if( (accessCode == null || accessCode.length() == 0) || days_diff > max_days){
            setAccessCode(IdGenerator.generateKey());
        }
        return accessCode;
    }

    public UserPage getUserPage() throws Exception {
        return UserManager.getStaticUserManager().findOrCreateUserPage(userKey);
    }

    public List<NGBook> findAllMemberSites() throws Exception {
        List<NGBook> memberOfSites=new ArrayList<NGBook>();
        for (NGBook aBook : NGBook.getAllSites()) {
            if (aBook.primaryOrSecondaryPermission(this)) {
                memberOfSites.add(aBook);
            }
        }
        return memberOfSites;
    }

    public String getTimeZone() {
        return timeZone;
    }
    
    public JSONArray getAllEmailAddresses() {
        JSONArray idArray = new JSONArray();
        for (String id : emailAddresses) {
            idArray.put(id);
        }
        return idArray;
    }

    public JSONObject getJSON() throws Exception {
        JSONObject jObj = new JSONObject();
        jObj.put("name", getName());
        jObj.put("uid", getUniversalId());
        jObj.put("key", getKey());
        return jObj;
    }

    public JSONObject getFullJSON() throws Exception {
        JSONObject jObj = getJSON();
        jObj.put("lastLogin",   lastLogin);
        jObj.put("lastLoginId", getLastLoginId());
        jObj.put("lastUpdated", lastUpdated);
        jObj.put("description", getDescription());
        jObj.put("disabled",    getDisabled());
        jObj.put("notifyPeriod",getNotificationPeriod());
        jObj.put("preferred",   getPreferredEmail());
        jObj.put("timeZone",    timeZone);

        jObj.put("image",       getImage());
        jObj.put("ids",         getAllEmailAddresses());

        jObj.put("wsSettings",  wsSettings);
        jObj.put("isFacilitator", isFacilitator);
        jObj.put("useNewUI",    useNewUI);
        return jObj;
    }

    /**
     * This should be used only for saving to a local file, never sending to a client.
     */
    public JSONObject getSecretJSON() throws Exception {
        JSONObject jObj = getFullJSON();
        jObj.put("licenseToken",       getLicenseToken());
        jObj.put("notifyTime",         notifyTime);
        jObj.put("accessCode",         accessCode);
        jObj.put("accessCodeModTime",  accessCodeModTime);
        return jObj;
    }


    public void updateFromJSON(JSONObject input) throws Exception {
        if (input.has("removeId")) {
            if (emailAddresses.size()<=1) {
                throw new Exception("Can not remove an id from user who only has less than two ids!");
            }
            this.removeId(input.getString("removeId"));
        }
        if (input.has("description")) {
            this.setDescription(input.getString("description"));
        }
        if (input.has("name")) {
            this.setName(input.getString("name"));
        }
        if (input.has("notifyPeriod")) {
            this.setNotificationPeriod(input.getInt("notifyPeriod"));
        }
        if (input.has("disabled")) {
            this.setDisabled(input.getBoolean("disabled"));
        }
        if (input.has("preferred")) {
            String newPref = input.getString("preferred");
            //have to properly add it in case it is not already there
            //does nothing if already there
            this.addId(newPref);
            //this makes sure it is first
            this.setPreferredEmail(newPref);
        }
        if (input.has("timeZone")) {
            timeZone = input.getString("timeZone");
        }
        if (input.has("isFacilitator")) {
            isFacilitator = input.getBoolean("isFacilitator");
        }
        if (input.has("useNewUI")) {
            useNewUI = input.getBoolean("useNewUI");
        }
    }

    /**
     * Each user specifies a time zone.
     * @return the Calendar object for the time zone specified by the user
     *         or the default time zone (from the server) if the user has
     *         not specified a time zone.
     */
    public Calendar getCalendar() {
        String tzid = getTimeZone();
        if (tzid==null || tzid.length()==0) {
            //this is the default calendar for the server environment
            return Calendar.getInstance();
        }
        TimeZone tz = TimeZone.getTimeZone(tzid);
        return Calendar.getInstance(tz);
    }


    /**
     * This use can and has indicated that they want to receive email that is
     * FROM the person who initiated the action.   If FALSE, then all email
     * sent to this person should be from the global Weaver email address.
     *
     * Some users have spam filters that remove email without telling them
     * that the email has been removed.  Sometimes the email servers between
     * the sender and the receiver will check to see if the sending email
     * server is capable of actually sending to the user mentioned in the
     * from address.  Thus when Weaver sends an email address from a particular
     * user such as alix@example.com and Weaver itself is not at example.com,
     * those email messages can be filtered out.   This depends on a user
     * by user basis as to whether they can receive these or not.
     *
     * So this flag allows us to track users who have indicated that they would
     * like the from address of the REAL user.
     *
     * Initial implementation: return false until we track people opting in.
     */
    public boolean canAcceptRealUserFromAddress() {
        return false;
    }


    // someday this can be rewritten to store as a record for all the settings
    // for a given workspace together instead of in four separate lists.
    public JSONObject getWorkspaceSettings(String siteWorkspaceCombo) throws Exception {
        JSONObject res = this.assureSettings(siteWorkspaceCombo);
        return res;
    }
    
    //fast access to whether they are a facilitator for listing, etc.
    public boolean isFacilitator() {
        return isFacilitator;
    }
    public void setFacilitator(boolean isNow) {
        isFacilitator = isNow;
    }

    public boolean hasLoggedIn() {
        return (getLastLogin() > 100000);
    }
}
