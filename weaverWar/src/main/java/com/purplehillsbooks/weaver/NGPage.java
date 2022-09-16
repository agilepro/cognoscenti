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
import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.mail.EmailGenerator;
import com.purplehillsbooks.weaver.mail.EmailRecord;
import com.purplehillsbooks.weaver.util.LRUCache;
import com.purplehillsbooks.weaver.util.StringCounter;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;

/**
* NGPage is an abstract parent of a NGWorkspace.
* A Workspace is the main container of a workspace/circle/etc.
* "Page" is the old term, "Leaf" is also an old term, avoid these.
* The current term for the user interaction is "Workspace"
* This should all be moved into NGWorkspace to simplify.
*/
public abstract class NGPage extends ContainerCommon {

    public static final int ACCESS_STATE_LIVE = 1;
    public static final int ACCESS_STATE_FROZEN = 2;
    public static final int ACCESS_STATE_DELETED = 3;

    public static final String ACCESS_STATE_LIVE_STR = "Live";
    public static final String ACCESS_STATE_FROZEN_STR = "Frozen";
    public static final String ACCESS_STATE_DELETED_STR = "Deleted";

    protected PageInfoRecord pageInfo;
    private ReminderMgr reminderMgr;
    private ProcessRecord pageProcess;

    protected List<String> displayNames;
    protected List<NGSection> sectionElements = null;
    private NGBook prjSite;
    protected List<String> existingIds = null;

    NGSection attParent;
    NGSection noteParent;
    NGSection attachParent;
    NGSection taskParent;
    
    //Least Recently Used Cache .... keep copies of the last ten
    //page objects in memory for reuse
    protected static LRUCache pageCache = new LRUCache(10);


    protected NGPage(File theFile, Document newDoc, NGBook site) throws Exception {
        super(theFile, newDoc);

        if (!"ProjInfo.xml".equals(theFile.getName())) {
            throw new Exception("Programmer Logic Error: the only file that holds a page should be called ProjInfo.xml");
        }
        if (site==null) {
            throw new Exception("workspaces have to be created with a site object sent in now");
        }


        pageInfo = requireChild("pageInfo", PageInfoRecord.class);

        displayNames = pageInfo.getPageNames();

        prjSite = site;
        pageInfo.setSiteKey(site.getKey());
        

        attParent = getRequiredSection("Attachments");
        SectionAttachments.assureSchemaMigration(attParent, (NGWorkspace)this);


        noteParent   = getRequiredSection("Comments");
        attachParent = getRequiredSection("Attachments");
        taskParent   = getRequiredSection("Tasks");

        //initialization of pageProcess member variable
        pageProcess = taskParent.requireChild("process", ProcessRecord.class);
        if (pageProcess.getId() == null || pageProcess.getId().length() == 0)  {
            // default values
            pageProcess.setId(getUniqueOnPage());
            pageProcess.setState(BaseRecord.STATE_UNSTARTED);
        }

        //This is the ONLY place you should see these
        //deprecated sections, check to see if
        //there are any leaflets in there, and move them to the
        //main comments section.

        assertNoSectionWithThisName("Public Attachments");
        assertNoSectionWithThisName("Public Comments");
        assertNoSectionWithThisName("See Also");
        assertNoSectionWithThisName("Links");
        assertNoSectionWithThisName("Description");
        assertNoSectionWithThisName("Public Content");
        assertNoSectionWithThisName("Notes");
        assertNoSectionWithThisName("Author Notes");
        assertNoSectionWithThisName("Private");
        assertNoSectionWithThisName("Member Content");
        assertNoSectionWithThisName("Poll");
        assertNoSectionWithThisName("Geospatial");

        //migrate the old forms of members and admins roles to the new form
        //the old form was a "userlist" element, with "user" elements below that
        //with permissions PM, M, PA, and A.  Move those to the real "roles"
        //and eliminate the old userlist element.
        NGRole newMemberRole = getRequiredRole("Members");
        NGRole newAdminRole = getRequiredRole("Administrators");

        DOMFace userList = pageInfo.getChild("userlist", DOMFace.class);
        if (userList!=null)
        {
            List<DOMFace> users = userList.getChildren("user", DOMFace.class);
            for (DOMFace ele : users) {
                String id = ele.getAttribute("id");
                AddressListEntry user = AddressListEntry.newEntryFromStorage(id);
                String permis = ele.getAttribute("permission");
                if (permis.equals("M") || permis.equals("PA"))
                {
                    newMemberRole.addPlayer(user);
                }
                if (permis.equals("A"))
                {
                    newAdminRole.addPlayer(user);
                }
            }
            //now get rid of all former evidence.
            pageInfo.removeChildElement(userList.getElement());
        }

        //assure that other roles exist
        getRequiredRole("Notify");
        getRequiredRole("Facilitator");
        getRequiredRole("Circle Administrator");
        getRequiredRole("Operations Leader");
        getRequiredRole("Representative");
        getRequiredRole("External Expert");

        //refresh the roles from the site if linked
        for (CustomRole aRole : this.getAllRoles()) {
            String linkedRole = aRole.getLinkedRole();
            if (linkedRole!=null && linkedRole.length()>0) {
                String actualName = "~"+linkedRole;
                CustomRole linker = prjSite.getRole(actualName);
                if (linker!=null) {
                    //this is saved only if the page is saved for any other reason
                    aRole.updateFromJSON(linker.getJSON());
                    aRole.setLinkedRole(linkedRole);
                }
            }
        }
        
        
        //eliminate old meetings that were just backlog containers
        //added Dec 2021 cleanup schema migration
        for (MeetingRecord meet: getMeetings()) {
            if (meet.deprecatedBacklogMeetingNoLongerAllowed()) {
                this.removeMeeting(meet.getId());
            }
        }

    }

