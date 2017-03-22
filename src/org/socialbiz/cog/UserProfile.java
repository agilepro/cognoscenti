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
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;

public class UserProfile implements UserRef
{
    private String key = "";
    private String name = "";
    private String description;
    private String image;
    private String licenseToken;
    private long   lastLogin;
    private String lastLoginId;
    private long   lastUpdated;
    private long   notificationTime;
    private String accessCode;
    private long   accessCodeModTime;
    private int    notificationPeriod;
    private boolean disabled;
    private List<String> ids = null;
    private List<WatchRecord> watchList = null;
    private List<String> notificationList = null;
    private List<String> templateList = null;

    public UserProfile(String guid) throws Exception {
        key = IdGenerator.generateKey();
        ids = new ArrayList<String>();
        ids.add(guid);
        watchList = new ArrayList<WatchRecord>();
        notificationList = new ArrayList<String>();
        templateList = new ArrayList<String>();
        
        //make sure that this profile has a license token
        getLicenseToken();
    }
    
    
    public UserProfile(UserProfileXML upXML) throws Exception {
        key = upXML.getKey();

        //consistency check here
        if (key == null || key.length() == 0)  {
            key = IdGenerator.generateKey();
        }
        
        name = upXML.getName();
        description = upXML.getDescription();
        image = upXML.getImage();
        licenseToken = upXML.getLicenseToken();
        
        lastLogin   = upXML.getLastLogin();
        lastLoginId = upXML.getLastLoginId();
        lastUpdated = upXML.getLastUpdated();
        notificationTime = upXML.getNotificationTime();
        
        accessCode = upXML.getAccessCode();
        accessCodeModTime = upXML.getAccessCodeModTime();
        notificationPeriod = upXML.getNotificationPeriod();
        disabled   = upXML.getDisabled();
        ids        = upXML.getIdList();

        watchList = upXML.getWatchList();
        notificationList = upXML.getNotificationList();
        templateList = upXML.getTemplateList();
        
        //make sure that this profile has a license token
        getLicenseToken();
    }
    
    public void transferAllValues(UserProfileXML upXML) throws Exception {
        upXML.setKey(key);
        upXML.setName(name);
        upXML.setDescription(description);
        upXML.setImage(image);
        upXML.setLicenseToken(licenseToken);
        
        upXML.setLastLogin(lastLogin, lastLoginId);
        upXML.setLastUpdated(lastUpdated);
        upXML.setNotificationTime(notificationTime);
        
        upXML.setAccessCode(accessCode);
        upXML.setAccessCodeModTime(accessCodeModTime);
        upXML.setNotificationPeriod(notificationPeriod);
        upXML.setDisabled(disabled);
        for (String oneId : ids) {
            upXML.addId(oneId);
        }

        for (WatchRecord wr : watchList) {
            upXML.addWatch(wr.pageKey, wr.lastSeen);
        }
        for (String note : notificationList) {
            upXML.addNotification(note);
        }
        for (String temper : templateList) {
            upXML.addTemplate(temper);
        }
    }

    
    public List<String> getAllIds() {
        List<String> retVal = new ArrayList<String> ();
        for (String anId : ids) {
            retVal.add(anId);
        }
        return retVal;
    }



    /**
    * This should be unique and internal, so .... not
    * sure why it would ever need to be set.
    */
    public void setKey(String nkey) {
        key = nkey;
    }

    /**
    * The key is a unique identifier on this server for a particular user.
    * Never forget that this is NOT a global identifier that is useful on
    * any other server.  The email address, and open id, are global identifiers
    * that can be transferred across servers, but the KEY is a key only on this
    * server.
    */
    public String getKey() {
        return key;
    }

