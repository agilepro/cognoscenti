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

import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.weaver.mail.ChunkTemplate;
import com.purplehillsbooks.weaver.mail.EmailSender;
import com.purplehillsbooks.weaver.mail.MailInst;
import com.purplehillsbooks.weaver.mail.OptOutAddr;
import com.purplehillsbooks.weaver.mail.OptOutTopicSubscriber;
import com.purplehillsbooks.weaver.mail.ScheduledNotification;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.MemFile;

/**
 * A TopicRecord represents a Topic in a Workspace.
 * Topic exist on workspaces as quick ways for people to
 * write and exchange information about the workspace.
 * Leaflet is the old term for this, we prefer the term Topic now everywhere.
 * (Used to be called LeafletRecord, but name changed March 2013)
 */
public class TopicRecord extends CommentContainer {

    public static final String DISCUSSION_PHASE_DRAFT = "Draft";
    public static final String DISCUSSION_PHASE_FREEFORM = "Freeform";
    public static final String DISCUSSION_PHASE_PICTURE_FORMING = "Forming";
    public static final String DISCUSSION_PHASE_PROPOSAL_SHAPING = "Shaping";
    public static final String DISCUSSION_PHASE_PROPOSAL_FINALIZING = "Finalizing";
    public static final String DISCUSSION_PHASE_RESOLVED = "Resolved";
    public static final String DISCUSSION_PHASE_TRASH = "Trash";
    public static final String DISCUSSION_PHASE_MOVED = "Moved";

    // This is actually one week before the server started, and is used mainly in
    // the startup methods for an arbitrary time long enough ago that automated
    // notifications should be cancelled or ignored. If the server stays on a long 
    // this value will not be updated -- it remains the time a week before starting the server.
    public static final long ONE_WEEK_AGO = System.currentTimeMillis() - 7L * 24 * 60 * 60 * 1000;

    private int repliesMade = -1;
    private int repliesNeeded = -1;

    public TopicRecord(Document definingDoc, Element definingElement, DOMFace new_ngs) {
        super(definingDoc, definingElement, new_ngs);

        // convert to using discussion phase instead of older deleted indicator
        // NGWorkspace schema 101 -> 102 migration
        String currentPhase = getDiscussionPhase();
        if (currentPhase == null || currentPhase.length() == 0) {
            // by default everything is freeform, unless deleted or possibly draft
            currentPhase = DISCUSSION_PHASE_FREEFORM;

            String delAttr = getAttribute("deleteUser");
            String saveAsDraft = getAttribute("saveAsDraft");
            if (delAttr != null && delAttr.length() > 0) {
                currentPhase = DISCUSSION_PHASE_TRASH;
            } else if (saveAsDraft != null && saveAsDraft.equals("yes")) {
                currentPhase = DISCUSSION_PHASE_DRAFT;
            }
            clearAttribute("saveAsDraft");
            setAttribute("discussionPhase", currentPhase);
        }
    }

    public void copyFrom(AuthRequest ar, NGWorkspace otherWorkspace, TopicRecord other) throws Exception {
        JSONObject full = other.getJSONWithComments(ar, otherWorkspace);
        // fake this to avoid the consistency assurance constraints
        full.put("id", getId());
        full.put("universalid", getUniversalId());
        updateNoteFromJSON(full, ar);
    }

    // This is a callback from container to set the specific fields
    public void addContainerFields(CommentRecord cr) {
        cr.containerType = CommentRecord.CONTAINER_TYPE_TOPIC;
        cr.containerID = getId();
        cr.containerName = this.getSubject();
    }

    public String getId() {
        return getAttribute("id");
    }

    public void setId(String newId) {
        setAttribute("id", newId);
    }

    public boolean hasId(String id) {
        if (id.equals(this.getId())) {
            return true;
        }
        if (id.equals(this.getUniversalId())) {
            return true;
        }
        return false;
    }

    // TODO: is this properly supported? Should be an AddressListEntry
    public String getOwner() {
        return getScalar("owner");
    }