    //this is the NGPage version, and a different approach is used for NGProj
    protected void migrateKeyValue(File theFile) throws Exception {
        String fileName = theFile.getName();
        String fileKey = SectionUtil.sanitize(fileName.substring(0,fileName.length()-3));
        setKey(fileKey);
    }



    /**
    * Set all static values back to their initial states, so that
    * garbage collection can be done, and subsequently, the
    * class will be reinitialized.
    */
    public synchronized static void clearAllStaticVars() {
        pageCache.emptyCache();
    }

    /**
     * To an existing workspace, add all the (1) Action Items (2) Roles of an
     * existing workspace.
     * @param ar is needed to get the current logged in user and the current time
     * @param template is the workspace to get the ActionItems/Roles from
     */
    public void injectTemplate(AuthRequest ar, NGPage template)
        throws Exception
    {
        String bestId = ar.getBestUserId();

        //copy all of the tasks, but no status.
        for (GoalRecord templateGoal : template.getAllGoals()) {
            GoalRecord newGoal = createGoal(ar.getBestUserId());
            newGoal.setSynopsis(templateGoal.getSynopsis());
            newGoal.setDescription(templateGoal.getDescription());
            newGoal.setPriority(templateGoal.getPriority());
            newGoal.setDuration(templateGoal.getDuration());
            newGoal.setCreator(bestId);
            newGoal.setState(BaseRecord.STATE_UNSTARTED);
            newGoal.setRank(templateGoal.getRank());
            newGoal.setModifiedBy(bestId);
            newGoal.setModifiedDate(ar.nowTime);
        }

        //copy all of the roles - without the players
        for (NGRole role : template.getAllRoles()) {
            String roleName = role.getName();
            NGRole alreadyExisting = getRole(roleName);
            if (alreadyExisting==null) {
                createRole(roleName,role.getDescription());
            }
        }

    }

    /**
     * Clears the current page from the cache.
     * This is the global "rollback" function.  It does not undo any changes
     * but if this is called before discarding the reference to a page object,
     * and without saving that page, then
     * the next access to the page will be from the prior saved version of the page.
     * This method should be called whenever an exception is caught (at the root level)
     * so that any possible changes during processing before the exception is thrown away.
     */
    public static void removeCachedPage(File fullFilePath) {
        pageCache.unstore(fullFilePath);
    }


    //Override
    public void saveFile(AuthRequest ar, String comment) throws Exception {
        try {
            setLastModify(ar);
            saveWithoutMarkingModified(ar.getBestUserId(), comment, ar.getCogInstance());
        }
        catch (Exception e) {
            throw new NGException("nugen.exception.unable.to.write.file",
                    new Object[] { getFilePath().toString() }, e);
        }
    }

    //Added new method without using ar parameter to save contents (Need to discuss)
    //Override
    public void saveWithoutAuthenticatedUser(String modUser, long modTime, String comment, Cognoscenti cog) throws Exception
    {
        pageInfo.setModTime(modTime);
        pageInfo.setModUser(modUser);

        saveWithoutMarkingModified(modUser, comment, cog);
    }


    //This is for config changes, NOT content changes
    public void saveWithoutMarkingModified(String modUser, String comment, Cognoscenti cog) throws Exception
    {
        long thisThread = Thread.currentThread().getId();
        try {
            System.out.println("FILESAVE ("+getKey()+") tid="+thisThread+" by ("+modUser+") for ("+comment+")");
            save();

            //update the in memory index because the file has changed
            refreshOutboundLinks(cog);

            //Update blocking Queue
            NGPageIndex.postEventMsg(this.getKey());
            System.out.println("FILESAVE done ("+getKey()+") tid="+thisThread);
        }
        catch (Exception e) {
            throw new NGException("nugen.exception.unable.to.write.file",
                    new Object[]{getFilePath().toString()}, e);
        }
    }

    /**
     * This should be called everytime the page contents are changed in a way
     * that might effect the links on the page.
     */
    private void refreshOutboundLinks(Cognoscenti cog) throws Exception {
        String key = getKey();
        String siteKey = getSiteKey();
        NGPageIndex ngpi = cog.getWSBySiteAndKey(siteKey, key);
        if (ngpi == null) {
            throw new JSONException("unable to find a workspace with site ({0}) and key ({1})", siteKey, key);
        }
        ngpi.unlinkAll();
        ngpi.buildLinks(this);

        // check if there is new email, and put this in the index as well
        if (hasEmailToSend()) {
            cog.workspacesWithEmailToSend.add(key);
        }
    }
    public boolean hasEmailToSend() throws Exception {
        for (EmailRecord er : getAllEmail()) {
            if (er.statusReadyToSend()) {
                return true;
            }
            System.out.println("!!!!!!!\n\n\n\n~~~~~~~\n EMAIL FOUND IN Workspace: "+this.getCombinedKey());
        }
        return false;
    }


    public int getAccessState() {
        if (pageInfo.isDeleted()) {
            return ACCESS_STATE_DELETED;
        }
        else if (pageInfo.isFrozen()) {
            return ACCESS_STATE_FROZEN;
        }
        else {
            return ACCESS_STATE_LIVE;
        }
    }
    public String getAccessStateStr() {
        if (pageInfo.isDeleted()) {
            return ACCESS_STATE_DELETED_STR;
        }
        else if (pageInfo.isFrozen()) {
            return ACCESS_STATE_FROZEN_STR;
        }
        else {
            return ACCESS_STATE_LIVE_STR;
        }
    }

