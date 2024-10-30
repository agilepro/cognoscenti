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
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import com.purplehillsbooks.weaver.exception.WeaverException;

import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.purplehillsbooks.json.JSONObject;


public class HistoryRecord extends DOMFace
{

    // list of outdated / unused history contexts
    //public final static int CONTEXT_TYPE_PROCESS      = 0;
    public final static int CONTEXT_TYPE_PERMISSIONS  = 2;
    public final static int CONTEXT_TYPE_ROLE         = 5;
    
    //These appear to be in use currently
    public final static int CONTEXT_TYPE_TASK         = 1;
    public final static int CONTEXT_TYPE_DOCUMENT     = 3;
    public final static int CONTEXT_TYPE_LEAFLET      = 4;
    public final static int CONTEXT_TYPE_CONTAINER    = 6;
    public final static int CONTEXT_TYPE_MEETING      = 7;
    public final static int CONTEXT_TYPE_DECISION     = 8;


    public final static String EVENT_TYPE_PREFIX="event.type";
    public final static String CONTEXT_TYPE_PREFIX="context.type";


    //public final static String OBJECT_TYPE_USER="object.type.user";
    //public final static String OBJECT_TYPE_ATTACHMENT="object.type.attachment";
    //public final static String OBJECT_TYPE_PLAYER="object.type.player";
    //public final static String OBJECT_TYPE_ROLE="object.type.role";
    //public final static String OBJECT_TYPE_PROCESS="object.type.process";
    //public final static String OBJECT_TYPE_TASK="object.type.task";
    //public final static String OBJECT_TYPE_NOTE="object.type.note";
    //public final static String OBJECT_TYPE_SUBTASK="object.type.subtask";

/*
    public final static String OBJECT_CREATED="object.created";
    public final static String OBJECT_SENT_BY_EMAIL="object.sent.by.email";
    public final static String OBJECT_MODIFIED="object.modified";
    public final static String OBJECT_DELETED="object.deleted";
    public final static String OBJECT_ACCESS_LEVEL_CHANGE="object.accees.level.changed";
    public final static String USER_REMOVED="user.removed";
    public final static String USER_ADDED="user.added";
    public final static String ROLE_REMOVED="role.removed";
    public final static String ROLE_ADDED="role.added";
    public final static String TASK_COMPLETED="task.completed";
    public final static String TASK_ACCEPTED="task.accepted";
    public final static String TASK_REJECTED="task.rejected";
    public final static String TASK_APPROVED="task.approved";
    public final static String TASK_STARTED ="task.started";
    public final static String DOC_ATTACHED="document.attached";
    public final static String DOC_UPDATED="document.updated";
    */


    // list of all the events.
    // states 0-6 are reserved as the old representation of 50-56

    public final static int EVENT_TYPE_CREATED  = 7;
    public final static int EVENT_TYPE_MODIFIED = 8;
    public final static int EVENT_TYPE_DELETED  = 9;

    public final static int EVENT_TYPE_APPROVED   = 10;
    public final static int EVENT_TYPE_REJECTED   = 11;

    public final static int EVENT_TYPE_SUBTASK_CREATED = 12;
    public final static int EVENT_TYPE_SUBLEAF_CREATED = 13;

    public final static int EVENT_TYPE_REORDERED = 14;

    public final static int EVENT_ROLE_ADDED     = 15;
    public final static int EVENT_ROLE_REMOVED   = 16;
    public final static int EVENT_ROLE_MODIFIED  = 17;


    public final static int EVENT_MEMBER_REQUEST = 20;
    public final static int EVENT_MEMBER_ADDED   = 21;
    public final static int EVENT_PLAYER_ADDED_CUSTOM_ROLE  = 41;
    public final static int EVENT_MEMBER_REMOVED = 22;
    public final static int EVENT_ADMIN_REQUEST  = 23;
    public final static int EVENT_ADMIN_ADDED    = 24;
    public final static int EVENT_ADMIN_REMOVED  = 25;
    public final static int EVENT_LEVEL_CHANGE   = 26;  //unspecified level change
    public final static int EVENT_PLAYER_ADDED   = 27;
    public final static int EVENT_PLAYER_REMOVED = 28;