    public void setOwner(String newOwner) {
        setScalar("owner", newOwner);
    }

    public String getTargetRole() throws Exception {
        String target = getAttribute("targetRole");
        if (target == null || target.length() == 0) {
            return "MembersRole";
        }
        return target;
    }

    public void setTargetRole(String newVal) throws Exception {
        setAttribute("targetRole", newVal);
    }

    public void appendTargetEmails(List<OptOutAddr> sendTo, NGWorkspace ngw) throws Exception {
        NGRole subsRole = getSubscriberRole();
        List<AddressListEntry> subscribers = subsRole.getDirectPlayers();
        if (subscribers.size() > 0) {
            for (AddressListEntry ale : subscribers) {
                if (ale.isWellFormed()) {
                    OptOutAddr ooa = new OptOutTopicSubscriber(ale, ngw.getSiteKey(), ngw.getKey(), this);
                    sendTo.add(ooa);
                }
            }
        } else {
            OptOutAddr.appendUnmutedUsersFromRole(ngw, getTargetRole(), sendTo);
        }
    }

    public long getLastEdited() {
        return getScalarLong("created");
    }

    public void setLastEdited(long newCreated) {
        setScalarLong("created", newCreated);
    }

    public AddressListEntry getModUser() {
        String userId = getScalar("modifiedby");
        return AddressListEntry.findOrCreate(userId);
    }

    public void setModUser(UserRef newModifier) {
        setScalar("modifiedby", newModifier.getUniversalId());
    }

    public String getSubject() {
        return getScalar("subject");
    }

    public void setSubject(String newSubj) {
        setScalar("subject", newSubj);
    }

    public String getWiki() {
        return getScalar("data");
    }

    public void setWiki(String newData) {
        setScalar("data", newData);
    }

    /**
     * This date used to sort the comments. Set to the date that
     * the comment was first made or published. That date remains
     * fixed even if the comment continues to be edited.
     *
     * When effective date is not set, use last saved date instead.
     * These will be the same a lot of the time.
     */
    public long getEffectiveDate() {
        long effDate = getScalarLong("effective");
        if (effDate == 0) {
            return getLastEdited();
        }
        return effDate;
    }

    public void setEffectiveDate(long newEffective) {
        setScalarLong("effective", newEffective);
    }

    /**
     * If the comment is "pinned" to the top of the page, then
     * this pin order will be set with a positive integer value
     * so that comments are in the order 1, 2, 3, etc.
     * A value of zero (or negative) means that the comment is
     * not pinned to the top, and should instead be sorted by
     * effective date.
     * Default: 0
     */
    public long getPinOrder() {
        long pin = getScalarLong("pin");
        if (pin < 0) {
            pin = 0;
        }
        return pin;
    }

    public void setPinOrder(long newPinOrder) {
        if (newPinOrder < 0) {
            newPinOrder = 0;
        }
        setScalar("pin", Long.toString(newPinOrder));
    }

    /**
     * Given a vector, this will fill the vector with tag terms
     */
    public void fillTags(List<String> result) {
        fillVectorValues(result, "tag");
    }

    /**
     * Returns a vector of string tag values
     */
    public List<String> getTags() {
        return getVector("tag");
    }

    /**
     * Given a vector of string, this tag terms for this comment
     */
    public void setTags(List<String> newVal) {
        setVector("tag", newVal);
    }

    /**
     * Returns a vector of string choice values
     */
    public String getChoices() {
        return getScalar("choices");
    }

    /**
     * Given a vector of string, this choices for this topic
     */
    public void setChoices(String choices) {
        setScalar("choices", choices);
    }

    public static void sortNotesInPinOrder(List<TopicRecord> v) {
        Collections.sort(v, new NotesInPinOrder());
    }

