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

package com.purplehillsbooks.weaver.spring;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import com.purplehillsbooks.weaver.AccessControl;
import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.IdGenerator;
import com.purplehillsbooks.weaver.MicroProfileMgr;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.ProfileRef;
import com.purplehillsbooks.weaver.RoleRequestRecord;
import com.purplehillsbooks.weaver.SearchResultRecord;
import com.purplehillsbooks.weaver.UserCache;
import com.purplehillsbooks.weaver.UserCacheMgr;
import com.purplehillsbooks.weaver.UserManager;
import com.purplehillsbooks.weaver.UserPage;
import com.purplehillsbooks.weaver.UserProfile;
import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.weaver.mail.EmailSender;
import com.purplehillsbooks.weaver.mail.MailInst;
import com.purplehillsbooks.weaver.mail.OptOutAddr;
import com.purplehillsbooks.weaver.util.Thumbnail;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.StreamHelper;


@Controller
public class UserController extends BaseController {





    ////////////////////// MAIN VIEWS /////////////////////////


    @RequestMapping(value = "/{userKey}/UserHome.htm", method = RequestMethod.GET)
    public void userHome(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "UserHome.jsp");
    }
    
    //this one just in case someone had bookmarked the old value
    //delete this after december 2022
    @RequestMapping(value = "/{userKey}/userHome.htm", method = RequestMethod.GET)
    public void userHome2(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "UserHome.jsp");
    }


    @RequestMapping(value = "{userKey}/WatchedProjects.htm", method = RequestMethod.GET)
    public void watchedProjects(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        streamJSPUserLogged2(request, response, userKey, "WatchedProjects.jsp");
    }

    @RequestMapping(value = "/{userKey}/OwnerProjects.htm", method = RequestMethod.GET)
    public void ownerProjects(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        streamJSPUserLogged2(request, response, userKey, "OwnerProjects.jsp");
    }


    @RequestMapping(value = "/{userKey}/ParticipantProjects.htm", method = RequestMethod.GET)
    public void participantProjects(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        streamJSPUserLogged2(request, response, userKey, "ParticipantProjects.jsp");
    }

    @RequestMapping(value = "/{userKey}/AllProjects.htm", method = RequestMethod.GET)
    public void allProjects(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "AllProjects.jsp");
    }



    @RequestMapping(value = "/{userKey}/UserAlerts.htm", method = RequestMethod.GET)
    public void loadUserAlerts(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "UserAlerts.jsp");
    }


    @RequestMapping(value = "/{userKey}/UserActiveTasks.htm", method = RequestMethod.GET)
    public void userActiveTasks(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "UserActiveTasks.jsp");
    }

    @RequestMapping(value = "/{userKey}/userMissingResponses.htm", method = RequestMethod.GET)
    public void userMissingResponses(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "UserMissingResponses.jsp");
    }

    @RequestMapping(value = "/{userKey}/userOpenRounds.htm", method = RequestMethod.GET)
    public void userOpenRounds(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "UserOpenRounds.jsp");
    }


    @RequestMapping(value = "/{userKey}/ShareRequests.htm", method = RequestMethod.GET)
    public void ShareRequests(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "ShareRequests.jsp");
    }

    @RequestMapping(value = "/{userKey}/userSites.htm", method = RequestMethod.GET)
    public void loadUserAccounts(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "UserAccounts.jsp");
    }

    @RequestMapping(value = "/{userKey}/UserProfileEdit.htm")
    public void userProfileEdit(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        request.setAttribute("userKey", userKey);
        streamJSPUserLogged2(request, response, userKey, "UserProfileEdit.jsp");
    }

    @RequestMapping(value = "/{userKey}/UserIconEdit.htm")
    public void userIconEdit(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        request.setAttribute("userKey", userKey);
        streamJSPUserLogged2(request, response, userKey, "UserIconEdit.jsp");
    }



    @RequestMapping(value = "/{userKey}/searchAllNotes.htm")
    public void searchAllNotes(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        request.setAttribute("userKey", userKey);
        streamJSPUserLogged2(request, response, userKey, "SearchAllNotes.jsp");
    }

    @RequestMapping(value = "/{userKey}/EmailUser.htm")
    public void emailUser(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        request.setAttribute("userKey", userKey);
        streamJSPUserLogged2(request, response, userKey, "EmailUser.jsp");
    }

    @RequestMapping(value = "/{userKey}/EmailMsgU.htm")
    public void emailMsgU(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        request.setAttribute("userKey", userKey);
        streamJSPUserLogged2(request, response, userKey, "EmailMsgU.jsp");
    }

    @RequestMapping(value = "/{userKey}/Facilitators.htm")
    public void facilitators(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        request.setAttribute("userKey", userKey);
        streamJSPUserLogged2(request, response, userKey, "Facilitators.jsp");
    }

    @RequestMapping(value = "/{userKey}/RemoteProfileUpdate.json", method = RequestMethod.POST)
    public void RemoteProfileUpdate(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            if(!ar.isLoggedIn()){
                throw WeaverException.newBasic("Must be logged in.");
            }
            String address = ar.reqParam("address");
            String act = ar.reqParam("act");
            UserProfile userBeingViewed = UserManager.getUserProfileOrFail(userKey);
            UserPage uPage = userBeingViewed.getUserPage();
            if ("Create".equals(act)) {
                ProfileRef pr = uPage.createProfileRefOrFail(address);
                ar.write("Remote profile link added for "+address);
                pr.setLastAccess(ar.nowTime);
            }
            else if ("Delete".equals(act)) {
                uPage.deleteProfileRef(address);
                ar.write("Remote profile deleted "+address);
            }
            else {
                throw WeaverException.newBasic("RemoteProfileAction does not understand the act "+act);
            }
            uPage.save();
            ar.flush();
        }catch(Exception ex){
            Exception ee = WeaverException.newWrap("Unable to get update from remote profile.", ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{userKey}/updateProfile.json", method = RequestMethod.POST)
    public void updateProfile(HttpServletRequest request, HttpServletResponse response,
                              @PathVariable String userKey) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            ar.assertLoggedIn("Must be logged in in order to edit a user profile.");
            Cognoscenti cog = ar.getCogInstance();
            UserManager userManager = cog.getUserManager();
            UserProfile userBeingEdited = userManager.findUserByAnyIdOrFail(userKey);
            UserProfile userEditing = ar.getUserProfile();

            if (!userEditing.getKey().equals(userBeingEdited.getKey())) {
                if (!ar.isSuperAdmin()) {
                    throw WeaverException.newBasic("User "+userEditing.getName()+" is not allowed to edit the profile of user "+userBeingEdited.getName());
                }
            }

            JSONObject newUserSettings = this.getPostedObject(ar);
            userBeingEdited.updateFromJSON(newUserSettings);
            UserManager.writeUserProfilesToFile();

            JSONObject userObj = userBeingEdited.getFullJSON();
            sendJson(ar, userObj);
        }
        catch(Exception ex){
            Exception ee = WeaverException.newWrap("Unable to update user "+userKey, ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/approveOrRejectRoleReqThroughMail.htm", method = RequestMethod.GET)
    public void gotoApproveOrRejectRoleReqPage(
            @PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw =  registerWorkspaceRequired(ar, siteId, pageId);

            String requestId = ar.reqParam("requestId");
            RoleRequestRecord roleRequestRecord = ngw.getRoleRequestRecordById(requestId);
            if (roleRequestRecord==null) {
                throw WeaverException.newBasic("Unable to find a role request record with id="+requestId);
            }
            boolean canAccessPage = AccessControl.canAccessRoleRequest(ar, ngw, roleRequestRecord);

            if(!canAccessPage){
                if (ar.isLoggedIn()) {
                    streamJSP(ar, "WarningNotMember.jsp");
                }
                else {
                    showDisplayWarning(ar, "In order to see this section, you need to be logged in.");
                }
                return;
            }

            String isAccessThroughEmail = ar.reqParam("isAccessThroughEmail");

            request.setAttribute("realRequestURL", ar.getRequestURL());

            request.setAttribute("isAccessThroughEmail", isAccessThroughEmail);
            request.setAttribute("canAccessPage", canAccessPage);
            streamJSP(ar, "RoleRequest.jsp");
        }catch(Exception e) {
            showDisplayException(ar, WeaverException.newWrap(
                "Failure approving or rejecting through email", 
                e));
        }
    }


    @RequestMapping(value="/updateMicroProfile.json", method = RequestMethod.POST)
    public void updateMicroProfile(HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        ar.assertLoggedIn("Can not update user contacts.");
        try{

            JSONObject received = this.getPostedObject(ar);
            String emailId = received.getString("uid");
            String idDisplayName = received.getString("name");
            MicroProfileMgr.setDisplayName(emailId, idDisplayName);
            MicroProfileMgr.save();

            sendJson(ar, received);
        }catch(Exception ex){
            Exception ee = WeaverException.newWrap("Unable to update micro profile.", ex);
            streamException(ee, ar);
        }
    }




    @RequestMapping(value = "/{userKey}/NotificationSettings.htm", method = RequestMethod.GET)
    public void goToNotificationSetting(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);

        if(ar.hasSpecialSessionAccess("Notifications:"+userKey)){
            //need to show this even if not logged in
            streamJSP(ar, "NotificationSettings.jsp");
            return;
        }

        streamJSPUserLoggedIn(ar, userKey, "NotificationSettings.jsp");
    }
    @RequestMapping(value = "/{userKey}/LearningPath.htm", method = RequestMethod.GET)
    public void learningPath(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        streamJSPUserLoggedIn(ar, userKey, "LearningPath.jsp");
    }

    @RequestMapping(value = "/unsubscribe.htm", method = RequestMethod.GET)
    public void unsubscribe(
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{

            if(ar.isLoggedIn()){
                UserProfile profile = ar.getUserProfile();
                ar.resp.sendRedirect(ar.baseURL+"v/"+profile.getKey()+"/NotificationSettings.htm");
                return;
            }

            String userKey = ar.defParam("userKey", null);

            if(userKey != null){
                UserProfile userProfile = UserManager.getUserProfileOrFail(userKey);
                String accessCode = ar.defParam("accessCode", null);
                if(userProfile != null && userProfile.getAccessCode().equals(accessCode)){
                    ar.setSpecialSessionAccess("Notifications:"+userKey);
                    ar.resp.sendRedirect(ar.baseURL+"v/"+userKey+"/NotificationSettings.htm");
                    return;
                }
            }
            sendRedirectToLogin(ar);
        }catch(Exception e){
            showDisplayException(ar, WeaverException.newWrap(
                "Failed to open notification settings page for user (%s)", 
                e, ar.getBestUserId()));
        }
    }

    @RequestMapping(value = "/{userKey}/UserSettings.htm", method = RequestMethod.GET)
    public void userSettings(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {

        streamJSPUserLogged2(request, response, userKey, "UserSettings.jsp");
    }
    
    
    @RequestMapping(value = "/{userKey}/FacSettings.htm", method = RequestMethod.GET)
    public void facSettings(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {

        streamJSPUserLogged2(request, response, userKey, "FacSettings.jsp");
    }



    @RequestMapping(value = "/{userKey}/searchNotes.json", method = RequestMethod.POST)
    public void searchPublicNotesJSON(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            ar.assertLoggedIn("Must be logged in to search the topics");

            JSONObject query = getPostedObject(ar);

            String searchText    = query.getString("searchFilter");
            // query.getString("searchSite") is not used because for a user there is no current site
            String searchProject = query.getString("searchProject");

            List<SearchResultRecord> searchResults = null;
            if (searchText.length()>0) {
                searchResults = ar.getCogInstance().performSearch(ar, searchText, searchProject, null, null);
            }
            else {
                searchResults = new ArrayList<SearchResultRecord>();
            }

            JSONArray resultList = new JSONArray();
            for (SearchResultRecord srr : searchResults) {
                resultList.put(srr.getJSON());
            }
            sendJsonArray(ar, resultList);
        }catch(Exception ex){
            Exception ee = WeaverException.newWrap("Unable to search for notes.", ex);
            streamException(ee, ar);
        }
    }


/*
    private static void removeFromRole(NGWorkspace ngw, AddressListEntry ale, String[] stopRolePlayer) throws Exception {
        if(stopRolePlayer != null && stopRolePlayer.length > 0){
            NGRole role = null;
            for (String roleName : stopRolePlayer) {
                role = ngw.getRoleOrFail(roleName);
                role.removePlayer(ale);
            }
            ngw.getSite().flushUserCache();
        }
    }
*/
    
    @RequestMapping(value = "/{userKey}/PersonShow.htm", method = RequestMethod.GET)
    public void personShow(@PathVariable String userKey, 
                           HttpServletRequest request, 
                           HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            UserProfile searchedFor = UserManager.lookupUserByAnyId(userKey);
            ar.req.setAttribute("userKey",  userKey);
            if (searchedFor==null) {
                if (userKey.indexOf("@")<0) {
                    showDisplayWarning(ar, "Can't find any person with that key ("+userKey+").  Maybe that person no longer has an account, or maybe there was some other mistake.");
                    return;
                }
                //this looks like an email address, so display non-profile display
                streamJSPAnon(ar, "PersonMissing.jsp");
                return;
            }
            showJSPDependingUser(ar, "PersonShow.jsp");
        }
        catch(Exception ex){
            throw WeaverException.newWrap("Failure trying to find user", ex);
        }
    }



    @RequestMapping(value = "/FindPerson.htm", method = RequestMethod.GET)
    public void FindPerson(HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            
            //new parameter 'key' but support old 'uid' in case still there somewhere
            String userKey = ar.defParam("key", null);
            if (userKey==null || userKey.length()==0) {
                userKey = ar.defParam("uid", null);
            }
            if (userKey==null || userKey.length()==0) {
                showDisplayWarning(ar, "The FindPerson page requires an ID to search for but that appears to be missing from the URL.");
                return;
            }
            ar.req.setAttribute("userKey",  userKey);
            UserProfile searchedFor = UserManager.lookupUserByAnyId(userKey);
            if (searchedFor!=null) {
                //so if we find it, just redirect to the settings page
                response.sendRedirect(ar.retPath+"v/"+searchedFor.getKey()+"/PersonShow.htm");
                return;
            }
            if (userKey.indexOf("@")<0) {
                showDisplayWarning(ar, "Can't find any person with that key ("+userKey+").  Maybe that person no longer has an account, or maybe there was some other mistake.");
                return;
            }
            //this looks like an email address, so display non-profile display
            streamJSPAnon(ar, "PersonMissing.jsp");
            return;
        }catch(Exception ex){
            showDisplayException(ar, WeaverException.newWrap("Failure trying to find user", ex));
        }
    }


    @RequestMapping(value="/{userKey}/addEmailAddress.htm", method = RequestMethod.GET)
    public void addEmailAddress(
            HttpServletRequest request,
            HttpServletResponse response,
            @PathVariable String userKey) throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            ar.assertLoggedIn("must be logged in to add an email address");
            Cognoscenti cog = ar.getCogInstance();

            String newEmail = ar.reqParam("newEmail");
            UserProfile user = ar.getUserProfile();
            UserCacheMgr cacheMgr = cog.getUserCacheMgr();
            UserCache uCache = cacheMgr.getCache(user.getKey());
            String token = uCache.genEmailAddressAttempt(newEmail);

            File templateFile = cog.getConfig().getFileFromRoot("email/ConfirmEmail.chtml");
            OptOutAddr ooa = new OptOutAddr(AddressListEntry.findOrCreate(newEmail));
            String confirmAddress = "v/" + userKey + "/confirmEmailAddress.htm?token=" + token;

            JSONObject mailData = user.getJSON();
            mailData.put("url", ar.baseURL + confirmAddress);
            mailData.put("newEmail", newEmail);
            mailData.put("token", token);

            MailInst mi = MailInst.genericEmail("$", "$", "Confirm your email address", "");
            mi.setBodyFromTemplate(templateFile, mailData, ooa);
            EmailSender.generalMailToOne(mi, user.getAddressListEntry(), ooa);
            sendJson(ar, mi.getJSON());

        }catch(Exception ex){
            streamException(ex,ar);
        }
    }


    @RequestMapping(value="/{userKey}/confirmEmailAddress.htm", method = RequestMethod.GET)
    public void confirmEmailAddress(
            HttpServletRequest request,
            HttpServletResponse response,
            @PathVariable String userKey) throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            if(!ar.isLoggedIn()) {
                showDisplayWarning(ar, "Please log in first, and then try another time to click on the email token.");
                return;
            }
            if (userKey==null || userKey.isEmpty()) {
                showDisplayWarning(ar, "Weaver can not understand that email verfication link.  It appears to be improperly formed.  Please request a new email verification link.");
                return;
            }
            Cognoscenti cog = ar.getCogInstance();
            UserProfile user = cog.getUserManager().findUserByAnyIdOrFail(userKey);

            String token = ar.reqParam("token");
            UserCacheMgr cacheMgr = cog.getUserCacheMgr();
            UserCache uCache = cacheMgr.getCache(user.getKey());
            String message = uCache.verifyEmailAddressAttempt(user, token);
            showDisplayWarning(ar, message);
        }catch(Exception ex){
            showDisplayException(ar, ex);
        }
    }


    @RequestMapping(value="/{userKey}/sendEmail", method = RequestMethod.POST)
    public void sendEmail(
            HttpServletRequest request,
            HttpServletResponse response,
            @PathVariable String userKey) throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            Cognoscenti cog = ar.getCogInstance();
            UserProfile destinationUser = cog.getUserManager().findUserByAnyIdOrFail(userKey);
            JSONObject postObject = this.getPostedObject(ar);

            UserProfile fromUser = ar.getUserProfile();
            postObject.put("from", fromUser.getJSON());

            AddressListEntry toUser = AddressListEntry.findOrCreate(destinationUser.getPreferredEmail());
            OptOutAddr ooa = new OptOutAddr(toUser);
            postObject.put("to", toUser.getJSON());

            postObject.put("baseURL", ar.baseURL);
            postObject.put("optout", ooa.getUnsubscribeJSON(ar));
            
            String subject = postObject.optString("subject");
            if (subject==null || subject.length()==0) {
                subject = "Email from "+fromUser.getName()+" to "+toUser.getName();
            }

            File templateFile = ar.getCogInstance().getConfig().getFileFromRoot("email/DirectEmail.chtml");

            MailInst mi = MailInst.genericEmail("$", "$", subject, "");
            mi.setBodyFromTemplate(templateFile, postObject, ooa);
            EmailSender.generalMailToOne(mi, fromUser.getAddressListEntry(), ooa);

            sendJson(ar, mi.getJSON());
        }catch(Exception ex){
            streamException(ex,ar);
        }
    }

    ///////////////////////// Eamil ///////////////////////

    @RequestMapping(value = "/{userKey}/QueryUserEmail.json", method = RequestMethod.POST)
    public void queryEmail(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            Cognoscenti cog = ar.getCogInstance();
            UserProfile user = cog.getUserManager().findUserByAnyIdOrFail(userKey);
            if (!user.equals(ar.getUserProfile()) && !ar.isSuperAdmin()) {
                throw WeaverException.newBasic("User email list is accessible only from the user themselves, or administrator.");
            }
            JSONObject posted = this.getPostedObject(ar);
            posted.put("userKey", user.getKey());
            posted.put("userEmail", user.getPreferredEmail());

            JSONObject repo = EmailSender.queryUserEmail(posted);

            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = WeaverException.newWrap("Unable to get email", ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{userKey}/GetFacilitatorInfo.json", method = RequestMethod.GET)
    public void getFacilitatorInfo(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            String key = request.getParameter("key");
            Cognoscenti cog = ar.getCogInstance();
            UserCache user = cog.getUserCacheMgr().getCache(key);

            JSONObject repo = user.getFacilitatorFields();
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = WeaverException.newWrap("Unable to get email", ex);
            streamException(ee, ar);
        }
    }
    
    @RequestMapping(value = "/{userKey}/UpdateFacilitatorInfo.json", method = RequestMethod.POST)
    public void updateFacilitatorInfo(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            String key = request.getParameter("key");
            Cognoscenti cog = ar.getCogInstance();
            UserCache user = cog.getUserCacheMgr().getCache(key);
            UserProfile uProf = UserManager.getUserProfileByKey(key);
            JSONObject posted = getPostedObject(ar);
            
            user.updateFacilitator(posted);
            user.save();
            
            uProf.setFacilitator(posted.getBoolean("isActive"));
            cog.getUserManager().saveUserProfiles();
            
            
            JSONObject repo = user.getFacilitatorFields();
            sendJson(ar, repo);
        }
        catch(Exception ex){
            Exception ee = WeaverException.newWrap("Unable to get email", ex);
            streamException(ee, ar);
        }
    }

    //refresh every 15 minutes, but keeping a copy here speeds up the client side.
    long mailProblemCacheTime = 0;
    JSONObject cacheMailProblem = new JSONObject();
    private synchronized JSONObject getMailProblems(AuthRequest ar) throws Exception {
        
        //dummy code to make a good response because we are not longer
        //using SendGrid and this must be rewritted for another service.
        
        cacheMailProblem.requireJSONArray("blocks");
        cacheMailProblem.requireJSONArray("bounces");
        cacheMailProblem.requireJSONArray("spams");
        
        /*  OLD CODE FOR SendGrid:
        if (mailProblemCacheTime < System.currentTimeMillis()-15*60*1000) {
            //it has been 15 minutes since fetching
            Cognoscenti cog = ar.getCogInstance();
            
            String apiKey = cog.getConfig().getProperty("sendGridKey");
            
            long oneYearAgo = (System.currentTimeMillis()/1000)-365*24*60*60;
            
            APIClient client = new APIClient();
            client.expectArray = true;
            client.setHeader("Authorization", "Bearer "+apiKey);
            URL url = new URL("https://api.sendgrid.com/v3/suppression/blocks?start_time="+oneYearAgo);
            JSONObject blocks = client.getFromRemote(url);
            
            url = new URL("https://api.sendgrid.com/v3/suppression/bounces?start_time="+oneYearAgo);
            JSONObject bounces = client.getFromRemote(url);

            url = new URL("https://api.sendgrid.com/v3/suppression/spam_reports?start_time="+oneYearAgo);
            JSONObject spams = client.getFromRemote(url);

            JSONObject res = new JSONObject();
            res.put("blocks", blocks.getJSONArray("list"));
            res.put("bounces", bounces.getJSONArray("list"));
            res.put("spams", spams.getJSONArray("list"));
            cacheMailProblem = res;
            mailProblemCacheTime = System.currentTimeMillis();
        }
        */
        return cacheMailProblem;
    }
    
    
    @RequestMapping(value = "/{userKey}/MailProblems.json", method = RequestMethod.GET)
    public void mailProblems(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
                sendJson(ar, getMailProblems(ar));
        }
        catch (Exception ex) {
            Exception ee = WeaverException.newWrap("Unable to get mail blockers", ex);
            streamException(ee, ar);
        }
    }
    @RequestMapping(value = "/{userKey}/MailProblemsUser.json", method = RequestMethod.GET)
    public void mailProblemsUser(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            UserProfile uProf = UserManager.getUserProfileByKey(userKey);
            JSONObject problems = getMailProblems(ar);
            
            JSONArray userBlocks = new JSONArray();
            for (JSONObject block : problems.getJSONArray("blocks").getJSONObjectList()) {
                String email = block.getString("email");
                if (uProf.hasAnyId(email)) {
                    userBlocks.put(block);
                }
            }
            JSONArray userBounces = new JSONArray();
            for (JSONObject block : problems.getJSONArray("bounces").getJSONObjectList()) {
                String email = block.getString("email");
                if (uProf.hasAnyId(email)) {
                    userBounces.put(block);
                }
            }
            JSONArray userSpams = new JSONArray();
            for (JSONObject block : problems.getJSONArray("spams").getJSONObjectList()) {
                String email = block.getString("email");
                if (uProf.hasAnyId(email)) {
                    userSpams.put(block);
                }
            }
            
            JSONObject res = new JSONObject();
            res.put("blocks", userBlocks);
            res.put("bounces", userBounces);
            res.put("spams", userSpams);

            sendJson(ar, res);
        }
        catch(Exception ex){
            Exception ee = WeaverException.newWrap("Unable to get mail blockers", ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{userKey}/ClearLearningDone.json", method = RequestMethod.POST)
    public void clearLearningPath(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            UserProfile user = ar.getUserProfile();
            if (user==null) {
                throw WeaverException.newBasic("User is not logged in or has no user profile");
            }
            UserPage userPage = user.getUserPage();
            userPage.clearAllLearning();
            userPage.saveUserPage(ar, "Cleared all learning flags");
            
            JSONObject res = new JSONObject();
            res.put("status", "cleared");
            sendJson(ar, res);
        }
        catch(Exception ex){
            Exception ee = WeaverException.newWrap("Unable to clear all learning flags", ex);
            streamException(ee, ar);
        }
    }

    /**
     * This method is primarily for uploading a temporary file 
     * for the use as a user icon.
     */
    @RequestMapping(value = "/{userKey}/TempFile/{tempName}", method = RequestMethod.PUT)
    public void doPut(@PathVariable String userKey, @PathVariable String tempName, 
            HttpServletRequest req, HttpServletResponse resp) {
        AuthRequest ar = AuthRequest.getOrCreate(req, resp);
        try {
            System.out.println("USER_PUT: "+ar.getCompleteURL());
            if (!tempName.startsWith("~tmp")) {
                throw WeaverException.newBasic("Temporary file name (%s) is not valid for use as temp file.  Must request a temp file name from the system.", 
                tempName);
            }
            File userfolder = ar.getCogInstance().getConfig().getUserFolderOrFail();
            File tempFile = new File(userfolder, tempName);
            if (tempFile.exists()) {
                throw WeaverException.newBasic("Temporary file (%s) already exists.  Should only be used once.", 
                tempName);
            }
            InputStream is = ar.req.getInputStream();
            FileOutputStream fos = new FileOutputStream(tempFile);
            StreamHelper.copyInputToOutput(is, fos);
            fos.flush();
            fos.close();
            
            //now wait to make sure it is actually there in the file system
            if (!tempFile.exists()) {
                //we had a problem where requests were getting here but the temp file did not exist
                //but inspection showed the file to exist.  There might be a delay in uploading the 
                //file due to caching delays.   This just waits for up to 4 seconds to see if the
                //file appears in the file system after a delay.
                int count = 0;
                while (!tempFile.exists() && count++ < 20) {
                    System.out.println("WAITING "+count+" FOR PUT FILE: "+tempFile.toString());
                    Thread.sleep(200);
                }
                throw WeaverException.newBasic("PUT temp file failed.  Can't see it in file system: %s", tempFile);
            }
            System.out.println("    PUT: file written: "+tempFile.getAbsolutePath());
            JSONObject result = new JSONObject();
            result.put("responseCode", 200);
            result.write(ar.resp.getWriter(), 2, 0);
        }
        catch (Exception e) {
            Exception ctx = WeaverException.newWrap("Unable to handle PUT to %s", e, ar.getCompleteURL());
            streamException(ctx, ar);
        }
    }

    @RequestMapping(value = "/{userKey}/UserPostOps.json", method = RequestMethod.POST)
    private void userPostOps(@PathVariable String userKey,
    HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try {
            JSONObject responseOK = new JSONObject();
            responseOK.put("responseCode", 200);
            JSONObject input = getPostedObject(ar);
            String op = input.getString("op");

            if ("tempFile".equals(op)) {
                String fileName = "~tmp~"+IdGenerator.generateKey()+".jpg";
                responseOK.put("tempFileName", fileName);
                responseOK.put("tempFileURL", ar.getServerPath() + "v/" + userKey + "/TempFile/" + fileName + "?lic=95125");
                responseOK.write(ar.resp.getWriter(), 2, 0);
                ar.flush();
                return;
            }

            if ("finishIcon".equals(op)) {
                String tempFileName = input.getString("tempFileName");
                File userfolder = ar.getCogInstance().getConfig().getUserFolderOrFail();
                File tempFile = new File(userfolder, tempFileName);
                File tempFile2 = new File(userfolder, tempFileName+"~2");
    
                if (!tempFile.exists()) {
                    throw WeaverException.newBasic("Can not fine temporary file (%s), can not make an icon from that", tempFileName);
                }
                File userIconFile = new File(userfolder, userKey.toLowerCase() + ".jpg");
                Thumbnail.makeSquareFile(tempFile, tempFile2, 100);
                tempFile.delete();
                if (tempFile2.length()>999999) {
                    throw WeaverException.newBasic("Temporary file (%s) is more than 1MB in size, and can not be used as an icon.", tempFileName);
                }

                if (userIconFile.exists()) {
                    userIconFile.delete();
                }
                tempFile2.renameTo(userIconFile);

                System.out.println("USER ICON: updated: "+userIconFile.getAbsolutePath());
                responseOK.put("tempFileName", tempFileName);
                responseOK.put("iconFileName", userIconFile.getName());
                responseOK.write(ar.resp.getWriter(), 2, 0);
                ar.flush();
                return;
            }

            throw WeaverException.newBasic("UserPostOps does not understand operation: %s", op);
        }
        catch (Exception e) {
            streamException(WeaverException.newWrap(
                "Failed to handle post operation for user (%s).", 
                e, userKey), ar);
        }
    }
  
}

