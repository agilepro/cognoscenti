package com.purplehillsbooks.weaver;

import java.util.ArrayList;
import java.util.List;

import com.purplehillsbooks.weaver.mail.ScheduledNotification;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;

public class AgendaItem extends CommentContainer {

    public static final int STATUS_GOOD = 1;
    public static final int STATUS_MID  = 2;
    public static final int STATUS_POOR = 3;
    
    public String meetingId = "";


    public AgendaItem(Document doc, Element ele, DOMFace p) {
        super(doc, ele, p);
        //check if the lock needs to be cleared after being idle
        //for 30 minutes
        long lockTime = getLockTime();
        if (lockTime>0 && lockTime < System.currentTimeMillis()-30*60000) {
            clearLock();
        }
    }


    //This is a callback from container to set the specific fields
    public void addContainerFields(CommentRecord cr) {
        cr.containerType = CommentRecord.CONTAINER_TYPE_MEETING;
        cr.containerID = meetingId+":"+getId();
    }

    public String getId() {
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

/*
    public String getNotes()  throws Exception {
        return getScalar("notes");
    }
    public void setNotes(String newVal) throws Exception {
        setScalar("notes", newVal);
    }
    */

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

    /**
     * An agenda item might start as a proposed, and then later be
     * accepted (not proposed).  
     * 
     * For schema migration, old agenda items without a setting will
     * be considered to be already accepted (not proposed).
     */
    public boolean isProposed() {
        return getAttributeBool("proposed");
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

    public void startTimer() {
        boolean isRunning = getAttributeBool("timerRunning");
        if (!isRunning) {
            setAttributeBool("timerRunning", true);
            setAttributeLong("timerStart", System.currentTimeMillis());
        }
    }
    public void stopTimer() {
        boolean isRunning = getAttributeBool("timerRunning");
        if (isRunning) {
            setAttributeBool("timerRunning", false);
            long newElapse = System.currentTimeMillis() - getAttributeLong("timerStart");
            long oldElapse = getAttributeLong("timerElapsed");
            setAttributeLong("timerElapsed", oldElapse + newElapse);
        }
    }
    
    public String getMeetingNotes() {
        return getScalar("minutes");
    }

    public void mergeMinutes(String oldMins, String newMins) {
        mergeScalar("minutes", oldMins, newMins);
    }
    
    
    /**
     * full JSON representation including all comments, etc.
     */
    public JSONObject getJSON(AuthRequest ar, NGWorkspace ngw, MeetingRecord meet, boolean allComments) throws Exception {
        
        JSONObject aiInfo = new JSONObject();
        aiInfo.put("id",        getId());
        aiInfo.put("subject",   getSubject());
        aiInfo.put("duration",  getDuration());
        aiInfo.put("status",    getStatus());
        aiInfo.put("topicLink", getTopicLink());
        aiInfo.put("readyToGo", getReadyToGo());
        aiInfo.put("description", getDesc());
        
        //REMOVE THIS soon, no HTML
        //String htmlVal = WikiConverterForWYSIWYG.makeHtmlString(ar, getDesc());
        //aiInfo.put("desc",      htmlVal);
        aiInfo.put("position",  getPosition());
        aiInfo.put("number",    getNumber());
        aiInfo.put("isSpacer",  isSpacer());
        aiInfo.put("presenters", constructJSONArray(getPresenters()));
        //htmlVal = WikiConverterForWYSIWYG.makeHtmlString(ar, getNotes());
        //aiInfo.put("notes",     htmlVal);
        
        //duplicated the presenters into a list of full person definitions.
        //ultimately get rid of the other.
        JSONArray presenterList = new JSONArray();
        for (String presenterId : getPresenters()) {
            AddressListEntry ale = new AddressListEntry(presenterId);
            presenterList.put(ale.getJSON());
        }
        aiInfo.put("presenterList", presenterList);
        
        aiInfo.put("actionItems", constructJSONArray(getActionItems()));
        aiInfo.put("docList", constructJSONArray(getDocList()));
        addJSONComments(ar, aiInfo, allComments);

        AddressListEntry locker = getLockUser();
        if (locker!=null) {
            aiInfo.put("lockUser",  locker.getJSON());
        }
        extractAttributeBool(aiInfo, "showMinutes");
        extractAttributeBool(aiInfo, "timerRunning");
        extractAttributeLong(aiInfo, "timerStart");
        extractAttributeLong(aiInfo, "timerElapsed");
        extractAttributeBool(aiInfo, "proposed");
        extractScalarString(aiInfo, "minutes");
        
        //retire this soon, no more HTML to the client
        //String htmlMinutes = WikiConverterForWYSIWYG.makeHtmlString(ar, getScalar("minutes"));
        //aiInfo.put("minutes", htmlMinutes);
        
        return aiInfo;
    }


    public void updateFromJSON(AuthRequest ar, JSONObject input, NGWorkspace ngw) throws Exception {
        if (input.has("subject")) {
            setSubject(input.getString("subject"));
        }
        updateAttributeLong("duration", input);
        if (input.has("timerElapsed")) {
            if (getAttributeBool("timerRunning")) {
                //if the timer is running, the reset the basis for the current
                //timer to be NOW so that the elapsed time starts with what 
                //we just set it to.
                setAttributeLong("timerStart", System.currentTimeMillis());
            }
            updateAttributeLong("timerElapsed", input);
        }
        if (input.has("descriptionMerge")) {
            JSONObject mergeObj = input.getJSONObject("descriptionMerge");
            String lastSaveVal = mergeObj.optString("old", "");
            String newVal = mergeObj.getString("new");
            mergeScalar("desc", lastSaveVal, newVal);
        }
        else if (input.has("description")) {
        	//if there is a descriptionMerge, then ignore any complete description,
        	//only  one or the other
            setDesc(input.getString("description"));
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

        /*
        if (input.has("notes")) {
            String html = input.getString("notes");
            setNotes(HtmlToWikiConverter.htmlToWiki(ar.baseURL, html));
        }
        */
        if (input.has("minutesMerge")) {
        	mergeScalarDelta("minutes", input.getJSONObject("minutesMerge"));
        }
        if (input.has("topicLink")) {
            String topicLink = input.getString("topicLink");
            setTopicLink(topicLink);
        }
        
        updateCommentsFromJSON(input, ar);
        if (input.has("actionItems")) {
            setActionItems(constructVector(input.getJSONArray("actionItems")));
        }
        if (input.has("docList")) {
            setDocList(constructVector(input.getJSONArray("docList")));
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
        updateAttributeBool("isSpacer", input);
        updateAttributeBool("showMinutes", input);
        updateAttributeBool("proposed", input);
    }

    public void gatherUnsentScheduledNotification(NGWorkspace ngw, EmailContext meet, 
            ArrayList<ScheduledNotification> resList, long timeout) throws Exception {
        for (CommentRecord ac : this.getComments()) {
            ac.gatherUnsentScheduledNotification(ngw, meet, resList, timeout);
        }
    }


}