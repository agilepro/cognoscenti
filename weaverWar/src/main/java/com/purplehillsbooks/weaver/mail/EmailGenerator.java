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

package com.purplehillsbooks.weaver.mail;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.MemFile;
import com.purplehillsbooks.weaver.AccessControl;
import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.AgendaItem;
import com.purplehillsbooks.weaver.AttachmentRecord;
import com.purplehillsbooks.weaver.AuthDummy;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.DOMFace;
import com.purplehillsbooks.weaver.GoalRecord;
import com.purplehillsbooks.weaver.MeetingRecord;
import com.purplehillsbooks.weaver.NGLabel;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.SectionUtil;
import com.purplehillsbooks.weaver.TopicRecord;
import com.purplehillsbooks.weaver.UserManager;
import com.purplehillsbooks.weaver.UserProfile;

/**
 * People create this, and this creates emails, sent possibly in
 * the future, and records the fact that the emails have been sent.
 */
public class EmailGenerator extends DOMFace {

    public EmailGenerator(Document nDoc, Element nEle, DOMFace p) {
        super(nDoc, nEle, p);

        //schema migration stuff
        if (getState()<EG_STATE_DRAFT) {
            setState(EG_STATE_DRAFT);
        }
    }

    public String getId() throws Exception {
        return getAttribute("id");
    }

    public void setId(String newVal) throws Exception {
        setAttribute("id", newVal);
    }

    public static final int EG_STATE_DRAFT     = 1;
    public static final int EG_STATE_SCHEDULED = 2;
    public static final int EG_STATE_SENT      = 3;

    public int getState() {
        return getAttributeInt("state");
    }
    public void setState(int newVal) {
        setAttributeInt("state", newVal);
    }


    /**
     * The owner is the actual user who created this record.  The email
     * will have the same access privileges at that user regardless of
     * who sends it in the future?
     */
    public String getOwner() throws Exception {
        return getScalar("owner");
    }
    public void setOwner(String newVal) throws Exception {
        setScalar("owner", newVal);
    }


    public String getSubject() throws Exception {
        return getScalar("subject");
    }

    public void setSubject(String newVal) throws Exception {
        setScalar("subject", newVal);
    }

    public String getIntro() throws Exception {
        return getScalar("intro");
    }

    public void setIntro(String newVal) throws Exception {
        setScalar("intro", newVal);
    }

    public long getSendDate() throws Exception {
        return safeConvertLong(getScalar("sendDate"));
    }
    public void setSendDate(long newVal) throws Exception {
        setScalar("sendDate", Long.toString(newVal));
    }

    /**
     * The email can be scheduled to be sent at a time in the future.
     * If the email is set to status EG_STATE_SCHEDULED then this
     * member tells the time that it should be sent.  The email can
     * (and should) be sent any time this time is in the past.
     * Let it wait if this time is in the future.
     * Of course, once sent the status should change to
     * EG_STATE_SENT and this value does not matter.
     */
    public long getScheduleTime() throws Exception {
        return safeConvertLong(getScalar("scheduleTime"));
    }
    public void setScheduleTime(long newVal) throws Exception {
        setScalar("scheduleTime", Long.toString(newVal));
    }


    public List<String> getRoleNames() throws Exception {
        return getVector("roleName");
    }

    public void setRoleNames(List<String> newVal) throws Exception {
        setVector("roleName", newVal);
    }

    public List<String> getAlsoTo() throws Exception {
        return getVector("alsoTo");
    }

    public void setAlsoTo(List<String> newVal) throws Exception {
        setVector("alsoTo", newVal);
    }

    public String getNoteId() throws Exception {
        return getScalar("noteId");
    }

    public void setNoteId(String newVal) throws Exception {
        setScalar("noteId", newVal);
    }

    public String getMeetingId() throws Exception {
        return getScalar("meetingId");
    }

    public void setMeetingId(String newVal) throws Exception {
        setScalar("meetingId", newVal);
    }

    /**
     * A list of document universalid values which have been selected
     * by the user for attachments to the email.
     */
    public List<String> getAttachments() throws Exception {
        return getVector("attachment");
    }

    public void setAttachments(List<String> newVal) throws Exception {
        setVector("attachment", newVal);
    }


    public boolean getExcludeResponders() throws Exception {
        return getAttributeBool("excludeResponders");
    }

