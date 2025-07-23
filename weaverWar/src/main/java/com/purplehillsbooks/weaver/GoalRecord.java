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

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.List;
import java.util.TimeZone;

import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.weaver.mail.ChunkTemplate;
import com.purplehillsbooks.weaver.mail.EmailSender;
import com.purplehillsbooks.weaver.mail.MailInst;
import com.purplehillsbooks.weaver.mail.OptOutAddr;
import com.purplehillsbooks.weaver.mail.ScheduledNotification;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.MemFile;

public class GoalRecord extends BaseRecord {
    public GoalRecord(Document definingDoc, Element definingElement, DOMFace p)
            throws Exception {
        super(definingDoc, definingElement, p);

        // migrate old documents
        accessLicense();

    }


    /**
     * Get a NGRole that represents the assignees of the action item. a role is a list
     * of users. Using the role you can test whether a user is playing the role
     * or not, as well as add and remove people from the role.
     */
    public NGRole getAssigneeRole() {
        return new RoleGoalAssignee(this);
    }

    public void setCreator(String newVal) throws Exception {
        if (newVal==null || newVal.length()==0) {
            throw WeaverException.newBasic("Why is the creator being set to null string?");
        }
        setScalar("creator", newVal);
    }

    public String getCreator() throws Exception {
        return UserManager.getCorrectedEmail(getScalar("creator"));
    }

    // The display link is determined FROM the Sub URL, by retrieving the
    // UML from the Sub URL location, and pulling the display URL out.
    // This is a read-only value, since this value is determined by the
    // the remote 'leaf' and can not be set or updated here, so there is
    // no setter.
    public String getDisplayLink() throws Exception {
        // at the current time we use a short-cut, and assume that the
        // display URL is the same as the process url, but with "process.xml"
        // replaced by "public.htm"
        String sub = getSub();
        if (sub.endsWith("process.xml")) {
            return sub.substring(0, sub.length() - 11) + "FrontPage.htm";
        }
        if (sub.endsWith("process.wfxml")) {
            return sub.substring(0, sub.length() - 13) + "FrontPage.htm";
        }

        // now for "Task0000.wfxml"
        if (sub.endsWith(".wfxml")) {
            return sub.substring(0, sub.length() - 14) + "FrontPage.htm";
        }
        return sub;
    }

    public void setStateAndAct(int newVal, AuthRequest ar) throws Exception {
        int prevState = getState();
        if (newVal==prevState) {
            //ignore any non-change call
            return;
        }

        //set the start and end dates if appropriate, and if not already
        //set.  Leave them alone if already set to something.
        if (isFinal(newVal)) {
            long end = getEndDate();
            if (end<=0) {
                setEndDate(ar.nowTime);
            }
            long begin = getStartDate();
            if (begin<=0) {
                setStartDate(ar.nowTime);
            }
            setPercentComplete(100);

            //if it was not final before, and now it is final, then notify
            if (!isFinal(prevState)) {
                setSendEmail();
            }
        }
        else if (isStarted(newVal)) {
            long begin = getStartDate();
            if (begin<=0) {
                setStartDate(ar.nowTime);
            }
            //since it is NOT final, clear the end date
            setEndDate(0);
            //if it was not final before, and now it is final, then notify
            if (!isStarted(prevState)) {
                setSendEmail();
            }
        }
        else {
            //neither started nor final, so clear both dates
            setStartDate(0);
            setEndDate(0);
            setPercentComplete(0);
            if (isStarted(prevState) || isFinal(prevState)) {
                setSendEmail();
            }
        }
        setState(newVal);
    }

    protected void handleStateChangeEvent() throws Exception {

        NGWorkspace ngw = getWorkspace();
        if (ngw == null) {
            throw WeaverException.newBasic(
                    "handleStateChangeEvent needs a NGWorkspace parameter");
        }

        List<GoalRecord> goalList = ngw.getAllGoals();
        if (goalList == null || goalList.size() == 0) {
            throw WeaverException.newBasic(
                    "Unable to find any action items on the workspace : " + ngw.getKey());
        }

        int state = getState();

        // for regular task.
        if (state != BaseRecord.STATE_COMPLETE
                && state != BaseRecord.STATE_SKIPPED
                && state != BaseRecord.STATE_WAITING) {
            // all other states should be ignored.
            return;
        }

        // Is a subtask.
        if (hasParentGoal()) {
            handleSubTaskStateChangeEvent(ngw);
        }

        // complete all the sub tasks.
        if (hasSubGoals()) {
            completeAllSubTasks();
        }

        // start the next task in the process.
        startTheNextTask(goalList);

        // update the state of the process.
        ProcessRecord process = ngw.getProcess();
        process.updateStatusFromGoals(goalList);
    }