    public void setAccessState(AuthRequest ar, int newState) {
        int oldState = getAccessState();
        if (newState == oldState) {
            //don't do anything if there is no change
            return;
        }
        if (newState == ACCESS_STATE_DELETED) {
            if (oldState == ACCESS_STATE_LIVE) {
                freezeWorkspace(ar);
            }
            markDeleted(ar);
        }
        else if (newState == ACCESS_STATE_FROZEN) {
            if (oldState == ACCESS_STATE_DELETED) {
                markUnDeleted(ar);
            }
            else {
                freezeWorkspace(ar);
            }
        }
        else if (newState == ACCESS_STATE_LIVE) {
            if (oldState == ACCESS_STATE_DELETED) {
                markUnDeleted(ar);
            }
            unfreezeWorkspace();
        }
    }

    @Override
    public boolean isFrozen() {
        //every workspace in a frozen site is considered frozen
        if (prjSite.isDeleted()) {
            return true;
        }
        if (prjSite.isFrozen()) {
            return true;
        }
        return pageInfo.isFrozen();
    }
    private void freezeWorkspace(AuthRequest ar) {
        pageInfo.freezeWorkspace(ar);
    }

    /**
     * Will set the workspace into unfrozen mode, but only
     */
    private void unfreezeWorkspace() {
        if (!isDeleted()) {
            pageInfo.unfreezeWorkspace();
        }
    }


    /**
    * This will mark the page as deleted at the time of the request
    * and by the person in the request.
    */
    private void markDeleted(AuthRequest ar) {
        if (!pageInfo.isFrozen()) {
            freezeWorkspace(ar);
        }
        pageInfo.setDeleted(ar);
    }
    /**
    * This will unmark the page from being deleted, clearing any earlier
    * setting that the page was deleted
    */
    private void markUnDeleted(AuthRequest ar)
    {
        pageInfo.clearDeleted();
    }

    @Override
    public boolean isDeleted() {
        if (this.prjSite.isDeleted()) {
            return true;
        }
        return pageInfo.isDeleted();
    }

    /**
    * Get a section, creating it if it does not exist yet
    */
    private NGSection getRequiredSection(String secName) throws Exception {
        if (secName==null) {
            throw new RuntimeException("getRequiredSection was passed a null secName parameter.");
        }
        NGSection sec = internalScanForSection(secName);
        if (sec==null) {
            sec = createSection(secName, null);
            if (sec == null) {
                throw new Exception("Unable to create a section named: "+secName);
            }
            getAllSections().add(sec);
        }
        return sec;
    }
    /*
     * this scans the XML document for sections and returns them
     * this scanning ONLY happens at init time, and only for specific
     * allows section names
     */
    private NGSection internalScanForSection(String sectionNameToLookFor) throws Exception {
        for (NGSection sec : getChildren("section", NGSection.class)) {
            String thisName = sec.getName();
            if (thisName == null || thisName.length() == 0) {
                throw new NGException("nugen.exception.section.not.have.name", null);
            }
            if (sectionNameToLookFor.equals(thisName)) {
                return sec;
            }
        }
        return null;
    }
    private void assertNoSectionWithThisName(String name) throws Exception {
        Element found = null;
        for (Element ele : getNamedChildrenVector("section")) {
            if (name.equals(ele.getAttribute("name"))) {
                found = ele;
            }
        }
        if (found!=null) {
            fEle.removeChild(found);
        }
    }
    /**
    * To create a new, empty, section, call this method.
    */
    private NGSection createSection(String secName, AuthRequest ar) throws Exception {
        SectionDef sd = SectionDef.getDefByName(secName);
        if (sd==null) {
            throw new NGException("nugen.exception.no.section.with.given.name", new Object[]{secName});
        }
        return createSection(sd, ar);
    }


    
    
    /* 
     * this is the external one
     */
    public NGSection getSection(String sectionNameToLookFor) throws Exception {
        for (NGSection sec : sectionElements) {
            String thisName = sec.getName();
            if (sectionNameToLookFor.equals(thisName)) {
                return sec;
            }
        }
        return null;
    }
    public NGSection getSectionOrFail(String sectionNameToLookFor)
            throws Exception
        {
            NGSection ngs = getSection(sectionNameToLookFor);
            if (ngs==null)
            {
                throw new NGException("nugen.exception.unable.to.locate.section", new Object[]{sectionNameToLookFor,getKey()});
            }
            return ngs;
        }





    /**
    *  The AuthRequest object is needed to record the user and time
    * of modification.  In the situation that a required section is
    * missing (such as the Tasks section which is supposed to be created
    * at the moment the page is created, but there are some old pages
    * today without Tasks sections) then it does not really matter to
    * record who added this required section.  In that case, pass a null
    * in for the AuthRecord, and nothing will be recorded.
    */
    private NGSection createSection(SectionDef sd, AuthRequest ar) throws Exception {
        if (sd==null)
        {
            throw new RuntimeException("createSection was passed a null sd parameter");
        }
        //clear the cached vector, force regeneration in any case
        sectionElements = null;
        String secName = sd.getTypeName();
        List<NGSection> allSections = getChildren("section", NGSection.class);
        for (NGSection sec : allSections) {
            if (secName.equals(sec.getAttribute("name"))) {
                return sec;  //already created, why calling this?
            }
        }

        NGSection newSection = createChildWithID("section", NGSection.class, "name", secName);
        return newSection;
    }



    public List<NGSection> getAllSections() throws Exception {
        if (sectionElements==null) {
            //fetch it and cache it here
            sectionElements = getChildren("section", NGSection.class);
        }
        return sectionElements;
    }



