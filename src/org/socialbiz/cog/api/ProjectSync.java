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

package org.socialbiz.cog.api;

import java.io.File;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.List;
import java.util.Vector;

import org.socialbiz.cog.AttachmentRecord;
import org.socialbiz.cog.AttachmentVersion;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.GoalRecord;
import org.socialbiz.cog.HistoryRecord;
import org.socialbiz.cog.LicenseForUser;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.NoteRecord;
import org.socialbiz.cog.SectionDef;
import org.socialbiz.cog.UtilityMethods;
import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;

/**
* supports comparing a local and remote project
*/
public class ProjectSync {
    NGPage local;
    RemoteProject remote;
    AuthRequest ar;
    String licenseID;

    Vector<SyncStatus> statii;

    public ProjectSync(NGPage _local, RemoteProject _remote, AuthRequest _ar, String _licenseID) throws Exception {

        local     = _local;
        remote    = _remote;
        ar        = _ar;
        licenseID = _licenseID;

        statii = new Vector<SyncStatus>();

        figureAttachments();
        figureNotes();
        figureGoals();

    }

    private void figureAttachments() throws Exception {

        Vector<String> docNames = new Vector<String>();
        List<AttachmentRecord> allAtts = local.getAllAttachments();
        for (AttachmentRecord att : allAtts) {
            if (!"FILE".equals(att.getType())) {
                continue;
            }
            if (att.isDeleted()) {
                continue;
            }
            if (!att.isUpstream()) {
                //simply ignore any attachments not marked for upstream.
                //this has the problem that if you UNCHECK the upstream,
                //then it will think you need to download another version
                //of the document.  However, that seems like the only
                //option, otherwise the document would 'hide' the upstream
                //document.  User has control and it is consistent.
                continue;
            }
            String attName = att.getUniversalId();
            docNames.add(attName);
        }
        JSONArray att2s = remote.getDocs();
        int len = att2s.length();
        for (int i=0; i<len; i++) {
            JSONObject oneAtt = att2s.getJSONObject(i);
            String attName = oneAtt.getString("universalid");
            if (!docNames.contains(attName)) {
                docNames.add(attName);
            }
        }
        for (String docName : docNames) {
            statii.add( findDocStatus( docName, allAtts, att2s ) );
        }
    }

    private SyncStatus findDocStatus(String docUID, List<AttachmentRecord> atts, JSONArray att2s) throws Exception {
        SyncStatus retval = new SyncStatus(this, SyncStatus.TYPE_DOCUMENT, docUID);

        for (AttachmentRecord att : atts) {

            //this avoids deleted files .. there might be multiple deleted files
            //with the same name.  Be sure not to look for them!
            if (!"FILE".equals(att.getType())) {
                continue;
            }
            String attName = att.getUniversalId();
            if (docUID.equals(attName)) {
                retval.isLocal = true;
                retval.nameLocal = att.getNiceName();
                retval.timeLocal = att.getModifiedDate();
                retval.urlLocal = att.getLicensedAccessURL(ar, local, licenseID);
                retval.idLocal = att.getId();
                retval.sizeLocal = att.getFileSize(local);
                retval.editorLocal = att.getModifiedBy();
                retval.descLocal   = att.getDescription();
                break;
            }
        }
        int len = att2s.length();
        for (int i=0; i<len; i++) {
            JSONObject att2 = att2s.getJSONObject(i);
            String attName = att2.getString("universalid");
            if (docUID.equals(attName)) {
                retval.isRemote = true;
                retval.idRemote = att2.getString("id");
                retval.nameRemote = att2.getString("name");
                retval.timeRemote = att2.getLong("modifiedtime");
                if (retval.timeRemote==0) {
                    throw new Exception("Something is wrong with information about remote document ("
                            +retval.nameRemote+") (id="+retval.idRemote
                            +") because the timestamp is zero");
                }
                retval.urlRemote = att2.getString("content");
                retval.sizeRemote = att2.getLong("size");
                retval.editorRemote = att2.getString("modifieduser");
                retval.remoteCopy = att2;
                break;
            }
        }

        return retval;
    }

