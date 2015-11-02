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

import java.io.StringWriter;
import java.util.Vector;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.workcast.json.JSONObject;

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
        return getAttributeBool("emailSent");
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
    
    
    public void responseEmailRecord(AuthRequest ar, NGPage ngp, NoteRecord note, CommentRecord cr) throws Exception {
        Vector<OptOutAddr> sendTo = new Vector<OptOutAddr>();
        OptOutAddr.appendUsersFromRole(ngp, "Members", sendTo);

        AddressListEntry commenter = new AddressListEntry(getUserId());
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
        String emailSubject = note.getSubject()+": NEW Proposal Response";
        AddressListEntry ale = commenterProfile.getAddressListEntry();
        
        clone.write("\n<p><b>From: ");
        ale.writeLink(clone);
        clone.write("&nbsp; \n    <b>Workspace:</b> ");
        ngp.writeContainerLink(clone, 40);
        clone.write("\n</p>\n<p><b>New Proposal Response</b> on topic <a href=\"");
        clone.write(topicAddress);
        clone.write("\">");
        clone.writeHtml(note.getSubject());
        clone.write("</a></p>\n<hr/>\n");

        clone.write(this.getHtml(ar));

        clone.write("</body></html>");


        EmailSender.containerEmail(ooa, ngp, emailSubject, bodyWriter.toString(), commenterProfile.getEmailWithName(),
                new Vector<String>(), ar.getCogInstance());
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

    public ScheduledNotification getScheduledNotification(NGPage ngp, NoteRecord note, CommentRecord cr) {
        return new RRScheduledNotification(ngp, note, cr, this);
    }
    
    private class RRScheduledNotification implements ScheduledNotification {
        NGPage ngp;
        NoteRecord note;
        CommentRecord cr;
        ResponseRecord rr;
        
        public RRScheduledNotification( NGPage _ngp, NoteRecord _note, CommentRecord _cr, ResponseRecord _rr) {
            ngp  = _ngp;
            note = _note;
            cr   = _cr;
            rr   = _rr;
        }
        public boolean isSent() throws Exception {
            return rr.getEmailSent();
        }
        
        public long timeToSend() throws Exception {
            return cr.getTime()+300000;
        }
        
        public void sendIt(AuthRequest ar) throws Exception {
            rr.responseEmailRecord(ar,ngp,note,cr);
        }
    }
    
}