    /**
    * This is the unique ID of the entire workspace
    * across all sites.  It is up to the system to
    * make sure this is created and maintained unique
    * and it must never be changed (or links will be
    * broken).  Linking should be by name if possible.
    */
    @Override
    public String getKey() {
        return pageInfo.getKey();
    }
    public void setKey(String newKey) {
        pageInfo.setKey(newKey);
    }
    /**
     * The combined key contains both the site key and the workspace key
     * @return
     */
    public String getCombinedKey() {
        return this.prjSite.getKey() + "|" + pageInfo.getKey();
    }

    /**
     * Returns the current full name of this page
     */
    @Override
    public String getFullName() {
        if (displayNames == null) {
            return "Uninitialized (displayNames is null)";
        }
        if (displayNames.size() == 0) {
            return "Uninitialized (displayNames contains zero items)";
        }
        return displayNames.get(0);
    }

    public List<String> getPageNames() {
        return displayNames;
    }

    public void setPageNames(List<String> newNames) {
        pageInfo.setPageNames(newNames);
        displayNames = pageInfo.getPageNames();
    }

    public void setNewName(String newName) {
        List<String> nameSet = new ArrayList<String>();

        //there used to be a set of names because this was supposed to ack like a wiki
        //and we wanted to preserve name-links that were old.
        //However, there are no name-links today, so there is nothing to preserve.
        //It is confusing to have to delete the OLD names, so changed this function
        //to simply replace the entire list of names, with the single new name.
        
        nameSet.add(newName);
        setPageNames(nameSet);
    }
    public void deleteOldName(String oldName) {
        List<String> nameSet = getPageNames();

        //there used to be a set of names because this was supposed to ack like a wiki
        //and we wanted to preserve name-links that were old.
        //However, there are no name-links today, so there is nothing to preserve.
        //It is confusing to have to delete the OLD names, so changed this function
        //to simply replace the entire list of names, with the single new name.
        //
        //This function need consider only the first name, and if the name to delete 
        //is not that name, just delete all except the first.
        //If there is NO names, then just make the one to delete be the only name.
        //This function should be deprecated.
        
        if (nameSet.size()>1) {
            String firstName = nameSet.get(0);
            setNewName(firstName);
        }
        else {
            setNewName(oldName);
        }
    }


    public void findLinks(List<String> v) throws Exception {
        for (NGSection sec : getAllSections()) {
            sec.findLinks(v);
        }
    }

    public void findTags(List<String> v) throws Exception {
        //Tags not implemented any more
    }


    @Override
    public long getLastModifyTime()
        throws Exception
    {
        long timeAttrib = pageInfo.getModTime();
        if (timeAttrib>0)
        {
            return timeAttrib;
        }

        //currently we have a lot of pages without last modified set, so when it
        //finds that the case, search through the sections, and find the latest
        //section modification.  This code can be removed once all the existing
        //pages get edited and upgraded.
        long latestSecTime = 0;
        for (NGSection sec : getAllSections())
        {
            long secTime = sec.getLastModifyTime();
            if (secTime>latestSecTime)
            {
                latestSecTime = secTime;
            }
        }
        return latestSecTime;
    }

    public String getLastModifyUser()
        throws Exception
    {
        String modUser = pageInfo.getModUser();
        if (modUser!=null)
        {
            return modUser;
        }

        //currently we have a lot of pages without last modified set, so when it
        //finds that the case, search through the sections, and find the latest
        //section modification.  This code can be removed once all the existing
        //pages get edited and upgraded.
        long latestSecTime = 0;
        for (NGSection sec : getAllSections())
        {
            long secTime = sec.getLastModifyTime();
            if (secTime>latestSecTime)
            {
                latestSecTime = secTime;
                modUser = sec.getLastModifyUser();
            }
        }
        return modUser;
     }

    public void setLastModify(AuthRequest ar)
        throws Exception
    {
        //ar.assertLoggedIn("Must be logged in in order to modify page.");
        pageInfo.setModTime(ar.nowTime);
        pageInfo.setModUser(ar.getBestUserId());
    }


    public NGBook getSite() {
        if (prjSite==null) {
            //this will prove that this always returns a non-null value.
            throw new RuntimeException("Program Logic Error: something is wrong with NGPage object which has a null site ... this should never happen.");
        }
        return prjSite;
    }

    public String getSiteKey() {
        return pageInfo.getSiteKey();
    }
    protected void setSiteKey(String newKey) {
        pageInfo.setSiteKey(newKey);
    }


    public void setSite(NGBook ngb) {
        if (ngb==null) {
            throw new RuntimeException("setSite called with null parameter.   Should not be using the 'default site' concept any more, this exception is checking to see if it ever happens");
        }
        pageInfo.setSiteKey(ngb.getKey());
        prjSite = ngb;
    }


    /**
    * Override the superclass implementation to add a license for the process
    */
    @Override
    public List<License> getLicenses() throws Exception {
        List<License> vc = super.getLicenses();
        vc.add(new LicenseForProcess(getProcess()));
        return vc;
    }

    public License createLicense(String userId, String role, long endDate,
            boolean readOnly) throws Exception{
        String id = IdGenerator.generateKey();
        License lr = addLicense(id);
        lr.setTimeout(endDate);   //one year later
        lr.setCreator(userId);
        lr.setRole(role);
        lr.setReadOnly(readOnly);
        return lr;
    }

    @Override
    public boolean isValidLicense(License lr, long time) throws Exception {
        if (super.isValidLicense(lr, time)) {
            return true;
        }
        if (lr instanceof LicenseForUser) {
            //check all the action items, the license will be valid if the person
            //is still assigned to a action items, and the license is a LicenseForUser
            AddressListEntry ale = new AddressListEntry(lr.getCreator());
            for (GoalRecord goal : this.getAllGoals()) {
                if (!goal.isPassive() && goal.isAssignee(ale)) {
                    //passive action items from other workspace should only effect those other workspaces,
                    //and should not allow anyone into a linked sub workspace.
                    //Active action items should allow anyone assigned to be treated as a member.
                    return true;
                }
            }
        }
        return false;
    }





