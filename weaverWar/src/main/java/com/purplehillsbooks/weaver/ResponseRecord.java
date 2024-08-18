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

package com.purplehillsbooks.weaver;

import java.util.ArrayList;
import java.util.List;

import com.purplehillsbooks.weaver.mail.ChunkTemplate;
import com.purplehillsbooks.weaver.mail.EmailSender;
import com.purplehillsbooks.weaver.mail.MailInst;
import com.purplehillsbooks.weaver.mail.OptOutAddr;
import com.purplehillsbooks.weaver.mail.ScheduledNotification;
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
            System.out.println("ResponseRecord Migration: will never send email due "+SectionUtil.getNicePrintDate(getTime()));
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
    public boolean isEmpty() {
        String body = getContent();
        if (body==null) {
            return true;
        }
        return body.length()==0;
    }

    public void responseEmailRecord(AuthRequest ar, NGWorkspace ngw, EmailContext noteOrMeet, CommentRecord cr, EmailSender mailFile) throws Exception {
        List<OptOutAddr> sendTo = new ArrayList<OptOutAddr>();
        noteOrMeet.appendTargetEmails(sendTo, ngw);

        //add the commenter in case missing from the target role
        AddressListEntry commenter1 = cr.getUser();
        OptOutAddr.appendOneDirectUser(commenter1, sendTo);


        AddressListEntry responder = new AddressListEntry(getUserId());
        UserProfile commenterProfile = responder.getUserProfile();
        if (commenterProfile==null || !commenterProfile.hasLoggedIn()) {
            System.out.println("DATA PROBLEM: proposal response came from a person who has not logged in ("+getUserId()+") ignoring");
            setEmailSent(true);
            return;
        }

        for (OptOutAddr ooa : sendTo) {
            constructEmailRecordOneUser(ar, ngw, noteOrMeet, ooa, cr, commenterProfile, mailFile);
        }
        setEmailSent(true);
    }

    private void constructEmailRecordOneUser(AuthRequest ar, NGWorkspace ngw, EmailContext noteOrMeet, OptOutAddr ooa,
            CommentRecord cr, UserProfile commenterProfile, EmailSender mailFile) throws Exception  {

        if (!ooa.hasEmailAddress()) {
            return;  //ignore users without email addresses
        }

        UserManager.getStaticUserManager();
        UserProfile toProfile = UserManager.lookupUserByAnyId(ooa.getEmail());
        if (toProfile!=null) {
            ar.getCogInstance().getUserCacheMgr().needRecalc(toProfile);
        }
        AddressListEntry owner = new AddressListEntry(this.getUserId());
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
        clone.retPath = ar.baseURL;


        JSONObject data = new JSONObject();
        data.put("baseURL", ar.baseURL);
        data.put("parentURL", ar.baseURL + noteOrMeet.getEmailURL(clone, ngw));
        data.put("parentName", noteOrMeet.emailSubject());
        data.put("commentURL", ar.baseURL + ar.getResourceURL(ngw,  "CommentZoom.htm?cid="+cr.getTime()));
        data.put("comment", cr.getJSONWithDocs(ngw));
        data.put("response", this.getJSON());
        data.put("choice", this.getChoice());
        data.put("wsBaseURL", ar.baseURL + clone.getWorkspaceBaseURL(ngw));
        data.put("isProposal", isProposal);
        data.put("wsName", ngw.getFullName());
        data.put("userURL", ar.baseURL + owner.getLinkUrl());
        data.put("userName", owner.getName());
        data.put("optout", ooa.getUnsubscribeJSON(clone));

        ChunkTemplate.streamAuthRequest(clone.w, ar, "NewResponse", data, ooa.getCalendar());
        clone.flush();

        MailInst mailMsg = ngw.createMailInst();
        mailMsg.setSubject(noteOrMeet.emailSubject()+": "+detailMsg);
        mailMsg.setBodyText(body.toString());

        mailFile.createEmailRecordInDB(mailMsg, commenterProfile.getAddressListEntry(), ooa.getEmail());
    }

    public JSONObject getJSON() throws Exception {
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
        jo.put("body", getContent());
        jo.put("time", getTime());
        return jo;
    }

    public void updateFromJSON(JSONObject input, AuthRequest ar) throws Exception {
        //can not change the user id since that is the key field.
        //user name and key is not stored here either
        if (input.has("body")) {
            setContent(input.getString("body"));
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
        @Override
        public boolean needsSendingBefore(long timeout) throws Exception {
            //return !rr.getEmailSent();
            //
            //April 2017 changed to never send email to reduce flood.
            //however if we get a nicer notification system, it might be nice to
            //at least notify the users.
            return false;
        }

        @Override
        public long futureTimeToSend() throws Exception {
            return -1;
        }

        @Override
        public void sendIt(AuthRequest ar, EmailSender mailFile) throws Exception {
            rr.responseEmailRecord(ar,ngw,noteOrMeet,cr,mailFile);
        }

        @Override
        public String selfDescription() throws Exception {
            return "(Response) "+rr.getUserId()+" on "+noteOrMeet.selfDescription();
        }
    }

}
