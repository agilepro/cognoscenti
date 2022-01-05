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
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.util.ArrayList;
import java.util.List;

//import org.apache.commons.io.FileUtils;
import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.mail.ScheduledNotification;

import org.apache.tomcat.util.http.fileupload.FileUtils;
import org.w3c.dom.Document;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.HTMLWriter;

/**
* NGWorkspace is a Container that represents a Workspace.
* This kind of project/page/workspace exists anywhere in a site hierarchy.
* The old project (NGPage) existed only in a single date folder, and all the attachments
* existed in the attachment folder.  The old NGPage is not used anymore,
* but exists in name only in the class hierarchy.
*
* This workspace is represented by a folder in a site hierarchy,
* and the attachments are just files within that folder.
* The project file itself has a reserved name ".cog/ProjInfo.xml"
* and the old versions of attachments are in the ".cog" folder as well.
*/
public class NGWorkspace extends NGPage {
    /**
    * This workspace inhabits a folder on disk, and this is the path to the folder.
    */
    public File containingFolder;

    private File        jsonFilePath;
    private JSONObject  workspaceJSON;


    public NGWorkspace(File theFile, Document newDoc, NGBook site) throws Exception {
        super(theFile, newDoc, site);

        jsonFilePath = new File(theFile.getParent(), "WorkspaceInfo.json");
        
        //we can relax this and get from lazy evaluation, but need to test carefully
        //leaving this in for now
        getWorkspaceJSON();
        
        //search for old, outdated invitations and delete them
        removeOldInvitations();


        String name = theFile.getName();
        if (!name.equals("ProjInfo.xml")) {
            throw new Exception("Something is wrong with the data folder structure.  "
                        +"Tried to open a NGWorkspace file named "+name
                        +" and don't know what to do with that.");
        }

        File cogFolder = theFile.getParentFile();
        if (!cogFolder.getName().equalsIgnoreCase(".cog")) {
            throw new Exception("Something is wrong with the data folder structure.  "
                    +"Tried to open a NGWorkspace file named "+name
                    +" except it should be in a folder named .cog, however "
                    +"it was in a folder named "+cogFolder.getName());
        }
        containingFolder = cogFolder.getParentFile();

        String realName = containingFolder.getName();
        String key = this.getKey();
        if (!key.equals(realName)) {
            //maybe the workspace was moved or renamed
            System.out.println("For some reason the page ("+site.getKey()+"/"+realName+") thinks its name is ("+key+") FIXING THIS");
            this.setKey(realName);
        }

        //upgrade all the note, document, and task records
        cleanUpTaskUniversalId();
        
        //check for and remove unnecessary files in the root folder
        purgeRootLevelFiles();
        
        //get rid of old ics files that are piling up in directory
        //oldest file should be today minus 30 days
        long thirtyDaysAgo = System.currentTimeMillis() - 1000L*60*60*24*30;
        for (File child : cogFolder.listFiles()) {
            String fname = child.getName();
            if (child.lastModified()>thirtyDaysAgo) {
                //don't bother cleaning up anything less than 30 days old
                continue;
            }
            if (fname.endsWith(".ics")) {
                System.out.println("CLEANUP: deleting ICS created more than 30 days ago: "+child.getAbsolutePath());
                if (!child.delete()) {
                    System.out.println("     ARRRGH: unable to delete it!  "+child.getAbsolutePath());
                }
            }
            if (fname.startsWith("~tmp")) {
                System.out.println("CLEANUP: deleting ~tmp file created more than 30 days ago: "+child.getAbsolutePath());
                if (!child.delete()) {
                    System.out.println("     ARRRGH: unable to delete it!  "+child.getAbsolutePath());
                }
            }
        }
    }


    /**
     * Need to inject the saving of the JSON file at this point
     * to assure that both XML and JSON get saved.
     */
    @Override
    public void save() throws Exception {
        super.save();

        if (workspaceJSON!=null) {
            workspaceJSON.writeToFile(jsonFilePath);
        }
        //store into the cache.  Something might be copying things in memory,
        //and this assures that the cache matches the latest written version.
        //String fullFilePath = associatedFile.toString();
        //pageCache.store(fullFilePath, this);
        pageCache.emptyCache();
    }

    public void saveFile(AuthRequest ar, String comment) throws Exception {
        super.saveFile(ar, comment);
        assureLaunchingPad(ar);
        System.out.println("     file save ("+getFullName()+") tid="+Thread.currentThread().getId()+" time="+(System.currentTimeMillis()%10000));
    }



    @Override
    protected void migrateKeyValue(File theFile) throws Exception {
        if (theFile.getName().equalsIgnoreCase("ProjInfo.xml")) {
            File cogFolder = theFile.getParentFile();
            for (File child : cogFolder.listFiles()) {
                String childName = child.getName();
                if (childName.startsWith("key_")) {
                    String fileKey = SectionUtil.sanitize(childName.substring(4));
                    setKey(fileKey);
                }
            }
        }
        else if (theFile.getName().endsWith(".sp")) {
            super.migrateKeyValue(theFile);
        }
        else {
            throw new Exception("don't know how to make key for "+theFile);
        }
    }