    //a page always has a process, so if asked for, and we can't find
    //it, then we create it.
    public ProcessRecord getProcess() throws Exception {
        if (pageProcess!=null) {
            return pageProcess;
        }
        throw new Exception("Looks like NGPage was not initialized correctly, missing pageProcess");
    }


    /**
    * Returns all the action items for a workspace.
    */
    public List<GoalRecord> getAllGoals() throws Exception {
        return SectionTask.getAllTasks(taskParent);
    }

    public JSONArray getJSONGoals() throws Exception {
        JSONArray val = new JSONArray();
        for (GoalRecord goal : getAllGoals()) {
            val.put(goal.getJSON4Goal((NGWorkspace)this));
        }
        return val;
    }


    /**
    * Find the requested action item, or throw an exception
    */
    public GoalRecord getGoalOrFail(String id) throws Exception {
        GoalRecord task = getGoalOrNull(id);
        if (task==null) {
            throw new JSONException("Could not find a action item with the id={0}", id);
        }
        return task;
    }

    public GoalRecord getGoalOrNull(String id) throws Exception {
        if (id==null) {
            throw new Exception("getGoalOrNull requires a non-null id parameter");
        }
        List<GoalRecord> list = taskParent.getChildren("task", GoalRecord.class);
        for (GoalRecord goal : list) {
            if (id.equals(goal.getId())) {
                return goal;
            }
            if (id.equals(goal.getUniversalId())) {
                return goal;
            }
        }
        return null;
    }

    public GoalRecord findGoalBySynopsis(String synopsis) throws Exception {
        for (GoalRecord goal : getAllGoals()) {
            if (synopsis.equals(goal.getSynopsis())) {
                return goal;
            }
        }
        return null;
    }

    /**
    * Creates an action item in a workspace without any history about creating it
    */
    public GoalRecord createGoal(String requesterId)
        throws Exception
    {
        String id = getUniqueOnPage();
        NGSection ngs = getSectionOrFail("Tasks");
        GoalRecord goal = ngs.createChildWithID("task", GoalRecord.class, "id", id);
        goal.setCreator(requesterId);
        String uid = getContainerUniversalId() + "@" + id;
        goal.setUniversalId(uid);
        goal.setRank(32000000);
        goal.setPassive(false);
        renumberGoalRanks();
        return goal;
    }

    /**
    * Create a new goal that is subordinant to another
    */
    public GoalRecord createSubGoal(GoalRecord parent, String requesterId) throws Exception {
        GoalRecord goal = createGoal(requesterId);
        goal.setParentGoal(parent.getId());
        goal.setDueDate(parent.getDueDate());
        parent.setState(BaseRecord.STATE_WAITING);
        return goal;
    }


    public JSONArray getJSONAttachments(AuthRequest ar) throws Exception {
        JSONArray val = new JSONArray();
        for (AttachmentRecord doc : getAccessibleAttachments(ar.getUserProfile())) {
            if (doc.isDeleted()) {
                continue;
            }
            val.put(doc.getJSON4Doc(ar, (NGWorkspace)this));
        }
        return val;
    }



    public List<HistoryRecord> getAllHistory()
        throws Exception
    {
        return getProcess().getAllHistory();
    }


    public HistoryRecord createNewHistory()
        throws Exception
    {
        HistoryRecord newHist = getProcess().createPartialHistoryRecord();
        newHist.setId(getUniqueOnPage());
        return newHist;
    }





    //Override
    public ReminderMgr getReminderMgr()
        throws Exception
    {
        if (reminderMgr==null)
        {
            reminderMgr = requireChild("reminders", ReminderMgr.class);
        }
        return reminderMgr;
    }


    /**
    * implemented special functionality for workspaces ... there are site
    * executives, and there are task assignees to consider.
    */
    @Override
    public boolean primaryOrSecondaryPermission(UserRef user) throws Exception {
        if (primaryPermission(user))
        {
            return true;
        }
        if (secondaryPermission(user))
        {
            return true;
        }
        NGRole execs = getSite().getRoleOrFail("Executives");
        if (execs.isPlayer(user))
        {
            return true;
        }
        //now walk through the action items, and check if person is assigned to any active goal

        for (GoalRecord gr : getAllGoals())
        {
            if (gr.isPassive()) {
                //ignore any passive action items that are from other workspaces.  Only consider local goals
                continue;
            }
            int state = gr.getState();
            if (state == BaseRecord.STATE_OFFERED ||
                state == BaseRecord.STATE_ACCEPTED||
                state == BaseRecord.STATE_WAITING )
            {
                if (gr.isAssignee(user))
                {
                    return true;
                }
            }
        }

        return false;
    }



    public synchronized static String generateKey() {
        return IdGenerator.generateKey();
    }




    //Override
    public void saveModifiedWorkspace(AuthRequest ar, String comment) throws Exception{
        saveFile( ar, comment );
    }


    @Override
    public List<String> getContainerNames(){
        return getPageNames();
    }




    /**
    * Used by ContainerCommon to provide methods for this class
    */
    @Override
    protected DOMFace getRoleParent() throws Exception {
        if (pageInfo==null) {
            pageInfo = requireChild("pageInfo", PageInfoRecord.class);
        }
        return pageInfo.requireChild("roleList", DOMFace.class);
    }


    /**
    * Used by ContainerCommon to provide methods for this class
    */
    @Override
    protected DOMFace getInfoParent() throws Exception {
        if (pageInfo==null) {
            pageInfo = requireChild("pageInfo", PageInfoRecord.class);
        }
        return pageInfo;
    }

