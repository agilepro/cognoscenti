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
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import jxl.Cell;
import jxl.Sheet;
import jxl.Workbook;

import com.purplehillsbooks.weaver.AccessControl;
import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.AuthDummy;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.BaseRecord;
import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.DOMFace;
import com.purplehillsbooks.weaver.EmailListener;
import com.purplehillsbooks.weaver.GoalRecord;
import com.purplehillsbooks.weaver.HistoryRecord;
import com.purplehillsbooks.weaver.MicroProfileMgr;
import com.purplehillsbooks.weaver.NGContainer;
import com.purplehillsbooks.weaver.NGPageIndex;
import com.purplehillsbooks.weaver.NGRole;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.OptOutAddr;
import com.purplehillsbooks.weaver.OptOutIndividualRequest;
import com.purplehillsbooks.weaver.ProfileRef;
import com.purplehillsbooks.weaver.ReminderMgr;
import com.purplehillsbooks.weaver.ReminderRecord;
import com.purplehillsbooks.weaver.RoleRequestRecord;
import com.purplehillsbooks.weaver.SearchResultRecord;
import com.purplehillsbooks.weaver.UserCache;
import com.purplehillsbooks.weaver.UserCacheMgr;
import com.purplehillsbooks.weaver.UserManager;
import com.purplehillsbooks.weaver.UserPage;
import com.purplehillsbooks.weaver.UserProfile;
import com.purplehillsbooks.weaver.api.RemoteProfile;
import com.purplehillsbooks.weaver.dms.FolderAccessHelper;
import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.exception.ProgramLogicError;
import com.purplehillsbooks.weaver.mail.EmailSender;
import com.purplehillsbooks.weaver.mail.MailInst;
import com.purplehillsbooks.weaver.util.Thumbnail;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.ServletRequestDataBinder;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.multipart.support.ByteArrayMultipartFileEditor;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.MemFile;


@Controller
public class UserController extends BaseController {



    public void streamJSPUserLoggedIn(AuthRequest ar, String userKey, String jspName) throws Exception {
        try {
            if(!ar.isLoggedIn()){
                ar.req.setAttribute("property_msg_key", "nugen.project.login.msg");
                streamJSP(ar, "Warning.jsp");
                return;
            }
            UserProfile up = UserManager.getUserProfileOrFail(userKey);
            ar.req.setAttribute("userProfile", up);
            ar.req.setAttribute("userKey", up.getKey());
            streamJSPUser(ar, jspName+".jsp");
        }
        catch (Exception e) {
            throw new Exception("Unable to prepare page ("+jspName+") for user ("+userKey+")", e);
        }
    }