    public void schemaUpgrade(int fromLevel, int toLevel) throws Exception {
        if (fromLevel<101) {
            getAllAttachments();
            this.getAllEmail();
            this.getAllGoals();
            this.getAllHistory();
            this.getAllLabels();
            for (TopicRecord note : this.getAllDiscussionTopics()) {
                for (CommentRecord comm : note.getComments()) {
                    //schema migration from before 101
                    comm.schemaMigration(fromLevel, toLevel);
                }
            }
            this.getAllRoles();
            for (MeetingRecord meet : getMeetings()) {
                for (AgendaItem ai : meet.getAgendaItems()) {
                    for (CommentRecord comm : ai.getComments()) {
                        //schema migration from before 101
                        comm.schemaMigration(fromLevel, toLevel);
                    }
                }
            }
        }
        if (fromLevel<102) {
            for (@SuppressWarnings("unused") TopicRecord nr : this.getAllDiscussionTopics()) {
                //just run the constructor
            }
        }
    }
    public int currentSchemaVersion() {
        return 102;
    }

    public static NGWorkspace readWorkspaceAbsolutePath(File theFile) throws Exception {
        if (!theFile.exists()) {
            throw new NGException("nugen.exception.file.not.exist", new Object[]{theFile});
        }
        try {
            //look in the cache
            NGWorkspace newWorkspace = pageCache.recall(theFile);
            if (newWorkspace==null) {
                 //determine the site settings
                File cogFolder = theFile.getParentFile();
                File workFolder = cogFolder.getParentFile();
                File siteFolder = workFolder.getParentFile();
                String siteKey = siteFolder.getName();
                NGBook theSite = NGBook.readSiteByKey(siteKey);

                Document newDoc;
                InputStream is = new FileInputStream(theFile);
                newDoc = DOMUtils.convertInputStreamToDocument(is, false, false);
                is.close();
                newWorkspace = new NGWorkspace(theFile, newDoc, theSite);

                if (!siteKey.equals(newWorkspace.getSiteKey())) {
                    System.out.println("Site ("+siteKey+") != ("+newWorkspace.getSiteKey()+") FIXING UP workspace "+theFile);
                    newWorkspace.setSiteKey(siteKey);
                    System.out.println("    NOW ("+newWorkspace.getSiteKey()+")");
                }

                String workspaceKey = workFolder.getName();
                if (!workspaceKey.equals(newWorkspace.getKey())) {
                    System.out.println("Workspace ("+workspaceKey+") != ("+newWorkspace.getKey()+") FIXING UP workspace "+theFile);
                    newWorkspace.setKey(workspaceKey);
                }
            }

            //store into the cache.
            pageCache.store(theFile, newWorkspace);
            return newWorkspace;
        }
        catch (Exception e) {
            throw new NGException("nugen.exception.unable.to.read.file",new Object[]{theFile}, e);
        }
    }

    @Override
    public void writeDocumentLink(AuthRequest ar, String documentId, int len) throws Exception
    {
        AttachmentRecord att = findAttachmentByID(documentId);
        if(att==null)
        {
            ar.write( "(Document " );
            ar.write( documentId );
            ar.write( ")" );
            return;
        }
        ar.write(ar.baseURL);
        ar.write(att.getEmailURL(ar, this));
        ar.write("\">" );
        ar.writeHtml(trimName(att.getDisplayName(), len));
        ar.write( "</a>");
    }


    public List<AttachmentRecord> getAllAttachments() throws Exception {
        List<AttachmentRecord> list = attachParent.getChildren("attachment", AttachmentRecord.class);
        for (AttachmentRecord att : list) {
            att.setContainer(this);
            
            String atype = att.getType();
            boolean isDel = att.isDeleted();
            if (atype.equals("FILE") && !isDel) {
                String attName = att.getDisplayName();
                if (attName==null || attName.length()==0) {
                    System.out.println("Found attachement without name, id="+att.getId()+" in project ("+this.getCombinedKey()+")");
                }
                
                //consider removing this check as unnecessary, project folder files
                //eliminated in Oct 2021 and so at some point remove this unnecessary check.
                /*
                File attPath = new File(containingFolder, attName);
                if (attPath.exists()) {
                    throw new Exception("There is a copy in the main folder, it should not be there: "
                        +attPath.getAbsolutePath());
                }
                */
            }
            else if (atype.equals("GONE")) {
                //old state no longer supported, this correction was in the code
                //eliminated project folder files in Oct 2021 and so at some point remove this unnecessary check.
                att.setType("FILE");
            }
        }
        return list;
    }