    public void writeContainerLink(AuthRequest ar, int len) throws Exception
    {
        ar.write("<a href=\"");
        ar.write(ar.retPath);
        ar.write(ar.getDefaultURL(this));
        ar.write("\">");
        ar.writeHtml(trimName(getFullName(), len));
        ar.write( "</a>");
    }





    public void deleteRoleRequest(String requestId) throws Exception {
        DOMFace roleRequests = pageInfo.requireChild("Role-Requests",
                DOMFace.class);
        List<Element> children = DOMUtils.getNamedChildrenVector( roleRequests.getElement(),
                "requests");
        for (Element child : children) {
            if ("requests".equals(child.getLocalName()) || "requests".equals(child.getNodeName())) {
                String childAttValue = child.getAttribute("id");
                if (childAttValue != null && requestId.equals(childAttValue)) {
                    roleRequests.getElement().removeChild(child);
                }
            }
        }
    }


    public String getWorkspaceMailId() {
        return pageInfo.getWorkspaceMailId();
    }
    public void setWorkspaceMailId(String id) {
        pageInfo.setWorkspaceMailId(id);
    }


    /**
     * Find all the tasks on this page, and assign them new, arbitrary
     * rank values such that they remain in the same order.
     * Assigned new values increasing by 10 so that other tasks can be place
     * between existing tasks if necessary.
     */
    public void renumberGoalRanks() throws Exception {
        int rankVal = 0;
        List<GoalRecord> allGoals = getAllGoals();
        GoalRecord.sortTasksByRank(allGoals);
        for (GoalRecord tr : allGoals) {
            String myParent = tr.getParentGoalId();
            // only renumber tasks that have no parent. Others renumbered
            // recursively
            if (myParent == null || myParent.length() == 0) {
                rankVal += 10;
                tr.setRank(rankVal);
                rankVal = renumberRankChildren(allGoals, rankVal, tr.getId());
            }
        }
    }

    private static int renumberRankChildren(List<GoalRecord> allGoals, int rankVal, String parentId)
            throws Exception {
        for (GoalRecord aGoal : allGoals) {
            if (parentId.equals(aGoal.getParentGoalId())) {
                rankVal += 10;
                aGoal.setRank(rankVal);
                rankVal = renumberRankChildren(allGoals, rankVal, aGoal.getId());
            }
        }
        return rankVal;
    }

    public abstract File getContainingFolder();


    public List<MeetingRecord> getMeetings() throws Exception {
        DOMFace meetings = requireChild("meetings", DOMFace.class);
        return meetings.getChildren("meeting", MeetingRecord.class);
    }
    public MeetingRecord findMeeting(String id) throws Exception {
        MeetingRecord m =findMeetingOrNull(id);
        if (m!=null) {
            return m;
        }
        throw new JSONException("Could not find a meeting with the id={0}", id);
    }
    public MeetingRecord findMeetingOrNull(String id) throws Exception {
        if (id==null) {
            throw new Exception("Program Logic Error: attempt to find meeting but passed null id value");
        }
        if (id.length()==0) {
            throw new Exception("Program Logic Error: attempt to find meeting but passed null-string id value");
        }
        for (MeetingRecord m : getMeetings()) {
            if (id.equals(m.getId())) {
                return m;
            }
        }
        return null;
    }
    public MeetingRecord createMeeting() throws Exception {
        DOMFace meetings = requireChild("meetings", DOMFace.class);
        MeetingRecord mr = meetings.createChildWithID("meeting", MeetingRecord.class, "id", this.getUniqueOnPage());
        mr.setState(1);
        return mr;
    }
    public void removeMeeting(String id) throws Exception {
        DOMFace meetings = requireChild("meetings", DOMFace.class);
        meetings.removeChildrenByNameAttrVal("meeting", "id", id);
    }


    public List<DecisionRecord> getDecisions() throws Exception {
        DOMFace meetings = requireChild("decisions", DOMFace.class);
        List<DecisionRecord> ret =  meetings.getChildren("decision", DecisionRecord.class);
        return ret;
    }
    public DecisionRecord createDecision() throws Exception {
        DOMFace decisions = requireChild("decisions", DOMFace.class);
        int max = 0;
        for (DecisionRecord m : getDecisions()) {
            if (max < m.getNumber()) {
                max = m.getNumber();
            }
        }
        DecisionRecord dr = decisions.createChildWithID("decision", DecisionRecord.class,
                "num", Integer.toString(max+1));
        dr.setUniversalId(this.getContainerUniversalId()+"@DEC"+max);
        return dr;
    }
    public void deleteDecision(int number) throws Exception {
        DOMFace decisions = requireChild("decisions", DOMFace.class);
        DecisionRecord dr = findDecisionOrNull(number);
        decisions.removeChild(dr);
    }
    public DecisionRecord findDecisionOrNull(int number) throws Exception {
        for (DecisionRecord m : getDecisions()) {
            if (number == m.getNumber()) {
                return m;
            }
        }
        return null;
    }
    public DecisionRecord findDecisionOrFail(int num) throws Exception {
        DecisionRecord dr = findDecisionOrNull(num);
        if (dr!=null) {
            return dr;
        }
        throw new JSONException("Could not find a decision with the number={0}", num);
    }



    /**
    * Returns all the email generators for a workspace.
    */
    public List<EmailGenerator> getAllEmailGenerators() throws Exception {
        DOMFace generators =  requireChild("generators", DOMFace.class);
        return generators.getChildren("emailGenerator", EmailGenerator.class);
    }

