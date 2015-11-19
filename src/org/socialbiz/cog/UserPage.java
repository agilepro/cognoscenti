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

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

import org.socialbiz.cog.dms.ConnectionSettings;
import org.socialbiz.cog.dms.ConnectionType;
import org.socialbiz.cog.dms.PublicWebAccess;
import org.socialbiz.cog.dms.ResourceEntity;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.w3c.dom.Document;
import org.workcast.json.JSONArray;

/**
* Holds extra information for a particular user.
* file name is "XXXXXXXXX.user" where the XXXXXXXX represents the
* users internal unique key.
*/
public class UserPage extends ContainerCommon
{
    private UserInfoRecord userInfo;
    private String    key;
    private Vector<String> existingIds = null;

    private DOMFace taskRefs = null;
    private List<RemoteGoal> userTaskRefs = null;
    private DOMFace statusReps = null;
    private List<StatusReport> statusRepList = null;
    private DOMFace profileRefs = null;
    private List<ProfileRef> profileList = null;
    private DOMFace agentRules = null;
    private List<AgentRule> agentList = null;


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


    public void saveUserPage(AuthRequest ar, String comment) throws Exception {
        saveFile(ar,comment);
    }

    public void saveFile(AuthRequest ar, String comment) throws Exception {
        setLastModify(ar);
        save();
    }


    public void setLastModify(AuthRequest ar)
    {
        userInfo.setModTime(ar.nowTime);
        userInfo.setModUser(ar.getBestUserId());
    }

    public String getKey()
    {
        return key;
    }



    /**
    * Returns a Vector of key values (Strings) for pages.
    * No guarantee that that page still exists.
    */
    public Vector<String> getProjectTemplates()
        throws Exception
    {
        Vector<String> nl = getVector("template");
        return nl;
    }
    public void addProjectTemplate(String pageKey)
        throws Exception
    {
        addVectorValue("template", pageKey);
    }
    public void removeProjectTemplate(String pageKey)
        throws Exception
    {
        removeVectorValue("template", pageKey);
    }

    public boolean inProjectTemplates(String pageKey) throws Exception {
        for (String val : getProjectTemplates()) {
            if (pageKey.equals(val)) {
                return true;
            }
        }
        return false;
    }

    public Vector<TaskTemplate> getTaskTemplates()
        throws Exception
    {
        Vector<TaskTemplate> nl = getChildren("task", TaskTemplate.class);
        return nl;
    }

    public TaskTemplate createTaskTemplate()
        throws Exception
    {
        TaskTemplate tt = createChildWithID("task",
                TaskTemplate.class, "id", getUniqueOnPage());
        return tt;
    }

    public void removeTaskTemplate(String id) throws Exception {
        Vector<TaskTemplate> nl = getChildren("task", TaskTemplate.class);
        for (TaskTemplate tEle : nl) {
            if (id.equals(tEle.getAttribute("id"))) {
                removeChild(tEle);
            }
        }
    }


    /**
    * Get a four digit numeric id which is unique on the page.
    */
    public String getUniqueOnPage() throws Exception {
        if (existingIds == null) {
            existingIds = new Vector<String>();

            // walk through all sections and find current ids
            for (StatusReport stat : getStatusReports()) {
                existingIds.add(stat.getId());
            }
            for (ConnectionSettings cs : getAllConnectionSettings()) {
                existingIds.add(cs.getId());
            }
            for (TaskTemplate tt : getTaskTemplates()) {
                existingIds.add(tt.getId());
            }
            for (AgentRule ar : getAgentRules()) {
                existingIds.add(ar.getId());
            }
        }
        return IdGenerator.generateFourDigit(existingIds);
    }





    protected DOMFace getAttachmentParent() throws Exception {
        return requireChild("attachments", DOMFace.class);
    }

    protected DOMFace getNoteParent() throws Exception {
        return requireChild("notes", DOMFace.class);
    }

    protected DOMFace getRoleParent() throws Exception {
        return requireChild("roleList", DOMFace.class);
    }

