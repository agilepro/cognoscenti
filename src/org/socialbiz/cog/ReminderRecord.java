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
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.List;

import org.socialbiz.cog.mail.EmailSender;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.workcast.json.JSONObject;

/**
* ReminderRecord hold the information about a reminder to attach a file
* to a page.  It is assigned to a person (email address) and then email
* messages can be sent to that person reminding them that they have a
* file that needs to be uploaded to the shared place.
*/
public class ReminderRecord extends DOMFace
{
    public ReminderRecord(Document doc, Element definingElement, DOMFace p)
    {
        super (doc, definingElement, p);
    }


    public String getId()
    {
        return checkAndReturnAttributeValue("id");
    }
    public void setId(String id)
    {
        setAttribute("id", id);
    }

    /**
    * Subject is like an email subject
    * This serves as the display name of the request
    */
    public String getSubject()
    {
        return checkAndReturnAttributeValue("subject");
    }
    public void setSubject(String desc)
    {
        setAttribute("subject", desc);
    }

    /**
    * When a virtual attachments is created to be filled in, a person
    * is assigned to fill int he attachment, and reminders will be sent
    * until it is filled.
    */
    public String getAssignee()
    {
        return getAttribute("assignee");
    }
    public void setAssignee(String assignee)
    {
        setAttribute("assignee", assignee);
    }
    public boolean isAssignee(UserProfile up)
    {
        return up.hasAnyId(getAttribute("assignee"));
    }


    /**
    * The instructions are a place that the requester can explain
    * a bit more about what is needed, where they saw the file
    * and anything else that might not be appropriate in the
    * eventual persistent file description.
    */
    public String getInstructions()
    {
        return checkAndReturnAttributeValue("instructions");
    }
    public void setInstructions(String instructions)
    {
        setAttribute("instructions", instructions);
    }

    /**
    * The file name can be proposed by the requester, in
    * the case that a particular naming convention is required
    * on the attachment leaf.
    */
    public String getFileName()
    {
        return checkAndReturnAttributeValue("fileName");
    }
    public void setFileName(String fname)
    {
        setAttribute("fileName", fname);
    }


    /**
    * FileDescription will eventually be the description on the
    * file itself (by default)
    */
    public String getFileDesc()
    {
        return checkAndReturnAttributeValue("fileDesc");
    }
    public void setFileDesc(String description)
    {
        setAttribute("fileDesc", description);
    }


    /**
    * The destination folder is where the file is to be
    * placed.  It is a path notation that indicates
    * the folder name, and the path within it.
    */
    public String getDestFolder()
    {
        return checkAndReturnAttributeValue("folder");
    }
    public void setDestFolder(String fname)
    {
        setAttribute("folder", fname);
    }


    public String getModifiedBy()
    {
        return checkAndReturnAttributeValue("modifiedBy");
    }
    public void setModifiedBy(String modifiedBy)
    {
        setAttribute("modifiedBy", modifiedBy);
    }

    /**
     * This is the date/time that the reminder was originally created
     * or something about it was modified.
     */
    public long getModifiedDate() {
        return safeConvertLong(checkAndReturnAttributeValue("modifiedDate"));
    }
    public void setModifiedDate(long modifiedDate) {
        setAttribute("modifiedDate", Long.toString(modifiedDate));
    }



    /**
     * This is the date that the last email message was sent
     * reminding the assignee about file to upload.
     */
    public long getLastReminderDate() {
        return safeConvertLong(checkAndReturnAttributeValue("lastReminder"));
    }
    public void setLastReminderDate(long modifiedDate) {
        setAttribute("lastReminder", Long.toString(modifiedDate));
    }

    /**
     * How long to wait (in milliseconds) before another automatic
     * reminder email is sent.
     */
    public long getCycleTime() {
        return safeConvertLong(checkAndReturnAttributeValue("cycleTime"));
    }
    public void setCycleTime(long cycleTime) {
        setAttribute("cycleTime", Long.toString(cycleTime));
    }


    private String checkAndReturnAttributeValue(String attrName)
    {
        String val = getAttribute(attrName);
        if (val==null)
        {
            return "";
        }
        return val;
    }

    public boolean isOpen()
    {
        String isOpen = getAttribute("isOpen");
        if (isOpen!=null && "closed".equals(isOpen))
        {
            return false;
        }
        return true;
    }

    public void setOpen() {
        setAttribute("isOpen", "open");
    }
    public void setClosed() {
        setAttribute("isOpen", "closed");
    }


    /**
    * this is a array of selected role names
    */
    public List<String> getNotifyRoles() {
        return getVector("notifyRoles");
    }
    public void setNotifyRoles(List<String> fname) {
        setVector("notifyRoles", fname);
    }