    public void setExcludeResponders(boolean newVal) throws Exception {
        this.setAttributeBool("excludeResponders", newVal);
    }

    /**
     * This boolean controls whether the body of the NOTE is included
     * in the message, or whether the topic is simply linked.
     */
    public boolean getIncludeBody() throws Exception {
        return getAttributeBool("includeBody");
    }

    public void setIncludeBody(boolean newVal) throws Exception {
        this.setAttributeBool("includeBody", newVal);
    }

    /**
     * This boolean determines whether to include the attachments as
     * actual email attachments, or just to link to them in the message.
     */
    public boolean getAttachFiles() throws Exception {
        return getAttributeBool("attachFiles");
    }

    public void setAttachFiles(boolean newVal) throws Exception {
        this.setAttributeBool("attachFiles", newVal);
    }



    public void scheduleEmail(AuthRequest ar) throws Exception {
        long aboutFifteenMinutesAgo = ar.nowTime - 15 * 60000;
        if (getScheduleTime()<aboutFifteenMinutesAgo) {
            throw new JSONException("To schedule the email for sending, the schedule time has to be in the future.  Schedule time currently set to: {0}",
                SectionUtil.getNicePrintDate(getScheduleTime()));
        }
        setState(EG_STATE_SCHEDULED);
    }


    /**
     * Different people will be receiving email for different reasons ... they might be in
     * a particular role, or they might be addressed directly.   This returns the right
     * OptOutAddress object for the given user ID.
     */
    public OptOutAddr getOOAForUserID(AuthRequest ar, NGWorkspace ngw, String userId) throws Exception {
        for (OptOutAddr ooa : expandAddresses(ar, ngw)) {
            if (ooa.matches(userId))  {
                return ooa;
            }
        }

        //didn't find them, then act as if they were directly added
        return new OptOutDirectAddress(new AddressListEntry(userId));
    }


    public List<OptOutAddr> expandAddresses(AuthRequest ar, NGWorkspace ngw) throws Exception {
        List<OptOutAddr> sendTo = new ArrayList<OptOutAddr>();
        for (String address : getAlsoTo()) {
            AddressListEntry enteredAddress = AddressListEntry.parseCombinedAddress(address);
            if (enteredAddress.isWellFormed()) {
                OptOutAddr.appendOneUser(new OptOutDirectAddress(enteredAddress), sendTo);
            }
        }
        
        return sendTo;
    }


    public void constructEmailRecords(AuthRequest ar, NGWorkspace ngw, EmailSender mailFile) throws Exception {
        List<OptOutAddr> sendTo = expandAddresses(ar, ngw);

        StringBuilder historyNameList = new StringBuilder();
        boolean needComma = false;
        for (OptOutAddr ooa : sendTo) {
            String addr = ooa.getEmail();
            if (addr!=null && addr.length()>0) {
                constructEmailRecordOneUser(ar, ngw, ooa, mailFile);
                if (needComma) {
                    historyNameList.append(",");
                }
                historyNameList.append(addr);
                needComma= true;
            }
        }
        setState(EG_STATE_SENT);
        setSendDate(ar.nowTime);
    }

