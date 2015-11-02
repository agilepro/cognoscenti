package org.socialbiz.cog;

import java.io.StringWriter;
import java.util.List;
import java.util.Vector;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;

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
        rr.setHtml(ar, htmlContent);
    }


    public List<String> getChoices() {
        return getVector("choice");
    }
    public void setChoices(Vector<String> choices) {
        setVector("choice", choices);
    }

    public boolean getEmailSent()  throws Exception {
        return getAttributeBool("emailSent");
    }
    public void setEmailSent(boolean newVal) throws Exception {
        setAttributeBool("emailSent", newVal);
    }


    /**
     * The email for a comment should be sent about 5 minutes after the comment is created.
     * This gives the author enough time to correct things if needed.
     * If the email has not been sent, this will return the time that it should be sent.
     * If the email has already been sent, then this return -1.
     */
    public long emailSchedule() throws Exception  {
        if (getEmailSent()) {
            return -1;
        }
        long createTime = getTime();
        if (createTime < System.currentTimeMillis() - 36 * 60 * 60 * 1000) {
            //if it is more than 36 hours old, then suppress sending email.
            //this is mainly to avoid sending email for every comment in history
            //before we invented the email sending of comments.
            setEmailSent(true);
            return -1;
        }
        //ok, set it to set five minutes after the time it was created
        return createTime + 300000;
    }

    public void commentEmailRecord(AuthRequest ar, NGPage ngp, NoteRecord note) throws Exception {
        Vector<OptOutAddr> sendTo = new Vector<OptOutAddr>();
        OptOutAddr.appendUsersFromRole(ngp, "Members", sendTo);

        AddressListEntry commenter = getUser();
        UserProfile commenterProfile = commenter.getUserProfile();

        for (OptOutAddr ooa : sendTo) {
            constructEmailRecordOneUser(ar, ngp, note, ooa, commenterProfile);
        }
        setEmailSent(true);
    }

    private void constructEmailRecordOneUser(AuthRequest ar, NGPage ngp, NoteRecord note, OptOutAddr ooa,
            UserProfile commenterProfile) throws Exception  {
        if (!ooa.hasEmailAddress()) {
            return;  //ignore users without email addresses
        }

        StringWriter bodyWriter = new StringWriter();
        AuthRequest clone = new AuthDummy(commenterProfile, bodyWriter, ar.getCogInstance());
        clone.setNewUI(true);
        clone.retPath = ar.baseURL;
        clone.write("<html><body>");

        String topicAddress = ar.baseURL + clone.getResourceURL(ngp, note) + "#cmt" + getTime();
        String emailSubject;
        String cmtType;
        if (this.isPoll()) {
            emailSubject = note.getSubject()+": NEW Proposal";
            cmtType = "proposal";
        }
        else {
            emailSubject = note.getSubject()+": NEW Comment";
            cmtType = "comment";
        }
        AddressListEntry ale = commenterProfile.getAddressListEntry();
        
        clone.write("\n<p><b>From: ");
        ale.writeLink(clone);
        clone.write("&nbsp; \n    <b>Workspace:</b> ");
        ngp.writeContainerLink(clone, 40);
        clone.write("\n</p>\n<p><b>New ");
        clone.write(cmtType);
        clone.write("</b> on topic <a href=\"");
        clone.write(topicAddress);
        clone.write("\">");
        clone.writeHtml(note.getSubject());
        clone.write("</a></p>\n<hr/>\n");

        clone.write(this.getContentHtml(ar));

        clone.write("</body></html>");


        EmailSender.containerEmail(ooa, ngp, emailSubject, bodyWriter.toString(), commenterProfile.getEmailWithName(),
                new Vector<String>(), ar.getCogInstance());
    }


    public JSONObject getJSON() throws Exception {
        AddressListEntry ale = getUser();
        UserProfile up = ale.getUserProfile();
        String userKey = "unknown";
        if (up!=null) {
            userKey = up.getKey();
        }
        JSONObject commInfo = new JSONObject();
        //TODO: remove the content field from JSON representation
        commInfo.put("content", getContent());
        commInfo.put("user",    ale.getUniversalId());
        commInfo.put("userName",ale.getName());
        commInfo.put("userKey", userKey);
        commInfo.put("time",    getTime());
        commInfo.put("poll",    isPoll());
        commInfo.put("emailSent",getEmailSent());
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
        System.out.println("COMMRESP:  looking for responses");
        if (input.has("responses")) {
            JSONArray responses = input.getJSONArray("responses");
            for (int i=0; i<responses.length(); i++) {
                JSONObject oneResp = responses.getJSONObject(i);
                String responseUser = oneResp.getString("user");

                //only update the response from a user if that user is the one logged in
                if (user.hasAnyId(responseUser)) {
                    ResponseRecord rr = getOrCreateResponse(user);
                    rr.updateFromJSON(oneResp, ar);
                }
            }
        }
    }

    public ScheduledNotification findNextScheduledNotification(NGPage ngp, NoteRecord note) throws Exception {
        ScheduledNotification best = null;
        ScheduledNotification sn = getScheduledNotification(ngp, note);
        if (!sn.isSent()) {
            best = sn;
        }
        for (ResponseRecord rr : getResponses()) {
            sn = rr.getScheduledNotification(ngp, note, this);
            if (!sn.isSent()) {
                if (best==null || sn.timeToSend() < best.timeToSend()) {
                    best=sn;
                }
            }
        }
        return best;
    }
    

    public ScheduledNotification getScheduledNotification(NGPage ngp, NoteRecord note) {
        return new CRScheduledNotification(ngp, note, this);
    }
    
    private class CRScheduledNotification implements ScheduledNotification {
        NGPage ngp;
        NoteRecord note;
        CommentRecord cr;
        
        public CRScheduledNotification( NGPage _ngp, NoteRecord _note, CommentRecord _cr) {
            ngp  = _ngp;
            note = _note;
            cr   = _cr;
        }
        public boolean isSent() throws Exception {
            return cr.getEmailSent();
        }
        
        public long timeToSend() throws Exception {
            return cr.getTime()+300000;
        }
        
        public void sendIt(AuthRequest ar) throws Exception {
            cr.commentEmailRecord(ar,ngp,note);
        }
    }
}