    public int getRank() throws Exception {
        String rank = getScalar("rank");
        return safeConvertInt(rank);
    }

    public void setRank(int newVal) throws Exception {
        setScalar("rank", Integer.toString(newVal));
    }

    public String getStatus() throws Exception {
        return getScalar("status");
    }

    public void setStatus(String newVal) throws Exception {
        setScalar("status", newVal);
    }

    public String getParentGoalId() throws Exception {
        return getAttribute("parenttask");
    }

    public void setParentGoal(String ptid) throws Exception {
        setAttribute("parenttask", ptid);
    }

    private boolean hasParentGoal() throws Exception {
        if (!fEle.hasAttribute("parenttask")) {
            return false;
        }

        String ptid = fEle.getAttribute("parenttask");
        if (ptid == null || ptid.trim().length() == 0) {
            return false;
        }

        return true;
    }

    @Override
    public void setDueDate(long newVal) throws Exception {
        super.setDueDate(newVal);
        // set the due date accordingly for all the subtasks.
        for (GoalRecord goal : getSubGoals()) {
            // due date not set
            if (goal.getDueDate() == 0) {
                goal.setDueDate(newVal);
            }
        }
    }



    public String getFreePass() throws Exception {
        return getScalar("freepass");
    }

    public void setFreePass(String licenceid) throws Exception {
        setScalar("freepass", licenceid);
    }

    /**
     * A user is allowed to specify what percentage that the task is complete.
     * This is rolled up into the values of the parent tasks
     */
    public int getPercentComplete() throws Exception {
        String stateVal = getScalar("percent");
        return safeConvertInt(stateVal);
    }


    /**
     * A user is allowed to specify what percentage that the task is complete.
     * The value must be 0 at the lowest, and 100 at the highest.
     */
    public void setPercentComplete(int newVal) throws Exception {
        if (newVal < 0 || newVal > 100) {
            throw WeaverException.newBasic(
                    "Percent complete value must be between 0% and 100%, instead received "
                            + newVal + "%");
        }
        setScalar("percent", Integer.toString(newVal));
    }

    /**
     * Given a user profile, this will check to see if this task is assigned to
     * ANY of that user's current ids. Tasks can be assigned to openids and to
     * email addresses, and this will find both cases. In the future we
     * anticipate multiple openids and multiple email addresses and this
     * patterns will handle that when it occurs.
     */
    public boolean isAssignee(UserRef user) throws Exception {
        NGRole ass = getAssigneeRole();
        return ass.isPlayer(user);
    }

    public boolean hasSubGoals() throws Exception {
        String myId = getId();
        for (GoalRecord gr : getWorkspace().getAllGoals()) {
            if (myId.equalsIgnoreCase(gr.getParentGoalId())) {
                return true;
            }
        }
        return false;
    }

    public List<GoalRecord> getSubGoals() throws Exception {
        List<GoalRecord> grlist = getWorkspace().getAllGoals();
        List<GoalRecord> subTasksVect = new ArrayList<GoalRecord>();
        String myId = getId();

        for (GoalRecord gr : grlist) {
            if (myId.equalsIgnoreCase(gr.getParentGoalId())) {
                subTasksVect.add(gr);
            }
        }

        sortTasksByRank(subTasksVect);
        return subTasksVect;
    }

    public static void sortTasksByRank(List<GoalRecord> tasks) {
        Collections.sort(tasks, new TaskRankComparator());
    }

    public void writeUserLinks(AuthRequest ar) throws Exception {
        List<String> assignees = getAssigneeList();
        writeLinks(ar, assignees);
    }

    private void writeLinks(AuthRequest ar, List<String> assignees)
            throws Exception {
        if (assignees == null || assignees.size() == 0) {
            // nobody is assigned to this task
            return;
        }
        boolean needsComma = false;
        for (String assignee : assignees) {
            if (needsComma) {
                ar.write(", ");
            }
            AddressListEntry ale = AddressListEntry.findOrCreate(assignee);
            ale.writeLink(ar);
            needsComma = true;
        }
    }

    public List<HistoryRecord> getTaskHistory(NGWorkspace ngc) throws Exception {
        List<HistoryRecord> list = new ArrayList<HistoryRecord>();
        String myid = getId();
        for (HistoryRecord history : ngc.getAllHistory()) {
            if (history.getContextType() == HistoryRecord.CONTEXT_TYPE_TASK) {
                if (myid.equals(history.getContext())) {
                    list.add(history);
                }
            }
        }
        return list;
    }

    public List<HistoryRecord> getTaskHistoryRange(NGWorkspace ngc,
            long startTime, long endTime) throws Exception {
        List<HistoryRecord> list = new ArrayList<HistoryRecord>();
        String myid = getId();
        for (HistoryRecord history : ngc.getAllHistory()) {
            if (history.getContextType() == HistoryRecord.CONTEXT_TYPE_TASK) {
                if (myid.equals(history.getContext())) {
                    long timeStamp = history.getTimeStamp();
                    if (timeStamp >= startTime && timeStamp < endTime) {
                        list.add(history);
                    }
                }
            }
        }
        return list;
    }