    public final static int EVENT_DOC_ADDED    = 30;
    public final static int EVENT_DOC_REMOVED  = 31;
    public final static int EVENT_DOC_UPDATED  = 32;
    public final static int EVENT_DOC_APPROVED = 33;  //I read it and it is OK
    public final static int EVENT_DOC_REJECTED = 34;  //I read it and it needs improvement
    public final static int EVENT_DOC_SKIPPED  = 35;  //I decided not to read it
    public final static int EVENT_DOC_DOWNLOADED = 36;
    public final static int EVENT_COMMENT_ADDED= 39;
    public final static int EVENT_EMAIL_SENT   = 40;

    //These used to be states 0-6 to match the states of the task,
    //but then a new state was added to the task, but there was no room
    //for history states.  So now, the history states are 50 + task state.
    public final static int EVENT_TYPE_STATE_CHANGE_ERROR     = 50;
    public final static int EVENT_TYPE_STATE_CHANGE_UNSTARTED = 51;
    public final static int EVENT_TYPE_STATE_CHANGE_STARTED   = 52;
    public final static int EVENT_TYPE_STATE_CHANGE_ACCEPTED  = 53;
    public final static int EVENT_TYPE_STATE_CHANGE_WAITING   = 54;
    public final static int EVENT_TYPE_STATE_CHANGE_COMPLETE  = 55;
    public final static int EVENT_TYPE_STATE_CHANGE_SKIPPED   = 56;
    public final static int EVENT_TYPE_STATE_CHANGE_REVIEWED  = 57;
    // reserve states 58-69 for task state mapping

    public HistoryRecord(Document definingDoc, Element definingElement, DOMFace p)
    {
        super(definingDoc, definingElement, p);
    }

    public String getId()
        throws Exception
    {
        return getAttribute("id");
    }

    public void setId(String id)
        throws Exception
    {
        if (id.length()!=4) {
            throw WeaverException.newBasic("Invalid id, must be a exactly four digits and no other characters");
        }

        for (int i=0; i<4; i++)
        {
            if (id.charAt(i)<'0' || id.charAt(i)>'9') {
                throw WeaverException.newBasic("Invalid id, must be a exactly four digits and no other characters");
            }
        }
        setAttribute("id", id);
    }



    /**
     * TODO: document what the event type is
     */
    public int getEventType()
        throws Exception
    {
        int i = safeConvertInt(getScalar("type"));
        //These used to be states 0-6 to match the states of the task,
        //but then a new state was added to the task, but there was no room
        //for history states.  So now, the history states are 50 + task state.
        //This code converts the old value 0-6 to new values "on the fly"
        if (i>=0 && i<=6)
        {
            //increment by 50
            i = 50+i;
            //remember this so the file is consistent ... eventually
            setEventType(i);
        }

        return i;
    }
    public void setEventType(int type)
        throws Exception
    {
        setScalar("type", Integer.toString(type));
    }

    /**
    * The context is the id of the "object" that the history item is
    * about.
    * In the case of task history, the context is the id of the task
    * in the case of permission, the context is the name of user changed
    * in document, the context is the path of the document
    */
    public String getContext()
        throws Exception
    {
        return getScalar("context");
    }
    public void setContext(String context)
        throws Exception
    {
        setScalar("context", context);
    }

    /**
    * Tells how to interpret the context id.  Must be one of:
    * CONTEXT_TYPE_PROCESS      = 0;
    * CONTEXT_TYPE_TASK         = 1;
    * CONTEXT_TYPE_PERMISSIONS  = 2;
    * CONTEXT_TYPE_DOCUMENT     = 3;
    * CONTEXT_TYPE_LEAFLET      = 4;
    * CONTEXT_TYPE_ROLE         = 5;
    * CONTEXT_TYPE_CONTAINER    = 6;
    * CONTEXT_TYPE_MEETING      = 7;
    * CONTEXT_TYPE_DECISION     = 8;
    */
    public int getContextType() throws Exception {
        return safeConvertInt(getScalar("contextType"));
    }
    public void setContextType(int contextTypeVal) throws Exception {
        if (contextTypeVal<0 || contextTypeVal>8) {
            throw WeaverException.newBasic("Program Logic Error: history context type must be from 0 to 8.");
        }
        setScalar("contextType", Integer.toString(contextTypeVal));
    }