    public AttachmentRecord createAttachment() throws Exception {
        String newId = getUniqueOnPage();
        AttachmentRecord attach = attachParent.createChild("attachment", AttachmentRecord.class);
        attach.setId(newId);
        attach.setContainer(this);
        attach.setUniversalId( getContainerUniversalId() + "@" + newId );
        return attach;
    }
    /**
     * This is effectively the "empty trashcan" operation.  Documents that
     * have been marked as deleted will actually, finally, be deleted with
     * this operation.
     */
    public void purgeDeletedAttachments() throws Exception {
        List<AttachmentRecord> cleanList = new ArrayList<AttachmentRecord>();
        for (AttachmentRecord ar : getAllAttachments()) {
            if (!ar.isDeleted()) {
                //don't purge or do anything to non-deleted attachments
                continue;
            }
            ar.purgeAllVersions(this);
            cleanList.add(ar);
        }
        for (AttachmentRecord ar : cleanList) {
            eraseAttachmentRecord(ar.getId());
        }
    }

    public File getAttachmentPathOrNull(String oneId) throws Exception {

        AttachmentRecord attach = this.findAttachmentByID(oneId);
        if (attach==null) {
            //attachments might get removed in the mean time, just ignore them
            //throw new Exception("getAttachmentPathFromContainer was called with an invalid ID?: "+oneId);
            return null;
        }
        AttachmentVersion aVer = attach.getLatestVersion(this);
        if (aVer==null) {
            //throw new Exception("Apparently there are no file versions of ID: "+oneId);
            return null;
        }
        return(aVer.getLocalFile());
    }


/*
    public void scanForNewFiles() throws Exception {
        File[] children = containingFolder.listFiles();
        List<AttachmentRecord> list = getAllAttachments();
        for (File child : children) {
            if (child.isDirectory()) {
                continue;
            }
            String fname = child.getName();
            if (fname.endsWith(".sp")) {
                //ignoring other possible project files
                continue;
            }
            if (fname.startsWith(".cog")) {
                //need to ignore .cogProjectView.htm and other files with .cog*
                continue;
            }

            //all others are possible documents at this point
            AttachmentRecord att = null;
            for (AttachmentRecord knownAtt : list) {
                if (fname.equals(knownAtt.getDisplayName())) {
                    att = knownAtt;
                }
            }
            if (att!=null) {
                continue;
            }
            att = createAttachment();
            att.setDisplayName(fname);
            att.setType("EXTRA");
            list.add(att);
        }
        List<AttachmentRecord> ghosts = new ArrayList<AttachmentRecord>();
        for (AttachmentRecord knownAtt : list) {
            if ("URL".equals(knownAtt.getType())) {
                continue;   //ignore URL attachments
            }
            AttachmentVersion aVer = knownAtt.getLatestVersion(this);
            if (aVer==null) {
                // this is a ghost if there are no versions at all.  Remove it
                ghosts.add(knownAtt);
                continue;
            }
            File attFile = aVer.getLocalFile();
            if (!attFile.exists()) {
                knownAtt.setType("GONE");
            }
        }

        //delete the ghosts, if any exist
        for (AttachmentRecord ghost : ghosts) {
            //it disappears without a trace.  But what else can we do?
            attachParent.removeChild(ghost);
        }
    }
    */

/*
    public void removeExtrasByName(String name) throws Exception {
        List<AttachmentRecord> list = attachParent.getChildren("attachment", AttachmentRecord.class);
        for (AttachmentRecord att : list) {
            if (att.getType().equals("EXTRA") && att.getDisplayName().equals(name)) {
                attachParent.removeChild(att);
                break;
            }
        }
    }
    */


    public void assureLaunchingPad(AuthRequest ar) throws Exception {
        File launchFile = new File(containingFolder, ".cogProjectView.htm");
        if (!launchFile.exists()) {
            OutputStream os = new FileOutputStream(launchFile);
            Writer w = new OutputStreamWriter(os, "UTF-8");
            w.write("<html><body><script>document.location = \"");
            HTMLWriter.writeHtml(w, ar.baseURL);
            HTMLWriter.writeHtml(w, ar.getDefaultURL(this));
            w.write("\";</script></body></html>");
            w.flush();
            w.close();
        }
    }


    public File getContainingFolder() {
        return containingFolder;
    }

    public JSONArray getJSONEmailGenerators(AuthRequest ar) throws Exception {
        JSONArray val = new JSONArray();
        List<EmailGenerator> gg = getAllEmailGenerators();
        long timeLimit = ar.nowTime - 366L * 24 * 3600000;
        for (EmailGenerator egen : gg) {
            //only list email generators less than one year old
            if (egen.getState()<EmailGenerator.EG_STATE_SENT || egen.getScheduleTime() > timeLimit) {
                val.put(egen.getJSON(ar, this));
            }
        }
        return val;
    }


