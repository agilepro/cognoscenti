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

import java.io.Writer;
import java.util.List;

import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.exception.ProgramLogicError;
import org.w3c.dom.Element;

/**
* Implements the process and task formatting
*/
public class SectionTask extends SectionUtil implements SectionFormat
{


    public SectionTask()
    {
    }

    public String getName()
    {
        return "Process";
    }


    public static List<GoalRecord> getAllTasks(NGSection sec)
            throws Exception
    {
        if (sec == null)
        {
            throw new ProgramLogicError("trying to get tasks from a null section does not make sense");
        }

        List<GoalRecord> list = sec.getChildren("task", GoalRecord.class);
        for (GoalRecord task : list)
        {
            //temporary -- tasks may not have had ids, so patch that up now if necessary
            //can remove this after existing pages have been converted to have id values
            String id = task.getId();
            if (id==null || id.length()!=4)
            {
                task.setId(sec.parent.getUniqueOnPage());
            }
        }
        GoalRecord.sortTasksByRank(list);
        return list;
    }

    public static GoalRecord getTaskOrFail(NGSection sec, String id)
        throws Exception
    {
        GoalRecord task = getTaskOrNull(sec, id);
        if (task==null)
        {
            throw new NGException("nugen.exception.could.not.find.task", new Object[]{id});
        }
        return task;
    }

    /**
     * Find the task by either the local id or the universal id.
     */
    public static GoalRecord getTaskOrNull(NGSection sec, String id)
        throws Exception
    {
        if (id==null) {
            throw new Exception("getTaskOrNull requires a non-null id parameter");
        }
        List<GoalRecord> list = sec.getChildren("task", GoalRecord.class);
        for (GoalRecord task : list) {
            if (id.equals(task.getId())) {
                return task;
            }
            if (id.equals(task.getUniversalId())) {
                return task;
            }
        }
        return null;
    }


    public void findLinks(List<String> v, NGSection sec)
        throws Exception
    {
        for (GoalRecord tr : getAllTasks(sec))
        {
            String link = tr.getDisplayLink();
            v.add(link);
        }
    }

    public void writePlainText(NGSection section, Writer out) throws Exception
    {
        ProcessRecord process = section.parent.getProcess();
        if (process != null) {
            SectionUtil.writeTextWithLB(process.getId() , out);
            SectionUtil.writeTextWithLB(process.getSynopsis() , out);
            SectionUtil.writeTextWithLB(process.getDescription() , out);
            SectionUtil.writeTextWithLB(String.valueOf(process.getState()) , out);
            SectionUtil.writeTextWithLB(String.valueOf(process.getDueDate()) , out);
            SectionUtil.writeTextWithLB(String.valueOf(process.getStartDate()) , out);
            SectionUtil.writeTextWithLB(String.valueOf(process.getEndDate()) , out);
            SectionUtil.writeTextWithLB(String.valueOf(process.getPriority()) , out);

            LicensedURL[] pp = process.getLicensedParents();
            for (int i=0; i<pp.length; i++) {
                SectionUtil.writeTextWithLB(String.valueOf(pp[i].url) , out);
            }
        }

        for (GoalRecord task : getAllTasks(section)) {
            SectionUtil.writeTextWithLB(task.getId() , out);
            SectionUtil.writeTextWithLB(task.getSynopsis() , out);
            SectionUtil.writeTextWithLB(task.getDescription() , out);
            SectionUtil.writeTextWithLB(task.getAssigneeCommaSeparatedList() , out);
            SectionUtil.writeTextWithLB(task.getStatus() , out);
            SectionUtil.writeTextWithLB(task.getSub() , out);
            SectionUtil.writeTextWithLB(task.getActionScripts() , out);
            SectionUtil.writeTextWithLB(String.valueOf(task.getRank()) , out);
            SectionUtil.writeTextWithLB(String.valueOf(task.getState()) , out);
            SectionUtil.writeTextWithLB(String.valueOf(task.getDueDate()) , out);
            SectionUtil.writeTextWithLB(String.valueOf(task.getStartDate()) , out);
            SectionUtil.writeTextWithLB(String.valueOf(task.getEndDate()) , out);
            SectionUtil.writeTextWithLB(String.valueOf(task.getPriority()) , out);
        }
    }

    public void removeTask(String taskId, NGSection section) {
        Element secElem = section.getElement();
        for (Element taskElem : DOMUtils
                .getNamedChildrenVector(secElem, "task")) {
            String id = taskElem.getAttribute("id");
            if (id.equals(taskId)) {
                secElem.removeChild(taskElem);
                return;
            }
        }
    }

    /**
    * Walk through whatever elements this owns and put all the four digit
    * IDs into the vector so that we can generate another ID and assure it
    * does not duplication any id found here.
    */
    public void findIDs(List<String> v, NGSection sec) throws Exception {
        for (GoalRecord tr : getAllTasks(sec)) {
            v.add(tr.getId());
        }
    }

    public static boolean canEditTask(NGWorkspace ngp, AuthRequest ar, String taskId) throws Exception
    {
        boolean edit = false;

        ProcessRecord pr = ngp.getProcess();
        String prlicense = pr.accessLicense().getId();
        if(prlicense != null && prlicense.equals(ar.licenseid))
        {
            edit = true;
            return edit;
        }
        try {
            GoalRecord tr = ngp.getGoalOrFail(taskId.trim());
            String trlicense = tr.accessLicense().getId();
            if(trlicense != null && trlicense.equals(ar.licenseid))
            {
                edit = true;
                return edit;
            }

        }catch(Exception e){
            edit = false;
            //Not a Task Licence
        }
        //Check if it has page licence
        return ar.isMember();
    }

/*
    public static void copyTaskRecord(GoalRecord sourceRecord, GoalRecord destinationRecord) throws Exception{
        destinationRecord.setSynopsis(sourceRecord.getSynopsis().toString());
        destinationRecord.setDueDate(SectionUtil.niceParseDate(String.valueOf(sourceRecord.getDueDate())));
        destinationRecord.setAssigneeCommaSeparatedList(sourceRecord.getAssigneeCommaSeparatedList());
        destinationRecord.setPriority(sourceRecord.getPriority());
        destinationRecord.setDescription(sourceRecord.getDescription());
        destinationRecord.setState(sourceRecord.getState());
        destinationRecord.setCreator(sourceRecord.getCreator());

        destinationRecord.setActionScripts(sourceRecord.getActionScripts());
        destinationRecord.setDuration(sourceRecord.getDuration());
        destinationRecord.setEndDate(sourceRecord.getEndDate());
        destinationRecord.setFreePass(sourceRecord.getFreePass());
        destinationRecord.setId(sourceRecord.getId());

        destinationRecord.setStartDate(sourceRecord.getStartDate());
        destinationRecord.setStatus(sourceRecord.getStatus());
        destinationRecord.setRank(sourceRecord.getRank());
        if(!"".equals(sourceRecord.getParentGoalId())){
            destinationRecord.setParentGoal(sourceRecord.getParentGoalId());
        }
    }
*/
}
