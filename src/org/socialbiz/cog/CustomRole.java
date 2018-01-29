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
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.socialbiz.cog.exception.ProgramLogicError;
import org.socialbiz.cog.util.StringCounter;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;

/**
* A custom role is defined by the users on a project, but
* defining a name, and associated users with it.
* 
* TODO: This class was designed around the idea that a role might contain
* other roles symbolically.  This has never really worked out ...
* it is too complicated for people to handle.  Should remove
* this capability to make this code simpler to use.
*/
public class CustomRole extends DOMFace implements NGRole
{

    public CustomRole(Document doc, Element ele, DOMFace p)
    {
        super(doc, ele, p);
    }

    public String getName()
    {
        return getScalar("rolename");
    }
    public void setName(String name)
    {
        if (name==null || name.length()==0) {
            throw new RuntimeException("A role can not be set to have an empty name.");
        }
        setScalar("rolename", name);
    }

    public String getDescription()
    {
        return getScalar("description");
    }
    public void setDescription(String desc)
    {
        setScalar("description", desc);
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
        RoleTerm term = getCurrentTerm();
        if (term==null) {
            addVectorValue("member", newMember.getStorageRepresentation());
        }
        else {
            term.addPlayer(newMember);
        }
    }
    public void removePlayer(AddressListEntry oldMember) throws Exception {
        RoleTerm term = getCurrentTerm();
        if (term==null) {
            String whichId = oldMember.getStorageRepresentation();
            UserProfile up = oldMember.getUserProfile();
            if (up!=null) {
                whichId = whichIDForUser(up);
            }
            removeVectorValue("member", whichId);
        }
        else {
            term.removePlayer(oldMember);
        }
    }
    public void removePlayerCompletely(UserRef user) throws Exception {
        RoleTerm term = getCurrentTerm();
        if (term!=null) {
            term.removePlayerCompletely(user);
        }
        else {
            List<String> oldPlayers = getVector("member");
            List<String> newPlayers = new ArrayList<String>();
            for (String memberID : oldPlayers) {
                if (!user.hasAnyId(memberID)) {
                    newPlayers.add(memberID);
                }
            }
            this.setVector("member", newPlayers);
        }
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
   

    public String getRequirements()
    {
        return getScalar("reqs");
    }
    public void setRequirements(String reqs)
    {
        setScalar("reqs", reqs);
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


    public static boolean isPlayerOfAddressList(UserRef user, List<AddressListEntry> list)
        throws Exception
    {
        if (user==null)
        {
            throw new ProgramLogicError("isPlayerOfAddressList called with null user object.");
        }
        for (AddressListEntry alr : list)
        {
            if (user.hasAnyId(alr.getInitialId()))
            {
                return true;
            }
        }
        return false;
    }
    static String whichIDForUserOfAddressList(UserRef uRef, List<AddressListEntry> list)
        throws Exception
    {
        for (AddressListEntry alr : list)
        {
            String thisID = alr.getInitialId();
            if (uRef.hasAnyId(thisID))
            {
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

    public void addPlayerIfNotPresent(AddressListEntry newMember) throws Exception {
        for (AddressListEntry one : getDirectPlayers()) {
            if (one.equals(newMember)) {
                return;
            }
        }
        if(newMember.getUserProfile() == null){
            MicroProfileMgr.findOrCreateMicroProfile(newMember.getUniversalId(), newMember.getNamePart());
            MicroProfileMgr.save();
        }
        addPlayer(newMember);
    }

    public void addPlayersIfNotPresent(List<AddressListEntry> addressList) throws Exception {
        for (AddressListEntry ale : addressList) {
            addPlayerIfNotPresent(ale);
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
        jObj.put("name", getName());
        extractAttributeString(jObj, "color");
        RoleTerm curTerm = this.getCurrentTerm();
        if (curTerm!=null) {
            jObj.put("currentTerm", curTerm.getKey());
        }
        else {
            jObj.put("currentTerm", "");
        }
        extractScalarString(jObj, "description");
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
        updateScalarString("description", roleInfo);
        updateAttributeInt("termLength", roleInfo);
        if (roleInfo.has("requirements")) {
            //internal key is not same as external
            setRequirements(roleInfo.getString("requirements"));
        }
        if (roleInfo.has("players")) {
            clear();
            JSONArray playerArray = roleInfo.getJSONArray("players");
            int last = playerArray.length();
            for (int i=0; i<last; i++) {
                JSONObject addr = playerArray.getJSONObject(i);
                AddressListEntry newMember = AddressListEntry.fromJSON(addr);
                this.addPlayer(newMember);
            }
        }
        updateCollection(roleInfo, "responsibilities", Responsibility.class,  "key");
        updateCollection(roleInfo, "terms",            RoleTerm.class,  "key");
    }
}
