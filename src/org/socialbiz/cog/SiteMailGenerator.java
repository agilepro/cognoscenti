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
import java.io.FileInputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

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

    public static final int SM_STATE_DRAFT     = 1;
    public static final int SM_STATE_SCHEDULED = 2;
    public static final int SM_STATE_SENT      = 3;

    public int getState() {
        return getAttributeInt("state");
    }
    public void setState(int newVal) {
        setAttributeInt("state", newVal);
    }


    public String getLayoutName() throws Exception {
        return getAttribute("layout");
    }
    public void setLayoutName(String newVal) throws Exception {
        setAttribute("layout", newVal);
    }


    public String getSubject() throws Exception {
        return getAttribute("subject");
    }
    public void setSubject(String newVal) throws Exception {
        setAttribute("subject", newVal);
    }



    public long getSendDate() throws Exception {
        return getAttributeLong("sendDate");
    }
    public void setSendDate(long newVal) throws Exception {
        setAttributeLong("sendDate", newVal);
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
        OptOutSiteExec.appendUsersFromSiteRole(prime, ngb, collector);
        NGRole second = ngb.getSecondaryRole();
        OptOutSiteExec.appendUsersFromSiteRole(second, ngb, collector);
        return collector;
    }


    public void constructEmailRecords(AuthRequest ar, NGBook ngb, MailFile mailFile) throws Exception {
        List<OptOutAddr> sendTo = expandAddresses(ar, ngb);

        StringBuilder historyNameList = new StringBuilder();
        boolean needComma = false;
        for (OptOutAddr ooa : sendTo) {
            String addr = ooa.getEmail();
            if (addr==null || addr.length()==0) {
                System.out.println("STRANGE: got site mail address with email address?? "+ooa.assignee.rawAddress);
            }
            else {
                constructEmailRecordOneUser(ar, ngb, ooa, mailFile);
                if (needComma) {
                    historyNameList.append(",");
                }
                historyNameList.append(addr);
                needComma= true;
            }
        }
        System.out.println("  SITE MAIL SENT: "+this.getLayoutName()+" to ("+historyNameList+")");
        setState(SM_STATE_SENT);
        setSendDate(ar.nowTime);
    }

    private void constructEmailRecordOneUser(AuthRequest ar, NGBook ngb, OptOutAddr ooa, MailFile mailFile)
            throws Exception  {
        String userAddress = ooa.getEmail();
        if (userAddress==null || userAddress.length()==0) {
            //don't send anything if the user does not have an email address
            return;
        }
        String from = getAttribute("from");
        if (from==null || from.length()==0) {
            File emailPropFile = ar.getCogInstance().getConfig().getFile("EmailNotification.properties");
            Properties emailProperties = new Properties();
            FileInputStream fis = new FileInputStream(emailPropFile);
            emailProperties.load(fis);
            from = emailProperties.getProperty("mail.smtp.from");
        }

        String[] subjAndBody = generateEmailBody(ar, ngb, ooa);
        String subject = subjAndBody[0];
        String entireBody = subjAndBody[1];

        List<File> noAttachments = new ArrayList<File>();

        mailFile.createEmailWithAttachments(new AddressListEntry(from), ooa.getEmail(), 
                subject, entireBody, noAttachments);
        System.out.println("SiteMail was sent to ("+ooa.getEmail()+") "+subject);
    }


    public String[] generateEmailBody(AuthRequest ar, NGBook ngb, OptOutAddr ooa) throws Exception {

        String[] ret = new String[2];

        MemFile bodyChunk = new MemFile();
        UserProfile originalSender = ar.getUserProfile();

        AuthRequest clone = new AuthDummy(originalSender, bodyChunk.getWriter(), ar.getCogInstance());
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
        data.put("baseUrl", ar.baseURL);

        
        JSONObject siteJSON = ngb.getConfigJSON();
        JSONArray projList = new JSONArray();
        for (NGPageIndex ngpi : ar.getCogInstance().getAllProjectsInSite(ngb.getKey())) {
            if (!ngpi.isProject()) {
                continue;
            }
            projList.put(ngpi.getJSON4List());
        }
        siteJSON.put("workspaces", projList);
        siteJSON.put("stats", ngb.getStatsJSON(ar.getCogInstance()));
        data.put("site", siteJSON);

        
        //String workspaceBaseUrl = ar.baseURL + "t/" + ngb.getKey() + "/$/";
        //data.put("workspaceName", ngb.getFullName());
        //data.put("workspaceUrl", workspaceBaseUrl);
        //data.put("site", ngb.getJSON());

        ar.ngp = ngb;

        return data;
    }

    private void writeNoteAttachmentEmailBody2(AuthRequest ar,
            OptOutAddr ooa, JSONObject data) throws Exception {

        data.put("optout", ooa.getUnsubscribeJSON(ar));

        File myTemplate = ar.getCogInstance().getConfig().getFileFromRoot("siteLayouts/"+getLayoutName());
        ChunkTemplate.streamIt(ar.w, myTemplate, data, ooa.getCalendar());
    }

    public JSONObject getJSON() throws Exception {
        JSONObject obj = new JSONObject();
        this.extractAttributeString(obj, "id");
        this.extractAttributeString(obj, "subject");
        this.extractAttributeInt(obj, "state");
        this.extractAttributeLong(obj, "sendDate");
        this.extractAttributeString(obj, "layout");
        this.extractAttributeString(obj, "from");
        return obj;
    }

    public void updateFromJSON(JSONObject obj) throws Exception {
        this.updateAttributeString("subject", obj);
        this.updateAttributeInt("state", obj);
        this.updateAttributeLong("sendDate", obj);
        this.updateAttributeString("layout", obj);
        this.updateAttributeString("from", obj);
    }

    public void gatherUnsentScheduledNotification(NGBook ngb, ArrayList<ScheduledNotification> resList, long timeout) throws Exception {
        if (getState()==SM_STATE_SCHEDULED) {
            SiteMailNotification sn = new SiteMailNotification(ngb, this);
            if (sn.needsSendingBefore(timeout)) {
                resList.add(sn);
            }
        }
    }


    private class SiteMailNotification implements ScheduledNotification {
        private NGBook ngb;
        private SiteMailGenerator eg;

        public SiteMailNotification( NGBook _ngb, SiteMailGenerator _eg) {
            ngb  = _ngb;
            eg = _eg;
        }
        @Override
        public boolean needsSendingBefore(long timeout) throws Exception {
            return eg.getState()!=SM_STATE_SENT;
        }

        @Override
        public long futureTimeToSend() throws Exception {
            if (eg.getState()!=SM_STATE_SENT) {
                return System.currentTimeMillis() - 100000;  //one hundred seconds ago
            }
            else {
                return -1;
            }
        }

        @Override
        public void sendIt(AuthRequest ar, MailFile mailFile) throws Exception {
            System.out.println("  SENDIT called on "+selfDescription());
            eg.constructEmailRecords(ar, ngb, mailFile);
        }

        @Override
        public String selfDescription() throws Exception {
            if (eg.getState()!=SM_STATE_SENT) {
                return "(Site Mail READY) "+eg.getLayoutName();
            }
            else {
                return "(Site Mail SENT)  "+eg.getLayoutName();
            }
        }
    }

}
