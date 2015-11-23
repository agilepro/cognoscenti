package org.socialbiz.cog;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Vector;

import org.socialbiz.cog.mail.MailFile;
import org.socialbiz.cog.mail.ScheduledNotification;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;
import org.workcast.streams.MemFile;

public class CommentRecord extends DOMFace {

    public CommentRecord(Document doc, Element ele, DOMFace p) {
        super(doc, ele, p);
    }

    public String getContent()  throws Exception {
        return getScalar("content");
    }
    public void setContent(String newVal) throws Exception {
        setScalar("content", newVal);
    }
    public String getContentHtml(AuthRequest ar)  throws Exception {
        return WikiConverterForWYSIWYG.makeHtmlString(ar, getContent());
    }
    public void setContentHtml(AuthRequest ar, String newHtml) throws Exception {
        setContent(HtmlToWikiConverter.htmlToWiki(ar.baseURL, newHtml));
    }

    public AddressListEntry getUser()  throws Exception {
        return new AddressListEntry(getAttribute("user"));
    }
    public void setUser(UserRef newVal) throws Exception {
        setAttribute("user", newVal.getUniversalId());
    }

    public long getTime() {
        return getAttributeLong("time");
    }
    public void setTime(long newVal) throws Exception {
        setAttributeLong("time", newVal);
    }