    static class TaskRankComparator implements Comparator<GoalRecord> {
        public TaskRankComparator() {
        }

        @Override
        public int compare(GoalRecord o1, GoalRecord o2) {
            try {
                int rank1 = o1.getRank();
                int rank2 = o2.getRank();
                if (rank1 == rank2) {
                    return 0;
                }
                if (rank1 < rank2) {
                    return -1;
                }
                return 1;
            } catch (Exception e) {
                return 0;
            }
        }
    }

    /**
     * get the id of the task in the other workspace that this task was moved to.
     */
    public String getMovedToTaskId() throws Exception {
        return getScalar("MovedToId");
    }

    public String getSub() throws Exception {
        return getScalar("sub");
    }

    public void setSub(String newVal) throws Exception {
        setScalar("sub", newVal);
    }

    
    public List<String> getAssigneeList() {
        String rawList = getScalar("assignee");
        if (rawList==null || rawList.length()==0) {
            return new ArrayList<String>();
        }
        return UtilityMethods.splitString(rawList, ',');
    }
    
    
    
    public void setAssigneeList(List<String> newList) {
        setScalar("assignee", UtilityMethods.joinStrings(newList));        
    }
    public void clearAssigneeList() {
        setScalar("assignee", null);
    }

    

    public String getModifiedBy() {
        return getAttribute("modifiedBy");
    }

    public void setModifiedBy(String modifiedBy) {
        setAttribute("modifiedBy", modifiedBy);
    }

    public long getModifiedDate() {
        return safeConvertLong(getAttribute("modifiedDate"));
    }

    public void setModifiedDate(long modifiedDate) {
        setAttribute("modifiedDate", Long.toString(modifiedDate));
    }

    // /////////////// DEPRECATED METHODS ////////////////////

    private NGWorkspace getWorkspace() {
        return ((NGSection) getParent()).parent;
    }

    /**
     * use setLastState instead
     */
    public void setLastState(String newVal) throws Exception {
        setScalar("LastState", newVal);
    }

    /**
     * use getLastState instead
     */
    public String getLastState() throws Exception {
        return getScalar("LastState");
    }

    /**
     * the universal id is a globally unique ID for this action item, composed of the
     * id for the server, the workspace, and the action item. This is set at the point
     * where the action item is created and remains with the note as it is carried
     * around the system as long as it is moved as a clone from a workspace to a
     * clone of a workspace. If it is copied or moved to another workspace for any
     * other reason, then the universal ID should be reset.
     */
    public String getUniversalId() throws Exception {
        return getScalar("universalid");
    }

    public void setUniversalId(String newID) throws Exception {
        setScalar("universalid", newID);
    }

    private void handleSubTaskStateChangeEvent(NGWorkspace ngw) throws Exception {
        if (hasParentGoal() == false) {
            return;
        }

        GoalRecord parentTask = ngw.getGoalOrNull(getParentGoalId());
        int state = getState();

        if (state == BaseRecord.STATE_COMPLETE
                || state == BaseRecord.STATE_SKIPPED) {
            boolean completeParentTask = true;
            // change the state of the parent task to completed state if there
            // no pending activities for that parent task.
            List<GoalRecord> subTasks = parentTask.getSubGoals();
            for (GoalRecord subTask : subTasks) {
                if (subTask.getState() != BaseRecord.STATE_COMPLETE
                        && subTask.getState() != BaseRecord.STATE_SKIPPED) {
                    completeParentTask = false;
                    break;
                }
            }
            if (completeParentTask) {
                parentTask.setState(BaseRecord.STATE_COMPLETE);
                parentTask.setPercentComplete(100);
            }
        } else if (state == BaseRecord.STATE_SKIPPED) {
            // check and change the state to avoid the event to firing.
            if (parentTask.getState() != BaseRecord.STATE_WAITING) {
                parentTask.setState(BaseRecord.STATE_WAITING);
            }
        }
    }

