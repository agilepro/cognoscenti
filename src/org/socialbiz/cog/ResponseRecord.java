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

import java.io.File;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import org.socialbiz.cog.mail.ChunkTemplate;
import org.socialbiz.cog.mail.MailFile;
import org.socialbiz.cog.mail.ScheduledNotification;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.MemFile;

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
        if (getTime() < TopicRecord.ONE_WEEK_AGO) {
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


    public void responseEmailRecord(AuthRequest ar, NGWorkspace ngw, EmailContext noteOrMeet, CommentRecord cr, MailFile mailFile) throws Exception {
        List<OptOutAddr> sendTo = new ArrayList<OptOutAddr>();
        noteOrMeet.appendTargetEmails(sendTo, ngw);

        //add the commenter in case missing from the target role
        AddressListEntry commenter1 = cr.getUser();
        OptOutAddr.appendOneDirectUser(commenter1, sendTo);


        AddressListEntry responder = new AddressListEntry(getUserId());
        UserProfile commenterProfile = responder.getUserProfile();
        if (commenterProfile==null) {
            System.out.println("DATA PROBLEM: proposal response came from a person without a profile ("+getUserId()+") ignoring");
            setEmailSent(true);
            return;
        }

        for (OptOutAddr ooa : sendTo) {
            constructEmailRecordOneUser(ar, ngw, noteOrMeet, ooa, cr, commenterProfile, mailFile);
        }
        setEmailSent(true);
    }

    private void constructEmailRecordOneUser(AuthRequest ar, NGWorkspace ngw, EmailContext noteOrMeet, OptOutAddr ooa,
            CommentRecord cr, UserProfile commenterProfile, MailFile mailFile) throws Exception  {

        if (!ooa.hasEmailAddress()) {
            return;  //ignore users without email addresses
        }

        Cognoscenti cog = ar.getCogInstance();
        UserProfile toProfile = UserManager.findUserByAnyId(ooa.getEmail());
        if (toProfile!=null) {
            ar.getCogInstance().getUserCacheMgr().needRecalc(toProfile);
        }
        AddressListEntry owner = new AddressListEntry(this.getUserId());
        UserProfile ownerProfile = cog.getUserManager().lookupUserByAnyId(this.getUserId());
        String detailMsg = "??";
        boolean isProposal = false;
        switch (cr.getCommentType()) {
            case CommentRecord.COMMENT_TYPE_PROPOSAL:
                detailMsg = "Proposal ("+getChoice()+") response";
                isProposal = true;
                break;
            case CommentRecord.COMMENT_TYPE_REQUEST:
                detailMsg = "Quick round response";

        }
        
        
        

        MemFile body = new MemFile();
        AuthRequest clone = new AuthDummy(commenterProfile, body.getWriter(), ar.getCogInstance());
        clone.setNewUI(true);
        clone.retPath = ar.baseURL;
        
        
        JSONObject data = new JSONObject();
        data.put("baseURL", ar.baseURL);
        data.put("parentURL", ar.baseURL + noteOrMeet.getEmailURL(clone, ngw));
        data.put("parentName", noteOrMeet.emailSubject());
        data.put("commentURL", ar.baseURL + noteOrMeet.getEmailURL(clone, ngw)+ "#cmt" + getTime());
        data.put("comment", cr.getHtmlJSON(ar));
        data.put("response", this.getJSON(ar));
        data.put("choice", this.getChoice());
        data.put("wsURL", ar.baseURL + clone.getDefaultURL(ngw));
        data.put("isProposal", isProposal);
        data.put("wsName", ngw.getFullName());
        if (ownerProfile!=null) {
            data.put("userURL", ar.baseURL + "v/"+ownerProfile.getKey()+"/userSettings.htm");
            data.put("userName", ownerProfile.getName());
        }
        else {
            data.put("userURL", ar.baseURL + "v/FindPerson.htm?uid="+owner.getUniversalId());
            data.put("userName", owner.getUniversalId());
        }
        //data.put("cmtType", cmtType);
        data.put("outcomeHtml", cr.getOutcomeHtml(clone));
        data.put("optout", ooa.getUnsubscribeJSON(clone));

        File emailFolder = cog.getConfig().getFileFromRoot("email");
        File templateFile = new File(emailFolder, "NewResponse.chtml");
        if (!templateFile.exists()) {
            throw new Exception("Strange, the template file is missing: "+templateFile);
        }

        ChunkTemplate.streamIt(clone.w, templateFile, data, ooa.getCalendar());
        clone.flush();
        
        String bodyStr = body.toString();
        String emailSubject =  noteOrMeet.emailSubject()+": "+detailMsg;
        mailFile.createEmailRecord(commenterProfile.getAddressListEntry(), ooa.getEmail(), emailSubject, bodyStr);
    }

    public JSONObject getJSON(AuthRequest ar) throws Exception {
        JSONObject jo = new JSONObject();
        AddressListEntry ale = new AddressListEntry(getUserId());
        jo.put("alt", ale.getJSON());
        jo.put("user", ale.getUniversalId());
        jo.put("userName", ale.getName());
        if (ale.user!=null) {
            jo.put("key", ale.user.getKey());
        }
        jo.put("userName", ale.getName());
        jo.put("choice",  getChoice());
        jo.put("html", getHtml(ar));
        jo.put("time", getTime());
        return jo;
    }

    public void updateFromJSON(JSONObject input, AuthRequest ar) throws Exception {
        //can not change the user id since that is the key field.
        //user name and key is not stored here either
        if (input.has("html")) {
            setHtml(ar, input.getString("html"));
        }
        if (input.has("choice")) {
            setChoice(input.getString("choice"));
        }
    }

    public ScheduledNotification getScheduledNotification(NGWorkspace ngw, EmailContext noteOrMeet, CommentRecord cr) {
        return new RRScheduledNotification(ngw, noteOrMeet, cr, this);
    }

    private class RRScheduledNotification implements ScheduledNotification {
        NGWorkspace ngw;
        EmailContext noteOrMeet;
        CommentRecord cr;
        ResponseRecord rr;

        public RRScheduledNotification( NGWorkspace _ngp, EmailContext _noteOrMeet, CommentRecord _cr, ResponseRecord _rr) {
            ngw  = _ngp;
            noteOrMeet = _noteOrMeet;
            cr   = _cr;
            rr   = _rr;
        }
        public boolean needsSending() throws Exception {
            //return !rr.getEmailSent();
            //
            //April 2017 changed to never send email to reduce flood.
            //however if we get a nicer notification system, it might be nice to 
            //at least notify the users.
            return false;
        }

        public long timeToSend() throws Exception {
            return cr.getTime()+1000;
        }

        public void sendIt(AuthRequest ar, MailFile mailFile) throws Exception {
            rr.responseEmailRecord(ar,ngw,noteOrMeet,cr,mailFile);
        }

        public String selfDescription() throws Exception {
            return "(Response) "+rr.getUserId()+" on "+noteOrMeet.selfDescription();
        }
    }

}
