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

import java.net.URLEncoder;
import java.util.HashMap;

public class AccessControl {

    //TODO: this is not a good idea, to cache the entire user page for every user
    //that touches the system.  This should be cleared occasionally or store a
    //smaller amount of data and should only cache a specified number of users.
    static HashMap<String, UserPage> userPageMap = new HashMap<String, UserPage>();

    /**
    * When the web request is trying to access a particular document, this will
    * say whether that document should be accessed, based on logged in user being
    * a member of the project, or whether a special session permission was granted.
    *
    * For documents, the localIdMagicNumber must be in the "mndoc" parameter
    * to get special session status.
    *
    * Side Effect: if the right magic number is found in URL, the session is marked
    * and this special access capability will persist as long as the session does.
    */
    public static boolean canAccessDoc(AuthRequest ar, NGContainer ngc, AttachmentRecord attachRec)
        throws Exception {
        //first, anyone can access a public document
        if (attachRec.getVisibility() == SectionDef.PUBLIC_ACCESS) {
            return true;
        }

        //then, if user is logged in, and is a member, then can access
        if (ar.isLoggedIn()) {
            UserProfile user = ar.getUserProfile();
            if (user!=null && ngc.primaryOrSecondaryPermission(user)) {
                return true;
            }
        }

        //then, check to see if there is any special condition in session
        String resourceId = "doc:"+attachRec.getId()+":"+ngc.getKey();
        if (ar.hasSpecialSessionAccess(resourceId)) {
            return true;
        }

        //now, check the query parameters, and if appropriate, set up the special access
        //url must have "mndoc"  (magic number for doc)
        String mndoc = ar.defParam("mndoc", null);
        if (mndoc != null) {
            String expectedMN = ngc.emailDependentMagicNumber(resourceId);
            if (expectedMN.equals(mndoc)) {
                ar.setSpecialSessionAccess(resourceId);
                return true;
            }
        }

        return false;
    }

    public static String getAccessDocParams(NGContainer ngc, AttachmentRecord attachRec) throws Exception{
        String resourceId = "doc:"+attachRec.getId()+":"+ngc.getKey();
        String encodedValue = URLEncoder.encode(ngc.emailDependentMagicNumber(resourceId), "UTF-8");
        return "mndoc=" + encodedValue;
    }

    public static boolean canAccessReminder(AuthRequest ar, NGContainer ngc, ReminderRecord reminderRecord)
    throws Exception {

        //then, if user is logged in, and is a member, then can access
        if (ar.isLoggedIn()) {
            UserProfile user = ar.getUserProfile();
            if (user!=null && ngc.primaryOrSecondaryPermission(user)) {
                return true;
            }
        }

        //then, check to see if there is any special condition in session
        String resourceId = "reminder:"+reminderRecord.getId()+":"+ngc.getKey();
        if (ar.hasSpecialSessionAccess(resourceId)) {
            return true;
        }

        //now, check the query parameters, and if appropriate, set up the special access
        //url must have "mnremider"  (magic number for remider)
        String mndoc = ar.defParam("mnremider", null);
        if (mndoc != null) {
            String expectedMN = ngc.emailDependentMagicNumber(resourceId);
            if (expectedMN.equals(mndoc)) {
                ar.setSpecialSessionAccess(resourceId);
                return true;
            }
        }

        return false;
    }

    public static String getAccessReminderParams(NGContainer ngc, ReminderRecord reminderRecord) throws Exception{
        String resourceId = "reminder:"+reminderRecord.getId()+":"+ngc.getKey();
        String encodedValue = URLEncoder.encode(ngc.emailDependentMagicNumber(resourceId), "UTF-8");
        return "mnremider=" + encodedValue;
    }

    public static boolean canAccessGoal(AuthRequest ar, NGContainer ngc, GoalRecord gr)
            throws Exception {

        //then, if user is logged in, and is a member, then can access
        if (ar.isLoggedIn()) {
            UserProfile user = ar.getUserProfile();
            if (user!=null && ngc.primaryOrSecondaryPermission(user)) {
                return true;
            }
        }

        //then, check to see if there is any special condition in session
        String resourceId = "goal:"+gr.getId()+":"+ngc.getKey();
        if (ar.hasSpecialSessionAccess(resourceId)) {
            return true;
        }

        //now, check the query parameters, and if apprpriate, set up the special access
        //url must have "mntask"  (magic number for task)
        String mntask = ar.defParam("mntask", null);
        if (mntask != null) {
            String expectedMN = ngc.emailDependentMagicNumber(resourceId);
            if (expectedMN.equals(mntask)) {
                ar.setSpecialSessionAccess(resourceId);
                return true;
            }
        }

        return false;
    }

    public static boolean isMagicNumber(AuthRequest ar, NGContainer ngc,
            GoalRecord gr, String mntask) throws Exception {
        String resourceId = "goal:"+gr.getId()+":"+ngc.getKey();
        String encodedValue = URLEncoder.encode(ngc.emailDependentMagicNumber(resourceId), "UTF-8");
        return mntask.equals(encodedValue);
    }