    /**
     * Return the time of the next automated action.  If there are multiple
     * scheduled actions, this returns the time of the next one.
     *
     * A negative number means there are no scheduled events.
     */
    @Override
    public long nextActionDue() throws Exception {
        //initialize to some time next year
        long yearFromNow = System.currentTimeMillis() + 31000000000L;
        long nextTime = yearFromNow;
        for (EmailRecord er : getAllEmail()) {
            if (er.statusReadyToSend()) {
                //there is no scheduled time for sending email .. it just is scheduled
                //immediately and supposed to be sent as soon as possible after that
                //so return now minus 1 minutes
                long reminderTime = System.currentTimeMillis()-60000;
                if (reminderTime < nextTime) {
                    //Workspace has email that needs to be collected
                    nextTime = reminderTime;
                }
            }
        }

        ArrayList<ScheduledNotification> resList = new ArrayList<ScheduledNotification>();
        gatherUnsentScheduledNotification(resList, yearFromNow);

        ScheduledNotification first = null;
        //Now scan all the standard scheduled notifications
        for (ScheduledNotification sn : resList) {
            long timeToAct = sn.futureTimeToSend();
            if (timeToAct < nextTime) {
                nextTime = timeToAct;
                first = sn;
            }
        }
        if (first!=null) {
            System.out.println("Found the next event to be: ("+first.selfDescription()+") to be sent at ("
                     +SectionUtil.getNicePrintDate(first.futureTimeToSend())+")");
        }
        return nextTime;
    }


    public void gatherUnsentScheduledNotification(ArrayList<ScheduledNotification> resList, long timeout) throws Exception {
        for (MeetingRecord meeting : getMeetings()) {
            meeting.gatherUnsentScheduledNotification(this, resList, timeout);
        }
        for (TopicRecord note : this.getAllDiscussionTopics()) {
            note.gatherUnsentScheduledNotification(this, resList, timeout);
        }
        for (EmailGenerator eg : getAllEmailGenerators()) {
            eg.gatherUnsentScheduledNotification(this, resList, timeout);
        }
        for (GoalRecord goal : getAllGoals()) {
            goal.gatherUnsentScheduledNotification(this, resList, timeout);
        }
        for (AttachmentRecord attach : this.getAllAttachments()) {
            attach.gatherUnsentScheduledNotification(this, resList, timeout);
        }
        for (RoleInvitation ri : getInvitations()) {
            ri.gatherUnsentScheduledNotification(this, resList, timeout);
        }
    }



    /**
    * schema migration ...
    * make sure that all tasks have universal ids.
    * do this here because the GoalRecord constructor
    * does not easily know what the container is.
    */
    private void cleanUpTaskUniversalId() throws Exception {

        cleanUpNoteAndDocUniversalId();

        for (GoalRecord goal : getAllGoals()) {
            String uid = goal.getUniversalId();
            if (uid==null || uid.length()==0) {
                uid = getContainerUniversalId() + "@" + goal.getId();
                goal.setUniversalId(uid);
            }
            long lastModTime = goal.getModifiedDate();
            if (lastModTime<=0) {
                String lastModUser = "";
                for (HistoryRecord hist : goal.getTaskHistory(this)) {
                    if (hist.getTimeStamp()>lastModTime) {
                        lastModTime = hist.getTimeStamp();
                        lastModUser = hist.getResponsible();
                    }
                }
                goal.setModifiedDate(lastModTime);
                goal.setModifiedBy(lastModUser);
            }
        }
    }
    
    /**
     * Another structure migration.   Get rid of the files that are in the root
     * of the project folder.
     */
    private void purgeRootLevelFiles() throws Exception {
        for (AttachmentRecord att : getAllAttachments()) {
            att.purgeUnnecessaryDuplicate();
        }
    }

    /**
    * schema migration ...
    * make sure that all topics and documents have universal ids.
    * do this here because the TopicRecord & AttachmentRecord constructor
    * does not easily know what the container is.
    */
    private void cleanUpNoteAndDocUniversalId() throws Exception {
        //schema migration ...
        //make sure that all topics have universal ids.
        for (TopicRecord lr : getAllDiscussionTopics()) {
            String uid = lr.getUniversalId();
            if (uid==null || uid.length()==0) {
                uid = getContainerUniversalId() + "@" + lr.getId();
                lr.setUniversalId(uid);
            }
        }

        //and the same for documents
        for (AttachmentRecord att : getAllAttachments()) {
            String uid = att.getUniversalId();
            if (uid==null || uid.length()==0) {
                uid = getContainerUniversalId() + "@" + att.getId();
                att.setUniversalId(uid);
            }
        }
    }


    ///////////////////////// SharePortRecord //////////////////