    protected DOMFace getHistoryParent() throws Exception {
        return requireChild("history", DOMFace.class);
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


    public List<RoleRequestRecord> getAllRoleRequestByState(String state, boolean completedReq) throws Exception
    {
        throw new ProgramLogicError("getAllRoleRequestByState not implemented on UserPage");
    }
    public RoleRequestRecord getRoleRequestRecordById(String requestId)throws Exception
    {
        throw new ProgramLogicError("getAllRoleRequest not implemented on UserPage");
    }
    public List<RoleRequestRecord> getAllRoleRequest() throws Exception
    {
        throw new ProgramLogicError("getAllRoleRequest not implemented on UserPage");
    }
    public RoleRequestRecord createRoleRequest(String roleName, String requestedBy,
        long modifiedDate, String modifiedBy, String requestDescription) throws Exception
    {
        throw new ProgramLogicError("createRoleRequest not implemented on UserPage");
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
    public String[] getContainerNames()
    {
        throw new RuntimeException("getContainerNames not implemented on UserPage");
    }
    public ReminderMgr getReminderMgr() throws Exception
    {
        throw new ProgramLogicError("getReminderMgr not implemented on UserPage");
    }


    public String getNoteLink(AuthRequest ar, String noteId) throws Exception {
        throw new ProgramLogicError("Not Implemented");
    }


    public String getTaskLink(AuthRequest ar, String taskId) throws Exception {
       throw new ProgramLogicError("Not Implemented");
    }


    public String getDocumentLink(AuthRequest ar, String documentId)
            throws Exception {
        throw new ProgramLogicError("Not Implemented");
    }


    public String getReminderLink(AuthRequest ar, String reminderId)
            throws Exception {
        throw new ProgramLogicError("Not Implemented");
    }


    public void setContainerNames(String[] nameSet) {
        throw new ProgramLogicError("You can not set the container names of a user page");
    }

    public ConnectionSettings createConnectionSettings()throws Exception
    {
        ConnectionSettings cSet = createChildWithID("folder",
                ConnectionSettings.class, ConnectionSettings.ATT_ID, getUniqueOnPage());
        cSet.setOwnerKey(key);  //TODO: this should be internal/automatic
        return cSet;
    }

    public Vector<ConnectionSettings> getAllConnectionSettings()throws Exception
    {
         return getChildren("folder", ConnectionSettings.class);
    }

    public ConnectionSettings getConnectionSettingsOrNull(String id)throws Exception
    {
        for (ConnectionSettings oneConnSet : getAllConnectionSettings())
        {
            if (id.equals(oneConnSet.getId()))
            {
                oneConnSet.setOwnerKey(key);  //TODO: this should be internal/automatic
                return oneConnSet;
            }
        }
        return null;
    }

    public ConnectionSettings getConnectionSettingsOrFail(String id)throws Exception
    {
        ConnectionSettings oneConnSet = getConnectionSettingsOrNull(id);
        if(oneConnSet == null)
        {
            throw new NGException("nugen.exception.no.con.for.user", new Object[]{key,id});
        }
        return oneConnSet;
    }

    public void removeConnection(String id)throws Exception
    {
        ConnectionSettings targetConnection = getConnectionSettingsOrNull(id);
        if (targetConnection!=null)
        {
            removeChild(targetConnection);
            return;
        }
        //should it throw an exception here?  Hard to say
        //for now, any request to delete a folder not there is ignored
    }



    public ConnectionType getConnectionOrNull(String id) throws Exception
    {
        //Public Web Access connection type is created automatically on demand
        //every user has one
        if ("PUBLIC".equals(id)) {
            return new PublicWebAccess(key);
        }
        ConnectionSettings targetConnection = getConnectionSettingsOrNull(id);
        if (targetConnection ==  null) {
            return null;
        }
        return targetConnection.getConnectionOrNull();
    }

    public ConnectionType getConnectionOrFail(String id) throws Exception
    {
        ConnectionType found = getConnectionOrNull(id);
        if (found == null) {
            throw new ProgramLogicError("Unable to find a connection with id = " + id + ", for user "+key);
        }
        return found;
    }


    /**
    * links to resources are stored using a combination
    *    {connection id}{relative path}
    *
    * the relative path ALWAYS starts with a slash.  This method returns the
    * ResourceEntity that represents that remote file (which may not exist.
    * Throws an exception if the connection does not exist, or is deleted.
    */
    public ResourceEntity getResourceFromSymbol(String symbolicLink) throws Exception
    {
        int slashPos = symbolicLink.indexOf("/");
        if (slashPos==0) {
            throw new ProgramLogicError("symbolic link can not begin with a slash ("+symbolicLink+")");
        }
        if (slashPos<0) {
            //special handling for no slash.  The slash at the end of a folder is optional.
            //thus the path of empty string is the same as path of single slash
            //so this code replaces an empty string path (just an ID) with a slash
            //because I am not sure at this moment that an empty string will work.
            return getResource(symbolicLink, "/");
        }
        String connId = symbolicLink.substring(0,slashPos);
        String relPath = symbolicLink.substring(slashPos);
        return getResource(connId, relPath);
    }

    /**
    * Given a combo link of the form   {userKey} @ {connId} {subpath}
    * this will find the remote resource, and return a ResourceEntity that
    * represents it.
    *
    * Throws exceptions if the combo link is not correctly formed.
    */
    public static ResourceEntity getResourceFromCombo(String comboLink) throws Exception
    {
        int atPos = comboLink.indexOf("@");
        if (atPos<0) {
            throw new ProgramLogicError("Can not get remote resource because there is no @ in the combo link: ("+comboLink+")");
        }
        String userKey = comboLink.substring(0,atPos);
        String symbol = comboLink.substring(atPos+1);
        UserPage uPage = UserManager.findOrCreateUserPage(userKey);
        return uPage.getResourceFromSymbol(symbol);
    }

    /**
    * returns a ResourceEntity that represents the remote file/folder given
    * a connection id and a relative path within that connection.
    * Throws an exception if the connection does not exist, or is deleted.
    */
    public ResourceEntity getResource(String connId, String relPath) throws Exception
    {
        ConnectionType cType = getConnectionOrFail(connId);
        return cType.getResourceInternal(relPath);
    }

    /**
    * returns a ResourceEntity that represents the remote file/folder given
    * a connection id and a relative path within that connection.
    * Throws an exception if the connection does not exist, or is deleted.
    */
    public ResourceEntity getResourceFromFullpath(String connId, String fullPath) throws Exception
    {
        ConnectionType cType = getConnectionOrFail(connId);
        return cType.getResource(fullPath);
    }

    /**
     * returns a ResourceEntity that represents the remote file/folder given
     * a connection id and a relative path within that connection.
     * Throws an exception if the connection does not exist, or is deleted.
     */
     public ResourceEntity getResourceOrNull(String connId, String relPath) throws Exception
     {
         ConnectionType cType = getConnectionOrNull(connId);
         if(cType==null){
             return null;
         }
         return cType.getResourceInternal(relPath);
     }

    public String getAllowPublic() throws Exception {
        return getAttribute("allowPublic");
    }


    public void setAllowPublic(String allowPublic) throws Exception {
        setAttribute("allowPublic", allowPublic);
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


    public void save(String modUser, long modTime, String comment, Cognoscenti cog)
            throws Exception {
        userInfo.setModTime(modTime);
        userInfo.setModUser(modUser);

        //TODO: save the comment someplace ... a history capability?
        save();
    }

    public List<RemoteGoal> getRemoteGoals() throws Exception {

        if (taskRefs==null) {
            taskRefs = requireChild("TaskRefs", DOMFace.class);
        }
        if (userTaskRefs==null) {
            userTaskRefs = taskRefs.getChildren("Task", RemoteGoal.class);
            RemoteGoal.sortTasksByRank(userTaskRefs);
        }

        return userTaskRefs;
    }

    public RemoteGoal findOrCreateTask(String projectKey, String id) throws Exception {

        for (RemoteGoal tr : getRemoteGoals()) {
            if (projectKey.equals(tr.getProjectKey()) && id.equals(tr.getId())) {
                return tr;
            }
        }

        RemoteGoal newOne = taskRefs.createChild("Task", RemoteGoal.class);
        newOne.setProjectKey(projectKey);
        newOne.setId(id);
        return newOne;

    }

    public RemoteGoal findRemoteGoal(String key) throws Exception {

        for (RemoteGoal tr : getRemoteGoals()) {
            if (key.equals(tr.getUniversalId())) {
                return tr;
            }
            if (key.equals(tr.getAccessURL())) {
                return tr;
            }
        }
        return null;
    }

    public RemoteGoal findOrCreateRemoteGoal(String accessUrl) throws Exception {

        for (RemoteGoal tr : getRemoteGoals()) {
            if (accessUrl.equals(tr.getAccessURL())) {
                return tr;
            }
        }

        RemoteGoal newOne = taskRefs.createChild("Task", RemoteGoal.class);
        newOne.setAccessURL(accessUrl);
        return newOne;
    }

    public void deleteTask(String projectKey, String id) throws Exception {

        RemoteGoal found = null;
        for (RemoteGoal tr : getRemoteGoals()) {
            if (projectKey.equals(tr.getProjectKey()) && id.equals(tr.getId())) {
                found = tr;
            }
        }

        if (found != null) {
            taskRefs.removeChild(found);
            userTaskRefs.remove(found);
        }
    }

    public void clearTaskRefFlags() throws Exception {
        for (RemoteGoal tr : getRemoteGoals()) {
            tr.touchFlag = false;
        }
    }

    public void cleanUpTaskRanks() throws Exception {

        List<RemoteGoal> refs = getRemoteGoals();
        RemoteGoal.sortTasksByRank(refs);
        int count = 0;

        //first, renumber the ones that have a rank
        for (RemoteGoal tr : refs) {
            if (tr.getRank()>0) {
                tr.setRank(++count);
            }
        }
        //then number the unranked ones after the above
        for (RemoteGoal tr : refs) {
            if (tr.getRank()<=0) {
                tr.setRank(++count);
            }
        }
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

        throw new Exception("Unable to find a status report with id ("+id+")");
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
        UserProfile[] profiles = UserManager.getAllUserProfiles();
        for (UserProfile userProfile : profiles) {
            if(!CustomRole.isPlayerOfAddressList(userProfile, existingContacts)){
                resultList.add(new AddressListEntry(userProfile));
            }
        }

        //TODO: this does the same thing with the microprofile entries.
        //I don't understand why it needs to do this.
        Vector<AddressListEntry> microProfileIds = MicroProfileMgr.getAllProfileIds();
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
                throw new Exception("The reference address already exists: "+urlAddress);
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


    public List<AgentRule> getAgentRules() throws Exception {
        if (agentRules==null) {
            agentRules = requireChild("AgentRules", DOMFace.class);
        }
        if (agentList==null) {
            agentList = agentRules.getChildren("AgentRule", AgentRule.class);
        }
        return agentList;
    }
    public AgentRule createAgentRule() throws Exception {
        if (agentRules==null) {
            agentRules = requireChild("AgentRules", DOMFace.class);
        }
        agentList=null;
        AgentRule newOne = agentRules.createChild("AgentRule", AgentRule.class);
        newOne.setId(getUniqueOnPage());
        return newOne;
    }
    public AgentRule findAgentRule(String id) throws Exception {
        for (AgentRule ar : getAgentRules()) {
            if (id.equals(ar.getId())) {
                return ar;
            }
        }
        return null;
    }
    public void deleteAgentRule(String id) throws Exception {
        AgentRule found = findAgentRule(id);
        agentRules.removeChild(found);
    }

    public void purgeDeletedAttachments() throws Exception {
        throw new Exception("purgeDeletedAttachments should never be needed on User");
    }


    // operation get task list.
    public static JSONArray getWorkListJSON(UserProfile up, Cognoscenti cog) throws Exception {

        NGPageIndex.assertNoLocksOnThread();
        if (up == null) {
            throw new Exception("getTaskListJSON requires a UserProfile but got a null");
        }
        JSONArray list = new JSONArray();

        for (NGPageIndex ngpi : cog.getAllContainers()) {
            // start by clearing any outstanding locks in every loop
            NGPageIndex.clearLocksHeldByThisThread();

            if (!ngpi.isProject()) {
                continue;
            }
            NGPage aPage = ngpi.getPage();
            for (GoalRecord gr : aPage.getAllGoals()) {

                if (gr.isPassive()) {
                    //ignore tasks that are from other servers.  They will be identified and tracked on
                    //those other servers
                    continue;
                }

                if (!gr.isAssignee(up)) {
                    continue;
                }

                list.put(gr.getJSON4Goal(aPage));
            }
        }

        return list;
    }




}