    private void figureNotes() throws Exception {

        Vector<String> noteIds = new Vector<String>();

        List<NoteRecord> allNotes = local.getAllNotes();
        for (NoteRecord note : allNotes) {
            if (note.getVisibility()>SectionDef.MEMBER_ACCESS) {
                continue;
            }
            if (note.isDraftNote()) {
                //never communicate drafts
                continue;
            }
            noteIds.add(note.getUniversalId());
        }
        JSONArray notes2 = remote.getNotes();
        int len = notes2.length();
        for (int i=0; i<len; i++) {
            JSONObject noteRef = notes2.getJSONObject(i);
            String noteName = noteRef.getString("universalid");
            if (!noteIds.contains(noteName)) {
                noteIds.add(noteName);
            }
        }
        for (String noteId : noteIds) {
            statii.add( findNoteStatus( noteId, allNotes, notes2 ) );
        }
    }

    private SyncStatus findNoteStatus(String noteId, List<NoteRecord> noteList,
            JSONArray notes2) throws Exception {
        SyncStatus retval = new SyncStatus(this, SyncStatus.TYPE_NOTE, noteId);

        for (NoteRecord note : noteList) {

            //this avoids deleted notes!
            if (note.getVisibility()>SectionDef.MEMBER_ACCESS) {
                continue;
            }
            String uid = note.getUniversalId();
            if (uid.equals(noteId)) {
                retval.isLocal = true;
                retval.timeLocal = note.getLastEdited();
                retval.urlLocal = note.getWiki();
                retval.idLocal = note.getId();
                retval.nameLocal = note.getSubject();
                retval.editorLocal = note.getModUser().getUniversalId();
                break;
            }
        }
        int len = notes2.length();
        for (int i=0; i<len; i++) {
            JSONObject noteRef = notes2.getJSONObject(i);
            String uid = noteRef.getString("universalid");
            if (noteId.equals(uid)) {
                retval.isRemote = true;
                retval.timeRemote = noteRef.getLong("modTime");
                retval.urlRemote = noteRef.getString("content");
                retval.idRemote = noteRef.getString("id");
                retval.nameRemote = noteRef.getString("subject");
                JSONObject userObj = noteRef.getJSONObject("modUser");
                retval.editorRemote = userObj.getString("uid");
                retval.remoteCopy = noteRef;
                break;
            }
        }
        return retval;
    }


    private void figureGoals() throws Exception {
        Vector<String> goalIds = new Vector<String>();

        List<GoalRecord> allGoals = local.getAllGoals();
        /*
        We don't walk through the local goals because:
        1) local goals created here are never sent upstream
        2) remote action items can not be changed here, and will never
           be updated back.
        So we never hae any case where we send action items from here upstream
        Only download if remote action items have changed.
        */
        JSONArray goals2 = remote.getGoals();
        int len = goals2.length();
        for (int i=0; i<len; i++) {
            JSONObject goal2 = goals2.getJSONObject(i);
            String goalName = goal2.getString("universalid");
            if (!goalIds.contains(goalName)) {
                goalIds.add(goalName);
            }
        }
        for (String goalId : goalIds) {
            statii.add( findGoalStatus( goalId, allGoals, goals2 ) );
        }
    }


    private SyncStatus findGoalStatus(String goalId, List<GoalRecord> goalList, JSONArray remGoals) throws Exception {
        SyncStatus retval = new SyncStatus(this, SyncStatus.TYPE_TASK, goalId);
        for (GoalRecord goal : goalList) {
            String uid = goal.getUniversalId();
            if (uid.equals(goalId)) {
                retval.isLocal = true;
                retval.timeLocal = goal.getModifiedDate();
                retval.editorLocal = goal.getModifiedBy();
                retval.idLocal = goal.getId();
                retval.nameLocal = goal.getSynopsis();
                retval.assigneeLocal = goal.getAssigneeCommaSeparatedList();
                retval.sizeLocal = goal.getState();
                retval.priorityLocal = goal.getPriority();
                retval.descLocal   = goal.getDescription();
                break;
            }
        }
        int len = remGoals.length();
        for (int i=0; i<len; i++) {
            JSONObject remGoalObj = remGoals.getJSONObject(i);
            String uid = remGoalObj.getString("universalid");
            if (goalId.equals(uid)) {
                retval.isRemote = true;
                retval.timeRemote = remGoalObj.getLong("modifiedtime");
                retval.idRemote = remGoalObj.getString("id");
                retval.nameRemote = remGoalObj.getString("synopsis");
                retval.editorRemote = remGoalObj.getString("modifieduser");
                retval.sizeRemote = remGoalObj.getInt("state");
                retval.urlRemote = remGoalObj.optString("ui");
                retval.remoteCopy = remGoalObj;
                break;
            }
        }
        return retval;
    }


