package com.purplehillsbooks.weaver;

import java.io.File;
import java.io.Writer;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.Hashtable;
import java.util.List;
import java.util.TimeZone;

import com.purplehillsbooks.weaver.mail.EmailGenerator;
import com.purplehillsbooks.weaver.mail.EmailSender;
import com.purplehillsbooks.weaver.mail.OptOutAddr;
import com.purplehillsbooks.weaver.mail.ScheduledNotification;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;

public class MeetingRecord extends DOMFace {

    public static final int MEETING_TYPE_CIRCLE = 1;
    public static final int MEETING_TYPE_OPERATIONAL = 2;

    public static final int MEETING_STATE_DRAFT = 0;
    public static final int MEETING_STATE_PLANNING = 1;
    public static final int MEETING_STATE_RUNNING = 2;
    public static final int MEETING_STATE_COMPLETED = 3;



    public MeetingRecord(Document doc, Element ele, DOMFace p) throws Exception {
        super(doc, ele, p);

        String defaultLayout = getScalar("defaultLayout");
        if (defaultLayout==null || defaultLayout.length()==0) {
            setScalar("defaultLayout", "MinutesDetails.chtml");
        }
        String notifyLayout = getScalar("notifyLayout");
        if (notifyLayout==null || notifyLayout.length()==0) {
            setScalar("notifyLayout", "AgendaDetail.chtml");
        }
    }



    public String getId() {
        return getAttribute("id");
    }

    public String getName() {
        return getAttribute("name");
    }
    public void setName(String newVal) throws Exception {
        setAttribute("name", newVal);
    }

    /**
     * The owner is the actual user who created this meeting.
     * Email will appear to be from this user.
     */
    public String getOwner() throws Exception {
        return getScalar("owner");
    }
    public void setOwner(String newVal) throws Exception {
        setScalar("owner", newVal);
    }

    public String getMeetingDescription()  throws Exception {
        return getScalar("meetingInfo");
    }
    private void setMeetingInfo(String newVal) throws Exception {
        setScalar("meetingInfo", newVal);
    }

    public int getState() {
        return getAttributeInt("state");
    }
    public void setState(int newVal) throws Exception {
        setAttributeInt("state", newVal);
    }

    public long getStartTime() {
        return getAttributeLong("startTime");
    }
    private void setStartTime(long newVal) throws Exception {
        setAttributeLong("startTime", newVal);
    }

    /**
     * Meeting duration in minutes
     */
    public long getDuration()  throws Exception {
        return getAttributeLong("duration");
    }
    public void setDuration(long newVal) throws Exception {
        setAttributeLong("duration", newVal);
    }

    private void setMeetingType(int newVal) {
        setAttributeInt("meetingType", newVal);
    }


    public String getTargetRole()  throws Exception {
        return getAttribute("targetRole");
    }
    public void setTargetRole(String newVal) throws Exception {
        setAttribute("targetRole", newVal);
    }
    public List<String> getParticipants() {
        return this.getVector("participants");
    }
    public void setParticipants(List<String> newSet) {
        this.setVector("participants", newSet);
    }

    public String getConferenceUrl() {
        return getAttribute("conferenceUrl");
    }
    public void setConferenceUrl(String newVal) throws Exception {
        setAttribute("conferenceUrl", newVal);
    }


    public void appendTargetEmails(List<OptOutAddr> sendTo, NGWorkspace ngw) throws Exception {
        List<String> partUsers = this.getVector("participants");
        if (partUsers.size()>0) {
            //append the participants if there are any
            OptOutAddr.appendUsersEmail(partUsers,sendTo);
        }
        else {
            //if no participants, get the members of the role
            String targetRole = getTargetRole();
            if (targetRole==null || targetRole.length()==0) {
                targetRole = "Members";
            }
            OptOutAddr.appendUnmutedUsersFromRole(ngw, targetRole, sendTo);
        }
    }

    public List<AgendaItem> getAgendaItems() throws Exception {
        List<AgendaItem> ret = getChildren("agenda", AgendaItem.class);
        for (AgendaItem ai : ret) {
            ai.setMeeting(this);
        }
        return ret;
    }
    public List<AgendaItem> getSortedAgendaItems() throws Exception {
        List<AgendaItem> tempList = getAgendaItems();
        Collections.sort(tempList, new AgendaItemPositionComparator());
        return tempList;
    }
    public AgendaItem findAgendaItem(String id) throws Exception {
        if (id==null) {
            throw new Exception("Program Logic Error: Attempt to find an agenda item with a null id");
        }
        AgendaItem ai = findAgendaItemOrNull(id);
        if (ai==null) {
            throw new Exception("Agenda Item with that id ("+id+") does not exist in this meeting.");
        }
        return ai;
    }
    public AgendaItem findAgendaItemOrNull(String id) throws Exception {
        for (AgendaItem ai : getAgendaItems()) {
            if (id.equals(ai.getId())) {
                return ai;
            }
        }
        return null;
    }
    public AgendaItem createAgendaItem(NGWorkspace ngw) throws Exception {
        AgendaItem ai = createChildWithID("agenda", AgendaItem.class, "id", ngw.getUniqueOnPage());
        ai.setMeeting(this);
        ai.setPosition(99999);   //position it at the end
        return ai;
    }
    public void removeAgendaItem(String id) throws Exception {
        removeChildrenByNameAttrVal("agenda", "id", id);
    }

    public String getMinutesId()  throws Exception {
        return getAttribute("minutesId");
    }
    public void setMinutesId(String newVal) throws Exception {
        setAttribute("minutesId", newVal);
    }


    /**
     * Reminder time is the amount of time (in minutes) before
     * the meeting to automatically send everyone the reminder.
     */
    public int getReminderAdvance()  throws Exception {
        return getAttributeInt("reminderTime");
    }
    private void setReminderAdvance(int newVal) throws Exception {
        setAttributeInt("reminderTime", newVal);
    }

    /**
     * This is the actual time that the reminder was actually sent.
     */
    private long getReminderSent()  throws Exception {
        return getAttributeLong("reminderSent");
    }
    private void setReminderSent(long newVal) throws Exception {
        setAttributeLong("reminderSent", newVal);
    }

    /**
     * If the meeting is in running state, and if the specified person is
     * not in the attendee list, this will add them.
     *
     * Returns true if it actually made a change, false if not
     * @param uRef
     */
    public boolean addAttendeeIfNeeded(UserRef uRef) {
        if (MeetingRecord.MEETING_STATE_RUNNING == getState()) {
            List<String> attendees = getVector("attended");
            boolean foundMe = false;
            for (String attendee : attendees) {
                if (uRef.hasAnyId(attendee)) {
                    foundMe = true;
                }
            }
            if (!foundMe) {
                attendees.add(uRef.getUniversalId());
                setVector("attended", attendees);
                return true;
            }
        }
        return false;
    }
    private List<String> getAttendees() {
        return getVector("attended");
    }


