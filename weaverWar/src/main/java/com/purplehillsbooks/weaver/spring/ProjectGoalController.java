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

import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.purplehillsbooks.weaver.AccessControl;
import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.BaseRecord;
import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.DOMFace;
import com.purplehillsbooks.weaver.DecisionRecord;
import com.purplehillsbooks.weaver.GoalRecord;
import com.purplehillsbooks.weaver.HistoryRecord;
import com.purplehillsbooks.weaver.LicensedURL;
import com.purplehillsbooks.weaver.NGPageIndex;
import com.purplehillsbooks.weaver.NGRole;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.ProcessRecord;
import com.purplehillsbooks.weaver.SectionUtil;
import com.purplehillsbooks.weaver.TaskArea;
import com.purplehillsbooks.weaver.UserManager;
import com.purplehillsbooks.weaver.UserPage;
import com.purplehillsbooks.weaver.UserProfile;
import com.purplehillsbooks.weaver.UtilityMethods;
import com.purplehillsbooks.weaver.exception.NGException;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.MemFile;

/**
 * This class will handle all requests managing process/tasks. Currently this is
 * handling only requests that are coming to create a new task, update/modify
 * task and also reassign the task to other member.
 *
 */
@Controller
public class ProjectGoalController extends BaseController {

    public static final String CREATE_TASK = "Create Task";
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



