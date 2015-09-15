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

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Vector;

import org.socialbiz.cog.exception.ProgramLogicError;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;

public class GoalRecord extends BaseRecord {
    public GoalRecord(Document definingDoc, Element definingElement, DOMFace p)
            throws Exception {
        super(definingDoc, definingElement, p);

        // migrate old documents
        accessLicense();

        // fix up the creator if we can...
        // There had been a chronic problem of filling in the creator with the
        // 'name'
        // of the user, not a permanent ID. So this attempts to fix it up by
        // first
        // searching for the user, and then putting the universal id in instead.
        // However, me might not find the user.
        // Note that this also handles cases where a use changes their ID.
        String currentCreator = getCreator();
        if (currentCreator != null && currentCreator.length() > 0) {
            UserProfile creatorUser = UserManager
                    .findUserByAnyId(currentCreator);
            if (creatorUser != null) {
                String betterID = creatorUser.getUniversalId();
                if (!betterID.equals(currentCreator)) {
                    setCreator(betterID);
                }
            }
        }
    }

    /**
     * Make sure that all the important attributes are copied from another goal
     * object, but NOT the id. The ID remains unchanged.
     */
    public void copyFrom(GoalRecord other) throws Exception {
        setSynopsis(other.getSynopsis());
        setDescription(other.getDescription());
        setActionScripts(other.getActionScripts());
        setDueDate(other.getDueDate());
        setStartDate(other.getStartDate());
        setEndDate(other.getEndDate());
        setPriority(other.getPriority());
        setDuration(other.getDuration());
        setCreator(other.getCreator());
        setState(other.getState());
        setRank(other.getRank());
        setStatus(other.getStatus());
        setPercentComplete(other.getPercentComplete());
        setAssigneeCommaSeparatedList(other.getAssigneeCommaSeparatedList());
        setLastState(other.getLastState());
    }

    /**
     * Generates a fully qualified, licensed, Wf-XML link for this goal This is
     * the link someone else would use to get to this goal. AuthRequest is
     * needed to know the current server context path
     */
    public LicensedURL getWfxmlLink(AuthRequest ar) throws Exception {
        NGContainer ngp = ar.ngp;
        if (ngp == null) {
            throw new ProgramLogicError(
                    "the NGPage must be loaded into the AuthRequest for getWfxmlLink to work");
        }
        return new LicensedURL(ar.baseURL + "p/" + ngp.getKey()
                + "/s/Tasks/id/" + getId() + "/data.xml", ngp.getKey()
                + "_task" + getId(), accessLicense().getId());
    }

    /**
     * Get a NGRole that represents the assignees of the goal. a role is a list
     * of users. Using the role you can test whether a user is playing the role
     * or not, as well as add and remove people from the role.
     */
    public NGRole getAssigneeRole() {
        return new RoleGoalAssignee(this);
    }

    public void setCreator(String newVal) throws Exception {
        setScalar("creator", newVal);
    }

    public String getCreator() throws Exception {
        return getScalar("creator");
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
            return sub.substring(0, sub.length() - 11) + "notesList.htm";
        }
        if (sub.endsWith("process.wfxml")) {
            return sub.substring(0, sub.length() - 13) + "notesList.htm";
        }

