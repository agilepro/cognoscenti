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

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import com.purplehillsbooks.weaver.exception.ProgramLogicError;
import org.w3c.dom.Document;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;

/**
* Holds extra information for a particular user.
* file name is "XXXXXXXXX.user" where the XXXXXXXX represents the
* users internal unique key.
*/
public class UserPage extends ContainerCommon
{
    private UserInfoRecord userInfo;
    private String    key;
    private List<String> existingIds = null;

    private DOMFace statusReps = null;
    private List<StatusReport> statusRepList = null;
    private DOMFace profileRefs = null;
    private List<ProfileRef> profileList = null;


    public UserPage(File file, Document newDoc, String userKey)
        throws Exception
    {
        super(file, newDoc);
        key = userKey;
        userInfo = requireChild("info", UserInfoRecord.class);


        //There is a special user page for ANONYMOUS_REQUESTS which has
        //no associated profile.  The code below should not be executed
        //for the anonymous requests user page.
        UserProfile user = UserManager.getUserProfileByKey(userKey);
        if (user!=null)
        {
            //make sure the two required roles exist
            NGRole principal = getRole("Principal");
            if (principal==null)
            {
                //this is the primary role
                principal = createRole("Principal", "The owner of this profile");
                principal.addPlayer(new AddressListEntry(user));
            }
            NGRole coll = getRole("Colleagues");
            if (coll==null)
            {
                //this is the secondary role
                coll = createRole("Colleagues", "People who work together with this person.");
            }
        }
    }

    public void schemaUpgrade(int fromLevel, int toLevel) throws Exception {
        //nothing to do.....
    }
    public int currentSchemaVersion() {
        return 51;
    }


    public void saveUserPage(AuthRequest ar, String comment) throws Exception {
        setLastModify(ar);
        save();
    }

    private void setLastModify(AuthRequest ar) {
        userInfo.setModTime(ar.nowTime);
        userInfo.setModUser(ar.getBestUserId());
    }

    public String getKey()
    {
        return key;
    }


    /**
    * Get a four digit numeric id which is unique on the page.
    */
    public String getUniqueOnPage() throws Exception {
        if (existingIds == null) {
            existingIds = new ArrayList<String>();

            // walk through all sections and find current ids
            for (StatusReport stat : getStatusReports()) {
                existingIds.add(stat.getId());
            }
        }
        return IdGenerator.generateFourDigit(existingIds);
    }


    protected DOMFace getRoleParent() throws Exception {
        return requireChild("roleList", DOMFace.class);
    }

    protected DOMFace getInfoParent() throws Exception {
        return requireChild("pageInfo", DOMFace.class);
    }


    public NGRole getPrimaryRole() throws Exception {
        return getRoleOrFail("Principal");
    }
    public NGRole getSecondaryRole() throws Exception {
        return getRoleOrFail("Colleagues");
    }


    public void saveContent(AuthRequest ar, String comment)  throws Exception
    {
        throw new ProgramLogicError("saveContent not implemented on UserPage");
    }
    public  String getFullName()
    {
        throw new RuntimeException("getFullName not implemented on UserPage");
    }
    public boolean isDeleted()
    {
        throw new RuntimeException("isDeleted not implemented on UserPage");
    }
    public long getLastModifyTime()throws Exception {
        return userInfo.getModTime();
    }
    public List<String> getContainerNames()
    {
        throw new RuntimeException("getContainerNames not implemented on UserPage");
    }


    public String getTaskLink(AuthRequest ar, String taskId) throws Exception {
       throw new ProgramLogicError("Not Implemented");
    }


    public String getReminderLink(AuthRequest ar, String reminderId) throws Exception {
        throw new ProgramLogicError("Not Implemented");
    }



    public boolean isFrozen() throws Exception {
        return false;
    }

    public NGRole getContactsRole()throws Exception {

        NGRole role = getRole("Contacts");
        if(role == null){
            role = createRole("Contacts", "this is preferred list of user.");
        }
        return role;
    }


    public List<StatusReport> getStatusReports() throws Exception {

        if (statusReps==null) {
            statusReps = requireChild("StatusReps", DOMFace.class);
        }
        if (statusRepList==null) {
            statusRepList = statusReps.getChildren("StatusReport", StatusReport.class);
        }

        return statusRepList;
    }

    public StatusReport findStatusReportOrFail(String id) throws Exception {

        for (StatusReport stat : getStatusReports()) {
            if (id.equals(stat.getId())) {
                return stat;
            }
        }

        throw new JSONException("Unable to find a status report with id ({0})", id);
    }

    public StatusReport createStatusReport() throws Exception {

        if (statusReps==null) {
            statusReps = requireChild("StatusReps", DOMFace.class);
        }
        StatusReport newOne = statusReps.createChild("StatusReport", StatusReport.class);
        newOne.setId(getUniqueOnPage());
        return newOne;
    }

