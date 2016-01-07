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

package org.socialbiz.cog;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import org.socialbiz.cog.mail.MailFile;
import org.socialbiz.cog.mail.ScheduledNotification;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.workcast.json.JSONObject;
import org.workcast.streams.MemFile;

public class ResponseRecord extends DOMFace
{

    public ResponseRecord(Document definingDoc, Element definingElement,  DOMFace p) {
        super(definingDoc, definingElement, p);
    }

    public String getUserId() {
        return getAttribute("uid");
    }
    public void setUserId(String userId) {
        setAttribute("uid", userId);
    }
    public long getTime() {
        return getAttributeLong("time");
    }
    public void setTime(long newVal) throws Exception {
        setAttributeLong("time", newVal);
    }
    public boolean getEmailSent()  throws Exception {
        if (getAttributeBool("emailSent")) {
            return true;
        }

        //schema migration BEFORE schema version 101
        //If the email was not sent, and the item was created
        //more than 1 week ago, then go ahead and mark it as sent, because it is
        //too late to send.   This is important while adding this automatic email
        //sending because there are a lot of old records that have never been marked
        //as being sent.   Need to set them as being sent so they are not sent now.
        if (getTime() < NoteRecord.ONE_WEEK_AGO) {
            System.out.println("ResponseRecord Migration: will never send email due "+new Date(getTime()));
            setEmailSent(true);
            return true;
        }

        return false;
    }
    public void setEmailSent(boolean newVal) throws Exception {
        setAttributeBool("emailSent", newVal);
    }


    public String getChoice() {
        return getScalar("choice");
    }
    public void setChoice(String content) {
        setScalar("choice", content);
    }

    public String getContent() {
        return getScalar("content");
    }
    public void setContent(String content) {
        setScalar("content", content);
    }

    public String getHtml(AuthRequest ar) throws Exception {
        return WikiConverterForWYSIWYG.makeHtmlString(ar, getContent());
    }
    public void setHtml(AuthRequest ar, String newHtml) throws Exception {
        setContent(HtmlToWikiConverter.htmlToWiki(ar.baseURL, newHtml));
    }


    public void responseEmailRecord(AuthRequest ar, NGPage ngp, EmailContext noteOrMeet, CommentRecord cr, MailFile mailFile) throws Exception {
        List<OptOutAddr> sendTo = new ArrayList<OptOutAddr>();
        String targetRole = noteOrMeet.getTargetRole();
        if (targetRole==null || targetRole.length()==0) {
            targetRole = "Members";
        }
        OptOutAddr.appendUsersFromRole(ngp, targetRole, sendTo);

        AddressListEntry commenter = new AddressListEntry(getUserId());
        UserProfile commenterProfile = commenter.getUserProfile();
        if (commenterProfile==null) {
            System.out.println("DATA PROBLEM: proposal response came from a person without a profile ("+getUserId()+") ignoring");
            setEmailSent(true);
            return;
        }

        for (OptOutAddr ooa : sendTo) {
            constructEmailRecordOneUser(ar, ngp, noteOrMeet, ooa, cr, commenterProfile, mailFile);
        }
        setEmailSent(true);
    }

    private void constructEmailRecordOneUser(AuthRequest ar, NGPage ngp, EmailContext noteOrMeet, OptOutAddr ooa,
            CommentRecord cr, UserProfile commenterProfile, MailFile mailFile) throws Exception  {
        
        if (!ooa.hasEmailAddress()) {
            return;  //ignore users without email addresses
        }

        UserProfile toProfile = UserManager.findUserByAnyId(ooa.getEmail());
        if (toProfile!=null) {
            ar.getCogInstance().getUserCacheMgr().needRecalc(toProfile);
        }

        MemFile body = new MemFile();
        AuthRequest clone = new AuthDummy(commenterProfile, body.getWriter(), ar.getCogInstance());
        clone.setNewUI(true);
        clone.retPath = ar.baseURL;
        clone.write("<html><body>");

        String topicAddress = ar.baseURL + noteOrMeet.getResourceURL(clone, ngp) + "#cmt" + cr.getTime();
        String emailSubject = "??";
        switch (cr.getCommentType()) {
            case CommentRecord.COMMENT_TYPE_PROPOSAL:
                emailSubject = noteOrMeet.emailSubject()+": proposal response ("+getChoice()+")";
            case CommentRecord.COMMENT_TYPE_REQUEST:
                emailSubject = noteOrMeet.emailSubject()+": answer for question";
        }
        
        AddressListEntry ale = commenterProfile.getAddressListEntry();

        clone.write("\n<p>From: ");
        ale.writeLink(clone);
        clone.write("&nbsp; \n    Workspace: ");
        ngp.writeContainerLink(clone, 40);
        clone.write("\n<br/>\nProposal <b>");
        clone.writeHtml(getChoice());
        clone.write("</b> response on a proposal on topic <a href=\"");
        clone.write(topicAddress);
        clone.write("\">");
        clone.writeHtml(noteOrMeet.emailSubject());
        clone.write("</a></p>\n<hr/>\n");

        clone.write(this.getHtml(ar));

        clone.write("<hr/>\nIn Response to the Proposal: <br/>");
        clone.write("\n<div style=\"color:#A9A9A9\">");
        clone.write(cr.getContentHtml(ar));
        clone.write("\n</div>");
        ooa.writeUnsubscribeLink(clone);
        clone.write("</body></html>");
        clone.flush();

        String bodyStr = body.toString();
        mailFile.createEmailRecord(commenterProfile.getEmailWithName(), ooa.getEmail(), emailSubject, bodyStr);
    }

    public JSONObject getJSON(AuthRequest ar) throws Exception {
        JSONObject jo = new JSONObject();
        AddressListEntry ale = new AddressListEntry(getUserId());
        jo.put("user", ale.getUniversalId());
        jo.put("userName", ale.getName());
        jo.put("choice",  getChoice());
        jo.put("html", getHtml(ar));
        return jo;
    }

    public void updateFromJSON(JSONObject input, AuthRequest ar) throws Exception {
        //can not change the user id since that is the key field.
        //user name is not stored here either
        if (input.has("html")) {
            setHtml(ar, input.getString("html"));
        }
        if (input.has("choice")) {
            setChoice(input.getString("choice"));
        }
    }

    public ScheduledNotification getScheduledNotification(NGPage ngp, EmailContext noteOrMeet, CommentRecord cr) {
        return new RRScheduledNotification(ngp, noteOrMeet, cr, this);
    }

    private class RRScheduledNotification implements ScheduledNotification {
        NGPage ngp;
        EmailContext noteOrMeet;
        CommentRecord cr;
        ResponseRecord rr;

        public RRScheduledNotification( NGPage _ngp, EmailContext _noteOrMeet, CommentRecord _cr, ResponseRecord _rr) {
            ngp  = _ngp;
            noteOrMeet = _noteOrMeet;
            cr   = _cr;
            rr   = _rr;
        }
        public boolean needsSending() throws Exception {
            return !rr.getEmailSent();
        }

        public long timeToSend() throws Exception {
            return cr.getTime()+1000;
        }

        public void sendIt(AuthRequest ar, MailFile mailFile) throws Exception {
            rr.responseEmailRecord(ar,ngp,noteOrMeet,cr,mailFile);
        }

        public String selfDescription() throws Exception {
            return "(Response) "+rr.getUserId()+" on "+noteOrMeet.selfDescription();
        }
    }

}
