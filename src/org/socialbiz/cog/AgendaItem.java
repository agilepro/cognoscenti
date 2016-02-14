package org.socialbiz.cog;

import java.util.ArrayList;
import java.util.List;

import org.socialbiz.cog.mail.ScheduledNotification;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.workcast.json.JSONObject;

public class AgendaItem extends CommentContainer {

    public static final int STATUS_GOOD = 1;
    public static final int STATUS_MID  = 2;
    public static final int STATUS_POOR = 3;


    public AgendaItem(Document doc, Element ele, DOMFace p) {
        super(doc, ele, p);
        //check if the lock needs to be cleared after being idle
        //for 30 minutes
        long lockTime = getLockTime();
        if (lockTime>0 && lockTime < System.currentTimeMillis()-30*60000) {
            clearLock();
        }
        
        //transitional
        String name = getSubject();
        if ("BREAK".equals(name) || "LUNCH".equals(name) || "DINNER".equals(name)) {
            setSpacer(true);
        }
    }


    public String getId()  throws Exception {
        return getAttribute("id");
    }

    public String getSubject() {
        return getScalar("subject");
    }
    public void setSubject(String newVal) throws Exception {
        setScalar("subject", newVal);
    }

    public String getDesc() {
        return getScalar("desc");
    }
    public void setDesc(String newVal) throws Exception {
        setScalar("desc", newVal);
    }

    public long getDuration() {
        return safeConvertLong(getAttribute("duration"));
    }
    public void setDuration(long newVal) throws Exception {
        setAttribute("duration", Long.toString(newVal));
    }

    /**
     * This value represents the order of the agenda items in the meeting
     * Lower values are before higher values.
     */
    public int getPosition() {
        return getAttributeInt("position");
    }
    public void setPosition(int newVal) throws Exception {
        setAttributeInt("position", newVal);
    }

    /**
     * This value represents the visible number of the agenda.
     * Not all of the agenda items count.  Spacers don't count.
     */
    public int getNumber() {
        return getAttributeInt("number");
    }
    public void setNumber(int newVal) throws Exception {
        setAttributeInt("number", newVal);
    }
    
    /**
     * Some agenda items are numbered and some are just spacers,
     * like BREAK, LUNCH, and DINNER.  This flag says that this
     * item is just a spacer.
     */
    public boolean isSpacer() {
        return getAttributeBool("isSpacer");
    }
    public void setSpacer(boolean val) {
        setAttributeBool("isSpacer", val);
    }

    
    /**
     * An agenda item can be linked to a discussion topic
     */
    public String getTopicLink() {
        return getAttribute("topicLink");
    }
    public void setTopicLink(String newVal) throws Exception {
        setAttribute("topicLink", newVal);
    }

    public String getNotes()  throws Exception {
        return getScalar("notes");
    }
    public void setNotes(String newVal) throws Exception {
        setScalar("notes", newVal);
    }

    public int getStatus() {
        return getAttributeInt("status");
    }
    public void setStatus(int newVal) throws Exception {
        setAttributeInt("status", newVal);
    }

    public boolean getReadyToGo() {
        return getAttributeBool("readyToGo");
    }
    public void setReadyToGo(boolean newVal) throws Exception {
        setAttributeBool("readyToGo", newVal);
    }


    public List<String> getActionItems()  throws Exception {
        return getVector("actionId");
    }
    public void addActionItemId(String goalId)  throws Exception {
        this.addVectorValue("actionId", goalId);
    }
    public void setActionItems(List<String> newVal) throws Exception {
        setVector("actionId", newVal);
    }

    public List<String> getDocList()  throws Exception {
        return getVector("docList");
    }
    public void addDocId(String goalId)  throws Exception {
        this.addVectorValue("docList", goalId);
    }
    public void setDocList(List<String> newVal) throws Exception {
        setVector("docList", newVal);
    }

    public List<String> getPresenters()  throws Exception {
        return getVector("presenters");
    }
    public void setPresenters(List<String> newVal) throws Exception {
        setVector("presenters", newVal);
    }


    /**
     * This is the edit lock mechanism.  Before making a change the
     * client should get an edit lock on this object.  It records the user
     * and the time that the lock was made.  Locks are automatically cleared
     * 30 minutes after setting them ... nobody can hold a lock that long.
     * When a save is made, the lock should be cleared.
     * The current lock owner is communicated to the client, for two reasons:
     * 1. this is the flag that opens the editor
     * 2. this tells others that the object is currently being edited.
     *
     * Rules:
     * 1. get the lock before allowing the user to edit
     * 2. If you try to get the lock, but find out it is someone else,
     *    then display that it is being edited by that other person
     * 3. When you save the lock will be cleared, so you have to get it again.
     * 4. If the user cancels edit, be sure to clear the lock.
     *
     */
    public AddressListEntry getLockUser() {
        String user = getScalar("editUser");
        if (user==null || user.length()==0) {
            return null;
        }
        return new AddressListEntry(user);
    }
    public long getLockTime() {
        return safeConvertLong( getScalar("editTime"));
    }
    public void setLock(UserRef ur, long time) {
        setScalar("editUser", ur.getUniversalId());
        setScalar("editTime", Long.toString(time));
    }
    public void clearLock() {
        setScalar("editUser", null);
        setScalar("editTime", null);
    }