    /**
     * NO LONGER a special meeting which is actually the container for backlog
     * agenda items. Should never exist any more.
     */
    public boolean deprecatedBacklogMeetingNoLongerAllowed() {
        return "true".equals(getAttribute("isBacklog"));
    }

    public boolean isScheduled() {
        return getStartTime()>100000000;
    }


    /**
     * Gives all the agenda items sequential increasing numbers
     */
    public void renumberItems() throws Exception {
        List<AgendaItem> tempList = getSortedAgendaItems();
        int pos = 0;
        int num = 0;
        for (AgendaItem ai : tempList) {
            ai.setPosition(++pos);
            if (ai.isSpacer()) {
                ai.setNumber(-1);
            }
            else {
                ai.setNumber(++num);
            }
        }
    }

    /**
     *
     */
    private void verifyTargetRole(NGWorkspace ngw) throws Exception {
        String target = this.getTargetRole();
        NGRole ngr = ngw.getRole(target);
        if (ngr!=null) {
            //ok, role exists, return
            return;
        }

        //specified role does not exist
        //so set it to 'Members'
        ngr = ngw.getRole("Members");
        if (ngr!=null) {
            this.setTargetRole("Members");
            return;
        }

        //oops, not even members exists.
        //set to the first role
        for (NGRole ngr2 : ngw.getAllRoles()) {
            this.setTargetRole(ngr2.getName());
            return;
        }

        //oh no, there are no roles at all.  Give up
        throw new Exception("Workspace ("+ngw.getFullName()+") does not appear to have any roles and at least one is required to have a meeting.");
    }

    /**
     * increments all the positions of the agenda items that are AT or
     * greater than the specified position.  Leaves the positions of those
     * less than the position alone.
     *
     * Usage to place a new agenda item at the position of 5,
     * then call openPosition(5) to make an opening, then set the desired
     * item to position 5,  then call renumber items to close any gaps left.
     */
    public void openPosition(int spacePos) throws Exception {
        for (AgendaItem ai : getAgendaItems()) {
            int thisPos = ai.getPosition();
            if (thisPos>=spacePos) {
                ai.setPosition(thisPos+1);
            }
        }
    }

    /**
     * Find all the agenda items that are linked to a particular document.
     * Pass in the universal id of the document attachment.
     */
    public List<AgendaItem> getDocumentLinkedAgendaItems(String docUniversalId) throws Exception {
        ArrayList<AgendaItem> allItems = new ArrayList<AgendaItem>();
        for (AgendaItem ai : this.getSortedAgendaItems()) {
            for (String docId : ai.getDocList()) {
                if (docUniversalId.equals(docId)) {
                    allItems.add(ai);
                }
            }
        }
        return allItems;
    }
    public List<String> getDocListIncludeComments() throws Exception {
        List<String> allDocList = new ArrayList<String>();
        for (AgendaItem ai : this.getSortedAgendaItems()) {
            for (String docId :ai.getDocList()) {
                if (!allDocList.contains(docId)) {
                    allDocList.add(docId);
                }
            }
            for (CommentRecord comm : ai.getComments()) {
                for (String docId : comm.getDocList()) {
                    if (!allDocList.contains(docId)) {
                        allDocList.add(docId);
                    }
                }
            }
        }
        return allDocList;
    }


    public void startTimer(String itemId) throws Exception {
        if (getState()!=2) {
            //if the meeting is not currently "running" then make it so
            setState(2);
        }
        boolean found = false;
        for (AgendaItem ai : this.getAgendaItems()) {
            if (ai.getId().equals(itemId)) {
                ai.startTimer();
                found = true;
            }
            else {
                ai.stopTimer();
            }
        }
        if (!found) {
            throw new Exception("Unable to find an agenda item with the id: "+itemId);
        }
    }
    public void stopTimer() throws Exception {
        for (AgendaItem ai : this.getAgendaItems()) {
            ai.stopTimer();
        }
    }


    /**
     * This is used to set particular aspects of the meeting time, without having to save
     * (and potentialy overwrite) another person's settings, allowing people to be settings
     * times simultaneously.
     *
     * Send in
     *
     * {
     *     "action":    "SetValue",
     *     "isCurrent": true/false,
     *     "time":      15432432534,
     *     "user":      "george.washington@whitehouse.gov",
     *     "value":     3
     * }
     *
     * or
     *
     * {
     *     "action":    "AddTime",
     *     "isCurrent": true/false,
     *     "time":      15432432534
     * }
     * {
     *     "action":    "RemoveTime",
     *     "isCurrent": true/false,
     *     "time":      15432432534
     * }
     * {
     *     "action":    "ChangeTime",
     *     "isCurrent": true/false,
     *     "time":      15432432534,
     *     "newTime":   15432888888
     * }
     *
     */
    public void actOnProposedTime(JSONObject cmdInput) throws Exception {
        String action = cmdInput.getString("action");
        if ("SetValue".equals(action)) {
            long time = cmdInput.getLong("time");
            MeetingProposeTime mpt = findProposedTime("timeSlots", time);
            if (mpt==null) {
                throw new Exception("This meeting does not have a proposed time of "+time);
            }
            String user = cmdInput.getString("user");
            int value = cmdInput.getInt("value");
            mpt.setPersonValue(user, value);
        }
        else if ("AddTime".equals(action)) {
            long time = cmdInput.getLong("time");
            MeetingProposeTime mpt = createChild("timeSlots", MeetingProposeTime.class);
            mpt.setProposedTime(time);
        }
        else if ("RemoveTime".equals(action)) {
            long time = cmdInput.getLong("time");
            this.removeChildrenByNameAttrVal("timeSlots", "proposedTime", Long.toString(time));
        }
        else if ("ChangeTime".equals(action)) {
            long newTime = cmdInput.getLong("newTime");
            MeetingProposeTime mpt = createChild("timeSlots", MeetingProposeTime.class);
            mpt.setProposedTime(newTime);
        }
        else if ("RemoveUser".equals(action)) {
            String user = cmdInput.getString("user");
            this.removeUserFromAllSlots("timeSlots", user);
        }
        else {
            throw new Exception("actOnProposedTime does not understand the command: "+action);
        }
    }

