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

package com.purplehillsbooks.weaver.mail;

import java.io.File;
import java.io.FileInputStream;
import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;

import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.AttachmentRecord;
import com.purplehillsbooks.weaver.AttachmentVersion;
import com.purplehillsbooks.weaver.DOMFace;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.exception.NGException;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.MemFile;

/**
 * This class represents an email message in the ngPage world.
 * Operations that happen in the page, will create an email message
 * of this type, and store it in the page for delivery.
 *
 * Constructing and storing this message is expected to be fast,
 * reliable, and part of the same transaction that updates the
 * page.
 *
 * A separate thread will wake up, take the message from the page
 * deleting it here, and adding it to the mail archive file.
 * Then mail messages in the archive file are sent to the email
 * service.
 *
 */
public class EmailRecord extends DOMFace
{

    public static final String READY_TO_GO = "Ready";
    public static final String SENT = "Sent";
    public static final String FAILED = "Failed";
    public static final String SKIPPED = "Skipped";
    public static final String RECEIVED = "Received";

    private Hashtable<String, MemFile> attachmentContents;
    private Hashtable<String, File>    attachmentPaths;

    public EmailRecord(Document doc, Element upEle, DOMFace p)
    {
        super(doc,upEle, p);
    }

    public String getId()
    {
        String val = getAttribute("id");
        if (val==null)
        {
            return "";
        }
        return val;
    }
    public void setId(String id)
    {
        setAttribute("id", id);
    }

    public String getFromAddress() {
        return getAttribute("fromAddress");
    }
    public void setFromAddress(String fromAddress) {
        setAttribute("fromAddress",fromAddress);
    }

    public List<OptOutAddr> getAddressees() throws Exception {
        List<DOMFace> children = getChildren("to", DOMFace.class);

        ArrayList<OptOutAddr> res = new ArrayList<OptOutAddr>();
        for (DOMFace assignee : children) {

            String ootype = assignee.getAttribute("ootype");
            String email = assignee.getAttribute("email");
            AddressListEntry ale = AddressListEntry.parseCombinedAddress(email);
            if (!ale.isWellFormed()) {
                continue;
            }
            if ("Role".equals(ootype)) {
                String containerID = assignee.getAttribute("containerID");
                String siteID = assignee.getAttribute("siteID");
                String roleName = assignee.getAttribute("roleName");
                res.add(new OptOutRolePlayer(ale, siteID, containerID, roleName));
            }
            else if ("Super".equals(ootype)) {
                res.add(new OptOutSuperAdmin(ale));
            }
            else if ("Indiv".equals(ootype)) {
                res.add(new OptOutIndividualRequest(ale));
            }
            else if ("Direct".equals(ootype)) {
                res.add(new OptOutDirectAddress(ale));
            }
            else {
                res.add(new OptOutAddr(ale));
            }
        }
        return res;
    }


    /**
     * Sets this email to go to a single address.
     */
    public void setAddress(OptOutAddr ooa) throws Exception {
        removeAllNamedChild("to");

        DOMFace assignee = createChild("to", DOMFace.class);
        assignee.setAttribute("email", ooa.getEmail());
        if (ooa instanceof OptOutRolePlayer) {
            OptOutRolePlayer oorm = (OptOutRolePlayer) ooa;
            assignee.setAttribute("ootype", "Role");
            assignee.setAttribute("containerID", oorm.containerID);
            assignee.setAttribute("siteID", oorm.siteID);
            assignee.setAttribute("roleName", oorm.roleName);
        }
        else if (ooa instanceof OptOutSuperAdmin) {
            assignee.setAttribute("ootype", "Super");
        }
        else if (ooa instanceof OptOutIndividualRequest) {
            assignee.setAttribute("ootype", "Indiv");
        }
        else if (ooa instanceof OptOutDirectAddress) {
            assignee.setAttribute("ootype", "Direct");
        }
        else {
            assignee.setAttribute("ootype", "Gen");
        }
    }
    
    public void setAddressees(List<OptOutAddr> inad) throws Exception {
        removeAllNamedChild("to");
        for (OptOutAddr ooa : inad) {

            DOMFace assignee = createChild("to", DOMFace.class);
            assignee.setAttribute("email", ooa.getEmail());
            if (ooa instanceof OptOutRolePlayer) {
                OptOutRolePlayer oorm = (OptOutRolePlayer) ooa;
                assignee.setAttribute("ootype", "Role");
                assignee.setAttribute("containerID", oorm.containerID);
                assignee.setAttribute("siteID", oorm.siteID);
                assignee.setAttribute("roleName", oorm.roleName);
            }
            else if (ooa instanceof OptOutSuperAdmin) {
                assignee.setAttribute("ootype", "Super");
            }
            else if (ooa instanceof OptOutIndividualRequest) {
                assignee.setAttribute("ootype", "Indiv");
            }
            else if (ooa instanceof OptOutDirectAddress) {
                assignee.setAttribute("ootype", "Direct");
            }
            else {
                assignee.setAttribute("ootype", "Gen");
            }
        }
    }

