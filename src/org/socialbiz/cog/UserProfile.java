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
import java.util.Iterator;
import java.util.List;
import java.util.Vector;

import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.workcast.json.JSONObject;

public class UserProfile extends DOMFace implements UserRef
{
    private String key = "";
    private String name = "";
    private long lastLogin;
    private long lastUpdated;
    private ValueElement[] favorites = null;
    private List<IDRecord> ids = null;
    private List<WatchRecord> watchList = null;
    private List<NotificationRecord> notificationList = null;
    private List<TemplateRecord> templateList = null;

    public UserProfile(Document doc, Element upEle, DOMFace p)
        throws Exception
    {
        super(doc,upEle,p);
        key = upEle.getAttribute("id");

        //consistency check here
        if (key == null || key.length() == 0)
        {
            key = IdGenerator.generateKey();
            upEle.setAttribute("id", key);
        }
        ids = new ArrayList<IDRecord>();

        IDRecord.findIDRecords(this, ids);

        // upgrade to using an IDRecord for holding openid, in case
        // there are any old files around with "userid"
        String uopenid = getScalar("userid");
        if (uopenid!=null && uopenid.length()>0)
        {
            //need to convert this user
            //first remove the old tag
            removeAllNamedChild("userid");
            IDRecord newId = IDRecord.createIDRecord(this, uopenid);
            ids.add(newId);
        }
        String email = getScalar("email");
        if (email!=null && email.length()>0)
        {
            //need to convert this user
            //first remove the old tag
            removeAllNamedChild("email");
            IDRecord newId = IDRecord.createIDRecord(this, email);
            ids.add(newId);
        }

        IDRecord.sortByType(ids);

        name = getScalar("name");
        lastLogin   = safeConvertLong(getScalar("lastlogin"));
        lastUpdated = safeConvertLong(getScalar("lastupdated"));

        //make sure that this profile has a license token
        String token = getLicenseToken();
        if (token==null || token.length()==0) {
            genNewLicenseToken();
        }
    }

    public List<IDRecord> getIdList()
    {
        List<IDRecord> retVal = new ArrayList<IDRecord> ();
        for (IDRecord anId : ids)
        {
            retVal.add(anId);
        }
        return retVal;
    }
    public List<String> getEmailList()
    {
        List<String> retVal = new ArrayList<String> ();
        for (IDRecord anId : ids)
        {
            if (anId.isEmail())
            {
                retVal.add(anId.getLoginId());
            }
        }
        return retVal;
    }


    /**
    * gets the first open id in the list.
    * This is rather arbitrary, and should not be used.
    * use getUniversalId instead.
    */
    public String getOpenId()
    {
        for (IDRecord possible : ids)
        {
            String idval = possible.getLoginId();
            if (idval.indexOf("@")<0)
            {
                return idval;
            }
        }
        return null;
    }




    /**
    * This should be unique and internal, so .... not
    * sure why it would ever need to be set.
    */
    public void setKey(String nkey)
    {
        key = nkey;
        setAttribute("id", key);
    }

    /**
    * The key is a unique identifier on this server for a particular user.
    * Never forget that this is NOT a global identifier that is useful on
    * any other server.  The email address, and open id, are global identifiers
    * that can be transferred across servers, but the KEY is a key only on this
    * server.
    */
    public String getKey()
    {
        return key;
    }

    public void setName(String newName)
    {
        if (newName == null)
        {
            newName = "";
        }
        if (!newName.equals(name))
        {
            name = newName;
            setScalar("name", newName);
        }
    }

    public String getName()
    {
        return name;
    }


    public void setDescription(String newDesc)
    {
        setScalar("description", newDesc);
    }

