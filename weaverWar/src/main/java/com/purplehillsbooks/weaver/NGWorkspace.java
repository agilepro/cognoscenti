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
import java.util.Collections;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.weaver.mail.EmailGenerator;
import com.purplehillsbooks.weaver.mail.EmailRecord;
import com.purplehillsbooks.weaver.mail.EmailSender;
import com.purplehillsbooks.weaver.mail.MailInst;
import com.purplehillsbooks.weaver.mail.OptOutAddr;
import com.purplehillsbooks.weaver.mail.ScheduledNotification;

import org.apache.tomcat.util.http.fileupload.FileUtils;
import org.w3c.dom.Document;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.json.SimpleException;
import com.purplehillsbooks.streams.HTMLWriter;

/**
* NGWorkspace is a Container that represents a Workspace.
* This kind of workspace/page/workspace exists anywhere in a site hierarchy.
* The old workspace (NGPage) existed only in a single date folder, and all the attachments
* existed in the attachment folder.  The old NGPage is not used anymore,
* but exists in name only in the class hierarchy.
*
* This workspace is represented by a folder in a site hierarchy,
* and the attachments are just files within that folder.
* The workspace file itself has a reserved name ".cog/ProjInfo.xml"
* and the old versions of attachments are in the ".cog" folder as well.
*/
public class NGWorkspace extends NGPage {
    /**
    * This workspace inhabits a folder on disk, and this is the path to the folder.
    */
    public File containingFolder;

    private File        jsonFilePath;
    private JSONObject  workspaceJSON;

    private static final String EMAIL_PATTERN = "^[_A-Za-z0-9-\\+]+(\\.[_A-Za-z0-9-]+)*@"
            + "[A-Za-z0-9-]+(\\.[A-Za-z0-9]+)*(\\.[A-Za-z]{2,})$";
    static private Pattern pattern = Pattern.compile(EMAIL_PATTERN);