    private void constructEmailRecordOneUser(AuthRequest ar, NGWorkspace ngw, OptOutAddr ooa, EmailSender sender)
            throws Exception  {
        String userAddress = ooa.getEmail();
        if (userAddress==null || userAddress.length()==0) {
            //don't send anything if the user does not have an email address
            return;
        }
        UserProfile originalSender = UserManager.getStaticUserManager().lookupUserByAnyId(getOwner());
        if (originalSender==null) {
            System.out.println("DATA PROBLEM: email generator came from a person without a profile ("+getOwner()+") ignoring");
            return;
        }

        MailInst mailMsg = ngw.createMailInst();
        

        TopicRecord topic = getTopicIfPresent(ngw);
        MeetingRecord meeting = getMeetingIfPresent(ngw);
        if (topic!=null) {
            mailMsg.setCommentContainer(topic.getGlobalContainerKey(ngw));
        }
        
        generateEmailBody(ar, ngw, ooa, mailMsg);
        String subject = mailMsg.getSubject();
        String entireBody = mailMsg.getBodyText();


        ArrayList<File> attachments = new ArrayList<File>();
        if (getAttachFiles()) {
            for (String attId : getAttachments()) {
                attachDocFromId(attachments, attId, ngw);
            }
            if (topic!=null) {
                for (String docId : topic.getDocList()) {
                    attachDocFromId(attachments, docId, ngw);
                }
            }
            else if (meeting!=null) {
                for (AgendaItem ai : meeting.getSortedAgendaItems()) {
                    for (String docId : ai.getDocList()) {
                        attachDocFromId(attachments, docId, ngw);
                    }
                }
            }
        }

        //always attach the ICS file whether they ask for it or not
        //but only if the meeting is scheduled for some time in the future
        if (meeting!=null && meeting.getStartTime()>System.currentTimeMillis()) {
            File cogFolder = new File(ngw.containingFolder, ".cog");
            File icsFile = new File(cogFolder, "meet"+meeting.getId()+".ics");
            File icsFileTmp = new File(cogFolder, "meet"+meeting.getId()+".ics~tmp"+System.currentTimeMillis());
            FileOutputStream fos = new FileOutputStream(icsFileTmp);
            Writer w = new OutputStreamWriter(fos, "UTF-8");
            meeting.streamICSFile(ar, w, ngw);
            w.close();
            if (icsFile.exists()) {
                icsFile.delete();
            }
            icsFileTmp.renameTo(icsFile);
            attachments.add(icsFile);
        }

        mailMsg.setSubject(subject);
        mailMsg.setBodyText(entireBody);
        mailMsg.setAttachmentFiles(attachments);
        
        sender.createEmailRecordInDB(mailMsg, new AddressListEntry(getOwner()), ooa.getEmail());
    }


    private void attachDocFromId(ArrayList<File> attachments, String attId, NGWorkspace ngw) throws Exception {
        File path = ngw.getAttachmentPathOrNull(attId);
        if (path==null) {
            System.out.println("constructEmailRecordOneUser: attachment id "+attId
                    +" can not be found for email: "+this.getSubject());
            return;
        }
        attachments.add(path);
    }

    private TopicRecord getTopicIfPresent(NGWorkspace ngw) throws Exception {
        String topicId = getNoteId();
        if (topicId==null || topicId.length()==0) {
            return null;
        }
        TopicRecord topic = ngw.getDiscussionTopic(topicId);
        return topic;
    }
    private MeetingRecord getMeetingIfPresent(NGWorkspace ngw) throws Exception {
        String meetId = getMeetingId();
        if (meetId==null || meetId.length()==0) {
            return null;
        }
        MeetingRecord meeting = ngw.findMeetingOrNull(meetId);
        return meeting;
    }

    public void generateEmailBody(AuthRequest ar, NGWorkspace ngw, OptOutAddr ooa, MailInst mail) throws Exception {

        TopicRecord noteRec = ngw.getDiscussionTopic(getNoteId());
        if (noteRec!=null) {
            mail.setCommentContainer(noteRec.getGlobalContainerKey(ngw));
        }
        MemFile bodyChunk = new MemFile();
        UserProfile originalSender = UserManager.getStaticUserManager().lookupUserByAnyId(getOwner());

        List<AttachmentRecord> attachList = getSelectedAttachments(ar, ngw);

        for (String attId : getAttachments()) {
            AttachmentRecord aRec = ngw.findAttachmentByUidOrNull(attId);
            if (aRec!=null) {
                attachList.add(aRec);
            }
        }

        String meetingString = "";
        String meetId = getMeetingId();
        MeetingRecord meeting = null;
        if (meetId!=null && meetId.length()>0) {
            meeting = ngw.findMeetingOrNull(meetId);
            if (meeting!=null) {
                for (AgendaItem ai : meeting.getSortedAgendaItems()) {
                    for (String docId : ai.getDocList()) {
                        AttachmentRecord aRec = ngw.findAttachmentByUidOrNull(docId);
                        if (aRec==null) {
                            //this means that the document does not exist.  Maybe it was deleted?  Ignore it.
                            continue;
                        }
                        attachList.add(aRec);
                    }
                }

                String meetingLayout = this.getScalar("meetingLayout");
                if (meetingLayout==null || meetingLayout.length()<=6) {
                    meetingLayout = "FullDetail.chtml";
                }
                String baseName = meetingLayout.substring(0, meetingLayout.length()-6);
                MemFile meetingOutput = new MemFile();
                ChunkTemplate.streamAuthRequest(meetingOutput.getWriter(), ar, baseName, meeting.getFullJSON(ar, ngw, false), ooa.getCalendar());
                meetingString = meetingOutput.toString();
            }
        }



        AuthRequest clone = new AuthDummy(originalSender, bodyChunk.getWriter(), ar.getCogInstance());
        clone.retPath = ar.baseURL;
        clone.setPageAccessLevels(ngw);

        JSONObject data = getJSONForTemplate(clone, ngw, noteRec, ooa.getAssignee(), getIntro(),
                getIncludeBody(), attachList, meeting);
        mail.addFieldsForRender(data);
        writeNoteAttachmentEmailBody2(clone, ooa, data);
        clone.flush();
        String body = bodyChunk.toString() + meetingString;
        mail.setBodyText(body);

        String subject = ChunkTemplate.stringIt(getSubject(), data, ooa.getCalendar());
        if (subject.length()>50) {
            subject = subject.substring(0,50);
        }
        mail.setSubject(subject);
    }