    public String getDescription()
    {
        return getScalar("description");
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
        String simplifiedId = IDRecord.simplifyOpenId(newId);
        for (IDRecord possible : ids)
        {
            String idval = possible.getLoginId();
            if (newId.equalsIgnoreCase(idval) ||
                simplifiedId.equalsIgnoreCase(IDRecord.simplifyOpenId(idval)))
            {
                //nothing to do, there is already an ID in there
                return;
            }
        }

        UserProfile otherUser = UserManager.findUserByAnyId(newId);
        while (otherUser!=null) {
            //user could be found because this is an email, openid, key or name of that user
            //if it is email or openid we can remove it.
            List<IDRecord> listid = otherUser.getIdList();
            IDRecord foundId = null;
            for (IDRecord oid : listid) {
                //loop through all IDS and clear them out.
                //remember, there may be more than one match
                if (oid.equalsId(newId)) {
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
            otherUser.removeId(foundId.getLoginId());

            //are there any more users with this ID?
            otherUser = UserManager.findUserByAnyId(newId);
        }

        IDRecord newIdRec = IDRecord.createIDRecord(this, newId);
        ids.add(newIdRec);
        IDRecord.sortByType(ids);
    }

    /**
    * Removes the id from the profile.
    * If no ID like that exists, then it does nothing, no error.
    * If duplicates exist, removes all of them.
    * If newId equals preferred Email then it clears that.
    */
    public void removeId(String newId)
        throws Exception
    {
        if (newId.equals(getPreferredEmail()))
        {
            setScalar("prefEmail", null);
        }

        //first iterate and find all the ID records that match
        Vector<IDRecord> found = new Vector<IDRecord>();
        for (IDRecord possible : ids)
        {
            if (possible.equalsId(newId))
            {
                found.add(possible);
            }
        }

        //then actually remove them from the collections
        for (IDRecord example : found) {
            ids.remove(example);
            example.removeIDRecord(this);
        }

    }

    public void setLastLogin(long newLastLogin, String loginId)
    {
        if (lastLogin != newLastLogin)
        {
            lastLogin = newLastLogin;
            setScalar("lastlogin", Long.toString(newLastLogin));
            setScalar("lastloginid", loginId);
        }
    }

    public long getLastLogin()
    {
        return this.lastLogin;
    }

    /**
    * Since a user can log in wiht more than one id, this records the
    * id that was used for the last actual login, so that this can be
    * used as a prompt for logging in (stored in cookies).
    */
    public String getLastLoginId()
    {
        String retval = getScalar("lastloginid");

        //migration code ... Remove after Feb 2010
        //if the user has not logged in since adding this method
        //then there will be no last id set, and return instead the best id, which is
        //what was being used before...
        if (retval == null)
        {
            retval = getUniversalId();
        }
        return retval;
    }

    public void setLastUpdated(long newLastUpdated)
    {
        if (lastUpdated != newLastUpdated)
        {
            lastUpdated = newLastUpdated;
            setScalar("lastupdated", Long.toString(newLastUpdated));
        }
    }

    public long getLastUpdated()
    {
        return this.lastUpdated;
    }

    public void setFavorites(ValueElement[] newFavorites)
    {
        if (favorites==null)
        {
            getFavorites();
        }

        //try to detect if they are the same to avoid thrashing memory
        boolean isSame = (newFavorites.length==favorites.length);
        if (isSame)
        {
            for (int i=0; i<favorites.length; i++)
            {
                ValueElement oldone = favorites[i];
                ValueElement newone = newFavorites[i];
                if (!oldone.name.equals(newone.name))
                {
                    isSame = false;
                }
                if (!oldone.value.equals(newone.value))
                {
                    isSame = false;
                }
            }
        }
        if (isSame)
        {
            return; //nothing to do, no change
        }

        favorites = newFavorites;

        Element favsEle = DOMUtils.getChildElement(fEle, "favorites");
        fEle.removeChild(favsEle);
        favsEle = DOMUtils.createChildElement(fDoc, fEle, "favorites");
        DOMUtils.removeAllChildren(favsEle);

        for (int i=0; i<favorites.length; i++)
        {
            Element favEle = DOMUtils.createChildElement(fDoc, favsEle, "favorite");
            favEle.setAttribute("name", favorites[i].name);
            favEle.setAttribute("address", favorites[i].value);
        }

        //DEBUG: double check that it got it right
        favorites = null;  //remove the cache, get favorites will parse again
        ValueElement[] testSet = getFavorites();

        if (newFavorites.length != testSet.length)
        {
            throw new RuntimeException("Tried to set '"+newFavorites.length+"' value, but ended up with '"+testSet.length+"' values.");
        }
    }

    public ValueElement[] getFavorites()
    {
        if (favorites==null)
        {
            //parse now, because we have not parsed yet
            Element favsEle = DOMUtils.getOrCreateChild(fDoc, fEle, "favorites");
            Vector<ValueElement> favsVect = new Vector<ValueElement>();
            for (Element favEle : DOMUtils.getChildElementsList(favsEle)) {
                ValueElement ve = new ValueElement(favEle.getAttribute("name"), favEle.getAttribute("address"));
                favsVect.add(ve);
            }
            favorites = new ValueElement[favsVect.size()];
            favsVect.copyInto(favorites);
        }

        return favorites;
    }

    public void setHomePage(String newHomePage) {
        setScalar("homepage", newHomePage);
    }
    public String getHomePage() {
        return getScalar("homepage");
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
        if (period<=0) {
            period=1;
        }
        setAttributeInt("notificationPeriod", period);
    }
    public int getNotificationPeriod() {
        int period = getAttributeInt("notificationPeriod");
        if (period<=0) {
            period=1;
        }
        return period;
    }


    public void setNotificationTime(long period) {
        setAttributeLong("notificationTime", period);
    }
    public long getNotificationTime() {
        return getAttributeLong("notificationTime");
    }


    /**
    * The magic number is set when the user makes a request for a password.
    * The magic number is sent to the user in the hyper link.
    * Then, a request to register a new password MUST have that same magic
    * number in it, in order to prove that we really sent the email message.
    * Magic number should be used ONLY ONCE, and cleared after use.
    */
    public void setMagicNumber(String magicnumber)
    {
        setScalar("magicnumber", magicnumber);
    }
    public String getMagicNumber()
    {
        return getScalar("magicnumber");
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
        setScalar("licensetoken", IdGenerator.generateKey());
    }
    public String getLicenseToken() {
        return getScalar("licensetoken");
    }

    public String toString()
    {
        StringBuffer sb = new StringBuffer();
        sb.append("\nName : ");
        sb.append(name);
        // add rest of the fields.
        return sb.toString();
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
    public boolean hasAnyId(String testId)
    {
        String simplifiedId = IDRecord.simplifyOpenId(testId);
        for (IDRecord possible : ids)
        {
            String idval = possible.getLoginId();
            if (testId.equalsIgnoreCase(idval) || simplifiedId.equalsIgnoreCase(IDRecord.simplifyOpenId(idval)))
            {
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
        if (testId.equalsIgnoreCase(name))
        {
            return true;
        }

        //also test the internal randomly generated key. Nobody has a key that is
        //exactly like someone else's email address.  If someone purposefully tries
        //to name themselves as someone else key, they will be chosen only
        //if there is nobody else with that email address.
        if (testId.equalsIgnoreCase(key))
        {
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
            //TODO: this chould be translateable
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
        if (usable==null || usable.length()==0)
        {
            usable = getOpenId();
            if (usable==null || usable.length()==0)
            {
                // not sure what to do here.  Profile is not valid without any ids
                // but key should work in most places it is needed.  Not universal
                // but it is unique on this site at least
                return getKey();
            }
        }
        return usable;
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
            if (pageKey.equals(sr.getPageKey())) {
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
        if (watchList == null) {
            getWatchList();
        }
        for (WatchRecord sr : watchList) {
            if (pageKey.equals(sr.getPageKey())) {
                return sr.getLastSeen();
            }
        }
        return 0;
    }

    /**
    * Returns a vector of WatchRecord objects.
    * Do not modify this vector externally, just read only.
    */
    public List<WatchRecord> getWatchList()  throws Exception {
        if (watchList == null) {
            watchList = new Vector<WatchRecord>();
            WatchRecord.findWatchRecord(this, watchList);
        }
        return watchList;
    }



    /**
    * Create or update a watch on a page.
    * the page key specifies the page.
    * The long value is the time of "last seen" which will be
    * used to determine if the page has changed since that time.
    */
    public void setWatch(String pageKey, long now) throws Exception {
        if (watchList == null) {
            getWatchList();
        }
        for (WatchRecord sr : watchList) {
            if (pageKey.equals(sr.getPageKey())) {
                sr.setLastSeen(now);
                return;
            }
        }

        //if none are found, then create one
        WatchRecord sr = WatchRecord.createWatchRecord(this, pageKey, now);
        watchList.add(sr);
    }

    /**
    * Get rid of any watch of the specified page -- if there is any.
    */
    public void clearWatch(String pageKey)  throws Exception {
        for (WatchRecord sr : getWatchList()) {
            if (pageKey.equals(sr.getPageKey())) {
                sr.removeWatchRecord(this);
                watchList.remove(sr);
                break;
            }
        }
    }


    /**
     * Get rid of any notification of the specified page.
     */
    public void clearAllNotifications() throws Exception {
        if (notificationList == null) {
            getNotificationList();
        }
        for (NotificationRecord sr : notificationList) {
            removeChild(sr);
        }
        notificationList.clear();
    }

    /**
     * Returns a vector of NotificationRecord objects.
     * Do not modify this vector externally, just read only.
     */
     public List<NotificationRecord> getNotificationList() throws Exception {
         if (notificationList == null) {
             notificationList = getChildren("notification", NotificationRecord.class);
         }
         return notificationList;
     }


     /**
     * Create or update a notification on a page.
     * the page key specifies the page.
     * The long value is the time of "last seen" which will be
     * used to determine if the page has changed since that time.
     */
    public void setNotification(String pageKey, long now)
        throws Exception
    {
        if (notificationList == null)
        {
            getNotificationList();
        }
        for (NotificationRecord sr : notificationList)
        {
            if (pageKey.equals(sr.getPageKey()))
            {
                //already have a record for this page
                return;
            }
        }
        NotificationRecord sr = NotificationRecord.createNotificationRecord(this, pageKey);
        notificationList.add(sr);
    }

     /**
      * Get rid of any notification of the specified page.
      */
    public void clearNotification(String pageKey)
        throws Exception
    {
        if (notificationList == null)
        {
            getNotificationList();
        }

        for (Iterator<NotificationRecord> iterator = notificationList.iterator(); iterator.hasNext();) {
            NotificationRecord sr = iterator.next();
            if (pageKey.equals(sr.getPageKey()))
            {
                removeChild(sr);
                iterator.remove();
            }
        }
    }


    public boolean isNotifiedForProject(String pageKey)
        throws Exception
    {
        if (notificationList == null)
        {
            getNotificationList();
        }
        for (NotificationRecord sr : notificationList)
        {
            if (pageKey.equals(sr.getPageKey()))
            {
                return true;
            }
        }
        return false;
    }

    public void setDisabled(boolean val)
    {
        if (val)
        {
            setAttribute("disable", "yes");
        }
        else
        {
            setAttribute("disable", null);
        }
    }

    public boolean getDisabled()
    {
        String disable = getAttribute("disable");
        return ((disable!=null) && ("yes".equals(disable)));
    }

    
    
    /**
     * Whether or not to display WEAVER style menus
     * @param val
     */
    public void setWeaverMenu(boolean val) {
        setAttributeBool("weaverMenu", val);
    }
    public boolean getWeaverMenu() {
        return getAttributeBool("weaverMenu");
    }

    
    
    public List<TemplateRecord> getTemplateList()
    throws Exception
    {
        templateList = TemplateRecord.getAllTemplateRecords(this);
        return templateList;
    }

    public void setProjectAsTemplate(String pageKey)
    throws Exception
    {
        TemplateRecord tr = TemplateRecord.createTemplateRecord(this, pageKey);
        templateList.add(tr);
    }

    public boolean findTemplate(String pageKey)
    throws Exception
    {
        List<TemplateRecord> templateList =  getTemplateList();

        for (Iterator<TemplateRecord> itr = templateList.iterator(); itr.hasNext();) {
            TemplateRecord template =  itr.next();
            String templatePageKey = template.getPageKey();
            if (pageKey.equals(templatePageKey))
            {
                return true;
            }
        }

        return false;
    }
    public void removeTemplateRecord(String pageKey)
    throws Exception
    {
        templateList = getTemplateList();

        TemplateRecord templateToBeRemoved = null;
        for (Iterator<TemplateRecord> itr = templateList.iterator(); itr.hasNext();) {
            TemplateRecord template =  itr.next();
            String templatePageKey = template.getPageKey();
            if (pageKey.equals(templatePageKey))
            {
                templateToBeRemoved = template;
                break;
            }
        }
        if(templateToBeRemoved != null){
            templateToBeRemoved.removeTemplateRecord(this);
            templateList.remove(templateToBeRemoved);
        }

    }

    /**
     * returns the NGPageIndex entries for each project template, but
     * only if that key matches a project that still exists.
     * Invalid template list entries are ignored.
     */
    public Vector<NGPageIndex> getValidTemplates(Cognoscenti cog) throws Exception {
        Vector<NGPageIndex> templates = new Vector<NGPageIndex>();
        for(TemplateRecord tr : getTemplateList()) {
            String pageKey = tr.getPageKey();
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
    public String getPreferredEmail()
    {
        String val = getScalar("prefEmail");
        if (val != null && val.length()>0)
        {
            return val;
        }
        //if not set use the default of the first email address ... if there is one
        for (IDRecord possible : ids)
        {
            String idval = possible.getLoginId();
            //an at sign in there, and no slashes, could be an email address
            if (idval.indexOf("@")>=0 && idval.indexOf("/")<0)
            {
                return idval;
            }
        }
        return null;
    }
    public void setPreferredEmail(String newValue)
    {
        setScalar("prefEmail", newValue);
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
        return getScalar("image");
    }

    public void setImage(String newImage) {
        if (newImage == null) {
            newImage = "";
        }
        if (!newImage.equals(name)) {
            setScalar("image", newImage);
        }
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
            System.out.println("The image file EXISTS for user: "+imageFile);
            return;
        }
        System.out.println("Did not find an image file for user "+getKey());
        char uidLetter = this.getUniversalId().charAt(0);
        File defaultFile =  new File(imageFolder, "fake-"+uidLetter+".jpg");
        if (!defaultFile.exists()) {
            throw new Exception("The default user image file is missing!: "+defaultFile);
        }
        UtilityMethods.copyFileContents(defaultFile, imageFile);
        System.out.println("Copied an image file for user "+getKey()+" from: "+defaultFile);
    }

    public List<SiteRequest> getUsersSiteRequests() throws Exception {
        List<SiteRequest> usersReqs = new ArrayList<SiteRequest>();
        for (SiteRequest oneReq : SiteReqFile.getAllSiteReqs()) {
            if(hasAnyId(oneReq.getUniversalId())) {
                usersReqs.add( oneReq );
            }
        }
        return usersReqs;
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
        for (IDRecord anId : ids) {
            String idval = anId.getLoginId();
            if(idval.toLowerCase().contains(frag)){
                return true;
            }
        }
        return false;
    }

    public void setAccessCode(String accessCode)throws Exception
    {
        setScalar("accesscode", accessCode);
        setScalar("accessCodeModTime", String.valueOf(System.currentTimeMillis()));
        UserManager.writeUserProfilesToFile();
    }
    public String getAccessCode()throws Exception
    {
        long max_days = 1;
        long days_diff = 0;
        String accessCodeModTime = getScalar("accessCodeModTime");
        if(accessCodeModTime != null && accessCodeModTime.length() > 0){
            days_diff = UtilityMethods.getDurationInDays(System.currentTimeMillis(),Long.parseLong(accessCodeModTime));
        }
        String accessCode = getScalar("accesscode");
        if( (accessCode == null || accessCode.length() == 0) || days_diff > max_days){
            accessCode = IdGenerator.generateKey();
            setAccessCode(accessCode);
        }

        return accessCode;
    }

    public UserPage getUserPage() throws Exception {
        return UserManager.findOrCreateUserPage(key);
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


}
