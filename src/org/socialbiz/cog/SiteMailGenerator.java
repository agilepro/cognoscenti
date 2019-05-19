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
import java.util.List;

import org.socialbiz.cog.mail.ChunkTemplate;
import org.socialbiz.cog.mail.MailFile;
import org.socialbiz.cog.mail.ScheduledNotification;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.MemFile;

/**
 * Email set to the owners and executives of a site
 * at various times.
 */
public class SiteMailGenerator extends DOMFace {

    public SiteMailGenerator(Document nDoc, Element nEle, DOMFace p) {
        super(nDoc, nEle, p);
    }

    public String getId() throws Exception {
        return getAttribute("id");
    }

    public void setId(String newVal) throws Exception {
        setAttribute("id", newVal);
    }

    public final int EG_STATE_DRAFT     = 1;
    public final int EG_STATE_SCHEDULED = 2;
    public final int EG_STATE_SENT      = 3;

    public int getState() {
        return getAttributeInt("state");
    }
    public void setState(int newVal) {
        setAttributeInt("state", newVal);
    }


    public String getLayoutName() throws Exception {
        return getScalar("layout");
    }
    public void setLayoutName(String newVal) throws Exception {
        setScalar("layout", newVal);
    }


    public String getSubject() throws Exception {
        return getScalar("subject");
    }
    public void setSubject(String newVal) throws Exception {
        setScalar("subject", newVal);
    }



    public long getSendDate() throws Exception {
        return safeConvertLong(getScalar("sendDate"));
    }
    public void setSendDate(long newVal) throws Exception {
        setScalar("sendDate", Long.toString(newVal));
    }


    /**
     * Different people will be receiving email for different reasons ... they might be in
     * a particular role, or they might be addressed directly.   This returns the right
     * OptOutAddress object for the given user ID.
     */
    public OptOutAddr getOOAForUserID(AuthRequest ar, NGBook ngb, String userId) throws Exception {
        for (OptOutAddr ooa : expandAddresses(ar, ngb)) {
            if (ooa.matches(userId))  {
                return ooa;
            }
        }

        //didn't find them, then act as if they were directly added
        return new OptOutDirectAddress(new AddressListEntry(userId));
    }


    public List<OptOutAddr> expandAddresses(AuthRequest ar, NGBook ngb) throws Exception {
        List<OptOutAddr> collector = new ArrayList<OptOutAddr>();
        NGRole prime = ngb.getPrimaryRole();
        OptOutAddr.appendUsersFromSiteRole(prime, ngb, collector);
        NGRole second = ngb.getSecondaryRole();
        OptOutAddr.appendUsersFromSiteRole(second, ngb, collector);
        return collector;
    }


    public void constructEmailRecords(AuthRequest ar, NGBook ngb, MailFile mailFile) throws Exception {
        List<OptOutAddr> sendTo = expandAddresses(ar, ngb);

        StringBuilder historyNameList = new StringBuilder();
        boolean needComma = false;
        for (OptOutAddr ooa : sendTo) {
            String addr = ooa.getEmail();
            if (addr!=null && addr.length()>0) {
                constructEmailRecordOneUser(ar, ngb, ooa, mailFile);
                if (needComma) {
                    historyNameList.append(",");
                }
                historyNameList.append(addr);
                needComma= true;
            }
        }
        setState(EG_STATE_SENT);
        setSendDate(ar.nowTime);
    }

    private void constructEmailRecordOneUser(AuthRequest ar, NGBook ngb, OptOutAddr ooa, MailFile mailFile)
            throws Exception  {
        String userAddress = ooa.getEmail();
        if (userAddress==null || userAddress.length()==0) {
            //don't send anything if the user does not have an email address
            return;
        }
        UserProfile originalSender = ar.getUserProfile();
        if (originalSender==null) {
            System.out.println("DATA PROBLEM: email generator got AuthRequest object without user");
            return;
        }

        String[] subjAndBody = generateEmailBody(ar, ngb, ooa);
        String subject = subjAndBody[0];
        String entireBody = subjAndBody[1];

        List<File> noAttachments = new ArrayList<File>();

        mailFile.createEmailWithAttachments(originalSender.getAddressListEntry(), ooa.getEmail(), 
                subject, entireBody, noAttachments);
    }