    private void streamJSPUserLogged2(HttpServletRequest request, HttpServletResponse response,
            String userKey, String viewName) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        streamJSPUserLoggedIn(ar, userKey, viewName);
    }




    ////////////////////// MAIN VIEWS /////////////////////////


    @RequestMapping(value = "/{userKey}/UserHome.htm", method = RequestMethod.GET)
    public void userHome(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "UserHome");
    }
    
    //this one just in case someone had bookmarked the old value
    @RequestMapping(value = "/{userKey}/userHome.htm", method = RequestMethod.GET)
    public void userHome2(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "UserHome");
    }


    @RequestMapping(value = "{userKey}/WatchedProjects.htm", method = RequestMethod.GET)
    public void watchedProjects(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        streamJSPUserLogged2(request, response, userKey, "WatchedProjects");
    }

    @RequestMapping(value = "/{userKey}/notifiedProjects.htm", method = RequestMethod.GET)
    public void notifiedProjects(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        streamJSPUserLogged2(request, response, userKey, "NotifiedProjects");
    }

    @RequestMapping(value = "/{userKey}/OwnerProjects.htm", method = RequestMethod.GET)
    public void ownerProjects(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        streamJSPUserLogged2(request, response, userKey, "OwnerProjects");
    }


    @RequestMapping(value = "/{userKey}/templates.htm", method = RequestMethod.GET)
    public void templates(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        streamJSPUserLogged2(request, response, userKey, "Templates");
    }

    @RequestMapping(value = "/{userKey}/ParticipantProjects.htm", method = RequestMethod.GET)
    public void participantProjects(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        streamJSPUserLogged2(request, response, userKey, "ParticipantProjects");
    }

    @RequestMapping(value = "/{userKey}/AllProjects.htm", method = RequestMethod.GET)
    public void allProjects(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "AllProjects");
    }



    @RequestMapping(value = "/{userKey}/UserAlerts.htm", method = RequestMethod.GET)
    public void loadUserAlerts(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "UserAlerts");
    }


    @RequestMapping(value = "/{userKey}/UserActiveTasks.htm", method = RequestMethod.GET)
    public void userActiveTasks(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "UserActiveTasks");
    }

    @RequestMapping(value = "/{userKey}/userMissingResponses.htm", method = RequestMethod.GET)
    public void userMissingResponses(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "UserMissingResponses");
    }

    @RequestMapping(value = "/{userKey}/userOpenRounds.htm", method = RequestMethod.GET)
    public void userOpenRounds(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "UserOpenRounds");
    }


    @RequestMapping(value = "/{userKey}/ShareRequests.htm", method = RequestMethod.GET)
    public void ShareRequests(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "ShareRequests");
    }

    @RequestMapping(value = "/{userKey}/userSites.htm", method = RequestMethod.GET)
    public void loadUserAccounts(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "UserAccounts");
    }

    @RequestMapping(value = "/{userKey}/UserProfileEdit.htm")
    public void changeUserProfile(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        request.setAttribute("userKey", userKey);
        streamJSPUserLogged2(request, response, userKey, "UserProfileEdit");
    }



    @RequestMapping(value = "/{userKey}/searchAllNotes.htm")
    public void searchAllNotes(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        request.setAttribute("userKey", userKey);
        streamJSPUserLogged2(request, response, userKey, "SearchAllNotes");
    }



    @RequestMapping(value = "/{userKey}/RemoteProfileAction.form", method = RequestMethod.POST)
    public void RemoteProfileAction(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if (warnNotLoggedIn(ar)) {
                return;
            }
            String address = ar.reqParam("address");
            String go = ar.reqParam("go");
            String act = ar.reqParam("act");
            UserProfile userBeingViewed = UserManager.getUserProfileOrFail(userKey);
            UserPage uPage = userBeingViewed.getUserPage();
            if ("Create".equals(act)) {
                ProfileRef pr = uPage.findOrCreateProfileRef(address);
                pr.setLastAccess(ar.nowTime);
            }
            else if ("Delete".equals(act)) {
                uPage.deleteProfileRef(address);
            }
            else {
                throw new Exception("RemoteProfileAction does not understand the act "+act);
            }
            uPage.save();

            redirectBrowser(ar, go);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.usertask.page", new Object[]{userKey} , ex);
        }
    }

    @RequestMapping(value = "/{userKey}/RemoteProfileUpdate.json", method = RequestMethod.POST)
    public void RemoteProfileUpdate(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            if(!ar.isLoggedIn()){
                throw new Exception("Must be logged in.");
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
                throw new Exception("RemoteProfileAction does not understand the act "+act);
            }
            uPage.save();
            ar.flush();
        }catch(Exception ex){
            Exception ee = new Exception("Unable to get update from remote profile.", ex);
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
                    throw new Exception("User "+userEditing.getName()+" is not allowed to edit the profile of user "+userBeingEdited.getName());
                }
            }

            JSONObject newUserSettings = this.getPostedObject(ar);
            userBeingEdited.updateFromJSON(newUserSettings);
            UserManager.writeUserProfilesToFile();

            JSONObject userObj = userBeingEdited.getFullJSON();
            sendJson(ar, userObj);
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to update user "+userKey, ex);
            streamException(ee, ar);
        }
    }




    @RequestMapping(value = "/{userKey}/uploadImage.form", method = RequestMethod.POST)
    protected void uploadImageFile(HttpServletRequest request,
            HttpServletResponse response,
            @PathVariable String userKey,
            @RequestParam("fname") MultipartFile fileInPost) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn( "Must be logged in in order to upload an image file.");
            if (fileInPost.getSize() == 0) {
                throw new NGException("nugen.exceptionhandling.no.file.attached",null);
            }
            if(fileInPost.getSize() > 500000000){
                throw new NGException("nugen.exceptionhandling.file.size.exceeded",new Object[]{"500000000"});
            }

            UserProfile profile = UserManager.getUserProfileOrFail(userKey);

            String uploadedFileName = fileInPost.getOriginalFilename();
            if (uploadedFileName == null || uploadedFileName.length()==0) {
                throw new NGException("nugen.exceptionhandling.filename.empty",null);
            }
            int dotPos = uploadedFileName.lastIndexOf(".");
            String fileExtension = uploadedFileName.substring(dotPos).toLowerCase();
            if (!".jpg".equals(fileExtension)) {
                throw new Exception("You must upload a JPG file, got: "+uploadedFileName);
            }


            File userImageFolder = ar.getCogInstance().getConfig().getUserFolderOrFail();
            String newImageName = profile.getKey()+fileExtension;
            newImageName = newImageName.toLowerCase();
            File newUserImage = new File(userImageFolder, newImageName);
            File userImageTmpFile = new File(userImageFolder, newImageName+".~TMP"+System.currentTimeMillis());

            File userImageTmpFile2 = new File(userImageFolder, newImageName+".~TMP2"+System.currentTimeMillis());

            //clean out any tmp file that might be left around
            if (userImageTmpFile.exists()) {
                userImageTmpFile.delete();
            }
            if (userImageTmpFile2.exists()) {
                userImageTmpFile2.delete();
            }

            //write the image content to the temp file
            AttachmentHelper.saveToFileAH(fileInPost, userImageTmpFile2);

            Thumbnail.makeSquareFile(userImageTmpFile2,userImageTmpFile,100);

            userImageTmpFile2.delete();


            String oldImageName = profile.getImage();
            if (oldImageName!=null) {
                File oldUserImage = new File(userImageFolder, oldImageName);
                //delete the old image if it existed
                if(oldUserImage.exists()){
                    oldUserImage.delete();
                }
            }
            //get rid of any garbage that might exist with the new name
            if(newUserImage.exists()){
                newUserImage.delete();
            }
            //now change the name of the newly uploaded file
            if (!userImageTmpFile.renameTo(newUserImage)) {
                throw new NGException("nugen.exceptionhandling.unable.rename.tempfile",
                        new Object[]{userImageTmpFile.toString(),newUserImage.toString()});
            }

            //just a consistency check to make sure everything worked
            if (userImageTmpFile.exists()) {
                throw new ProgramLogicError("Temporary file should not exist, but for some reason it does: "
                        +userImageTmpFile.toString());
            }

            //set the new name into the profile and save it
            profile.setLastUpdated(ar.nowTime);
            ar.getCogInstance().getUserManager().saveUserProfiles();

            redirectBrowser(ar,"UserProfileEdit.htm?u="+userKey);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.upload.user.image.page",
                    new Object[]{userKey} , ex);
        }
    }



    @RequestMapping(value = "/{siteId}/{pageId}/approveOrRejectRoleReqThroughMail.htm", method = RequestMethod.GET)
    public void gotoApproveOrRejectRoleReqPage(
            @PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGContainer ngc =  registerSiteOrProject(ar, siteId, pageId);

            String requestId = ar.reqParam("requestId");
            RoleRequestRecord roleRequestRecord = ngc.getRoleRequestRecordById(requestId);
            if (roleRequestRecord==null) {
                throw new Exception("Unable to find a role request record with id="+requestId);
            }
            boolean canAccessPage = AccessControl.canAccessRoleRequest(ar, ngc, roleRequestRecord);

            if(!canAccessPage){
                if (ar.isLoggedIn()) {
                    streamJSP(ar, "WarningNotMember.jsp");
                }
                else {
                    showWarningView(ar, "nugen.project.login.msg");
                }
                return;
            }

            String isAccessThroughEmail = ar.reqParam("isAccessThroughEmail");

            request.setAttribute("realRequestURL", ar.getRequestURL());

            request.setAttribute("isAccessThroughEmail", isAccessThroughEmail);
            request.setAttribute("canAccessPage", canAccessPage);
            streamJSP(ar, "RoleRequest.jsp");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.approve.reject.rolereq.page", null , ex);
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
            Exception ee = new Exception("Unable to update micro profile.", ex);
            streamException(ee, ar);
        }
    }




    @RequestMapping(value = "/{userKey}/NotificationSettings.htm", method = RequestMethod.GET)
    public void goToNotificationSetting(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);

            if(ar.hasSpecialSessionAccess("Notifications:"+userKey)){
                //need to show this even if not logged in
                streamJSP(ar, "NotificationSettings.jsp");
                return;
            }

            //this will fail if not logged in
            streamJSPUserLoggedIn(ar, userKey, "NotificationSettings");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.open.notification.page", new Object[]{userKey} , ex);
        }
    }

    @RequestMapping(value = "/unsubscribe.htm", method = RequestMethod.GET)
    public void unsubscribe(
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);

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
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.open.notification.page", null , ex);
        }
    }

    @RequestMapping(value="/{userKey}/saveNotificationSettings.form", method = RequestMethod.POST)
    public void saveNotificationSettings(
            @PathVariable String userKey,
            HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        try{
            AuthRequest ar =  AuthRequest.getOrCreate(request, response);
            if(!ar.hasSpecialSessionAccess("Notifications:"+userKey)){
                ar.assertLoggedIn("Can not update notification settings.");
            }
            String pageId = ar.reqParam("pageId");

            NGWorkspace ngw = ar.getCogInstance().getWSByCombinedKeyOrFail(pageId).getWorkspace();
            ar.setPageAccessLevels(ngw);
            UserProfile up = UserManager.getUserProfileOrFail(userKey);

            String sendDigest = ar.defParam("sendDigest", null);
            if(sendDigest != null && "never".equals(sendDigest)){

                up.clearNotification( ngw.getKey());
                ar.getCogInstance().getUserManager().saveUserProfiles();
            }

            int eventType = HistoryRecord.EVENT_TYPE_MODIFIED;
            String[] tasksToBeCompleted= ar.req.getParameterValues("markascompleted");
            if(tasksToBeCompleted != null && tasksToBeCompleted.length > 0){
                GoalRecord taskRecord = null;
                for (String taskId : tasksToBeCompleted) {
                    taskRecord = ngw.getGoalOrFail(taskId);
                    taskRecord.setEndDate(ar.nowTime);
                    taskRecord.setStateAndAct(BaseRecord.STATE_COMPLETE, ar);
                    eventType = HistoryRecord.EVENT_TYPE_STATE_CHANGE_COMPLETE;
                    taskRecord.setModifiedDate(ar.nowTime);
                    taskRecord.setModifiedBy(ar.getBestUserId());
                    HistoryRecord.createHistoryRecord(ngw, taskRecord.getId(),
                            HistoryRecord.CONTEXT_TYPE_TASK, eventType, ar, "task completed");
                }
            }

            String[] tasksToBeUnassigned= ar.req.getParameterValues("unassign");
            if(tasksToBeUnassigned != null && tasksToBeUnassigned.length > 0){
                GoalRecord taskRecord = null;
                for (String taskId : tasksToBeUnassigned) {
                    taskRecord = ngw.getGoalOrFail(taskId);
                    taskRecord.getAssigneeRole().removePlayer(new AddressListEntry(up.getPreferredEmail()));
                    taskRecord.setModifiedDate(ar.nowTime);
                    taskRecord.setModifiedBy(ar.getBestUserId());
                    HistoryRecord.createHistoryRecord(ngw, taskRecord.getId(),
                            HistoryRecord.CONTEXT_TYPE_TASK,
                            HistoryRecord.EVENT_TYPE_MODIFIED, ar, "unassigned");
                }
            }

            String[] stopRolePlayer= ar.req.getParameterValues("stoproleplayer");
            removeFromRole(ngw, new AddressListEntry(up), stopRolePlayer);


            String[] stopReminding= ar.req.getParameterValues("stopReminding");
            if(stopReminding != null && stopReminding.length > 0){
                ReminderMgr rMgr = ngw.getReminderMgr();
                ReminderRecord rRec = null;
                for (String reminderId : stopReminding) {
                    rRec = rMgr.findReminderByID(reminderId);
                    rRec.setSendNotification("no");
                }
            }

            ngw.saveFile(ar,"updated notification settings");
            redirectBrowser(ar,"NotificationSettings.htm");

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.to.update.notification.settings", null, ex);
        }
    }



    @RequestMapping(value = "/{userKey}/userSettings.htm", method = RequestMethod.GET)
    public void userSettings(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(ar.isLoggedIn()){
                UserProfile uProf = UserManager.getUserProfileOrFail(userKey);
                UserProfile loggedInUser = ar.getUserProfile();

                String userName = loggedInUser.getName();

                if (userName==null || userName.length()==0) {
                    userName = loggedInUser.getKey();
                }
                if (userName.length()>28) {
                    userName = userName.substring(0,28);
                }

                String isRequestingForNewProjectUsingLinks = ar.defParam( "projectName", null );
                String bookForNewProject = ar.defParam( "bookKey", null );

                if(isRequestingForNewProjectUsingLinks!=null && bookForNewProject!=null){
                    List<NGPageIndex> foundPages = ar.getCogInstance().getPageIndexByName(isRequestingForNewProjectUsingLinks);
                    if(foundPages.size()>0){
                        NGPageIndex foundPage = foundPages.get( 0 );
                        response.sendRedirect(ar.retPath+"t/"+bookForNewProject+"/"+foundPage.containerKey+"/FrontPage.htm" );
                        return;
                    }
                }

                request.setAttribute("userName",userName);
            }
            streamJSPUserLogged2(request, response, userKey, "UserSettings");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.userprofile.page", new Object[]{userKey} , ex);
        }
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
            Exception ee = new Exception("Unable to search for notes.", ex);
            streamException(ee, ar);
        }
    }


