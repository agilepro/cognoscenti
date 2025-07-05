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
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.weaver.util.StringCounter;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;

/**
* workspace role has a special relationship to the role definitions
* from the site, while roles from sites and user pages do not have that.
*/
public class WorkspaceRole extends CustomRole {

    NGBook site;
    RoleDefinition def;

    // this is needed for the DomFace style create on the DOM
    public WorkspaceRole(Document doc, Element ele, DOMFace p) {
        super(doc, ele, p);
    }

    public void setDef(NGBook newSite, RoleDefinition newDef) {
        site = newSite;
        def = newDef;
    }

    // performs the check that if the role is edit role, the user must be full(paid)
    private void assertPlayerAcceptible(AddressListEntry newMember) throws Exception {
        if (def.canEdit) {
            UserProfile uProf = newMember.getUserProfile();
            if (site.isUnpaidUser(uProf)) {
                throw WeaverException.newBasic(
                    "Role (%s) is an update role, and can not be played by a basic user (%s)", 
                    getName(), newMember.getEmail());
            }
        }
    }

    public String getSymbol() {
        return def.symbol;
    }
    public String getName() {
        return def.name;
    }
    public void setName(String name) {
        throw new RuntimeException("setName not implemented on Workspace Roles");
    }

    public String getDescription() {
        return def.description;
    }
    public void setDescription(String desc) {
        throw new RuntimeException("setDescription not implemented on Workspace Roles");
    }

    public String getRequirements() {
        return def.eligibility;
    }
    public void setRequirements(String reqs) {
        throw new RuntimeException("setRequirements(eligibility) not implemented on Workspace Roles");
    }
    
    /**
     * Each role in a workspace can be linked to a role in the Site.
     * These will be synchronized.  When the workspace is read, it will
     * be refreshed from the linked role.  When the workspace is updated
     * it will also update the linked role.  The Site become a common
     * ground to exchange the list of people who constitute a role.
     */
    public String getLinkedRole()
    {
        return getAttribute("linkedRole");
    }
    public void setLinkedRole(String linkedRole)
    {
        setAttribute("linkedRole", linkedRole);
    }



    public List<AddressListEntry> getExpandedPlayers(NGContainer ngp) throws Exception
    {
        List<AddressListEntry> result = new ArrayList<AddressListEntry>();
        expandRoles(result, ngp, getDirectPlayers(), 4);
        return result;
    }

    public List<AddressListEntry> getDirectPlayers() throws Exception {
        RoleTerm term = getCurrentTerm();
        if (term==null) {
            return getNonTermList();
        }
        return term.getDirectPlayers();
    }

    public AddressListEntry getFirstPlayer() throws Exception {
        for (AddressListEntry ale : getDirectPlayers()) {
            return ale;
        }
        return null;
    }

    private List<AddressListEntry> getNonTermList() throws Exception {
        List<AddressListEntry> list=new ArrayList<AddressListEntry>();
        List<String> members = getVector("member");
        for (String memberID : members) {
            AddressListEntry ale = AddressListEntry.newEntryFromStorage(memberID);
            if (ale.isWellFormed()) {
                //don't add the reference if it is not a suitable user
                list.add(ale);
            }
        }
        return list;
    }

    public void addPlayer(AddressListEntry newMember) throws Exception {
        assertPlayerAcceptible(newMember);
        super.addPlayer(newMember);
    }

    public void clear() {
        try {
            RoleTerm term = getCurrentTerm();
            if (term!=null) {
                term.clear();
            }
            //the vector should be cleared out in any case, even
            //if there is a valid term object.
            clearVector("member");
        }
        catch (Exception e) {
            //i hate this, but clear was previously a method unlikely to
            //throw exception.  Still unlikely, so I don't want to change
            //the signature for this.  So throw an undeclared exception.
            throw new RuntimeException("Unable to clear the role", e);
        }
    }