    private MeetingProposeTime findProposedTime(String fieldName, long timeValue) throws Exception {
        List<MeetingProposeTime> timeSlot = getChildren(fieldName, MeetingProposeTime.class);
        for (MeetingProposeTime oneSlot : timeSlot) {
            if (oneSlot.getProposedTime() == timeValue) {
                return oneSlot;
            }
        }
        return null;
    }

    public MeetingProposeTime findOrCreateProposedTime(String fieldName, long timeValue) throws Exception {
        MeetingProposeTime mpt = findProposedTime(fieldName, timeValue);
        if (mpt == null) {
            mpt = createChild(fieldName, MeetingProposeTime.class);
            mpt.setProposedTime(timeValue);
        }
        return mpt;
    }

    private MeetingProposeTime removeUserFromAllSlots(String fieldName, String userName) throws Exception {
        List<MeetingProposeTime> timeSlot = getChildren(fieldName, MeetingProposeTime.class);
        for (MeetingProposeTime oneSlot : timeSlot) {
            oneSlot.clearPersonValue(userName);
        }
        return null;
    }


    public JSONObject getWillAttend(String userKey) throws Exception {
        AddressListEntry ale = AddressListEntry.findOrCreate(userKey);
        DOMFace foundOne = null;
        for (DOMFace onePerson : getChildren("rollCall", DOMFace.class)){
            if (ale.hasAnyId(onePerson.getAttribute("uid"))) {
                foundOne = onePerson;
            }
        }
        if (foundOne==null) {
            foundOne = createChildWithID("rollCall", DOMFace.class, "uid", ale.getUniversalId());
        }
        JSONObject res = new JSONObject();
        res.put("attend", foundOne.getScalar("attend"));
        res.put("situation", foundOne.getScalar("situation"));
        return res;
    }
    public void setWillAttend(String userKey, JSONObject attendValues) throws Exception {
        AddressListEntry ale = AddressListEntry.findOrCreate(userKey);
        DOMFace foundOne = null;
        for (DOMFace onePerson : getChildren("rollCall", DOMFace.class)){
            if (ale.hasAnyId(onePerson.getAttribute("uid"))) {
                foundOne = onePerson;
            }
        }
        if (foundOne==null) {
            foundOne = createChildWithID("rollCall", DOMFace.class, "uid", ale.getUniversalId());
        }
        if (attendValues.has("attend")) {
            foundOne.setScalar("attend", attendValues.getString("attend"));
        }
        if (attendValues.has("situation")) {
            foundOne.setScalar("situation", attendValues.getString("situation"));
        }
    }


    public boolean removeFromRollCall(String sourceUser) throws Exception {
        AddressListEntry ale = AddressListEntry.findOrCreate(sourceUser);
        DOMFace foundOne = null;
        for (DOMFace onePerson : getChildren("rollCall", DOMFace.class)){
            if (ale.hasAnyId(onePerson.getAttribute("uid"))) {
                foundOne = onePerson;
            }
        }
        if (foundOne != null) {
            removeChild(foundOne);
            return true;
        }
        return false;
    }
    public boolean removeFromAttended(String sourceUser) throws Exception {
        boolean found = false;
        List<Element> children = getNamedChildrenVector("attended");
        for (Element child : children) {
            String childVal = DOMUtils.textValueOf(child, false);
            if (childVal.equalsIgnoreCase(sourceUser)) {
                fEle.removeChild(child);
                found = true;
            }
        }
        return found;
    }
    public int removeFromTimeSlots(String sourceUser) throws Exception {
        int count = 0;
        for (DOMFace slot : getChildren("timeSlots", DOMFace.class)) {
            boolean found = false;
            List<String> people = slot.getVector("people");
            List<String> newList = new ArrayList<String>();
            for (String onePers : people) {
                if (onePers.startsWith(sourceUser)) {
                    found = true;
                }
                else {
                    newList.add(onePers);
                }
            }
            if (found) {
                count++;
                slot.setVector("people", newList);
            }
        }
        return count;
    }

    /**
     * A vary small object suitable for notification event lists
     */
    public JSONObject getMinimalJSON() throws Exception {
        JSONObject meetingInfo = new JSONObject();
        extractAttributeString(meetingInfo, "id");
        extractAttributeString(meetingInfo, "name");
        extractAttributeString(meetingInfo, "targetRole");
        extractAttributeInt   (meetingInfo, "state");
        extractAttributeLong  (meetingInfo, "startTime");
        extractAttributeLong  (meetingInfo, "duration");
        extractAttributeInt   (meetingInfo, "meetingType");
        extractAttributeInt   (meetingInfo, "reminderTime");
        extractAttributeLong  (meetingInfo, "reminderSent");
        extractScalarEmail    (meetingInfo, "owner");
        extractScalarString   (meetingInfo, "previousMeeting");
        extractScalarString   (meetingInfo, "defaultLayout");
        extractScalarString   (meetingInfo, "notifyLayout");
        extractAttributeString(meetingInfo, "minutesId");
        extractAttributeString(meetingInfo, "conferenceUrl");
        return meetingInfo;
    }


    /**
     * A small object suitable for lists of meetings
     */
    public JSONObject getListableJSON(AuthRequest ar) throws Exception {
        JSONObject meetingInfo = getMinimalJSON();
        meetingInfo.put("description", getMeetingDescription());

        //REMOVE THIS sometime soon, no more HTML needed
        //String htmlVal = WikiConverterForWYSIWYG.makeHtmlString(ar, getMeetingDescription());
        //meetingInfo.put("meetingInfo", htmlVal);

        JSONArray rollCall = new JSONArray();
        for (DOMFace onePerson : getChildren("rollCall", DOMFace.class)){
            AddressListEntry ale = AddressListEntry.findOrCreate(onePerson.getAttribute("uid"));
            JSONObject sub = new JSONObject();
            //user id
            sub.put("uid", ale.getUniversalId());
            sub.put("key", ale.getKey());

            // yse, no, maybe
            sub.put("attend", onePerson.getScalar("attend"));

            // a comment about their situation
            sub.put("situation", onePerson.getScalar("situation"));
            rollCall.put(sub);
        }
        meetingInfo.put("rollCall",  rollCall);

        JSONArray attended = new JSONArray();
        for (String attendee : this.getVector("attended")) {
            attended.put(UserManager.getCorrectedEmail(attendee));
        }
        meetingInfo.put("attended", attended);
        meetingInfo.put("agendaUrl", ar.baseURL + ar.getResourceURL(ar.ngp, "MeetPrint.htm?id="+getId()+"&tem="+getScalar("notifyLayout")));
        meetingInfo.put("minutesUrl", ar.baseURL + ar.getResourceURL(ar.ngp, "MeetPrint.htm?id="+getId()+"&tem="+getScalar("defaultLayout")));
        return meetingInfo;
    }