    public List<SharePortRecord> getSharePorts() throws Exception {
        JSONArray ports = workspaceJSON.requireJSONArray("sharePorts");
        ArrayList<SharePortRecord> res = new ArrayList<SharePortRecord>();
        for (int i=0; i<ports.length(); i++) {
            JSONObject onePort = ports.getJSONObject(i);
            SharePortRecord spr = new SharePortRecord(onePort);
            res.add(spr);
        }
        return res;
    }
    public SharePortRecord createSharePort() throws Exception {
        JSONArray ports = workspaceJSON.requireJSONArray("sharePorts");
        JSONObject jo = new JSONObject();
        jo.put("id", IdGenerator.generateDoubleKey());
        ports.put(jo);
        SharePortRecord spr = new SharePortRecord(jo);
        return spr;
    }
    public SharePortRecord findSharePortOrNull(String id) throws Exception {
        for (SharePortRecord m : getSharePorts()) {
            if (id.equals(m.getPermId())) {
                return m;
            }
        }
        return null;
    }
    public SharePortRecord findSharePortOrFail(String id) throws Exception {
        SharePortRecord spr = findSharePortOrNull(id);
        if (spr!=null) {
            return spr;
        }
        throw new Exception("Could not find a share port with the id="+id);
    }


    public int replaceUserAcrossWorkspace(String sourceUser, String destUser) throws Exception {
        try {
            int count = 0;
            for (GoalRecord goal : this.getAllGoals()) {
                NGRole assignee = goal.getAssigneeRole();
                if (assignee.replaceId(sourceUser, destUser)) {
                    count++;
                }
            }
            for (NGRole role : this.getAllRoles()) {
                if (role.replaceId(sourceUser, destUser)) {
                    count++;
                }
            }
            for (TaskArea ta : this.getTaskAreas()) {
                ta.replaceAssignee(sourceUser, destUser);
            }
            return count;
        }
        catch (Exception e) {
            throw new Exception("Unable to replace user ("+sourceUser+") in workspace: "+this.getKey(), e);
        }
    }

    
    private JSONObject getWorkspaceJSON() throws Exception {
        if (workspaceJSON == null) {
            if (jsonFilePath.exists()) {
                workspaceJSON = JSONObject.readFromFile(jsonFilePath);
            }
            else {
                workspaceJSON = new JSONObject();
            }
        }
        return workspaceJSON;
    }
    
    public JSONObject getWSSettings() throws Exception {
        JSONObject wsJSON = getWorkspaceJSON();
        if (!wsJSON.has("wsSettings")) {
            //traditionally we have shown the aim on the front page, 
            //so if the settings are not there, default to that setting
            JSONObject def = new JSONObject();
            def.put("showAimOnFrontPage", true);
            wsJSON.put("wsSettings", def);
        }
        return wsJSON.getJSONObject("wsSettings");
    }
    
    public void updateWSSettings(JSONObject newValues) throws Exception {
        JSONObject props = getWorkspaceJSON().requireJSONObject("wsSettings");
        for (String key : newValues.keySet()) {
            props.put(key, newValues.get(key));
        }
    }


    ///////////////////////// TaskArea //////////////////

    public List<TaskArea> getTaskAreas() throws Exception {
        JSONArray ports = getWorkspaceJSON().requireJSONArray("taskAreas");
        ArrayList<TaskArea> res = new ArrayList<TaskArea>();
        for (int i=0; i<ports.length(); i++) {
            JSONObject onePort = ports.getJSONObject(i);
            TaskArea spr = new TaskArea(onePort);
            res.add(spr);
        }
        return res;
    }
    public void moveTaskArea(String id, boolean moveDown) throws Exception {
        JSONArray ports = getWorkspaceJSON().requireJSONArray("taskAreas");
        int index = -1;
        for (int i=0; i<ports.length(); i++) {
            if (id.equals(ports.getJSONObject(i).getString("id"))) {
                index = i;
            }
        }
        if (index<0) {
            throw new Exception("Can not find any task area named "+id);
        }
        if (moveDown && index == ports.length()-1) {
            return;  //nothing to do
        }
        if (!moveDown && index == 0) {
            return;  //nothing to do
        }
        JSONArray newArray = new JSONArray();
        JSONObject movedOne = ports.getJSONObject(index);
        for (int i=0; i<ports.length(); i++) {
            JSONObject thisOne = ports.getJSONObject(i);
            if (!moveDown && i==index-1) {
                newArray.put(movedOne);
            }
            if (i != index) {
                newArray.put(thisOne);
            }
            if (moveDown && i==index+1) {
                newArray.put(movedOne);
            }
        }
        workspaceJSON.put("taskAreas", newArray);
    }
    public TaskArea createTaskArea() throws Exception {
        JSONArray ports = getWorkspaceJSON().requireJSONArray("taskAreas");
        JSONObject jo = new JSONObject();
        jo.put("id", IdGenerator.generateKey());
        ports.put(jo);
        TaskArea ta = new TaskArea(jo);
        return ta;
    }
    public TaskArea findTaskAreaOrNull(String id) throws Exception {
        for (TaskArea m : getTaskAreas()) {
            if (id.equals(m.getId())) {
                return m;
            }
        }
        return null;
    }
    public TaskArea findTaskAreaOrFail(String id) throws Exception {
        TaskArea ta = findTaskAreaOrNull(id);
        if (ta!=null) {
            return ta;
        }
        throw new Exception("Could not find a task area with the id="+id);
    }