    /**
    * This records the specific version of the context object.
    * In the case of "reading" a document, when a new version
    * of the document arrives, it invalidates the read note.
    * For documents, the version is simply the timestamp of the document.
    */
    public long getContextVersion()
        throws Exception
    {
        return safeConvertLong(getScalar("contextVersion"));
    }
    public void setContextVersion(long context)
        throws Exception
    {
        setScalar("contextVersion", Long.toString(context));
    }


    /**
    * Each history item can have text explanation, presumably
    * entered by the user at the time of taking action.
    */
    public String getComments()
        throws Exception
    {
        return getScalar("comments");
    }
    public void setComments(String comment)
        throws Exception
    {
        if (comment==null)
        {
            comment = "";
        }
        setScalar("comments", comment);
    }

    /**
    * This is the timestamp at which the history action happened.
    */
    public long getTimeStamp()
        throws Exception
    {
        return safeConvertLong(getScalar("timestamp"));
    }
    public void setTimeStamp(long ts)
        throws Exception
    {
        setScalar("timestamp", Long.toString(ts));
    }

    public String getResponsible()
        throws Exception
    {
        return UserManager.getCorrectedEmail(getScalar("responsible"));
    }
    public void setResponsible(String resp)
        throws Exception
    {
        setScalar("responsible", resp);
    }

    public static String getContextTypeName(int ptype)
    {
        switch (ptype)
        {
            //case CONTEXT_TYPE_PROCESS:
            //    return "Process";
            case CONTEXT_TYPE_TASK:
                return "Action Item";
            case CONTEXT_TYPE_PERMISSIONS:
                return "Permission";
            case CONTEXT_TYPE_DOCUMENT:
                return "Document";
            case CONTEXT_TYPE_LEAFLET:
                return "Topic";
            case CONTEXT_TYPE_ROLE:
                return "Role";
            case CONTEXT_TYPE_MEETING:
                return "Meeting";
            case CONTEXT_TYPE_DECISION:
                return "Decision";
            default:
        }
        return "Object";
    }


    /**
    * @deprecated: remove this method when there is a chance.
    */
    public static HistoryRecord createHistoryRecord(NGWorkspace ngw,
        String context, int contextType, int eventType,
        AuthRequest ar, String comments) throws Exception
    {
        return createHistoryRecord(ngw, context, contextType, 0, eventType, ar, comments);
    }

    /**
     *
     * @param ngc the container (Workspace, Site, Profile) that this history is to add to
     * @param objectID this is the ID of the object that the history is about.  Use null string if about the entire container
     * @param contextType
     * @param contextVersion
     * @param eventType
     * @param ar
     * @param comments
     * @return
     * @throws Exception
     */
    public static HistoryRecord createHistoryRecord(NGWorkspace ngc,
        String objectID, int contextType, long contextVersion, int eventType,
        AuthRequest ar, String comments) throws Exception
    {
        //there are certain situations where the editor is doing automatic saves, and creating the same
        //history item over and over.  This suppresses all the duplicate history records, but looking
        //at the last history.  If it is the same, then it simply updates the timestamp, and retains
        //that, without creating a new history item.
        HistoryRecord hr = ngc.getLatestHistory();
        if (hr!=null && hr.getContextType() == contextType && hr.getContext().equals(objectID) &&
                hr.getEventType() == eventType) {
            hr.setTimeStamp(ar.nowTime);
            return hr;
        }

        hr = ngc.createNewHistory();
        hr.setContext(objectID);
        hr.setContextType(contextType);
        hr.setContextVersion(contextVersion);
        hr.setEventType(eventType);
        hr.setResponsible(ar.getBestUserId());
        hr.setComments(comments);
        hr.setTimeStamp(ar.nowTime);
        return hr;
    }

    /**
     * Creates a history record appropriate for the entire container
     * without referring to any part within the container.
     */
    public static HistoryRecord createContainerHistoryRecord(NGWorkspace ngc,
            int eventType, AuthRequest ar, String comments) throws Exception
    {
        return createHistoryRecord(ngc, "",  HistoryRecord.CONTEXT_TYPE_CONTAINER,
                0, eventType, ar, comments);
    }