    /**
     * Complete representation as a JSONObject, including subobjects
     * @return
     * @throws Exception
     */
    public JSONObject getFullJSON(AuthRequest ar, NGWorkspace ngw, boolean allcomments) throws Exception {
        verifyTargetRole(ngw);
        JSONObject meetingInfo = getListableJSON(ar);
        JSONArray aiArray = new JSONArray();
        long scheduledTime = this.getStartTime();
        for (AgendaItem ai : getSortedAgendaItems()) {
            JSONObject aiObj = ai.getJSON(ar, ngw, this, allcomments);

            //calculate the scheduled start and end
            aiObj.put("schedStart", scheduledTime);
            scheduledTime = scheduledTime + (aiObj.getLong("duration")*60000);
            aiObj.put("schedEnd", scheduledTime);

            aiArray.put(aiObj);
        }
        meetingInfo.put("agenda", aiArray);
        String mid = getMinutesId();
        if (mid!=null && mid.length()>0) {
            TopicRecord  nr = ngw.getDiscussionTopic(mid);
            if (nr!=null) {
                meetingInfo.put("minutesId",      mid);
                meetingInfo.put("minutesLocalId", nr.getId());
            }
            else {
                //since no corresponding topic exists, clear the setting
                //could be a schema migration thing
                setMinutesId(null);
            }
        }
        JSONArray timeSlotArray = new JSONArray();
        List<MeetingProposeTime> timeSlot = getChildren("timeSlots", MeetingProposeTime.class);
        for (MeetingProposeTime oneSlot : timeSlot) {
            timeSlotArray.put(oneSlot.getJSON());
        }
        meetingInfo.put("timeSlots", timeSlotArray);

        //we need to know the id of the minutes of the previous meeting
        //if they exist.  Look it up every time.
        String previousMeetingId = getScalar("previousMeeting");
        if (previousMeetingId!=null && previousMeetingId.length()>0) {
            MeetingRecord prevMeet = ngw.findMeetingOrNull(previousMeetingId);
            //check that the meeting really exists
            if (prevMeet!=null) {
                String minutesID = prevMeet.getMinutesId();
                if (minutesID!=null && minutesID.length()>0) {
                    //check that the minutes really exist
                    TopicRecord tr = ngw.getDiscussionTopic(minutesID);
                    if (tr!=null) {
                        meetingInfo.put("previousMinutes", minutesID);
                    }
                }

                meetingInfo.put("prevMeet", prevMeet.getListableJSON(ar));
            }
        }
        meetingInfo.put("participants", AddressListEntry.getJSONArrayFromIds(this.getVector("participants")));

        //now work out the people map to consolidate all details of a person in one map
        JSONObject peopleMap = new JSONObject();
        for (String id : this.getVector("participants")) {
            AddressListEntry ale = AddressListEntry.findOrCreate(id);
            peopleMap.requireJSONObject(ale.getKey());
        }
        for (String id : this.getVector("attended")) {
            AddressListEntry ale = AddressListEntry.findOrCreate(id);
            if (peopleMap.has(ale.getKey())) {
                JSONObject personRecord = peopleMap.getJSONObject(ale.getKey());
                personRecord.put("attended", true);
            }
        }
        for (DOMFace onePerson : getChildren("rollCall", DOMFace.class)){
            AddressListEntry ale = AddressListEntry.findOrCreate(onePerson.getAttribute("uid"));
            if (peopleMap.has(ale.getKey())) {
                JSONObject personRecord = peopleMap.getJSONObject(ale.getKey());

                //whether they expect to attend or not
                personRecord.put("expect", onePerson.getScalar("attend"));

                // a comment about their situation
                personRecord.put("situation", onePerson.getScalar("situation"));
            }
        }
        for (String key : peopleMap.keySet()) {
            AddressListEntry ale = AddressListEntry.findOrCreate(key);
            JSONObject personRecord = peopleMap.requireJSONObject(key);
            personRecord.put("uid", ale.getUniversalId());
            personRecord.put("name", ale.getName());
            personRecord.put("key", ale.getKey());
        }
        meetingInfo.put("people", peopleMap);

        //general pieces of information in case not elsewhere
        meetingInfo.put("baseUrl", ar.baseURL);
        meetingInfo.put("workspaceUrl", ar.baseURL + ar.getResourceURL(ngw, ""));

        return meetingInfo;
    }

