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

import java.util.ArrayList;
import java.util.List;

import com.purplehillsbooks.weaver.util.StringCounter;
import com.purplehillsbooks.json.JSONObject;

/**
 * This is a role that extacts the assignees of a task, and returns that using
 * an interface of a role.
 *
 * This class is an interface wrapper class -- it does not hold any information but it
 * simply reads and write information to/from the GoalRecord itself without
 * caching anything.
 */
public class RoleGoalAssignee extends RoleSpecialBase {
    private GoalRecord goal;

    RoleGoalAssignee(GoalRecord newTask) {
        goal = newTask;
    }

    public String getName() {
        return "Assigned to goal: " + taskName();
    }

    /**
     * A description of the purpose of the role, suitable for display to user.
     */
    public String getDescription() {
        return "Assigned to the goal " + taskName();
    }

    public List<AddressListEntry> getDirectPlayers() throws Exception {
        List<AddressListEntry> list = new ArrayList<AddressListEntry>();
        for (String assignee : getAssigneeList()) {
            if (assignee.length() > 0) {
                list.add(AddressListEntry.findOrCreate(assignee));
            }
        }
        return list;
    }

    @Override
    public void addPlayer(AddressListEntry newMember) throws Exception {
        List<AddressListEntry> current = getDirectPlayers();
        List<String> newList = new ArrayList<String>();
        for (AddressListEntry one : current) {
            if (newMember.hasAnyId(one.getUniversalId())) {
                // person is already in the list, so leave without updating
                return;
            }
            newList.add(one.getUniversalId());
        }
        newList.add(newMember.getUniversalId());
        goal.setAssigneeList(newList);
    }
    
    @Override
    public void addPlayersIfNotPresent(List<AddressListEntry> addressList) throws Exception {
        for (AddressListEntry ale : addressList) {
            addPlayer(ale);
        }
    }


    @Override
    public void removePlayer(AddressListEntry oldMember) throws Exception {
        //in this case the methods are the same as the one below
        //however this is an interface method to implement
        removePlayerCompletely(oldMember);
    }
    @Override
    public void removePlayerCompletely(UserRef user) throws Exception {
        List<AddressListEntry> current = getDirectPlayers();
        List<String> newList = new ArrayList<String>();
        boolean changed = false;
        for (AddressListEntry one : current) {
            if (user.hasAnyId(one.getUniversalId())) {
                // person was in the list, this will remove him from it
                changed = true;
            } 
            else {
                newList.add(one.getUniversalId());
            }
        }
        if (changed) {
            goal.setAssigneeList(newList);
        }
    }

    private List<String> getAssigneeList() {
        return goal.getAssigneeList();
    }

    protected String taskName() {
        try {
            return goal.getSynopsis();
        } catch (Exception e) {
            return "(unspecified synopsis)";
        }
    }

    public void clear() {
        try {
            goal.clearAssigneeList();
        } catch (Exception e) {
            // this is very unlikely ...
            throw new RuntimeException("Unable to clear the action item assignees", e);
        }
    }

    @Override
    public String getColor() {
        return "lightgreen";
    }
    @Override
    public void setColor(String reqs) {
        //ignore this
    }

    @Override
    public JSONObject getJSON() throws Exception {
        throw new Exception("getJSON has not been implemented on RoleGoalAssignee");
    }


    public void countIdentifiersInRole(StringCounter sc) {
        for (String id : getAssigneeList()) {
            sc.increment(id);
        }
    }


    /**
     * This will replace the assignee of an goal with another, avoiding
     * any duplication.
     */
    public boolean replaceId(String sourceId, String destId) {
        //first a clear search path to see if one is there.
        List<String> assignees = getAssigneeList();

        List<String> newList = new ArrayList<String>();
        newList.add(destId);
        boolean found = false;
        for (String oneAss : assignees) {
            //be sure not to duplicate the destId ... one might have already been in there.
            if (oneAss.equalsIgnoreCase(sourceId)) {
                found = true;
            } 
            else if (oneAss.equalsIgnoreCase(destId)) {
                //already there???
            }
            else {
                newList.add(oneAss);
            }
        }
        if (!found) {
            //if you never find the source, then ignore the command
            return false;
        }
        goal.setAssigneeList(newList);
        return true;
    }
    
}
