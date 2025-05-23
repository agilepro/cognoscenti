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

import com.purplehillsbooks.weaver.mail.JSONWrapper;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;

public class TaskArea extends JSONWrapper {

    public TaskArea(JSONObject jo) {
        super(jo);
    }

    public String getId() {
        try {
            return kernel.getString("id");
        }
        catch (Exception e) {
            throw new RuntimeException("TaskArea does not have an id????", e);
        }
    }
    public void setId(String newId) throws Exception {
        kernel.put("id", newId);
    }

    /**
     * looks for one name, and replaces them with another name
     */
    public void replaceAssignee(String sourceUser, String destUser) throws Exception {
        JSONArray assignees = kernel.optJSONArray("assignees");
        if (assignees==null) {
            //if there are no assignees at all, then ignore this task area
            return;
        }
        JSONArray newOnes = new JSONArray();
        for (int i=0; i<assignees.length(); i++) {
            JSONObject oneAss = assignees.getJSONObject(i);
            String oneName = oneAss.getString("uid");
            if (sourceUser.equalsIgnoreCase(oneName)) {
                AddressListEntry ale = AddressListEntry.findOrCreate(destUser);
                newOnes.put(ale.getJSON());
            }
            else {
                newOnes.put(oneAss);
            }
        }
        kernel.put("assignees", newOnes);
    }

    public JSONObject getMinJSON() throws Exception {
        JSONObject thisPort = new JSONObject();
        extractString(thisPort, "id");
        extractString(thisPort, "name");
        extractString(thisPort, "purpose");
        extractString(thisPort, "status");
        extractString(thisPort, "prospects");
        extractArray(thisPort, "assignees");
        return thisPort;
    }


    public void updateFromJSON(JSONObject input) throws Exception {
        boolean changed = copyStringToKernel(input, "name");
        changed = copyStringToKernel(input, "purpose") || changed;
        changed = copyStringToKernel(input, "status") || changed;
        changed = copyStringToKernel(input, "prospects") || changed;
        changed = copyArrayToKernel(input, "assignees") || changed;
    }

}