    public void updateFromJSON(JSONObject input, AuthRequest ar) throws Exception {
        boolean hasSetMeetingInfo = false;

        if (input.has("name")) {
            setName(input.getString("name"));
            hasSetMeetingInfo = true;
        }
        if (input.has("state")) {
            setState(input.getInt("state"));
        }
        if (input.has("reminderSent")) {
            //the only reason the UI might want to clear this to cause the
            //reminder to be sent again
            setReminderSent(input.getLong("reminderSent"));
        }
        if (input.has("startTime")) {
            long newTime = input.getLong("startTime");
            long oldTime = this.getStartTime();
            if (newTime!=oldTime) {
                setStartTime(newTime);
                hasSetMeetingInfo = true;

                //if the meeting time changes, then clear out the reminder sent
                //time to cause it to be sent again (if already sent).
                setReminderSent(0);
            }
        }
        if (input.has("targetRole")) {
            setTargetRole(input.getString("targetRole"));
        }
        if (input.has("duration")) {
            setDuration(input.getLong("duration"));
            hasSetMeetingInfo = true;
        }
        if (input.has("meetingType")) {
            setMeetingType(input.getInt("meetingType"));
            hasSetMeetingInfo = true;
        }
        if (input.has("reminderTime")) {
            setReminderAdvance(input.getInt("reminderTime"));
            hasSetMeetingInfo = true;
        }
        if (input.has("descriptionMerge")) {
            JSONObject mergeObj = input.getJSONObject("descriptionMerge");
            String lastSaveVal = mergeObj.optString("old");
            String newVal = mergeObj.getString("new");
            mergeScalar("meetingInfo", lastSaveVal, newVal);
            hasSetMeetingInfo = true;
        }
        else if (input.has("description")) {
        	//if there is a descriptionMerge, then ignore any complete description,
        	//only  one or the other
            String markdown = input.getString("description");
            setMeetingInfo(markdown);
            hasSetMeetingInfo = true;
        }


        updateScalarString("previousMeeting", input);
        updateScalarString("defaultLayout", input);
        updateScalarString("notifyLayout", input);
        updateAttributeString("conferenceUrl", input);

        if (input.has("owner")) {
            setOwner(input.getString("owner"));
        }

        if (input.has("rollCall")) {
            JSONArray roleCall = input.getJSONArray("rollCall");
            for (int i=0; i<roleCall.length(); i++) {
                JSONObject onePerson = roleCall.getJSONObject(i);
                if (onePerson.has("uid")) {
                    String personId = onePerson.getString("uid");
                    DOMFace found = getChildAttribute(personId, DOMFace.class, "uid");
                    if (found==null) {
                        found = createChildWithID("rollCall", DOMFace.class, "uid", personId);
                    }
                    if (onePerson.has("attend")) {
                        found.setScalar("attend", onePerson.getString("attend"));
                    }
                    if (onePerson.has("situation")) {
                        found.setScalar("situation", onePerson.getString("situation"));
                    }
                }
            }
        }

        if (input.has("attended")) {
            this.setVector("attended", constructVector(input.getJSONArray("attended")));
        }
        if (input.has("attended_add")) {
            this.addUserToVector("attended", input.getString("attended_add"));
        }
        if (input.has("attended_remove")) {
            this.removeUserFromVector("attended", input.getString("attended_remove"));
        }

        if (input.has("participants")) {
            this.setVector("participants", AddressListEntry.uidListfromJSONArray(input.getJSONArray("participants")));
        }

        if (input.has("timeSlots")) {
            this.removeAllNamedChild("timeSlots");
            JSONArray timeSlotArray = input.getJSONArray("timeSlots");
            for(int i=0; i<timeSlotArray.length(); i++) {
                JSONObject oneSlot = timeSlotArray.getJSONObject(i);
                MeetingProposeTime mpt = createChild("timeSlots", MeetingProposeTime.class);
                mpt.updateFromJSON(oneSlot);
            }
        }

        //fix up the owner if needed .. schema migration
        //TODO: remove after Dec 2015
        String owner = getOwner();
        if (hasSetMeetingInfo && (owner==null || owner.length()==0)) {
            //set to the person currently saving the record.
            setOwner(ar.getBestUserId());
        }
        if (input.has("startTimer")) {
            startTimer( input.getString("startTimer"));
        }
        if (input.has("stopTimer")) {
            stopTimer();
        }
    }

    public void removeUserFromVector(String memberName, String value) {
        AddressListEntry ale = AddressListEntry.findOrCreate(value);
        if (memberName == null) {
            throw new RuntimeException("Program logic error: a null member name"
                +" was passed to addVectorValue.");
        }
        List<Element> children = getNamedChildrenVector(memberName);
        for (Element child : children) {
            String childVal = DOMUtils.textValueOf(child, false);
            if (ale.hasAnyId(childVal)) {
                fEle.removeChild(child);
            }
        }
    }
    public void addUserToVector(String memberName, String value) {
        if (memberName == null) {
            throw new RuntimeException("Program logic error: a null member name"
                +" was passed to addVectorValue.");
        }
        AddressListEntry newUser = AddressListEntry.findOrCreate(value);
        List<Element> children = getNamedChildrenVector(memberName);
        for (Element child : children) {
            String childVal = DOMUtils.textValueOf(child, false);
            if (newUser.hasAnyId(childVal)) {
                //value is already there, so ignore this add
                return;
            }
        }
        createChildElement(memberName, newUser.getKey());
    }


    /**
     * This will update the existing agenda items with values from
     * the JSONArray.  This will NOT remove any agenda items.
     * If the id is "~new~" if will create an agenda item.
     * This is most useful to change the order of the items.
     */
    public void updateAgendaFromJSON(JSONObject input, AuthRequest ar, NGWorkspace ngw) throws Exception {
        JSONArray agenda = input.optJSONArray("agenda");
        if (agenda==null) {
            return;
        }
        int last = agenda.length();
        for (int i=0; i<last; i++) {
            JSONObject aiobj = agenda.getJSONObject(i);
            String aid = aiobj.optString("id");
            if (aid==null) {
                continue;
            }
            AgendaItem ai = null;
            if ("~new~".equals(aid)) {
                ai = createAgendaItem(ngw);
            }
            else {
                ai = findAgendaItem(aid);
            }
            if (ai!=null) {
                ai.updateFromJSON(ar,aiobj,ngw);
            }
        }
        renumberItems();  //sort & fix any numbering problems
    }

    /**
     * This takes a meeting JSONObject, the agenda portion
     * and it create new cloned agenda items for each in the array.
     */
    public void createAgendaFromJSON(JSONObject input, AuthRequest ar, NGWorkspace ngw) throws Exception {
        JSONArray agenda = input.optJSONArray("agenda");
        if (agenda==null) {
            //in some cases there is no agenda
            return;
        }
        int last = agenda.length();
        for (int i=0; i<last; i++) {
            JSONObject aiobj = agenda.getJSONObject(i);
            if (aiobj.has("selected") && aiobj.getBoolean("selected")) {
                AgendaItem ai = createAgendaItem(ngw);
                ai.updateFromJSON(ar, aiobj, ngw);
            }
        }
        renumberItems();  //sort & fix any numbering problems
    }

    public String getNameAndDate(Calendar cal) throws Exception {
        return getName() + " @ " + formatDate(getStartTime(), cal, "HH:mm z 'on' dd-MMM-yyyy", "(to be determined)");
    }

    public String generateWikiRep(AuthRequest ar, NGWorkspace ngw) throws Exception {
        StringBuilder sb = new StringBuilder();
        Calendar cal = getOwnerCalendar();

        sb.append("!!!"+getName());

        sb.append("\n\n!!");
        sb.append(formatDate(getStartTime(), cal, "HH:mm z 'on' dd-MMM-yyyy", "(to be determined)"));

        sb.append("\n\n");
        sb.append(getMeetingDescription());

        sb.append("\n\n!!Agenda");

        long itemTime = this.getStartTime();

        for (AgendaItem ai : getSortedAgendaItems()) {
            sb.append("\n\n!");
            sb.append(Integer.toString(ai.getPosition()));
            sb.append(". ");
            sb.append(ai.getSubject());
            sb.append("\n\n");
            sb.append(formatDate(itemTime, cal, "HH:mm", "(tbd)"));
            long minutes = ai.getDuration();
            long finishTime = itemTime + (minutes*60*1000);
            sb.append(" - ");
            sb.append(formatDate(finishTime, cal, "HH:mm", "(tbd)"));
            sb.append(" (");
            sb.append(Long.toString(minutes));
            sb.append(" minutes)");
            itemTime = finishTime;
            boolean isFirst = true;
            for (AddressListEntry ale : ai.getPresenters()) {
                if (isFirst) {
                    sb.append(" Presented by: ");
                }
                else {
                    sb.append(", ");
                }
                isFirst = false;
                sb.append(ale.getName());
            }
        }

        return sb.toString();
    }