    ///////////////////////// Invitations //////////////////

    public List<RoleInvitation> getInvitations() throws Exception {
        JSONArray invites = getWorkspaceJSON().requireJSONArray("roleInvitations");
        ArrayList<RoleInvitation> res = new ArrayList<RoleInvitation>();
        for (int i=0; i<invites.length(); i++) {
            JSONObject riObj = invites.getJSONObject(i);
            RoleInvitation spr = new RoleInvitation(riObj);
            res.add(spr);
        }
        return res;
    }
    public void removeOldInvitations() throws Exception {
        if (!getWorkspaceJSON().has("roleInvitations")) {
            return;
        }
        long timeLimit = System.currentTimeMillis() - 180L*24*60*60*1000;
        JSONArray invites = workspaceJSON.getJSONArray("roleInvitations");
        JSONArray newInvites = new JSONArray();
        for (int i=0; i<invites.length(); i++) {
            JSONObject onePort = invites.getJSONObject(i);
            if (onePort.getLong("timestamp")>timeLimit) {
                newInvites.put(onePort);
            }
        }
        workspaceJSON.put("roleInvitations", newInvites);
    }
    public RoleInvitation findOrCreateInvite(AddressListEntry ale) throws Exception {
        for (RoleInvitation ri : getInvitations()) {
            if (ale.hasAnyId(ri.getEmail())) {
                return ri;
            }
        }
        JSONArray invites = workspaceJSON.getJSONArray("roleInvitations");
        JSONObject newInvite = new JSONObject();
        newInvite.put("email", ale.getEmail());
        invites.put(newInvite);
        return new RoleInvitation(newInvite);
    }

    /**
     * When users are invited, and the invitation send, then
     * we mark the invitation as "joined" when they actually
     * visit the workspace in question.
     */
    public void registerJoining(UserProfile user) throws Exception {
        boolean needSave = false;
        for (RoleInvitation ri : getInvitations()) {
            if (user.hasAnyId(ri.getEmail())) {
                if (!ri.isJoined()) {
                    ri.markJoined();
                    needSave = true;

                    //if the user has entered a name for themselves
                    //copy it into the invite so that there is less confusion
                    //even though this is temporary
                    String userName = user.getName();
                    if (userName!=null && userName.length()>3) {
                        ri.setName(userName);
                    }
                }
            }
        }
        if (needSave) {
            this.save();
        }
    }


    public CommentRecord getCommentOrNull(long cid) throws Exception {
        for (TopicRecord note : this.getAllDiscussionTopics()) {
            for (CommentRecord comm : note.getComments()) {
                if (comm.getTime()==cid) {
                    return comm;
                }
            }
        }
        for (MeetingRecord meet : getMeetings()) {
            for (AgendaItem ai : meet.getAgendaItems()) {
                for (CommentRecord comm : ai.getComments()) {
                    if (comm.getTime()==cid) {
                        return comm;
                    }
                }
            }
        }
        for (AttachmentRecord doc : this.getAllAttachments()) {
            for (CommentRecord comm : doc.getComments()) {
                if (comm.getTime()==cid) {
                    return comm;
                }
            }
        }
        return null;
    }
    public CommentRecord getCommentOrFail(long cid) throws Exception {
        CommentRecord com = getCommentOrNull(cid);
        if (com==null) {
            throw new Exception("Unable to find any comment "+cid+" on workspace "+this.getFullName());
        }
        return com;
    }
    public List<CommentRecord> getAllComments() throws Exception {
        List<CommentRecord> res = new ArrayList<CommentRecord>();
        for (TopicRecord note : this.getAllDiscussionTopics()) {
            for (CommentRecord comm : note.getComments()) {
                res.add(comm);
            }
        }
        for (MeetingRecord meet : getMeetings()) {
            for (AgendaItem ai : meet.getAgendaItems()) {
                for (CommentRecord comm : ai.getComments()) {
                    res.add(comm);
                }
            }
        }
        for (AttachmentRecord doc : this.getAllAttachments()) {
            for (CommentRecord comm : doc.getComments()) {
                res.add(comm);
            }
        }
        CommentRecord.sortByTimestamp(res);
        return res;
    }
    