    public void startTheNextTask(List<GoalRecord> tasks) throws Exception {
        if (tasks == null || tasks.size() == 0) {
            return;
        }

        GoalRecord.sortTasksByRank(tasks);

        // cant start the next step when the current task in not skipped//
        // completed.
        if (getState() != BaseRecord.STATE_COMPLETE
                && getState() != BaseRecord.STATE_SKIPPED) {
            return;
        }

        String currentId = getId();
        boolean found = false;
        for (GoalRecord task : tasks) {
            if (!found) {
                if (currentId.equals(task.getId())) {
                    found = true;
                }
                // otherwise ignore tasks before and up to the current task
                continue;
            }

            int state = task.getState();

            if (state == BaseRecord.STATE_OFFERED
                    || state == BaseRecord.STATE_ACCEPTED
                    || state == BaseRecord.STATE_WAITING) {
                // stop looking since the next task is started/active/waiting.
                break;
            }

            if (state == BaseRecord.STATE_ERROR
                    || state == BaseRecord.STATE_COMPLETE
                    || state == BaseRecord.STATE_SKIPPED) {
                // continue looping to next task.
                continue;
            }

            if (state == BaseRecord.STATE_UNSTARTED) {
                task.setState(BaseRecord.STATE_OFFERED);
                // done and so break.
                break;
            }
        }
    }

    public void completeAllSubTasks() throws Exception {
        int state = getState();

        if (state == BaseRecord.STATE_COMPLETE
                || state == BaseRecord.STATE_SKIPPED) {
            List<GoalRecord> subTasks = getSubGoals();
            // change the state of the existing incomplete tasks based on main
            // task state.
            for (GoalRecord subTask : subTasks) {
                int tstate = subTask.getState();

                if (tstate == BaseRecord.STATE_ACCEPTED
                        || tstate == BaseRecord.STATE_ERROR
                        || tstate == BaseRecord.STATE_WAITING) {
                    subTask.setState(BaseRecord.STATE_COMPLETE);
                    subTask.setPercentComplete(100);
                } else if (tstate == BaseRecord.STATE_UNSTARTED
                        || tstate == BaseRecord.STATE_OFFERED) {
                    subTask.setState(BaseRecord.STATE_SKIPPED);
                }
            }
        }
    }

    public boolean hasSubProcess() throws Exception {
        String sub = getSub();
        return (sub != null && sub.length() > 0);
    }

    /**
     * This value, if set, is the GMT time that the wait period is scheduled
     * to end.  If the action item is discovered in wait mode after this time, then
     * it should be reset to active mode.  A setting of zero or negative
     * indicates that this wakup is disabled.
     */
    public void setWaitEnd(long timeout) {
        setScalar("waitEnd", Long.toString(timeout));
    }
    public long getWaitEnd() {
        return safeConvertLong(getScalar("waitEnd"));
    }

    /**
     * WaitPeriod is an expression that specifies what the normal wait
     * delay will be: day(1), week(1), month(1) or something like that.
     * An empty string (or null) indicates that there is no specified
     * normal waiting period.
     */
    public void setWaitPeriod(String period) {
        setScalar("waitPeriod", period);
    }
    public String getWaitPeriod() {
        return getScalar("waitPeriod");
    }

    /**
     * Passive is a setting that says that the action item was not defined
     * in this particular replicant of the workspace, and so it should
     * only display the status, and not allow any means to change
     * the state.
     *
     * Default (if the setting has not been set) is false.
     */
    public void setPassive(boolean isPassive) {
        if (isPassive) {
            setAttribute("passive", "true");
        }
        else {
            setAttribute("passive", null);
        }
    }
    public boolean isPassive() {
        String pVal = getAttribute("passive");
        if (pVal==null) {
            return false;
        }
        return "true".equals(pVal);
    }

    /**
     * RemoteUpdateURL is a URL that is provided during synchronization
     * for passive tasks that provides a place to redirect to in order
     * to allow the user to manipulate the state of the task on the
     * original site.
     */
    public void setRemoteUpdateURL(String url) {
        setScalar("remoteUpdateURL", url);
    }
    public String getRemoteUpdateURL() {
        return getScalar("remoteUpdateURL");
    }

    /**
     * RemoteProjectName is the name of the
     * project that this action item is defined in
     */
    public void setRemoteProjectName(String url) {
        setScalar("remoteProjectName", url);
    }
    public String getRemoteProjectName() {
        return getScalar("remoteProjectName");
    }

    /**
     * RemoteSiteURL is the URL to get information about the
     * site that this action item is defined in
     */
    public void setRemoteSiteURL(String url) {
        setScalar("remoteSiteURL", url);
    }
    public String getRemoteSiteURL() {
        return getScalar("remoteSiteURL");
    }

    /**
     * RemoteSiteName is the name of the
     * site that this action item is defined in
     */
    public void setRemoteSiteName(String url) {
        setScalar("remoteSiteName", url);
    }
    public String getRemoteSiteName() {
        return getScalar("remoteSiteName");
    }

    /**
     * SnoozeTime is the time, in the future, to wake the
     * task back up out of WAITING state, and into active
     * state.  This is NOT a duration.   Instead it is an
     * absolute time that the activity will wake up.
     * Any time in the past is the same as not being set.
     */
    public void setSnoozeTime(long time) {
        setScalar("snooze", Long.toString(time));
    }
    public long getSnoozeTime() {
        return safeConvertLong(getScalar("snooze"));
    }