    public Vector<SyncStatus> getStatus() {
        return statii;
    }

    /**
    * Pass the type of resource, either SyncStatus.TYPE_DOCUMENT,
    * SyncStatus.TYPE_NOTE, or SyncStatus.TYPE_TASK.
    * Returns a collection that represents all the resources that
    * need to be downloaded.
    */
    public Vector<SyncStatus> getToDownload(int resourceType) {
        Vector<SyncStatus> retset = new Vector<SyncStatus>();
        for (SyncStatus stat : statii) {
            if (stat.type != resourceType) {
                //only interested specified resource type
                continue;
            }
            if (!stat.isRemote) {
                //if there is no remote then you can't download
                continue;
            }
            // if there is no local, or if local is older, or if sizes different regardless of age
            boolean couldDown = (!stat.isLocal
                    ||  stat.timeLocal < stat.timeRemote
                    || (stat.timeLocal == stat.timeRemote  && stat.sizeLocal != stat.sizeRemote)  );

            if (couldDown) {
                retset.add(stat);
            }
        }
        return retset;
    }

    /**
    * Pass the type of resource, either SyncStatus.TYPE_DOCUMENT,
    * SyncStatus.TYPE_NOTE, or SyncStatus.TYPE_TASK.
    * Returns a collection that represents all the resources that
    * need to be uploaded to the upstream site.
    */
    public Vector<SyncStatus> getToUpload(int resourceType) {
        Vector<SyncStatus> retset = new Vector<SyncStatus>();
        for (SyncStatus stat : statii) {
            if (stat.type != resourceType) {
                //only interested specified resource type
                continue;
            }
            if (!stat.isLocal) {
                //if there is no local then you can't upload
                continue;
            }
            // if there is no remote, or if local is newer
            boolean couldUp   = (!stat.isRemote || stat.timeLocal > stat.timeRemote );

            if (couldUp) {
                retset.add(stat);
            }
        }
        return retset;
    }

    /**
    * Pass the type of resource, either SyncStatus.TYPE_DOCUMENT,
    * SyncStatus.TYPE_NOTE, or SyncStatus.TYPE_TASK.
    * Returns a collection that represents all the resources that
    * are fully synchronized and need no additional handling
    */
    public Vector<SyncStatus> getEqual(int resourceType) {
        Vector<SyncStatus> retset = new Vector<SyncStatus>();
        for (SyncStatus stat : statii) {
            if (stat.type != resourceType) {
                //only interested specified resource type
                continue;
            }
            if (!stat.isLocal || !stat.isRemote) {
                //can't be equal if one is missing
                continue;
            }
            // only if they both have same timestamp and size
            boolean isEqual = (stat.timeLocal == stat.timeRemote
                               && stat.sizeLocal == stat.sizeRemote);

            if (isEqual) {
                retset.add(stat);
            }
        }
        return retset;
    }