    public boolean isPoll()  throws Exception {
        return "true".equals(getAttribute("poll"));
    }
    public void setPoll(boolean isPoll) throws Exception {
        if (isPoll) {
            setAttribute("poll", "true");
        }
        else {
            clearAttribute("poll");
        }
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


    public List<String> getChoices() {
        return getVector("choice");
    }
    public void setChoices(Vector<String> choices) {
        setVector("choice", choices);
    }

    public long getReplyTo() {
        return getScalarLong("replyTo");
    }
    public void setReplyTo(long replyVal) {
        setScalar("replyTo", replyVal);
    }

    public String getDecision() {
        return getScalar("decision");
    }
    public void setDecision(String replies) {
        setScalar("decision", replies);
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
        addVectorValue("replies", val);
    }
    public void setReplies(Vector<Long> replies) {
        setVectorLong("replies", replies);
    }

    public boolean getEmailSent()  throws Exception {
        if (getAttributeBool("emailSent")) {
            return true;
        }

        //schema migration.  If the email was not sent, and the item was created
        //more than 1 week ago, then go ahead and mark it as sent, because it is
        //too late to send.   This is important while adding this automatic email
        //sending because there are a lot of old records that have never been marked
        //as being sent.   Need to set them as being sent so they are not sent now.
        if (getTime() < NoteRecord.ONE_WEEK_AGO) {
            System.out.println("CommentRecord Migration: will never send email due "+new Date(getTime()));
            setEmailSent(true);
            return true;
        }

        return false;
    }
    public void setEmailSent(boolean newVal) throws Exception {
        setAttributeBool("emailSent", newVal);
    }



    public void commentEmailRecord(AuthRequest ar, NGPage ngp, EmailContext noteOrMeet, MailFile mailFile) throws Exception {
        Vector<OptOutAddr> sendTo = new Vector<OptOutAddr>();
        OptOutAddr.appendUsersFromRole(ngp, "Members", sendTo);

        AddressListEntry commenter = getUser();
        UserProfile commenterProfile = commenter.getUserProfile();
        if (commenterProfile==null) {
            System.out.println("DATA PROBLEM: comment came from a person without a profile ("+getUser().getEmail()+") ignoring");
            setEmailSent(true);
            return;
        }

        for (OptOutAddr ooa : sendTo) {
            constructEmailRecordOneUser(ar, ngp, noteOrMeet, ooa, commenterProfile, mailFile);
        }
        setEmailSent(true);
    }

    private void constructEmailRecordOneUser(AuthRequest ar, NGPage ngp, EmailContext noteOrMeet, OptOutAddr ooa,
            UserProfile commenterProfile, MailFile mailFile) throws Exception  {
        if (!ooa.hasEmailAddress()) {
            return;  //ignore users without email addresses
        }

        MemFile body = new MemFile();
        AuthRequest clone = new AuthDummy(commenterProfile, body.getWriter(), ar.getCogInstance());
        clone.setNewUI(true);
        clone.retPath = ar.baseURL;
        clone.write("<html><body>");

        String topicAddress = ar.baseURL + noteOrMeet.getResourceURL(clone, ngp) + "#cmt" + getTime();
        String emailSubject;
        String cmtType;
        if (this.isPoll()) {
            emailSubject = noteOrMeet.emailSubject()+": NEW Proposal";
            cmtType = "proposal";
        }
        else {
            emailSubject = noteOrMeet.emailSubject()+": NEW Comment";
            cmtType = "comment";
        }
        AddressListEntry ale = commenterProfile.getAddressListEntry();

        clone.write("\n<p>From: ");
        ale.writeLink(clone);
        clone.write("&nbsp; \n    Workspace: ");
        ngp.writeContainerLink(clone, 40);
        clone.write("\n<br/>\nNew <b>");
        clone.write(cmtType);
        clone.write("</b> on topic <a href=\"");
        clone.write(topicAddress);
        clone.write("\">");
        clone.writeHtml(noteOrMeet.emailSubject());
        clone.write("</a></p>\n<hr/>\n");

        clone.write(this.getContentHtml(ar));

        ooa.writeUnsubscribeLink(clone);
        clone.write("</body></html>");
        clone.flush();

        mailFile.createEmailRecord(commenterProfile.getEmailWithName(), ooa.getEmail(), emailSubject, body.toString());
    }


    public JSONObject getJSON() throws Exception {
        AddressListEntry ale = getUser();
        UserProfile up = ale.getUserProfile();
        String userKey = "unknown";
        if (up!=null) {
            userKey = up.getKey();
        }
        JSONObject commInfo = new JSONObject();
        commInfo.put("user",     ale.getUniversalId());
        commInfo.put("userName", ale.getName());
        commInfo.put("userKey",  userKey);
        commInfo.put("time",     getTime());
        commInfo.put("poll",     isPoll());
        commInfo.put("emailSent",getEmailSent());
        commInfo.put("replyTo",  getReplyTo());
        JSONArray replyList = new JSONArray();
        for (Long val : getReplies()) {
            replyList.put(val.longValue());
        }
        commInfo.put("replies",  replyList);
        commInfo.put("decision", getDecision());
        return commInfo;
    }
    public JSONObject getHtmlJSON(AuthRequest ar) throws Exception {
        JSONObject commInfo = getJSON();
        commInfo.put("html", getContentHtml(ar));
        JSONArray responses = new JSONArray();
        for (ResponseRecord rr : getResponses()) {
            responses.put(rr.getJSON(ar));
        }
        commInfo.put("responses", responses);
        commInfo.put("choices", constructJSONArray(getChoices()));
        return commInfo;
    }

    public void updateFromJSON(JSONObject input, AuthRequest ar) throws Exception {
        UserRef owner = getUser();
        UserProfile user = ar.getUserProfile();
        //only update the comment if that user is the one logged in
        if (user.equals(owner)) {
            if (input.has("html")) {
                String html = input.getString("html");
                setContentHtml(ar, html);
            }
            if (input.has("poll")) {
                setPoll(input.getBoolean("poll"));
            }
            if (input.has("choices")) {
                setChoices(constructVector(input.getJSONArray("choices")));
            }
        }
        if (input.has("responses")) {
            JSONArray responses = input.getJSONArray("responses");
            System.out.println("Submitted to server comment responses: "+responses.toString());
            for (int i=0; i<responses.length(); i++) {
                JSONObject oneResp = responses.getJSONObject(i);
                String responseUser = oneResp.getString("user");

                //only update the response from a user if that user is the one logged in
                if (user.hasAnyId(responseUser)) {
                    ResponseRecord rr = getOrCreateResponse(user);
                    rr.updateFromJSON(oneResp, ar);
                    rr.setTime(ar.nowTime);
                }
            }
        }
        if (input.has("replyTo")) {
            setReplyTo(input.getLong("replyTo"));
        }
        if (input.has("replies")) {
            setReplies(constructVectorLong(input.getJSONArray("replies")));
        }
        if (input.has("decision")) {
            setDecision(input.getString("decision"));
        }
    }


    public void gatherUnsentScheduledNotification(NGPage ngp, EmailContext noteOrMeet,
            ArrayList<ScheduledNotification> resList) throws Exception {
        if (!getEmailSent()) {
            ScheduledNotification sn = new CRScheduledNotification(ngp, noteOrMeet, this);
            if (!sn.isSent()) {
                resList.add(sn);
            }
        }
        for (ResponseRecord rr : getResponses()) {
            ScheduledNotification sn = rr.getScheduledNotification(ngp, noteOrMeet, this);
            if (!sn.isSent()) {
                resList.add(sn);
            }
        }
    }


    private class CRScheduledNotification implements ScheduledNotification {
        NGPage ngp;
        EmailContext noteOrMeet;
        CommentRecord cr;

        public CRScheduledNotification( NGPage _ngp, EmailContext _noteOrMeet, CommentRecord _cr) {
            ngp  = _ngp;
            noteOrMeet = _noteOrMeet;
            cr   = _cr;
        }
        public boolean isSent() throws Exception {
            return cr.getEmailSent();
        }

        public long timeToSend() throws Exception {
            return cr.getTime()+1000;
        }

        public void sendIt(AuthRequest ar, MailFile mailFile) throws Exception {
            cr.commentEmailRecord(ar,ngp,noteOrMeet,mailFile);
        }

        public String selfDescription() throws Exception {
            return "(Comment) "+cr.getUser().getName()+" on "+noteOrMeet.selfDescription();
        }

    }


}
