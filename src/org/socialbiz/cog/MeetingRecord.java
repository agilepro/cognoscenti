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


    public MeetingRecord(Document doc, Element ele, DOMFace p) {
        super(doc, ele, p);
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

    public String getMeetingInfo()  throws Exception {
        return getScalar("meetingInfo");
    }
    public void setMeetingInfo(String newVal) throws Exception {
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
    public void setStartTime(long newVal) throws Exception {
        setAttributeLong("startTime", newVal);
    }

    public long getDuration()  throws Exception {
        return getAttributeLong("duration");
    }
    public void setDuration(long newVal) throws Exception {
        setAttributeLong("duration", newVal);
    }

    public long getMeetingType() {
        return getAttributeInt("meetingType");
    }
    public void setMeetingType(int newVal) {
        setAttributeInt("meetingType", newVal);
    }


    public String getTargetRole()  throws Exception {
        return getAttribute("targetRole");
    }
    public void setTargetRole(String newVal) throws Exception {
        setAttribute("targetRole", newVal);
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
    public void setReminderAdvance(int newVal) throws Exception {
        setAttributeInt("reminderTime", newVal);
    }

    /**
     * This is the actual time that the reminder was actually sent.
     */
    public long getReminderSent()  throws Exception {
        return getAttributeLong("reminderSent");
    }
    public void setReminderSent(long newVal) throws Exception {
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
        for (AgendaItem ai : tempList) {
            ai.setPosition( (++pos) );
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


    /**
     * A small object suitable for lists of meetings
     */
    public JSONObject getListableJSON(AuthRequest ar) throws Exception {
        JSONObject meetingInfo = new JSONObject();
        meetingInfo.put("id",          getId());
        meetingInfo.put("name",        getName());
        meetingInfo.put("targetRole",  getTargetRole());
        meetingInfo.put("state",       getState());
        meetingInfo.put("startTime",   getStartTime());
        meetingInfo.put("duration",    getDuration());
        meetingInfo.put("meetingType", getMeetingType());
        String htmlVal = WikiConverterForWYSIWYG.makeHtmlString(ar, getMeetingInfo());
        meetingInfo.put("meetingInfo", htmlVal);
        meetingInfo.put("reminderTime",getReminderAdvance());
        meetingInfo.put("reminderSent",getReminderSent());
        meetingInfo.put("owner",       getOwner());
        
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
            NoteRecord  nr = ngw.getNoteByUidOrNull(mid);
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
        if (input.has("startTime")) {
            setStartTime(input.getLong("startTime"));
            hasSetMeetingInfo = true;
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
        if (input.has("reminderSent")) {
            setReminderSent(input.getLong("reminderSent"));
        }
        if (input.has("meetingInfo")) {
            String html = input.getString("meetingInfo");
            setMeetingInfo(HtmlToWikiConverter.htmlToWiki(ar.baseURL, html));
            hasSetMeetingInfo = true;
        }
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
                
        //fix up the owner if needed .. schema migration
        //TODO: remove after Dec 2015
        String owner = getOwner();
        if (hasSetMeetingInfo && (owner==null || owner.length()==0)) {
            //set to the person currently saving the record.
            setOwner(ar.getBestUserId());
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

    public String getNameAndDate() throws Exception {
        SimpleDateFormat DATE_FORMAT = new SimpleDateFormat("hh:mm 'on' dd-MMM-yyyy");
        return getName() + " @ " + DATE_FORMAT.format(new Date(getStartTime()));
    }

    public String generateWikiRep(AuthRequest ar, NGPage ngp) throws Exception {
        StringBuilder sb = new StringBuilder();
        Calendar cal = Calendar.getInstance();

        sb.append("!!!Meeting: "+getNameAndDate());

        sb.append("\n\n");

        sb.append(getMeetingInfo());

        sb.append("\n\n!!!Agenda");

        long itemTime = this.getStartTime();

        for (AgendaItem ai : getSortedAgendaItems()) {
            sb.append("\n\n!");
            sb.append(Integer.toString(ai.getPosition()));
            sb.append(". ");
            sb.append(ai.getSubject());
            cal.setTimeInMillis(itemTime);
            sb.append("\n\n"+cal.get(Calendar.HOUR_OF_DAY)+":"+cal.get(Calendar.MINUTE));
            sb.append(" (");
            sb.append(Long.toString(ai.getDuration()));
            sb.append(" minutes)");
            itemTime = itemTime + (ai.getDuration()*60*1000);
            for (String presenter : ai.getPresenters()) {
                AddressListEntry ale = new AddressListEntry(presenter);
                sb.append(", ");
                sb.append(ale.getName());
            }
        }

        return sb.toString();
    }

    public String generateMinutes(AuthRequest ar, NGPage ngp) throws Exception {
        StringBuilder sb = new StringBuilder();
        Calendar cal = Calendar.getInstance();

        sb.append("!!!Meeting: "+getNameAndDate());

        sb.append("\n\n");

        sb.append(getMeetingInfo());

        sb.append("\n\n");
        sb.append("See original meeting: [");
        sb.append(getNameAndDate());
        sb.append("|meetingFull.htm?id=");
        sb.append(getId());
        sb.append("]");

        sb.append("\n\n!!!Agenda");

        long itemTime = this.getStartTime();

        for (AgendaItem ai : getSortedAgendaItems()) {
            sb.append("\n\n!");
            sb.append(Integer.toString(ai.getPosition()));
            sb.append(". ");
            sb.append(ai.getSubject());
            cal.setTimeInMillis(itemTime);
            sb.append("\n\n"+cal.get(Calendar.HOUR_OF_DAY)+":"+cal.get(Calendar.MINUTE));
            sb.append(" (");
            sb.append(Long.toString(ai.getDuration()));
            sb.append(" minutes)");
            itemTime = itemTime + (ai.getDuration()*60*1000);
            for (String presenter : ai.getPresenters()) {
                AddressListEntry ale = new AddressListEntry(presenter);
                sb.append(", ");
                sb.append(ale.getName());
            }

            sb.append("\n\n"+ai.getDesc());

            String ainotes = ai.getNotes();

            if (ainotes!=null && ainotes.length()>0) {
                sb.append("\n\n''Notes:''\n\n");
                sb.append(ainotes);
            }
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
     * Needed for the EmailContext interface
     */
    public String emailSubject() throws Exception {
        return getName();
    }
    public String getResourceURL(AuthRequest ar, NGPage ngp) throws Exception {
        return ar.getResourceURL(ngp,  "meetingFull.htm?id="+this.getId());
    }
    public String selfDescription() throws Exception {
        return "(Meeting) "+getNameAndDate();
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


    private class MScheduledNotification implements ScheduledNotification {
        NGWorkspace ngw;
        MeetingRecord meet;

        public MScheduledNotification( NGWorkspace _ngp, MeetingRecord _meet) {
            ngw  = _ngp;
            meet = _meet;
        }
        public boolean needsSending() throws Exception {
            long reminderTime = timeToSend();
            long reminderSent = meet.getReminderSent();
            //the reminder has not been sent AFTER the time to send,
            //then it still needs to be sent.
            return (reminderTime>0 && reminderSent < reminderTime);
        }

        public long timeToSend() throws Exception {
            long meetStart = meet.getStartTime();
            int delta = meet.getReminderAdvance();
            if (delta<=0) {
                return -1;
            }
            return meetStart - (delta * 60000);
        }

        public void sendIt(AuthRequest ar, MailFile mailFile) throws Exception {
            System.out.println("SENDING MEETING NOTICE: "+new Date()+" with SENDTIME: "+new Date(timeToSend())+" and MEETTIME: "+new Date(meet.getStartTime()));

            if (timeToSend() > ar.nowTime) {
                System.out.println("MEETING NOTIFICATION BUG:  Request to send when TimeToSend ("
                     +new Date(timeToSend())+") is still in the future!");
                return;
            }

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

}