    /**
    * This will walk through the discrepancies, and it will transfer documents or
    * notes until the projects are in sync.
    * *
    * Normally an upstream document with a universal ID will be matched with the
    * downstream document with that same ID, and they will have the same name.
    *
    * What happens when you have documents that have different universal IDs but
    * the same name?  This can happen if a document was added upstream and downstream
    * with the same name at the same time, and upon synchronization the name clash
    * is noticed.  Each project does not allow duplicate files with the same
    * name.
    *
    * Principle 1: upstream wins.  If there is a name clash, then the upstream
    * file keeps the name, and the downstream file has to change name.
    */
    public void downloadAll() throws Exception {

        int docNum = 0;
        int noteNum = 0;
        int goalNum = 0;

        Vector<SyncStatus> docsNeedingDown  = getToDownload(SyncStatus.TYPE_DOCUMENT);
        for (SyncStatus docStat : docsNeedingDown) {
            if (docStat.timeRemote==0) {
                //this is a programming consistency thing.  A doc falls into the needing
                //download category only when it has a reasonable remote timestamp
                throw new Exception("Something is wrong with information about remote document ("
                        +docStat.nameRemote+") because the timestamp is zero");
            }
            AttachmentRecord localAtt;
            String newName = docStat.nameRemote;  //might be a new name or same old name
            if (docStat.isLocal) {
                localAtt = local.findAttachmentByID(docStat.idLocal);
                if (!localAtt.isUpstream()) {
                    //this is the case of a 'severed' sync.  The User has marked this local document
                    //to NOT be synchronized upstream, so it is cut off.  Do not synchronize this
                    //document
                    //TODO: should we tell the user that a document was skipped?
                    continue;
                    //throw new Exception("Synchronization error with document ("+docStat.idLocal
                    //        +") because local version has been marked as NOT being sychronized upstream.");
                }
                //check of name change scenario
                if (!newName.equals(localAtt.getNiceName())) {
                    //in this case will will have to change the name, check first that there
                    //will not a local name conflict.
                    AttachmentRecord otherFileWithSameName = local.findAttachmentByName(newName);
                    if (otherFileWithSameName!=null) {
                        //this is the name conflict ... a local document exists with that name
                        //that this document is going to be, so ignore the sync request.
                        continue;
                        //TODO: should we tell the user about this problem?
                    }
                }
                HistoryRecord.createAttHistoryRecord(local, localAtt, HistoryRecord.EVENT_DOC_UPDATED, ar,
                        "from upstream project");
            }
            else {
                //this is a new document to us, but check for name conflict
                AttachmentRecord otherFileWithSameName = local.findAttachmentByName(newName);
                if (otherFileWithSameName!=null) {
                    //this is the name conflict ... a local document exists with that name
                    //so don't attempt to synchronize it
                    continue;
                    //TODO: should we tell the user about this problem?
                }

                localAtt = local.createAttachment();
                localAtt.setUniversalId(docStat.universalId);
                //this document came from upstream, so set to synch in the future upstream
                localAtt.setUpstream(true);
                HistoryRecord.createAttHistoryRecord(local, localAtt, HistoryRecord.EVENT_TYPE_CREATED, ar,
                        "from upstream project");
            }
            localAtt.updateDocFromJSON(docStat.remoteCopy, ar);
            String modifieduser = docStat.remoteCopy.getString("modifieduser");
            long modifiedtime = docStat.remoteCopy.getLong("modifiedtime");

            URL link = new URL(docStat.urlRemote);
            InputStream is = link.openStream();
            localAtt.streamNewVersion(local, is, modifieduser, modifiedtime);
            docNum++;
        }

        Vector<SyncStatus> notesNeedingDown  = getToDownload(SyncStatus.TYPE_NOTE);

        for (SyncStatus noteStat : notesNeedingDown) {

            NoteRecord note;
            int historyEvent = 0;
            if (noteStat.isLocal) {
                note = local.getNote(noteStat.idLocal);
                historyEvent = HistoryRecord.EVENT_TYPE_MODIFIED;
            }
            else {
                note = local.createNote();
                note.setUniversalId(noteStat.universalId);
                note.setUpstream(true);
                historyEvent = HistoryRecord.EVENT_TYPE_CREATED;
            }

            URL url = new URL(noteStat.urlRemote);
            InputStream is = url.openStream();
            InputStreamReader isr = new InputStreamReader(is, "UTF-8");
            StringBuffer sb = new StringBuffer();
            char[] buf = new char[800];
            int amt = isr.read(buf);
            while (amt>0) {
                sb.append(buf,0,amt);
                amt = isr.read(buf);
            }
            noteStat.remoteCopy.put("data", sb.toString());
            note.updateNoteFromJSON(noteStat.remoteCopy, ar);
            noteNum++;
            HistoryRecord.createNoteHistoryRecord(local, note, historyEvent, ar,
                    "from upstream project");
        }

        Vector<SyncStatus> goalsNeedingDown  = getToDownload(SyncStatus.TYPE_TASK);
        for (SyncStatus goalStat : goalsNeedingDown) {

            GoalRecord goal;
            if (goalStat.isLocal) {
                goal = local.getGoalOrFail(goalStat.idLocal);
            }
            else {
                goal = local.createGoal("%fake creator%");
                goal.setUniversalId(goalStat.universalId);
                goal.setPassive(true);
                goal.setRemoteUpdateURL(goalStat.urlRemote);
            }
            goal.updateGoalFromJSON(goalStat.remoteCopy, local, ar);
            goalNum++;
        }

        if (docNum+noteNum+goalNum>0) {
            HistoryRecord.createContainerHistoryRecord(local,
                HistoryRecord.EVENT_DOC_UPDATED, ar, "Synchronized from upstream workspace:  "+docNum+" documents, "
                +noteNum+" topics, and "+goalNum+" action items.");
        }

        local.saveFile(ar, "Synchronized topics and documents from upstream workspace");
    }