    /**
     * Compares its two arguments for order.
     * First compares their pin order value which the user has placed
     * on them to pin them in a particular position. The order
     * is 1, 2, 3, ... and then 0 at the end denoting that there is
     * no pin order set.
     * If no pin order is set (or if pin order is equal) then
     * compared by effective date order, which is usually the date
     * that the comment was first created.
     */
    private static class NotesInPinOrder implements Comparator<TopicRecord> {
        NotesInPinOrder() {
        }

        public int compare(TopicRecord o1, TopicRecord o2) {
            long p1 = o1.getPinOrder();
            long p2 = o2.getPinOrder();
            if (p1 != p2) {
                if (p1 == 0) {
                    return 1;
                }
                if (p2 == 0) {
                    return -1;
                }
                if (p2 < p1) {
                    return 1;
                }
                if (p2 > p1) {
                    return -1;
                }
            }

            // pin number is equal, so sort by effective date
            long t1 = o1.getEffectiveDate();
            long t2 = o2.getEffectiveDate();
            if (t2 < t1) {
                return -1;
            }
            if (t2 == t1) {
                return 0;
            }
            return 1;
        }

    }

    /**
     * Discussion Phase is an overall state of the note object.
     * These are the phases:
     * Draft - private, not publicized, one person only
     * Freeform - just a general discussion topic, freeform
     * Picture Forming
     * Proposal Shaping
     * Proposal Finalizing
     * Resolved
     * Closed
     * Trash - this overlaps with deleted.
     */
    public String getDiscussionPhase() {
        return getAttribute("discussionPhase");
    }

    public void setDiscussionPhase(String newPhase, AuthRequest ar) throws Exception {
        String oldPhase = getDiscussionPhase();
        if (newPhase.equals(oldPhase)) {
            return;
        }
        CommentRecord cr = this.addComment(ar);
        cr.setCommentType(CommentRecord.COMMENT_TYPE_PHASE_CHANGE);
        cr.setNewPhase(newPhase);
        setAttribute("discussionPhase", newPhase);
    }

    /**
     * Marking a Topic as deleted means that we SET the phase to trash.
     * A Topic that is deleted / trash remains in the archive until a later
     * date, when garbage has been collected.
     */
    public boolean isDeleted() {
        String currentPhase = getDiscussionPhase();
        return (DISCUSSION_PHASE_TRASH.equals(currentPhase));
    }

    /**
     * Set deleted date to the date that it is effectively deleted,
     * which is the current time in most cases.
     * Set the date to zero in order to clear the deleted flag
     * and make the topic to be not-deleted
     */
    public void setTrashPhase(AuthRequest ar) throws Exception {
        setAttribute("deleteDate", Long.toString(ar.nowTime));
        setAttribute("deleteUser", ar.getBestUserId());
        setDiscussionPhase("Trash", ar);
    }

    public void clearTrashPhase(AuthRequest ar) throws Exception {
        setAttribute("deleteDate", null);
        setAttribute("deleteUser", null);
        setDiscussionPhase("Freeform", ar);
    }

    public long getDeleteDate() {
        return getAttributeLong("deleteDate");
    }

    public String getDeleteUser() {
        return getAttribute("deleteUser");
    }

    public boolean isDraftNote() {
        return (DISCUSSION_PHASE_DRAFT.equals(getDiscussionPhase()));
    }

    /**
     * the universal id is a globally unique ID for this topic, composed of the id
     * for the
     * server, the workspace, and the topic. This is set at the point where the
     * topic is created
     * and remains with the topic as it is carried around the system as long as it
     * is moved
     * as a clone from a workspace to a clone of a workspace. If it is copied or
     * moved to another
     * workspace for any other reason, then the universal ID should be reset.
     */
    public String getUniversalId() {
        return getScalar("universalid");
    }

    public void setUniversalId(String newID) throws Exception {
        setScalar("universalid", newID);
    }

    /**
     * check if a particular role has access to the particular topic.
     * Just handles the 'special' roles, and does not take into consideration
     * the Members or Admin roles, nor whether the attachment is public.
     */
    public boolean roleCanAccess(String roleName) {
        List<String> roleNames = getVector("labels");
        for (String name : roleNames) {
            if (roleName.equals(name)) {
                return true;
            }
        }
        return false;
    }

