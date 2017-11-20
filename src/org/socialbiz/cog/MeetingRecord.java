package org.socialbiz.cog;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.List;

import org.socialbiz.cog.mail.MailFile;
import org.socialbiz.cog.mail.ScheduledNotification;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;

public class MeetingRecord extends DOMFace implements EmailContext {

    public static final int MEETING_TYPE_CIRCLE = 1;
    public static final int MEETING_TYPE_OPERATIONAL = 2;

    public static final int MEETING_STATE_DRAFT = 0;
    public static final int MEETING_STATE_PLANNING = 1;
    public static final int MEETING_STATE_RUNNING = 2;
    public static final int MEETING_STATE_COMPLETED = 3;



    public MeetingRecord(Document doc, Element ele, DOMFace p) throws Exception {
        super(doc, ele, p);

        //new "number" field added, and this initializes it
        renumberItems();
    }



    public String getId()  throws Exception {
        return getAttribute("id");
    }

    public String getName()  throws Exception {
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

    public int getState()  throws Exception {
        return getAttributeInt("state");
    }
    public void setState(int newVal) throws Exception {
        setAttributeInt("state", newVal);
    }

    public long getStartTime()  throws Exception {
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

    private long getMeetingType() {
        return getAttributeInt("meetingType");
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
    public void appendTargetEmails(List<OptOutAddr> sendTo, NGWorkspace ngw) throws Exception {
        String targetRole = getTargetRole();
        if (targetRole==null || targetRole.length()==0) {
            targetRole = "Members";
        }
        OptOutAddr.appendUnmutedUsersFromRole(ngw, targetRole, sendTo);
    }

    public List<AgendaItem> getAgendaItems() throws Exception {
        return getChildren("agenda", AgendaItem.class);
    }
    public List<AgendaItem> getSortedAgendaItems() throws Exception {
        List<AgendaItem> tempList =  getChildren("agenda", AgendaItem.class);
        Collections.sort(tempList, new AgendaItemPositionComparator());
        return tempList;
    }
    public AgendaItem findAgendaItem(String id) throws Exception {
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
    public AgendaItem createAgendaItem(NGPage ngp) throws Exception {
        AgendaItem ai = createChildWithID("agenda", AgendaItem.class, "id", ngp.getUniqueOnPage());
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
     * There is one special meeting which is actually the container for backlog
     * agenda items.  This special meeting should never be shown as a meeting
     * but instead only to hold the agenda items.  The name and description
     * does not matter.  If this special meeting does not exist, it should be
     * created whenever needed.
     */
    public boolean isBacklogContainer() {
        return "true".equals(getAttribute("isBacklog"));
    }

    public void setBacklogContainer(boolean isBack) {
        if (isBack) {
            setAttribute("isBacklog", "true");
        }
        else {
            setAttribute("isBacklog", null);
        }
    }

    /**
     * Gives all the agenda items sequential increasing numbers
     */
    public void renumberItems() throws Exception {
        List<AgendaItem> tempList = getAgendaItems();
        Collections.sort(tempList, new AgendaItemPositionComparator());
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
        for (AgendaItem ai : this.getAgendaItems()) {
            for (String docId : ai.getDocList()) {
                if (docUniversalId.equals(docId)) {
                    allItems.add(ai);
                }
            }
        }
        return allItems;
    }


    public void startTimer(String itemId) throws Exception {
        if (getState()!=2) {
            throw new Exception("Can only time an agenda item when the meeting is in run state, and it is in state="+getState());
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
        extractScalarString   (meetingInfo, "owner");
        extractScalarString   (meetingInfo, "previousMeeting");
        extractAttributeString(meetingInfo, "minutesId");
        return meetingInfo;
    }


    /**
     * A small object suitable for lists of meetings
     */
    public JSONObject getListableJSON(AuthRequest ar) throws Exception {
        JSONObject meetingInfo = getMinimalJSON();
        String htmlVal = WikiConverterForWYSIWYG.makeHtmlString(ar, getMeetingDescription());
        meetingInfo.put("meetingInfo", htmlVal);

        JSONArray rollCall = new JSONArray();
        for (DOMFace onePerson : getChildren("rollCall", DOMFace.class)){
            JSONObject sub = new JSONObject();
            //user id
            sub.put("uid", onePerson.getAttribute("uid"));

            // yse, no, maybe
            sub.put("attend", onePerson.getScalar("attend"));

            // a comment about their situation
            sub.put("situation", onePerson.getScalar("situation"));
            rollCall.put(sub);
        }
        meetingInfo.put("rollCall",  rollCall);

        meetingInfo.put("attended", constructJSONArray(this.getVector("attended")));
        return meetingInfo;
    }

    /**
     * Complete representation as a JSONObject, including subobjects
     * @return
     * @throws Exception
     */
    public JSONObject getFullJSON(AuthRequest ar, NGWorkspace ngw) throws Exception {
        JSONObject meetingInfo = getListableJSON(ar);
        JSONArray aiArray = new JSONArray();
        for (AgendaItem ai : getAgendaItems()) {
            aiArray.put(ai.getJSON(ar, ngw, this));
        }
        meetingInfo.put("agenda", aiArray);
        String mid = getMinutesId();
        if (mid!=null && mid.length()>0) {
            TopicRecord  nr = ngw.getNoteByUidOrNull(mid);
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
                    TopicRecord tr = ngw.getNote(minutesID);
                    if (tr!=null) {
                        meetingInfo.put("previousMinutes", minutesID);
                    }
                }
            }
        }
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
        if (input.has("meetingInfo")) {
            String html = input.getString("meetingInfo");
            setMeetingInfo(HtmlToWikiConverter.htmlToWiki(ar.baseURL, html));
            hasSetMeetingInfo = true;
        }
        updateScalarString("previousMeeting", input);
        if (input.has("owner")) {
            setOwner(input.getString("owner"));
        }

        if (input.has("rollCall")) {
            JSONArray roleCall = input.getJSONArray("rollCall");
            for (int i=0; i<roleCall.length(); i++) {
                JSONObject onePerson = roleCall.getJSONObject(i);
                String personId = onePerson.getString("uid");
                DOMFace found = getChildAttribute(personId, DOMFace.class, "uid");
                if (found==null) {
                    found = createChildWithID("rollCall", DOMFace.class, "uid", personId);
                }
                found.setScalar("attend", onePerson.getString("attend"));
                found.setScalar("situation", onePerson.getString("situation"));
            }
        }

        if (input.has("attended")) {
            this.setVector("attended", constructVector(input.getJSONArray("attended")));
        }
        if (input.has("attended_add")) {
            this.addUniqueValue("attended", input.getString("attended_add"));
        }
        if (input.has("attended_remove")) {
            this.removeVectorValue("attended", input.getString("attended_remove"));
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
        SimpleDateFormat sdf = new SimpleDateFormat("HH:mm z 'on' dd-MMM-yyyy");
        sdf.setCalendar(cal);
        return getName() + " @ " + sdf.format(new Date(getStartTime()));
    }

    public String generateWikiRep(AuthRequest ar, NGPage ngp) throws Exception {
        StringBuilder sb = new StringBuilder();
        Calendar cal = getOwnerCalendar();

        SimpleDateFormat sdfFull = new SimpleDateFormat("HH:mm z 'on' dd-MMM-yyyy");
        SimpleDateFormat sdfTime = new SimpleDateFormat("HH:mm");
        sdfFull.setCalendar(cal);
        sdfTime.setCalendar(cal);
        
        sb.append("!!!"+getName());

        sb.append("\n\n!!");
        sb.append(sdfFull.format(new Date(getStartTime())));

        sb.append("\n\n");
        sb.append(getMeetingDescription());

        sb.append("\n\n!!Agenda");

        long itemTime = this.getStartTime();

        for (AgendaItem ai : getSortedAgendaItems()) {
            sb.append("\n\n!");
            sb.append(Integer.toString(ai.getPosition()));
            sb.append(". ");
            sb.append(ai.getSubject());
            sb.append("\n\n"+sdfTime.format(new Date(itemTime)));
            long minutes = ai.getDuration();
            long finishTime = itemTime + (minutes*60*1000);
            sb.append(" - "+sdfTime.format(new Date(finishTime)));
            sb.append(" (");
            sb.append(Long.toString(minutes));
            sb.append(" minutes)");
            itemTime = finishTime;
            boolean isFirst = true;
            for (String presenter : ai.getPresenters()) {
                AddressListEntry ale = new AddressListEntry(presenter);
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


    public void generateReminderHtml(AuthRequest ar, NGPage ngp, AddressListEntry ale) throws Exception {

        //notice section
        List<GoalRecord> overDue = new ArrayList<GoalRecord>();
        List<GoalRecord> almostDue = new ArrayList<GoalRecord>();
        List<AgendaItem> presentingList = new ArrayList<AgendaItem>();
        for (AgendaItem ai : this.getAgendaItems()) {
            for (String presenter : ai.getPresenters()) {
                if (ale.hasAnyId(presenter)) {
                    presentingList.add(ai);
                }
            }

            for (String actionId : ai.getActionItems()) {
                GoalRecord goal = ngp.getGoalOrNull(actionId);
                if (goal!=null) {
                    if (goal.isAssignee(ale)) {
                        if (BaseRecord.isFinal(goal.getState())) {
                            continue;
                        }

                        if (goal.getDueDate()<ar.nowTime){
                            overDue.add(goal);
                        }
                        else if (goal.getDueDate()< (ar.nowTime + (7*24*60*60*1000))) {
                            almostDue.add(goal);
                        }
                    }
                }
            }
        }

        String workspaceAddress = ar.baseURL + ar.getResourceURL(ngp, "");
        if (overDue.size()>0 || almostDue.size()>0 || presentingList.size()>0 ) {

            ar.write("\n<div style=\"border:5px solid red;padding:10px;\">");
            ar.write("Notice about this meeting:");
            ar.write("\n<ul>");
            for (GoalRecord goal : overDue) {
                ar.write("\n<li><b>Overdue</b> action item: <a href=\"" + workspaceAddress + "task"+goal.getId()+".htm\">");
                ar.writeHtml(goal.getSynopsis());
                ar.write("</a></li>");
            }
            for (AgendaItem agit : presentingList) {
                ar.write("\n<li>You are presenting agenda item: <b>");
                ar.writeHtml(agit.getSubject());
                ar.write("</b></li>");
            }
            for (GoalRecord goal : almostDue) {
                ar.write("\n<li>Due soon: <a href=\"" + workspaceAddress + "task"+goal.getId()+".htm\">");
                ar.writeHtml(goal.getSynopsis());
                ar.write("</a></li>");
            }
            ar.write("\n</ul>");
            ar.write("</div>");
        }


        ar.write("\n<h1>");
        ar.writeHtml(getName());
        ar.write("</h1>");

        Calendar cal = getOwnerCalendar();
        SimpleDateFormat sdfFull = new SimpleDateFormat("HH:mm z 'on' dd-MMM-yyyy");
        SimpleDateFormat sdfTime = new SimpleDateFormat("HH:mm");
        sdfFull.setCalendar(cal);
        sdfTime.setCalendar(cal);

        String dateRep = sdfFull.format(new Date(getStartTime()));
        ar.write("\n<h2>");
        ar.writeHtml(dateRep);
        ar.write("</h2>");

        ar.write("\n<div class=\"leafContent\" >");
        WikiConverter.writeWikiAsHtml(ar, getMeetingDescription());
        ar.write("</div>");


        ar.write("\n<h2>Agenda</h2>");

        long itemTime = this.getStartTime();

        for (AgendaItem ai : getSortedAgendaItems()) {
            long minutes = ai.getDuration();
            if (ai.isSpacer()) {
                ar.write("<p>");
                ar.writeHtml(ai.getSubject());
                ar.write(" - ");
                ar.write(sdfTime.format(new Date(itemTime)));
                itemTime = itemTime + (minutes*60*1000);
                cal.setTimeInMillis(itemTime);
                ar.write(" - ");
                ar.write(sdfTime.format(new Date(itemTime)));
                ar.write(" ("+minutes+" minutes) </p>");
            }
            else {
                ar.write("\n<h3>");
                ar.write(Integer.toString(ai.getNumber()));
                ar.write(". ");
                ar.writeHtml(ai.getSubject());
                ar.write("</h3>");

                ar.write("\n<p>");
                ar.write(sdfTime.format(new Date(itemTime)));
                itemTime = itemTime + (minutes*60*1000);
                ar.write(" - ");
                ar.write(sdfTime.format(new Date(itemTime)));
                ar.write(" ("+minutes+" minutes)");
                boolean isFirst = true;
                for (String presenter : ai.getPresenters()) {
                    AddressListEntry pale = new AddressListEntry(presenter);
                    if (isFirst) {
                        ar.write(" Presented by: ");
                    }
                    else {
                        ar.write(", ");
                    }
                    isFirst = false;
                    pale.writeLink(ar);
                }
            }
        }
    }


    public Calendar getOwnerCalendar() throws Exception {
        UserProfile up = UserManager.findUserByAnyId(getOwner());
        if (up!=null) {
            return up.getCalendar();
        }
        return Calendar.getInstance();
    }
    
    public String generateMinutes(AuthRequest ar, NGPage ngp) throws Exception {
        Calendar cal = getOwnerCalendar();
        SimpleDateFormat sdfTime = new SimpleDateFormat("HH:mm");
        sdfTime.setCalendar(cal);

        StringBuilder sb = new StringBuilder();
        sb.append("!!!Meeting: "+getNameAndDate(cal));

        sb.append("\n\n");

        sb.append(getMeetingDescription());

        sb.append("\n\n");
        sb.append("See original meeting: [");
        sb.append(getNameAndDate(cal));
        sb.append("|");
        sb.append(ar.baseURL);
        sb.append(ar.getResourceURL(ngp, "meetingFull.htm?id="+getId()));
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
            sb.append("\n\n"+sdfTime.format(new Date(itemTime)));
            long minutes = ai.getDuration();
            long finishTime = itemTime + (minutes*60*1000);
            sb.append(" - "+sdfTime.format(new Date(finishTime)));
            sb.append(" (");
            sb.append(Long.toString(ai.getDuration()));
            sb.append(" minutes)");
            itemTime = itemTime + (ai.getDuration()*60*1000);
            boolean isFirst = true;
            for (String presenter : ai.getPresenters()) {
                AddressListEntry ale = new AddressListEntry(presenter);
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

            String ainotes = ai.getNotes();

            //TODO: I don't think notes are used any more
            if (ainotes!=null && ainotes.length()>0) {
                sb.append("\n\n''Notes:''\n\n");
                sb.append(ainotes);
            }

            TopicRecord linkedTopic = ngp.getNoteByUidOrNull(ai.getTopicLink());
            if (linkedTopic==null) {
                for (String actionItemId : ai.getActionItems()) {
                    GoalRecord gr = ngp.getGoalOrNull(actionItemId);
                    if (gr!=null) {
                        sb.append("\n\n* Action Item: [");
                        sb.append(gr.getSynopsis());
                        sb.append("|");
                        sb.append(ar.baseURL);
                        sb.append(ar.getResourceURL(ngp, "task"+gr.getId()+".htm"));
                        sb.append("]");
                    }
                }
                for (String doc : ai.getDocList()) {
                    AttachmentRecord aRec = ngp.findAttachmentByUidOrNull(doc);
                    if (aRec!=null) {
                        sb.append("\n\n* Attachment: [");
                        sb.append(aRec.getNiceName());
                        sb.append("|");
                        sb.append(ar.baseURL);
                        sb.append(ar.getResourceURL(ngp, "docinfo"+aRec.getId()+".htm"));
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
                                AddressListEntry ale = new AddressListEntry(rr.getUserId());
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
            else {

                for (String actionItemId : linkedTopic.getActionList()) {
                    GoalRecord gr = ngp.getGoalOrNull(actionItemId);
                    if (gr!=null) {
                        sb.append("\n\n* Action Item: [");
                        sb.append(gr.getSynopsis());
                        sb.append("|");
                        sb.append(ar.baseURL);
                        sb.append(ar.getResourceURL(ngp, "task"+gr.getId()+".htm"));
                        sb.append("]");
                    }
                }
                for (String doc : linkedTopic.getDocList()) {
                    AttachmentRecord aRec = ngp.findAttachmentByUidOrNull(doc);
                    if (aRec!=null) {
                        sb.append("\n\n* Attachment: [");
                        sb.append(aRec.getNiceName());
                        sb.append("|");
                        sb.append(ar.baseURL);
                        sb.append(ar.getResourceURL(ngp, "docinfo"+aRec.getId()+".htm"));
                        sb.append("]");
                    }
                }
                long includeCommentRangeStart = getStartTime() - 3*24*60*60*1000;
                long includeCommentRangeEnd = getStartTime() + 3*24*60*60*1000;
                
                for (CommentRecord cr : linkedTopic.getCommentTimeFrame(includeCommentRangeStart, includeCommentRangeEnd)) {
                    if (cr.getCommentType() == CommentRecord.COMMENT_TYPE_MINUTES) {
                        sb.append("\n\n''Minutes:''\n\n");
                        sb.append(cr.getContent());
                    }
                }
            }
        }

        return sb.toString();
    }


    public void sendReminderEmail(AuthRequest ar, NGWorkspace ngw, MailFile mailFile) throws Exception {
        try {

            //TODO: make a non-persistent version of EmailGenerator -- no real reason to save this
            EmailGenerator emg = ngw.createEmailGenerator();
            emg.setSubject("Reminder for meeting: "+this.getName());
            List<String> names = new ArrayList<String>();
            String tRole = getTargetRole();
            if (tRole==null || tRole.length()==0) {
                tRole = "Members";
            }
            names.add(tRole);
            emg.setRoleNames(names);
            emg.setMeetingId(getId());
            String meetingOwner = getOwner();
            if (meetingOwner==null || meetingOwner.length()==0) {
                throw new Exception("The owner of the meeting has not been set.");
            }
            emg.setOwner(meetingOwner);
            emg.setFrom(meetingOwner);
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


    static class AgendaItemPositionComparator implements Comparator<AgendaItem> {

        @Override
        public int compare(AgendaItem arg0, AgendaItem arg1) {
            //this syntax allowed in JAva 7 and later
            //return Integer.compare(arg0.getPosition(), arg1.getPosition());

            //this for before Java 7
            return Integer.valueOf(arg0.getPosition()).compareTo(Integer.valueOf(arg1.getPosition()));
        }

    }


    static class MeetingRecordChronoComparator implements Comparator<MeetingRecord> {
        @Override
        public int compare(MeetingRecord arg0, MeetingRecord arg1) {
            try {
                //this syntax allowed in JAva 7 and later
                //return 0 - Integer.compare(arg0.getPosition(), arg1.getPosition());

                //this for before Java 7
                return 0 - Long.valueOf(arg0.getStartTime()).compareTo(Long.valueOf(arg1.getStartTime()));
            }
            catch (Exception e) {
                return 0;
            }
        }
    }

    /**
     * Needed for the EmailContext interface x
     */
    public String emailSubject() throws Exception {
        return getName();
    }
    public String getEmailURL(AuthRequest ar, NGPage ngp) throws Exception {
        return ar.getResourceURL(ngp,  "meetingFull.htm?id="+this.getId()) 
                + "&" + AccessControl.getAccessMeetParams(ngp, this);
    }
    public String selfDescription() throws Exception {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm");
        return "(Meeting) "+getName()+" @ " + sdf.format(new Date(getStartTime()));
    }
    public void markTimestamp(long newTime) throws Exception {
        //the meeting does not care about the timestamp that an comment is emailed.
    }
    @Override
    public void extendNotifyList(List<AddressListEntry> addressList) throws Exception {
        //there is no subscribers for meetings
    }

    public void gatherUnsentScheduledNotification(NGWorkspace ngp, ArrayList<ScheduledNotification> resList) throws Exception {
        MScheduledNotification sn = new MScheduledNotification(ngp, this);
        if (sn.needsSending()) {

            //DEBUG -- what are meeting notifications being sent multiple times!
            if (sn.timeToSend()<System.currentTimeMillis()) {
                System.out.println("TimeToSend:  "+new Date(sn.timeToSend())+",  ACTUALLY SENT: "+new Date(getReminderAdvance())+" for MEETING: "+getName());
            }

            resList.add(sn);
        }
        for (AgendaItem ai : this.getAgendaItems()) {
            ai.gatherUnsentScheduledNotification(ngp, this, resList);
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
        public boolean needsSending() throws Exception {
            //only send email while in planning state
            if (meet.getState() != MeetingRecord.MEETING_STATE_PLANNING) {
                return false;
            }
            
            long reminderTime = timeToSend();
            long reminderSent = meet.getReminderSent();
            //the reminder has not been sent AFTER the time to send,
            //then it still needs to be sent.
            return (reminderTime>0 && reminderSent < reminderTime);
        }

        public long timeToSend() throws Exception {
            if (meet.getState() != MeetingRecord.MEETING_STATE_PLANNING) {
                return -1;
            }
            int delta = meet.getReminderAdvance();
            if (delta<=0) {
                return -1;
            }
            long meetStart = meet.getStartTime();
            return meetStart - (delta * 60000);
        }

        public void sendIt(AuthRequest ar, MailFile mailFile) throws Exception {
            if (meet.getState() != MeetingRecord.MEETING_STATE_PLANNING) {
                throw new Exception("Attempting to send email reminder when not in planning state.  State="+meet.getState());
            }

            if (timeToSend() > ar.nowTime) {
                throw new Exception("MEETING NOTIFICATION BUG:  Request to send when TimeToSend ("
                     +new Date(timeToSend())+") is still in the future!");
            }

            System.out.println("SENDING MEETING NOTICE: "+new Date()+" with SENDTIME: "+new Date(timeToSend())+" and MEETTIME: "+new Date(meet.getStartTime()));
            meet.sendReminderEmail(ar, ngw, mailFile);
             //test to see that all the logic is right
            if (needsSending()) {
                System.out.println("STRANGE: the meeting was just sent, but it does not think so. SENDTIME: "+new Date(timeToSend())+" and MEETTIME: "+new Date(meet.getStartTime()));
            }
        }

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
            String oldMins = oneAi.getString("old");
            String newMins = oneAi.getString("new");
            AgendaItem ai = this.findAgendaItem(id);
            ai.mergeMinutes(oldMins, newMins);
        }
    }
}
