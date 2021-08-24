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

package com.purplehillsbooks.weaver.rest;

import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;
import java.util.Vector;

import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.BaseRecord;
import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.DOMUtils;
import com.purplehillsbooks.weaver.GoalRecord;
import com.purplehillsbooks.weaver.NGContainer;
import com.purplehillsbooks.weaver.NGPageIndex;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.RemoteGoal;
import com.purplehillsbooks.weaver.UserPage;
import com.purplehillsbooks.weaver.UtilityMethods;
import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.exception.ProgramLogicError;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

/**
 * This class represents holds the global id of a particular user, and it
 * helps to build the XML representation of that user's tasks.
 */
public class TaskHelper
{
    private String lserverURL;
    private AddressListEntry ale = null;

    private Hashtable<GoalRecord,NGWorkspace> pageMap = new Hashtable<GoalRecord,NGWorkspace>();
    private List<GoalRecord> allTask = new ArrayList<GoalRecord>();
    private List<GoalRecord> activeTask = new ArrayList<GoalRecord>();
    private List<GoalRecord> completedTask = new ArrayList<GoalRecord>();
    private List<GoalRecord> futureTask = new ArrayList<GoalRecord>();

    private boolean isFilled = false;

    public TaskHelper(String uopenid, String serverURL)
    {
        lserverURL = serverURL;
        ale = new AddressListEntry(uopenid);
    }

    /**
     * This method GENERATES a list of XML document elements representing the
     * current collection of tasks so that they can be sent out in response to a
     * REST request.
     */
    public void fillInTaskList(Document doc, Element element_activities, String filter)
            throws Exception {
        if (!isFilled) {
            throw new ProgramLogicError(
                    "Attempt to produce a task list, but the tasks have not been collected yet.");
        }
        List<GoalRecord> taskList = null;
        if (NGResource.DATA_ALLTASK_XML.equals(filter)) {
            taskList = allTask;
        }
        else if (NGResource.DATA_ACTIVETASK_XML.equals(filter)) {
            taskList = activeTask;
        }
        else if (NGResource.DATA_COMPLETETASK_XML.equals(filter)) {
            taskList = completedTask;
        }
        else if (NGResource.DATA_FUTURETASK_XML.equals(filter)) {
            taskList = futureTask;
        }
        else {
            // this is a program logic error
            throw new ProgramLogicError("Don't understand the filter: " + filter);
        }

        for (GoalRecord tr : taskList) {
            Element actEle = DOMUtils.createChildElement(doc, element_activities, "activity");
            NGWorkspace ngp = pageMap.get(tr);
            String processurl = lserverURL + "p/" + ngp.getKey() + "/process.xml";
            tr.fillInWfxmlActivity(doc, actEle, processurl);
        }
    }


    public void scanAllTask(Cognoscenti cog) throws Exception
    {
        if (isFilled) {
            throw new ProgramLogicError("Attempting to fill a TaskHelper twice!  Probably an error.");
            //could change the logic to clear out the collections at this point, but
            //adding an exception here so we can learn if this ever happens.
        }
        List<NGPageIndex> pindxlist = cog.getAllContainers();
        if (pindxlist==null || pindxlist.size()==0)
        {
            //this can happen if the server has been restarted and not yet
            //initialized.  What to do?  Thos exception
            throw new NGException("nugen.exception.server.uninitialized",null);
        }
        for (NGPageIndex ngpi : pindxlist)
        {
            //only includes tasks from projects at this point
            if (ngpi.isProject())
            {
                NGWorkspace aProject = ngpi.getWorkspace();
                registerGoalsAssignedToUser(aProject, ale);
            }
        }
        isFilled = true;
    }

    private void registerGoalsAssignedToUser(NGWorkspace aProject, AddressListEntry forAssignee) throws Exception {
        if (forAssignee==null) {
            throw new Exception("Program Logic Error: null assignee parameter in registerGoalsAssignedToUser");
        }
        for(GoalRecord gr : aProject.getAllGoals()) {
            if (!gr.isPassive() && gr.isAssignee(forAssignee)) {
                registerGoal(aProject, gr);
            }
        }
    }

    private void registerAllGoalsOnPage(NGWorkspace aProject) throws Exception {
        for(GoalRecord gr : aProject.getAllGoals()) {
            registerGoal(aProject, gr);
        }
    }