    /**
    * Find the requested email generator, or throw an exception
    */
    public EmailGenerator getEmailGeneratorOrFail(String id) throws Exception {
        EmailGenerator egen = getEmailGeneratorOrNull(id);
        if (egen==null) {
            throw new Exception("Not able to find an Email Generator with the ID="+id);
        }
        return egen;
    }

    public EmailGenerator getEmailGeneratorOrNull(String id) throws Exception {
        for (EmailGenerator egen : getAllEmailGenerators()) {
            if (id.equals(egen.getId())) {
                return egen;
            }
        }
        return null;
    }

    public EmailGenerator createEmailGenerator() throws Exception {
        DOMFace meetings = requireChild("generators", DOMFace.class);
        EmailGenerator egen = meetings.createChildWithID("emailGenerator", EmailGenerator.class, "id", this.getUniqueOnPage());
        return egen;
    }

    public void deleteEmailGenerator(String id) throws Exception {
        DOMFace generators =  requireChild("generators", DOMFace.class);
        generators.removeChildrenByNameAttrVal("emailGenerator", "id", id);
    }


    /**
    * Returns all the labels for a workspace, including all the
    * roles as well as the non-role labels
    */
    public List<NGLabel> getAllLabels() throws Exception {
        List<NGLabel> ret = new ArrayList<NGLabel>();
        DOMFace labelList =  requireChild("labelList", DOMFace.class);
        for (LabelRecord lr : labelList.getChildren("label", LabelRecord.class)) {
            ret.add(lr);
        }
        for (NGRole aRole : this.getAllRoles()) {
            ret.add(aRole);
        }
        return ret;
    }

    public JSONArray getJSONLabels() throws Exception {
        JSONArray val = new JSONArray();
        for (NGLabel egen : getAllLabels()) {
            val.put(egen.getJSON());
        }
        return val;
    }

    /**
    * Find the requested label record, or throw an exception
    */
    public NGLabel getLabelRecordOrFail(String name) throws Exception {
        NGLabel label = getLabelRecordOrNull(name);
        if (label==null) {
            throw new JSONException("Not able to find a Label Record with the name={0}", name);
        }
        return label;
    }

    public NGLabel getLabelRecordOrNull(String name) throws Exception {
        for (NGLabel egen : getAllLabels()) {
            if (name.equals(egen.getName())) {
                return egen;
            }
        }
        return null;
    }

    public NGLabel findOrCreateLabelRecord(String name, String color) throws Exception {
        NGLabel label = getLabelRecordOrNull(name);
        if (label==null) {
            DOMFace labelList = requireChild("labelList", DOMFace.class);
            label = labelList.createChildWithID("label", LabelRecord.class, "name", name);
            if (color!=null) {
                label.setColor(color);
            }
        }
        return label;
    }

    /**
     * Only removes the "pure label" style of label
     */
    public void removeLabelRecord(LabelRecord existing) throws Exception {
        DOMFace labelList = requireChild("labelList", DOMFace.class);
        labelList.removeChild(existing);
    }


    ///////////////////// PARENT WORKSPACE /////////////////////


    public String getParentKey() throws Exception {
        return getInfoParent().getScalar("parentProject");
    }

    public void setParentKey(String parentKey) throws Exception {
        getInfoParent().setScalar("parentProject", parentKey);
    }





    public void countIdentifiersInWorkspace(StringCounter sc) throws Exception {
        for (NGRole role : this.getAllRoles()) {
            role.countIdentifiersInRole(sc);
        }
    }

    public String getPurpose() throws Exception {
        return getProcess().getDescription();
    }
    public void setPurpose(String purp) throws Exception {
        getProcess().setDescription(purp);
    }

    public abstract JSONObject getConfigJSON() throws Exception;

    public abstract void updateConfigJSON(AuthRequest ar, JSONObject newConfig) throws Exception;
    



    public abstract List<AttachmentRecord> getAllAttachments() throws Exception;

    /**
     * This determines the subset of all the documents that a particular user
     * can access, either because the document is public, because the user is
     * a Member or Owner, or because they are in a role that has access.
     */
    public List<AttachmentRecord> getAccessibleAttachments(UserProfile up) throws Exception {
        List<NGRole> rolesPlayed = findRolesOfPlayer(up);
        List<AttachmentRecord> aList = new ArrayList<AttachmentRecord>();
        for(AttachmentRecord attachment : getAllAttachments()) {
            if (attachment.isDeleted()) {
                continue;
            }
            if (up==null) {
                continue;
            }
            if (primaryOrSecondaryPermission(up)) {
                aList.add(attachment);
                continue;
            }
            for (NGRole ngr : rolesPlayed) {
                if (attachment.roleCanAccess(ngr.getName())) {
                    aList.add(attachment);
                    break;
                }
            }
        }
        return aList;
    }


    /**
     * Can use either the short ID or the Universal ID
     */
    public AttachmentRecord findAttachmentByID(String id) throws Exception {
        for (AttachmentRecord att : getAllAttachments()) {
            if (id.equals(att.getId()) || id.equals(att.getUniversalId())) {
                return att;
            }
        }
        return null;
    }

    public AttachmentRecord findAttachmentByIDOrFail(String id) throws Exception {

        AttachmentRecord ret =  findAttachmentByID( id );

        if (ret==null)
        {
            throw new NGException("nugen.exception.unable.to.locate.att.with.id", new Object[]{id, getFullName()});
        }
        return ret;
    }