    public Calendar getOwnerCalendar() throws Exception {
        UserProfile up = UserManager.lookupUserByAnyId(getOwner());
        if (up!=null) {
            return up.getCalendar();
        }
        return Calendar.getInstance();
    }

    public String generateMinutes(AuthRequest ar, NGWorkspace ngw) throws Exception {
        Calendar cal = getOwnerCalendar();

        StringBuilder sb = new StringBuilder();
        sb.append("!!!Meeting: "+getNameAndDate(cal));

        sb.append("\n\n");

        sb.append(getMeetingDescription());

        sb.append("\n\n");
        sb.append("See original meeting: [");
        sb.append(getNameAndDate(cal));
        sb.append("|");
        sb.append(ar.baseURL);
        sb.append(ar.getResourceURL(ngw, "MeetingHtml.htm?id="+getId()));
        sb.append("]");

        sb.append("\n\n!!!Agenda");

        long itemTime = this.getStartTime();

        for (AgendaItem ai : getSortedAgendaItems()) {
            sb.append("\n\n!");
            if (!ai.isSpacer()) {
                sb.append(Integer.toString(ai.getNumber()));
                sb.append(". ");
            }
            sb.append(ai.getSubject());
            sb.append("\n\n"+formatDate(itemTime, cal, "HH:mm", ""));
            long minutes = ai.getDuration();
            long finishTime = itemTime + (minutes*60*1000);
            sb.append(" - "+formatDate(finishTime, cal, "HH:mm", ""));
            sb.append(" (");
            sb.append(Long.toString(ai.getDuration()));
            sb.append(" minutes)");
            itemTime = itemTime + (ai.getDuration()*60*1000);
            boolean isFirst = true;
            for (AddressListEntry ale : ai.getPresenters()) {
                if (isFirst) {
                    sb.append(" Presented by: ");
                }
                else {
                    sb.append(", ");
                }
                isFirst = false;
                sb.append(ale.getName());
            }

            sb.append("\n\n"+ai.getDesc());

            /*
            String ainotes = ai.getNotes();

            //TODO: I don't think notes are used any more
            if (ainotes!=null && ainotes.length()>0) {
                sb.append("\n\n''Notes:''\n\n");
                sb.append(ainotes);
            }
            */

            for (String actionItemId : ai.getActionItems()) {
                GoalRecord gr = ngw.getGoalOrNull(actionItemId);
                if (gr!=null) {
                    sb.append("\n\n* Action Item: [");
                    sb.append(gr.getSynopsis());
                    sb.append("|");
                    sb.append(ar.baseURL);
                    sb.append(ar.getResourceURL(ngw, "task"+gr.getId()+".htm"));
                    sb.append("]");
                }
            }
            for (String doc : ai.getDocList()) {
                AttachmentRecord aRec = ngw.findAttachmentByUidOrNull(doc);
                if (aRec!=null) {
                    sb.append("\n\n* Attachment: [");
                    sb.append(aRec.getNiceName());
                    sb.append("|");
                    sb.append(ar.baseURL);
                    sb.append(aRec.getEmailURL(ar, ngw));
                    sb.append("]");
                }
            }

            String realMinutes = ai.getScalar("minutes");
            if (realMinutes!=null && realMinutes.length()>0) {
                sb.append("\n\n''Minutes:''\n\n");
                sb.append(realMinutes);
            }

            for (CommentRecord cr : ai.getComments()) {
                int cType = cr.getCommentType();
                if (cType == CommentRecord.COMMENT_TYPE_MINUTES ||
                        cType == CommentRecord.COMMENT_TYPE_SIMPLE||
                        cType == CommentRecord.COMMENT_TYPE_PROPOSAL||
                        cType == CommentRecord.COMMENT_TYPE_REQUEST) {
                    sb.append("\n\n''"+cr.getTypeName()+":''\n\n");
                    sb.append(cr.getContent());
                    if (cType == CommentRecord.COMMENT_TYPE_PROPOSAL||
                            cType == CommentRecord.COMMENT_TYPE_REQUEST) {
                        for (ResponseRecord rr : cr.getResponses()) {
                            AddressListEntry ale = AddressListEntry.findOrCreate(rr.getUserId());
                            sb.append("\n\n");
                            sb.append(ale.getName());
                            if (cType == CommentRecord.COMMENT_TYPE_PROPOSAL) {
                                sb.append(" responded with __");
                                sb.append(rr.getChoice());
                                sb.append("__:");
                            }
                            else {
                                sb.append(" says:");
                            }
                            sb.append("\n\n");
                            sb.append(rr.getContent());
                        }
                    }
                }
            }
        }

        return sb.toString();
    }


    public void sendReminderEmail(AuthRequest ar, NGWorkspace ngw, EmailSender mailFile) throws Exception {
        try {

            //TODO: make a non-persistent version of EmailGenerator -- no real reason to save this
            EmailGenerator emg = ngw.createEmailGenerator();
            emg.setSubject("Reminder for meeting: "+this.getName());

            List<String> partUsers = this.getVector("participants");
            if (partUsers.size()>0) {
                //put the participants into the "also to" field
                emg.setAlsoTo(partUsers);
            }
            else {
                //of no participants, use the role
                List<String> names = new ArrayList<String>();
                String tRole = getTargetRole();
                if (tRole==null || tRole.length()==0) {
                    tRole = "Members";
                }
                names.add(tRole);
                emg.setRoleNames(names);
            }



            emg.setMeetingId(getId());
            String meetingOwner = getOwner();
            if (meetingOwner==null || meetingOwner.length()==0) {
                throw new Exception("The owner of the meeting has not been set.");
            }
            emg.setOwner(meetingOwner);
            emg.constructEmailRecords(ar, ngw, mailFile);
            setReminderSent(ar.nowTime);
        }
        catch (Exception e) {
            throw new Exception("Unable to send reminder email for meeting '"+getName()
                    +"' in workspace '"+ngw.getFullName()+"'",e);
        }
    }


    public static void sortChrono(List<MeetingRecord> meetList) {
        Collections.sort(meetList, new MeetingRecordChronoComparator());
    }