    /**
     * How is the action item proceeding and is it likely
     * to be completed on time.
     * The values are "good", "ok", "bad"
     */
    public void setProspects(String pros) {
        setScalar("prospects", pros);
    }
    public String getProspects() {
        return getScalar("prospects");
    }
    public String getTaskArea() {
        return getScalar("taskArea");
    }

    /**
     * get the labels on a document -- only labels valid in the project,
     * and no duplicates
     */
    public List<NGLabel> getLabels(NGWorkspace ngw) throws Exception {
        List<NGLabel> res = new ArrayList<NGLabel>();
        for (String name : getVector("labels")) {
            NGLabel aLabel = ngw.getLabelRecordOrNull(name);
            if (aLabel!=null) {
                if (!res.contains(aLabel)) {
                    res.add(aLabel);
                }
            }
        }
        return res;
    }

    /**
     * set the list of labels on a document
     */
    public void setLabels(List<NGLabel> values) throws Exception {
        List<String> labelNames = new ArrayList<String>();
        for (NGLabel aLable : values) {
            labelNames.add(aLable.getName());
        }
        //Since this is a 'set' type vector, always sort them so that they are
        //stored in a consistent way ... so files are more easily compared
        Collections.sort(labelNames);
        setVector("labels", labelNames);
    }

    /**
     * Documents that are linked to this action item
     * This is an array of string, each string value is
     * a universalid of a document
     */
    public void setDocLinks(List<String> newVal) {
        setVector("docLinks", newVal);
    }
    public List<String> getDocLinks() {
        return getVector("docLinks");
    }


    /**
     * This is a version that can be included in lists of action items,
     * such as those linked to an agenda item.
     */
    public JSONObject getMinimalJSON() throws Exception {
        JSONObject oneAI = new JSONObject();
        oneAI.put("synopsis", this.getSynopsis());
        oneAI.put("id", this.getId());
        oneAI.put("state", this.getState());
        oneAI.put("universalid", getUniversalId());
        return oneAI;
    }

    public JSONObject getJSON4Goal(NGWorkspace ngw) throws Exception {
        JSONObject thisGoal = getMinimalJSON();
        thisGoal.put("description", getDescription());
        thisGoal.put("modifiedtime", getModifiedDate());
        thisGoal.put("modifieduser", getModifiedBy());
        thisGoal.put("status",    getStatus());
        thisGoal.put("priority",  getPriority());
        thisGoal.put("duedate",   getDueDate());
        thisGoal.put("startdate", getStartDate());
        thisGoal.put("enddate",   getEndDate());
        thisGoal.put("duration",  getDuration());
        thisGoal.put("rank",      getRank());
        thisGoal.put("prospects", getProspects());
        thisGoal.put("needEmail", needSendEmail());
        extractScalarString(thisGoal, "taskArea");

        thisGoal.put("projectname", ngw.getFullName());
        thisGoal.put("projectKey", ngw.getKey());

        NGRole assignees = getAssigneeRole();
        JSONArray peopleList = new JSONArray();
        JSONArray assignTo = new JSONArray();
        for (AddressListEntry ale : assignees.getExpandedPlayers(ngw)) {
            peopleList.put(ale.getUniversalId());
            assignTo.put(ale.getJSON());
        }
        thisGoal.put("assignees", peopleList);
        thisGoal.put("assignTo", assignTo);

        JSONArray creatorArray = new JSONArray();
        creatorArray.put(getCreator());
        thisGoal.put("requesters", creatorArray);

        NGBook site = ngw.getSite();
        thisGoal.put("sitename", site.getFullName());
        thisGoal.put("siteKey", site.getKey());

        JSONObject labelMap = new JSONObject();
        for (NGLabel lRec : getLabels(ngw) ) {
            labelMap.put(lRec.getName(), true);
        }
        thisGoal.put("labelMap",  labelMap);
        thisGoal.put("docLinks",  constructJSONArray(getDocLinks()));

        extractScalarString(thisGoal, "checklist");
        extractAttributeLong(thisGoal, "waitUntil");
        extractVectorString(thisGoal, "waitFor");

        return thisGoal;
    }
    public JSONObject getJSON4Goal(NGWorkspace ngw, String baseURL, License license) throws Exception {
        if (license==null) {
            throw WeaverException.newBasic("getJSON4Goal needs a license object");
        }
        JSONObject thisGoal = getJSON4Goal(ngw);
        LicenseForUser lfu = LicenseForUser.getUserLicense(license);
        String siteRoot = baseURL + "api/" + ngw.getSiteKey() + "/$/?lic=" + lfu.getId();
        String uiUrl = getRemoteUpdateURL();
        if (uiUrl==null || uiUrl.length()==0) {
            uiUrl = baseURL + "t/" + ngw.getSiteKey() + "/" + ngw.getKey()
                + "/task" + getId() + ".htm";
        }
        thisGoal.put("ui", uiUrl);
        thisGoal.put("siteinfo", siteRoot);
        return thisGoal;
    }