    private static List<AttachmentRecord> getSelectedAttachments(AuthRequest ar,
            NGWorkspace ngw) throws Exception {
        List<AttachmentRecord> res = new ArrayList<AttachmentRecord>();
        for (AttachmentRecord att : ngw.getAllAttachments()) {
            String paramId = "attach" + att.getId();
            if (ar.defParam(paramId, null) != null) {
                res.add(att);
            }
        }
        return res;
    }


    private JSONObject getJSONForTemplate(AuthRequest ar,
            NGWorkspace ngw, TopicRecord selectedNote,
            AddressListEntry ale, String intro, boolean includeBody,
            List<AttachmentRecord> selAtt, MeetingRecord meeting) throws Exception {
        //Gather all the data into a JSON structure
        JSONObject data = new JSONObject();
        data.put("baseURL", ar.baseURL);
        UserProfile ownerProfile = UserManager.getStaticUserManager().lookupUserByAnyId(getOwner());
        if (ownerProfile!=null) {
            data.put("sender",  ownerProfile.getJSON());
        }
        else {
            System.out.println("No Sender info set.  AuthRequest user ("+ar.getBestUserId()+") does not have a user profile for the email message");
        }

        String workspaceBaseUrl = ar.baseURL + "t/" + ngw.getSiteKey() + "/" + ngw.getKey() + "/";
        data.put("workspaceName", ngw.getFullName());
        data.put("workspaceUrl", workspaceBaseUrl);
        data.put("intro", intro);

        ar.ngp = ngw;
        
        JSONArray attachArray = new JSONArray();
        Set<String> duplicateEliminator = new HashSet<String>();
        for (AttachmentRecord att : selAtt) {
            if (att==null) {
                System.out.println("How is it possible that the iterated value 'att' is null in getJSONForTemplate???");
                continue;
            }
            String docId = att.getUniversalId();
            if (duplicateEliminator.contains(docId)) {
                continue;
            }
            duplicateEliminator.add(docId);
            JSONObject oneAtt = new JSONObject();
            StringBuilder sb = new StringBuilder();
            sb.append(ar.baseURL);
            sb.append(att.getEmailURL(ar, ngw));
            sb.append("&");
            sb.append(AccessControl.getAccessDocParams(ngw, att));
            sb.append("&emailId=");
            sb.append(URLEncoder.encode(ale.getEmail(), "UTF-8"));
            oneAtt.put("url",  sb.toString());
            oneAtt.put("name", att.getNiceName());
            attachArray.put(oneAtt);
        }
        data.put("attach", attachArray);

        if (selectedNote != null) {
            String licensedUrl = ar.retPath + ar.getResourceURL(ngw, selectedNote)
                    + "?" + AccessControl.getAccessTopicParams(ngw, selectedNote)
                    + "&emailId=" + URLEncoder.encode(ale.getEmail(), "UTF-8");
            data.put("commentContainer", selectedNote.getGlobalContainerKey(ngw));
            data.put("noteUrl", licensedUrl);
            data.put("noteName", selectedNote.getSubject());


            JSONObject noteObj = selectedNote.getJSONWithMarkdown(ngw);
            noteObj.put("noteUrl", licensedUrl);
            AttachmentRecord.addEmailStyleAttList(noteObj, ar, ngw, selectedNote.getDocList());

            data.put("note", noteObj);
            if (includeBody) {
                data.put("includeTopic", "yes");
            }
        }

        if (meeting!=null) {
            JSONObject meetingObj = meeting.getFullJSON(ar, ngw, false);
            meetingObj.put("meetingUrl", ar.retPath + ar.getResourceURL(ngw, "MeetingHtml.htm?id="+meeting.getId()
                    +"&"+AccessControl.getAccessMeetParams(ngw, meeting))
                    + "&emailId=" + URLEncoder.encode(ale.getEmail(), "UTF-8"));
            meetingObj.put("isScheduled", meeting.isScheduled());
            data.put("meeting", meetingObj);

            //TODO: this is temporary until templates can handle dates
            data.put("meetingTime", SectionUtil.getNicePrintDate(meeting.getStartTime()));
        }

        //now handle the tasks
        String tasksOption = getAttribute("tasksOption");
        boolean onlyAssigned = "Assignee".equals(tasksOption);
        if ("All".equals(tasksOption) || onlyAssigned) {
            List<String> labels = getVector("tasksLabels");
            String filter = getScalar("tasksFilter");

            JSONArray goalArray = new JSONArray();
            for (GoalRecord aGoal : ngw.getAllGoals()) {
                if (!GoalRecord.isActive(aGoal.getState())) {
                    //only include active goals, not future or completed
                    continue;
                }
                if (filter!=null && filter.length()>0) {
                    String synlc = aGoal.getSynopsis().toLowerCase();
                    String desclc = aGoal.getDescription().toLowerCase();
                    if (!synlc.contains(filter) && !desclc.contains("filter")) {
                        //skip this if the filter value not found
                        continue;
                    }
                }
                boolean missingLabel = false;
                for (String aLabel : labels) {
                    boolean hasThisOne = false;
                    for (NGLabel whatGoalHas : aGoal.getLabels(ngw)) {
                        if (whatGoalHas.getName().equals(aLabel)) {
                            hasThisOne = true;
                        }
                    }
                    if (!hasThisOne) {
                        missingLabel = true;
                    }
                }
                if (missingLabel) {
                    continue;
                }

                if (onlyAssigned) {
                    if (!aGoal.isAssignee(ale)) {
                        continue;
                    }
                }

                JSONObject goalJson = aGoal.getJSON4Goal(ngw);
                goalJson.put("url", workspaceBaseUrl + "task" + aGoal.getId() + ".htm");
                goalArray.put(goalJson);
            }
            data.put("goals", goalArray);
        }

        return data;
    }