    /*
     * Sorts all of the not-proposed items first, in numerical order,
     * then all the proposed ones, in numerical order.
     *
     * An item should typically start as "proposed" and then be
     * be moved to a not-proposed (accepted) position
     */
    static class AgendaItemPositionComparator implements Comparator<AgendaItem> {

        @Override
        public int compare(AgendaItem arg0, AgendaItem arg1) {
            if (arg0.isProposed()==arg1.isProposed()) {
                return Integer.compare(arg0.getPosition(), arg1.getPosition());
            }
            else if (arg0.isProposed()) {
                return 1;
            }
            else {
                return -1;
            }
        }
    }


    static class MeetingRecordChronoComparator implements Comparator<MeetingRecord> {
        @Override
        public int compare(MeetingRecord arg0, MeetingRecord arg1) {
            try {
                //if the meeting time is NOT set, then consider it sorted in the place
                //of the current time.....
                long st0 = arg0.getStartTime();
                if (st0<=0) {
                    st0 = System.currentTimeMillis();
                }
                long st1 = arg1.getStartTime();
                if (st1<=0) {
                    st1 = System.currentTimeMillis();
                }
                return 0 - Long.valueOf(st0).compareTo(Long.valueOf(st1));
            }
            catch (Exception e) {
                return 0;
            }
        }
    }

    /**
     * Needed for the EmailContext interface x
     */

    public String getEmailURL(AuthRequest ar, NGWorkspace ngw) throws Exception {
        return ar.getResourceURL(ngw,  "MeetingHtml.htm?id="+this.getId())
                + "&" + AccessControl.getAccessMeetParams(ngw, this);
    }

    public String getUnsubURL(AuthRequest ar, NGWorkspace ngw, long commentId) throws Exception {
        //don't know how to go straight into unsub mode, so just go to the meeting
        return ar.getResourceURL(ngw,  "CommentZoom.htm?cid="+commentId);
    }
    public String selfDescription() throws Exception {
        return "(Meeting) "+getName()+" @ " + formatDate(getStartTime(), getOwnerCalendar(), "yyyy-MM-dd HH:mm", "(to be determined)");
    }
    public void markTimestamp(long newTime) throws Exception {
        //the meeting does not care about the timestamp that an comment is emailed.
    }

    public void extendNotifyList(List<AddressListEntry> addressList) throws Exception {
        //there is no subscribers for meetings
    }

    public void gatherUnsentScheduledNotification(NGWorkspace ngw, ArrayList<ScheduledNotification> resList, long timeout) throws Exception {
        MScheduledNotification sn = new MScheduledNotification(ngw, this);
        if (sn.needsSendingBefore(timeout)) {
            resList.add(sn);
        }
        for (AgendaItem ai : this.getSortedAgendaItems()) {
            ai.gatherUnsentScheduledNotification(ngw, new EmailContext(this,ai), resList, timeout);
        }
    }

/**
 * This is a pain getting this right.  The meeting might be scheduled in the future
 * or in the past.  (the latter is not likely but possible).
 *
 * You can set different settings for how much before the meeting to send the
 * announcement.  Even if the meeting is in the future, the announcement time
 * can be in the future or in the past.
 *
 * Regardless of the announcement time, the announcement email might have already
 * been sent.
 *
 * The meeting time might have been changed, and in that case a new announcement
 * should be sent, regardless of whether sent previously or not.
 *
 * Meeting might be in draft mode, and so don't send any announcement until
 * it changes to Plan mode.
 * ONLY send if it Plan more.  Don't send in running or completed.
 *
 * Here are the facts we have to work with:  meeting time, reminder minutes, state,
 * and actual send time.
 *
 * The meeting time and reminder minutes combine to form reminderPlanTime.
 * There is a reminderSent which is the actual time sent.
 *
 * When the meeting time changes, you should send the notification again, regardless
 * of whether sent or not, regardless of whether this is in the future or the past.
 * When the meeting time changes, clear the sent flag, and clear the sent time.
 *
 * Then, every polling cycle, check whether it is time to send or not, depending
 * on expected send time and state.  If planning and expected time is in past, and
 * have not already been sent, then send it.
 *
 * When email sent, set the reminderSent time, so that it is sent only once.
 * The only thing that clears reminder sent is changing the meeting time.
 *
 */
    private class MScheduledNotification implements ScheduledNotification {
        NGWorkspace ngw;
        MeetingRecord meet;

        public MScheduledNotification( NGWorkspace _ngp, MeetingRecord _meet) {
            ngw  = _ngp;
            meet = _meet;
        }
        @Override
        public boolean needsSendingBefore(long timeout) throws Exception {
            //only send email while in planning state
            if (meet.getState() != MeetingRecord.MEETING_STATE_PLANNING) {
                return false;
            }

            long reminderTime = futureTimeToSend();
            if (reminderTime>timeout) {
                //not yet time to send the reminder
                return false;
            }

            //so it is time to send, check if it has
            long reminderSent = meet.getReminderSent();

            //If reminder was sent after the reminder time, then all OK
            if (reminderSent >= reminderTime) {
                return false;
            }

            //If the reminder was never sent, or
            //reminder was sent BEFORE the time to send,
            //then it still needs to be sent again, because meeting rescheduled
            return true;
        }

        @Override
        public long futureTimeToSend() throws Exception {
            if (meet.getState() != MeetingRecord.MEETING_STATE_PLANNING) {
                return -1;
            }

            int delta = meet.getReminderAdvance();
            if (delta<=0) {
                return -1;
            }
            long meetStart = meet.getStartTime();
            long reminderTime =  meetStart - (delta * 60000);

            //so it is time to send, check if it has
            long reminderSent = meet.getReminderSent();

            //If reminder was sent after the reminder time, then all OK
            if (reminderSent >= reminderTime) {
                return -1;
            }

            return reminderTime;
        }

        @Override
        public void sendIt(AuthRequest ar, EmailSender mailFile) throws Exception {
            if (meet.getState() != MeetingRecord.MEETING_STATE_PLANNING) {
                throw new Exception("Attempting to send email reminder when not in planning state.  State="+meet.getState());
            }

            if (!needsSendingBefore(ar.nowTime)) {
                throw new Exception("MEETING NOTIFICATION BUG:  Request to send when TimeToSend ("
                     +SectionUtil.getNicePrintDate(futureTimeToSend())+") is still in the future!");
            }

            System.out.println("SENDING MEETING NOTICE: "+SectionUtil.currentTimestampString()+" with SENDTIME: "
                    +SectionUtil.getNicePrintDate(futureTimeToSend())+" and MEETTIME: "
                    +SectionUtil.getNicePrintDate(meet.getStartTime()));
            meet.sendReminderEmail(ar, ngw, mailFile);
             //test to see that all the logic is right
            if (needsSendingBefore(ar.nowTime)) {
                System.out.println("STRANGE: the meeting was just sent, but it does not think so. SENDTIME: "
                        +SectionUtil.getNicePrintDate(futureTimeToSend())+" and MEETTIME: "
                        +SectionUtil.getNicePrintDate(meet.getStartTime()));
            }
        }

