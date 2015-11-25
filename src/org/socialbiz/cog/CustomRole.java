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

import org.socialbiz.cog.exception.ProgramLogicError;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;

/**
* A custom role is defined by the users on a project, but
* defining a name, and associated users with it.
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

    public List<AddressListEntry> getDirectPlayers() throws Exception
    {
        List<AddressListEntry> list=new ArrayList<AddressListEntry>();
        List<String> members = getVector("member");
        for (String memberID : members)
        {
            list.add(AddressListEntry.newEntryFromStorage(memberID));
        }
        return list;
    }
    public void addPlayer(AddressListEntry newMember) throws Exception
    {
        addVectorValue("member", newMember.getStorageRepresentation());
    }
    public void removePlayer(AddressListEntry oldMember) throws Exception
    {
        String whichId = oldMember.getStorageRepresentation();
        UserProfile up = oldMember.getUserProfile();
        if (up!=null) {
            whichId = whichIDForUser(up);
        }
        removeVectorValue("member", whichId);
    }
    public void clear()
    {
        clearVector("member");
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
        for (AddressListEntry one : getDirectPlayers())
        {
            if (one.equals(newMember))
            {
                return;
            }
        }
        if(newMember.getUserProfile() == null){
            MicroProfileMgr.findOrCreateMicroProfile(newMember.getUniversalId(), newMember.getNamePart());
            MicroProfileMgr.save();
        }
        addPlayer(newMember);
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

    public JSONObject getJSON() throws Exception {
        JSONObject jObj = new JSONObject();
        jObj.put("name", getName());
        jObj.put("color", getColor());
        jObj.put("description", getDescription());
        jObj.put("requirements", getRequirements());
        JSONArray shortList = new JSONArray();
        for (AddressListEntry player : getDirectPlayers()) {
            shortList.put( player.getJSON() );
        }
        jObj.put("players", shortList);
        //shortList = new JSONArray();
        //for (AddressListEntry player : getExpandedPlayers(ngp)) {
        //    shortList.put( player.getJSON() );
        //}
        //jObj.put("expandedPlayers", shortList);
        return jObj;
    }
    public void updateFromJSON(JSONObject roleInfo) throws Exception {
        if (roleInfo.has("color")) {
            setColor(roleInfo.getString("color"));
        }
        if (roleInfo.has("description")) {
            setDescription(roleInfo.getString("description"));
        }
        if (roleInfo.has("requirements")) {
            setRequirements(roleInfo.getString("requirements"));
        }
        if (roleInfo.has("players")) {
            clear();
            JSONArray players = roleInfo.getJSONArray("players");
            int last = players.length();
            for (int i=0; i<last; i++) {
                JSONObject addr = players.getJSONObject(i);
                this.addPlayer(AddressListEntry.fromJSON(addr));
            }
        }
    }
}