    public void deleteComment(long cid) throws Exception {
        CommentRecord foundComment = null;
        for (TopicRecord note : this.getAllDiscussionTopics()) {
            for (CommentRecord comm : note.getComments()) {
                if (comm.getTime()==cid) {
                    foundComment = comm;
                }
            }
            if (foundComment != null) {
                note.deleteComment(cid);
                return;
            }
        }
        for (MeetingRecord meet : getMeetings()) {
            for (AgendaItem ai : meet.getAgendaItems()) {
                for (CommentRecord comm : ai.getComments()) {
                    if (comm.getTime()==cid) {
                        foundComment = comm;
                    }
                }
                if (foundComment != null) {
                    ai.deleteComment(cid);
                    return;
                }
            }
        }
        for (AttachmentRecord doc : this.getAllAttachments()) {
            for (CommentRecord comm : doc.getComments()) {
                if (comm.getTime()==cid) {
                    foundComment = comm;
                }
            }
            if (foundComment != null) {
                doc.deleteComment(cid);
                return;
            }
        }
    }
    /**
     * Context is that a comment going to be changed.  If that comment was on a meeting
     * then the meeting cache needs to be updated.   This method searches to 
     * find whether a comment in on a meeting, and returns the id for that meeting
     * so that the cache can be updated.
     * 
     * Returns null if the comment is NOT on any meeting
     */
    public String findMeetingIdForComment(long cid) throws Exception {
        for (MeetingRecord meet : getMeetings()) {
            for (AgendaItem ai : meet.getAgendaItems()) {
                for (CommentRecord comm : ai.getComments()) {
                    if (comm.getTime()==cid) {
                        return meet.getId();
                    }
                }
            }
        }
        return null;
    }
    
    public void assureRepliesSet(long cid, long replyId) throws Exception {
        CommentRecord source = getCommentOrNull(cid);
        if (source!=null) {
            source.addOneToReplies(replyId);
        }
    }
    
    public void correctAllRepliesLinks() throws Exception {
        List<CommentRecord> allComments = getAllComments();
        List<Long> emptySet = new ArrayList<Long>();
        for (CommentRecord cr : allComments) {
            cr.setReplies(emptySet);
        }
        for (CommentRecord cr : allComments) {
            long replyTo = cr.getReplyTo();
            if (replyTo>0) {
                assureRepliesSet(replyTo, cr.getTime());
            }
        }
    }


    public JSONObject actuallyGarbageCollect(Cognoscenti cog) throws Exception {

        JSONObject results = new JSONObject();
        results.put("workspaceID", this.getKey());
        results.put("workspaceName", this.getFullName());
        results.put("state", this.getAccessStateStr());

        int state = this.getAccessState();
        if (state == ACCESS_STATE_DELETED) {
            //delete everything
            File cogFolder = this.associatedFile.getParentFile();
            File workspaceFolder = cogFolder.getParentFile();

            cog.eliminateIndexForWorkspace(this);

            FileUtils.deleteDirectory(workspaceFolder);
            results.put("action", "folder for workapce is completed deleted");
        }
        else {
            boolean didClean = false;
            List<String> oldIds = new ArrayList<String>();
            for (TopicRecord tr : this.getAllDiscussionTopics()) {
                if (tr.isDeleted()) {
                    oldIds.add(tr.getId());
                }
            }
            for (String oldId: oldIds) {
                noteParent.removeChildrenByNameAttrVal("note", "id", oldId);
                didClean = true;
            }
            List<AttachmentRecord> deletedOnes = new ArrayList<AttachmentRecord>();
            for (AttachmentRecord ar : this.getAllAttachments()) {
                if (ar.isDeleted()) {
                    deletedOnes.add(ar);
                }
            }
            for (AttachmentRecord att : deletedOnes) {
                att.purgeAllVersions(this);
                attachParent.removeChild(att);
                didClean = true;
            }
            if (didClean) {
                this.save();
                results.put("action", "removed some topics or documents");
            }
            else {
                results.put("action", "no change required");
            }
        }

        //check for documents to delete garbage collect
        //not implemented yet
        return results;

    }

    
    public JSONObject getPersonalWorkspaceSettings(UserProfile user) throws Exception {
        File cogFolder = new File(containingFolder, ".cog");
        File personalFile = new File(cogFolder, "personal-"+user.getKey()+".json");
        
        if (personalFile.exists()) {
            return JSONObject.readFromFile(personalFile);
        }
        
        //the old way was in these specific settings.
        //pull them out (if there) convert to JSON object
        //and eliminate the old settings.
        JSONObject personalSettings = new JSONObject();
        String combo = this.getCombinedKey();
        personalSettings.put("isWatching", user.isWatch(combo));
        personalSettings.put("reviewTime", user.watchTime(combo));

        personalSettings.put("isTemplate", user.isTemplate(combo));
        personalSettings.put("isNotify", user.isNotifiedForProject(combo));
        user.clearNotification(combo);
        if (getMuteRole().isPlayer(user)) {
            personalSettings.put("isMute", true);
            getMuteRole().removePlayerCompletely(user);
        }
        personalSettings.writeToFile(personalFile);
        return personalSettings;
    }
    
