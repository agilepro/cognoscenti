package com.purplehillsbooks.weaver;

import java.io.File;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

import com.purplehillsbooks.weaver.mail.ChunkTemplate;
import com.purplehillsbooks.weaver.mail.MailFile;
import com.purplehillsbooks.weaver.mail.ScheduledNotification;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.MemFile;

public class CommentRecord extends DOMFace {

    public static final int COMMENT_TYPE_SIMPLE    = 1;
    public static final int COMMENT_TYPE_PROPOSAL  = 2;
    public static final int COMMENT_TYPE_REQUEST   = 3;
    public static final int COMMENT_TYPE_MEETING   = 4;
    public static final int COMMENT_TYPE_MINUTES   = 5;
    public static final int COMMENT_TYPE_PHASE_CHANGE = 6;

    public static final int COMMENT_STATE_DRAFT   = 11;
    public static final int COMMENT_STATE_OPEN    = 12;
    public static final int COMMENT_STATE_CLOSED  = 13;

    public static final char CONTAINER_TYPE_MEETING = 'M';
    public static final char CONTAINER_TYPE_TOPIC = 'T';
    public static final char CONTAINER_TYPE_ATTACHMENT = 'A';

    public char containerType = '?';
    public String containerID = "";

    public CommentRecord(Document doc, Element ele, DOMFace p) {
        super(doc, ele, p);

        //a simple comment should never be 'open'.
        //insure here that it goes to 'closed' state
        //maybe this can be removed once all the existing simple comments are closed
        if (getCommentType()==COMMENT_TYPE_SIMPLE  &&
                getState()==COMMENT_STATE_OPEN) {
            setState(COMMENT_STATE_CLOSED);
        }
    }

    public void schemaMigration(int fromLevel, int toLevel) throws Exception {

        if (fromLevel<101) {
            //if the comment was created before Feb 24, 2016, then mark the closed
            //email as being sent to disable closed email to avoid sending email for all
            //the old, closed records in the database.
            if (getTime()<1456272000000L) {
                //don't send the closed email for these records created when there was
                //no closed email.
                setCloseEmailSent(true);

                //Also set the regular sent email flag.  If mail not sent by now, it should
                //never be sent.
                setEmailSent(true);
            }


            //schema migration before version 101 of NGWorkspace
            getEmailSent();
            getCommentType();
            //state added in version 101 of schema
            getState();

            for (ResponseRecord rr : getResponses()) {
                //schema migration before version 101 of NGWorkspace
                rr.getEmailSent();
            }

            //needed for version 101 schema ... a few comments got
            //created incorrectly
            if (getCommentType()==COMMENT_TYPE_SIMPLE  &&
                    getState()==COMMENT_STATE_OPEN) {
                setState(COMMENT_STATE_CLOSED);
            }
        }

    }

    public String getContent() {
        return getScalar("content");
    }
    public void setContent(String newVal) {
        setScalar("content", newVal);
    }
    public String getContentHtml(AuthRequest ar)  throws Exception {
        if (ar.ngp==null) {
            throw new Exception("getContentHtml requires the AuthRequest to have a ngp object");
        }
        return WikiConverterForWYSIWYG.makeHtmlString(ar, getContent());
    }
    public void setContentHtml(AuthRequest ar, String newHtml) throws Exception {
        setContent(HtmlToWikiConverter.htmlToWiki(ar.baseURL, newHtml));
    }
    
    public String getAllSearchableText() throws Exception {
        StringBuilder sb = new StringBuilder();
        sb.append(getContent());
        sb.append("\n\n");
        for (ResponseRecord rr : getResponses()) {
            sb.append(rr.getContent());
            sb.append("\n\n");
        }
        sb.append(getScalar("outcome"));
        sb.append("\n\n");
        return sb.toString();
    }

    /**
     * The 'outcome' is the result of a proposal, or a quick response round
     */
    public String getOutcomeHtml(AuthRequest ar)  throws Exception {
        return WikiConverterForWYSIWYG.makeHtmlString(ar, getScalar("outcome"));
    }
    public void setOutcomeHtml(AuthRequest ar, String newHtml) throws Exception {
        setScalar("outcome", HtmlToWikiConverter.htmlToWiki(ar.baseURL, newHtml));
    }