    public boolean isExpandedPlayer(UserRef user, NGContainer ngp) throws Exception
    {
        return isPlayerOfAddressList(user, getExpandedPlayers(ngp));
    }
    public boolean isPlayer(UserRef user) throws Exception
    {
        return isPlayerOfAddressList(user, getDirectPlayers());
    }
    public String whichIDForUser(UserRef user) throws Exception
    {
        return whichIDForUserOfAddressList(user, getDirectPlayers());
    }



    public String getColor() {
        return getAttribute("color");
    }
    public void setColor(String color) {
        setAttribute("color", color);
    }
    public RoleTerm getCurrentTerm() throws Exception {
        long nowTime = System.currentTimeMillis();
        for( RoleTerm rt : getAllTerms()) {
            if (rt.isComplete() && rt.includesDate(nowTime)) {
                return rt;
            }
        }
        return null;
    }


    public static boolean isPlayerOfAddressList(UserRef user, List<AddressListEntry> list) throws Exception {
        if (user==null) {
            throw WeaverException.newBasic("isPlayerOfAddressList called with null user object.");
        }
        for (AddressListEntry alr : list) {
            if (user.hasAnyId(alr.getInitialId())) {
                return true;
            }
        }
        return false;
    }

    static String whichIDForUserOfAddressList(UserRef uRef, List<AddressListEntry> list) throws Exception {
        for (AddressListEntry alr : list) {
            String thisID = alr.getInitialId();
            if (uRef.hasAnyId(thisID)) {
                return thisID;
            }
        }
        return null;
    }

    /**
    * recursively walk through users and roles, expanding roles and adding all the
    * the user so that you have a single, flat list of users in the result list.
    * loopLimiter prevents endless loops from badly formed role data.
    */
    static void expandRoles(List<AddressListEntry> result, NGContainer ngp,
        List<AddressListEntry> list, int loopLimiter)
        throws Exception
    {
        if (--loopLimiter<0)
        {
            //stop recuring after the limit has been reached, silently ignore the problem
            return;
        }
        for (AddressListEntry ale : list)
        {
            if (ale.isRoleRef())
            {
                String roleName = ale.getInitialId();
                NGRole role = ngp.getRole(roleName);
                //silently ignore invalid role references - no users in nonexistent role
                if (role!=null)
                {
                    List<AddressListEntry> nextLevel = role.getDirectPlayers();
                    expandRoles(result, ngp, nextLevel, loopLimiter);
                }
            }
            else
            {
                //only add an entry if it is not already in the result list
                boolean found = false;
                for (AddressListEntry listEntry : result)
                {
                    if (listEntry.equals(ale))
                    {
                        found=true;
                    }
                }
                if (!found)
                {
                    result.add(ale);
                }
            }
        }
    }



    public List<AddressListEntry> getMatchedFragment(String frag)throws Exception {
        List<AddressListEntry> result = new ArrayList<AddressListEntry>();
        for (AddressListEntry ale : getDirectPlayers()) {
            if(ale.hasAddressMatchingFrag(frag)) {
                result.add(ale);
            }
        }
        return result;
    }

    public void countIdentifiersInRole(StringCounter sc) {
        for (String id : getVector("member")) {
            sc.increment(id);
        }
    }

    public boolean replaceId(String sourceId, String destId) {
        List<String> players = getVector("member");
        boolean foundOne=false;
        for (String playerId : players) {
            if (playerId.equalsIgnoreCase(sourceId)) {
                foundOne = true;
            }
        }
        if (!foundOne) {
            return false;
        }
        List<String> newPlayers =  new ArrayList<String>();
        newPlayers.add(destId);
        foundOne=false;
        for (String playerId : players) {
            if (!playerId.equalsIgnoreCase(sourceId)
                && !playerId.equalsIgnoreCase(destId)) {
                newPlayers.add(playerId);
            }
        }
        setVector("member", newPlayers);
        return true;
    }

    public List<RoleTerm> getAllTerms() throws Exception {
        List<RoleTerm> list= this.getChildren("terms", RoleTerm.class);
        return list;
    }