    public boolean isUpstream() {
        String delAttr = getAttribute("upstreamAccess");
        return (delAttr != null && delAttr.length() > 0);
    }

    public void setUpstream(boolean val) {
        if (val) {
            setAttribute("upstreamAccess", "yes");
        } else {
            setAttribute("upstreamAccess", null);
        }
    }

    public void writeNoteHtml(AuthRequest ar) throws Exception {
        WikiConverterForWYSIWYG.writeWikiAsHtml(ar, getWiki());
    }

    public String getNoteHtml(AuthRequest ar) throws Exception {
        MemFile htmlChunk = new MemFile();
        AuthDummy dummy = new AuthDummy(ar.getUserProfile(), htmlChunk.getWriter(), ar.getCogInstance());
        dummy.ngp = ar.ngp;
        dummy.retPath = ar.retPath;
        WikiConverterForWYSIWYG.writeWikiAsHtml(dummy, getWiki());
        dummy.flush();
        return htmlChunk.toString();
    }

    public void verifyAllAttachments(NGWorkspace ngw) throws Exception {
        List<String> attached = getDocList();
        List<String> newList = new ArrayList<String>();
        List<AttachmentRecord> attaches = ngw.getAllAttachments();
        boolean changed = false;
        for (String attId : attached) {
            boolean found = false;
            if (newList.contains(attId)) {
                continue;
            }
            for (AttachmentRecord aRec : attaches) {
                if (aRec.getUniversalId().equals(attId)) {
                    found = true;
                }
            }
            if (found) {
                newList.add(attId);
            } else {
                changed = true;
            }
        }
        if (changed) {
            setDocList(newList);
        }
    }

    public List<String> getDocList() {
        return getVector("docList");
    }

    public void addDocId(String goalId) {
        this.addVectorValue("docList", goalId);
    }

    public void setDocList(List<String> newVal) {
        setVector("docList", newVal);
    }

    public List<String> getDocListIncludeComments() throws Exception {
        List<String> allDocList = new ArrayList<String>();
        for (String docId : getDocList()) {
            if (!allDocList.contains(docId)) {
                allDocList.add(docId);
            }
        }
        for (CommentRecord comm : this.getComments()) {
            for (String docId : comm.getDocList()) {
                if (!allDocList.contains(docId)) {
                    allDocList.add(docId);
                }
            }
        }
        return allDocList;
    }

    public List<AttachmentRecord> getAttachedDocs(NGWorkspace ngw) throws Exception {
        return ngw.getListedAttachments(getDocList());
    }

    public List<AttachmentRecord> getAttachedDocsIncludeComments(NGWorkspace ngw) throws Exception {
        return ngw.getListedAttachments(getDocListIncludeComments());
    }

    public List<String> getActionList() {
        return getVector("actionList");
    }

    public void setActionList(List<String> newVal) {
        setVector("actionList", newVal);
    }

    /**
     * Return all the Action Items that were 'live' during the specified
     * time period. We only know the state that it is now, and timestamp
     * that if was started and ended. Exclude anything that was closed before the
     * time period
     * began. Exclude anything that had not yet started by the time period end.
     */
    public List<String> getActionItemsAtTime(NGWorkspace ngw, long startTime, long endTime) throws Exception {
        ArrayList<String> res = new ArrayList<String>();
        for (String possible : getActionList()) {
            GoalRecord gr = ngw.getGoalOrNull(possible);
            if (gr != null && gr.wasActiveAtTime(startTime, endTime)) {
                res.add(possible);
            }
        }
        return res;
    }

    /**
     * get the labels on a document -- only labels valid in the workspace,
     * and no duplicates
     */
    public List<NGLabel> getLabels(NGWorkspace ngw) throws Exception {
        List<NGLabel> res = new ArrayList<NGLabel>();
        for (String name : getVector("labels")) {
            NGLabel aLabel = ngw.getLabelRecordOrNull(name);
            if (aLabel != null) {
                if (!res.contains(aLabel)) {
                    res.add(aLabel);
                }
            }
        }
        return res;
    }