    public AddressListEntry getUser()  {
        return new AddressListEntry(getAttribute("user"));
    }
    public void setUser(UserRef newVal) {
        if (newVal==null) {
            throw new RuntimeException("setUser was called with a null parameter");
        }
        setAttribute("user", newVal.getUniversalId());
    }

    /**
     * A comment can have a list of users to be notified, and in effect added to the list of
     * people who are notified about a topic or meeting agenda item.
     */
    public NGRole getNotifyRole() throws Exception {
        return requireChild("subscriberRole", CustomRole.class);
    }

    public int getCommentType() {
        int ct =  getAttributeInt("commentType");
        if (ct<=0) {
            //schema migration from BEFORE schema version 101
            //old attribute was boolean "poll" where true was a
            //proposal, and false was a simple comment.  This is
            //replaced by the commentType which has three or more
            //values.
            if ("true".equals(getAttribute("poll"))) {
                ct = COMMENT_TYPE_PROPOSAL;
            }
            else {
                ct = COMMENT_TYPE_SIMPLE;
            }
            setCommentType(ct);
            clearAttribute("poll");
        }
        return ct;
    }
    public void setCommentType(int newVal) {
        setAttributeInt("commentType", newVal);
    }
    public String getTypeName() {
        switch (getCommentType()) {
        case COMMENT_TYPE_SIMPLE:
            return "comment";
        case COMMENT_TYPE_PROPOSAL:
            return "proposal";
        case COMMENT_TYPE_REQUEST:
            return "round";
        case COMMENT_TYPE_MEETING:
            return "meeting";
        case COMMENT_TYPE_MINUTES:
            return "minutes";
        case COMMENT_TYPE_PHASE_CHANGE:
            return "phase";
        }
        return "unknown";
    }

    public long getTime() {
        return getAttributeLong("time");
    }
    public void setTime(long newVal) throws Exception {
        setAttributeLong("time", newVal);
    }

    public long getPostTime() {
        return getAttributeLong("postTime");
    }
    public void setPostTime(long newVal) throws Exception {
        setAttributeLong("postTime", newVal);
    }

    /**
     * Should be one of these states:
     *
     * COMMENT_STATE_DRAFT
     * COMMENT_STATE_OPEN
     * COMMENT_STATE_CLOSED
     */
    public int getState() {
        int state = getAttributeInt("state");

        //schema migration from BEFORE version 101
        if (state<COMMENT_STATE_DRAFT || state > COMMENT_STATE_CLOSED) {
            if (getCommentType() == COMMENT_TYPE_SIMPLE) {
                //simple comments go directly to closed
                state = COMMENT_STATE_CLOSED;
            }
            else if (getTime()<System.currentTimeMillis()-14L*24*60*60*1000) {
                //if more than 2 weeks old, close it
                state = COMMENT_STATE_CLOSED;
            }
            else {
                //default everything to open state
                state = COMMENT_STATE_OPEN;
            }
            setState(state);
        }
        return state;
    }
    public void setState(int newVal) {
        if (newVal<COMMENT_STATE_DRAFT || newVal > COMMENT_STATE_CLOSED) {
            //default value used instead of a funny value
            newVal = COMMENT_STATE_OPEN;
        }
        setAttributeInt("state", newVal);
    }

    public long getDueDate() {
        long dueDate = getAttributeLong("dueDate");
        if (dueDate <= 0) {
            //default duedate to one day from when created
            dueDate = getTime() + 24L*60*60*1000;
        }
        return dueDate;
    }
    public void setDueDate(long newVal) throws Exception {
        setAttributeLong("dueDate", newVal);
    }