    public NGWorkspace(File theFile, Document newDoc, NGBook site) throws Exception {
        super(theFile, newDoc, site);

        //eliminate any attachments to topics from documents that have been deleted
        for (TopicRecord tr : this.getAllDiscussionTopics()) {
            tr.verifyAllAttachments(this);
        }

        jsonFilePath = new File(theFile.getParent(), "WorkspaceInfo.json");

        //we can relax this and get from lazy evaluation, but need to test carefully
        //leaving this in for now
        getWorkspaceJSON();

        //search for old, outdated invitations and delete them
        removeOldInvitations();


        String name = theFile.getName();
        if (!name.equals("ProjInfo.xml")) {
            throw WeaverException.newBasic("Something is wrong with the data folder structure.  "
                        +"Tried to open a NGWorkspace file named %s"
                        +" and don't know what to do with that.", name);
        }

        File cogFolder = theFile.getParentFile();
        if (!cogFolder.getName().equalsIgnoreCase(".cog")) {
            throw WeaverException.newBasic("Something is wrong with the data folder structure.  "
                    +"Tried to open a NGWorkspace file named %s"
                    +" except it should be in a folder named .cog, however "
                    +"it was in a folder named %s", name, cogFolder.getName());
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

        // eliminate all the old unsupported attachments types, there should not be any
        // since all the other types were eliminated in 2021, but might be some somewhere
        // just throw them away because they are old, and those types were often empty
        List<String> badList = new ArrayList<>();
        for (AttachmentRecord att : getAllAttachments()) {
            if (!att.isFile() && !att.isURL()) {
                badList.add(att.getId());
            }
        }
        for (String idx : badList) {
            eraseAttachmentRecord(idx);
        }
    }


    ///////////////// TOPICS //////////////////////

    public List<TopicRecord> getAllDiscussionTopics() throws Exception {
        return Collections.unmodifiableList(noteParent.getChildren("note", TopicRecord.class));
    }

    public List<TopicRecord> getDraftNotes(AuthRequest ar)
    throws Exception {
        List<TopicRecord> list=new ArrayList<TopicRecord>();
        if (ar.isLoggedIn()) {
            List<TopicRecord> fullList = getAllDiscussionTopics();
            UserProfile thisUserId = ar.getUserProfile();
            for (TopicRecord note : fullList) {
                if (!note.isDeleted() && note.isDraftNote() && note.getModUser().equals(thisUserId)) {
                    list.add(note);
                }
            }
        }
        return list;
    }


    public TopicRecord getDiscussionTopic(String topicId) throws Exception {
        if (topicId==null) {
            //this is a program logic error so let it be known
            throw WeaverException.newBasic("Attempt to getDiscussionTopic but a NULL was passed as the topic id");
        }
        for (TopicRecord lr : getAllDiscussionTopics()) {
            if (topicId.equals(lr.getId())) {
                return lr;
            }
            if (topicId.equals(lr.getUniversalId())) {
                return lr;
            }
        }
        return null;
    }


    public TopicRecord getNoteOrFail(String noteId) throws Exception {
        TopicRecord ret =  getDiscussionTopic(noteId);
        if (ret==null) {
            throw WeaverException.newBasic("Unable to find a discussin topic (id=%s) %s",  noteId, getFullName());
        }
        return ret;
    }


    /** mark deleted, don't actually deleting the Topic. */
    public void deleteNote(String id,AuthRequest ar) throws Exception {
        TopicRecord ei = getDiscussionTopic( id );

        ei.setTrashPhase( ar );
    }

    public void unDeleteNote(String id,AuthRequest ar) throws Exception {
        TopicRecord ei = getDiscussionTopic( id );
        ei.clearTrashPhase(ar);
    }



    public List<TopicRecord> getDeletedNotes(AuthRequest ar)
    throws Exception {
        List<TopicRecord> list=new ArrayList<TopicRecord>();
        List<TopicRecord> fullList = getAllDiscussionTopics();

        for (TopicRecord note : fullList) {
            if (note.isDeleted()) {
                list.add(note);
            }
        }
        return Collections.unmodifiableList(list);
    }


    public TopicRecord createNote() throws Exception {
        TopicRecord note = noteParent.createChild("note", TopicRecord.class);
        String localId = getUniqueOnPage();
        note.setId( localId );
        note.setUniversalId(getContainerUniversalId() + "@" + localId);
        NGRole subscribers = note.getSubscriberRole();
        NGRole workspaceMembers = this.getPrimaryRole();
        subscribers.addPlayersIfNotPresent(workspaceMembers.getExpandedPlayers(this));
        return note;
    }



    /**
    * Get a four digit numeric id which is unique on the page.
    */
    @Override
    public String getUniqueOnPage()
        throws Exception
    {
        existingIds = new ArrayList<String>();

        //this is not to be trusted any more
        for (NGSection sec : getAllSections()) {
            sec.findIDs(existingIds);
        }

        //these added to be sure.  There is no harm in
        //being redundant.
        for (TopicRecord note : getAllDiscussionTopics()) {
            existingIds.add(note.getId());
        }
        for (AttachmentRecord att : getAllAttachments()) {
            existingIds.add(att.getId());
        }
        for (GoalRecord task : getAllGoals()) {
            existingIds.add(task.getId());
        }
        for (MeetingRecord meeting : this.getMeetings()) {
            existingIds.add(meeting.getId());
            for (AgendaItem ai : meeting.getAgendaItems()) {
                existingIds.add(ai.getId());
            }
        }
        return IdGenerator.generateFourDigit(existingIds);
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
        System.out.println("     file save ("+getFullName()+") tid="+Thread.currentThread().threadId()+" time="+(System.currentTimeMillis()%10000));

        NGPageIndex ngpi = ar.cog.getWSBySiteAndKey(getSiteKey(), getKey());
        ngpi.updateAllUsersFromWorkspace(this);
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
            throw WeaverException.newBasic("don't know how to make key for %s", theFile.getAbsoluteFile());
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
            throw WeaverException.newBasic("Workspace file is missing (%s)", theFile.getAbsolutePath());
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
            throw WeaverException.newBasic("Unable to read the workspace file (%s)", e, theFile.getAbsolutePath());
        }
    }



