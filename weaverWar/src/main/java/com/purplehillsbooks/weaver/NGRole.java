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

import java.util.List;

import com.purplehillsbooks.weaver.util.StringCounter;

/**
* Interface of all objects that define a role.
*
* A role is firstly a label.  It acts as a label in that things can be marked
* and it has the colors of label.  It ALSO has members.
*
* A role is a collection of address list entries which each represent either
* email addresses, openids, or user profiles.  In all cases, a unique representation
* of a particular user.  Users (Address List Entries) can be added or removed.
*
* There is no significance to the order of the users in the role.  New users will
* normally be added to the end of the list, but that is not guaranteed.  The order
* of the users is generally preserved, but that is not guaranteed either.
* When displaying a list of users, that list should be sorted for display in a
* particular order.
*
* A particular user is either a member or is not a member.
*
* NOTE: there is a special complication when it comes to users who have multiple
* global ids.  The role
*/
public interface NGRole extends NGLabel {
    /**
    * Symbol that all the users are saved under.  Not the same as the name.
    */
    public String getSymbol();

    /**
    * Display name of the role, suitable for display in user interface.
    */
    public String getName();
    public void setName(String name);

    /**
    * A standard html color value (string) which will be used when displaying
    * the name of this role.
    */
    public String getColor();
    public void setColor(String reqs);

    /**
    * Each role specifies whether the person is allowed to edit the contents 
    * of the workspace or not.   This is a least-permission mode, that is, 
    * if not specifically allowed, then the user becomes an read only
    * for this particular workspace.  
    * The user need be in only one role that allows edit, and they get 
    * edit capability.   They are read-only if none of their roles
    * allows edit.   
    * Also note: there is a global setting by the administrator
    * that specifies a user as a basic user for the entire site, and that
    * takes precidence.   Someone marked by admin as an basic can never edit 
    * anything on the site, can never play a role that allows update.
    */
    public boolean allowUpdateWorkspace();
    public void setUpdateWorkspace(boolean alllowed);

    /**
    * A description of the purpose of the role, suitable for display to user.
    */
    public String getDescription();
    public void setDescription(String desc);


    /**
    * This method recurses through all the role references, and retrieve
    * the entire list of direct and indirect players.
    */
    public List<AddressListEntry> getExpandedPlayers(NGContainer ngp) throws Exception;

    /**
    * This returns the list of direct players of this role, which can be
    * user references, or role references.
    */
    public List<AddressListEntry> getDirectPlayers() throws Exception;

    /**
    * Adds the specified user or role reference to be a direct member of this role
    */
    public void addPlayer(AddressListEntry newMember) throws Exception;

    /**
    * Removes the specified user or role reference if there is a direct member
    * of this role by that name.
    *
    * Note 1: that if the member was indirect, that is a member of a role referenced by this
    * role, the specified user will NOT be removed from the role, and the request
    * is silently ignored.
    *
    * Note 2: this removes exactly the address passed.  Since a user may have multiple
    * IDs, and because some IDs are case independent, you should first call whichIDForUser()
    * to find out the exact ID of a user, and then use that exact ID for the remove.
    */
    public void removePlayer(AddressListEntry oldMember) throws Exception;
    
    /**
    * Searches the role and removes all ids which belong to a particular user
    */
    public void removePlayerCompletely(UserRef user) throws Exception;

    /**
    * Remove all direct players of this role.
    */
    public void clear();

    public boolean isExpandedPlayer(UserRef user, NGContainer ngp) throws Exception;
    public boolean isPlayer(UserRef user)                          throws Exception;

    /**
    * A user with multiple IDs may be a member of this role on the
    * basis of any of the ids.  This method returns the first
    * id in the role that belongs to the specified user profile.
    * Returns null if the user is not a member of this role.
    */
    public String whichIDForUser(UserRef user) throws Exception;


    /**
    * A descriptive statement to the users about the requirements of becoming a
    * member of this role.  This will have whatever the users that set up the role
    * want, but it might include: required skills, required certifications,
    * a description of expected duties, how long to expect to wait for approval,
    * and whatever a person should know before attempting to join the role.
    */
    public String getRequirements();
    public void setRequirements(String reqs);

    public void addPlayerIfNotPresent(AddressListEntry member)throws Exception;
    public void addPlayersIfNotPresent(List<AddressListEntry> addressList)throws Exception;

    public List<AddressListEntry> getMatchedFragment(String frag)throws Exception;

    /**
     * This is a maintenance method.  When one person leaves the scene, the owner of the
     * site may wish to move all of their assignments (of any kind) to another user.
     * It may also be that a user has changed their email address, and wants to update
     * all the locations of the old address to the new address.   This function accomplished
     * that on a role, but note that it works on the "id" level (email address) and not the
     * user level, since one user might have both addresses.
     * @param sourceId the email address that you are looking for.  If this address is
     *      not found in the Role then this method does nothing.  If this is found multiple
     *      times, all instances of the address will be removed.
     * @param destId the email address that the sourceId is to be replaced with.  If this
     *      destId is already in the role it should take care not to duplicate it.
     * @return true if at least one sourceId was removed from the role.
     *      Return false if no instances of the source were found
     */
    public boolean replaceId(String sourceId, String destId);

    public void countIdentifiersInRole(StringCounter sc);

}