    public List<ResponseRecord> getResponses() throws Exception  {
        return getChildren("response", ResponseRecord.class);
    }
    public ResponseRecord getResponse(UserRef user) throws Exception  {
        for (ResponseRecord rr : getResponses()) {
            if (user.hasAnyId(rr.getUserId())) {
                return rr;
            }
        }
        return null;
    }
    public ResponseRecord getOrCreateResponse(UserRef user) throws Exception  {
        ResponseRecord rr = getResponse(user);
        if (rr==null) {
            rr = createChild("response", ResponseRecord.class);
            rr.setUserId(user.getUniversalId());
        }
        return rr;
    }
    public void setResponse(AuthRequest ar, UserRef user, String choice, String htmlContent) throws Exception  {
        ResponseRecord rr = getOrCreateResponse(user);
        rr.setChoice(choice);
        rr.setTime(ar.nowTime);
        rr.setHtml(ar, htmlContent);
    }
    public void removeResponse(UserRef user) throws Exception  {
        this.removeChildrenByNameAttrVal("response", "uid", user.getUniversalId());
    }


    public List<String> getChoices() {
        return getVector("choice");
    }
    public void setChoices(List<String> choices) {
        setVector("choice", choices);
    }

    public long getReplyTo() {
        return getScalarLong("replyTo");
    }
    public void setReplyTo(long replyVal) {
        setScalarLong("replyTo", replyVal);
    }

    /**
     * This is the duration (in minutes) that the question or
     * proposal should be 'open' before automatically closing.
     * @return
     */
    public int getDuration() {
        return getAttributeInt("duration");
    }
    public void setDuration(int replyVal) {
        setAttributeInt("duration", replyVal);
    }

    public String getDecision() {
        return getScalar("decision");
    }
    public void setDecision(String replies) {
        setScalar("decision", replies);
    }

    public boolean getSuppressEmail() {
        return getAttributeBool("suppressEmail");
    }
    public void setSuppressEmail(boolean replyVal) {
        setAttributeBool("suppressEmail", replyVal);
    }


    /**
     * NewPhase is applicable only when the comment is indicating
     * a phase change in a conversation.  It represents the phase
     * that the conversation just changed to.  This value will be
     * empty for other comment types.
     */
    public String getNewPhase() {
        return getScalar("newPhase");
    }
    public void setNewPhase(String newPhase) {
        setScalar("newPhase", newPhase);
    }

    public List<Long> getReplies() {
        ArrayList<Long> ret = new ArrayList<Long>();
        for(String val : getVector("replies")) {
            long longVal = safeConvertLong(val);
            ret.add(new Long(longVal));
        }
        return ret;
    }
    public void addOneToReplies(long replyValue) {
        String val = Long.toString(replyValue);
        for (Long aReply : getReplies()) {
            if (aReply.longValue()==replyValue) {
                //found it already there, nothing more to do
                return;
            }
        }
        //if we get here we did not find anything, so go ahead and add it
        addVectorValue("replies", val);
    }
    public void removeFromReplies(long replyValue) {
        String foundVal = null;
        for(String val : getVector("replies")) {
            long longVal = safeConvertLong(val);
            if (longVal == replyValue) {
                foundVal = val;
            }
        }
        if (foundVal!=null) {
            removeVectorValue("replies", foundVal);
        }
    }
    public void setReplies(List<Long> replies) {
        setVectorLong("replies", replies);
    }

    public boolean needCreateEmailSent() {
        if (getState()==CommentRecord.COMMENT_STATE_DRAFT) {
            //never send email for draft or phase change
            return false;
        }
        if (getCommentType()==CommentRecord.COMMENT_TYPE_PHASE_CHANGE) {
            //never send email for phase change
            return false;
        }
        if (getCommentType()==CommentRecord.COMMENT_TYPE_MINUTES) {
            //never send email for minutes
            return false;
        }
        if (getTime()<1456272000000L) {
            //if this was created before Feb 24, 2016, then don't send any email
            return false;
        }
        if (getEmailSent()) {
            return false;
        }
        //so we have something to send, but is it time yet?
        //comments don't have a future time for sending, so eventhing immediate
        return true;
    }