    public void deleteStatusReport(String id) throws Exception {
        StatusReport found = null;
        for (StatusReport stat : getStatusReports()) {
            if (id.equals(stat.getId())) {
                found = stat;
            }
        }
        if (found != null) {
            statusReps.removeChild(found);
            statusRepList.remove(found);
        }
    }

    public List<AddressListEntry> getExistingContacts() throws Exception{
        NGRole aRole  = getRole("Contacts");
        if(aRole != null){
            return aRole.getExpandedPlayers(this);
        }
        else{
            return new ArrayList<AddressListEntry>();
        }
    }

    public List<AddressListEntry> getPeopleYouMayKnowList() throws Exception{

        List<AddressListEntry> resultList = new ArrayList<AddressListEntry>();
        List <AddressListEntry> existingContacts = getExistingContacts();

        //TODO: this looks very suspicious.  It gets your contacts, and then it looks through
        // all of the user profiles, and gets the address list entry of the contct.
        // I can't tell if this does anything important or not.
        for (UserProfile userProfile : UserManager.getStaticUserManager().getAllUserProfiles()) {
            if(!CustomRole.isPlayerOfAddressList(userProfile, existingContacts)){
                resultList.add(new AddressListEntry(userProfile));
            }
        }

        //TODO: this does the same thing with the microprofile entries.
        //I don't understand why it needs to do this.
        List<AddressListEntry> microProfileIds = MicroProfileMgr.getAllProfileIds();
        for (AddressListEntry ale : microProfileIds) {
            if(!CustomRole.isPlayerOfAddressList(ale, existingContacts)){
                resultList.add(ale);
            }
        }

        return resultList;
    }

    public List<ProfileRef> getProfileRefs() throws Exception {
        if (profileRefs==null) {
            profileRefs = requireChild("ProfileRefs", DOMFace.class);
        }
        if (profileList==null) {
            profileList = profileRefs.getChildren("ProfileRef", ProfileRef.class);
        }
        return profileList;
    }

    public ProfileRef findOrCreateProfileRef(String address) throws Exception {

        for (ProfileRef tr : getProfileRefs()) {
            if (address.equals(tr.getAddress())) {
                return tr;
            }
        }

        ProfileRef newOne = profileRefs.createChild("ProfileRef", ProfileRef.class);
        newOne.setAddress(address);
        return newOne;
    }

    /**
     * Creates one if it does not already exist.
     * Throws as error if it exists.
     */
    public ProfileRef createProfileRefOrFail(String urlAddress) throws Exception {

        for (ProfileRef tr : getProfileRefs()) {
            if (urlAddress.equals(tr.getAddress())) {
                throw new JSONException("The reference address already exists: {0}", urlAddress);
            }
        }

        ProfileRef newOne = profileRefs.createChild("ProfileRef", ProfileRef.class);
        newOne.setAddress(urlAddress);
        return newOne;
    }

    public void deleteProfileRef(String urlAddress) throws Exception {

        ProfileRef found = null;
        for (ProfileRef tr : getProfileRefs()) {
            if (urlAddress.equals(tr.getAddress())) {
                found = tr;
            }
        }

        if (found != null) {
            profileRefs.removeChild(found);
            profileList.remove(found);
        }
    }



    // operation get task list.
    public static JSONArray getWorkListJSON(UserProfile up, Cognoscenti cog) throws Exception {

        NGPageIndex.assertNoLocksOnThread();
        if (up == null) {
            throw new JSONException("getTaskListJSON requires a UserProfile but got a null");
        }
        JSONArray list = new JSONArray();

        for (NGPageIndex ngpi : cog.getProjectsUserIsPartOf(up)) {

            if (!ngpi.isWorkspace() || ngpi.isDeleted) {
                continue;
            }
            NGWorkspace aWorkspace = ngpi.getWorkspace();
            if (aWorkspace.isDeleted() || aWorkspace.isFrozen()) {
                continue;
            }
            NGBook site = aWorkspace.getSite();
            if (site.isDeleted() || site.isMoved() || site.isFrozen()) {
                //ignore any workspaces in deleted, frozen, or moved sites.
                continue;
            }
            for (GoalRecord gr : aWorkspace.getAllGoals()) {

                if (gr.isPassive()) {
                    //ignore tasks that are from other servers.  They will be identified and tracked on
                    //those other servers
                    continue;
                }

                if (!gr.isAssignee(up)) {
                    continue;
                }

                list.put(gr.getJSON4Goal(aWorkspace));
            }
            // clean out any outstanding locks in every loop
            NGPageIndex.clearLocksHeldByThisThread();
       }

        return list;
    }


}