    private void writeNoteAttachmentEmailBody2(AuthRequest ar,
            OptOutAddr ooa, JSONObject data) throws Exception {

        data.put("optout", ooa.getUnsubscribeJSON(ar));

        ChunkTemplate.streamAuthRequest(ar.w, ar, "DiscussionTopicManual", data, ooa.getCalendar());
    }

    public JSONObject getJSON(AuthRequest ar, NGWorkspace ngw) throws Exception {
        AddressListEntry ownerAle = new AddressListEntry(getOwner());
        JSONObject obj = new JSONObject();
        obj.put("id", getId());
        obj.put("from", getOwner());
        obj.put("fromUser", ownerAle.getJSON());
        obj.put("subject", getSubject());
        obj.put("state", getState());
        obj.put("sendDate", getSendDate());
        obj.put("roleNames", constructJSONArray(getRoleNames()));

        JSONArray toList = new JSONArray();
        for (String uid : getAlsoTo()) {
            AddressListEntry ale = AddressListEntry.parseCombinedAddress(uid);
            toList.put(ale.getJSON());
        }
        obj.put("alsoTo", toList);
        obj.put("intro", getIntro());
        obj.put("excludeResponders", getExcludeResponders());
        obj.put("includeBody", getIncludeBody());
        obj.put("attachFiles", getAttachFiles());
        obj.put("scheduleTime", getScheduleTime());
        
        

        JSONArray attachmentInfo = new JSONArray();
        for (String attId : getAttachments()) {
            AttachmentRecord atRec = ngw.findAttachmentByUidOrNull(attId);
            if (atRec!=null) {
                attachmentInfo.put(atRec.getUniversalId());
            }
        }
        obj.put("docList", attachmentInfo);

        String noteId = getNoteId();
        if (noteId!=null && noteId.length()>0) {
            TopicRecord nr = ngw.getDiscussionTopic(noteId);
            if (nr!=null) {
                obj.put("noteInfo", nr.getJSONWithMarkdown(ngw));
            }
        }
        String meetingId = getMeetingId();
        if (meetingId!=null && meetingId.length()>0) {
            MeetingRecord meet = ngw.findMeetingOrNull(meetingId);
            if (meet!=null) {
                obj.put("meetingInfo", meet.getFullJSON(ar, ngw, false));
            }
        }

        this.extractAttributeString(obj, "tasksOption");
        this.extractScalarString(obj, "tasksFilter");
        this.extractVectorString(obj, "tasksLabels");
        this.extractAttributeBool(obj, "tasksFuture");
        this.extractAttributeBool(obj, "tasksCompleted");
        this.extractScalarString(obj, "meetingLayout");
        return obj;
    }