    public boolean getEmailSent() {
        if (getAttributeBool("emailSent")) {
            return true;
        }

        //minutes are never sent, so mark that now as having been sent
        if (getCommentType()==CommentRecord.COMMENT_TYPE_MINUTES) {
            setEmailSent(true);
            return true;
        }

        //schema migration BEFORE version 101
        //If the email was not sent, and the item was created
        //more than 1 week ago, then go ahead and mark it as sent, because it is
        //too late to send.   This is important while adding this automatic email
        //sending because there are a lot of old records that have never been marked
        //as being sent.   Need to set them as being sent so they are not sent now.
        if (getTime() < TopicRecord.ONE_WEEK_AGO) {
            setEmailSent(true);
            return true;
        }

        return false;
    }
    public void setEmailSent(boolean newVal) {
        setAttributeBool("emailSent", newVal);
    }


    public boolean needCloseEmailSent() {
        if (getCommentType()==CommentRecord.COMMENT_TYPE_SIMPLE
            || getCommentType()==CommentRecord.COMMENT_TYPE_MINUTES
            || getCommentType()==CommentRecord.COMMENT_TYPE_PHASE_CHANGE) {
            return false;
        }
        if (getState()!=CommentRecord.COMMENT_STATE_CLOSED) {
            return false;
        }

        if (getTime() < 1456272000000L) {
            //if this was created before Feb 24, 2016, then don't send any email
            setCloseEmailSent(true);
            return false;
        }
        if (getCloseEmailSent()) {
            return false;
        }
        return true;
    }

    public boolean getCloseEmailSent() {
        return getAttributeBool("closeEmailSent");
    }
    public void setCloseEmailSent(boolean newVal) {
        setAttributeBool("closeEmailSent", newVal);
    }


    public List<String> getDocList()  throws Exception {
        return getVector("docList");
    }
    public void setDocList(List<String> newVal) throws Exception {
        setVector("docList", newVal);
    }


    public void commentEmailRecord(AuthRequest ar, NGWorkspace ngw, EmailContext noteOrMeet, MailFile mailFile) throws Exception {
        try {
            List<OptOutAddr> sendTo = new ArrayList<OptOutAddr>();
            boolean excludeSelf = getAttributeBool("excludeSelf");

            List<AddressListEntry> notifyList = getNotifyRole().getDirectPlayers();
            noteOrMeet.extendNotifyList(notifyList);  //so it can remember it
            noteOrMeet.appendTargetEmails(sendTo, ngw);

            //add the commenter in case missing from the target role
            AddressListEntry commenter = getUser();
            if (!excludeSelf) {
                OptOutAddr.appendOneDirectUser(commenter, sendTo);
            }
            OptOutAddr.appendUsers(notifyList, sendTo); //in case the container does not remember it

            UserProfile commenterProfile = commenter.getUserProfile();
            if (commenterProfile==null) {
                System.out.println("DATA PROBLEM: comment "+this.getTime()+" came from a person without a profile ("+getUser().getEmail()+") ignoring.");
                setEmailSent(true);
                setCloseEmailSent(true);
                return;
            }

            for (OptOutAddr ooa : sendTo) {
                if (this.getCommentType()>CommentRecord.COMMENT_TYPE_SIMPLE) {
                    UserProfile toProfile = UserManager.getStaticUserManager().lookupUserByAnyId(ooa.getEmail());
                    if (toProfile!=null) {
                        ar.getCogInstance().getUserCacheMgr().needRecalc(toProfile);
                    }
                }
                if (excludeSelf) {
                    if (commenter.equals(ooa.assignee)) {
                        //skip sending email if the user said to exclude themselves
                        continue;
                    }
                }

                constructEmailRecordOneUser(ar, ngw, noteOrMeet, ooa, commenterProfile, mailFile);
            }

            if (getState()==CommentRecord.COMMENT_STATE_CLOSED) {
                //if sending the close email, also mark the other email as sent
                setCloseEmailSent(true);
                setEmailSent(true);
            }
            else {
                setEmailSent(true);
            }
            setPostTime(ar.nowTime);
            noteOrMeet.markTimestamp(ar.nowTime);
        }
        catch (Exception e) {
            throw new Exception("Unable to compose email for comment #"+this.getTime()
                    +" in "+noteOrMeet.selfDescription()
                    +" in workspace "+ngw.getFullName(), e);
        }
    }