        // now for "Task0000.wfxml"
        if (sub.endsWith(".wfxml")) {
            return sub.substring(0, sub.length() - 14) + "notesList.htm";
        }
        return sub;
    }

    public int getState() throws Exception {
        String stateVal = getScalar("state");
        return safeConvertInt(stateVal);
    }

    public void setState(int newVal) throws Exception {
        int prevState = getState();
        setScalar("state", Integer.toString(newVal));
        if (prevState != newVal) {
            handleStateChangeEvent(getProject());
        }
    }

    private void handleStateChangeEvent(NGPage ngp) throws Exception {

        if (ngp == null) {
            throw new ProgramLogicError(
                    "handleStateChangeEvent needs a NGPage parameter");
        }

        List<GoalRecord> goalList = ngp.getAllGoals();
        if (goalList == null || goalList.size() == 0) {
            throw new ProgramLogicError(
                    "Unable to find any goals on the project : " + ngp.getKey());
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
            handleSubTaskStateChangeEvent();
        }

        // complete all the sub tasks.
        if (hasSubGoals()) {
            completeAllSubTasks();
        }

        // start the next task in the process.
        startTheNextTask(goalList);

        // update the state of the process.
        ProcessRecord process = ngp.getProcess();
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

    public GoalRecord getParentGoal() throws Exception {
        String parentGoalId = getAttribute("parenttask");
        if (parentGoalId == null || parentGoalId.length() == 0) {
            return null;
        }
        return getProject().getGoalOrFail(parentGoalId);
    }

    public boolean hasParentGoal() throws Exception {
        if (!fEle.hasAttribute("parenttask")) {
            return false;
        }

        String ptid = fEle.getAttribute("parenttask");
        if (ptid == null || ptid.trim().length() == 0) {
            return false;
        }

        return true;
    }

    public void makeAsRegularGoal() throws Exception {
        // removing the parent goal attribute would make this task a regular
        // task
        // instead of subtask.
        fEle.removeAttribute("parenttask");
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

    /**
     * Constructs an XML representation of the task for WfXML purpose
     *
     * @param ngc
     *            is the container of the task if you want last modified user
     *            and time to be generated in the output.
     */
    public void fillInWfxmlActivity(Document doc, Element actEle,
            String processurl) throws Exception {
        String actkey = "act" + getId();
        String relaykey = "relay" + getId();
        String activityurl = "";
        String relayurl = "";
        int indx1 = processurl.indexOf("/process.xml");
        int indx2 = processurl.indexOf("/process.wfxml");
        if (indx1 > 0) {
            activityurl = processurl.substring(0, indx1) + "/" + actkey
                    + ".xml";
            relayurl = processurl.substring(0, indx1) + "/" + relaykey
                    + "/process.xml";
        } else if (indx2 > 0) {
            activityurl = processurl.substring(0, indx2) + "/" + actkey
                    + ".wfxml";
            relayurl = processurl.substring(0, indx1) + "/" + relaykey
                    + "/process.xml";
        } else {
            activityurl = actkey + ".xml";
        }

        if (doc == null || actEle == null) {
            return;
        }

        actEle.setAttribute("id", getId());
        DOMUtils.createChildElement(doc, actEle, "processurl", processurl);
        DOMUtils.createChildElement(doc, actEle, "key", activityurl);
        DOMUtils.createChildElement(doc, actEle, "display", "notesList.htm");
        DOMUtils.createChildElement(doc, actEle, "synopsis", getSynopsis());
        DOMUtils.createChildElement(doc, actEle, "description",
                getDescription());
        DOMUtils.createChildElement(doc, actEle, "state",
                Integer.toString(getState()));
        DOMUtils.createChildElement(doc, actEle, "assignee",
                getAssigneeCommaSeparatedList());
        UserProfile creatorUser = UserManager.findUserByAnyId(getCreator());
        if (creatorUser != null) {
            DOMUtils.createChildElement(doc, actEle, "creator",
                    creatorUser.getUniversalId());
        }
        Element subEle = DOMUtils.createChildElement(doc, actEle, "subprocess");
        String subKey = getSub();
        if (subKey != null && subKey.length() > 0) {
            DOMUtils.createChildElement(doc, subEle, "subkey", getSub());
            DOMUtils.createChildElement(doc, subEle, "relayurl", relayurl);
        }
        DOMUtils.createChildElement(doc, actEle, "actionscripts",
                this.getActionScripts());
        DOMUtils.createChildElement(doc, actEle, "progress", getStatus());
        DOMUtils.createChildElement(doc, actEle, "priority",
                String.valueOf(getPriority()));
        DOMUtils.createChildElement(doc, actEle, "duedate",
                UtilityMethods.getXMLDateFormat(getDueDate()));
        DOMUtils.createChildElement(doc, actEle, "startdate",
                UtilityMethods.getXMLDateFormat(getStartDate()));
        DOMUtils.createChildElement(doc, actEle, "duration",
                String.valueOf(getDuration()));
        DOMUtils.createChildElement(doc, actEle, "enddate",
                UtilityMethods.getXMLDateFormat(getEndDate()));
        DOMUtils.createChildElement(doc, actEle, "rank",
                String.valueOf(getRank()));

        // this added to enable synchronization of tasks
        DOMUtils.createChildElement(doc, actEle, "modifiedtime",
                UtilityMethods.getXMLDateFormat(getModifiedDate()));
        DOMUtils.createChildElement(doc, actEle, "modifieduser",
                getModifiedBy());
        String uid = getUniversalId();
        if (uid == null || uid.length() == 0) {
            throw new Exception("Task " + getId() + " has no universal ID ("
                    + getSynopsis() + ") -- nust have one!");
        }
        DOMUtils.createChildElement(doc, actEle, "universalid", uid);
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
     * User may never set the percent complete. This method forces the percetn
     * complete retrieved to be zero if the task has not been started, and 100
     * if it is completed, and it is the stored value for everything else.
     */
    public int getCorrectedPercentComplete() throws Exception {
        int state = getState();
        switch (state) {
        case STATE_UNSTARTED:
            return 0;
        case STATE_COMPLETE:
        case STATE_SKIPPED:
        case STATE_REVIEW:
            return 100;
        default:
            // do nothing, use stored value
        }
        return getPercentComplete();
    }

    /**
     * A user is allowed to specify what percentage that the task is complete.
     * The value must be 0 at the lowest, and 100 at the highest.
     */
    public void setPercentComplete(int newVal) throws Exception {
        if (newVal < 0 || newVal > 100) {
            throw new Exception(
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
        for (GoalRecord gr : getProject().getAllGoals()) {
            if (myId.equalsIgnoreCase(gr.getParentGoalId())) {
                return true;
            }
        }
        return false;
    }

    public List<GoalRecord> getSubGoals() throws Exception {
        List<GoalRecord> grlist = getProject().getAllGoals();
        Vector<GoalRecord> subTasksVect = new Vector<GoalRecord>();
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
        String[] assignees = UtilityMethods.splitOnDelimiter(
                getAssigneeCommaSeparatedList(), ',');
        writeLinks(ar, assignees);
    }

    private void writeLinks(AuthRequest ar, String[] assignees)
            throws Exception {
        if (assignees == null || assignees.length == 0) {
            // nobody is assigned to this task
            return;
        }
        boolean needsComma = false;
        for (String assignee : assignees) {
            if (needsComma) {
                ar.write(", ");
            }
            AddressListEntry ale = new AddressListEntry(assignee);
            ale.writeLink(ar);
            needsComma = true;
        }
    }

    public List<HistoryRecord> getTaskHistory(NGContainer ngc) throws Exception {
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

    public List<HistoryRecord> getTaskHistoryRange(NGContainer ngc,
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
     * when a task is moved to another project, use this to record where it was
     * moved to, so that we can link there.
     */
    public void setMovedTo(String project, String otherId) throws Exception {
        setScalar("MovedToProject", project);
        setScalar("MovedToId", otherId);
    }

    /**
     * get the project that this task was moved to.
     */
    public String getMovedToProjectKey() throws Exception {
        return getScalar("MovedToProject");
    }

    /**
     * get the id of the task in the other project that this task was moved to.
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

    //TODO: this should be changed to vector form to avoid problems with commas
    public String getAssigneeCommaSeparatedList() throws Exception {
        return getScalar("assignee");
    }

    //TODO: this should be changed to vector form to avoid problems with commas
    public void setAssigneeCommaSeparatedList(String newVal) throws Exception {
        setScalar("assignee", newVal);
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

    public NGPage getProject() {
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
     * the universal id is a globally unique ID for this goal, composed of the
     * id for the server, the project, and the goal. This is set at the point
     * where the goal is created and remains with the note as it is carried
     * around the system as long as it is moved as a clone from a project to a
     * clone of a project. If it is copied or moved to another project for any
     * other reason, then the universal ID should be reset.
     */
    public String getUniversalId() throws Exception {
        return getScalar("universalid");
    }

    public void setUniversalId(String newID) throws Exception {
        setScalar("universalid", newID);
    }

    private void handleSubTaskStateChangeEvent() throws Exception {
        if (hasParentGoal() == false) {
            return;
        }

        GoalRecord parentTask = getParentGoal();
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

            if (state == BaseRecord.STATE_STARTED
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
                task.setState(BaseRecord.STATE_STARTED);
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
                        || tstate == BaseRecord.STATE_STARTED) {
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
     * to end.  IF the goal is discovered in wait mode after this time, then
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
     * Passive is a setting that says that the goal was not defined
     * in this particular replicant of the project, and so it should
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
     * RemoteProjectURL is the URL to get information about the
     * project that this goal is defined in
     */
    public void setRemoteProjectURL(String url) {
        setScalar("remoteProjectURL", url);
    }
    public String getRemoteProjectURL() {
        return getScalar("remoteProjectURL");
    }

    /**
     * RemoteProjectName is the name of the
     * project that this goal is defined in
     */
    public void setRemoteProjectName(String url) {
        setScalar("remoteProjectName", url);
    }
    public String getRemoteProjectName() {
        return getScalar("remoteProjectName");
    }

    /**
     * RemoteSiteURL is the URL to get information about the
     * site that this goal is defined in
     */
    public void setRemoteSiteURL(String url) {
        setScalar("remoteSiteURL", url);
    }
    public String getRemoteSiteURL() {
        return getScalar("remoteSiteURL");
    }

    /**
     * RemoteSiteName is the name of the
     * site that this goal is defined in
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



    public JSONObject getJSON4Goal(NGPage ngp) throws Exception {
        JSONObject thisGoal = new JSONObject();
        thisGoal.put("universalid", getUniversalId());
        thisGoal.put("id", getId());
        thisGoal.put("synopsis", getSynopsis());
        thisGoal.put("description", getDescription());
        thisGoal.put("modifiedtime", getModifiedDate());
        thisGoal.put("modifieduser", getModifiedBy());
        thisGoal.put("state",     getState());
        thisGoal.put("status",    getStatus());
        thisGoal.put("priority",  getPriority());
        thisGoal.put("duedate",   getDueDate());
        thisGoal.put("startdate", getStartDate());
        thisGoal.put("enddate",   getEndDate());
        thisGoal.put("duration",  getDuration());
        thisGoal.put("rank",      getRank());
        thisGoal.put("prospects", getProspects());
        
        thisGoal.put("projectname", ngp.getFullName());
        thisGoal.put("projectKey", ngp.getKey());

        NGRole assignees = getAssigneeRole();
        JSONArray peopleList = new JSONArray();
        JSONArray assignTo = new JSONArray();
        for (AddressListEntry ale : assignees.getExpandedPlayers(ngp)) {
            peopleList.put(ale.getUniversalId());
            assignTo.put(ale.getJSON());
        }
        thisGoal.put("assignees", peopleList);
        thisGoal.put("assignTo", assignTo);

        NGBook site = ngp.getSite();
        thisGoal.put("sitename", site.getFullName());
        thisGoal.put("siteKey", site.getKey());

        return thisGoal;
    }
    public JSONObject getJSON4Goal(NGPage ngp, String baseURL, License license) throws Exception {
        if (license==null) {
            throw new Exception("getJSON4Goal needs a license object");
        }
        JSONObject thisGoal = getJSON4Goal(ngp);
        String urlRoot = baseURL + "api/" + ngp.getSiteKey() + "/" + ngp.getKey() + "/";
        String goalinfo = urlRoot + "goal" + getId() + "/goal.json?lic=" + license.getId();
        LicenseForUser lfu = LicenseForUser.getUserLicense(license);
        String siteRoot = baseURL + "api/" + ngp.getSiteKey() + "/$/?lic=" + lfu.getId();
        String uiUrl = getRemoteUpdateURL();
        if (uiUrl==null || uiUrl.length()==0) {
            uiUrl = baseURL + "t/" + ngp.getSiteKey() + "/" + ngp.getKey()
                + "/task" + getId() + ".htm";
        }
        thisGoal.put("projectinfo", urlRoot+"?lic="+license.getId());
        thisGoal.put("goalinfo", goalinfo);
        thisGoal.put("ui", uiUrl);
        thisGoal.put("siteinfo", siteRoot);
        return thisGoal;
    }

    //TODO: looks like this can be used either to update from an upstream representation
    //or a JSON from the UI, but the behavior should probably be a little different.
    //probably need two separate functions for that.
    public void updateGoalFromJSON(JSONObject goalObj) throws Exception {
        String universalid = goalObj.getString("universalid");
        if (!universalid.equals(getUniversalId())) {
            //just checking, this should never happen
            throw new Exception("Error trying to update the record for a goal with UID ("
                    +getUniversalId()+") with post from goal with UID ("+universalid+")");
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
        if (goalObj.has("status")) {
            setStatus(goalObj.getString("status"));
        }
        if (goalObj.has("state")) {
            setState(goalObj.optInt("state"));
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
        if (goalObj.has("duration")) {
            setDuration(goalObj.getLong("duration"));
        }
        if (goalObj.has("rank")) {
            setPriority(goalObj.getInt("rank"));
        }
        if (goalObj.has("ui")) {
            setRemoteUpdateURL(goalObj.getString("ui"));
        }
        if (goalObj.has("projectinfo")) {
            setRemoteProjectURL(goalObj.getString("projectinfo"));
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
            NGRole assigneeRole = getAssigneeRole();
            assigneeRole.clear();
            JSONArray peopleList = goalObj.getJSONArray("assignTo");
            int lastPerson = peopleList.length();
            for (int i=0; i<lastPerson; i++) {
                JSONObject person = peopleList.getJSONObject(i);
                assigneeRole.addPlayer(new AddressListEntry(person.getString("uid"), person.getString("name")));
            }
        }
        else if (goalObj.has("assignee")) {
            throw new Exception("Potential problem.... JSON has assignee but no assignTo field. Assignee is deprecated.");
        }
    }
}