    public static String getAccessGoalParams(NGContainer ngc, GoalRecord gr) throws Exception{
        String resourceId = "goal:"+gr.getId()+":"+ngc.getKey();
        String encodedValue = URLEncoder.encode(ngc.emailDependentMagicNumber(resourceId), "UTF-8");
        return "mntask=" + encodedValue;
    }

    public static boolean canAccessNote(AuthRequest ar, NGContainer ngc, NoteRecord noteRec)
    throws Exception {
        //first, anyone can access a public note
        if (noteRec.getVisibility() == SectionDef.PUBLIC_ACCESS) {
            return true;
        }
        //then, if user is logged in, and is a member, then can access
        if (ar.isLoggedIn()) {
            UserProfile user = ar.getUserProfile();
            if (user!=null && ngc.primaryOrSecondaryPermission(user)) {
                return true;
            }
        }

        //then, check to see if there is any special condition in session
        String resourceId = "goal:"+noteRec.getId()+":"+ngc.getKey();
        if (ar.hasSpecialSessionAccess(resourceId)) {
            return true;
        }

        //now, check the query parameters, and if appropriate, set up the special access
        //url must have "mnnote"  (magic number for note)
        String mndoc = ar.defParam("mnnote", null);
        if (mndoc != null) {
            String expectedMN = ngc.emailDependentMagicNumber(resourceId);
            if (expectedMN.equals(mndoc)) {
                ar.setSpecialSessionAccess(resourceId);
                return true;
            }
        }

        return false;
    }

    public static String getAccessNoteParams(NGContainer ngc, NoteRecord noteRec) throws Exception{
        String resourceId = "goal:"+noteRec.getId()+":"+ngc.getKey();
        String encodedValue = URLEncoder.encode(ngc.emailDependentMagicNumber(resourceId), "UTF-8");
        return "mnnote=" + encodedValue;
    }

    public static boolean canAccessRoleRequest(AuthRequest ar, NGContainer ngc, RoleRequestRecord roleRequestRecord)
    throws Exception {

        //then, if user is logged in, and is a member, then can access
        if (ar.isLoggedIn()) {
            UserProfile user = ar.getUserProfile();
            if (user!=null && ngc.primaryOrSecondaryPermission(user)) {
                return true;
            }
        }

        //then, check to see if there is any special condition in session
        String resourceId = "rolerequest:"+ngc.getKey()+":"+roleRequestRecord.getRequestId();
        if (ar.hasSpecialSessionAccess(resourceId)) {
            return true;
        }

        //now, check the query parameters, and if appropriate, set up the special access
        //url must have "mnrolerequest"  (magic number for role request)
        String mndoc = ar.defParam("mnrolerequest", null);
        if (mndoc != null) {
            String expectedMN = ngc.emailDependentMagicNumber(resourceId);
            if (expectedMN.equals(mndoc)) {
                ar.setSpecialSessionAccess(resourceId);
                return true;
            }
        }

        return false;
    }

    public static String getAccessRoleRequestParams(NGContainer ngc, RoleRequestRecord roleRequestRecord) throws Exception{
        String accessDocParam = "mnrolerequest=";
        String resourceId = "rolerequest:"+ngc.getKey()+":"+roleRequestRecord.getRequestId();
        String encodedValue = URLEncoder.encode(ngc.emailDependentMagicNumber(resourceId), "UTF-8");
        accessDocParam += encodedValue;
        return accessDocParam;
    }

    public static boolean canAccessSiteRequest(AuthRequest ar, String userKey, SiteRequest accountDetails)
    throws Exception {

        //then, if user is logged in, and is a super admin, then can always access
        if (ar.isLoggedIn()) {
            if (ar.isSuperAdmin()) {
                return true;
            }
        }

        //then, check to see if there is any special condition in session
        String resourceId = "accountrequest:"+userKey+":"+accountDetails.getRequestId();
        if (ar.hasSpecialSessionAccess(resourceId)) {
            return true;
        }

        //now, check the query parameters, and if appropriate, set up the special access
        //url must have "mnaccountrequest"  (magic number for site request)
        String mndoc = ar.defParam("mnaccountrequest", null);
        if (mndoc == null) {
            //no magic number, no luck
            return false;
        }
        if(userPageMap.containsKey(userKey)){
            UserPage userPage = userPageMap.get(userKey);
            String expectedMN = userPage.emailDependentMagicNumber(resourceId);
            if (expectedMN.equals(mndoc)) {
                ar.setSpecialSessionAccess(resourceId);
                return true;
            }
        }

        return false;
    }

    public static String getAccessSiteRequestParams(String userKey, SiteRequest accountDetails) throws Exception{
        String accessDocParam = "mnaccountrequest=";
        UserPage userPage = null;
        if(userPageMap.containsKey(userKey)){
            userPage = userPageMap.get(userKey);
        }else{
            userPage = UserManager.findOrCreateUserPage(userKey);
            userPageMap.put(userKey, userPage);
        }
        String resourceId = "accountrequest:"+userPage.getKey()+":"+accountDetails.getRequestId();
        String encodedValue = URLEncoder.encode(userPage.emailDependentMagicNumber(resourceId), "UTF-8");
        accessDocParam += encodedValue;
        return accessDocParam;
    }

}
