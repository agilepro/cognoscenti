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

import com.purplehillsbooks.json.JSONObject;

/**
* this defines a role in terms of a name, a symbol, a
* description.  These are defined at the site level,
* and are used at the workspace level.  thus each workspace 
* can decide which roles it wants to use.
*/
public class RoleDefinition {

    public String symbol;
    public String name;
    public String description;
    public String eligibility;

    // can edit give priviledges to edit within a workspace
    // and can only be filled by full(paid) users.
    public boolean canEdit = false;

    // special priviledges for administration
    // can only be filled by full(paid) users.
    public boolean canAdminister = false;

    // whether this is created by default in a workspace
    public boolean isWorkspaceDefault = false;

    public RoleDefinition() {}
 
    /**
     * getJSON is for normal lists of roles, the current players, and such.
     * Does not include all the historical detail.
     */
    public JSONObject getJSON() throws Exception {
        JSONObject jObj = new JSONObject();
        jObj.put("symbol", symbol);
        jObj.put("name", name);
        jObj.put("description", description);
        jObj.put("eligibility", eligibility);
        jObj.put("canEdit", canEdit);
        jObj.put("canAdminister", canAdminister);
        return jObj;
    }

    public void updateFromJSON(JSONObject roleInfo) throws Exception {
        // the symbol can not be changed, it is the key
        if (roleInfo.has("name")) {
            name = roleInfo.getString("name");
        }
        if (roleInfo.has("description")) {
            description = roleInfo.getString("description");
        }
        if (roleInfo.has("eligibility")) {
            eligibility = roleInfo.getString("eligibility");
        }
        if (roleInfo.has("canEdit")) {
            canEdit = roleInfo.getBoolean("canEdit");
        }
        if (roleInfo.has("canAdminister")) {
            canAdminister = roleInfo.getBoolean("canAdminister");
        }
        if (roleInfo.has("isWorkspaceDefault")) {
            isWorkspaceDefault = roleInfo.getBoolean("isWorkspaceDefault");
        }
    }

    public RoleDefinition getClone() {
        RoleDefinition clone = new RoleDefinition();
        clone.symbol = this.symbol;
        clone.name = this.name;
        clone.description = this.description;
        clone.eligibility = this.eligibility;
        clone.canEdit = this.canEdit;
        clone.canAdminister = this.canAdminister;
        clone.isWorkspaceDefault = this.isWorkspaceDefault;
        return clone;
    }

}