    /**
    * This will walk through the discrepancies, and send all documents up
    * to the upstream project.
    */
    public void uploadAll() throws Exception {

        String urlRoot = ar.baseURL + "api/" + local.getSiteKey() + "/" + local.getKey() + "/";
        Vector<SyncStatus> goalsNeedingUp  = getToUpload(SyncStatus.TYPE_TASK);

        //This license is not really used after upload is complete, so any license will do
        LicenseForUser lfu = new LicenseForUser(ar.getUserProfile());

        for (SyncStatus goalStat : goalsNeedingUp) {

            GoalRecord goal = local.getGoalOrNull(goalStat.universalId);
            JSONObject goalObj = goal.getJSON4Goal(local, ar.baseURL, lfu);
            JSONObject request = new JSONObject();
            if (goalStat.isRemote) {
                request.put("operation", "updateGoal");
            }
            else {
                request.put("operation", "newGoal");
            }
            request.put("goal", goalObj);
            remote.call(request);
        }
        Vector<SyncStatus> docsNeedingUp  = getToUpload(SyncStatus.TYPE_DOCUMENT);
        for (SyncStatus docStat : docsNeedingUp) {
            AttachmentRecord newAtt = local.findAttachmentByIDOrFail(docStat.idLocal);

            //first we make a quick request to the project to get a temp file name to send to
            JSONObject tempFileRequest = new JSONObject();
            tempFileRequest.put("operation", "tempFile");
            JSONObject response = remote.call(tempFileRequest);
            String tempFileName = response.getString("tempFileName");
            String tempFileURL = response.getString("tempFileURL");

            //now upload the contents to the tempfile address
            AttachmentVersion aVer = newAtt.getLatestVersion(local);
            File docFile = aVer.getLocalFile();
            URL remoteURL = new URL(tempFileURL);
            System.out.println("Ready to PUT to: "+tempFileURL);
            HttpURLConnection httpCon = (HttpURLConnection) remoteURL.openConnection();
            httpCon.setDoOutput(true);
            httpCon.setRequestProperty( "Content-Type", "application/octet-stream" );
            httpCon.setRequestMethod("PUT");
            httpCon.setUseCaches(false);
            httpCon.setDoInput(true);
            httpCon.setConnectTimeout(60000); //60 secs
            httpCon.setReadTimeout(60000); //60 secs
            httpCon.setRequestProperty("Accept-Encoding", "application/octet-stream");
            httpCon.connect();
            OutputStream os = httpCon.getOutputStream();
            UtilityMethods.streamFileContents(docFile, os);
            os.flush();
            os.close();
            httpCon.getInputStream();
            if (httpCon.getResponseCode()!=200) {
                throw new Exception("Attempt to PUT file failed with code ("
                        +httpCon.getResponseCode()+"): "+tempFileURL);
            }
            //there is a response... should it be read here?

            //Now, make the temp file official
            JSONObject request = new JSONObject();
            if (docStat.isRemote) {
                request.put("operation", "updateDoc");
            }
            else {
                request.put("operation", "newDoc");
            }
            request.put("tempFileName", tempFileName);
            newAtt = local.findAttachmentByID(docStat.idLocal);
            request.put("doc", newAtt.getJSON4Doc(local, ar, urlRoot, lfu));
            response = remote.call(request);
        }
        Vector<SyncStatus> notesNeedingUp  = getToUpload(SyncStatus.TYPE_NOTE);
        for (SyncStatus docStat : notesNeedingUp) {
            NoteRecord note = local.getNoteOrFail(docStat.idLocal);
            JSONObject request = new JSONObject();
            if (docStat.isRemote) {
                request.put("operation", "updateNote");
            }
            else {
                request.put("operation", "newNote");
            }
            request.put("note", note.getJSON4Note(urlRoot, true, lfu, local));
            remote.call(request);
        }

    }



    public void pingUpstream() throws Exception {
        JSONObject msg = new JSONObject();
        msg.put("operation", "ping");
        JSONObject resp = remote.call(msg);
        String op = resp.getString("operation");
        if (op==null || op.length()==0) {
            throw new Exception("Unable to contact server for a PING response, no operation in response object from: "
                    +remote.urlStr);
        }
        if (!"ping".equals(op)) {
            throw new Exception("Error in PING response, wrong operation returned: "+op);
        }
        //otherwise the PING is all OK, so no news is good news
    }
}
