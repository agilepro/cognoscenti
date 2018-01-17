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

package org.socialbiz.cog.spring;

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

import org.socialbiz.cog.AccessControl;
import org.socialbiz.cog.AddressListEntry;
import org.socialbiz.cog.AgentRule;
import org.socialbiz.cog.AuthDummy;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.BaseRecord;
import org.socialbiz.cog.Cognoscenti;
import org.socialbiz.cog.DOMFace;
import org.socialbiz.cog.EmailListener;
import org.socialbiz.cog.GoalRecord;
import org.socialbiz.cog.HistoryRecord;
import org.socialbiz.cog.MicroProfileMgr;
import org.socialbiz.cog.NGContainer;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.NGPageIndex;
import org.socialbiz.cog.NGRole;
import org.socialbiz.cog.OptOutAddr;
import org.socialbiz.cog.OptOutIndividualRequest;
import org.socialbiz.cog.ProfileRef;
import org.socialbiz.cog.ReminderMgr;
import org.socialbiz.cog.ReminderRecord;
import org.socialbiz.cog.RemoteGoal;
import org.socialbiz.cog.RoleRequestRecord;
import org.socialbiz.cog.SearchManager;
import org.socialbiz.cog.SearchResultRecord;
import org.socialbiz.cog.UserManager;
import org.socialbiz.cog.UserPage;
import org.socialbiz.cog.UserProfile;
import org.socialbiz.cog.api.RemoteProfile;
import org.socialbiz.cog.dms.FolderAccessHelper;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.socialbiz.cog.mail.EmailSender;
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

    protected void initBinder(HttpServletRequest request,
            ServletRequestDataBinder binder) throws ServletException {
        binder.registerCustomEditor(byte[].class,new ByteArrayMultipartFileEditor());
    }


    protected UserProfile getUserToDisplay(AuthRequest ar, String userKey) throws Exception {
        if ("$".equals(userKey) && ar.isLoggedIn()) {
            return ar.getUserProfile();
        }
        return UserManager.getUserProfileOrFail(userKey);
    }

    public void streamJSPUserLoggedIn(AuthRequest ar, String userKey, String jspName) throws Exception {
        try {
            if(!ar.isLoggedIn()){
                ar.req.setAttribute("property_msg_key", "nugen.project.login.msg");
                streamJSP(ar, "Warning");
                return;
            }
            UserProfile up = getUserToDisplay(ar, userKey);
            ar.req.setAttribute("userProfile", up);
            ar.req.setAttribute("userKey", up.getKey());
            streamJSP(ar, jspName);
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


    @RequestMapping(value = "/{userKey}/userProfile.htm", method = RequestMethod.GET)
    public void loadProfile(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        redirectBrowser(ar,"userSettings.htm");
    }

    @RequestMapping(value = "/{userKey}/userHome.htm", method = RequestMethod.GET)
    public void loadUserHome(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        redirectBrowser(ar,"watchedProjects.htm");
    }




    ////////////////////// MAIN VIEWS /////////////////////////


    @RequestMapping(value = "/{userKey}/UserHome.htm", method = RequestMethod.GET)
    public void userHome(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "../jsp/UserHome");
    }


    @RequestMapping(value = "{userKey}/watchedProjects.htm", method = RequestMethod.GET)
    public void watchedProjects(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        streamJSPUserLogged2(request, response, userKey, "../jsp/WatchedProjects");
    }

    @RequestMapping(value = "/{userKey}/notifiedProjects.htm", method = RequestMethod.GET)
    public void notifiedProjects(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        streamJSPUserLogged2(request, response, userKey, "../jsp/NotifiedProjects");
    }

    @RequestMapping(value = "/{userKey}/ownerProjects.htm", method = RequestMethod.GET)
    public void ownerProjects(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        streamJSPUserLogged2(request, response, userKey, "../jsp/OwnerProjects");
    }


    @RequestMapping(value = "/{userKey}/templates.htm", method = RequestMethod.GET)
    public void templates(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        streamJSPUserLogged2(request, response, userKey, "../jsp/Templates");
    }

    @RequestMapping(value = "/{userKey}/participantProjects.htm", method = RequestMethod.GET)
    public void participantProjects(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        streamJSPUserLogged2(request, response, userKey, "../jsp/ParticipantProjects");
    }

    @RequestMapping(value = "/{userKey}/allProjects.htm", method = RequestMethod.GET)
    public void allProjects(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "../jsp/AllProjects");
    }


    @RequestMapping(value = "/{userKey}/userCreateProject.htm", method = RequestMethod.GET)
    public void userCreateProject(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)  throws Exception {
        streamJSPUserLogged2(request, response, userKey, "../jsp/UserCreateProject");
    }



    @RequestMapping(value = "/{userKey}/userAlerts.htm", method = RequestMethod.GET)
    public void loadUserAlerts(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "../jsp/UserAlerts");
    }


    @RequestMapping(value = "/{userKey}/userActiveTasks.htm", method = RequestMethod.GET)
    public void userActiveTasks(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "../jsp/UserActiveTasks");
    }

    @RequestMapping(value = "/{userKey}/userMissingResponses.htm", method = RequestMethod.GET)
    public void userMissingResponses(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "../jsp/UserMissingResponses");
    }

    @RequestMapping(value = "/{userKey}/userOpenRounds.htm", method = RequestMethod.GET)
    public void userOpenRounds(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "../jsp/UserOpenRounds");
    }


    @RequestMapping(value = "/{userKey}/ShareRequests.htm", method = RequestMethod.GET)
    public void ShareRequests(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "../jsp/ShareRequests");
    }

    @RequestMapping(value = "/{userKey}/RemoteProfiles.htm", method = RequestMethod.GET)
    public void remoteProfiles(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "../jsp/RemoteProfiles");
    }

    @RequestMapping(value = "/{userKey}/Agents.htm", method = RequestMethod.GET)
    public void Agents(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "../jsp/Agents");
    }

    @RequestMapping(value = "/{userKey}/userRemoteTasks.htm", method = RequestMethod.GET)
    public void consolidatedTasks(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "../jsp/UserRemoteTasks");
    }

    @RequestMapping(value = "/{userKey}/EditAgent.htm", method = RequestMethod.GET)
    public void EditAgent(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if (ar.isLoggedIn()) {
                //only check if the user logged in, because the display will fail on that case
                UserProfile userBeingViewed = getUserToDisplay(ar, userKey);
                UserPage uPage = userBeingViewed.getUserPage();
                String agentId = ar.reqParam("id");
                AgentRule agent = uPage.findAgentRule(agentId);
                if (agent==null) {
                    throw new Exception("Unable to find an agent with id="+agentId);
                }
            }
            streamJSPUserLogged2(request, response, userKey, "../jsp/EditAgent");
        }
        catch(Exception ex){
            throw new NGException("nugen.operation.fail.usertask.page", new Object[]{userKey} , ex);
        }
    }

    @RequestMapping(value = "/{userKey}/userAccounts.htm", method = RequestMethod.GET)
    public void loadUserAccounts(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        streamJSPUserLogged2(request, response, userKey, "../jsp/UserAccounts");
    }

    @RequestMapping(value = "/{userKey}/editUserProfile.htm")
    public void changeUserProfile(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        request.setAttribute("userKey", userKey);
        streamJSPUserLogged2(request, response, userKey, "../jsp/edituserprofile");
    }

    @RequestMapping(value = "/{userKey}/ViewRemoteTask.htm", method = RequestMethod.GET)
    public void ViewRemoteTask(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        if(ar.isLoggedIn()){
            UserProfile userBeingViewed = getUserToDisplay(ar, userKey);
            UserPage uPage = userBeingViewed.getUserPage();
            String accessUrl = ar.reqParam("url");
            RemoteGoal rg =  uPage.findRemoteGoal(accessUrl);
            if (rg==null) {
                throw new Exception("unable to find a remote goal records with the url="+accessUrl);
            }
        }
        streamJSPUserLoggedIn(ar, userKey, "ViewRemoteTask");
    }

    /**
    * This lists the connections so that a user can select one when browsing
    * to attach a document.
    */
    @RequestMapping(value = "/{userKey}/ListConnections.htm", method = RequestMethod.GET)
    public void folderDisplay(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        streamJSPUserLoggedIn(ar, userKey, "ListConnections");
    }

    @RequestMapping(value = "/{userKey}/searchAllNotes.htm")
    public void searchAllNotes(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        request.setAttribute("userKey", userKey);
        streamJSPUserLogged2(request, response, userKey, "../jsp/SearchAllNotes");
    }



    @RequestMapping(value = "/AllPeople.json", method = RequestMethod.GET)
    public void AllPeople(HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        AuthRequest ar = null;
        try{
            ar = AuthRequest.getOrCreate(request, response);
            if (!ar.isLoggedIn()) {
                throw new Exception("Must be logged in to get users");
            }
            JSONArray peopleList = new JSONArray();
            List<AddressListEntry> userList = ar.getCogInstance().getUserManager().getAllPossibleUsers();
            for (AddressListEntry ale : userList) {
                JSONObject person = ale.getJSON();
                peopleList.put(person);
            }
            JSONObject result = new JSONObject();
            result.put("people", peopleList);
            sendJson(ar, result);
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to generate people information.", ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{userKey}/RemoteProfileAction.form", method = RequestMethod.POST)
    public void RemoteProfileAction(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if (checkLogin(ar)) {
                return;
            }
            String address = ar.reqParam("address");
            String go = ar.reqParam("go");
            String act = ar.reqParam("act");
            UserProfile userBeingViewed = getUserToDisplay(ar, userKey);
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
            UserProfile userBeingViewed = getUserToDisplay(ar, userKey);
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

    @RequestMapping(value = "/{userKey}/AgentAction.json", method = RequestMethod.POST)
    public void AgentAction(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            ar.assertLoggedIn("Must be logged in to look up agents.");

            UserProfile userBeingViewed = getUserToDisplay(ar, userKey);
            UserPage uPage = userBeingViewed.getUserPage();

            String aid = ar.reqParam("aid");
            JSONObject agentInfo = getPostedObject(ar);

            AgentRule agent = null;
            if ("~new~".equals(aid)) {
                agent = uPage.createAgentRule();
            }
            else {
                agent = uPage.findAgentRule(aid);
                if (agent==null) {
                    throw new Exception("Unable to find an agent with id = "+aid);
                }
            }
            agent.updateJSON(agentInfo);

            uPage.save();

            JSONObject repo = agent.getJSON();
            repo.write(ar.w, 2, 2);
            ar.flush();
        }catch(Exception ex){
            Exception ee = new Exception("Unable to update Agent for user.", ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{userKey}/RefreshFromRemoteProfiles.form", method = RequestMethod.POST)
    public void RefreshFromRemoteProfiles(@PathVariable String userKey,
            HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = NGWebUtils.getAuthRequest(request, response, "Can not update user contacts.");

            String go = ar.reqParam("go");

            UserProfile uProf = UserManager.getUserProfileByKey(userKey);
            UserPage uPage = uProf.getUserPage();

            List<ProfileRef> profRefs = uPage.getProfileRefs();
            for (ProfileRef pRef : profRefs) {
                RemoteProfile remProf = new RemoteProfile(pRef.getAddress());
                remProf.syncRemoteGoals(uPage);
            }
            uPage.saveFile(ar, "Synchronized action items from remote profiles");

            redirectBrowser(ar,go);

        }catch(Exception ex){
            throw new Exception("Unable to refresh consolidates action items list from remote profiles", ex);
        }
    }



    @RequestMapping(value = "/markAsTemplate.ajax", method = RequestMethod.POST)
    public void markAsTemplate(HttpServletRequest request, HttpServletResponse response)
    throws Exception {

        String responseMessage = "";
        AuthRequest ar = null;
        try{
            ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Unable to set to watch this page.");

            String p = ar.reqParam("pageId");
            NGPage ngp = ar.getCogInstance().getWSByCombinedKeyOrFail(p).getWorkspace();
            ar.setPageAccessLevels(ngp);

            UserProfile uProf = ar.getUserProfile();
            String action = ar.reqParam("action");
            if ("MarkAsTemplate".equals(action))
            {
                uProf.setProjectAsTemplate(ngp.getSiteKey(), ngp.getKey());
            }
            else if ("removeTemplate".equals(action))
            {
                uProf.removeTemplateRecord(ngp.getKey());
            }
            else if ("stopusingastemplate".equals(action))
            {
                uProf.clearWatch(ngp.getKey());
            }
            else
            {
                throw new NGException("nugen.exceptionhandling.system.not.understand.action",new Object[]{action});
            }
            JSONObject paramMap = new JSONObject();
            paramMap.put("msgType" , "success");
            paramMap.put("action", action);
            responseMessage = paramMap.toString();
        }
        catch(Exception ex){
            responseMessage = NGWebUtils.getExceptionMessageForAjaxRequest(ex, ar.getLocale());
            ar.logException("Caught by projectNotifications.ajax", ex);
        }

        NGWebUtils.sendResponse(ar, responseMessage);
    }

    @RequestMapping(value = "/{userKey}/EditUserProfileAction.form", method = RequestMethod.POST)
    public void updateUserProfile(HttpServletRequest request, HttpServletResponse response,
            @PathVariable String userKey)
    throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Must be logged in in order to edit a user profile.");
            String action = ar.reqParam("action");
            if (action.equals("Cancel")) {
                redirectBrowser(ar,"userSettings.htm");
                return;
            }

            String u = ar.reqParam("u");
            UserProfile profile = UserManager.getUserProfileOrFail(u);

            if(action.equals("Save")) {
                profile.setName(ar.defParam("name", ""));
                profile.setDescription(ar.defParam("description", ""));
                profile.setNotificationPeriod(DOMFace.safeConvertInt(ar.defParam("notificationPeriod", "1")));
            }

            String email= ar.defParam("email", null);
            if (email!=null && email.length()>0){
                profile.addId(email);
            }

            profile.setLastUpdated(ar.nowTime);
            ar.getCogInstance().getUserManager().saveUserProfiles();
            redirectBrowser(ar,"editUserProfile.htm?u="+userKey);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.edit.userprofile", new Object[]{userKey} , ex);
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
    
    
    @RequestMapping(value = "/approveOrRejectRoleRequest.ajax", method = RequestMethod.POST)
    public void approveOrRejectRoleRequest(HttpServletRequest request, HttpServletResponse response)
    throws Exception {
        AuthRequest ar = null;
        String responseMessage = "";
        try{
            ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Must be logged in to approve a role request.");
            UserProfile uProf = ar.getUserProfile();

            String p = ar.reqParam("pageId");
            NGPage project = ar.getCogInstance().getWSByCombinedKeyOrFail(p).getWorkspace();
            ar.setPageAccessLevels(project);

            RoleRequestRecord roleRequestRecord = null;
            String requestId = ar.defParam("requestId", null);

            boolean canAccessPage = false;
            if(requestId != null){
                roleRequestRecord = project.getRoleRequestRecordById(requestId);
                canAccessPage = AccessControl.canAccessRoleRequest(ar, project, roleRequestRecord);
            }

            if(!canAccessPage){
                ar.assertLoggedIn("Must be logged in to approve a role request.");
            }

            String requestedBy ="";
            String roleName = "";
            String action = ar.reqParam("action");
            if ("approved".equals(action))
            {
                String responseDescription = ar.defParam("responseDescription", "");
                if(roleRequestRecord != null){
                    roleName = roleRequestRecord.getRoleName();
                    requestedBy = roleRequestRecord.getRequestedBy();
                    project.addPlayerToRole(roleName,requestedBy);
                    roleRequestRecord.setState("Approved");
                    roleRequestRecord.setResponseDescription(responseDescription);
                    roleRequestRecord.setCompleted(true);
                }
                HistoryRecord.createHistoryRecord(project,requestedBy,
                        HistoryRecord.CONTEXT_TYPE_PERMISSIONS,0,
                        HistoryRecord.EVENT_PLAYER_ADDED, ar, roleName);

                project.saveFile(ar, "Add New Member ("+requestedBy+") to Role "+roleName);

                String subject = "Approved: Role request for '"+roleName+"'";
                sendRoleRequestApprovedOrRejectionEmail(ar, requestedBy, subject,responseDescription,project,roleName,action);
            }
            else if ("rejected".equals(action))
            {
                requestId = ar.reqParam("requestId");
                String responseDescription = ar.defParam("responseDescription", "");
                if(roleRequestRecord != null){
                    roleName = roleRequestRecord.getRoleName();
                    requestedBy = roleRequestRecord.getRequestedBy();
                    roleRequestRecord.setState("Rejected");
                    roleRequestRecord.setCompleted(true);
                    roleRequestRecord.setResponseDescription(responseDescription);
                }

                project.saveFile(ar, "Rejected role request");

                String subject = "Rejected: Role request for '"+roleName+"'";
                sendRoleRequestApprovedOrRejectionEmail(ar, requestedBy, subject,responseDescription,project,roleName,action);
            }else if ("cancel".equals(action)){
                roleName = ar.reqParam("roleName").trim();
                requestedBy = uProf.getUniversalId();
                roleRequestRecord = project.getRoleRequestRecord(roleName,requestedBy);
                project.deleteRoleRequest(roleRequestRecord.getRequestId());
                project.saveContent(ar,"deleted role request "+requestId);
            }else{
               throw new NGException("nugen.exceptionhandling.system.not.understand.action",new Object[]{action});
            }

            JSONObject paramMap = new JSONObject();
            paramMap.put("msgType" , "success");
            paramMap.put("action", action);
            paramMap.put("roleName", roleName);
            responseMessage = paramMap.toString();
        }
        catch(Exception ex){
            responseMessage = NGWebUtils.getExceptionMessageForAjaxRequest(ex, ar.getLocale());
            ar.logException("Caught by approveOrRejectRoleRequest.ajax", ex);
        }

        NGWebUtils.sendResponse(ar, responseMessage);
    }

    private File getUserImageFolder(HttpServletRequest request) {
        String path=request.getSession().getServletContext().getRealPath("/");
        File file_users = new File(path, "users");
        if(!file_users.exists()){
            file_users.mkdir();
        }
        return file_users;
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

            UserProfile profile = getUserToDisplay(ar, userKey);

            String uploadedFileName = fileInPost.getOriginalFilename();
            if (uploadedFileName == null || uploadedFileName.length()==0) {
                throw new NGException("nugen.exceptionhandling.filename.empty",null);
            }
            int dotPos = uploadedFileName.lastIndexOf(".");
            String fileExtension = uploadedFileName.substring(dotPos);

            File userImageFolder = getUserImageFolder(request);
            String newImageName = profile.getKey()+fileExtension;
            File newUserImage = new File(userImageFolder, newImageName);
            File userImageTmpFile = new File(userImageFolder, newImageName+".~TMP");
            //clean out any tmp file that might be left around
            if (userImageTmpFile.exists()) {
                userImageTmpFile.delete();
            }

            //write the image content to the temp file
            AttachmentHelper.saveToFileAH(fileInPost, userImageTmpFile);

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
            profile.setImage(newImageName);
            profile.setLastUpdated(ar.nowTime);
            ar.getCogInstance().getUserManager().saveUserProfiles();

            redirectBrowser(ar,"editUserProfile.htm?u="+userKey);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.upload.user.image.page",
                    new Object[]{userKey} , ex);
        }
    }

    @RequestMapping(value = "/deleteUserId.ajax", method = RequestMethod.POST)
    public void deleteUserId(HttpServletRequest request, HttpServletResponse response)
    throws Exception {

        AuthRequest ar = null;

        String responseMessage  ="";
        try{
            ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("You need to login to perform this function.");

            String action = ar.reqParam("action");
            String u = ar.reqParam("u");
            String modid = ar.reqParam("modid");

            UserProfile profile = ar.getCogInstance().getUserManager().getUserProfileOrFail(u);

            if (action.equals("removeId"))
            {
                String delconf = ar.defParam("delconf", null);
                if (delconf==null || delconf.length()==0) {
                    throw new NGException("message.user.profile.error", null);
                }
                profile.removeId(modid);
                profile.setLastUpdated(ar.nowTime);
                ar.getCogInstance().getUserManager().saveUserProfiles();

                JSONObject paramMap = new JSONObject();
                paramMap.put("msgType" , "success");
                paramMap.put("modid", modid);
                responseMessage = paramMap.toString();
            }
        }catch(Exception ex){
            responseMessage = NGWebUtils.getExceptionMessageForAjaxRequest(ex, ar.getLocale());
            ar.logException("Caught by deleteUserId.ajax", ex);
        }
        NGWebUtils.sendResponse(ar, responseMessage);
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
                    streamJSP(ar, "WarningNotMember");
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
            streamJSP(ar, "RoleRequest");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.approve.reject.rolereq.page", null , ex);
        }
    }


    /**
    * user key must be valid and must be logged in user
    * must have a "path" parameter to say the path in the folder
    * path ALWAYS starts with a slash.  Use just a slash to get root.
    */
    @RequestMapping(value = "/{userKey}/folder{folderId}.htm", method = RequestMethod.GET)
    public void folderDisplay2(@PathVariable String userKey, @PathVariable String folderId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        try{
            request.setAttribute("folderId", folderId);
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Need to log in to see remote folder page.");
            UserPage uPage = ar.getUserPage();
            String path = ar.defParam("path", "/");

            //test to see if things are working OK before going to the JSP level
            uPage.getConnectionOrFail(folderId);
            FolderAccessHelper fdh = new FolderAccessHelper(ar);
            fdh.getRemoteResource(folderId, path, true);

            request.setAttribute("path", path);

            //this is deprecated ... remove soon
            request.setAttribute("fid", folderId + path);
            streamJSPUserLoggedIn(ar, userKey, "FolderDisplay");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.user.folder.page", new Object[]{userKey}, ex);
        }
    }

    @RequestMapping(value = "/{userKey}/BrowseConnection{folderId}.htm", method = RequestMethod.GET)
    public void folderDisplay5(@PathVariable String userKey,
            @PathVariable String folderId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Need to log in to see page.");
            UserPage uPage = ar.getUserPage();
            uPage.getConnectionOrFail(folderId);

            String path = ar.defParam("path", "/");

            //verify that the resource path is properly formed
            uPage.getResource(folderId, path);

            String p = ar.reqParam("p");
            ar.getCogInstance().getWSByCombinedKeyOrFail(p);
            request.setAttribute("folderId", folderId);
            request.setAttribute("path", path);
            streamJSPUserLoggedIn(ar, userKey, "BrowseConnection");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.browse.connection.page", new Object[]{userKey}, ex);
        }
    }


    @RequestMapping(value = "/{userKey}/fd{folderId}/show.htm", method = RequestMethod.GET)
    public void folderDisplay3(@PathVariable String userKey, @PathVariable String folderId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Need to log in to see remote folder page.");
            String path = "/";  //debug
            request.setAttribute("fid", folderId + path);
            streamJSPUserLogged2(request, response, userKey, "../jsp/FolderDisplay");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.page", new Object[]{userKey}, ex);
        }
    }

    @RequestMapping(value = "/{userKey}/fd{folderId}/*/show.htm", method = RequestMethod.GET)
    public void folderDisplay4(@PathVariable String userKey, @PathVariable String folderId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Need to log in to see remote folder page.");
            String path = "/";  //debug
            request.setAttribute("fid", folderId + path);
            streamJSPUserLogged2(request, response, userKey, "../jsp/FolderDisplay");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.page", new Object[]{userKey}, ex);
        }
    }

    @RequestMapping(value="/{userKey}/f{folderId}/remote.htm", method = RequestMethod.GET)
    public void loadRemoteDocument(
            @PathVariable String userKey,
            @PathVariable String folderId,
            HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar  = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                sendRedirectToLogin(ar);
                return;
            }

            String path = ar.reqParam("path");

            FolderAccessHelper fah = new FolderAccessHelper(ar);
            fah.serveUpRemoteFile(folderId+path);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.page", new Object[]{userKey}, ex);
        }
    }

    @RequestMapping(value = "/addEmailToProfile.form", method = RequestMethod.POST)
    public void addEmailToProfile(HttpServletRequest request, HttpServletResponse response)
    throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("You need to login to perform this function.");
            String emailId    = ar.reqParam("emailId").trim();
            String mn       = ar.reqParam("mn");
            String containerId = ar.reqParam( "containerId" );

            NGPage page = ar.getCogInstance().getWSByCombinedKeyOrFail( containerId ).getWorkspace();
            Cognoscenti cog = ar.getCogInstance();
            cog.getSiteByIdOrFail(page.getSite().getKey());

            String expectedMN = page.emailDependentMagicNumber(emailId);
            if(!mn.equals(expectedMN)){
                throw new NGException("nugen.exception.link.configured.improperly", new Object[]{emailId});
            }
            UserProfile  profileExists =  cog.getUserManager().lookupUserByAnyId( emailId );
            if(profileExists != null){
                throw new NGException("nugen.exception.invalid.link",null);
            }
            UserProfile up = ar.getUserProfile();
            up.addId(emailId);
            up.setLastUpdated(ar.nowTime);
            cog.getUserManager().saveUserProfiles();

            //remove micro profile if exists.
            MicroProfileMgr.removeMicroProfileRecord(emailId);
            MicroProfileMgr.save();

            String go = ar.baseURL+"v/"+up.getKey()+"/userSettings.htm";
            redirectBrowser(ar,go);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.add.mail.to.profile", null, ex);
        }
    }

    @RequestMapping(value="/{userKey}/uploadContacts.form", method = RequestMethod.POST)
    public void uploadContacts(
            @PathVariable String userKey,
            HttpServletRequest request,
            HttpServletResponse response,
            @RequestParam("fname") MultipartFile file) throws Exception {

        try{

            AuthRequest ar = NGWebUtils.getAuthRequest(request, response, "CAN_NOT_UPLOAD_ATTACHMENT");
            ar.req = request;

            request.setCharacterEncoding("UTF-8");

            if (file.getSize() == 0) {
                throw new NGException("nugen.exceptionhandling.no.file.attached",null);
            }

            String fileName = file.getOriginalFilename();

            if (fileName == null || fileName.length()==0) {
                throw new NGException("nugen.exceptionhandling.filename.empty", null);
            }

            Workbook workbook = Workbook.getWorkbook(file.getInputStream());
            Sheet sheet = workbook.getSheet(0);
            int emailColumn = Integer.valueOf(ar.reqParam("emailCol"));
            int nameCol = Integer.valueOf(ar.reqParam("nameCol"));

            Map<String, String> contactsMap = new HashMap<String, String>();
            for (int i = 1; i < sheet.getRows(); i++) {
                Cell name = sheet.getCell(nameCol, i);
                Cell emailId = sheet.getCell(emailColumn, i);
                contactsMap.put(name.getContents(), emailId.getContents());
            }

            request.getSession().setAttribute("contactList", contactsMap);
            redirectBrowser(ar,"contacts.htm");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.upload.contacts", new Object[]{userKey}, ex);
        }
    }


    @RequestMapping(value="/updateMicroProfile.json", method = RequestMethod.POST)
    public void updateMicroProfile(HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        AuthRequest ar = NGWebUtils.getAuthRequest(request, response, "Can not update user contacts.");
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

    @RequestMapping(value="/editMicroProfileDetail.form", method = RequestMethod.POST)
    public void editMicroProfileDetail(

            HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        try{
            AuthRequest ar = NGWebUtils.getAuthRequest(request, response, "Can not update user contacts.");

            String emailId = ar.reqParam("emailId").trim();
            String idDisplayName = ar.reqParam("userName");
            String go = ar.reqParam("go");

            MicroProfileMgr.setDisplayName(emailId, idDisplayName);
            MicroProfileMgr.save();
            redirectBrowser(ar,go);

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.edit.micro.profile", null, ex);
        }
    }


    @RequestMapping(value="/getPeopleYouMayKnowList.ajax", method = RequestMethod.POST)
    public void getPeopleYouMayKnowList(
            HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        String responseMessage = null;
        AuthRequest ar = NGWebUtils.getAuthRequest(request, response, "Can not get PeopleYouMayKnow List.");
        try{

            String searchStr = ar.defParam("searchStr","");

            JSONObject parameters = new JSONObject();
            parameters.put("msgType" , "success");
            JSONArray array = getPeopleListInJSONArray(ar, searchStr);
            parameters.put("datatable", array );

            responseMessage = parameters.toString();
        }catch(Exception ex){
            responseMessage = NGWebUtils.getExceptionMessageForAjaxRequest(ex, ar.getLocale());
            ar.logException("Caught by getPeopleYouMayKnowList.ajax", ex);
        }
        NGWebUtils.sendResponse(ar, responseMessage);
    }

    @RequestMapping(value="/{userKey}/confirmedAddIdView.htm", method = RequestMethod.GET)
    public void openConfirmedAddIdView(
            @PathVariable String userKey,
            HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        try{
            AuthRequest ar = NGWebUtils.getAuthRequest(request, response, "Can not open confirm page.");
            request.setAttribute("userKey", ar.getUserProfile().getKey());
            streamJSPUserLogged2(request, response, userKey, "../jsp/confirmedAddIdView");
        }
        catch(Exception ex){
            throw new NGException("nugen.operation.fail.open.confirm.added.id.view", new Object[]{userKey}, ex);
        }
    }

    @RequestMapping(value="/{userKey}/changeListenerSettings.form", method = RequestMethod.POST)
    public void changeListenerSettings(
            HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        try{
            AuthRequest ar = NGWebUtils.getAuthRequest(request, response, "Can not update user contacts.");

            String pop3Host = ar.reqParam("pop3Host");
            String pop3Port = ar.reqParam("pop3Port");
            String pop3User = ar.reqParam("pop3User");
            String pop3Password = ar.reqParam("pop3Password");

            Properties emailProperties = EmailListener.getEmailProperties();

            emailProperties.setProperty("mail.pop3.host", pop3Host);
            emailProperties.setProperty("mail.pop3.port", pop3Port);
            emailProperties.setProperty("mail.pop3.user", pop3User);
            emailProperties.setProperty("mail.pop3.password", pop3Password);

            EmailListener emailListener = EmailListener.getEmailListener();
            emailProperties.store(new FileOutputStream(emailListener.getEmailPropertiesFile()), "updating Listener properties");

            emailListener.reStart();

            redirectBrowser(ar,"emailListnerSettings.htm");

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.to.change.listener.settings", null, ex);
        }
    }


    @RequestMapping(value = "/{userKey}/notificationSettings.htm", method = RequestMethod.GET)
    public void goToNotificationSetting(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);

            if(ar.hasSpecialSessionAccess("Notifications:"+userKey)){
                //need to show this even if not logged in
                streamJSP(ar, "../jsp/NotificationSettings");
                return;
            }

            //this will fail if not logged in
            streamJSPUserLogged2(request, response, userKey, "../jsp/NotificationSettings");
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
                ar.resp.sendRedirect(ar.baseURL+"v/"+profile.getKey()+"/notificationSettings.htm");
                return;
            }

            String userKey = ar.defParam("userKey", null);

            if(userKey != null){
                UserProfile userProfile = getUserToDisplay(ar, userKey);
                String accessCode = ar.defParam("accessCode", null);
                if(userProfile != null && userProfile.getAccessCode().equals(accessCode)){
                    ar.setSpecialSessionAccess("Notifications:"+userKey);
                    ar.resp.sendRedirect(ar.baseURL+"v/"+userKey+"/notificationSettings.htm");
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

            NGPage ngp = ar.getCogInstance().getWSByCombinedKeyOrFail(pageId).getWorkspace();
            ar.setPageAccessLevels(ngp);
            UserProfile up = getUserToDisplay(ar, userKey);

            String sendDigest = ar.defParam("sendDigest", null);
            if(sendDigest != null && "never".equals(sendDigest)){

                up.clearNotification( ngp.getKey());
                ar.getCogInstance().getUserManager().saveUserProfiles();
            }

            int eventType = HistoryRecord.EVENT_TYPE_MODIFIED;
            String[] tasksToBeCompleted= ar.req.getParameterValues("markascompleted");
            if(tasksToBeCompleted != null && tasksToBeCompleted.length > 0){
                GoalRecord taskRecord = null;
                for (String taskId : tasksToBeCompleted) {
                    taskRecord = ngp.getGoalOrFail(taskId);
                    taskRecord.setEndDate(ar.nowTime);
                    taskRecord.setStateAndAct(BaseRecord.STATE_COMPLETE, ar);
                    eventType = HistoryRecord.EVENT_TYPE_STATE_CHANGE_COMPLETE;
                    taskRecord.setModifiedDate(ar.nowTime);
                    taskRecord.setModifiedBy(ar.getBestUserId());
                    HistoryRecord.createHistoryRecord(ngp, taskRecord.getId(),
                            HistoryRecord.CONTEXT_TYPE_TASK, eventType, ar, "task completed");
                }
            }

            String[] tasksToBeUnassigned= ar.req.getParameterValues("unassign");
            if(tasksToBeUnassigned != null && tasksToBeUnassigned.length > 0){
                GoalRecord taskRecord = null;
                for (String taskId : tasksToBeUnassigned) {
                    taskRecord = ngp.getGoalOrFail(taskId);
                    taskRecord.getAssigneeRole().removePlayer(new AddressListEntry(up.getPreferredEmail()));
                    taskRecord.setModifiedDate(ar.nowTime);
                    taskRecord.setModifiedBy(ar.getBestUserId());
                    HistoryRecord.createHistoryRecord(ngp, taskRecord.getId(),
                            HistoryRecord.CONTEXT_TYPE_TASK,
                            HistoryRecord.EVENT_TYPE_MODIFIED, ar, "unassigned");
                }
            }

            String[] stopRolePlayer= ar.req.getParameterValues("stoproleplayer");
            removeFromRole(ngp, new AddressListEntry(up), stopRolePlayer);


            String[] stopReminding= ar.req.getParameterValues("stopReminding");
            if(stopReminding != null && stopReminding.length > 0){
                ReminderMgr rMgr = ngp.getReminderMgr();
                ReminderRecord rRec = null;
                for (String reminderId : stopReminding) {
                    rRec = rMgr.findReminderByID(reminderId);
                    rRec.setSendNotification("no");
                }
            }

            ngp.saveFile(ar,"updated notification settings");
            redirectBrowser(ar,"notificationSettings.htm");

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
                UserProfile uProf = getUserToDisplay(ar, userKey);
                UserProfile loggedInUser = ar.getUserProfile();

                String userName = loggedInUser.getName();

                if (userName==null || userName.length()==0) {
                    userName = loggedInUser.getKey();
                }
                if (userName.length()>28) {
                    userName = userName.substring(0,28);
                }

                uProf.assureImage(ar.getCogInstance());

                String isRequestingForNewProjectUsingLinks = ar.defParam( "projectName", null );
                String bookForNewProject = ar.defParam( "bookKey", null );

                if(isRequestingForNewProjectUsingLinks!=null && bookForNewProject!=null){
                    List<NGPageIndex> foundPages = ar.getCogInstance().getPageIndexByName(isRequestingForNewProjectUsingLinks);
                    if(foundPages.size()>0){
                        NGPageIndex foundPage = foundPages.get( 0 );
                        response.sendRedirect(ar.retPath+"t/"+bookForNewProject+"/"+foundPage.containerKey+"/frontPage.htm" );
                        return;
                    }
                }

                request.setAttribute("ngpage",null);
                request.setAttribute("userName",userName);
                request.setAttribute("flag","true");
                request.setAttribute("retPath",ar.retPath);
            }
            streamJSPUserLogged2(request, response, userKey, "../jsp/UserSettings");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.userprofile.page", new Object[]{userKey} , ex);
        }
    }


    @RequestMapping(value = "/{userKey}/userContacts.htm", method = RequestMethod.GET)
    public void userContacts(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {

        try{

            AuthRequest ar = AuthRequest.getOrCreate(request, response);

            if(ar.isLoggedIn()){
                UserProfile loggedInUser = ar.getUserProfile();
                String userName = loggedInUser.getName();

                if (userName==null || userName.length()==0) {
                    userName = loggedInUser.getKey();
                }
                if (userName.length()>28) {
                    userName = userName.substring(0,28);
                }

                NGContainer ngp =null;

                String isRequestingForNewProjectUsingLinks = ar.defParam( "projectName", null );
                String bookForNewProject = ar.defParam( "bookKey", null );

                if(isRequestingForNewProjectUsingLinks!=null && bookForNewProject!=null){
                    List<NGPageIndex> foundPages = ar.getCogInstance().getPageIndexByName(isRequestingForNewProjectUsingLinks);
                    if(foundPages.size()>0){
                        NGPageIndex foundPage = foundPages.get( 0 );
                        response.sendRedirect(ar.retPath+"t/"+bookForNewProject+"/"+foundPage.containerKey+"/frontPage.htm" );
                        return;
                    }
                }

                request.setAttribute("ngpage",ngp);
                request.setAttribute("userName",userName);
                request.setAttribute("flag","true");
                request.setAttribute("retPath",ar.retPath);
            }
            streamJSPUserLogged2(request, response, userKey, "../jsp/UserContacts");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.userprofile.page", new Object[]{userKey} , ex);
        }
    }

    @RequestMapping(value = "/{userKey}/userConnections.htm", method = RequestMethod.GET)
    public void userConnections(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        try{

            AuthRequest ar = AuthRequest.getOrCreate(request, response);

            if(ar.isLoggedIn()){
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
                        response.sendRedirect(ar.retPath+"t/"+bookForNewProject+"/"+foundPage.containerKey+"/frontPage.htm" );
                        return;
                    }
                }

                request.setAttribute("userName",userName);
                request.setAttribute("flag","true");
                request.setAttribute("retPath",ar.retPath);
            }
            streamJSPUserLogged2(request, response, userKey, "../jsp/UserConnections");
        }
        catch(Exception ex){
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
            String searchSite    = query.getString("searchSite");
            String searchProject = query.getString("searchProject");

            if ("all".equals(searchSite)) {
                searchSite = null;
            }

            List<SearchResultRecord> searchResults = null;
            if (searchText.length()>0) {
                SearchManager.initializeIndex(ar.getCogInstance());
                searchResults = SearchManager.performSearch(ar, searchText, searchProject, searchSite);
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

    private static void removeFromRole(NGPage ngp, AddressListEntry ale, String[] stopRolePlayer) throws Exception {
        if(stopRolePlayer != null && stopRolePlayer.length > 0){
            NGRole role = null;
            for (String roleName : stopRolePlayer) {
                role = ngp.getRoleOrFail(roleName);
                role.removePlayer(ale);
            }
        }
    }

    private static void sendRoleRequestApprovedOrRejectionEmail(AuthRequest ar,
            String addressee, String subject, String responseComment,
            NGContainer ngp, String roleName, String action) throws Exception {
        Cognoscenti cog = ar.getCogInstance();
        MemFile bodyWriter = new MemFile();
        AuthRequest clone = new AuthDummy(ar.getUserProfile(), bodyWriter.getWriter(), ar.getCogInstance());
        clone.setNewUI(true);
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


    @RequestMapping(value = "/FindPerson.htm", method = RequestMethod.GET)
    public void FindPerson(HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if (checkLogin(ar)) {
                return;
            }
            String userKey = ar.reqParam("uid");
            UserProfile searchedFor = ar.getCogInstance().getUserManager().lookupUserByAnyId(userKey);
            if (searchedFor!=null) {
                //so if we find it, just redirect to the settings page
                response.sendRedirect(ar.retPath+"v/"+searchedFor.getKey()+"/userSettings.htm");
                return;
            }
            streamJSP(ar, "FindPerson");

        }catch(Exception ex){
            throw new Exception("Failure trying to find user", ex);
        }
    }


}

