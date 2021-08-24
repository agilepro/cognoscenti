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

import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;

/**
* A role may have many terms, and they will be played
* by different people each term.  A term will have a
* specific start date, and end date.
* Some roles will not have terms, and they are perpetual
* meaning that the same person holds them forever.
* Old terms become a kind of history behind who
* has played the role in the past.
* 
* Terms have a complete cycle around selecting people
* to play a particular term of a particular role.
* 
* JSON Members:
* 
* key: this is an arbitrary (unique) key
* 
* state: Nominating, Proposing, Completed
* 
* termStart: TimeStamp for the beginning of the term
* 
* termEnd: TimeStamp for the end of the term
* 
* players: a list of people assigned to this term
* 
* nominations: a list of RoleNomination objects, key=owner
* 
* responses: a list of RoleNomResponse objects, key=owner
*/
public class RoleTerm extends DOMFace {

    public RoleTerm(Document doc, Element ele, DOMFace p) {
        super(doc, ele, p);
    }

    public String getKey() {
        return getAttribute("key");
    }
    /**
     * Note, this is the 'key',
     * so don't change it if you have references elsewhere.
     */
    public void setKey(String newKey) {
        setAttribute("key", newKey);
    }

    public List<AddressListEntry> getDirectPlayers() throws Exception {
        ArrayList<AddressListEntry> playerList = new ArrayList<AddressListEntry>();
        List<String> players = getVector("players");
        for (String player : players) {
            AddressListEntry ale = new AddressListEntry(player);
            if (ale.isWellFormed()) {
                playerList.add(ale);
            }
        }
        return playerList;
    }
    public void addPlayer(AddressListEntry newMember) throws Exception {
        addVectorValue("players", newMember.getStorageRepresentation());
    }
    public void removePlayer(AddressListEntry oldMember) throws Exception {
        String whichId = oldMember.getStorageRepresentation();
        UserProfile up = oldMember.getUserProfile();
        if (up!=null) {
            whichId = CustomRole.whichIDForUserOfAddressList(up, getDirectPlayers());
        }
        removeVectorValue("players", whichId);
    }
    public void removePlayerCompletely(UserRef user) throws Exception {
        List<String> oldPlayers = getVector("players");
        List<String> newPlayers = new ArrayList<String>();
        for (String memberID : oldPlayers) {
            if (!user.hasAnyId(memberID)) {
                newPlayers.add(memberID);
            }
        }
        this.setVector("players", newPlayers);
    }
    public void clear() {
        clearVector("players");
    }
    public boolean isComplete() {
        String state = this.getAttribute("state");
        return "Completed".equals(state);
    }
    public boolean includesDate(long testDate) {
        long termStart = getAttributeLong("termStart");
        long termEnd = getAttributeLong("termEnd");
        return (testDate >= termStart && testDate < termEnd);
    }
    
    
    public JSONObject getJSON() throws Exception {
        JSONObject jObj = new JSONObject();
        extractAttributeString(jObj, "key");
        extractAttributeString(jObj, "state");
        extractAttributeLong(jObj, "termStart");
        extractAttributeLong(jObj, "termEnd");
        
        JSONArray playerArray = new JSONArray();
        List<String> players = getVector("players");
        for (String player : players) {
            AddressListEntry ale = new AddressListEntry(player);
            if (ale.isWellFormed()) {
                playerArray.put(ale.getJSON());
            }
        }
        jObj.put("players", playerArray);
        
        extractCollection(jObj, "nominations", RoleNomination.class);
        extractCollection(jObj, "responses", RoleNomResponse.class);
        return jObj;
    }
    public void updateFromJSON(JSONObject termInfo) throws Exception {
        updateAttributeString("state", termInfo);
        updateAttributeLong("termStart", termInfo);
        updateAttributeLong("termEnd", termInfo);
        
        if (termInfo.has("players")) {
            JSONArray playerArray = termInfo.getJSONArray("players");
            List<String> players = AddressListEntry.uidListfromJSONArray(playerArray);
            this.setVector("players", players);
        }
        
        updateCollection(termInfo, "nominations", RoleNomination.class, "owner");
        updateCollection(termInfo, "responses", RoleNomResponse.class, "owner");
    }
}