    public String commentTypeName() {
        switch (this.getCommentType()) {
            case CommentRecord.COMMENT_TYPE_SIMPLE:
                return "comment";
            case CommentRecord.COMMENT_TYPE_PROPOSAL:
                return "proposal";
            case CommentRecord.COMMENT_TYPE_REQUEST:
                return "round";
            case CommentRecord.COMMENT_TYPE_MEETING:
                return "meeting notice";
            case CommentRecord.COMMENT_TYPE_MINUTES:
                return "minutes";
            case CommentRecord.COMMENT_TYPE_PHASE_CHANGE:
                return "phase change";
        }
        throw new RuntimeException("Program Logic Error: This comment type is missing a name: "+this.getCommentType());
    }

    private void constructEmailRecordOneUser(AuthRequest ar, NGWorkspace ngp, EmailContext noteOrMeet, OptOutAddr ooa,
            UserProfile commenterProfile, MailFile mailFile) throws Exception  {
        Cognoscenti cog = ar.getCogInstance();
        if (!ooa.hasEmailAddress()) {
            return;  //ignore users without email addresses
        }
        //simple types go straight to closed, but we still need to send the 'created' message
        boolean isClosed = getState()==CommentRecord.COMMENT_STATE_CLOSED && getCommentType()!=CommentRecord.COMMENT_TYPE_SIMPLE;

        MemFile body = new MemFile();
        AuthRequest clone = new AuthDummy(commenterProfile, body.getWriter(), ar.getCogInstance());
        clone.retPath = ar.baseURL;

        //this is needed for the HTML conversion.
        if (ngp==null) {
            throw new Exception("constructEmailRecordOneUser requires NGP non null");
        }
        clone.ngp = ngp;

        String opType = "New ";
        if (isClosed) {
            opType = "Closed ";
        }
        String cmtType = commentTypeName();
        AddressListEntry owner = getUser();

        JSONObject data = new JSONObject();
        data.put("baseURL", ar.baseURL);
        String fullURLtoContext = ar.baseURL + noteOrMeet.getEmailURL(clone, ngp);
        data.put("parentURL", fullURLtoContext);
        data.put("parentName", noteOrMeet.emailSubject());
        data.put("commentURL", fullURLtoContext + "#cmt" + getTime());
        data.put("comment", this.getHtmlJSON(clone));
        data.put("wsURL", ar.baseURL + clone.getDefaultURL(ngp));
        data.put("wsName", ngp.getFullName());
        data.put("userURL", ar.baseURL + owner.getLinkUrl());
        data.put("userName", owner.getName());

        data.put("opType", opType);
        data.put("cmtType", cmtType);
        data.put("isClosed", isClosed);
        data.put("outcomeHtml", this.getOutcomeHtml(clone));
        data.put("optout", ooa.getUnsubscribeJSON(clone));

        data.put("replyUrl", ar.baseURL + noteOrMeet.getReplyURL(ar,ngp,this.getTime())
                + "&emailId=" + URLEncoder.encode(ooa.getEmail(), "UTF-8"));
        data.put("unsubUrl", ar.baseURL + noteOrMeet.getUnsubURL(ar,ngp,this.getTime())
                + "&emailId=" + URLEncoder.encode(ooa.getEmail(), "UTF-8"));

        AttachmentRecord.addEmailStyleAttList(data, ar, ngp, getDocList());

        File templateFile = cog.getConfig().getFileFromRoot("email/NewComment.chtml");
        ChunkTemplate.streamIt(clone.w, templateFile, data, ooa.getCalendar());
        clone.flush();

        String emailSubject =  noteOrMeet.emailSubject()+": "+opType+cmtType;
        mailFile.createEmailRecord(commenterProfile.getAddressListEntry(), ooa.getEmail(), emailSubject, body.toString());
    }