/*
    private static JSONArray getPeopleListInJSONArray(AuthRequest ar, String searchStr)
    throws Exception {
        String displayName = "";
        String id = "";
        String profilelinkwithquote = "";
        String profilelink = "";
        JSONArray array = new JSONArray();
        List<AddressListEntry> list = ar.getUserPage().getPeopleYouMayKnowList();
        String go = ar.reqParam("go");
        for (AddressListEntry ale : list) {
            UserProfile profile = ale.getUserProfile();
            String srcOfPhoto = "assets/photoThumbnail.gif";
            displayName = ale.getName();
            if(profile != null){
                id = profile.getUniversalId();
                if(profile.getImage().length() > 0){
                    srcOfPhoto = "users/"+profile.getImage();
                }
                MemFile owner = new MemFile();
                AuthRequest clone = new AuthDummy(profile, owner.getWriter(), ar.getCogInstance());
                ale.writeLink(clone);
                clone.flush();
                profilelinkwithquote = ar.getQuote4JS(owner.toString());
                profilelink = owner.toString();
            }else{
                id = ale.getUniversalId();
                profilelink = "<a href=\"javascript:\" onclick=\"javascript:editDetail("+ar.getQuote4JS(id)+", "+ar.getQuote4JS(displayName)+",this,"+ar.getQuote4JS(go)+");\"><div>"+displayName+"&nbsp;&nbsp;(&nbsp;"+id+"&nbsp;)</div></a>";
                profilelinkwithquote = ar.getQuote4JS(profilelink);
            }
            String lookupInStr = id+" "+displayName;

            if(searchStr.trim().length()==0 || lookupInStr.toLowerCase().indexOf(searchStr.toLowerCase()) >=0 ){

                JSONObject jsonObj= new JSONObject();
                jsonObj.put("username", displayName);
                jsonObj.put("userid", id);
                jsonObj.put("srcOfPhoto", srcOfPhoto);
                jsonObj.put("profilelinkwithquote", profilelinkwithquote);
                jsonObj.put("profilelink", profilelink);
                jsonObj.put("go", go);
                array.put(jsonObj);
            }
        }
        return array;
    }
    */

    private static void removeFromRole(NGWorkspace ngp, AddressListEntry ale, String[] stopRolePlayer) throws Exception {
        if(stopRolePlayer != null && stopRolePlayer.length > 0){
            NGRole role = null;
            for (String roleName : stopRolePlayer) {
                role = ngp.getRoleOrFail(roleName);
                role.removePlayer(ale);
            }
            ngp.getSite().flushUserCache();
        }
    }

    
    /*
    private static void sendRoleRequestApprovedOrRejectionEmail(AuthRequest ar,
            String addressee, String subject, String responseComment,
            NGContainer ngp, String roleName, String action) throws Exception {
        Cognoscenti cog = ar.getCogInstance();
        MemFile bodyWriter = new MemFile();
        AuthRequest clone = new AuthDummy(ar.getUserProfile(), bodyWriter.getWriter(), ar.getCogInstance());
        clone.retPath = ar.baseURL;
        OptOutAddr ooa = new OptOutIndividualRequest(new AddressListEntry(
                addressee));

        JSONObject data = new JSONObject();
        data.put("aseURL",  ar.baseURL);
        data.put("roleName",  roleName);
        data.put("wsURL", clone.baseURL + clone.getDefaultURL(ngp));
        data.put("wsName", ngp.getFullName());
        data.put("isApproved", "approved".equalsIgnoreCase(action));
        data.put("responseComment", responseComment);

        File templateFile = cog.getConfig().getFileFromRoot("email/RoleResponse.chtml");

        EmailSender.containerEmail(ooa, ngp, subject, templateFile, data,
                null, new ArrayList<String>(), cog);
    }
    */


    @RequestMapping(value = "/FindPerson.htm", method = RequestMethod.GET)
    public void FindPerson(HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if (warnNotLoggedIn(ar)) {
                return;
            }
            String userKey = ar.reqParam("uid");
            UserProfile searchedFor = ar.getCogInstance().getUserManager().lookupUserByAnyId(userKey);
            if (searchedFor!=null) {
                //so if we find it, just redirect to the settings page
                response.sendRedirect(ar.retPath+"v/"+searchedFor.getKey()+"/userSettings.htm");
                return;
            }
            streamJSP(ar, "FindPerson.jsp");

        }catch(Exception ex){
            throw new Exception("Failure trying to find user", ex);
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
            OptOutAddr ooa = new OptOutAddr(user.getAddressListEntry());
            String confirmAddress = "v/" + userKey + "/confirmEmailAddress.htm?token=" + token;

            JSONObject mailData = user.getJSON();
            mailData.put("url", ar.baseURL + confirmAddress);
            mailData.put("newEmail", newEmail);
            mailData.put("token", token);

            MailInst mi = EmailSender.createEmailFromTemplate(ooa, newEmail, "Confirm your email address", templateFile, mailData);
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

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            Cognoscenti cog = ar.getCogInstance();
            UserProfile user = cog.getUserManager().findUserByAnyIdOrFail(userKey);


            String token = ar.reqParam("token");
            UserCacheMgr cacheMgr = cog.getUserCacheMgr();
            UserCache uCache = cacheMgr.getCache(user.getKey());
            if (!uCache.verifyEmailAddressAttempt(user, token)) {
                throw new Exception("Unable to confirm that email address");
            }

            redirectBrowser(ar,"userSettings.htm");
        }catch(Exception ex){
            throw new Exception("Email address not added to profile", ex);
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
            UserProfile user = cog.getUserManager().findUserByAnyIdOrFail(userKey);
            JSONObject postObject = this.getPostedObject(ar);

            AddressListEntry ale = new AddressListEntry(ar.getBestUserId());
            OptOutAddr ooa = new OptOutAddr(ale);
            postObject.put("from", ale.getJSON());

            AddressListEntry ale2 = new AddressListEntry(user.getPreferredEmail());
            postObject.put("to", ale2.getJSON());

            postObject.put("baseURL", ar.baseURL);
            postObject.put("optout", ooa.getUnsubscribeJSON(ar));

            File templateFile = ar.getCogInstance().getConfig().getFileFromRoot("email/DirectEmail.chtml");

            MailInst mi = EmailSender.createEmailFromTemplate( ooa, user.getPreferredEmail(),
                    postObject.getString("subject"), templateFile, postObject);

            sendJson(ar, mi.getJSON());
        }catch(Exception ex){
            streamException(ex,ar);
        }
    }



}