    public String[] generateEmailBody(AuthRequest ar, NGBook ngb, OptOutAddr ooa) throws Exception {

        String[] ret = new String[2];

        MemFile bodyChunk = new MemFile();
        UserProfile originalSender = ar.getUserProfile();

        AuthRequest clone = new AuthDummy(originalSender, bodyChunk.getWriter(), ar.getCogInstance());
        clone.setNewUI(true);
        clone.retPath = ar.baseURL;
        clone.setPageAccessLevels(ngb);

        JSONObject data = getJSONForTemplate(clone, ngb, ooa.getAssignee());

        writeNoteAttachmentEmailBody2(clone, ooa, data);
        clone.flush();
        ret[1] = bodyChunk.toString();

        ret[0] = ChunkTemplate.stringIt(getSubject(), data, ooa.getCalendar());

        return ret;
    }

    private JSONObject getJSONForTemplate(AuthRequest ar, NGBook ngb, AddressListEntry ale) throws Exception {
        //Gather all the data into a JSON structure
        JSONObject data = new JSONObject();
        data.put("baseURL", ar.baseURL);
        UserProfile originalSender = ar.getUserProfile();
        if (originalSender==null) {
            throw new Exception("AuthRequest object must have a logged in user");
		}

        String workspaceBaseUrl = ar.baseURL + "t/" + ngb.getKey() + "/$/";
        data.put("workspaceName", ngb.getFullName());
        data.put("workspaceUrl", workspaceBaseUrl);

		ar.ngp = ngb;

        return data;
    }

    private void writeNoteAttachmentEmailBody2(AuthRequest ar,
            OptOutAddr ooa, JSONObject data) throws Exception {

        data.put("optout", ooa.getUnsubscribeJSON(ar));

        File myTemplate = ar.getCogInstance().getConfig().getFileFromRoot("email/DiscussionTopicManual.chtml");
        ChunkTemplate.streamIt(ar.w, myTemplate, data, ooa.getCalendar());
    }

    public JSONObject getJSON(AuthRequest ar, NGWorkspace ngw) throws Exception {
        JSONObject obj = new JSONObject();
        obj.put("id", getId());
        obj.put("subject", getSubject());
        obj.put("state", getState());
        obj.put("sendDate", getSendDate());

        JSONArray toList = new JSONArray();
        obj.put("alsoTo", toList);

        this.extractAttributeString(obj, "tasksOption");
        this.extractScalarString(obj, "tasksFilter");
        this.extractVectorString(obj, "tasksLabels");
        this.extractAttributeBool(obj, "tasksFuture");
        this.extractAttributeBool(obj, "tasksCompleted");
        this.extractScalarString(obj, "meetingLayout");
        return obj;
    }

    public void updateFromJSON(JSONObject obj) throws Exception {
        if (obj.has("subject")) {
            setSubject(obj.getString("subject"));
        }

        //NO SET STATE from JSON!!

        if (obj.has("sendDate")) {
            setSendDate(obj.getLong("sendDate"));
        }
        this.updateAttributeString("tasksOption", obj);
        this.updateScalarString("tasksFilter", obj);
        this.updateVectorString("tasksLabels", obj);
        this.updateAttributeBool("tasksFuture", obj);
        this.updateAttributeBool("tasksCompleted", obj);
        this.updateScalarString("meetingLayout", obj);
    }

    public void gatherUnsentScheduledNotification(NGBook ngb, ArrayList<ScheduledNotification> resList) throws Exception {
        if (getState()==EG_STATE_SCHEDULED) {
            SiteMailNotification sn = new SiteMailNotification(ngb, this);
            resList.add(sn);
        }
    }


    private class SiteMailNotification implements ScheduledNotification {
        private NGBook ngb;
        private SiteMailGenerator eg;

        public SiteMailNotification( NGBook _ngb, SiteMailGenerator _eg) {
            ngb  = _ngb;
            eg = _eg;
        }
        public boolean needsSending() throws Exception {
            return eg.getState()!=EG_STATE_SENT;
        }

        public long timeToSend() throws Exception {
            return System.currentTimeMillis();
        }

        public void sendIt(AuthRequest ar, MailFile mailFile) throws Exception {
            eg.constructEmailRecords(ar, ngb, mailFile);
        }

        public String selfDescription() throws Exception {
            return "(Email Generator) "+eg.getSubject();
        }
    }

}