    /**
     * Creates a history record appropriate for a change to a topic.
     */
    public static HistoryRecord createNoteHistoryRecord(NGWorkspace ngc,
            TopicRecord note, int eventType, AuthRequest ar, String comments) throws Exception
    {
        return createHistoryRecord(ngc, note.getId(),  HistoryRecord.CONTEXT_TYPE_LEAFLET,
                0, eventType, ar, comments);
    }



    public String getCombinedKey()
        throws Exception
    {
        String messageID;
        int ctx = getContextType();
        switch (ctx) {
            //case CONTEXT_TYPE_PROCESS:
            //    messageID = "history.process.";
            //    break;
            case CONTEXT_TYPE_TASK:
                messageID = "history.task.";
                break;
            case CONTEXT_TYPE_PERMISSIONS:
                messageID = "history.permission.";
                break;
            case CONTEXT_TYPE_DOCUMENT:
                messageID = "history.doc.";
                break;
            case CONTEXT_TYPE_LEAFLET:
                messageID = "history.note.";
                break;
            case CONTEXT_TYPE_ROLE:
                messageID = "history.role.";
                break;
            case CONTEXT_TYPE_MEETING:
                messageID = "history.meeting.";
                break;
            case CONTEXT_TYPE_DECISION:
                messageID = "history.decision.";
                break;
            case CONTEXT_TYPE_CONTAINER:
                //THIS IS NEVER USED!
                messageID = "history.container.";
                break;
            default:
                throw WeaverException.newBasic("HistoryRecord.getCombinedKey does "
                + "not know how to handle a context type value: %s ", ctx);
        }

        int event = getEventType();
        switch (event)
        {
            case EVENT_TYPE_CREATED:
                //history.note.created  506
                //history.process.created   397
                //history.role.created  15
                //history.task.created  1028
                return messageID+"created";
            case EVENT_TYPE_MODIFIED:
                //history.note.modified 1617
                //history.process.modified  23
                //history.task.modified 2014
                return messageID+"modified";
            case EVENT_TYPE_DELETED:
                //history.note.deleted  35
                return messageID+"deleted";
            case EVENT_TYPE_APPROVED:
                //history.task.approved 16
                return messageID+"approved";
            case EVENT_TYPE_REJECTED:
                //history.task.rejected 2
                return messageID+"rejected";
            case EVENT_TYPE_SUBTASK_CREATED:
                //history.task.subtask.add  113
                return messageID+"subtask.add";
            case EVENT_TYPE_SUBLEAF_CREATED:
                //history.task.subproject.add   9
                return messageID+"subproject.add";
            case EVENT_TYPE_REORDERED:
                return messageID+"reordered";
            case EVENT_ROLE_ADDED:
                //history.role.role.add 10
                return messageID+"role.add";
            case EVENT_ROLE_REMOVED:
                return messageID+"role.remove";
            case EVENT_ROLE_MODIFIED:
                //history.role.role.mod 22
                return messageID+"role.mod";
            case EVENT_TYPE_STATE_CHANGE_ERROR:
                //history.process.state.error   2
                return messageID+"state.error";
            case EVENT_TYPE_STATE_CHANGE_UNSTARTED:
                return messageID+"state.unstarted";
            case EVENT_TYPE_STATE_CHANGE_STARTED:
                //history.task.state.started    65
                return messageID+"state.started";
            case EVENT_TYPE_STATE_CHANGE_ACCEPTED:
                //history.task.state.accepted   206
                return messageID+"state.accepted";
            case EVENT_TYPE_STATE_CHANGE_WAITING:
                return messageID+"state.waiting";
            case EVENT_TYPE_STATE_CHANGE_COMPLETE:
                //history.task.state.completed  553
                return messageID+"state.completed";
            case EVENT_TYPE_STATE_CHANGE_SKIPPED:
                return messageID+"state.skipped";
            case EVENT_TYPE_STATE_CHANGE_REVIEWED:
                return messageID+"state.reviewed";
            case EVENT_MEMBER_REQUEST:
                //history.permission.member.request 26
                return messageID+"member.request";
            case EVENT_MEMBER_ADDED:
                //history.permission.member.add 179
                return messageID+"member.add";
            case EVENT_MEMBER_REMOVED:
                //history.permission.member.remove  21
                return messageID+"member.remove";
            case EVENT_ADMIN_REQUEST:
                //history.permission.admin.request  12
                return messageID+"admin.request";
            case EVENT_ADMIN_ADDED:
                //history.permission.admin.add  6
                return messageID+"admin.add";
            case EVENT_ADMIN_REMOVED:
                //history.permission.admin.remove   3
                return messageID+"admin.remove";
            case EVENT_LEVEL_CHANGE:
                //history.doc.access.level.change: 1
                //history.note.access.level.change  39
                //history.permission.access.level.change    1
                //history.role.access.level.change  122
                return messageID+"access.level.change";
            case EVENT_PLAYER_ADDED:
                //history.permission.player.add 233
                //history.role.player.add   322
                return messageID+"player.add";
            case EVENT_PLAYER_REMOVED:
                //history.role.player.removed   188
                return messageID+"player.removed";
            case EVENT_PLAYER_ADDED_CUSTOM_ROLE:
                //history.permission.player.custom  105
                return messageID+"player.custom";
            case EVENT_DOC_ADDED:
                //history.doc.attached  1899
                return messageID+"attached";
            case EVENT_DOC_REMOVED:
                //history.doc.removed   47
                return messageID+"removed";
            case EVENT_DOC_UPDATED:
                //history.doc.updated   414
                return messageID+"updated";
            case EVENT_DOC_APPROVED:
                //history.doc.mark.read   7
                return messageID+"mark.read";
            case EVENT_DOC_REJECTED:
                //history.doc.mark.reject   1
                return messageID+"mark.reject";
            case EVENT_DOC_SKIPPED:
                return messageID+"mark.skipped";
            case EVENT_DOC_DOWNLOADED:
                return messageID+"downloaded";
            case EVENT_EMAIL_SENT:
                //history.note.email.sent   1173
                //history.process.email.sent  1
                return messageID+"email.sent";
            default:
                return messageID+"((HISTORY TYPE "+event+"))";
        }

    }

/*
 *
 * Performed a study of the actual history states that
 * were used in the 7 year history of the Nugen server
 * in the office.   Some of these might have been in the
 * early early years and no longer produced.
 *
history.doc.access.level.change  1
history.doc.attached    1899
history.doc.mark.read   7
history.doc.mark.reject 1
history.doc.removed 47
history.doc.updated 414
history.note.access.level.change    39
history.note.created    506
history.note.deleted    35
history.note.email.sent 1173
history.note.modified   1617
history.permission.access.level.change  1
history.permission.admin.add    6
history.permission.admin.remove 3
history.permission.admin.request    12
history.permission.member.add   179
history.permission.member.remove    21
history.permission.member.request   26
history.permission.player.add   233
history.permission.player.custom    105
history.process.created 397
history.process.email.sent  1
history.process.modified    23
history.process.state.error 2
history.role.access.level.change    122
history.role.created    15
history.role.player.add 322
history.role.player.removed 188
history.role.role.add   10
history.role.role.mod   22
history.task.approved   16
history.task.created    1028
history.task.modified   2014
history.task.rejected   2
history.task.state.accepted 206
history.task.state.completed    553
history.task.state.started  65
history.task.subproject.add 9
history.task.subtask.add    113
 *
 *
 *
 */

