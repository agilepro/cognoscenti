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

import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

import org.w3c.dom.Document;
import org.w3c.dom.Element;

public class UserProfileXML extends DOMFace {

    public UserProfileXML(Document doc, Element upEle, DOMFace p)
        throws Exception
    {
        super(doc,upEle,p);
        String key = upEle.getAttribute("id");

        //consistency check here
        if (key == null || key.length() == 0){
            key = IdGenerator.generateKey();
            upEle.setAttribute("id", key);
        }
    }


    public List<String> getIdList() throws Exception {
        ArrayList<IDRecord> ids = new ArrayList<IDRecord>();

        List<IDRecord> chilluns = getChildren("idrec", IDRecord.class);
        for (IDRecord ele : chilluns) {
            ids.add(ele);
        }

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

        List<String> retVal = new ArrayList<String> ();
        for (IDRecord anId : ids) {
            retVal.add(anId.getLoginId());
        }
        return retVal;
    }



    /**
    * This should be unique and internal, so .... not
    * sure why it would ever need to be set.
    */
    public void setKey(String nkey) {
        setAttribute("id", nkey);
    }

    /**
    * The key is a unique identifier on this server for a particular user.
    * Never forget that this is NOT a global identifier that is useful on
    * any other server.  The email address, and open id, are global identifiers
    * that can be transferred across servers, but the KEY is a key only on this
    * server.
    */
    public String getKey() {
        return getAttribute("id");
    }

    public void setName(String newName) {
        setScalar("name", newName);
    }

    public String getName() {
        return getScalar("name");
    }


    public void setDescription(String newDesc) {
        setScalar("description", newDesc);
    }

    public String getDescription() {
        return getScalar("description");
    }

    /**
    * Gives this user the specified ID (either email or OpenId).
    * Note: only do this when the ID have been verified as belonging
    * to this user!   This method will search for other users with that
    * ID, and remove that id from those other users.
    */
    public void addId(String newId) throws Exception {
        DOMFace newIdRec = this.createChild("idrec", DOMFace.class);
        newIdRec.setAttribute("loginid", newId);
    }



    public void setLastLogin(long newLastLogin, String loginId) {
        setScalarLong("lastlogin", newLastLogin);
        setScalar("lastloginid", loginId);
    }

    public long getLastLogin() {
        return getScalarLong("lastlogin");
    }
    public String getLastLoginId() {
        return getScalar("lastloginid");
    }

    public void setLastUpdated(long newLastUpdated) {
        setScalarLong("lastupdated", newLastUpdated);
    }
    public long getLastUpdated() {
        return getScalarLong("lastupdated");
    }

    public void setNotificationPeriod(int period) {
        setAttributeInt("notificationPeriod", period);
    }
    public int getNotificationPeriod() {
        return getAttributeInt("notificationPeriod");
    }


    public void setNotificationTime(long period) {
        setAttributeLong("notificationTime", period);
    }
    public long getNotificationTime() {
        return getAttributeLong("notificationTime");
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
    public void setLicenseToken(String newLicTok) {
        setScalar("licensetoken", newLicTok);
    }
    public String getLicenseToken() {
        return getScalar("licensetoken");
    }




    /**
    * Returns a vector of WatchRecord objects.
    * Do not modify this vector externally, just read only.
    */
    public List<WatchRecord> getWatchList()  throws Exception {
        List<WatchRecord> watchList = new Vector<WatchRecord>();
        List<WatchRecordXML> chilluns = this.getChildren("watch", WatchRecordXML.class);
        for (WatchRecordXML wr : chilluns) {
            watchList.add(new WatchRecord(wr.getPageKey(), wr.getLastSeen()));
        }
        return watchList;
    }

    /**
    * Create or update a watch on a page.
    * the page key specifies the page.
    * The long value is the time of "last seen" which will be
    * used to determine if the page has changed since that time.
    */
    public void addWatch(String pageKey, long seenTime) throws Exception {
        DOMFace newSR = createChildWithID("watch", DOMFace.class, "pagekey", pageKey);
        newSR.setAttributeLong("lastseen",seenTime);
    }




    /**
     * Returns a vector of keys of pages in the notify list
     * Do not modify this vector externally, just read only.
     */
     public List<String> getNotificationList() throws Exception {
         ArrayList<String> cache = new ArrayList<String>();
         for (DOMFace nr : getChildren("notification", DOMFace.class)) {
             cache.add(nr.getAttribute("pagekey"));
         }
         return cache;
     }


     /**
     * Create or update a notification on a page.
     * the page key specifies the page.
     * The long value is the time of "last seen" which will be
     * used to determine if the page has changed since that time.
     */
    public void addNotification(String pageKey) throws Exception {
        createChildWithID("notification", DOMFace.class, "pagekey", pageKey);
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



    public List<String> getTemplateList() throws Exception {
        ArrayList<String> cache = new ArrayList<String>();
        List<DOMFace> chilluns = getChildren("template", DOMFace.class);
        for (DOMFace tr : chilluns) {
            cache.add(tr.getAttribute("pagekey"));
        }
        return cache;
    }

    public void addTemplate(String pageKey) throws Exception {
        createChildWithID("template", DOMFace.class, "pagekey", pageKey);
    }




    public String getImage() {
        return getScalar("image");
    }
    public void setImage(String newImage) {
        setScalar("image", newImage);
    }




    public void setAccessCode(String accessCode)throws Exception {
        setScalar("accesscode", accessCode);
    }
    public String getAccessCode()throws Exception {
        return getScalar("accesscode");
    }
    public void setAccessCodeModTime(long newTime)throws Exception {
        setScalarLong("accessCodeModTime", newTime);
    }
    public long getAccessCodeModTime()throws Exception {
        return getScalarLong("accessCodeModTime");
    }

}