    public AttachmentRecord findAttachmentByName(String name) throws Exception {
        for (AttachmentRecord att : getAllAttachments()) {
            if (att.equivalentName( name )) {
                return att;
            }
        }
        return null;
    }
    public AttachmentRecord findAttachmentByUidOrNull(String universalId) throws Exception {
        for (AttachmentRecord att : getAllAttachments()) {
            if (universalId.equals(att.getUniversalId())) {
                return att;
            }
        }
        return null;
    }
    public AttachmentRecord findAttachmentByNameOrFail(String name) throws Exception {

        AttachmentRecord ret =  findAttachmentByName( name );

        if (ret==null)
        {
            throw new NGException("nugen.exception.unable.to.locate.att.with.name", new Object[]{name, getFullName()});
        }
        return ret;
    }


    public void deleteAttachment(String id,AuthRequest ar) throws Exception {
        AttachmentRecord att = findAttachmentByIDOrFail( id );
        att.setDeleted( ar );
    }


    public void unDeleteAttachment(String id) throws Exception {
        AttachmentRecord att = findAttachmentByIDOrFail( id );
        att.clearDeleted();
    }

    public void eraseAttachmentRecord(String id) throws Exception {
        AttachmentRecord att = findAttachmentByIDOrFail( id );
        attachParent.removeChild(att);
    }




    //////////////////// HISTORY ///////////////////////


    public List<HistoryRecord>  getHistoryForResource(int contextType, String id) throws Exception {
        List<HistoryRecord> allHist = getAllHistory();
        List<HistoryRecord> newHist = new ArrayList<HistoryRecord>();
        for (HistoryRecord hr : allHist) {
            if (contextType != hr.getContextType()) {
                continue;
            }
            if (!id.equals(hr.getContext())) {
                continue;
            }
            newHist.add(hr);
        }
        HistoryRecord.sortByTimeStamp(newHist);
        return newHist;
    }


    public List<HistoryRecord> getHistoryRange(long startTime, long endTime)
            throws Exception
    {
        List<HistoryRecord> allHist = getAllHistory();
        List<HistoryRecord> newHist = new ArrayList<HistoryRecord>();
        for (HistoryRecord hr : allHist)
        {
            long eventTime = hr.getTimeStamp();
            if (eventTime > startTime && eventTime <= endTime)
            {
                newHist.add(hr);
            }
        }
        HistoryRecord.sortByTimeStamp(newHist);
        return newHist;
    }


    public HistoryRecord getLatestHistory() throws Exception {
        List<HistoryRecord> allSortedHist = getAllHistory();
        if (allSortedHist.size()==0) {
            return null;
        }
        return allSortedHist.get(0);
    }


    public List<RoleRequestRecord> getAllRoleRequest() throws Exception {
        long tooOld = System.currentTimeMillis() - 90L*24*60*60*1000;
        List<RoleRequestRecord> requestList = new ArrayList<RoleRequestRecord>();
        DOMFace rolelist = pageInfo.requireChild("Role-Requests", DOMFace.class);
        List<RoleRequestRecord> children =  rolelist.getChildren("requests", RoleRequestRecord.class);
        for (RoleRequestRecord rrr: children) {
            if (rrr.getModifiedDate() > tooOld) {
                //only add requests that are not too old
                requestList.add(rrr);
            }
        }
        return requestList;
    }

    
    
    public RoleRequestRecord getRoleRequestRecordById(String requestId) throws Exception{
        RoleRequestRecord requestRecord = null;
        for (RoleRequestRecord roleRequestRecord : getAllRoleRequest()) {
            if(roleRequestRecord.getAttribute("id").equalsIgnoreCase(requestId)){
                requestRecord = roleRequestRecord;
                break;
            }
        }
        return requestRecord;
    }

    //TODO: If there are two, it gets the latest, ignoring earlier requests.
    //how do they get removed??
    //Are they reused??
    public RoleRequestRecord getRoleRequestRecord(String roleName, String requestedBy) throws Exception {
        RoleRequestRecord requestRecord = null;
        long modifiedDate = 0;
        for (RoleRequestRecord roleRequestRecord : getAllRoleRequest()) {
            if(requestedBy.equals(roleRequestRecord.getRequestedBy())
                    && roleName.equals(roleRequestRecord.getRoleName())
                    && modifiedDate < roleRequestRecord.getModifiedDate()){

                    requestRecord = roleRequestRecord;
                    modifiedDate = roleRequestRecord.getModifiedDate();
            }
        }
        return requestRecord;
    }

    public RoleRequestRecord createRoleRequest(String roleName, String requestedBy, long modifiedDate, String modifiedBy, String requestDescription) throws Exception
    {
        //remove any old requests more than 90 days old, before creating a new one
        List<String> removalList = new ArrayList<String>();
        long tooOld = System.currentTimeMillis() - 90L*24*60*60*1000;
        DOMFace rolelist = pageInfo.requireChild("Role-Requests", DOMFace.class);
        List<RoleRequestRecord> children =  rolelist.getChildren("requests", RoleRequestRecord.class);
        for (RoleRequestRecord rrr: children) {
            if (rrr.getModifiedDate() < tooOld) {
                removalList.add(rrr.getRequestId());
            }
        }
        //now clean up the removals.
        for (String oldId : removalList) {
            rolelist.removeChildrenByNameAttrVal("requests", "id", oldId);
        }

        RoleRequestRecord newRoleRequest = rolelist.createChild("requests", RoleRequestRecord.class);
        newRoleRequest.setRequestId(generateKey());
        newRoleRequest.setModifiedDate(modifiedDate);
        newRoleRequest.setModifiedBy(modifiedBy);
        newRoleRequest.setState("Requested");
        newRoleRequest.setCompleted(false);
        newRoleRequest.setRoleName(roleName);
        newRoleRequest.setRequestedBy(requestedBy);
        newRoleRequest.setRequestDescription(requestDescription);
        newRoleRequest.setResponseDescription("");

        return newRoleRequest;
    }


}