    public static String convertEventTypeToString(int type)
    {
        switch (type)
        {
            case EVENT_TYPE_CREATED:
                return "created";
            case EVENT_TYPE_MODIFIED:
                return "modified";
            case EVENT_TYPE_DELETED:
                return "deleted";
            case EVENT_TYPE_APPROVED:
                return "approved";
            case EVENT_TYPE_REJECTED:
                return "rejected";
            case EVENT_TYPE_SUBTASK_CREATED:
                return "subtask added";
            case EVENT_TYPE_SUBLEAF_CREATED:
                return "subleaf added";
            case EVENT_TYPE_REORDERED:
                return "reordered";
            case EVENT_ROLE_ADDED:
                return "added new role";
            case EVENT_ROLE_REMOVED:
                return "removed role";
            case EVENT_ROLE_MODIFIED:
                return "modified role";
            case EVENT_TYPE_STATE_CHANGE_ERROR:
                return "set into error state";
            case EVENT_TYPE_STATE_CHANGE_UNSTARTED:
                return "reset to unstarted state";
            case EVENT_TYPE_STATE_CHANGE_STARTED:
                return "started";
            case EVENT_TYPE_STATE_CHANGE_ACCEPTED:
                return "accepted";
            case EVENT_TYPE_STATE_CHANGE_WAITING:
                return "set to waiting state";
            case EVENT_TYPE_STATE_CHANGE_COMPLETE:
                return "completed";
            case EVENT_TYPE_STATE_CHANGE_SKIPPED:
                return "set to skipped state";
            case EVENT_TYPE_STATE_CHANGE_REVIEWED:
                return "marked as reviewed";
            case EVENT_MEMBER_REQUEST:
                return "made prospective member";
            case EVENT_MEMBER_ADDED:
                return "added to members";
            case EVENT_MEMBER_REMOVED:
                return "removed from being a member";
            case EVENT_ADMIN_REQUEST:
                return "made prospective admin";
            case EVENT_ADMIN_ADDED:
                return "made admin";
            case EVENT_ADMIN_REMOVED:
                return "removed from being an admin";
            case EVENT_LEVEL_CHANGE:
                return "had access level changed";
            case EVENT_PLAYER_ADDED:
                return "added to role";
            case EVENT_PLAYER_REMOVED:
                return "removed from role";
            case EVENT_DOC_ADDED:
                return "attached";
            case EVENT_DOC_REMOVED:
                return "removed";
            case EVENT_DOC_UPDATED:
                return "updated";
            case EVENT_DOC_APPROVED:
                return "marked as read";
            case EVENT_DOC_REJECTED:
                return "marked as revisions needed";
            case EVENT_DOC_SKIPPED:
                return "marked as skipped";
            case EVENT_DOC_DOWNLOADED:
                return "downloaded";
            case EVENT_EMAIL_SENT:
                return "sent as email";
            case EVENT_COMMENT_ADDED:
                return "extended with a comment";
            default:
                return "modified (#"+type+")";
        }
    }