    @RequestMapping(value = "/{siteId}/{pageId}/GoalStatus.htm", method = RequestMethod.GET)
    public void goalStatus(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request,   HttpServletResponse response)  throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "GoalStatus");
    }


    /**
     * Access right on this are a little complicated.  These elements
     * 1. are you logged in
     * 2. if logged in, are you a member of the workspace
     *    people assigned to a task are considered members while the task is open
     * 3. do you have a magic number for the task in order access it anonymously.
     *
     * Situations:
     *
     * 1. login-yes, member-yes, magic number-NA
     * 2. login-no,  member-NA,  magic number-no, show the login error page
     * 3. login-no,  member-NA,  magic number-yes, show the special anon page
     * 4. login-yes, member-no,  magic number-no, show not a member error
     * 5. login-yes, member-no,  magic number-yes, show the special anon page
     */
    @RequestMapping(value = "/{siteId}/{pageId}/task{taskId}.htm", method = RequestMethod.GET)
    public void displayTask(@PathVariable String siteId,
        @PathVariable String pageId,  @PathVariable String taskId,
        HttpServletRequest request,   HttpServletResponse response)
            throws Exception
    {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGWorkspace ngp = registerRequiredProject(ar, siteId, pageId);

            GoalRecord goal = ngp.getGoalOrFail(taskId);
            if(goal.isPassive()) {
                throw new Exception("Passive goals are not supported any more");
            }
            boolean isLoggedIn = ar.isLoggedIn();

            //TODO: why does login not work?
            //System.out.println("task page logged in: "+isLoggedIn);
            boolean isMember   = ar.isMember();
            boolean canAccessGoal = AccessControl.canAccessGoal(ar, ngp, goal);

            request.setAttribute("taskId", taskId);
            if (canAccessGoal && (!isLoggedIn || !isMember) ) {
                specialAnonJSP(ar, siteId, pageId, "ActionItem.jsp");
            }
            else{
                if (warnNotMember(ar)) {
                    return;
                }
                streamJSP(ar, "GoalEdit");
            }

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.edit.task.page", new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/DecisionList.htm", method = RequestMethod.GET)
    public void decisionList(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request,   HttpServletResponse response)  throws Exception {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        showJSPMembers(ar, siteId, pageId, "DecisionList");
    }



    ////////////////////////// FORM SUBMISSIONS //////////////////////////////



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
            NGWorkspace ngp = registerRequiredProject(ar, siteId, pageId);
            ar.assertLoggedIn("Must be logged in to manipulate tasks.");

            //TODO: taskId should really be parentTaskId
            taskActionCreate(ar, ngp, request, taskId);

            String assignto= ar.defParam("assignto", "");
            updateUserContactAndSaveUserPage(ar, "Add",assignto);

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
            NGWorkspace nGPage = registerRequiredProject(ar, siteId, pageId);
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
    private void taskActionUpdate(AuthRequest ar, NGWorkspace ngp, String parentTaskId)
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


    private void taskActionCreate(AuthRequest ar, NGWorkspace ngp,
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



    @RequestMapping(value = "/{siteId}/{pageId}/reassignTaskSubmit.form", method = RequestMethod.POST)
    public void reassignTask(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            ar.assertLoggedIn("Must be logged in to reassign task.");
            NGWorkspace ngp = registerRequiredProject(ar, siteId, pageId);
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
                updateUserContactAndSaveUserPage(ar, "Add" ,assignto);
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
            NGWorkspace ngp = registerRequiredProject(ar, siteId, pageId);
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

            NGWorkspace ngp = registerRequiredProject(ar, siteId, pageId);
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
            sendJson(ar,param);
        }catch(Exception ex){
            streamException(ex,ar);
        }
    }


    private String getLocalProcess(String siteId, String projectID,
            AuthRequest ar) throws Exception {

        for (NGPageIndex ngpi : ar.getCogInstance().getAllProjectsInSite(siteId)) {
            if (ngpi.containerKey.equals(projectID)) {
                NGWorkspace page = ngpi.getWorkspace();
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
            NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
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
            NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngp);
            ar.assertNotFrozen(ngp);
            gid = ar.reqParam("gid");
            JSONObject goalInfo = getPostedObject(ar);
            GoalRecord gr = null;
            int eventType = HistoryRecord.EVENT_TYPE_MODIFIED;
            boolean isNew = "~new~".equals(gid);
            if (isNew) {
                //if it is a new goal you MUST be a member
                ar.assertMember("Need to be Member or assignee of task");
                gr = ngp.createGoal(ar.getBestUserId());
                goalInfo.put("universalid", gr.getUniversalId());
                eventType = HistoryRecord.EVENT_TYPE_CREATED;
            }
            else {
                //you might be an assignee to gain access
                gr = ngp.getGoalOrFail(gid);
                boolean canAccessGoal = AccessControl.canAccessGoal(ar, ngp, gr);
                if (!canAccessGoal) {
                    ar.assertMember("Need to be Member or assignee of task");
                }
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
            NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
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
            NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            ar.setPageAccessLevels(ngp);
            String gid = ar.reqParam("gid");
            GoalRecord gr = ngp.getGoalOrFail(gid);
            boolean canAccessGoal = AccessControl.canAccessGoal(ar, ngp, gr);
            if (!canAccessGoal) {
                ar.assertMember("Need to be Member or assignee of task");
            }

            JSONArray repo = new JSONArray();
            for (HistoryRecord hist : gr.getTaskHistory(ngp)) {
                repo.put(hist.getJSON(ngp, ar));
            }
            sendJsonArray(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to get history for Action Item.", ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/updateDecision.json", method = RequestMethod.POST)
    public void updateDecision(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String did = "";
        try{
            NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
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
                dr.updateDecisionFromJSON(decisionInfo, ngp, ar);
            }
            else if (decisionInfo.has("deleteMe")) {
                int didVal = DOMFace.safeConvertInt(did);
                dr = ngp.findDecisionOrFail(didVal);
                ngp.deleteDecision(didVal);
            }
            else {
                int didVal = DOMFace.safeConvertInt(did);
                if (didVal<=0) {
                    throw new Exception("Don't understand the decision number: "+didVal);
                }
                dr = ngp.findDecisionOrFail(didVal);
                dr.updateDecisionFromJSON(decisionInfo, ngp, ar);
            }


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
    public void taskAreasJSON(@PathVariable String siteId,@PathVariable String pageId,
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
    @RequestMapping(value = "/{siteId}/{pageId}/moveTaskArea.json", method = RequestMethod.POST)
    public void moveTaskArea(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            JSONObject post = this.getPostedObject(ar);
            String areaId = post.getString("areaId");
            boolean moveDown = post.getBoolean("moveDown");
            ngw.moveTaskArea(areaId, moveDown);
            ngw.saveFile(ar, "changed the order of task areas");

            JSONObject repo = new JSONObject();
            JSONArray shareList = new JSONArray();
            for (TaskArea ta : ngw.getTaskAreas()) {
                shareList.put(ta.getMinJSON());
            }
            repo.put("taskAreas", shareList);
            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to get change the order of task areas ", ex);
            streamException(ee, ar);
        }
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

    @RequestMapping(value = "/{siteId}/{pageId}/ActionItem{actId}Due.ics", method = RequestMethod.GET)
    public void meetingTime(@PathVariable String siteId,@PathVariable String pageId,
            @PathVariable String actId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            //NOTE: you do NOT need to be logged in to get the calendar file
            //It is important to allow anyone to receive these links in an email
            //and not be logged in, and still be able to get the calendar on
            //their calendar.  So allow this information to ANYONE who has a link.

            NGWorkspace ngw = registerRequiredProject(ar, siteId, pageId);
            GoalRecord goal = ngw.getGoalOrFail(actId);

            MemFile mf = new MemFile();

            goal.streamICSFile(ar, mf.getWriter(), ngw);

            ar.resp.setContentType("text/calendar");
            mf.outToWriter(ar.w);
            ar.flush();

        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.process.page", new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/moveActionItem.json", method = RequestMethod.POST)
    public void moveActionItem(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            JSONObject postBody = this.getPostedObject(ar);
            String fromCombo = postBody.getString("from");
            String goalId = postBody.getString("id");

            Cognoscenti cog = ar.getCogInstance();
            NGWorkspace thisWS = cog.getWSBySiteAndKeyOrFail( siteId, pageId ).getWorkspace();
            NGWorkspace fromWS = cog.getWSByCombinedKeyOrFail( fromCombo ).getWorkspace();

            ar.setPageAccessLevels(thisWS);
            ar.assertMember("You must be the member of the workspace you are copying to");
            ar.setPageAccessLevels(fromWS);
            ar.assertMember("You must be the member of the workspace you are copying from");

            GoalRecord oldGoal = fromWS.getGoalOrNull(goalId);
            if (oldGoal==null) {
                throw new Exception("Unable to find a action item with id="+goalId);
            }

            JSONObject goalJSON = oldGoal.getJSON4Goal(fromWS);
            String synopsis = oldGoal.getSynopsis();

            GoalRecord newCopy = thisWS.findGoalBySynopsis(synopsis);
            if (newCopy == null) {
                newCopy = thisWS.createGoal(ar.getBestUserId());
                newCopy.setSynopsis(synopsis);
            }
            goalJSON.put("id", newCopy.getId());
            goalJSON.put("universalid", newCopy.getUniversalId());
            newCopy.updateGoalFromJSON(goalJSON, thisWS, ar);
            newCopy.setScalar("taskArea", null);

            //get rid of the old copy
            oldGoal.setState(GoalRecord.STATE_SKIPPED);
            oldGoal.setDescription("This task was moved to another workspace: "+thisWS.getFullName());
            fromWS.saveContent(ar, "Action Item moved to another workspace: "+thisWS.getFullName());

            JSONObject repo = new JSONObject();
            repo.put("created", newCopy.getJSON4Goal(thisWS));

            thisWS.saveFile(ar, "Action Item '"+synopsis+"' copied from workspace: "+fromWS.getFullName());

            sendJson(ar, repo);
        }catch(Exception ex){
            Exception ee = new Exception("Unable to move the action item", ex);
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
    
    private static void addMembersInContacts(AuthRequest ar,
            List<AddressListEntry> contactList) throws Exception {
        UserPage up = ar.getUserPage();
        if (contactList != null) {
            NGRole role = up.getContactsRole();
            for (AddressListEntry ale : contactList) {
                role.addPlayerIfNotPresent(ale);
            }
            up.saveFile(ar, "Added contacts");
        }
    }

    private static void updateUserContactAndSaveUserPage(AuthRequest ar,
            String op, String emailIds) throws Exception {
        UserPage up = ar.getUserPage();
        if (emailIds.length() > 0) {
            if (op.equals("Remove")) {
                NGRole role = up.getContactsRole();
                AddressListEntry ale = AddressListEntry
                        .newEntryFromStorage(emailIds);
                role.removePlayer(ale);
                up.saveFile(ar, "removed user " + emailIds + " from role "
                        + role.getName());
            } else if (op.equals("Add")) {

                List<AddressListEntry> contactList = AddressListEntry
                        .parseEmailList(emailIds);
                addMembersInContacts(ar, contactList);
            }
        }
    }
}