    public JSONObject updatePersonalWorkspaceSettings(UserProfile user, JSONObject newVals) throws Exception {
        File cogFolder = new File(containingFolder, ".cog");
        File personalFile = new File(cogFolder, "personal-"+user.getKey()+".json");
        JSONObject personal = getPersonalWorkspaceSettings(user);
        String combo = getCombinedKey();
        
        for (String key : newVals.keySet()) {
            personal.put(key, newVals.get(key));
            if ("isWatching".equals(key)) {
                boolean bval = newVals.getBoolean(key);
                if (bval) {
                    user.setWatch(combo);
                }
                else {
                    user.clearWatch(combo);
                }
            }
            if ("isTemplate".equals(key)) {
                user.setProjectAsTemplate(combo, newVals.getBoolean(key));
            }
        }

        personal.writeToFile(personalFile);
        return personal;
    }
    
    public boolean isWatching(UserProfile user) throws Exception {
        JSONObject personal = getPersonalWorkspaceSettings(user);
        if (!personal.has("isWatching")) {
            return false;
        }
        return personal.getBoolean("isWatching");
    }
    public void setWatching(UserProfile user, boolean val) throws Exception {
        JSONObject newVal = new JSONObject();
        newVal.put("isWatching", val);
        updatePersonalWorkspaceSettings(user, newVal);
    }

    
    
    public boolean isTemplate(UserProfile user) throws Exception {
        JSONObject personal = getPersonalWorkspaceSettings(user);
        if (!personal.has("isTemplate")) {
            return false;
        }
        return personal.getBoolean("isTemplate");
    }
    public void setTemplate(UserProfile user, boolean val) throws Exception {
        JSONObject newVal = new JSONObject();
        newVal.put("isTemplate", val);
        updatePersonalWorkspaceSettings(user, newVal);
    }
    

    
    public JSONObject getConfigJSON() throws Exception {
        ProcessRecord process = getProcess();
        JSONObject workspaceConfigInfo = new JSONObject();
        workspaceConfigInfo.put("key", getKey());
        workspaceConfigInfo.put("site", getSiteKey());
        workspaceConfigInfo.put("goal", process.getSynopsis());
        workspaceConfigInfo.put("parentKey", getParentKey());
        workspaceConfigInfo.put("frozen", isFrozen());
        workspaceConfigInfo.put("deleted", isDeleted());
        if (isDeleted()) {
            workspaceConfigInfo.put("deleteDate", pageInfo.getDeleteDate());
            workspaceConfigInfo.put("deleteUser", UserManager.getCorrectedEmail(pageInfo.getDeleteUser()));
        }
        workspaceConfigInfo.put("accessState", getAccessStateStr());

        //read only information from the site
        workspaceConfigInfo.put("showExperimental", this.getSite().getShowExperimental());

        //returns all the names for this page
        List<String> nameSet = getPageNames();
        workspaceConfigInfo.put("allNames", constructJSONArray(nameSet));

        workspaceConfigInfo.put("purpose", process.getDescription());  //a.k.a. 'aim'
        process.extractScalarString(workspaceConfigInfo, "mission");
        process.extractScalarString(workspaceConfigInfo, "vision");
        process.extractScalarString(workspaceConfigInfo, "domain");
        workspaceConfigInfo.put("wsSettings", getWSSettings());
        return workspaceConfigInfo;
    }

    public void updateConfigJSON(AuthRequest ar, JSONObject newConfig) throws Exception {
        ProcessRecord process = getProcess();
        if (newConfig.has("goal")) {
            process.setSynopsis(newConfig.getString("goal"));
        }
        if (newConfig.has("parentKey")) {
            String parentKey = newConfig.getString("parentKey");
            if ("$delete$".equals(parentKey)) {
                setParentKey(null);
            }
            else {
                setParentKey(parentKey);
            }
        }
        if (newConfig.has("deleted") || newConfig.has("frozen")) {
            boolean newDelete = newConfig.optBoolean("deleted", false);
            boolean newFrozen = newConfig.optBoolean("frozen", false);
            if (newDelete) {
                setAccessState(ar, ACCESS_STATE_DELETED);
            }
            else if (newFrozen) {
                setAccessState(ar, ACCESS_STATE_FROZEN);
            }
            else {
                setAccessState(ar, ACCESS_STATE_LIVE);
            }
        }
        if (newConfig.has("projectMail")) {
            setWorkspaceMailId(newConfig.getString("projectMail"));
        }
        if (newConfig.has("purpose")) {
            //also known as 'aim'
            process.setDescription(newConfig.getString("purpose"));
        }
        process.updateScalarString("mission", newConfig);
        process.updateScalarString("vision", newConfig);
        process.updateScalarString("domain", newConfig);
        if (newConfig.has("wsSettings")) {
            updateWSSettings(newConfig.getJSONObject("wsSettings"));
        }
    }
    
    
    
}