    public String getCcAddress() {
        return getScalar("ccAddress");
    }
    public void setCcAddress(String ccAddress) {
        setScalar("ccAddress",ccAddress);
    }

    /**
    * The body is the message without the unsubscribe part
    */
    public String getBodyText() {
        return getScalar("bodyText");
    }
    public void setBodyText(String bodyText) {
        setScalar("bodyText",bodyText);
    }

    public String getStatus() {
        return getAttribute("status");
    }
    public void setStatus(String status) {
        setAttribute("status",status);
    }
    public boolean statusReadyToSend() {
        return READY_TO_GO.equals(getAttribute("status"));
    }

    public String getErrorMessage() {
        return getScalar("error");
    }
    public void setErrorMessage(String err) {
        setScalar("error", err);
    }

    public long getLastSentDate() {
        return safeConvertLong(getAttribute("lastSentDate"));
    }
    public void setLastSentDate(long sentDate) {
        setAttribute("lastSentDate",String.valueOf(sentDate));
    }

    public String getSubject() {
        return getAttribute("subject");
    }
    public void setSubject(String subject) {
        setAttribute("subject",subject);
    }

    public String getProjectId() {
        return getAttribute("projectId");
    }
    public void setProjectId(String projectId) {
        setAttribute("projectId",projectId);
    }

    public long getCreateDate() {
        return safeConvertLong(getAttribute("createDate"));
    }
    public void setCreateDate(long createDate) {
        setAttribute("createDate",String.valueOf(createDate));
    }

    public String getExceptionMessage() {
        return getScalar("exception");
    }
    public void setExceptionMessage(Exception e) {
        setScalar("exception", NGException.getFullMessage(e));
    }

    public List<String> getAttachmentIds() {
        return getVector("attachid");
    }
    public void setAttachmentIds(List<String> ids) {
        setVector("attachid", ids);
    }


    /**
     * Read attachments into cache so that all the information to send
     * a file is held in memory and there is no chance for failure.
     */
    public void prepareForSending(NGWorkspace ngw) throws Exception {
        attachmentContents = new Hashtable<String, MemFile>();
        attachmentPaths = new Hashtable<String, File>();

        for (String oneId : getAttachmentIds()) {

            AttachmentRecord attach = ngw.findAttachmentByID(oneId);
            if (attach==null) {
                //attachments might get removed in the mean time, just ignore them
                continue;
            }
            AttachmentVersion aVer = attach.getLatestVersion(ngw);
            if (aVer==null) {
                continue;
            }
            File attachFile = aVer.getLocalFile();
            if (!attachFile.exists()) {
                continue;
            }
            attachmentPaths.put(oneId,  attachFile);

            MemFile thisContent = new MemFile();
            thisContent.fillWithInputStream(new FileInputStream(attachFile));
            attachmentContents.put(oneId, thisContent);
       }
    }

    public void clearCache() throws Exception {
        attachmentContents = null;
        attachmentPaths = null;
    }

    /**
     * If the EailRecord is 'prepared' for sending, then you can get the file path for an attachment.
     * Returns null if for any reason it was not able to find attachment or it had no latest version.
     */
    public File getAttachPath(String attId) throws Exception  {
        if (attachmentPaths==null) {
            throw new Exception("EmailRecord object has not been prepared for sending, and so can not return attachment paths.");
        }
        return attachmentPaths.get(attId);
    }

    /**
     * If the EailRecord is 'prepared' for sending, then you can get the contents of an attachment
     * from the MemFile returned by this method.
     * Returns null if for any reason it was not able to find and get the contents.
     */
    public MemFile getAttachContents(String attId) throws Exception  {
        if (attachmentContents==null) {
            throw new Exception("EmailRecord object has not been prepared for sending, and so can not return attachment contents.");
        }
        MemFile mf = attachmentContents.get(attId);
        if (mf==null) {
            return null;
        }
        return mf;
    }


    public JSONObject getJSON() throws Exception {
        JSONObject obj = new JSONObject();
        obj.put("from", getFromAddress());
        obj.put("subject", getSubject());
        JSONArray toList = new JSONArray();
        for (OptOutAddr ooa : getAddressees()) {
            toList.put(ooa.getEmail());
        }
        obj.put("to", toList);
        obj.put("status", getStatus());
        obj.put("sendDate", getLastSentDate());
        obj.put("error", getErrorMessage());

        return obj;
    }



}