    public static void sortByTimeStamp(List<HistoryRecord> list)
    {
        Collections.sort(list, new HistoryRecord.HistoryTimeStampComparator());
    }

    public static void sortByContext(List<HistoryRecord> list)
    {
        Collections.sort(list, new HistoryRecord.HistoryContextComparator());
    }



    public static class HistoryTimeStampComparator implements Comparator<HistoryRecord>
    {
        public HistoryTimeStampComparator() {}

        public int compare(HistoryRecord o1, HistoryRecord o2) {
            try {
                long ts1 = o1.getTimeStamp();
                long ts2 = o2.getTimeStamp();
                if (ts1 == ts2) {
                    return 0;
                }
                if (ts1 > ts2) {
                    return -1;
                }
                return 1;
            }
            catch (Exception e) {
                return 0;
            }
        }
    }

    public static class HistoryContextComparator implements Comparator<HistoryRecord>
    {
        public HistoryContextComparator() {}

        public int compare(HistoryRecord o1, HistoryRecord o2) {
            try {
                String c1 = o1.getContext();
                String c2 = o2.getContext();
                int comp = c1.compareTo(c2);
                if (comp != 0) {
                    return comp;
                }
                long ts1 = o1.getContextVersion();
                long ts2 = o2.getContextVersion();
                if (ts1 > ts2) {
                    return -1;
                }
                if (ts1 < ts2) {
                    return 1;
                }
                ts1 = o1.getTimeStamp();
                ts2 = o2.getTimeStamp();
                if (ts1 > ts2) {
                    return -1;
                }
                if (ts1 < ts2) {
                    return 1;
                }
                return 0;
            }
            catch (Exception e) {
                return 0;
            }
        }
    }