    public List<AttachmentRecord> getAllAttachments() throws Exception {
        List<AttachmentRecord> list = attachParent.getChildren("attachment", AttachmentRecord.class);
        List<AttachmentRecord> outlist = new ArrayList<>();
        for (AttachmentRecord att : list) {
            att.setContainer(this);

            boolean isDel = att.isDeleted();
            if (att.isFile()) {
                if (!isDel) {
                    String attName = att.getDisplayName();
                    if (attName==null || attName.length()==0) {
                        System.out.println("Found attachement without name, id="+att.getId()+" in workspace ("+this.getCombinedKey()+")");
                    }
                }
                outlist.add(att);
            }
            else if (att.isURL()) {
                outlist.add(att);
            }
            else {
                // all other lingering attachments types should be ignored
            }
        }
        return Collections.unmodifiableList(outlist);
    }
    public List<AttachmentRecord> getListedAttachments(List<String> idList) throws Exception {
        List<AttachmentRecord> list = new ArrayList<AttachmentRecord>();
        for (AttachmentRecord aRec : getAllAttachments()) {
            for (String universalId : idList) {
                if (aRec.getUniversalId().equals(universalId)) {
                    list.add(aRec);
                }
            }
        }
        return Collections.unmodifiableList(list);
    }
    public AttachmentRecord findAttachmentOrNull(String docId) throws Exception {
        for (AttachmentRecord aRec : getAllAttachments()) {
            if (aRec.getUniversalId().equals(docId)) {
                return aRec;
            }
            if (aRec.getId().equals(docId)) {
                return aRec;
            }
        }
        return null;
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
            return null;
        }
        AttachmentVersion aVer = attach.getLatestVersion(this);
        if (aVer==null) {
            return null;
        }
        return(aVer.getLocalFile());
    }


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

    public boolean suppressEmail() {
        return pageInfo.getAttributeBool("suppressEmail");
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
        if (getAllEmail().size()>0) {
            //if any email is found in the workspace, then immediately mark it as
            //needing an action.   The background email processing will move all email to DB.
            System.out.println("!!!!!!!\n\n\n\n~~~~~~~\n EMAIL FOUND IN workspace: "+this.getCombinedKey());
            return System.currentTimeMillis()-100000;
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

    public boolean transferEmailToDB(Cognoscenti cog, EmailSender sender) throws Exception {
        List<EmailRecord> allEmail = getAllEmail();
        if (allEmail.size()==0) {
            return false;
        }

        //at this point, this should NEVER be happening.   Remove this routine.

        System.out.println("!!!!!!!\n\n\n\n~~~~~~~\n EMAIL BEING REMOVED FROM WORKSPACE: "+this.getFullName());
        for (EmailRecord er : allEmail) {
            String fullFromAddress = er.getFromAddress();
            AddressListEntry fromAle = AddressListEntry.parseCombinedAddress(fullFromAddress);
            List<OptOutAddr> allAddressees = er.getAddressees();
            for (OptOutAddr oaa : allAddressees) {
                //create a message for each addressee ... actually there is
                //usually only one so this usually creates only a single email
                MailInst inst = createMailInst();
                inst.setAddressee(oaa.getEmail());
                inst.setStatus(MailInst.SENT);    //suppress the sending of anything in here
                inst.setSubject(er.getSubject());
                inst.setFromAddress(fromAle.getEmail());
                inst.setFromName(fromAle.getName());
                oaa.prepareInternalMessage(cog);
                inst.setBodyText(er.getBodyText()+oaa.getUnSubscriptionAsString());
                inst.setLastSentDate(er.getLastSentDate());
                ArrayList<File> attachments = new ArrayList<File>();
                for (String id : er.getAttachmentIds()) {
                    File path = getAttachmentPathOrNull(id);
                    if (path!=null) {
                        attachments.add(path);
                    }
                }
                inst.setAttachmentFiles(attachments);
                sender.updateEmailInDB(inst);
            }
        }
        clearAllEmail();
        return true;
    }
    /**
     * This will delete all email records in the workspace (workspace)
     */
    private void clearAllEmail() throws Exception {
        DOMFace mail = requireChild("mail", DOMFace.class);
        mail.clearVector("email");
    }
    public MailInst createMailInst() throws Exception {
        MailInst msg = new MailInst();
        msg.setSiteKey(getSiteKey());
        msg.setWorkspaceKey(getKey());
        if (suppressEmail()) {
            //if this workspace is not supposed to send email, then generate
            //the email in the already sent state
            msg.setStatus(MailInst.SUPPRESS);
        }
        return msg;
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
    public boolean generateNotificationEmail(AuthRequest ar, EmailSender sender, long nowTime) throws Exception {
        boolean sentMessage = false;
        //now open the page and generate all the email messages, remember this
        //locks the file blocking all other threads, so be quick
        ArrayList<ScheduledNotification> resList = new ArrayList<ScheduledNotification>();
        gatherUnsentScheduledNotification(resList, nowTime);

        for (ScheduledNotification sn : resList) {
            if (sn.needsSendingBefore(nowTime)) {
                sn.sendIt(ar, sender);
                sentMessage = true;
            }
        }
        return sentMessage;
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
     * of the workspace folder.
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
        return Collections.unmodifiableList(res);
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
        throw WeaverException.newBasic("Could not find a share port with the id=%s", id);
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
            for (TopicRecord topic : this.getAllDiscussionTopics()) {
                NGRole assignee = topic.getSubscriberRole();
                if (assignee.replaceId(sourceUser, destUser)) {
                    count++;
                }
            }
            for (MeetingRecord meet : this.getMeetings()) {
                List<String> newList = new ArrayList<String>();
                boolean found = false;
                for (String part : meet.getParticipants()) {
                    if (sourceUser.equalsIgnoreCase(part)) {
                        part = destUser;
                        found = true;
                    }
                    if (!newList.contains(part)) {
                        newList.add(part);
                    }
                }
                if (found) {
                    meet.setParticipants(newList);
                    count++;
                }
                if (meet.removeFromRollCall(sourceUser)) {
                    count++;
                }
                if (meet.removeFromAttended(sourceUser)) {
                    count++;
                }
                count += meet.removeFromTimeSlots(sourceUser);
            }
            return count;
        }
        catch (Exception e) {
            throw WeaverException.newBasic("Unable to replace user (%s) in workspace: %s", e, sourceUser, this.getKey());
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
            throw WeaverException.newBasic("Can not find any task area named %s", id);
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
        throw WeaverException.newBasic("Could not find a task area with the id=%s", id);
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
        return Collections.unmodifiableList(res);
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
        String emailId = ale.getEmail();

        // this might not actually be an email address so check and skip otherwise
        Matcher matcher = pattern.matcher(emailId.trim());
        if (!matcher.matches()) {
            throw new SimpleException("This email id (%s) does not look like an email address", emailId);
        }
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
            throw WeaverException.newBasic("Unable to find any comment (%s) on workspace %s", cid, this.getFullName());
        }
        return com;
    }
    public CommentContainer getCommentContainer(long cid) throws Exception {
        for (TopicRecord note : this.getAllDiscussionTopics()) {
            for (CommentRecord comm : note.getComments()) {
                if (comm.getTime()==cid) {
                    return note;
                }
            }
        }
        for (MeetingRecord meet : getMeetings()) {
            for (AgendaItem ai : meet.getAgendaItems()) {
                for (CommentRecord comm : ai.getComments()) {
                    if (comm.getTime()==cid) {
                        return ai;
                    }
                }
            }
        }
        for (AttachmentRecord doc : this.getAllAttachments()) {
            for (CommentRecord comm : doc.getComments()) {
                if (comm.getTime()==cid) {
                    return doc;
                }
            }
        }
        return null;
    }
    public CommentContainer findContainerByKey(String searchKey) throws Exception {

        for (MeetingRecord meet : getMeetings()) {
            for (AgendaItem ai : meet.getAgendaItems()) {
                if (searchKey.equals(ai.getGlobalContainerKey(this))) {
                    return ai;
                }
            }
        }
        for (TopicRecord topic : getAllDiscussionTopics()) {
            if (searchKey.equals(topic.getGlobalContainerKey(this))) {
                return topic;
            }
        }
        for (AttachmentRecord att : getAllAttachments()) {
            if (searchKey.equals(att.getGlobalContainerKey(this))) {
                return att;
            }
        }
        System.out.println("COMMENT-CONTAINER: attempt to find container not found: "+searchKey);
        return null;
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
            File cogFolder = this.getFilePath().getParentFile();
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



    public JSONObject getConfigJSON() throws Exception {

        JSONObject workspaceConfigInfo = new JSONObject();
        workspaceConfigInfo.put("key", getKey());
        workspaceConfigInfo.put("site", getSiteKey());
        workspaceConfigInfo.put("parentKey", getParentKey());
        workspaceConfigInfo.put("frozen", isFrozen() || isDeleted());
        workspaceConfigInfo.put("deleted", isDeleted());
        if (isDeleted()) {
            workspaceConfigInfo.put("deleteDate", pageInfo.getDeleteDate());
            workspaceConfigInfo.put("deleteUser", UserManager.getCorrectedEmail(pageInfo.getDeleteUser()));
        }
        workspaceConfigInfo.put("accessState", getAccessStateStr());
        pageInfo.extractAttributeBool(workspaceConfigInfo, "suppressEmail");

        //read only information from the site
        workspaceConfigInfo.put("showExperimental", this.getSite().getShowExperimental());

        //returns all the names for this page
        List<String> nameSet = getPageNames();
        workspaceConfigInfo.put("allNames", constructJSONArray(nameSet));

        ProcessRecord process = getProcess();
        workspaceConfigInfo.put("goal", process.getSynopsis());
        workspaceConfigInfo.put("purpose", process.getDescription());  //a.k.a. 'aim'
        process.extractScalarString(workspaceConfigInfo, "mission");
        process.extractScalarString(workspaceConfigInfo, "vision");
        process.extractScalarString(workspaceConfigInfo, "domain");
        workspaceConfigInfo.put("wsSettings", getWSSettings());
        return workspaceConfigInfo;
    }

    public void updateConfigJSON(AuthRequest ar, JSONObject newConfig) throws Exception {
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
        pageInfo.updateAttributeBool("suppressEmail", newConfig);

        ProcessRecord process = getProcess();
        process.updateScalarString("goal", newConfig);
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



    @Override
    public NGRole getPrimaryRole() throws Exception {
        return getRequiredRole("Members");
    }
    @Override
    public NGRole getSecondaryRole() throws Exception {
        return getRequiredRole("Administrators");
    }

    public NGRole getMuteRole() throws Exception {
        return pageInfo.requireChild("muteRole", CustomRole.class);
    }





    /**
     * This gives a definitive response of whether this workspace can be updated
     * by the given user.  It checks all roles, and anyone in any role will be
     * able to have read-only access, but if the role is a role that allows update
     * then they will have update access.
     */
    public boolean canUpdateWorkspace(UserProfile user) throws Exception {
        //The administrator can control which users are update users and
        //which users are read only.
        if (getSite().userReadOnly(user)) {
            return false;
        }
        //now look through all the roles and see if this person plays any
        //that allow update
        for (NGRole role : this.getAllRoles()) {
            if (role.allowUpdateWorkspace()) {
                if (role.isExpandedPlayer(user, this)) {
                    return true;
                }
            }
        }
        return false;
    }
    public boolean canAccessWorkspace(UserRef user) throws Exception {
        for (NGRole role : this.getAllRoles()) {
            if (role.isExpandedPlayer(user, this)) {
                    return true;
            }
        }
        return false;
    }
    public String getGlobalContainerKey() {
        return "S"+getSiteKey()+"|W"+getKey();
    }


}