    public JSONObject getJSON() throws Exception {
        AddressListEntry ale = getUser();
        UserProfile up = ale.getUserProfile();
        String userKey = "unknown";
        if (up!=null) {
            userKey = up.getKey();
        }
        JSONObject commInfo = new JSONObject();
        commInfo.put("containerType",  ""+containerType);
        commInfo.put("containerID",  containerID);
        commInfo.put("user",     ale.getUniversalId());
        commInfo.put("userName", ale.getName());
        commInfo.put("userKey",  userKey);
        commInfo.put("time",     getTime());
        commInfo.put("postTime", getPostTime());
        commInfo.put("state",    getState());
        commInfo.put("dueDate",  getDueDate());
        commInfo.put("commentType",getCommentType());
        commInfo.put("emailPending",needCreateEmailSent()||needCloseEmailSent());  //display only
        extractScalarLong(commInfo, "replyTo");
        extractScalarString(commInfo, "newPhase");
        JSONArray replyArray = new JSONArray();
        for (Long val : getReplies()) {
            replyArray.put(val.longValue());
        }
        commInfo.put("replies",  replyArray);
        commInfo.put("decision", getDecision());
        extractAttributeBool(commInfo, "suppressEmail");
        extractAttributeBool(commInfo, "excludeSelf");
        extractAttributeBool(commInfo, "includeInMinutes");
        
        //this is temporary
        commInfo.put("poll", getCommentType()>CommentRecord.COMMENT_TYPE_SIMPLE);
        return commInfo;
    }
    public JSONObject getHtmlJSON(AuthRequest ar) throws Exception {
        if (ar.ngp==null) {
            throw new Exception("getHtmlJSON requires an AuthRequest object with a NGP member set");
        }
        JSONObject commInfo = getJSON();
        commInfo.put("html", getContentHtml(ar));
        commInfo.put("outcome", getOutcomeHtml(ar));
        JSONArray responseArray = new JSONArray();
        for (ResponseRecord rr : getResponses()) {
            responseArray.put(rr.getJSON(ar));
        }
        commInfo.put("responses", responseArray);
        commInfo.put("choices", constructJSONArray(getChoices()));
        commInfo.put("notify", AddressListEntry.getJSONArray(getNotifyRole().getDirectPlayers()));
        commInfo.put("docList", constructJSONArray(getDocList()));
        return commInfo;
    }

    public void updateFromJSON(JSONObject input, AuthRequest ar) throws Exception {

        if (input.has("html")) {
            String html = input.getString("html");
            setContentHtml(ar, html);
        }
        if (input.has("outcome")) {
            String html = input.getString("outcome");
            setOutcomeHtml(ar, html);
        }
        if (input.has("commentType")) {
            setCommentType(input.getInt("commentType"));
        }
        if (input.has("choices")) {
            setChoices(constructVector(input.getJSONArray("choices")));
        }
        if (input.has("responses")) {
            JSONArray responseArray = input.getJSONArray("responses");
            for (int i=0; i<responseArray.length(); i++) {
                JSONObject oneResp = responseArray.getJSONObject(i);
                String responseUser = oneResp.getString("user");
                AddressListEntry ale = new AddressListEntry(responseUser);
                boolean removeMe = (oneResp.has("removeMe") && oneResp.getBoolean("removeMe"));
                if (removeMe) {
                    removeResponse(ale);
                }
                else {
                    ResponseRecord rr = getOrCreateResponse(ale);
                    rr.updateFromJSON(oneResp, ar);
                    rr.setTime(ar.nowTime);
                }
            }
        }
        if (input.has("replyTo")) {
            setReplyTo(input.getLong("replyTo"));
        }
        if (input.has("postTime")) {
            setPostTime(input.getLong("postTime"));
        }
        if (input.has("state")) {
            setState(input.getInt("state"));
        }
        if (input.has("dueDate")) {
            setDueDate(input.getLong("dueDate"));
        }
        if (input.has("replies")) {
            setReplies(constructVectorLong(input.getJSONArray("replies")));
        }
        if (input.has("decision")) {
            setDecision(input.getString("decision"));
        }
        if (input.has("notify")) {
            NGRole alsoNotify = this.getNotifyRole();
            alsoNotify.clear();
            alsoNotify.addPlayersIfNotPresent(
                    AddressListEntry.toAddressList(
                            AddressListEntry.uidListfromJSONArray(
                                    input.getJSONArray("notify"))));
        }
        if (input.has("docList")) {
            setDocList(constructVector(input.getJSONArray("docList")));
        }
        updateAttributeBool("suppressEmail", input);
        updateAttributeBool("excludeSelf", input);
        updateAttributeBool("includeInMinutes", input);


        //A simple comment should never be "open", only draft or closed, so assure that here
        if (getCommentType()==COMMENT_TYPE_SIMPLE  &&
                getState()==COMMENT_STATE_OPEN) {
            setState(COMMENT_STATE_CLOSED);
        }
    }