    /**
     * set the list of labels on a document
     */
    public void setLabels(List<NGLabel> values) throws Exception {
        List<String> labelNames = new ArrayList<String>();
        for (NGLabel aLable : values) {
            labelNames.add(aLable.getName());
        }
        // Since this is a 'set' type vector, always sort them so that they are
        // stored in a consistent way ... so files are more easily compared
        Collections.sort(labelNames);
        setVector("labels", labelNames);
    }

    /**
     * Check to see if a label is on the discussion topic,
     * if not, add it
     */
    public void assureLabel(String labelName) throws Exception {
        List<String> labels = getVector("labels");
        for (String name : labels) {
            if (name.equals(labelName)) {
                // found it, nothing left to do
                return;
            }
        }
        labels.add(labelName);
        // Since this is a 'set' type vector, always sort them so that they are
        // stored in a consistent way ... so files are more easily compared
        Collections.sort(labels);
        setVector("labels", labels);
    }

    public boolean getEmailSent() throws Exception {
        if (getAttributeBool("emailSent")) {
            return true;
        }

        // schema migration. If the email was not sent, and the item was created
        // more than 1 week ago, then go ahead and mark it as sent, because it is
        // too late to send. This is important whie adding this automatic email
        // sending becaue there are a lot of old records that have never been marked
        // as being sent. Need to set them as being sent so they are not sent now.
        if (getLastEdited() < ONE_WEEK_AGO) {
            setEmailSent(true);
            return true;
        }

        return false;
    }

    public void setEmailSent(boolean newVal) throws Exception {
        setAttributeBool("emailSent", newVal);
    }

    public List<HistoryRecord> getNoteHistory(NGWorkspace ngc) throws Exception {
        ArrayList<HistoryRecord> histRecs = new ArrayList<HistoryRecord>();
        String nid = this.getId();
        for (HistoryRecord hist : ngc.getAllHistory()) {
            if (hist.getContextType() == HistoryRecord.CONTEXT_TYPE_LEAFLET
                    && nid.equals(hist.getContext())) {
                histRecs.add(hist);
            }
        }
        return histRecs;
    }

    public List<MeetingRecord> getLinkedMeetings(NGWorkspace ngc) throws Exception {
        ArrayList<MeetingRecord> allMeetings = new ArrayList<MeetingRecord>();
        String nid = this.getId();
        String uid = this.getUniversalId();
        for (MeetingRecord meet : ngc.getMeetings()) {
            boolean found = false;
            for (AgendaItem ai : meet.getAgendaItems()) {
                List<String> linkedTopics = ai.getLinkedTopics();
                if (linkedTopics.contains(uid)) {
                    found = true;
                } else if (linkedTopics.contains(nid)) {
                    // for a while local id was being saved....so look for that as well.
                    found = true;
                }
            }
            if (found) {
                allMeetings.add(meet);
            }
        }
        return allMeetings;
    }

    public NGRole getSubscriberRole() throws Exception {
        return requireChild("subscriberRole", CustomRole.class);
    }

    public void topicEmailRecord(AuthRequest ar, NGWorkspace ngw, EmailSender mailFile) throws Exception {
        List<OptOutAddr> sendTo = new ArrayList<OptOutAddr>();

        // The user interface will initialize the subscribers to the members of the
        // target role
        // and will allow editing of those subscribers just before sending the first
        // time
        // so email to the subscribers.
        OptOutAddr.appendUsers(getSubscriberRole().getExpandedPlayers(ngw), sendTo);

        UserRef creator = getModUser();
        UserProfile creatorProfile = UserManager.lookupUserByAnyId(creator.getUniversalId());
        if (creatorProfile == null) {
            System.out.println("DATA PROBLEM: discussion topic came from a person without a profile ("
                    + getModUser().getUniversalId() + ") ignoring");
            setEmailSent(true);
            return;
        }

        for (OptOutAddr ooa : sendTo) {
            constructEmailRecordOneUser(ar, ngw, this, ooa, creatorProfile, mailFile);
        }
        setEmailSent(true);

        // when the email is sent, update the time
        // of the entire note so that it appears at the top of list.
        setLastEdited(ar.nowTime);
    }