    /**
     * Includes an action item record into the registry of action items that are being
     * tracked by this TaskHelper object.
     */
    private void registerGoal(NGWorkspace aProject, GoalRecord gr) throws Exception {
        pageMap.put(gr, aProject);
        allTask.add(gr);
        int state = gr.getState();
        if(state == BaseRecord.STATE_ERROR){
            activeTask.add(gr);
        }else if(state == BaseRecord.STATE_ACCEPTED){
            activeTask.add(gr);
        }else if(state == BaseRecord.STATE_OFFERED){
            activeTask.add(gr);
        }else if(state == BaseRecord.STATE_WAITING){
            activeTask.add(gr);
        }else if(state == BaseRecord.STATE_UNSTARTED){
            futureTask.add(gr);
        }else if(state == BaseRecord.STATE_COMPLETE){
            completedTask.add(gr);
        }
    }

    /**
    * loads the action items from the specified project, and then, given a list of task ids, it
    * generate an XML dom tree from the tasks specifically mentioned by ID.
    */
    public void generateXPDLTaskInfo(NGWorkspace ngp, Document doc, Element element_activities, String dataIds)
            throws Exception {
        List<String> idList = null;
        if (dataIds!= null) {
            idList = UtilityMethods.splitString(dataIds,',');
        }
        registerAllGoalsOnPage(ngp);
        for(GoalRecord tr : allTask) {
            if(!isRequested(tr.getId(), idList)) {
                continue;
            }
            Element actEle = DOMUtils.createChildElement(doc, element_activities, "activity");
            String processurl = lserverURL + "p/" + ngp.getKey() + "/process.xml";
            tr.fillInWfxmlActivity(doc, actEle, processurl);
        }
    }

    private  boolean isRequested(String id, List<String> idList) throws Exception
    {
        if(idList == null){
            return true;
        }
        for(String test : idList){
            if(id.equals(test))
            {
                return true;
            }
        }
        return false;
    }


    public List<GoalRecord> getAllTasks() {
        if (!isFilled) {
            throw new ProgramLogicError("Attempt to get a task list, but the tasks have not been collected yet.");
        }
        return allTask;
    }
    public List<GoalRecord> getActiveTasks() {
        if (!isFilled) {
            throw new ProgramLogicError("Attempt to get a task list, but the tasks have not been collected yet.");
        }
        return activeTask;
    }
    public List<GoalRecord> getCompletedTasks() {
        if (!isFilled) {
            throw new ProgramLogicError("Attempt to get a task list, but the tasks have not been collected yet.");
        }
        return completedTask;
    }
    public List<GoalRecord> getFutureTasks() {
        if (!isFilled) {
            throw new ProgramLogicError("Attempt to get a task list, but the tasks have not been collected yet.");
        }
        return futureTask;
    }
    public NGContainer getPageForTask(GoalRecord tr) {
        if (!isFilled) {
            throw new ProgramLogicError("Attempt to get a task list, but the tasks have not been collected yet.");
        }
        return pageMap.get(tr);
    }


    public void syncTasksToProfile(UserPage uPage, Cognoscenti cog) throws Exception {
        if (!isFilled) {
            scanAllTask(cog);
        }

        uPage.clearTaskRefFlags();
        for (GoalRecord existingTask : allTask) {
            int state = existingTask.getState();
            if (state == BaseRecord.STATE_OFFERED ||
                state == BaseRecord.STATE_ACCEPTED)  {
                NGWorkspace proj = pageMap.get(existingTask);
                RemoteGoal ref = uPage.findOrCreateTask( proj.getKey(), existingTask.getId() );
                ref.touchFlag = true;
                ref.syncFromTask(existingTask);
            }
        }

        Vector<RemoteGoal> untouched = new Vector<RemoteGoal>();
        for (RemoteGoal ref : uPage.getRemoteGoals()) {

            if (!ref.touchFlag) {
                untouched.add(ref);
            }
        }

        for (RemoteGoal dangler : untouched) {
            uPage.deleteTask(dangler.getProjectKey(), dangler.getId());
        }

        //renumber, rerank the tasks
        uPage.cleanUpTaskRanks();

    }


}
