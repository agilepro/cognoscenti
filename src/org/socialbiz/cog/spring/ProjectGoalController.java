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

import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AccessControl;
import org.socialbiz.cog.AddressListEntry;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.BaseRecord;
import org.socialbiz.cog.DOMFace;
import org.socialbiz.cog.DecisionRecord;
import org.socialbiz.cog.GoalRecord;
import org.socialbiz.cog.HistoryRecord;
import org.socialbiz.cog.LicensedURL;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.NGPageIndex;
import org.socialbiz.cog.NGRole;
import org.socialbiz.cog.NGWorkspace;
import org.socialbiz.cog.ProcessRecord;
import org.socialbiz.cog.SectionUtil;
import org.socialbiz.cog.TaskArea;
import org.socialbiz.cog.UserManager;
import org.socialbiz.cog.UserProfile;
import org.socialbiz.cog.UtilityMethods;
import org.socialbiz.cog.exception.NGException;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;
import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;

/**
 * This class will handle all requests managing process/tasks. Currently this is
 * handling only requests that are coming to create a new task, update/modify
 * task and also reassign the task to other member.
 *
 */
@Controller
public class ProjectGoalController extends BaseController {

    public static final String CREATE_TASK = "Create Task";
    public static final String BOOK_ATT = "book";
    public static final String PROCESS_HTML = "projectActiveTasks.htm";
    public static final String PROJECT_TASKS="Workspace Action Items";
    public static final String SUCCESS_LOCAL = "success_local";
    public static final String SUCCESS_REMOTE = "success_remote";
    public static final String REMOTE_PROJECT = "Remote_project";
    public static final String LOCAL_PROJECT = "Local_Project";



    ///////////////////////// MAIN VIEWS ////////////////////////////////////