    private void constructEmailRecordOneUser(AuthRequest ar, NGWorkspace ngw, TopicRecord note, OptOutAddr ooa,
            UserProfile commenterProfile, EmailSender mailFile) throws Exception {
        if (!ooa.hasEmailAddress()) {
            return; // ignore users without email addresses
        }
        MemFile body = new MemFile();
        AuthRequest clone = new AuthDummy(commenterProfile, body.getWriter(), ar.getCogInstance());
        clone.retPath = ar.baseURL;

        MailInst mailMsg = ngw.createMailInst();
        mailMsg.setCommentContainer(getGlobalContainerKey(ngw));

        JSONObject data = new JSONObject();
        data.put("baseURL", ar.baseURL);
        data.put("topicURL", ar.baseURL + ar.getResourceURL(ngw, this)
                + "?" + AccessControl.getAccessTopicParams(ngw, this)
                + "&emailId=" + URLEncoder.encode(ooa.getEmail(), "UTF-8"));
        data.put("topic", this.getJSONWithMarkdown(ngw));
        data.put("wsBaseURL", ar.baseURL + clone.getWorkspaceBaseURL(ngw));
        data.put("wsName", ngw.getFullName());
        data.put("optout", ooa.getUnsubscribeJSON(ar));
        mailMsg.addFieldsForRender(data);

        AttachmentRecord.addEmailStyleAttList(data, ar, ngw, getDocList());

        ChunkTemplate.streamAuthRequest(clone.w, ar, "NewTopic", data, commenterProfile.getCalendar());
        clone.flush();

        mailMsg.setSubject("New Topic: " + note.getSubject());
        mailMsg.setBodyText(body.toString());

        mailFile.createEmailRecordInDB(mailMsg, commenterProfile.getAddressListEntry(), ooa.getEmail());
    }

    /////////////////////////// JSON ///////////////////////////////

    public JSONObject getLinkableJSON() throws Exception {
        JSONObject thisNote = new JSONObject();
        extractAttributeString(thisNote, "id");
        extractScalarString(thisNote, "subject");
        extractScalarString(thisNote, "universalid");
        return thisNote;
    }

    public JSONObject getJSON(NGWorkspace ngw) throws Exception {
        JSONObject thisNote = getLinkableJSON();
        thisNote.put("modTime", getLastEdited());
        thisNote.put("modUser", getModUser().getJSON());
        thisNote.put("deleted", isDeleted());
        thisNote.put("draft", isDraftNote());
        extractAttributeString(thisNote, "discussionPhase");
        thisNote.put("pin", getPinOrder());
        thisNote.put("actionList", constructJSONArray(getActionList()));
        extractAttributeBool(thisNote, "suppressEmail");
        extractScalarLong(thisNote, "reportStart");
        extractScalarLong(thisNote, "reportEnd");
        thisNote.put("docList", constructJSONArray(getDocList()));

        // now make a read-only convenience with addition info about the document
        JSONArray attachedDocs = new JSONArray();
        for (AttachmentRecord att : this.getAttachedDocs(ngw)) {
            attachedDocs.put(att.getLinkableJSON());
        }
        thisNote.put("attachedDocs", attachedDocs);

        JSONObject labelMap = new JSONObject();
        for (NGLabel lRec : getLabels(ngw)) {
            labelMap.put(lRec.getName(), true);
        }
        thisNote.put("labelMap", labelMap);
        JSONArray subs = new JSONArray();
        NGRole subRole = getSubscriberRole();
        for (AddressListEntry ale : subRole.getDirectPlayers()) {
            subs.put(ale.getJSON());
        }
        thisNote.put("subscribers", subs);
        return thisNote;
    }