    /**
    * this is a array of attachment ids so that you
    * can tell the user what has already been uploaded
    * before.
    *
    * Once you attach a particular ID, this remains
    * forever part of this record.  There is no undo
    * to dis-associate a document from this reminder.
    */
    public List<String> getAttachedIds() {
        return getVector("attachedIds");
    }
    public void addAttachedId(String oneId) {
        addVectorValue("attachedIds", oneId);
    }



    public void setSendNotification(String sendNotification)
    {
        setAttribute("sendNotification", sendNotification);
    }

    public String getSendNotification()
    {
        String sendNotification = getAttribute("sendNotification");
        if(sendNotification.length() == 0){
            return "yes";
        }
        return sendNotification;
    }

    public void createHistory(AuthRequest ar, NGPage ngp, int event,
        String comment) throws Exception
    {
        HistoryRecord.createHistoryRecord(ngp,getId(),
            HistoryRecord.CONTEXT_TYPE_DOCUMENT,
            getModifiedDate(), event, ar, comment);
    }

    //TODO: this should be only for a project, not container
    public void writeReminderEmailBody(AuthRequest ar, NGContainer ngp) throws Exception {
        String userName = getModifiedBy();
        AddressListEntry ale = new AddressListEntry(userName);

        ar.write("<table>");
        ar.write("<p>From: ");
        ale.writeLink(ar);
        ar.write(", &nbsp; Workspace: ");
        ngp.writeContainerLink(ar, 100);
        ar.write("</p>\n");
        ar.write("<p>You have been invited to upload a file so that it can ");
        ar.write("be shared (in a controlled manner) with others in ");
        ar.write("the workspace \"");
        ar.writeHtml(ngp.getFullName());
        ar.write("\". Uploading the file will stop the email reminders. </p>\n<hr/>");
        ar.write("\n<p><b>Instructions:</b> ");
        ar.writeHtml(getInstructions());
        ar.write("</p>");
        ar.write("\n<p>Click on the following link or cut and paste the URL into a ");
        ar.write("web browser to access the page for uploading the file:</p>");
        ar.write("\n<p><a href=\"");
        ar.write(ar.baseURL);
        ar.write(ar.getResourceURL(ngp, ""));
        ar.write("remindAttachment.htm?");
        ar.write(AccessControl.getAccessReminderParams(ngp, this));
        ar.write("&rid=");
        ar.writeURLData(getId());
        ar.write("\">");

        ar.write(ar.baseURL);
        ar.write(ar.getResourceURL(ngp, ""));
        ar.write("remindAttachment.htm?");
        ar.write(AccessControl.getAccessReminderParams(ngp, this));
        ar.write("&rid=");
        ar.writeURLData(getId());

        ar.write("</a>");
        ar.write("</p>");
        ar.write("\n<p><b>Description of File:</b> ");
        ar.writeHtml(getFileDesc());
        ar.write("</p>");
        ar.write("\n<p>Thank you.</p>");
        ar.write("\n<hr/>");
    }

    public JSONObject getReminderEmailData(AuthRequest ar, NGContainer ngp) throws Exception {
        AddressListEntry ale = new AddressListEntry(getModifiedBy());
        JSONObject data = new JSONObject();
        data.put("from", ale.getJSON());
        data.put("instructions", getInstructions());
        data.put("resourceURL", ar.baseURL+ar.getResourceURL(ngp, "remindAttachment.htm?")
                +AccessControl.getAccessReminderParams(ngp, this)
                +"&rid="+URLEncoder.encode(getId(),"UTF-8"));
        data.put("fileDesc",  getFileDesc());
        return data;
    }
    
    public static void reminderEmail(AuthRequest ar, String pageId,String reminderId,
            String emailto, NGContainer ngp) throws Exception {

        Cognoscenti cog = ar.getCogInstance();
        ReminderMgr rMgr = ngp.getReminderMgr();
        ReminderRecord rRec = rMgr.findReminderByIDOrFail(reminderId);
        String subject = "Reminder to Upload: " + rRec.getSubject();
        List<AddressListEntry> addressList = AddressListEntry.parseEmailList(emailto);
        for (AddressListEntry ale : addressList) {
            OptOutAddr ooa = new OptOutAddr(ale);
            
            JSONObject data = rRec.getReminderEmailData(ar, ngp);
            
            File templateFile = cog.getConfig().getFileFromRoot("email/Reminder.chtml");
            
            EmailSender.containerEmail(ooa, ngp, subject, templateFile, data, null, new ArrayList<String>(), cog);
        }
        if (ngp instanceof NGPage) {
            HistoryRecord.createHistoryRecord(ngp, reminderId,
                    HistoryRecord.CONTEXT_TYPE_DOCUMENT, ar.nowTime,
                    HistoryRecord.EVENT_DOC_UPDATED, ar, "Reminder Emailed to "
                            + emailto);
        }
        ngp.saveContent(ar, "sending reminder email");
    }

}
