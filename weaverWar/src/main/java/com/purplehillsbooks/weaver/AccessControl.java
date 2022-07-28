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
import java.util.HashMap;
import java.util.List;

import com.purplehillsbooks.json.JSONException;

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
    public static boolean canAccessDoc(AuthRequest ar, NGWorkspace ngc, AttachmentRecord attachRec)
        throws Exception {

        if (ar.canAccessWorkspace()) {
            return true;
        }

        //then, check to see if there is any special condition in session
        String resourceId = "doc:"+attachRec.getId()+":"+ngc.getKey();
        System.out.println("CAN-ACCESS-DOC: checking for resource: ("+resourceId+")");
        if (ar.hasSpecialSessionAccess(resourceId)) {
            System.out.println("CAN-ACCESS-DOC: session has resource: ("+resourceId+")");
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

        //now check to see if you have any special access to a MEETING that has attached
        //this document.  In that case you are allowed access as well!
        for (MeetingRecord meet : attachRec.getLinkedMeetings(ngc)) {
            if (canAccessMeeting(ar, ngc, meet)) {
                //have to remember that you have access to this attachment to allow download
                ar.setSpecialSessionAccess(resourceId);
                return true;
            }
        }

        //now check to see if you have any special access to a Discussion Topic that has attached
        //this document.  In that case you are allowed access as well!
        for (TopicRecord note : attachRec.getLinkedTopics(ngc)) {
            if (canAccessTopic(ar, ngc, note)) {
                //have to remember that you have access to this attachment to allow download
                ar.setSpecialSessionAccess(resourceId);
                return true;
            }
        }

        //now check to see if you have any special access to a Action Item that has attached
        //this document.  In that case you are allowed access as well!
        for (GoalRecord goal : attachRec.getLinkedGoals(ngc)) {
            if (canAccessGoal(ar, ngc, goal)) {
                //have to remember that you have access to this attachment to allow download
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

            //also allow the assignee of an actoin item free access as well
            if (gr.isAssignee(user)) {
                return true;
            }
        }

        //then, check to see if there is any special condition in session
        String resourceId = "goal:"+gr.getId()+":"+ngc.getKey();
        if (ar.hasSpecialSessionAccess(resourceId)) {
            return true;
        }

        //now, check the query parameters, and if appropriate, set up the special access
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

    public static boolean canAccessTopic(AuthRequest ar, NGWorkspace ngc, TopicRecord topicRec)
    throws Exception {
        if (ar.isLoggedIn()) {
            //if user is logged in, and is a member or superadmin, then can access
            if (ar.canAccessWorkspace()) {
                System.out.println("CAN-ACCESS-TOPIC: user can access the workspace");
                return true;
            }
            
            //if the user is a subscriber to the topic then they get special access
            UserProfile user = ar.getUserProfile();
            NGRole subscribers = topicRec.getSubscriberRole();
            if (subscribers.isExpandedPlayer(user, ngc)) {
                System.out.println("CAN-ACCESS-TOPIC: user is a subscriber");
                return true;
            }
        }

        //then, check to see if there is any special condition in session
        String resourceId = "topic:"+topicRec.getId()+":"+ngc.getKey();
        if (!ar.isLoggedIn() && ar.hasSpecialSessionAccess(resourceId)) {
            System.out.println("CAN-ACCESS-TOPIC: user has a session flag");
            assureTemporaryProfile(ar);
            return true;
        }

        //now, check the query parameters, and if appropriate, set up the special access
        //url must have "mnnote"  (magic number for note)
        String mnnote = ar.defParam("mnnote", null);
        if (mnnote == null) {
            System.out.println("CAN-ACCESS-TOPIC: not allowed because mnnote is missing ");
            return false;
        }
        
        String expectedMN = ngc.emailDependentMagicNumber(resourceId);
        if (!expectedMN.equals(mnnote)) {
            System.out.println("CAN-ACCESS-TOPIC: not allowed because ("+mnnote+") is not ("+expectedMN+")");
            return false;
        }

        //at this point, we have seen a magic number allowing access to this page
        //so set up the rest of the login credentials for one request
        ar.setSpecialSessionAccess(resourceId);
        System.out.println("CAN-ACCESS-TOPIC: user has magic number");
        if (!ar.isLoggedIn()) {
            assureTemporaryProfile(ar);
        }
        return true;
    }
    public static void assertAccessTopic(AuthRequest ar, NGWorkspace ngc, TopicRecord topicRec) throws Exception {
        if (!canAccessTopic(ar, ngc, topicRec)) {
            throw new JSONException("User {0} is not able to access topic {1}", ar.getBestUserId(), topicRec.getId());
        }
    }

    public static boolean assureTemporaryProfile(AuthRequest ar) throws Exception {
        
        if (ar.isLoggedIn()) {
            throw new Exception("PROGRAM LOGIC ERROR: assureTemporaryProfile should be called onl when NOT logged in.");
        }
        String emailId = ar.defParam("emailId", null);
        if (emailId==null) {
            return false;
        }
        Cognoscenti cog = ar.getCogInstance();
        UserManager userManager = cog.getUserManager();
        UserProfile licensedUser = userManager.lookupUserByAnyId(emailId);
        if (licensedUser == null) {
            licensedUser = userManager.createUserWithId(emailId);
        }
        if (licensedUser == null) {
            throw new Exception("For some reason the user manager did not create the profile.");
        }
        ar.setPossibleUser(licensedUser);
        UserProfile up = ar.getPossibleUser();
        if (up==null) {
            throw new Exception("something wrong, user profile is null after setUserForOneRequest ");
        }
        
        return true;
    }

    public static String getAccessTopicParams(NGContainer ngc, TopicRecord topicRec) throws Exception{
        String resourceId = "topic:"+topicRec.getId()+":"+ngc.getKey();
        String encodedValue = URLEncoder.encode(ngc.emailDependentMagicNumber(resourceId), "UTF-8");
        return "mnnote=" + encodedValue;
    }

    public static boolean canAccessRoleRequest(AuthRequest ar, NGContainer ngc, RoleRequestRecord roleRequestRecord)
    throws Exception {

        //then, if user is logged in, and is a member, then can access
        if (ar.canAccessWorkspace()) {
            return true;
        }

        //then, check to see if there is any special condition in session
        String resourceId = "rolerequest:"+ngc.getKey()+":"+roleRequestRecord.getRequestId();
        if (ar.hasSpecialSessionAccess(resourceId)) {
            return true;
        }

        //now, check the query parameters, and if appropriate, set up the special access
        //url must have "mnrolerequest"  (magic number for role request)
        String mndoc = ar.defParam("mnrolerequest", null);
        if (mndoc == null) {
            return false;
        }
        
        String expectedMN = ngc.emailDependentMagicNumber(resourceId);
        if (expectedMN.equals(mndoc)) {
            ar.setSpecialSessionAccess(resourceId);
            return true;
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
            userPage = UserManager.getStaticUserManager().findOrCreateUserPage(userKey);
            userPageMap.put(userKey, userPage);
        }
        String resourceId = "accountrequest:"+userPage.getKey()+":"+accountDetails.getRequestId();
        String encodedValue = URLEncoder.encode(userPage.emailDependentMagicNumber(resourceId), "UTF-8");
        accessDocParam += encodedValue;
        return accessDocParam;
    }

    public static boolean canAccessMeeting(AuthRequest ar, NGContainer ngc, MeetingRecord meet) throws Exception {
        //then, if user is logged in, and is a member, then can access
        if (ar.isLoggedIn()) {
            UserProfile user = ar.getUserProfile();
            if (user!=null && ngc.primaryOrSecondaryPermission(user)) {
                return true;
            }

            //members of the workspace always allowed in
            if (ar.canAccessWorkspace()) {
                return true;
            }

            //players of the target role are always allowed in as well
            NGRole targetRole = ngc.getRole(meet.getTargetRole());
            if (targetRole!=null && targetRole.isExpandedPlayer(user, ngc)) {
                return true;
            }

            //The actual participants of the meeting are allowed as well
            //regardless of whether they are in workspace or not
            List<String> participantIds = meet.getParticipants();
            for (String id : participantIds) {
                if (user.hasAnyId(id)) {
                    return true;
                }
            }
            
            //also walk through and allow any presenters access as well
            for (AgendaItem ai : meet.getAgendaItems()) {
                for (AddressListEntry ale : ai.getPresenters()) {
                    if (user.hasAnyId(ale.getUniversalId())) {
                        return true;
                    }
                }
            }
            
        }


        //then, check to see if there is any special condition in session
        String resourceId = "meet:"+meet.getId()+":"+ngc.getKey();
        if (ar.hasSpecialSessionAccess(resourceId)) {
            return true;
        }

        //now, check the query parameters, and if appropriate, set up the special access
        //url must have "mndoc"  (magic number for doc)
        String mnm = ar.defParam("mnm", null);
        if (mnm != null) {
            String expectedMN = ngc.emailDependentMagicNumber(resourceId);
            if (expectedMN.equals(mnm)) {
                ar.setSpecialSessionAccess(resourceId);
                return true;
            }
        }

        return false;
    }

    public static String getAccessMeetParams(NGContainer ngc, MeetingRecord meet) throws Exception{
        String resourceId = "meet:"+meet.getId()+":"+ngc.getKey();
        String encodedValue = URLEncoder.encode(ngc.emailDependentMagicNumber(resourceId), "UTF-8");
        return "mnm=" + encodedValue;
    }


}