    public JSONObject getJSONWithMarkdown(NGWorkspace ngw) throws Exception {
        JSONObject noteData = getJSON(ngw);
        noteData.put("wiki", getWiki());
        return noteData;
    }

    public JSONObject getJSONWithComments(AuthRequest ar, NGWorkspace ngw) throws Exception {
        JSONObject noteData = getJSONWithMarkdown(ngw);
        JSONArray comments = getAllComments(ngw);
        /* DON'T add the meeting comments any more 
        for (MeetingRecord meet : getLinkedMeetings(ngw)) {
            JSONObject specialMeetingComment = new JSONObject();
            specialMeetingComment.put("emailSent", true);
            specialMeetingComment.put("meet", meet.getListableJSON(ar));
            specialMeetingComment.put("time", meet.getStartTime());
            specialMeetingComment.put("containerType", "T");
            specialMeetingComment.put("containerId", this.getId());
            specialMeetingComment.put("commentType", 4);
            comments.put(specialMeetingComment);
        }
        */
        noteData.put("comments", comments);
        return noteData;
    }

    public JSONObject getJSON4Note(String urlRoot, License license, NGWorkspace ngw) throws Exception {
        JSONObject thisNote = getJSON(ngw);
        String contentUrl = urlRoot + "note" + getId() + "/"
                + SectionUtil.sanitize(getSubject()) + ".txt?lic=" + license.getId();
        thisNote.put("content", contentUrl);
        return thisNote;
    }

    public void updateNoteFromJSON(JSONObject noteObj, AuthRequest ar) throws Exception {
        String universalid = noteObj.getString("universalid");
        if (!universalid.equals(getUniversalId())) {
            // just checking, this should never happen
            throw WeaverException.newBasic(
                    "Error trying to update the record for a note with UID (%s) with post from topic with UID (%s)",
                    getUniversalId(), universalid);
        }
        updateScalarString("subject", noteObj);
        if (noteObj.has("modifieduser") && noteObj.has("modifiedtime")) {
            setLastEdited(noteObj.getLong("modTime"));
            setModUser(AddressListEntry.fromJSON(noteObj.getJSONObject("modUser")));
        }
        if (noteObj.has("deleted")) {
            if (noteObj.getBoolean("deleted")) {
                // only set if not already set so that the user & date does
                // not get changed on every update
                if (!isDeleted()) {
                    setTrashPhase(ar);
                }
            } else {
                if (isDeleted()) {
                    clearTrashPhase(ar);
                }
            }
        }
        if (noteObj.has("data")) {
            setWiki(noteObj.getString("data"));
        }

        updateCommentsFromJSON(noteObj, ar);

        if (noteObj.has("docList")) {
            setDocList(constructVector(noteObj.getJSONArray("docList")));
        }
        if (noteObj.has("actionList")) {
            setActionList(constructVector(noteObj.getJSONArray("actionList")));
        }
        if (noteObj.has("labelMap")) {
            JSONObject labelMap = noteObj.getJSONObject("labelMap");
            List<NGLabel> selectedLabels = new ArrayList<NGLabel>();
            for (NGLabel stdLabel : ((NGWorkspace) ar.ngp).getAllLabels()) {
                String labelName = stdLabel.getName();
                if (labelMap.optBoolean(labelName)) {
                    selectedLabels.add(stdLabel);
                }
            }
            setLabels(selectedLabels);
        }
        if (noteObj.has("pin")) {
            setPinOrder(noteObj.getInt("pin"));
        }
        if (noteObj.has("discussionPhase")) {
            setDiscussionPhase(noteObj.getString("discussionPhase"), ar);
        }
        if (noteObj.has("sendEmailNow")) {
            boolean sendEmailNow = noteObj.getBoolean("sendEmailNow");
            setAttributeBool("suppressEmail", !sendEmailNow);
            if (sendEmailNow) {
                setAttributeBool("emailSent", false);
            }
        } else {
            updateAttributeBool("suppressEmail", noteObj);
        }
        if (noteObj.has("wiki")) {
            setWiki(noteObj.getString("wiki"));
        }
        NGRole subRole = getSubscriberRole();
        if (noteObj.has("subscribers")) {
            subRole.clear();
            JSONArray ja = noteObj.getJSONArray("subscribers");
            for (int i = 0; i < ja.length(); i++) {
                JSONObject oneSub = ja.getJSONObject(i);
                subRole.addPlayerIfNotPresent(AddressListEntry.fromJSON(oneSub));
            }
        }

        // simplistic for now ... if you update anything, you get added to the
        // subscribers
        subRole.addPlayerIfNotPresent(ar.getUserProfile().getAddressListEntry());
        updateScalarLong("reportStart", noteObj);
        updateScalarLong("reportEnd", noteObj);
    }