    public void setName(String newName) {
        name = newName;
    }
    public String getName() {
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
    public void addId(String newId)
        throws Exception
    {
        if (newId.indexOf(" ")>=0) {
            throw new ProgramLogicError("an id value with a space in it was passed to UserProfile.addID: ("+newId+")");
        }

        //check if this user already has the ID, and do nothing if true
        for (String idval : ids) {
            if (newId.equalsIgnoreCase(idval)) {
                //nothing to do, there is already an ID in there
                return;
            }
        }

        UserProfile otherUser = UserManager.findUserByAnyId(newId);
        while (otherUser!=null) {
            //user could be found because this is an email, openid, key or name of that user
            //if it is email or openid we can remove it.
            List<String> listid = otherUser.getAllIds();
            String foundId = null;
            for (String oid : listid) {
                //loop through all IDS and clear them out.
                //remember, there may be more than one match
                if (oid.equalsIgnoreCase(newId)) {
                    foundId = oid;
                    break;
                }
            }

            if (foundId==null) {
                //if the other user was retrieved, but it was NOT an email or openid
                //it might be that you are trying to add a key or user name as another
                //users id, and that can not be supported.  Throw an error.
                throw new NGException("nugen.exception.user.conflicts", new Object[]{newId, otherUser.getName(),otherUser.getKey()});
            }

            //found at least one on this user, remove it.
            otherUser.removeId(foundId);

            //are there any more users with this ID?
            otherUser = UserManager.findUserByAnyId(newId);
        }
        ids.add(newId);
    }

    /**
    * Removes the id from the profile.
    * If no ID like that exists, then it does nothing, no error.
    * If duplicates exist, removes all of them.
    * If newId equals preferred Email then it clears that.
    * NOTE: this can leave the profile without any id.
    */
    public void removeId(String newId) throws Exception {
        Vector<String> cache = new Vector<String>();
        for (String possible : ids) {
            if (!possible.equalsIgnoreCase(newId)) {
                cache.add(possible);
            }
        }
        ids = cache;
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
        return lastLoginId;
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
        notificationPeriod = period;
    }
    public int getNotificationPeriod() {
        if (notificationPeriod<=0) {
            notificationPeriod=1;
        }
        return notificationPeriod;
    }



    public void setNotificationTime(long time) {
        notificationTime = time;
    }
    public long getNotificationTime() {
        return notificationTime;
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
        for (String idval : ids) {
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
        if (testId.equalsIgnoreCase(key)) {
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

    /**
    * compares two openid values properly
    */
    public static boolean equalsOpenId(String openId1, String openId2)
    {
        //if either value passed is null, then it never matches the other
        //(even if they are both null)
        if (openId1==null || openId2==null)
        {
            return false;
        }
        return IDRecord.simplifyOpenId(openId1).equalsIgnoreCase(IDRecord.simplifyOpenId(openId2));
    }

    public AddressListEntry getAddressListEntry() {
        return new AddressListEntry(this);
    }

    public static void writeLink(AuthRequest ar, String anyId)
        throws Exception
    {
        if (anyId==null || anyId.length()==0)
        {
            //TODO: this should be translateable
            ar.write("Unknown User");
            return;
        }
        AddressListEntry ale = new AddressListEntry(anyId);
        ale.writeLink(ar);
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
        return "v/FindPerson.htm?uid="+URLEncoder.encode(getUniversalId(), "UTF-8");
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
        String olink = "v/FindPerson.htm?uid="+URLEncoder.encode(getUniversalId(), "UTF-8");
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



    public boolean isWatch(String pageKey)  throws Exception  {
        for (WatchRecord sr : getWatchList())  {
            if (pageKey.equals(sr.pageKey)) {
                return true;
            }
        }
        return false;
    }


    /**
    * If the user is watching this page, then this returns the
    * time that the page was last seen, otherwise returns
    * zero if the user does not have a subscription.
    */
    public long watchTime(String pageKey) throws Exception {
        for (WatchRecord wr : watchList) {
            if (pageKey.equals(wr.pageKey)) {
                return wr.lastSeen;
            }
        }
        return 0;
    }

    /**
    * Returns a vector of WatchRecord objects.
    * Do not modify this vector externally, just read only.
    */
    public List<WatchRecord> getWatchList()  throws Exception {
        return watchList;
    }



    /**
    * Create or update a watch on a page.
    * the page key specifies the page.
    * The long value is the time of "last seen" which will be
    * used to determine if the page has changed since that time.
    */
    public void setWatch(String pageKey, long now) throws Exception {
        for (WatchRecord sr : watchList) {
            if (pageKey.equals(sr.pageKey)) {
                sr.lastSeen = now;
                return;
            }
        }
        watchList.add(new WatchRecord(pageKey, now));
    }

    /**
    * Create a watch on a page.
    * if none exists at this time.
    */
    public void assureWatch(String pageKey) throws Exception {
        if (!isWatch(pageKey)) {
            setWatch( pageKey, System.currentTimeMillis());
        }
    }

    /**
    * Get rid of any watch of the specified page -- if there is any.
    */
    public void clearWatch(String pageKey)  throws Exception {
        watchList.clear();
    }


    /**
     * Get rid of any notification of the specified page.
     */
    public void clearAllNotifications() throws Exception {
        notificationList.clear();
    }

    /**
     * Returns a vector of keys of pages in the notify list.
     * Do not modify this vector externally, just read only.
     */
     public List<String> getNotificationList() throws Exception {
         return notificationList;
     }


     /**
     * Create or update a notification on a page.
     * the page key specifies the page.
     * The long value is the time of "last seen" which will be
     * used to determine if the page has changed since that time.
     */
    public void setNotification(String pageKey)
        throws Exception
    {
        for (String sr : notificationList) {
            if (pageKey.equals(sr)) {
                //already have a record for this page
                return;
            }
        }
        notificationList.add(pageKey);
    }

     /**
      * Get rid of any notification of the specified page.
      */
    public void clearNotification(String pageKey) throws Exception {
        ArrayList<String> cache = new ArrayList<String>();
        for (String noteItem : notificationList) {
            if (!pageKey.equals(noteItem)) {
                cache.add(noteItem);
            }
        }
        notificationList = cache;
    }


    public boolean isNotifiedForProject(String pageKey) throws Exception {
        for (String sr : notificationList) {
            if (pageKey.equals(sr)) {
                return true;
            }
        }
        return false;
    }

    public void setDisabled(boolean val) {
        disabled = val;
    }

    public boolean getDisabled() {
        return disabled;
    }


    public List<String> getTemplateList() throws Exception {
        return templateList;
    }

    public void setProjectAsTemplate(String pageKey) throws Exception {
        templateList.add(pageKey);
    }

    public boolean isTemplate(String pageKey) throws Exception {
        for (String templatePageKey : templateList) {
            if (pageKey.equals(templatePageKey)) {
                return true;
            }
        }
        return false;
    }
    
    
    public void removeTemplateRecord(String pageKey) throws Exception {
        ArrayList<String> cache = new ArrayList<String>();
        for (String templatePageKey : templateList) {
            if (!pageKey.equalsIgnoreCase(templatePageKey)) {
                cache.add(templatePageKey);
            }
        }
        templateList = cache;
    }

    /**
     * returns the NGPageIndex entries for each project template, but
     * only if that key matches a project that still exists.
     * Invalid template list entries are ignored.
     */
    public Vector<NGPageIndex> getValidTemplates(Cognoscenti cog) throws Exception {
        Vector<NGPageIndex> templates = new Vector<NGPageIndex>();
        for(String pageKey : templateList) {
            NGPageIndex ngpi = cog.getContainerIndexByKey(pageKey);
            if (ngpi!=null) {
                //silently ignore templates that no longer exist
                templates.add(ngpi);
            }
        }
        NGPageIndex.sortInverseChronological(templates);
        return templates;
    }

    /**
    * Preferred email is where all the notifications to this user will be sent.
    * Should be set to a valid email address that has already been proven
    * to belong to the user.  (Don't let the user just type in any email
    * address here!)
    */
    public String getPreferredEmail() {
        //return the first email address ... if there is one
        for (String idval : ids) {
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
        for (String idval : ids) {
            if (!idval.equalsIgnoreCase(newAddress)) {
                newList.add(idval);
            }
        }
        ids = newList;
    }

    /**
    * returns a properly formatted SMTP user name with email
    * address together as one string.
    */
    public String getEmailWithName() {
        StringBuffer sb = new StringBuffer();

        String baseName = getName();
        int last = baseName.length();
        for (int i=0; i<last; i++) {
            char ch = baseName.charAt(i);
            if ( (ch>='0' && ch<='9') || (ch>='A' && ch<='Z') || (ch>='a' && ch<='z') || (ch==' ')) {
                sb.append(ch);
            }
        }

        sb.append(" <");
        sb.append(getPreferredEmail());
        sb.append(">");
        return sb.toString();
    }




    public String getImage() {
        return image;
    }
    public void setImage(String newImage) {
        image = newImage;
    }

    /**
     * Check to see if the user has an image.  If so, leave it there,
     * if not, then copy one of the default images for this user.
     */
    public void assureImage(Cognoscenti cog) throws Exception {
        File imageFolder = cog.getConfig().getFileFromRoot("users");
        if (!imageFolder.exists()) {
            throw new Exception("Can't find the user folder!: "+imageFolder);
        }
        File imageFile = new File(imageFolder, getKey()+".jpg");
        if (imageFile.exists()) {
            return;
        }
        char uidLetter = this.getUniversalId().charAt(0);
        File defaultFile =  new File(imageFolder, "fake-"+uidLetter+".jpg");
        if (!defaultFile.exists()) {
            throw new Exception("The default user image file is missing!: "+defaultFile);
        }
        UtilityMethods.copyFileContents(defaultFile, imageFile);
        System.out.println("Created a default image file for user "+getKey()+" from: "+defaultFile);
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
        for (String idval : ids) {
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
        return UserManager.getStaticUserManager().findOrCreateUserPage(key);
    }

    public List<NGBook> findAllMemberSites() throws Exception {
        List<NGBook> memberOfSites=new ArrayList<NGBook>();
        for (NGBook aBook : NGBook.getAllSites()){
            if (aBook.primaryOrSecondaryPermission(this)) {
                memberOfSites.add(aBook);
            }
        }
        return memberOfSites;
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
        
        jObj.put("image",       this.getImage());
        
        {
            JSONArray idArray = new JSONArray();
            for (String id : ids) {
                idArray.put(id);
            }
            jObj.put("ids", idArray);
        }
        {
            JSONArray watchArray = new JSONArray();
            for (WatchRecord watch : getWatchList()) {
                JSONObject watchRec = new JSONObject();
                watchRec.put("key",watch.pageKey);
                watchRec.put("lastSeen",watch.lastSeen);
                watchArray.put(watchRec);
            }
            jObj.put("watchList", watchArray);
        }
        {
            JSONArray notifyArray = new JSONArray();
            for (String note : notificationList) {
                notifyArray.put(note);
            }
            jObj.put("notifyList", notifyArray);
        }
        {
            JSONArray tempArray = new JSONArray();
            for (String temp : getTemplateList()) {
                tempArray.put(temp);
            }
            jObj.put("templateList", tempArray);
        }
        return jObj;
    }

    public void updateFromJSON(JSONObject input) throws Exception {
        if (input.has("removeId")) {
            if (ids.size()<=1) {
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
    }
    
}