    /**
     * full JSON representation including all comments, etc.
     */
    public JSONObject getJSON(AuthRequest ar, NGWorkspace ngw, MeetingRecord meet) throws Exception {
        NoteRecord linkedTopic = ngw.getNoteByUidOrNull(getTopicLink());
        
        JSONObject aiInfo = new JSONObject();
        aiInfo.put("id",        getId());
        aiInfo.put("subject",   getSubject());
        aiInfo.put("duration",  getDuration());
        aiInfo.put("status",    getStatus());
        aiInfo.put("topicLink", getTopicLink());
        aiInfo.put("readyToGo", getReadyToGo());
        String htmlVal = WikiConverterForWYSIWYG.makeHtmlString(ar, getDesc());
        aiInfo.put("desc",      htmlVal);
        aiInfo.put("position",  getPosition());
        aiInfo.put("number",    getNumber());
        aiInfo.put("isSpacer",  isSpacer());
        htmlVal = WikiConverterForWYSIWYG.makeHtmlString(ar, getNotes());
        aiInfo.put("notes",     htmlVal);
        aiInfo.put("presenters", constructJSONArray(getPresenters()));
        
        if (linkedTopic!=null) {
            long includeCommentRangeStart = meet.getStartTime() - 7*24*60*60*1000;
            long includeCommentRangeEnd = meet.getStartTime() + 7*24*60*60*1000;
            aiInfo.put("actionItems", constructJSONArray(linkedTopic.getActionList()));
            aiInfo.put("docList", constructJSONArray(linkedTopic.getDocList()));
            linkedTopic.addJSONComments(ar, aiInfo, includeCommentRangeStart, includeCommentRangeEnd);
        }
        else {
            aiInfo.put("actionItems", constructJSONArray(getActionItems()));
            aiInfo.put("docList", constructJSONArray(getDocList()));
            addJSONComments(ar, aiInfo);
        }

        AddressListEntry locker = getLockUser();
        if (locker!=null) {
            aiInfo.put("lockUser",  locker.getJSON());
        }
        return aiInfo;
    }


    public void updateFromJSON(AuthRequest ar, JSONObject input, NGWorkspace ngw) throws Exception {
        NoteRecord linkedTopic = ngw.getNoteByUidOrNull(getTopicLink());
        
        if (input.has("subject")) {
            setSubject(input.getString("subject"));
        }
        if (input.has("duration")) {
            setDuration(input.getLong("duration"));
        }
        if (input.has("desc")) {
            String html = input.getString("desc");
            setDesc(HtmlToWikiConverter.htmlToWiki(ar.baseURL, html));
        }
        if (input.has("position")) {
            setPosition(input.getInt("position"));
        }
        if (input.has("status")) {
            setStatus(input.getInt("status"));
        }
        if (input.has("readyToGo")) {
            setReadyToGo(input.getBoolean("readyToGo"));
        }

        if (input.has("notes")) {
            String html = input.getString("notes");
            setNotes(HtmlToWikiConverter.htmlToWiki(ar.baseURL, html));
        }
        if (input.has("topicLink")) {
            String topicLink = input.getString("topicLink");
            setTopicLink(topicLink);
        }
        
        if (linkedTopic!=null) {
            //Comments, Goals, and Attachments come from the linked item, if an item
            //is linked, as well as Decisions (when implemented).
            linkedTopic.updateCommentsFromJSON(input, ar);
            if (input.has("actionItems")) {
                //note: this sets the ENTIRE list, and so you must not have selected
                //from the original list of action items.
                linkedTopic.setActionList(constructVector(input.getJSONArray("actionItems")));
            }
            if (input.has("docList")) {
                linkedTopic.setDocList(constructVector(input.getJSONArray("docList")));
            }
        }
        else {
            updateCommentsFromJSON(input, ar);
            if (input.has("actionItems")) {
                setActionItems(constructVector(input.getJSONArray("actionItems")));
            }
            if (input.has("docList")) {
                setDocList(constructVector(input.getJSONArray("docList")));
            }
        }

        if (input.has("presenters")) {
            setPresenters(constructVector(input.getJSONArray("presenters")));
        }


        if (input.has("setLock")) {
            AddressListEntry currentLocker = getLockUser();
            if (currentLocker==null) {
                setLock(ar.getUserProfile(), ar.nowTime);
            }
        }
        if (input.has("clearLock")) {
            AddressListEntry currentLocker = getLockUser();
            if (currentLocker!=null && ar.getUserProfile().equals(currentLocker)) {
                clearLock();
            }
        }
        if (input.has("isSpacer")) {
            setSpacer(input.getBoolean("isSpacer"));
        }

    }

    public void gatherUnsentScheduledNotification(NGPage ngp, EmailContext meet, ArrayList<ScheduledNotification> resList) throws Exception {
        for (CommentRecord ac : this.getComments()) {
            ac.gatherUnsentScheduledNotification(ngp, meet, resList);
        }
    }


}
