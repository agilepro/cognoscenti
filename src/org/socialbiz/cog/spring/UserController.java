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
import java.io.StringWriter;
import java.net.URLEncoder;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Vector;

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
import org.socialbiz.cog.EmailListener;
import org.socialbiz.cog.EmailSender;
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
import org.socialbiz.cog.ProfileRequest;
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
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.ServletRequestDataBinder;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.multipart.support.ByteArrayMultipartFileEditor;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.view.RedirectView;
import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;


@Controller
public class UserController extends BaseController {

    private ApplicationContext context;
    @Autowired
    public void setContext(ApplicationContext context) {
        this.context = context;
    }

    protected void initBinder(HttpServletRequest request,
            ServletRequestDataBinder binder) throws ServletException {

        binder.registerCustomEditor(byte[].class,new ByteArrayMultipartFileEditor());
    }

    public static ModelAndView createModelAndView(AuthRequest ar,
            UserProfile up, String tabId,
            String modelAndViewName) {

        HttpServletRequest request = ar.req;
        ModelAndView modelAndView = new ModelAndView(modelAndViewName);

        String realRequestURL = request.getRequestURL().toString();
        request.setAttribute("realRequestURL", realRequestURL);

        request.setAttribute("userKey", up.getKey());
        request.setAttribute("userProfile", up);
        request.setAttribute("pageTitle", "User: " + up.getName());
        request.setAttribute("tabId", tabId);
        request.setAttribute("title", up.getName());
        return modelAndView;
    }


    @RequestMapping(value = "/{userKey}/userProfile.htm", method = RequestMethod.GET)
    public ModelAndView loadProfile(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        return redirectBrowser(ar,"userSettings.htm");
    }

    @RequestMapping(value = "/{userKey}/userHome.htm", method = RequestMethod.GET)
    public ModelAndView loadUserHome(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        return redirectBrowser(ar,"watchedProjects.htm");
    }

    @RequestMapping(value = "{userKey}/watchedProjects.htm", method = RequestMethod.GET)
    public ModelAndView watchedProjects(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }

            UserProfile userBeingViewed = UserManager.getUserProfileOrFail(userKey);

            ModelAndView modelAndView = createModelAndView(ar, userBeingViewed, "Projects", "WatchedProjects");
            modelAndView.addObject( "messages", context );