    //TODO: looks like this can be used to update a JSON from the UI
    public void updateGoalFromJSON(JSONObject goalObj, NGWorkspace ngw, AuthRequest ar) throws Exception {
        String universalid = goalObj.getString("universalid");
        if (!universalid.equals(getUniversalId())) {
            //just checking, this should never happen
            throw WeaverException.newBasic("Error trying to update the record for a action item with UID ("
                    +getUniversalId()+") with post from action item with UID ("+universalid+")");
        }
        if (goalObj.has("synopsis")) {
            setSynopsis(goalObj.optString("synopsis"));
        }
        if (goalObj.has("description")) {
            setDescription(goalObj.optString("description"));
        }
        if (goalObj.has("modifiedtime")) {
            setModifiedDate(goalObj.optLong("modifiedtime"));
        }
        if (goalObj.has("modifieduser")) {
            setModifiedBy(goalObj.getString("modifieduser"));
        }
        if (goalObj.has("priority")) {
            setPriority(goalObj.getInt("priority"));
        }
        if (goalObj.has("duedate")) {
            setDueDate(goalObj.getLong("duedate"));
        }
        if (goalObj.has("startdate")) {
            setStartDate(goalObj.getLong("startdate"));
        }
        if (goalObj.has("enddate")) {
            setEndDate(goalObj.getLong("enddate"));
        }
        if (goalObj.has("state")) {
            setStateAndAct(goalObj.optInt("state"), ar);
        }
        if (goalObj.has("status")) {
            setStatus(goalObj.getString("status"));
        }
        if (goalObj.has("duration")) {
            setDuration(goalObj.getLong("duration"));
        }
        if (goalObj.has("rank")) {
            setRank(goalObj.getInt("rank"));
        }
        if (goalObj.has("ui")) {
            setRemoteUpdateURL(goalObj.getString("ui"));
        }
        if (goalObj.has("projectname")) {
            setRemoteProjectName(goalObj.getString("projectname"));
        }
        if (goalObj.has("siteinfo")) {
            setRemoteSiteURL(goalObj.getString("siteinfo"));
        }
        if (goalObj.has("sitename")) {
            setRemoteSiteName(goalObj.getString("sitename"));
        }
        if (goalObj.has("prospects")) {
            setProspects(goalObj.getString("prospects"));
        }

        if (goalObj.has("assignTo")) {
            JSONArray peopleList = goalObj.getJSONArray("assignTo");
            NGRole assigneeRole = getAssigneeRole();
            int numPeopleBefore = assigneeRole.getDirectPlayers().size();
            assigneeRole.clear();
            int lastPerson = peopleList.length();
            for (int i=0; i<lastPerson; i++) {
                JSONObject person = peopleList.getJSONObject(i);
                if (!person.has("uid")) {
                    continue;  //ignore any entry without a UID
                }
                assigneeRole.addPlayer(AddressListEntry.fromJSON(person));
            }
            int numPeopleAfter = assigneeRole.getDirectPlayers().size();
            if (numPeopleBefore != numPeopleAfter) {
                //if the assignee number changes, send email in 5 minutes
                setSendEmail();
            }
        }
        else if (goalObj.has("assignee")) {
            throw WeaverException.newBasic("Potential problem.... JSON has assignee but no assignTo field. Assignee is deprecated.");
        }

        if (goalObj.has("labelMap")) {
            JSONObject labelMap = goalObj.getJSONObject("labelMap");
            List<NGLabel> selectedLabels = new ArrayList<NGLabel>();
            for (NGLabel stdLabel : ngw.getAllLabels()) {
                String labelName = stdLabel.getName();
                if (labelMap.optBoolean(labelName)) {
                    selectedLabels.add(stdLabel);
                }
            }
            setLabels(selectedLabels);
        }
        if (goalObj.has("docLinks")) {
            setDocLinks(constructVector(goalObj.getJSONArray("docLinks")));
        }
        updateScalarString( "taskArea",  goalObj);
        updateScalarString( "checklist", goalObj);
        updateAttributeLong("waitUntil", goalObj);
        updateVectorString( "waitFor",   goalObj);
    }

    //This used to be a time scheduled to send the email, but it was only lbeing used
    //as a boolean, so now the API is a boolean.
    public boolean needSendEmail()  throws Exception {
        return getAttributeLong("emailSendTime")>0;
    }
    public void setSendEmail() throws Exception {
        setAttributeLong("emailSendTime", System.currentTimeMillis());
    }
    public void clearSendEmail() throws Exception {
        setAttributeLong("emailSendTime", 0);
    }
    public long getEmailSendTime() throws Exception {
        return getAttributeLong("emailSendTime");
    }



