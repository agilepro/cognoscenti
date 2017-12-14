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
import java.util.List;

import org.socialbiz.cog.util.StringCounter;
import com.purplehillsbooks.json.JSONObject;

/**
 * This is a role that extacts the assignees of a task, and returns that using
 * an interface of a role.
 *
 * This class is an interface wrapper class -- it does not hold any information but it
 * simply reads and write information to/from the GoalRecord itself without
 * caching anything.
 */
public class RoleGoalAssignee extends RoleSpecialBase implements NGRole {
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
        String assigneeList = getList();
        if (assigneeList == null) {
            return list;
        }
        List<String> assignees = UtilityMethods.splitString(assigneeList, ',');
        for (String assignee : assignees) {
            if (assignee.length() > 0) {
                list.add(new AddressListEntry(assignee));
            }
        }
        return list;
    }

    @Override
    public void addPlayer(AddressListEntry newMember) throws Exception {
        List<AddressListEntry> current = getDirectPlayers();
        StringBuilder newVal = new StringBuilder();
        for (AddressListEntry one : current) {
            if (one.equals(newMember)) {
                // person is already in the list, so leave without updating
                return;
            }
            newVal.append(one.getUniversalId());
            newVal.append(",");
        }
        newVal.append(newMember.getUniversalId());
        setList(newVal.toString());
    }
    
    @Override
    public void addPlayersIfNotPresent(List<AddressListEntry> addressList) throws Exception {
        for (AddressListEntry ale : addressList) {
            addPlayer(ale);
        }
    }


    public void removePlayer(AddressListEntry oldMember) throws Exception {
        removePlayerCompletely(oldMember);
    }
    public void removePlayerCompletely(UserRef user) throws Exception {
        List<AddressListEntry> current = getDirectPlayers();
        StringBuilder newVal = new StringBuilder();
        boolean needComma = false;
        boolean changed = false;
        for (AddressListEntry one : current) {
            if (user.hasAnyId(one.getUniversalId())) {
                // person was in the list, this will remove him from it
                changed = true;
            } else {
                if (needComma) {
                    newVal.append(",");
                }
                newVal.append(one.getUniversalId());
                needComma = true;
            }
        }
        if (changed) {
            setList(newVal.toString());
        }
    }

    private String getList() {
        return goal.getAssigneeCommaSeparatedList();
    }

    private void setList(String newVal) {
        goal.setAssigneeCommaSeparatedList(newVal);
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
            goal.setAssigneeCommaSeparatedList("");
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
        String assigneeList = getList();
        if (assigneeList == null) {
            return;
        }

        for (String id : UtilityMethods.splitString(assigneeList, ',')) {
            sc.increment(id);
        }
    }


    /**
     * This will replace the assignee of an goal with another, avoiding
     * any duplication.
     */
    public boolean replaceId(String sourceId, String destId) {
        String assigneeList = getList();
        if (assigneeList == null) {
            return false;
        }

        //first a clear search path to see if one is there.
        List<String> assignees = UtilityMethods.splitString(assigneeList, ',');
        boolean foundOne = false;
        for (String oneAss : assignees) {
            if (oneAss.equalsIgnoreCase(sourceId)) {
                foundOne = true;
            }
        }
        if (!foundOne) {
            return false;
        }

        //since we found one, now reconstruct the assignee list
        StringBuilder result = new StringBuilder();
        result.append(destId);
        for (String oneAss : assignees) {
            //be sure not to duplicate the destId ... one might have already been in there.
            if (!oneAss.equalsIgnoreCase(sourceId) && !oneAss.equalsIgnoreCase(destId)) {
                result.append(",");
                result.append(oneAss);
            }
        }
        setList(result.toString());
        return true;
    }

}