    public void updateFromJSON(JSONObject obj) throws Exception {
        if (obj.has("subject")) {
            setSubject(obj.getString("subject"));
        }
        if (obj.has("intro")) {
            setIntro(obj.getString("intro"));
        }

        //NO SET STATE from JSON!!

        if (obj.has("sendDate")) {
            setSendDate(obj.getLong("sendDate"));
        }
        if (obj.has("noteInfo")) {
            JSONObject noteObj = obj.getJSONObject("noteInfo");
            setNoteId(noteObj.getString("universalid"));
        }
        if (obj.has("roleNames")) {
            setRoleNames(constructVector(obj.getJSONArray("roleNames")));
        }
        if (obj.has("alsoTo")) {
            JSONArray toList = obj.getJSONArray("alsoTo");
            List<String> justIdList = new ArrayList<String>();
            for (int i=0; i<toList.length(); i++) {
                JSONObject item = toList.getJSONObject(i);
                justIdList.add(item.getString("uid"));
            }
            setAlsoTo(justIdList);
        }
        if (obj.has("docList")) {
            setAttachments(constructVector(obj.getJSONArray("docList")));
        }
        if (obj.has("excludeResponders")) {
            setExcludeResponders(obj.getBoolean("excludeResponders"));
        }
        if (obj.has("includeBody")) {
            setIncludeBody(obj.getBoolean("includeBody"));
        }
        if (obj.has("attachFiles")) {
            setAttachFiles(obj.getBoolean("attachFiles"));
        }
        if (obj.has("meetingInfo")) {
            JSONObject attInfo = obj.getJSONObject("meetingInfo");
            setMeetingId( attInfo.getString("id") );
        }
        if (obj.has("scheduleTime")) {
            setScheduleTime(obj.getLong("scheduleTime"));
        }
        this.updateAttributeString("tasksOption", obj);
        this.updateScalarString("tasksFilter", obj);
        this.updateVectorString("tasksLabels", obj);
        this.updateAttributeBool("tasksFuture", obj);
        this.updateAttributeBool("tasksCompleted", obj);
        this.updateScalarString("meetingLayout", obj);
    }

    public void gatherUnsentScheduledNotification(NGWorkspace ngw, ArrayList<ScheduledNotification> resList, long timeout) throws Exception {
        if (getState()==EG_STATE_SCHEDULED) {
            EGScheduledNotification sn = new EGScheduledNotification(ngw, this);
            resList.add(sn);
        }
    }


    private class EGScheduledNotification implements ScheduledNotification {
        private NGWorkspace ngw;
        private EmailGenerator eg;

        public EGScheduledNotification( NGWorkspace _ngw, EmailGenerator _eg) {
            ngw  = _ngw;
            eg = _eg;
        }
        @Override
        public boolean needsSendingBefore(long timeout) throws Exception {
            if (eg.getState()==EG_STATE_SENT) {
                return false;
            }
            return (eg.getScheduleTime()<timeout);
        }
        @Override
        public long futureTimeToSend() throws Exception {
            if (eg.getState()==EG_STATE_SENT) {
                return -1;
            }
            return eg.getScheduleTime();
        }


        @Override
        public void sendIt(AuthRequest ar, EmailSender mailFile) throws Exception {
            eg.constructEmailRecords(ar, ngw, mailFile);
        }

        @Override
        public String selfDescription() throws Exception {
            return "(Email Generator) "+eg.getSubject();
        }
    }

}