    ////////////////////////// EMAIL /////////////////////////////

    public void goalEmailRecord(AuthRequest ar, NGWorkspace ngw, EmailSender mailFile) throws Exception {
        try {
            if (!needSendEmail()) {
                throw WeaverException.newBasic("Program Logic Error: attempt to send email on action item when no schedule for sending is set");
            }
            boolean isStarted = isStarted(getState());

            NGRole assigneeRole = getAssigneeRole();
            List<AddressListEntry> players = assigneeRole.getExpandedPlayers(ngw);
            if (players.size()==0 && !isStarted) {
                System.out.println("no assignee yet, and not started .... so wait");
                clearSendEmail();
                return;
            }

            //add the creator to recipients
            String creator = this.getCreator();
            UserProfile creatorProfile = null;
            if (creator==null || creator.length()==0) {
                //if action item not set correctly, then use the owner of the page as the 'from' person
                NGRole owners = ngw.getSecondaryRole();
                List<AddressListEntry> ownerList = owners.getExpandedPlayers(ngw);
                if (ownerList.size()==0) {
                    throw WeaverException.newBasic("Action Item has no requester, and the Workspace has no owner");
                }
                creatorProfile = ownerList.get(0).getUserProfile();
            }
            else {
                AddressListEntry commenter = AddressListEntry.findOrCreate(creator);
                creatorProfile = commenter.getUserProfile();
            }


            //add the creator to recipients
            boolean found = false;
            for (AddressListEntry ale : players) {
                if (ale.hasAnyId(creator)) {
                    found = true;
                }
            }
            if (!found) {
                players.add(AddressListEntry.findOrCreate(creator));
            }

            List<OptOutAddr> sendTo = new ArrayList<OptOutAddr>();
            OptOutAddr.appendUsers(players, sendTo);

            for (OptOutAddr ooa : sendTo) {
                UserManager.getStaticUserManager();
                UserProfile toProfile = UserManager.lookupUserByAnyId(ooa.getEmail());
                if (toProfile!=null) {
                    ar.getCogInstance().getUserCacheMgr().needRecalc(toProfile);
                }
                constructEmailRecordOneUser(ar, ngw, ooa, creatorProfile, mailFile);
            }
            System.out.println("Marking ActionItem as SENT: "+getSynopsis());
            clearSendEmail();
        }
        catch (Exception e) {
            throw WeaverException.newWrap("Unable to send email for Action Item: %s", e, getSynopsis());
        }
    }

    private void constructEmailRecordOneUser(AuthRequest ar, NGWorkspace ngw, OptOutAddr ooa,
            UserProfile requesterProfile, EmailSender mailFile) throws Exception  {
        if (!ooa.hasEmailAddress()) {
            return;  //ignore users without email addresses
        }

        //note that assignee means two different things in this next line
        boolean recipientIsAssignedTask = isAssignee(ooa.getAssignee());



        if (requesterProfile==null) {
            System.out.println("DATA PROBLEM: action item came from a person without a profile ("+getCreator()+") ignoring");
            return;
        }


        JSONObject data = new JSONObject();

        MemFile body = new MemFile();
        AuthRequest clone = new AuthDummy(requesterProfile, body.getWriter(), ar.getCogInstance());
        clone.retPath = ar.baseURL;

        data.put("baseURL", ar.baseURL);
        data.put("actionItemURL", ar.baseURL + clone.getResourceURL(ngw, "task"+getId()+".htm"));
        if (ooa.isUserWithProfile()) {
            UserProfile recipient = ooa.getAssignee().getUserProfile();
            LicenseForUser lfu = new LicenseForUser(recipient);
            data.put("actionItem", this.getJSON4Goal(ngw, ar.baseURL, lfu));
        }
        else {
            data.put("actionItem", this.getJSON4Goal(ngw));
        }
        data.put("wsBaseURL", ar.baseURL + clone.getWorkspaceBaseURL(ngw));
        data.put("wsName", ngw.getFullName());
        data.put("isFinal", isFinal(getState()));
        data.put("isFuture", isFuture(getState()));
        data.put("recipientIsAssignedTask", recipientIsAssignedTask);
        data.put("requesterURL", ar.baseURL);
        data.put("stateName", stateName(getState()));
        data.put("optout", ooa.getUnsubscribeJSON(clone));

        ChunkTemplate.streamAuthRequest(clone.w, ar, "ActionItem", data, ooa.getCalendar());
        clone.flush();

        String stateNameStr = stateName(getState());
        String overdueStr = "";
        if (!BaseRecord.isFinal(getState()) && this.getDueDate()<ar.nowTime && this.getDueDate()>0) {
            //if it is not finished and past due date, then say that
            overdueStr = " Overdue!";
        }

        ArrayList<File> attachments = new ArrayList<File>();
        if (this.getDueDate()>0) {
            File weFolder = ngw.getContainingFolder();
            File cogFolder = new File(weFolder, ".cog");
            File icsFile = new File(cogFolder, "actitem"+this.getId()+".ics");
            File icsFileTmp = new File(cogFolder, "meet"+this.getId()+".ics~tmp"+System.currentTimeMillis());
            FileOutputStream fos = new FileOutputStream(icsFileTmp);
            Writer w = new OutputStreamWriter(fos, "UTF-8");
            streamICSFile(ar, w, ngw);
            w.close();
            if (icsFile.exists()) {
                icsFile.delete();
            }
            icsFileTmp.renameTo(icsFile);
            attachments.add(icsFile);
        }
        
        MailInst mailMsg = ngw.createMailInst();
        mailMsg.setSubject("Action Item: "+getSynopsis()+" ("+stateNameStr+") "+overdueStr);
        mailMsg.setBodyText(body.toString());

        mailFile.createEmailRecordInDB(mailMsg, requesterProfile.getAddressListEntry(), ooa.getEmail());
    }