    @RequestMapping(value = "/{siteId}/{pageId}/goalList.htm", method = RequestMethod.GET)
    public void goalList(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request,   HttpServletResponse response)  throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "GoalList");
    }



    @RequestMapping(value = "/{siteId}/{pageId}/statusList.htm", method = RequestMethod.GET)
    public void statusList(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request,   HttpServletResponse response)  throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "StatusList");
    }


    @RequestMapping(value = "/{siteId}/{pageId}/task{taskId}.htm", method = RequestMethod.GET)
    public void displayTask(@PathVariable String siteId,
        @PathVariable String pageId,  @PathVariable String taskId,
        HttpServletRequest request,   HttpServletResponse response)
            throws Exception
    {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGPage ngp = registerRequiredProject(ar, siteId, pageId);

            GoalRecord goal = ngp.getGoalOrFail(taskId);
            boolean canAccessGoal = AccessControl.canAccessGoal(ar, ngp, goal);

            if(!canAccessGoal){
                if (checkLoginMember(ar)) {
                    return;
                }
                throw new Exception("Program Logic Error: logged in member should be able to see task.");
            }
            
            //only get here if you are logged in, and you have permission to access the task.
            request.setAttribute("taskId", taskId);
            if(goal.isPassive()) {
                streamJSP(ar, "displayPassiveGoal");
            }
            else{
                streamJSP(ar, "GoalEdit");
            }

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.edit.task.page", new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/decisionList.htm", method = RequestMethod.GET)
    public void decisionList(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request,   HttpServletResponse response)  throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "DecisionList");
    }



    ////////////////////////// FORM SUBMISSIONS //////////////////////////////


    @RequestMapping(value = "/{siteId}/{pageId}/CreateTask.form", method = RequestMethod.POST)
    public void createTask(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGPage ngp = registerRequiredProject(ar, siteId, pageId);
            ar.assertLoggedIn("Must be logged in to create a task.");

            // call a method for creating new task
            taskActionCreate(ar, ngp, request, null);

            String assignto= ar.defParam("assignto", "");
            NGWebUtils.updateUserContactAndSaveUserPage(ar, "Add",assignto);

            redirectBrowser(ar,PROCESS_HTML);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.create.task", new Object[]{pageId,siteId} , ex);
        }
    }

    public static String parseEmailId(String assigneTo) throws Exception {

        String assignessEmail = "";
        List<String> emails = UtilityMethods.splitString(assigneTo, ',');

        for (String email : emails) {
            if (!email.equals("")) {
                int bindx = email.indexOf('<');
                int length = email.length();
                if (bindx > 0) {
                    email = email.substring(bindx + 1, length - 1);
                }

                assignessEmail = assignessEmail + "," + email;
            }
        }
        if (assignessEmail.startsWith(",")) {
            assignessEmail = assignessEmail.substring(1);
        }
        return assignessEmail;
    }

    @RequestMapping(value = "/{siteId}/{pageId}/createSubTask.form", method = RequestMethod.POST)
    public void createSubTask(@PathVariable String siteId,
            @PathVariable String pageId, @RequestParam String taskId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGPage ngp = registerRequiredProject(ar, siteId, pageId);
            ar.assertLoggedIn("Must be logged in to manipulate tasks.");

            //TODO: taskId should really be parentTaskId
            taskActionCreate(ar, ngp, request, taskId);

            String assignto= ar.defParam("assignto", "");
            NGWebUtils.updateUserContactAndSaveUserPage(ar, "Add",assignto);

            String go = ar.reqParam("go");
            ar.resp.sendRedirect(go);

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.create.sub.task", new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/subtask.htm", method = RequestMethod.GET)
    public ModelAndView showSubTask(@PathVariable
    String siteId, @PathVariable
    String pageId, @RequestParam
    String taskId, HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGPage nGPage = registerRequiredProject(ar, siteId, pageId);
            ar.assertLoggedIn("Must be logged in to open a sub task");

            request.setAttribute("realRequestURL", ar.getRequestURL());
            request.setAttribute("taskId", taskId);
            request.setAttribute("title", " : " + nGPage.getFullName());
            return new ModelAndView("subtask");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.create.task.page", new Object[]{pageId,siteId} , ex);
        }
    }

    //TODO: is this still used?
    private void taskActionUpdate(AuthRequest ar, NGPage ngp, String parentTaskId)
            throws Exception
    {
       // final boolean updateTask =  true;
        ar.setPageAccessLevels(ngp);
        ar.assertMember("Must be a member of a workspace to manipulate tasks.");
        ar.assertNotFrozen(ngp);

        UserProfile userProfile = ar.getUserProfile();

        String taskState = ar.reqParam("state");
        String priority = ar.reqParam("priority");

        GoalRecord task = ngp.getGoalOrFail(parentTaskId);
        int eventType = HistoryRecord.EVENT_TYPE_MODIFIED;
        task.setSynopsis(ar.reqParam("taskname_update"));

        task.setDueDate(SectionUtil.niceParseDate(ar.defParam("dueDate_update","")));
        task.setStartDate(SectionUtil.niceParseDate(ar.defParam("startDate_update","")));
        task.setEndDate(SectionUtil.niceParseDate(ar.defParam("endDate_update","")));

        String assignto= ar.defParam("assignto", null);
        String assigneeAddress = null;

        if (assignto!=null && assignto.length()>0) {
            assigneeAddress = parseEmailId(assignto);
        }
        if(assigneeAddress!=null) {
            //if the assignee is set, use it
            task.getAssigneeRole().addPlayer(new AddressListEntry(assigneeAddress));
        }
        else {
            //if the assignee is not set, then set assignee to the current user.
            task.getAssigneeRole().addPlayer(new AddressListEntry(userProfile));
        }


        String processLink = ar.defParam("processLink", "");
        if (processLink.length()>0) {
            task.setSub(processLink);
        }

        task.setPriority(Integer.parseInt(priority));
        task.setDescription(ar.defParam("description", ""));
        task.setStateAndAct(Integer.parseInt(taskState), ar);

        task.setCreator(userProfile.getUniversalId());
        task.setModifiedDate(ar.nowTime);
        task.setModifiedBy(ar.getBestUserId());

        HistoryRecord.createHistoryRecord(ngp, task.getId(),
                        HistoryRecord.CONTEXT_TYPE_TASK, eventType, ar, "");

        ngp.saveFile(ar, CREATE_TASK);
    }


    private void taskActionCreate(AuthRequest ar, NGPage ngp,
            HttpServletRequest request, String parentTaskId)
            throws Exception
    {
        ar.setPageAccessLevels(ngp);
        ar.assertMember("Must be a member of a workspace to manipulate tasks.");
        ar.assertNotFrozen(ngp);

        UserProfile userProfile = ar.getUserProfile();

        int eventType;

        GoalRecord task = null;
        GoalRecord parentTask = null;


        boolean isSubTask = (parentTaskId != null && parentTaskId.length() > 0);
        if (isSubTask) {
            parentTask = ngp.getGoalOrFail(parentTaskId);
            task = ngp.createSubGoal(parentTask, ar.getBestUserId());
            eventType = HistoryRecord.EVENT_TYPE_SUBTASK_CREATED;
        } else {
            task = ngp.createGoal(ar.getBestUserId());
            eventType = HistoryRecord.EVENT_TYPE_CREATED;
        }
        task.setSynopsis(ar.reqParam("taskname"));

        if (isSubTask) {
            // set the subtask's due date.
            task.setDueDate(parentTask.getDueDate());
        } else {
            String duedate = ar.defParam("dueDate","");
            if(duedate.length()>0){
                task.setDueDate(SectionUtil.niceParseDate(duedate));
            }
        }

        String assignto= ar.defParam("assignto", null);

        if (assignto==null || assignto.length()==0) {
            //The assignee is not set, then set assignee to the current user.
            //They can change that later.
            task.getAssigneeRole().addPlayer(new AddressListEntry(userProfile));
        }
        else {
            String assignee = parseEmailId(assignto);
            if(assignee!=null) {
                //if the assignee is set, use it
                task.getAssigneeRole().addPlayer(new AddressListEntry(assignee));
            }
            else {
                //if the assignee is not set, then set assignee to the current user.
                task.getAssigneeRole().addPlayer(new AddressListEntry(userProfile));
            }
        }


        String processLink = ar.defParam("processLink", "");
        if (processLink.length()>0) {
            task.setSub(processLink);
        }

        task.setPriority(Integer.parseInt(ar.reqParam("priority")));
        task.setDescription(ar.defParam("description", ""));
        // should allow the user to specify the desired state, but if not specified,
        // the default should be "offered" when creating a task.

        String startOption=ar.defParam("startActivity", "");
        if(startOption.length()>0){
            task.setState(BaseRecord.STATE_OFFERED);
        }else{
            task.setState(BaseRecord.STATE_UNSTARTED);
        }


        task.setCreator(ar.getBestUserId());
        task.setModifiedDate(ar.nowTime);
        task.setModifiedBy(ar.getBestUserId());

        HistoryRecord.createHistoryRecord(ngp, task.getId(),
                        HistoryRecord.CONTEXT_TYPE_TASK, eventType, ar, "");
        ngp.saveFile(ar, CREATE_TASK);
    }



    @RequestMapping(value = "/{siteId}/{pageId}/updateTaskStatus.ajax", method = RequestMethod.POST)
    public void handleActivityUpdates(@PathVariable String siteId, @PathVariable String pageId,@RequestParam String pId,
                HttpServletRequest request, HttpServletResponse response) throws Exception
    {
        AuthRequest ar = null;
        try{
            ar = AuthRequest.getOrCreate(request, response);
            NGPage ngp = registerRequiredProject(ar, siteId, pageId);
            ar.assertLoggedIn("Can't edit a work item.");
            ar.assertMember("Must be a member of a workspace to update tasks.");

            String id = ar.reqParam("id");
            GoalRecord task = ngp.getGoalOrFail(id);
            String index=ar.reqParam("index");
            int eventType = HistoryRecord.EVENT_TYPE_MODIFIED;
            String comments = "";
            String action = ar.reqParam("action");
            if (action.equals("Start Offer")) {
                task.setStateAndAct(BaseRecord.STATE_OFFERED, ar);
                eventType = HistoryRecord.EVENT_TYPE_STATE_CHANGE_STARTED;
            } else if (action.equals("Mark Accepted") || action.equals("Accept Activity")) {
                task.setStateAndAct(BaseRecord.STATE_ACCEPTED, ar);
                eventType = HistoryRecord.EVENT_TYPE_STATE_CHANGE_ACCEPTED;
            } else if (action.equals("Complete Activity")) {
                task.setStateAndAct(BaseRecord.STATE_COMPLETE, ar);
                eventType = HistoryRecord.EVENT_TYPE_STATE_CHANGE_COMPLETE;
            } else if (action.equals("Update Status")) {
                String newStatus = ar.defParam("status", null);
                task.setStatus(newStatus);
            } else {
                throw new NGException("nugen.exceptionhandling.did.not.understand.option", new Object[]{action});
            }

            task.setModifiedDate(ar.nowTime);
            task.setModifiedBy(ar.getBestUserId());
            HistoryRecord.createHistoryRecord(ngp, task.getId(),
                    HistoryRecord.CONTEXT_TYPE_TASK, eventType, ar, comments);

            ngp.saveFile(ar, "Edit Work Item");

            JSONObject jo = new JSONObject();
            jo.put("msgType", "success");
            jo.put("taskId", task.getId());
            jo.put("index", index);
            jo.put("taskState", String.valueOf(task.getState()));
            NGWebUtils.sendResponse(ar, jo.toString());
        }catch (Exception ex) {
            ar.logException("Caught by updateTaskStatus.ajax", ex);
            NGWebUtils.sendResponse(ar, NGWebUtils.getExceptionMessageForAjaxRequest(ex, ar.getLocale()));
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/reassignTaskSubmit.form", method = RequestMethod.POST)
    public void reassignTask(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Must be logged in to reassign task.");
            NGPage ngp = registerRequiredProject(ar, siteId, pageId);
            ar.assertMember("Must be a member of a workspace to reassign tasks.");
            ar.assertNotFrozen(ngp);

            String taskId = ar.reqParam("taskid");
            GoalRecord task = ngp.getGoalOrFail(taskId);
            String go = ar.reqParam("go");

            String assignee = null;
            UserProfile userProfile = ar.getUserProfile();

            String assignto = ar.defParam("assignto","");
            if (assignto == null || "".equals(assignto)) {
                assignee = userProfile.getPreferredEmail();
            } else {
                assignee = parseEmailId(assignto);
            }

            String removeUser=ar.defParam("remove","");
            NGRole goalRole = task.getAssigneeRole();
            if(removeUser!=""){
                String removeAssignee= ar.defParam("removeAssignee","") ;
                goalRole.removePlayer(new AddressListEntry(removeAssignee));
            }
            else{
                goalRole.clear();
                goalRole.addPlayer(new AddressListEntry(assignee));
                NGWebUtils.updateUserContactAndSaveUserPage(ar, "Add" ,assignto);
            }

            task.setModifiedDate(ar.nowTime);
            task.setModifiedBy(ar.getBestUserId());
            HistoryRecord.createHistoryRecord(ngp, task.getId(),
                    HistoryRecord.CONTEXT_TYPE_TASK,
                    HistoryRecord.EVENT_TYPE_MODIFIED, ar, "");

            ngp.saveFile(ar, CREATE_TASK);

            redirectBrowser(ar,go);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.reassign.task",
                    new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/updateTask.form", method = RequestMethod.POST)
    public void updateTask(@PathVariable String siteId,
            @PathVariable String pageId,
            @RequestParam String taskId,HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Must be logged in to update task.");
            NGPage ngp = registerRequiredProject(ar, siteId, pageId);
            String go = ar.reqParam("go");

            taskActionUpdate(ar, ngp, taskId);

            redirectBrowser(ar,go);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.update.task", new Object[]{pageId,siteId} , ex);
        }
    }


    //TODO: is this still used?  Switch to JSON option?
    @RequestMapping(value = "/{siteId}/{pageId}/updateGoalSpecial.form", method = RequestMethod.POST)
    public void updateGoalSpecial(@PathVariable String siteId,
            @PathVariable String pageId,HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{

            //note: this form is for people NOT logged in!
            //ukey specifies user, and mntask verifies they have a proper link to the action item

            NGPage ngp = registerRequiredProject(ar, siteId, pageId);
            String taskId = ar.reqParam("taskId");
            String mntask = ar.reqParam("mntask");
            String ukey = ar.reqParam("ukey");
            String go = ar.reqParam("go");
            String cmd = ar.reqParam("cmd");

            GoalRecord goal  = ngp.getGoalOrFail(taskId);
            if (!AccessControl.isMagicNumber(ar, ngp, goal, mntask)) {
                throw new Exception("Program Logic Error: improperly constructed request mntask = "+mntask);
            }
            UserProfile uProf = UserManager.getUserProfileByKey(ukey);
            ar.setUserForOneRequest(uProf);
            int eventType = HistoryRecord.EVENT_TYPE_MODIFIED;
            String accomp = "";

            if ("Remove Me".equals(cmd))  {
                NGRole assignees = goal.getAssigneeRole();
                if (assignees.isPlayer(uProf)) {
                    String userId = assignees.whichIDForUser(uProf);
                    AddressListEntry ale = new AddressListEntry(userId);
                    assignees.removePlayer(ale);
                    eventType = HistoryRecord.EVENT_PLAYER_REMOVED;
                    accomp = "using 'Remove Me' from anonymous web form";
                }
                //silently ignore requests for users that are not assigned
            }
            else if ("Complete".equals(cmd))  {
                goal.setStateAndAct(GoalRecord.STATE_COMPLETE, ar);
                eventType = HistoryRecord.EVENT_TYPE_STATE_CHANGE_COMPLETE;
                accomp = "using 'Completed' through anonymous web form";
            }
            else if ("Other".equals(cmd))  {
                sendRedirectToLogin(ar);
                return;
                //do not save any changes
            }
            else {
                throw new Exception("Program Logic Error: don't understand command = "+cmd);
            }

            goal.setModifiedDate(ar.nowTime);
            goal.setModifiedBy(ar.getBestUserId());
            HistoryRecord.createHistoryRecord(ngp, goal.getId(),
                    HistoryRecord.CONTEXT_TYPE_TASK, eventType, ar, accomp);
            ngp.save();

            redirectBrowser(ar,go);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.update.task", new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/subProcess.ajax", method = RequestMethod.POST)
    public void searchSubProcess(HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        String responseMessage = "";
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            ar.assertLoggedIn("You need to login to access subProcess.ajax.");

            String processURL = ar.reqParam("processURL");
            int pcolon = processURL.indexOf(":");
            int pfs = processURL.indexOf("/");

            String processLocation = processURL.substring(0, pcolon);
            String accoundID = processURL.substring(pcolon + 1, pfs);
            String projectID = processURL.substring(pfs + 1, processURL.length());

            JSONObject param = new JSONObject();
            if (processLocation.equalsIgnoreCase("local")) {
                param.put("msgType", SUCCESS_LOCAL);
                param.put(LOCAL_PROJECT, getLocalProcess(accoundID, projectID, ar));
            }else if(processLocation.equalsIgnoreCase("http")){
                param.put("msgType", SUCCESS_REMOTE);
                param.put("msg", REMOTE_PROJECT);
            }
            responseMessage = param.toString();
        }catch(Exception ex){
            responseMessage = NGWebUtils.getExceptionMessageForAjaxRequest(ex, ar.getLocale());
            ar.logException("Caught by subProcess.ajax", ex);
        }
        NGWebUtils.sendResponse(ar, responseMessage);
    }


    private String getLocalProcess(String siteId, String projectID,
            AuthRequest ar) throws Exception {

        for (NGPageIndex ngpi : ar.getCogInstance().getAllProjectsInSite(siteId)) {
            if (ngpi.containerKey.equals(projectID)) {
                NGPage page = ngpi.getWorkspace();
                ar.setPageAccessLevels(page);
                ProcessRecord process = page.getProcess();
                LicensedURL thisProcessUrl = process.getWfxmlLink(ar);
                return thisProcessUrl.getCombinedRepresentation();
            }
        }

        throw new Exception("Local process for workspace '"+projectID+"' not found");
    }


    @RequestMapping(value = "/{siteId}/{pageId}/fetchGoal.json", method = RequestMethod.GET)
    public void fetchGoal(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String gid = "";
        try{
            NGPage ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngp);
            ar.assertMember("Must be a member to see a action item.");
            gid = ar.reqParam("gid");
            GoalRecord gr = null;
            gr = ngp.getGoalOrFail(gid);
            JSONObject repo = gr.getJSON4Goal(ngp);
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to fetch Action Item ("+gid+")", ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/updateGoal.json", method = RequestMethod.POST)
    public void updateGoal(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String gid = "";
        try{
            NGPage ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngp);
            ar.assertMember("Must be a member to create a action item.");
            ar.assertNotFrozen(ngp);
            gid = ar.reqParam("gid");
            JSONObject goalInfo = getPostedObject(ar);
            GoalRecord gr = null;
            int eventType = HistoryRecord.EVENT_TYPE_MODIFIED;
            boolean isNew = "~new~".equals(gid);
            if (isNew) {
                gr = ngp.createGoal(ar.getBestUserId());
                goalInfo.put("universalid", gr.getUniversalId());
                eventType = HistoryRecord.EVENT_TYPE_CREATED;
            }
            else {
                gr = ngp.getGoalOrFail(gid);
            }

            int previousState = gr.getState();
            String previousStatus = gr.getStatus();
            long previousDue = gr.getDueDate();
            String previousProspects = gr.getProspects();

            gr.updateGoalFromJSON(goalInfo, ngp, ar);

            //now make the history description of what just happened
            StringBuilder inventedComment = new StringBuilder(goalInfo.optString("newAccomplishment"));
            boolean hasChanged = false;
            if (previousState != gr.getState()) {
                inventedComment.append(" State:");
                inventedComment.append(BaseRecord.stateName(gr.getState()));
                hasChanged = true;
            }
            if (!previousStatus.equals(gr.getStatus())) {
                inventedComment.append(" Status:");
                inventedComment.append(gr.getStatus());
                hasChanged = true;
            }
            if (previousDue != gr.getDueDate()) {
                inventedComment.append(" DueDate:");
                inventedComment.append(SectionUtil.getNicePrintDate(gr.getDueDate()));
                hasChanged = true;
            }
            if (!previousProspects.equals(gr.getProspects())) {
                inventedComment.append(" R-Y-G:");
                inventedComment.append(gr.getProspects());
                hasChanged = true;
            }

            if (hasChanged) {
                String comments = inventedComment.toString();

                //create the history record here.
                HistoryRecord.createHistoryRecord(ngp, gr.getId(),
                        HistoryRecord.CONTEXT_TYPE_TASK, eventType, ar,
                        comments);
            }
            ngp.renumberGoalRanks();
            ngp.saveFile(ar, "Updated action item "+gid);
            JSONObject repo = gr.getJSON4Goal(ngp);
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to update Action Item ("+gid+")", ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/updateMultiGoal.json", method = RequestMethod.POST)
    public void updateMultiGoal(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGPage ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngp);
            ar.assertMember("Must be a member to create a action item.");
            ar.assertNotFrozen(ngp);

            JSONObject goalEnvelope = getPostedObject(ar);
            JSONArray goalList = goalEnvelope.getJSONArray("list");
            JSONArray responseList = new JSONArray();

            int last = goalList.length();
            for (int i=0; i<last; i++) {
                JSONObject goalInfo = goalList.getJSONObject(i);
                String gid = goalInfo.getString("id");
                GoalRecord gr = null;
                boolean isNew = "~new~".equals(gid);
                if (isNew) {
                    gr = ngp.createGoal(ar.getBestUserId());
                    goalInfo.put("universalid", gr.getUniversalId());
                }
                else {
                    gr = ngp.getGoalOrFail(gid);
                }

                gr.updateGoalFromJSON(goalInfo, ngp, ar);
                responseList.put(gr.getJSON4Goal(ngp));
            }

            //TODO: maybe this should return ALL the goals since they all
            //might change when renumbered
            ngp.renumberGoalRanks();

            ngp.saveFile(ar, "Updated multiple action items");
            JSONObject repo = new JSONObject();
            repo.put("list",  responseList);
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to update multiple Action Items", ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/getGoalHistory.json", method = RequestMethod.GET)
    public void getGoalHistory(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGPage ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngp);
            ar.assertMember("Must be a member to get action item history.");
            String gid = ar.reqParam("gid");
            GoalRecord gr = ngp.getGoalOrFail(gid);

            JSONArray repo = new JSONArray();
            for (HistoryRecord hist : gr.getTaskHistory(ngp)) {
                repo.put(hist.getJSON(ngp, ar));
            }
            sendJsonArray(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to create Action Item for minutes of meeting.", ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/updateDecision.json", method = RequestMethod.POST)
    public void updateDecision(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String did = "";
        try{
            NGPage ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngp);
            ar.assertMember("Must be a member to update a decision.");
            ar.assertNotFrozen(ngp);
            did = ar.reqParam("did");
            JSONObject decisionInfo = getPostedObject(ar);
            DecisionRecord dr = null;
            int eventType = HistoryRecord.EVENT_TYPE_MODIFIED;
            boolean isNew = "~new~".equals(did);
            if (isNew) {
                dr = ngp.createDecision();
                decisionInfo.put("universalid", dr.getUniversalId());
                dr.setTimestamp(ar.nowTime);
                decisionInfo.put("timestamp", ar.nowTime);
                eventType = HistoryRecord.EVENT_TYPE_CREATED;
            }
            else {
                int didVal = DOMFace.safeConvertInt(did);
                if (didVal<=0) {
                    throw new Exception("Don't understand the decision number: "+didVal);
                }
                dr = ngp.findDecisionOrFail(didVal);
            }
            dr.updateDecisionFromJSON(decisionInfo, ngp, ar);

            //create the history record here.
            HistoryRecord.createHistoryRecord(ngp, Integer.toString(dr.getNumber()),
                    HistoryRecord.CONTEXT_TYPE_DECISION, eventType, ar,
                    "update decision");

            ngp.saveFile(ar, "Updated decision "+did);
            JSONObject repo = dr.getJSON4Decision(ngp, ar);
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to update Decision ("+did+")", ex);
            streamException(ee, ar);
        }
    }

    
    
    @RequestMapping(value = "/{siteId}/{pageId}/taskAreas.htm", method = RequestMethod.GET)
    public void taskArea(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request,   HttpServletResponse response)  throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "TaskAreas");
    }
    @RequestMapping(value = "/{siteId}/{pageId}/taskAreas.json", method = RequestMethod.GET)
    public void sharePortsJSON(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            JSONObject repo = new JSONObject();
            JSONArray shareList = new JSONArray();
            for (TaskArea ta : ngw.getTaskAreas()) {
                shareList.put(ta.getMinJSON());
            }
            repo.put("taskAreas", shareList);
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to get the list of task areas ", ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/taskArea{id}.htm", method = RequestMethod.GET)
    public void onePortHTML(@PathVariable String siteId, 
            @PathVariable String pageId,
            @PathVariable String id,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        ar.setParam("id", id);
        ar.setParam("pageId", pageId);
        ar.invokeJSP("/spring/jsp/TaskArea.jsp");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/taskArea{id}.json")
    public void onePortJSON(@PathVariable String siteId, 
            @PathVariable String pageId,
            @PathVariable String id,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            TaskArea ta = null;
            boolean needSave = false;
            if ("~new~".equals(id)) {
                ta = ngw.createTaskArea();
                id = ta.getId();
                needSave = true;
            }
            else {
                ta = ngw.findTaskAreaOrFail(id);
            }
            if ("POST".equalsIgnoreCase(request.getMethod())) {
                JSONObject postBody = this.getPostedObject(ar);
                ta.updateFromJSON(postBody);
                needSave = true;
            }
            if (needSave) {
                ngw.saveContent(ar, "updating the TaskArea");
            }
            JSONObject repo = ta.getMinJSON();
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to get the list of task areas ", ex);
            streamException(ee, ar);
        }
    }

    
    ////////////////////// Process linkage with BPM //////////////////
    
    @RequestMapping(value = "/{siteId}/{pageId}/ProcessApps.htm", method = RequestMethod.GET)
    public void processApps(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request,   HttpServletResponse response)  throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "ProcessApps");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/ProcessRun.htm", method = RequestMethod.GET)
    public void processRun(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request,   HttpServletResponse response)  throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "ProcessRun");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/ProcessTasks.htm", method = RequestMethod.GET)
    public void processTasks(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request,   HttpServletResponse response)  throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "ProcessTasks");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/Analytics.htm", method = RequestMethod.GET)
    public void analytics(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request,   HttpServletResponse response)  throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "Analytics");
    }

    @RequestMapping(value = "/{siteId}/{pageId}/RulesList.htm", method = RequestMethod.GET)
    public void rulesList(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request,   HttpServletResponse response)  throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "RulesList");
    }
    
}