            return modelAndView;
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.userhome.page", new Object[]{userKey} , ex);
        }
    }

    @RequestMapping(value = "/{userKey}/notifiedProjects.htm", method = RequestMethod.GET)
    public ModelAndView notifiedProjects(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }

            UserProfile userBeingViewed = UserManager.getUserProfileOrFail(userKey);

            ModelAndView modelAndView = createModelAndView(ar, userBeingViewed, "Projects", "NotifiedProjects");
            modelAndView.addObject( "messages", context );

            return modelAndView;
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.userhome.page", new Object[]{userKey} , ex);
        }
    }

    @RequestMapping(value = "/{userKey}/ownerProjects.htm", method = RequestMethod.GET)
    public ModelAndView ownerProjects(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{

            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }

            UserProfile userBeingViewed = UserManager.getUserProfileOrFail(userKey);
            ModelAndView modelAndView = createModelAndView(ar, userBeingViewed, "Projects", "OwnerProjects");

            return modelAndView;
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.userhome.page", new Object[]{userKey} , ex);
        }
    }


    @RequestMapping(value = "/{userKey}/templates.htm", method = RequestMethod.GET)
    public ModelAndView templates(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{

            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }

            UserProfile userBeingViewed = UserManager.getUserProfileOrFail(userKey);

            ModelAndView modelAndView = createModelAndView(ar, userBeingViewed, "Projects", "Templates");
            //modelAndView.addObject( "messages", context );

            return modelAndView;
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.userhome.page", new Object[]{userKey} , ex);
        }
    }

    @RequestMapping(value = "/{userKey}/participantProjects.htm", method = RequestMethod.GET)
    public ModelAndView participantProjects(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{

            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }

            UserProfile userBeingViewed = UserManager.getUserProfileOrFail(userKey);
            ModelAndView modelAndView = createModelAndView(ar, userBeingViewed, "Projects", "ParticipantProjects");

            return modelAndView;
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.userhome.page", new Object[]{userKey} , ex);
        }
    }

    @RequestMapping(value = "/{userKey}/allProjects.htm", method = RequestMethod.GET)
    public ModelAndView allProjects(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{

            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }

            UserProfile userBeingViewed = UserManager.getUserProfileOrFail(userKey);
            ModelAndView modelAndView = createModelAndView(ar, userBeingViewed, "Projects", "AllProjects");

            return modelAndView;
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.userhome.page", new Object[]{userKey} , ex);
        }
    }





    @RequestMapping(value = "/{userKey}/userAlerts.htm", method = RequestMethod.GET)
    public ModelAndView loadUserAlerts(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Need to log in to see a user's alerts page.");

            UserProfile userBeingViewed = UserManager.getUserProfileOrFail(userKey);

            ModelAndView modelAndView = createModelAndView(ar, userBeingViewed, "Updates", "UserAlerts");
            modelAndView.addObject( "messages", context );
            request.setAttribute("title", userBeingViewed.getName());
            return modelAndView;
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.useralerts.page", new Object[]{userKey} , ex);
        }
    }


    @RequestMapping(value = "/{userKey}/userTasks.htm", method = RequestMethod.GET)
    public ModelAndView loadUserTasks(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        return redirectBrowser(ar,"userActiveTasks.htm");
    }

    private ModelAndView displayTaskList(HttpServletRequest request, HttpServletResponse response,
            String userKey, String level, String viewName) throws Exception {
        try {
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }
            UserProfile userBeingViewed = UserManager.getUserProfileOrFail(userKey);

            request.setAttribute("title", userBeingViewed.getName());
            ModelAndView modelAndView = createModelAndView(ar, userBeingViewed, "Goals", viewName);
            modelAndView.addObject("active", level);
            return modelAndView;
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.usertask.page", new Object[]{userKey} , ex);
        }
    }

    @RequestMapping(value = "/{userKey}/userActiveTasks.htm", method = RequestMethod.GET)
    public ModelAndView userActiveTasks(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        return displayTaskList(request, response, userKey, "0", "UserActiveTasks");
    }

    @RequestMapping(value = "/{userKey}/userCompletedTasks.htm", method = RequestMethod.GET)
    public ModelAndView userCompletedTasks(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        return displayTaskList(request, response, userKey, "1", "UserCompletedTasks");
    }

    @RequestMapping(value = "/{userKey}/userFutureTasks.htm", method = RequestMethod.GET)
    public ModelAndView userFutureTasks(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        return displayTaskList(request, response, userKey, "2", "UserFutureTasks");
    }

    @RequestMapping(value = "/{userKey}/userAllTasks.htm", method = RequestMethod.GET)
    public ModelAndView userAllTasks(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        return displayTaskList(request, response, userKey, "3", "UserAllTasks");
    }

    @RequestMapping(value = "/{userKey}/ShareRequests.htm", method = RequestMethod.GET)
    public ModelAndView ShareRequests(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }
            UserProfile userBeingViewed = UserManager.getUserProfileOrFail(userKey);

            return createModelAndView(ar, userBeingViewed, "Goals", "ShareRequests");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.usertask.page", new Object[]{userKey} , ex);
        }
    }

    @RequestMapping(value = "/{userKey}/RemoteProfileAction.form", method = RequestMethod.POST)
    public ModelAndView RemoteProfileAction(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
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

            return redirectBrowser(ar, go);
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
            streamException(ex, ar);
        }
    }

    @RequestMapping(value = "/{userKey}/RemoteProfiles.htm", method = RequestMethod.GET)
    public ModelAndView remoteProfiles(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }
            UserProfile userBeingViewed = UserManager.getUserProfileOrFail(userKey);

            return createModelAndView(ar, userBeingViewed, "Goals", "RemoteProfiles");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.usertask.page", new Object[]{userKey} , ex);
        }
    }

    @RequestMapping(value = "/{userKey}/userRemoteTasks.htm", method = RequestMethod.GET)
    public ModelAndView consolidatedTasks(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }
            UserProfile userBeingViewed = UserManager.getUserProfileOrFail(userKey);

            return createModelAndView(ar, userBeingViewed, "Goals", "UserRemoteTasks");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.usertask.page", new Object[]{userKey} , ex);
        }
    }

    @RequestMapping(value = "/{userKey}/AgentAction.json", method = RequestMethod.POST)
    public void AgentAction(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            ar.assertLoggedIn("Must be logged in to update an agent.");

            UserProfile userBeingViewed = UserManager.getUserProfileOrFail(userKey);
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

    @RequestMapping(value = "/{userKey}/Agents.htm", method = RequestMethod.GET)
    public ModelAndView Agents(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }
            UserProfile userBeingViewed = UserManager.getUserProfileOrFail(userKey);

            return createModelAndView(ar, userBeingViewed, "Goals", "Agents");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.usertask.page", new Object[]{userKey} , ex);
        }
    }


    @RequestMapping(value = "/{userKey}/EditAgent.htm", method = RequestMethod.GET)
    public ModelAndView EditAgent(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }
            UserProfile userBeingViewed = UserManager.getUserProfileOrFail(userKey);
            UserPage uPage = userBeingViewed.getUserPage();
            String agentId = ar.reqParam("id");
            AgentRule agent = uPage.findAgentRule(agentId);
            if (agent==null) {
                throw new Exception("Unable to find an agent with id="+agentId);
            }

            return createModelAndView(ar, userBeingViewed, "Goals", "EditAgent");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.usertask.page", new Object[]{userKey} , ex);
        }
    }


    @RequestMapping(value = "/{userKey}/ViewRemoteTask.htm", method = RequestMethod.GET)
    public ModelAndView ViewRemoteTask(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }
            UserProfile userBeingViewed = UserManager.getUserProfileOrFail(userKey);
            UserPage uPage = userBeingViewed.getUserPage();
            String accessUrl = ar.reqParam("url");
            RemoteGoal rg =  uPage.findRemoteGoal(accessUrl);
            if (rg==null) {
                throw new Exception("unable to find a remote goal records with the url="+accessUrl);
            }

            return createModelAndView(ar, userBeingViewed, "Goals", "ViewRemoteTask");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.usertask.page", new Object[]{userKey} , ex);
        }
    }


    @RequestMapping(value = "/{userKey}/RefreshFromRemoteProfiles.form", method = RequestMethod.POST)
    public ModelAndView RefreshFromRemoteProfiles(@PathVariable String userKey,
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
            uPage.saveFile(ar, "Synchronized goals from remote profiles");

            return redirectBrowser(ar,go);

        }catch(Exception ex){
            throw new Exception("Unable to refresh consolidates goals list from remote profiles", ex);
        }
    }







    @RequestMapping(value = "/handlePersonalSubscriptions.ajax", method = RequestMethod.POST)
    public void handlePersonalSubscriptions(HttpServletRequest request, HttpServletResponse response)
    throws Exception {

        AuthRequest ar = null;
        String responseMessage = "";
        try{
            ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Unable to set to watch this page.");
            NGPage ngp = null;
            String action = ar.reqParam("action");
            if(!"Stop All Notifications".equals(action)){
                String p = ar.reqParam("pageId");
                ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
                ar.setPageAccessLevels(ngp);
            }
            UserProfile uProf = ar.getUserProfile();
            JSONObject paramMap = new JSONObject();


            if ("Start Watching".equals(action))
            {
                uProf.setWatch(ngp.getKey(), ar.nowTime);
                paramMap.put("watchTime", String.valueOf(uProf.watchTime(ngp.getKey())));
            }
            else if ("Reset Watch Time".equals(action))
            {
                uProf.setWatch(ngp.getKey(), ar.nowTime);
                paramMap.put("watchTime", String.valueOf(uProf.watchTime(ngp.getKey())));
            }
            else if ("Stop Watching".equals(action))
            {
                uProf.clearWatch(ngp.getKey());
                paramMap.put("watchTime", String.valueOf(uProf.watchTime(ngp.getKey())));
            }
            else if ("Start Notifications".equals(action))
            {
                uProf.setNotification(ngp.getKey(), ar.nowTime);
                paramMap.put("notifications" , "start");
            }
            else if ("Stop Notifications".equals(action))
            {
                uProf.clearNotification( ngp.getKey());
                paramMap.put("notifications" , "stop");
            }
            else if("Stop All Notifications".equals(action)){
                uProf.clearAllNotifications();
            }
            else
            {
                throw new NGException("nugen.exceptionhandling.system.not.understand.action",new Object[]{action});
            }
            UserManager.writeUserProfilesToFile();

            paramMap.put(Constant.MSG_TYPE , Constant.SUCCESS);
            responseMessage = paramMap.toString();
        }
        catch(Exception ex){
            responseMessage = NGWebUtils.getExceptionMessageForAjaxRequest(ex, ar.getLocale());
            ar.logException("Caught by handlePersonalSubscriptions.ajax", ex);
        }

        NGWebUtils.sendResponse(ar, responseMessage);
    }



    @RequestMapping(value = "/getUsers.ajax", method = RequestMethod.GET)
    public void getUsers(HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        AuthRequest ar = null;
        try{
            ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Must be logged in to get users");

            String matchKey = ar.reqParam("matchkey");
            StringBuffer users = new StringBuffer();
            Vector<AddressListEntry> userList = ar.getMatchedFragment(matchKey.toLowerCase());
            for (AddressListEntry ale : userList) {
                if(ale.getName().length() == 0){
                    users.append(ale.getUniversalId());
                }else{
                    users.append(" ");
                    users.append(ale.getName());
                    users.append("<");
                    users.append(ale.getUniversalId());
                    users.append(">");
                }
                users.append(",");
            }
            NGWebUtils.sendResponse(ar, users.toString());
        }
        catch(Exception ex){
            ar.logException("Caught by getUsers.ajax", ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/CreateRole.form", method = RequestMethod.POST)
    public ModelAndView createRole(@PathVariable String siteId,@PathVariable String pageId,HttpServletRequest request,
            HttpServletResponse response)
    throws Exception
    {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request,  response ,null);
            NGPage project  = registerRequiredProject(ar, siteId, pageId);
            ar.assertLoggedIn("Can't create a Role.");
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }
            ar.assertAdmin("Must be an admin of the project to create a role.");

            String roleName = ar.reqParam("rolename").trim();
            String des = ar.defParam("description", "");

            NGRole role = project.createRole(roleName,des);

            HistoryRecord.createHistoryRecord(project, role.getName(),
                HistoryRecord.CONTEXT_TYPE_ROLE,
                HistoryRecord.EVENT_TYPE_CREATED, ar, "");
            project.saveFile(ar, "Add New Role "+roleName+" to roleList");

            return redirectBrowser(ar,"permission.htm");

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.user.create.role.page", new Object[]{pageId,siteId} , ex);
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
            NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
            ar.setPageAccessLevels(ngp);

            UserProfile uProf = ar.getUserProfile();
            String action = ar.reqParam("action");
            if ("MarkAsTemplate".equals(action))
            {
                uProf.setProjectAsTemplate(ngp.getKey());
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
            paramMap.put(Constant.MSG_TYPE , Constant.SUCCESS);
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
    public ModelAndView updateUserProfile(HttpServletRequest request, HttpServletResponse response,
            @PathVariable String userKey)
    throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Must be logged in in order to edit a user profile.");
            String action = ar.reqParam("action");
            if (action.equals("Cancel")) {
                return redirectBrowser(ar,"userSettings.htm");
            }

            String u = ar.reqParam("u");
            UserProfile profile = UserManager.getUserProfileOrFail(u);

            if(action.equals("UpdatePreferredEmail")){
                String preferredEmail = ar.defParam("preferredEmail", "");
                if(preferredEmail != "") {
                    profile.setPreferredEmail(preferredEmail);
                }
            }

            if(action.equals("Save"))
            {
            profile.setName(ar.defParam("name", ""));
            profile.setDescription(ar.defParam("description", ""));
            }

            String email= ar.defParam("email", null);
            if (email!=null && email.length()>0){
                profile.addId(email);
            }

            profile.setLastUpdated(ar.nowTime);
            UserManager.writeUserProfilesToFile();
            return redirectBrowser(ar,"editUserProfile.htm?u="+userKey);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.edit.userprofile", new Object[]{userKey} , ex);
        }
    }

    @RequestMapping(value = "/{userKey}/addUserId.htm", method = RequestMethod.GET)
    public ModelAndView addUserId(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        ModelAndView modelAndView = null;
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Can't access to the Add User ID page.");
            UserProfile up = UserManager.getUserProfileOrFail(userKey);
            modelAndView = new ModelAndView("addUserIdForm");
            request.setAttribute("userProfile", up);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.user.adduserid.page", new Object[]{userKey} , ex);
        }
        return modelAndView;
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
            NGPage project = ar.getCogInstance().getProjectByKeyOrFail(p);
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
            paramMap.put(Constant.MSG_TYPE , Constant.SUCCESS);
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

    @RequestMapping(value = "/{userKey}/userAccounts.htm", method = RequestMethod.GET)
    public ModelAndView loadUserAccounts(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Need to log in to see a user's sites.");
            UserProfile uProf = UserManager.getUserProfileOrFail(userKey);

            return createModelAndView(ar, uProf, "Settings", "UserAccounts");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.useraccounts.page", new Object[]{userKey} , ex);
        }
    }

    @RequestMapping(value = "/{userKey}/userCreateProject.htm", method = RequestMethod.GET)
    public ModelAndView userCreateProject(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Need to log in to create a project.");
            UserProfile uProf = UserManager.getUserProfileOrFail(userKey);

            return createModelAndView(ar, uProf, "Projects", "UserCreateProject");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.useraccounts.page", new Object[]{userKey} , ex);
        }

    }

    @RequestMapping(value = "/addUserId.ajax", method = RequestMethod.POST)
    public void addUserId(HttpServletRequest request, HttpServletResponse response)
    throws Exception {

        AuthRequest ar = null;
        String responseMessage = "";
        try{
            ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Must be logged in to add User Id");

            String go     = ar.reqParam("go");
            String isEmailStr = ar.reqParam("isEmail");
            boolean isEmail = "true".equals(isEmailStr);
            String newid  = ar.reqParam("newid");

            //if parameter for email is not set at all, go back to the login page.
            if (isEmail && newid.indexOf("@")<0)
            {
                throw new NGException("nugen.exception.enter.valid.email",null);
            }

            if (!isEmail && newid.indexOf("@")>=0)
            {
                throw new NGException("nugen.exception.incorrect.openid",null);
            }

            UserProfile up = ar.getUserProfile();

            if (isEmail)
            {
                UserPage anonPage = ar.getAnonymousUserPage();
                ProfileRequest newReq = anonPage.createProfileRequest(ProfileRequest.ADD_EMAIL, newid, ar.nowTime);
                newReq.setUserKey(up.getKey());
                newReq.sendEmail(ar, go);

                anonPage.saveFile(ar, "requested to add Id "+newid);
            }else{
                up.addId(newid);
                up.setLastUpdated(ar.nowTime);
                UserManager.writeUserProfilesToFile();
            }

            JSONObject paramMap = new JSONObject();
            paramMap.put(Constant.MSG_TYPE , Constant.SUCCESS);
            paramMap.put("newId", newid);
            responseMessage = paramMap.toString();
        }
        catch(Exception ex){
            responseMessage = NGWebUtils.getExceptionMessageForAjaxRequest(ex, ar.getLocale());
            ar.logException("Caught by addUserId.ajax", ex);
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
    protected ModelAndView uploadImageFile(HttpServletRequest request,
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
            String fileExtension = uploadedFileName.substring(dotPos);

            File userImageFolder = getUserImageFolder(request);
            String newImageName = profile.getKey()+fileExtension;
            File oldUserImage = new File(userImageFolder, profile.getImage());
            File newUserImage = new File(userImageFolder, newImageName);
            File userImageTmpFile = new File(userImageFolder, newImageName+".~TMP");
            //clean out any tmp file that might be left around
            if (userImageTmpFile.exists()) {
                userImageTmpFile.delete();
            }

            //write the image content to the temp file
            AttachmentHelper.saveToFileAH(fileInPost, userImageTmpFile);

            //delete the old image if it existed
            if(oldUserImage.exists()){
                oldUserImage.delete();
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
            UserManager.writeUserProfilesToFile();

            return redirectBrowser(ar,"editUserProfile.htm?u="+userKey);
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

            UserProfile profile = UserManager.getUserProfileOrFail(u);

            if (action.equals("removeId"))
            {
                String delconf = ar.defParam("delconf", null);
                if (delconf==null || delconf.length()==0) {
                    throw new NGException("message.user.profile.error", null);
                }
                profile.removeId(modid);
                profile.setLastUpdated(ar.nowTime);
                UserManager.writeUserProfilesToFile();

                JSONObject paramMap = new JSONObject();
                paramMap.put(Constant.MSG_TYPE , Constant.SUCCESS);
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
    public ModelAndView gotoApproveOrRejectRoleReqPage(
            @PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        ModelAndView modelAndView = null;
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGContainer ngc =  registerSiteOrProject(ar, siteId, pageId);

            String requestId = ar.reqParam("requestId");
            RoleRequestRecord roleRequestRecord = ngc.getRoleRequestRecordById(requestId);
            boolean canAccessPage = AccessControl.canAccessRoleRequest(ar, ngc, roleRequestRecord);

            if(!canAccessPage){
                 return showWarningView(ar, "nugen.project.member.login.msg");
            }

            String isAccessThroughEmail = ar.reqParam("isAccessThroughEmail");

            request.setAttribute("realRequestURL", ar.getRequestURL());

            modelAndView = new ModelAndView("RoleRequest");

            request.setAttribute("isAccessThroughEmail", isAccessThroughEmail);
            request.setAttribute("tabId", "Project Settings");
            request.setAttribute("canAccessPage", canAccessPage);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.approve.reject.rolereq.page", null , ex);
        }
        return modelAndView;
    }

    @RequestMapping(value = "/{userKey}/administration.htm", method = RequestMethod.GET)
    public ModelAndView loadAdministration(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        return redirectBrowser(ar,"emailListnerSettings.htm");
    }

    /**
    * This lists the connections so that a user can select one when browsing
    * to attach a document.
    */
    @RequestMapping(value = "/{userKey}/ListConnections.htm", method = RequestMethod.GET)
    public ModelAndView folderDisplay(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        ModelAndView modelAndView = null;
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Need to log in to see page.");
            UserProfile up = UserManager.getUserProfileOrFail(userKey);

            modelAndView = createModelAndView(ar, up, "Home", "ListConnections");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.list.connection.page", new Object[]{userKey} , ex);
        }
        return modelAndView;
    }


    /**
    * user key must be valid and must be logged in user
    * must have a "path" parameter to say the path in the folder
    * path ALWAYS starts with a slash.  Use just a slash to get root.
    */
    @RequestMapping(value = "/{userKey}/folder{folderId}.htm", method = RequestMethod.GET)
    public ModelAndView folderDisplay2(@PathVariable String userKey, @PathVariable String folderId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            request.setAttribute("folderId", folderId);
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Need to log in to see remote folder page.");
            UserProfile up = UserManager.getUserProfileOrFail(userKey);
            UserPage uPage = ar.getUserPage();
            String path = ar.defParam("path", "/");

            //test to see if things are working OK before going to the JSP level
            uPage.getConnectionOrFail(folderId);
            FolderAccessHelper fdh = new FolderAccessHelper(ar);
            fdh.getRemoteResource(folderId, path, true);

            ModelAndView modelAndView = createModelAndView(ar, up, "Home", "FolderDisplay");
            request.setAttribute("path", path);

            //this is deprecated ... remove soon
            request.setAttribute("fid", folderId + path);
            return modelAndView;
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.user.folder.page", new Object[]{userKey}, ex);
        }
    }

    @RequestMapping(value = "/{userKey}/BrowseConnection{folderId}.htm", method = RequestMethod.GET)
    public ModelAndView folderDisplay5(@PathVariable String userKey,
            @PathVariable String folderId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        ModelAndView modelAndView = null;
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Need to log in to see page.");
            UserProfile up = UserManager.getUserProfileOrFail(userKey);
            UserPage uPage = ar.getUserPage();
            uPage.getConnectionOrFail(folderId);

            String path = ar.defParam("path", "/");

            //verify that the resource path is properly formed
            uPage.getResource(folderId, path);

            String p = ar.reqParam("p");
            ar.getCogInstance().getProjectByKeyOrFail(p);

            modelAndView = createModelAndView(ar, up, "Home", "BrowseConnection");
            request.setAttribute("folderId", folderId);
            request.setAttribute("path", path);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.browse.connection.page", new Object[]{userKey}, ex);
        }
        return modelAndView;
    }


    @RequestMapping(value = "/{userKey}/fd{folderId}/show.htm", method = RequestMethod.GET)
    public ModelAndView folderDisplay3(@PathVariable String userKey, @PathVariable String folderId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        ModelAndView modelAndView = null;
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Need to log in to see remote folder page.");
            UserProfile up = UserManager.getUserProfileOrFail(userKey);
            String path = "/";  //debug
            modelAndView = createModelAndView(ar, up, "Home", "FolderDisplay");
            request.setAttribute("fid", folderId + path);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.page", new Object[]{userKey}, ex);
        }
        return modelAndView;
    }

    @RequestMapping(value = "/{userKey}/fd{folderId}/*/show.htm", method = RequestMethod.GET)
    public ModelAndView folderDisplay4(@PathVariable String userKey, @PathVariable String folderId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        ModelAndView modelAndView = null;
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Need to log in to see remote folder page.");
            UserProfile up = UserManager.getUserProfileOrFail(userKey);
            String path = "/";  //debug
            modelAndView = createModelAndView(ar, up, "Home", "FolderDisplay");
            request.setAttribute("fid", folderId + path);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.page", new Object[]{userKey}, ex);
        }
        return modelAndView;
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
                String go = ar.getRequestURL();
                String loginUrl = ar.baseURL+"t/EmailLoginForm.htm?go="+URLEncoder.encode(go,"UTF-8")
                +"&msg="+URLEncoder.encode("Need to log in to browse remote folders","UTF-8");
                response.sendRedirect(loginUrl);
            }

            String path = ar.reqParam("path");

            FolderAccessHelper fah = new FolderAccessHelper(ar);
            fah.serveUpRemoteFile(folderId+path);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.page", new Object[]{userKey}, ex);
        }
    }

    @RequestMapping(value = "/addEmailToProfile.form", method = RequestMethod.POST)
    public ModelAndView addEmailToProfile(HttpServletRequest request, HttpServletResponse response)
    throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("You need to login to perform this function.");
            String emailId    = ar.reqParam("emailId").trim();
            String mn       = ar.reqParam("mn");
            String containerId = ar.reqParam( "containerId" );

            NGPage page = ar.getCogInstance().getProjectByKeyOrFail( containerId );
            ar.getCogInstance().getSiteByIdOrFail(page.getSite().getKey());

            String expectedMN = page.emailDependentMagicNumber(emailId);
            if(!mn.equals(expectedMN)){
                throw new NGException("nugen.exception.link.configured.improperly", new Object[]{emailId});
            }
            UserProfile  profileExists = UserManager.findUserByAnyId( emailId );
            if(profileExists != null){
                throw new NGException("nugen.exception.invalid.link",null);
            }
            UserProfile up = ar.getUserProfile();
            up.addId(emailId);
            up.setLastUpdated(ar.nowTime);
            UserManager.writeUserProfilesToFile();

            //remove micro profile if exists.
            MicroProfileMgr.removeMicroProfileRecord(emailId);
            MicroProfileMgr.save();

            String go = ar.baseURL+"v/"+up.getKey()+"/userSettings.htm";
            return redirectBrowser(ar,go);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.add.mail.to.profile", null, ex);
        }
    }

    @RequestMapping(value="/{userKey}/uploadContacts.form", method = RequestMethod.POST)
    public ModelAndView uploadContacts(
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
            return redirectBrowser(ar,"contacts.htm");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.upload.contacts", new Object[]{userKey}, ex);
        }
    }


    @RequestMapping(value="/editMicroProfileDetail.form", method = RequestMethod.POST)
    public ModelAndView editMicroProfileDetail(

            HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        try{
            AuthRequest ar = NGWebUtils.getAuthRequest(request, response, "Can not update user contacts.");

            String emailId = ar.reqParam("emailId").trim();
            String idDisplayName = ar.reqParam("userName");
            String go = ar.reqParam("go");

            MicroProfileMgr.setDisplayName(emailId, idDisplayName);
            MicroProfileMgr.save();
            return redirectBrowser(ar,go);

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
            parameters.put(Constant.MSG_TYPE , Constant.SUCCESS);
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
    public ModelAndView openConfirmedAddIdView(
            @PathVariable String userKey,
            HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        ModelAndView modelAndView = null;
        try{

            AuthRequest ar = NGWebUtils.getAuthRequest(request, response, "Can not open confirm page.");

            modelAndView = new ModelAndView("confirmedAddIdView");
            request.setAttribute("tabId", "My Settings");
            String realRequestURL = request.getRequestURL().toString();
            request.setAttribute("realRequestURL", realRequestURL);

            request.setAttribute("userKey", ar.getUserProfile().getKey());
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.open.confirm.added.id.view", new Object[]{userKey}, ex);
        }
        return modelAndView;
    }

    @RequestMapping(value="/{userKey}/changeListenerSettings.form", method = RequestMethod.POST)
    public ModelAndView changeListenerSettings(
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

            return redirectBrowser(ar,"emailListnerSettings.htm");

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.to.change.listener.settings", null, ex);
        }
    }


    @RequestMapping(value = "/{userKey}/notificationSettings.htm", method = RequestMethod.GET)
    public ModelAndView goToNotificationSetting(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);

            UserProfile userProfile = UserManager.getUserProfileOrFail(userKey);

            if(!ar.hasSpecialSessionAccess("Notifications:"+userKey)){
                if(!ar.isLoggedIn()){
                    return showWarningView(ar, "message.loginalert.see.page");
                }
            }

            ModelAndView modelAndView = createModelAndView(ar, userProfile, "Notification Settings", "NotificationSettings");
            modelAndView.addObject( "messages", context );
            request.setAttribute("tabId", "Settings");
            return modelAndView;
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.open.notification.page", new Object[]{userKey} , ex);
        }
    }

    @RequestMapping(value = "/unsubscribe.htm", method = RequestMethod.GET)
    public ModelAndView unsubscribe(
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);

            if(ar.isLoggedIn()){
                UserProfile profile = ar.getUserProfile();
                ar.resp.sendRedirect(ar.baseURL+"v/"+profile.getKey()+"/notificationSettings.htm");
                return null;
            }

            String userKey = ar.defParam("userKey", null);
            String emailId = ar.defParam("emailId", null);

            if(userKey != null){
                UserProfile userProfile = UserManager.getUserProfileOrFail(userKey);
                String accessCode = ar.defParam("accessCode", null);
                if(userProfile != null && userProfile.getAccessCode().equals(accessCode)){
                    ar.setSpecialSessionAccess("Notifications:"+userKey);
                    ar.resp.sendRedirect(ar.baseURL+"v/"+userKey+"/notificationSettings.htm");
                    return null;
                }
            }else if(emailId != null){
                return redirectBrowser(ar,"unsubscribemember.htm?emailId="+URLEncoder.encode(emailId, "UTF-8"));
            }
            return redirectToLoginView(ar, "nugen.user.notification.automatic.access.denied",null );
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.open.notification.page", null , ex);
        }
    }

    @RequestMapping(value="/{userKey}/saveNotificationSettings.form", method = RequestMethod.POST)
    public ModelAndView saveNotificationSettings(
            @PathVariable String userKey,
            HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        try{
            AuthRequest ar =  AuthRequest.getOrCreate(request, response);
            if(!ar.hasSpecialSessionAccess("Notifications:"+userKey)){
                ar.assertLoggedIn("Can not update notification settings.");
            }
            String pageId = ar.reqParam("pageId");

            NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
            ar.setPageAccessLevels(ngp);
            UserProfile up = UserManager.getUserProfileOrFail(userKey);

            String sendDigest = ar.defParam("sendDigest", null);
            if(sendDigest != null && "never".equals(sendDigest)){

                up.clearNotification( ngp.getKey());
                UserManager.writeUserProfilesToFile();
            }

            int eventType = HistoryRecord.EVENT_TYPE_MODIFIED;
            String[] tasksToBeCompleted= ar.req.getParameterValues("markascompleted");
            if(tasksToBeCompleted != null && tasksToBeCompleted.length > 0){
                GoalRecord taskRecord = null;
                for (String taskId : tasksToBeCompleted) {
                    taskRecord = ngp.getGoalOrFail(taskId);
                    taskRecord.setEndDate(ar.nowTime);
                    taskRecord.setState(BaseRecord.STATE_COMPLETE);
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
            return redirectBrowser(ar,"notificationSettings.htm");

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.to.update.notification.settings", null, ex);
        }
    }


    @RequestMapping(value = "/unsubscribemember.htm", method = RequestMethod.GET)
    public ModelAndView unSubscribeMember(
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);

            String emailId = ar.reqParam("emailId").trim();
            ModelAndView modelAndView = new ModelAndView("unsubscribemember");
            modelAndView.addObject( "emailId", emailId );

            return modelAndView;
        }catch(Exception ex){
            throw new Exception("Unable to unsubscribe member", ex);
        }
    }

    @RequestMapping(value="/unsubscribemember.form", method = RequestMethod.POST)
    public ModelAndView saveUnsubScribeMember(
            HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        ModelAndView modelAndView = null;
        try{
            AuthRequest ar =  AuthRequest.getOrCreate(request, response);//NGWebUtils.getAuthRequest(request, response, "Can not update notification settings.");

            String pageId = ar.reqParam("pageId");
            String emailId = ar.reqParam("emailId").trim();

            NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
            ar.setPageAccessLevels(ngp);

            String[] stopRolePlayer= ar.req.getParameterValues("stoproleplayer");
            removeFromRole(ngp, new AddressListEntry(emailId), stopRolePlayer);
            ngp.saveFile(ar, "unsubscribe member");

            modelAndView = new ModelAndView(new RedirectView("unsubscribemember.htm"));
            modelAndView.addObject( "emailId", emailId );
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.to.update.notification.settings", null, ex);
        }
        return modelAndView;
    }


    @RequestMapping(value = "/{userKey}/userSettings.htm", method = RequestMethod.GET)
    public ModelAndView userSettings(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{

            AuthRequest ar = AuthRequest.getOrCreate(request, response);

            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }

            UserProfile uProf = UserManager.getUserProfileOrFail(userKey);

            UserProfile loggedInUser = ar.getUserProfile();
            String userName = loggedInUser.getName();

            if (userName==null || userName.length()==0) {
                userName = loggedInUser.getKey();
            }
            if (userName.length()>28)
            {
                userName = userName.substring(0,28);
            }

            NGContainer ngp =null;

            String isRequestingForNewProjectUsingLinks = ar.defParam( "projectName", null );
            String bookForNewProject = ar.defParam( "bookKey", null );

            if(isRequestingForNewProjectUsingLinks!=null && bookForNewProject!=null){
                Vector<NGPageIndex> foundPages = ar.getCogInstance().getPageIndexByName(isRequestingForNewProjectUsingLinks);
                if(foundPages.size()>0){
                    NGPageIndex foundPage = foundPages.get( 0 );
                    return redirectBrowser(ar,ar.retPath+"t/"+bookForNewProject+"/"+foundPage.containerKey+"/notesList.htm" );
                }
            }

            request.setAttribute("book",    null);
            request.setAttribute("ngpage",ngp);
            request.setAttribute("userName",userName);
            request.setAttribute("flag","true");
            request.setAttribute("retPath",ar.retPath);
            return createModelAndView(ar, uProf, "Settings", "UserSettings");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.userprofile.page", new Object[]{userKey} , ex);
        }
    }

    @RequestMapping(value = "/{userKey}/userContacts.htm", method = RequestMethod.GET)
    public ModelAndView userContacts(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{

            AuthRequest ar = AuthRequest.getOrCreate(request, response);

            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }
            UserProfile uProf = UserManager.getUserProfileOrFail(userKey);

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
                Vector<NGPageIndex> foundPages = ar.getCogInstance().getPageIndexByName(isRequestingForNewProjectUsingLinks);
                if(foundPages.size()>0){
                    NGPageIndex foundPage = foundPages.get( 0 );
                    return redirectBrowser(ar,ar.retPath+"t/"+bookForNewProject+"/"+foundPage.containerKey+"/notesList.htm" );
                }
            }

            request.setAttribute("book",    null);
            request.setAttribute("ngpage",ngp);
            request.setAttribute("userName",userName);
            request.setAttribute("username","PLEASE REPORT ISSUE #148944");
            request.setAttribute("flag","true");
            request.setAttribute("retPath",ar.retPath);
            return createModelAndView(ar, uProf, "Settings", "UserContacts");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.userprofile.page", new Object[]{userKey} , ex);
        }
    }

    @RequestMapping(value = "/{userKey}/userConnections.htm", method = RequestMethod.GET)
    public ModelAndView userConnections(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{

            AuthRequest ar = AuthRequest.getOrCreate(request, response);

            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }
            UserProfile up = UserManager.getUserProfileOrFail(userKey);

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
                Vector<NGPageIndex> foundPages = ar.getCogInstance().getPageIndexByName(isRequestingForNewProjectUsingLinks);
                if(foundPages.size()>0){
                    NGPageIndex foundPage = foundPages.get( 0 );
                    return redirectBrowser(ar,ar.retPath+"t/"+bookForNewProject+"/"+foundPage.containerKey+"/notesList.htm" );
                }
            }

            request.setAttribute("book",    null);
            request.setAttribute("ngpage",ngp);
            request.setAttribute("userName",userName);
            request.setAttribute("flag","true");
            request.setAttribute("retPath",ar.retPath);
            return createModelAndView(ar, up, "Settings", "UserConnections");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.userprofile.page", new Object[]{userKey} , ex);
        }
    }


    @RequestMapping(value = "/accountRequestResult.htm", method = RequestMethod.GET)
    public ModelAndView accountRequestResult(HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        ModelAndView modelAndView = new ModelAndView("accountRequestResult");
        return modelAndView;
    }

    @RequestMapping(value = "/{userKey}/clearCookie.form", method = RequestMethod.POST)
    public ModelAndView clearCookie(HttpServletRequest request, HttpServletResponse response)
    throws Exception {
        ModelAndView modelAndView = null;
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }
            ar.clearCookie();

            UserProfile up = ar.getUserProfile();

            String go = ar.baseURL+"v/"+up.getKey()+"/userSettings.htm";
            modelAndView = new ModelAndView(new RedirectView(go));
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.to.clear.cookies", null, ex);
        }
        return modelAndView;
    }


    @RequestMapping(value = "/{userKey}/searchAllNotes.htm", method = RequestMethod.GET)
    public ModelAndView searchAllNotes(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
           throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);

            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }

            return new ModelAndView("SearchAllNotes");

        }catch(Exception ex){
            throw new Exception("failure searching with userid: "+userKey, ex);
        }
    }

    @RequestMapping(value = "/{userKey}/searchNotes.json", method = RequestMethod.POST)
    public void searchPublicNotesJSON(@PathVariable String userKey,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            ar.assertLoggedIn("Must be logged in to search the notes");

            JSONObject query = getPostedObject(ar);

            String searchText    = query.getString("searchFilter");
            String searchSite    = query.getString("searchSite");
            String searchProject = query.getString("searchProject");

            if ("all".equals(searchSite)) {
                searchSite = null;
            }

            SearchManager.initializeIndex(ar.getCogInstance());
            List<SearchResultRecord> searchResults = null;
            if (searchText.length()>0) {
                searchResults = SearchManager.performSearch(ar, searchText, searchProject, searchSite);
            }
            else {
                searchResults = new Vector<SearchResultRecord>();
            }

            JSONArray resultList = new JSONArray();
            for (SearchResultRecord srr : searchResults) {
                resultList.put(srr.getJSON());
            }
            resultList.write(ar.w, 2, 2);
            ar.flush();
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
                StringWriter owner = new StringWriter();
                AuthRequest clone = new AuthDummy(profile, owner, ar.getCogInstance());
                ale.writeLink(clone);
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
        StringWriter bodyWriter = new StringWriter();
        AuthRequest clone = new AuthDummy(ar.getUserProfile(), bodyWriter, ar.getCogInstance());
        OptOutAddr ooa = new OptOutIndividualRequest(new AddressListEntry(
                addressee));

        clone.setNewUI(true);
        clone.retPath = ar.baseURL;
        clone.write("<html><body>\n");
        clone.write("You requested to join the role <b>'");
        clone.writeHtml(roleName);
        clone.write("'</b> on the project '");
        ngp.writeContainerLink(clone, 100);
        clone.write("'.</p><p>\n");
        if ("approved".equalsIgnoreCase(action)) {
            clone.write("Your request has been <b>accepted</b>. Now you can play the role of <b>'");
            clone.write(roleName);
            clone.write("'</b> in that project.");

        } else {
            clone.write("Your request has been <b>denied</b>.");
        }
        clone.write("\n</p><p><i>Reason/Comment: </i>");
        clone.writeHtml(responseComment);
        clone.write("</p>");
        clone.write("</body></html>");

        EmailSender.containerEmail(ooa, ngp, subject, bodyWriter.toString(),
                null, new Vector<String>(), ar.getCogInstance());
    }



}