    public void streamICSFile(AuthRequest ar, Writer w, NGWorkspace ngw) throws Exception {
        UserProfile creatorUser = UserManager.lookupUserByAnyId(getCreator());
        w.write("BEGIN:VCALENDAR\n");
        w.write("VERSION:2.0\n");
        w.write("PRODID:-//example/Weaver//NONSGML v1.0//EN\n");
        w.write("BEGIN:VEVENT\n");
        w.write("UID:"+ngw.getSiteKey()+ngw.getKey()+getId()+"\n");
        w.write("DTSTAMP:"+getSpecialICSFormat(System.currentTimeMillis())+"\n");
        if (creatorUser!=null) {
            w.write("ORGANIZER:CN="+creatorUser.getName()+":MAILTO:"+creatorUser.getAddressListEntry().getEmail()+"\n");
        }
        w.write("DTSTART:"+getSpecialICSFormat(getDueDate())+"\n");
        w.write("DTEND:"+getSpecialICSFormat(getDueDate()+(30*60*1000))+"\n");
        w.write("SUMMARY:"+getSynopsis()+"\n");
        w.write("DESCRIPTION:"+specialEncode(this.getSynopsis()+"-"+this.getDescription())+"\n");
        w.write("END:VEVENT\n");
        w.write("END:VCALENDAR\n");
        w.flush();
    }
    private String getSpecialICSFormat(long date) {
        SimpleDateFormat formatter = new SimpleDateFormat("yyyyMMdd'T'HHmmss'Z'");
        formatter.setTimeZone(TimeZone.getTimeZone("UTC"));
        return formatter.format(new Date(date));
    }
    private String specialEncode(String input) {
        StringBuilder sb = new StringBuilder();
        for (int i=0; i<input.length(); i++) {
            char ch = input.charAt(i);
            if (ch=='\n') {
                sb.append("\\n");
            }
            else if (ch<' ') {
                //do nothing
            }
            else {
                sb.append(ch);
            }
        }
        return sb.toString();
    }

    public void gatherUnsentScheduledNotification(NGWorkspace ngw,
            ArrayList<ScheduledNotification> resList, long timeout) throws Exception {
        //don't send email if there is no assignee.  Wait till there is an assignee
        if (needSendEmail()) {
            resList.add(new GScheduledNotification(ngw, this));
        }
    }
    public String getAllSearchableText() throws Exception  {
        return this.getSynopsis() + "\n" + this.getDescription();
    }

    private class GScheduledNotification implements ScheduledNotification {
        private NGWorkspace ngw;
        private GoalRecord goal;

        public GScheduledNotification( NGWorkspace _ngp, GoalRecord _goal) {
            ngw  = _ngp;
            goal = _goal;
        }
        @Override
        public boolean needsSendingBefore(long timeout) throws Exception {
            if (!goal.needSendEmail()) {
                return false;
            }
            if (getEmailSendTime()>timeout) {
                return false;
            }
            return true;
        }
        @Override
        public long futureTimeToSend() throws Exception {
            if (!goal.needSendEmail()) {
                return -1;
            }
            return getEmailSendTime();
        }

        @Override
        public void sendIt(AuthRequest ar, EmailSender mailFile) throws Exception {
            goal.goalEmailRecord(ar, ngw, mailFile);
            if (goal.needSendEmail()) {
                System.out.println("ERROR: for some reason it did not get move to the mailFile?");
            }
        }

        @Override
        public String selfDescription() throws Exception {
            return "(ActionItem) "+getSynopsis();
        }
        
    }

}