    public void mergeDoc(String oldMarkDown, String newMarkDown) {
        mergeScalar("data", oldMarkDown, newMarkDown);
    }

    /**
     * Needed for the EmailContext interface
     */
    public String getEmailURL(AuthRequest ar, NGWorkspace ngw) throws Exception {
        return ar.getResourceURL(ngw, "NoteZoom" + this.getId() + ".htm?")
                + AccessControl.getAccessTopicParams(ngw, this);
    }

    public String getUnsubURL(AuthRequest ar, NGWorkspace ngw, long commentId) throws Exception {
        return ar.getResourceURL(ngw, "unsub/" + this.getId() + "/" + commentId + ".htm?")
                + AccessControl.getAccessTopicParams(ngw, this);
    }

    public void extendNotifyList(List<AddressListEntry> addressList) throws Exception {
        getSubscriberRole().addPlayersIfNotPresent(addressList);

    }

    public void gatherUnsentScheduledNotification(NGWorkspace ngw,
            ArrayList<ScheduledNotification> resList, long timeout) throws Exception {
        ScheduledNotification sn = new NScheduledNotification(ngw, this);
        if (sn.needsSendingBefore(timeout)) {
            resList.add(sn);
        } else {
            // only look for comments when the email for the note (topic) has been sent
            // avoids problem of comment getting sent before the topic comes out of draft
            for (CommentRecord cr : getComments()) {
                cr.gatherUnsentScheduledNotification(ngw, new EmailContext(this), resList, timeout);
            }
        }
    }

    private class NScheduledNotification implements ScheduledNotification {
        private NGWorkspace ngw;
        private TopicRecord note;

        public NScheduledNotification(NGWorkspace _ngp, TopicRecord _note) {
            ngw = _ngp;
            note = _note;
        }

        @Override
        public boolean needsSendingBefore(long timeout) throws Exception {
            if (note.getEmailSent()) {
                return false;
            }
            if (note.isDraftNote()) {
                return false;
            }
            if (note.getAttributeBool("suppressEmail")) {
                return false;
            }
            return true;
        }

        @Override
        public long futureTimeToSend() throws Exception {
            if (note.getEmailSent()) {
                return -1;
            }
            if (note.isDraftNote()) {
                return -1;
            }
            if (note.getAttributeBool("suppressEmail")) {
                return -1;
            }
            return getLastEdited() + 1000;
        }

        @Override
        public void sendIt(AuthRequest ar, EmailSender mailFile) throws Exception {
            note.topicEmailRecord(ar, ngw, mailFile);
        }

        @Override
        public String selfDescription() throws Exception {
            return "(Note) " + note.getSubject();
        }
    }

    public String getGlobalContainerKey(NGWorkspace ngw) {
        return "T" + getId();
    }

    public long getReportStart() {
        return getScalarLong("reportStart");
    }
    public void setReportStart(long newDate) throws Exception {
        setScalarLong("reportStart", newDate);
    }

    public long getReportEnd() {
        return getScalarLong("reportEnd");
    }
    public void setReportEnd(long newDate) throws Exception {
        setScalarLong("reportEnd", newDate);
    }   

}