    public void writeLocalizedHistoryMessage(NGWorkspace ngw, AuthRequest ar) throws Exception {
        /*
         * Previously, we used a way where the object type and the action type were combined to a
         * key which then brought up a record from the messages bundle.  However, this didn't
         * really work for the Angular UI, so it was abandoned.
         *
         * Instead we compose the message simply from the object type name, and the action name.
         */

        ar.writeHtml(getContextTypeName(getContextType()));
        ar.write(" <a href=\"");
        ar.write(ar.baseURL);
        ar.write(lookUpURL(ar, ngw));
        ar.write("\">");
        ar.writeHtml(lookUpObjectName(ngw));
        ar.write("</a> was ");
        ar.writeHtml(convertEventTypeToString(getEventType()));
        ar.write(" by ");
        AddressListEntry ale = AddressListEntry.findOrCreate(getResponsible());
        ale.writeLink(ar);
        ar.write(" on ");
        SectionUtil.nicePrintDate(ar.w, getTimeStamp(), null);
        String comment = this.getComments();
        if (comment!=null && comment.length()>0) {
            ar.write(" - ");
            ar.writeHtml(comment);
        }
    }

    public JSONObject getJSON(NGWorkspace ngw, AuthRequest ar) throws Exception {
        AddressListEntry ale = AddressListEntry.findOrCreate(getResponsible());
        JSONObject jo = new JSONObject();
        jo.put("ctxId", getContext());
        jo.put("ctxName", lookUpObjectName(ngw));
        jo.put("ctxProject", ngw.getKey());
        jo.put("ctxSite", ngw.getSiteKey());
        jo.put("ctxType", getContextTypeName(getContextType()));
        jo.put("event", convertEventTypeToString(getEventType()));
        jo.put("responsible", ale.getJSON());
        jo.put("time",getTimeStamp());
        jo.put("comment",getComments());
        return jo;
    }

    public String lookUpObjectName(NGWorkspace ngw) throws Exception {
        int contextType = getContextType();
        String objectKey = getContext();
        if (contextType == HistoryRecord.CONTEXT_TYPE_TASK) {
            GoalRecord gr = ngw.getGoalOrNull(objectKey);
            if (gr!=null) {
                return gr.getSynopsis();
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_DOCUMENT) {
            AttachmentRecord att = ngw.findAttachmentByID(objectKey);
            if (att!=null) {
                return att.getDisplayName();
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_LEAFLET) {
            TopicRecord nr = ngw.getDiscussionTopic(objectKey);
            if (nr!=null) {
                return nr.getSubject();
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_MEETING) {
            MeetingRecord meet = ngw.findMeetingOrNull(objectKey);
            if (meet!=null) {
                return meet.getName() + " @ " + SectionUtil.getNicePrintDate( meet.getStartTime() );
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_DECISION) {
            DecisionRecord dr = ngw.findDecisionOrNull(safeConvertInt(objectKey));
            if (dr!=null) {
                String val = dr.getDecision();
                if (val.length()>30) {
                    val = val.substring(0,30);
                }
                return "#" + dr.getNumber() + ": " + val;
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_PERMISSIONS) {
            return objectKey;
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_ROLE) {
            NGRole role = ngw.getRole(objectKey);
            if (role!=null) {
                return role.getName();
            }
        }
        return "Unknown";
    }

    public String lookUpURL(AuthRequest ar, NGWorkspace ngw) throws Exception {
        return lookUpResourceURL(ar, ngw, getContextType(), getContext());
    }

    /**
     * Get a 'standard' URL for accessing object based on their type and ID.
     * Only work on a single project workspace.
     */
    public static String lookUpResourceURL(AuthRequest ar, NGWorkspace ngw,
            int contextType, String contextKey) throws Exception {

        //always encode to avoid problems with injection
        String objectKey = URLEncoder.encode(contextKey, "UTF-8");

        if (contextType == HistoryRecord.CONTEXT_TYPE_TASK) {
            return  ar.getResourceURL(ngw, "task"+objectKey+".htm");
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_DOCUMENT) {
            return ar.getResourceURL(ngw, "DocDetail.htm?aid="+objectKey);
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_LEAFLET) {
            return ar.getResourceURL(ngw, "noteZoom"+objectKey+".htm");
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_MEETING) {
            return ar.getResourceURL(ngw, "MeetingHtml.htm?id=")+objectKey;
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_DECISION) {
            return ar.getResourceURL(ngw, "DecisionList.htm#DEC")+objectKey;
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_PERMISSIONS) {
            return ar.getResourceURL(ngw, "findUser.htm?id=")+objectKey;
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_ROLE) {
            return ar.getResourceURL(ngw, "RoleManagement.htm");
        }
        return ar.getResourceURL(ngw, "FrontPage.htm");
    }


}