    public void gatherUnsentScheduledNotification(NGWorkspace ngw, EmailContext noteOrMeet,
            ArrayList<ScheduledNotification> resList, long timeout) throws Exception {
        ScheduledNotification sn = new CRScheduledNotification(ngw, noteOrMeet, this);
        if (sn.needsSendingBefore(timeout)) {
            resList.add(sn);
        }
        else if (getCommentType()>CommentRecord.COMMENT_TYPE_SIMPLE) {
            //only look for responses if the main comment has been sent.
            //prevents problem with a response going before the comment gets out of draft
            //
            //there can be responses only if this is a "poll" type comment (a proposal)
            for (ResponseRecord rr : getResponses()) {
                ScheduledNotification snr = rr.getScheduledNotification(ngw, noteOrMeet, this);
                if (snr.needsSendingBefore(timeout)) {
                    resList.add(snr);
                }
            }
        }
    }


    private class CRScheduledNotification implements ScheduledNotification {
        NGWorkspace ngw;
        EmailContext noteOrMeet;
        CommentRecord cr;

        public CRScheduledNotification(NGWorkspace _ngp, EmailContext _noteOrMeet, CommentRecord _cr) {
            ngw  = _ngp;
            noteOrMeet = _noteOrMeet;
            cr   = _cr;
        }

        @Override
        public boolean needsSendingBefore(long timeout) throws Exception {
            if (cr.getState()==CommentRecord.COMMENT_STATE_DRAFT) {
                //draft records do not get email sent
                return false;
            }
            if (cr.getCommentType()==CommentRecord.COMMENT_TYPE_MINUTES) {
                //minutes don't have email sent not ever so mark sent
                return false;
            }
            if (cr.getSuppressEmail()) {
                return false;
            }
            if (cr.needCreateEmailSent()) {
                //simple comments are created but not closed
                return true;
            }
            if (cr.needCloseEmailSent()) {
                return true;
            }
            return false;
        }

        @Override
        public long futureTimeToSend() throws Exception {
            if (cr.getState()==CommentRecord.COMMENT_STATE_DRAFT) {
                //draft records do not get email sent
                return -1;
            }
            if (cr.getCommentType()==CommentRecord.COMMENT_TYPE_MINUTES) {
                //minutes don't have email sent not ever so mark sent
                return -1;
            }
            if (cr.getSuppressEmail()) {
                return -1;
            }
            if (cr.needCreateEmailSent()) {
                return System.currentTimeMillis()-1000000;
            }
            if (cr.needCloseEmailSent()) {
                return System.currentTimeMillis()-1000000;
            }
            return -1;
        }

        @Override
        public void sendIt(AuthRequest ar, MailFile mailFile) throws Exception {
            cr.commentEmailRecord(ar,ngw,noteOrMeet,mailFile);
        }

        @Override
        public String selfDescription() throws Exception {
            return "("+cr.getTypeName()+") "+cr.getUser().getName()+" on "+noteOrMeet.selfDescription();
        }

    }

    public static void sortByTimestamp(List<CommentRecord> list) {
        list.sort(new CommentTimeComparator());
        
    }
    
    private static class CommentTimeComparator implements Comparator<CommentRecord> {

        @Override
        public int compare(CommentRecord arg0, CommentRecord arg1) {
            long diff = (arg1.getTime() - arg1.getTime());
            if (diff>0) {
                return 1;
            }
            else {
                return -1;
            }
        }
        
    }
}