    /**
     * getJSON is for normal lists of roles, the current players, and such.
     * Does not include all the historical detail.
     */
    public JSONObject getJSON() throws Exception {
        JSONObject jObj = new JSONObject();
        jObj.put("symbol", getSymbol());
        jObj.put("name", getName());
        extractAttributeString(jObj, "color");
        extractAttributeString(jObj, "linkedRole");
        RoleTerm curTerm = this.getCurrentTerm();
        if (curTerm!=null) {
            jObj.put("currentTerm", curTerm.getKey());
        }
        else {
            jObj.put("currentTerm", "");
        }
        jObj.put("description", getDescription());
        jObj.put("requirements", getRequirements());
        Set<String> uniquenessEnforcer = new HashSet<String>();
        JSONArray playerArray = new JSONArray();
        for (AddressListEntry player : getDirectPlayers()) {
            String uniqueId = player.getUniversalId();
            if (uniqueId==null || uniqueId.length()==0) {
                //should not be any of these, but ignore any member without a unique global id
                continue;
            }
            if (uniquenessEnforcer.contains(uniqueId)) {
                //each member should be in the set only once.  There was some cases where this
                //was somehow happening, maybe people changing name, or whatever, so always
                //enforce uniqueness in the output list.
                continue;
            }
            uniquenessEnforcer.add(uniqueId);
            playerArray.put( player.getJSON() );
        }
        jObj.put("players", playerArray);
        
        //this does some special things for Members and Stewards
        jObj.put("canUpdateWorkspace", allowUpdateWorkspace());
        jObj.put("canAccessWorkspace", allowAccessWorkspace());

        jObj.put("def", def.getJSON());

        return jObj;
    }
    /**
     * Includes all the current info, and
     * also the terms (historical) and data around
     * what has happened with the role in the past and future.
     */
    public JSONObject getJSONDetail() throws Exception {
        JSONObject jObj = getJSON();
        jObj.put("perpetual", this.getAttributeBool("perpetual"));
        extractAttributeInt(jObj, "termLength");

        List<RoleTerm> allTerms = getAllTerms();
        JSONArray termArray = new JSONArray();
        for (RoleTerm rt : allTerms) {
            termArray.put(rt.getJSON());
        }
        jObj.put("terms", termArray);

        List<Responsibility> resplist= this.getChildren("responsibilities", Responsibility.class);
        JSONArray respArray = new JSONArray();
        for (Responsibility res : resplist) {
            respArray.put(res.getJSON());
        }
        jObj.put("responsibilities", respArray);

        return jObj;
    }
    public void updateFromJSON(JSONObject roleInfo) throws Exception {
        updateAttributeString("color", roleInfo);
        updateAttributeString("linkedRole", roleInfo);
        updateAttributeInt("termLength", roleInfo);

        if (roleInfo.has("players")) {
            clear();
            JSONArray playerArray = roleInfo.getJSONArray("players");
            for (JSONObject addr : playerArray.getJSONObjectList()) {
                AddressListEntry newMember = AddressListEntry.fromJSON(addr);
                this.addPlayer(newMember);
            }
        }
        if (roleInfo.has("addPlayers")) {
            JSONArray playerArray = roleInfo.getJSONArray("addPlayers");
            for (JSONObject addr : playerArray.getJSONObjectList()) {
                AddressListEntry newMember = AddressListEntry.fromJSON(addr);
                this.addPlayer(newMember);
            }
        }
        if (roleInfo.has("removePlayers")) {
            JSONArray playerArray = roleInfo.getJSONArray("removePlayers");
            for (JSONObject addr : playerArray.getJSONObjectList()) {
                AddressListEntry oldMember = AddressListEntry.fromJSON(addr);
                this.removePlayer(oldMember);
            }
        }
        updateCollection(roleInfo, "responsibilities", Responsibility.class,  "key");
        updateCollection(roleInfo, "terms",            RoleTerm.class,  "key");
    }
    
    public boolean allowAccessWorkspace() {
        if (def == null) {
            return false;
        }
        return !def.onlyMail;
    }
    public boolean allowUpdateWorkspace() {
        if (def == null) {
            return false;
        }
        return !def.onlyMail && def.canEdit;
    }

}