        @Override
        public String selfDescription() throws Exception {
            return meet.selfDescription();
        }

    }



    public JSONObject getMeetingNotes() throws Exception {
        JSONObject jo = new JSONObject();
        JSONArray ja = new JSONArray();
        for (AgendaItem ai : getSortedAgendaItems()) {
            JSONObject oneAi = new JSONObject();
            oneAi.put("id",    ai.getId());
            oneAi.put("new",   ai.getMeetingNotes());
            oneAi.put("title", ai.getSubject());
            oneAi.put("pos",   ai.getPosition());
            ai.extractAttributeBool(oneAi, "timerRunning");
            ai.extractAttributeLong(oneAi, "timerStart");
            ai.extractAttributeLong(oneAi, "timerElapsed");
            ai.extractAttributeLong(oneAi, "duration");
            ja.put(oneAi);
        }
        jo.put("minutes", ja);
        return jo;
    }

    public void updateMeetingNotes(JSONObject input) throws Exception {
        JSONArray ja = input.getJSONArray("minutes");
        for (int i=0; i<ja.length(); i++) {
            JSONObject oneAi = ja.getJSONObject(i);
            String id = oneAi.getString("id");
            String oldMins = oneAi.optString("old", "");
            String newMins = oneAi.getString("new");
            AgendaItem ai = this.findAgendaItem(id);
            ai.mergeMinutes(oldMins, newMins);
        }
    }



    public static String formatDate(long dateTime, Calendar cal, String format, String nullValue) {
        if (dateTime<=0) {
            return (nullValue);
        }
        SimpleDateFormat sdfFull = new SimpleDateFormat(format);
        sdfFull.setCalendar(cal);

        return sdfFull.format(new Date(dateTime));
    }

    public void streamICSFile(AuthRequest ar, Writer w, NGWorkspace ngw) throws Exception {
        AddressListEntry ale = AddressListEntry.findOrCreate(getOwner());
        w.write("BEGIN:VCALENDAR\n");
        w.write("VERSION:2.0\n");
        w.write("PRODID:-//example/Weaver//NONSGML v1.0//EN\n");
        w.write("BEGIN:VEVENT\n");
        w.write("UID:"+ngw.getSiteKey()+ngw.getKey()+getId()+"\n");
        w.write("DTSTAMP:"+getSpecialICSFormat(System.currentTimeMillis())+"\n");
        w.write("ORGANIZER:CN="+ale.getName()+":MAILTO:"+ale.getEmail()+"\n");
        w.write("DTSTART:"+getSpecialICSFormat(getStartTime())+"\n");
        w.write("DTEND:"+getSpecialICSFormat(getStartTime()+(getDuration()*60*1000))+"\n");
        w.write("SUMMARY:"+getName()+"\n");
        String descriptionHtml = "This appointment is for a Meeting organized in Weaver.\n"
                +"Find more information about the meeting in the following links.\n"
                +"Meeting: "+ar.baseURL+getEmailURL(ar, ngw)
                +"\nWorkspace: "+ar.baseURL+ar.getResourceURL(ngw, "FrontPage.htm");
        w.write("DESCRIPTION:"+specialEncode(descriptionHtml)+"\n");
        w.write("END:VEVENT\n");
        w.write("END:VCALENDAR\n");
        w.flush();
    }
    private String getSpecialICSFormat(long date) {
        SimpleDateFormat formatter = new SimpleDateFormat("yyyyMMdd'T'HHmmss'Z'");
        formatter.setTimeZone(TimeZone.getTimeZone("UTC"));
        return formatter.format(new Date(date));
    }
    private String specialEncode(String input) {
        StringBuilder sb = new StringBuilder();
        for (int i=0; i<input.length(); i++) {
            char ch = input.charAt(i);
            if (ch=='\n') {
                sb.append("\\n");
            }
            else if (ch<' ') {
                //do nothing
            }
            else {
                sb.append(ch);
            }
        }
        return sb.toString();
    }

    public static List<File> getAllLayouts(AuthRequest ar, NGWorkspace ngw) {
        File parentPath = ngw.getContainingFolder();
        File siteFolder = parentPath.getParentFile();
        File siteCogFolder = new File(siteFolder, ".cog");
        File siteMeetsFolder = new File(siteCogFolder, "meets");

        File templateFolder = ar.getCogInstance().getConfig().getFileFromRoot("meets");
        ArrayList<File> allTemplates = new ArrayList<File>();
        Hashtable<String, File> used = new Hashtable<String, File>();

        File[] children = siteMeetsFolder.listFiles();
        if (children!=null) {
            for (File tempName: children) {
                allTemplates.add(tempName);
                used.put(tempName.getName(), tempName);
            }
        }
        children = templateFolder.listFiles();
        if (children!=null) {
            for (File tempName: children) {
                if (!used.contains(tempName.getName())) {
                    allTemplates.add(tempName);
                    used.put(tempName.getName(), tempName);
                }
            }
        }
        return allTemplates;
    }

    public static File findMeetingLayout(AuthRequest ar, NGWorkspace ngw, String layoutName) throws Exception {
        File meetingLayoutFile = ar.findChunkTemplate(layoutName);
        return meetingLayoutFile;
    }

    /**
     * This produces a list of meeting attendees, but ONLY those who are members
     * of the site in the list of site users.   Ad-hoc users added to a meeting
     * are ignored.
     */
    public static JSONObject findAttendeeMatrix(NGWorkspace ngw) throws Exception {
        NGBook site = ngw.getSite();
        List<AddressListEntry> siteUsers = site.getSiteUsersList();
        JSONObject jo = new JSONObject();
        for (MeetingRecord meet : ngw.getMeetings()) {
            for (String attendee : meet.getAttendees()) {
                AddressListEntry foundUser = null;
                for (AddressListEntry ale: siteUsers) {
                    if (ale.hasAnyId(attendee)) {
                        foundUser = ale;
                    }
                }
                if (foundUser != null) {
                    JSONObject attendeeRecord = jo.requireJSONObject(foundUser.getKey());
                    attendeeRecord.put(meet.getId(), true);
                }
            }
        }
        return jo;
    }
}
