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

package org.socialbiz.cog.mail;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.util.ArrayList;
import java.util.List;

import org.socialbiz.cog.EmailRecord;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;
import org.workcast.json.JSONTokener;

/**
* Holds all the email to be sent, and already sent,
* in a file on disk.  This object represents the
* file that holds all the mail in an mail archive.
* This file is the core of an email subsystem.
*
* Email messages are placed into here "unsent".
* This provides a quick safe way to schedule an email message
* to be sent.  Later, in a background thread the mail
* will be actually delivered to the SMTP server
* and marked as "sent" or "failed" (if it is determined
* that there are permanent errors in sending.)
*
*/
public class MailFile extends JSONWrapper {

    File myPath;

    public static MailFile readOrCreate(File path) throws Exception {
        if (!path.exists()) {
            JSONObject newFile = new JSONObject();
            return new MailFile(path, newFile);
        }
        else {
            FileInputStream fis = new FileInputStream(path);
            JSONTokener jt = new JSONTokener(fis);
            JSONObject newKernel = new JSONObject(jt);
            fis.close();
            return new MailFile(path, newKernel);
        }
    }


    private MailFile(File path, JSONObject _kernel) throws Exception {
        super(_kernel);
        myPath = path;
    }

    public void save() throws Exception {
        File folder = myPath.getParentFile();
        File tempFile = new File(folder, "~temp."+myPath.getName()+System.currentTimeMillis());
        FileOutputStream fos = new FileOutputStream(tempFile);
        OutputStreamWriter osw = new OutputStreamWriter(fos, "UTF-8");
        kernel.write(osw, 2, 0);
        //kernel.write(osw);
        osw.flush();
        osw.close();
        fos.close();
        if (myPath.exists()) {
            myPath.delete();
        }
        tempFile.renameTo(myPath);
    }

    public List<MailInst> getAllMessages() throws Exception {
        JSONArray msgs = this.getRequiredArray("msgs");
        ArrayList<MailInst> ret = new ArrayList<MailInst>();
        int last = msgs.length();
        for (int i=0; i<last; i++) {
            ret.add(new MailInst(msgs.getJSONObject(i)));
        }
        return ret;
    }
    public void addMessage(MailInst mail) throws Exception {
        JSONArray msgs = this.getRequiredArray("msgs");
        msgs.put(mail.kernel);
    }
    public MailInst createMessage() throws Exception {
        JSONArray msgs = this.getRequiredArray("msgs");
        JSONObject jo = new JSONObject();
        msgs.put(jo);
        return new MailInst(jo);
    }




    public MailInst createEmailWithAttachments(NGPage ngc,
            String from,
            String addressee,
            String subject,
            String emailBody,
            List<String> attachIds) throws Exception {

        if (ngc == null) {
            throw new ProgramLogicError("createEmailRecord requires a non null ngc parameter");
        }

        MailInst mi = createEmailRecord(from, addressee, subject, emailBody);

        //is this needed?
        //emailRec.setProjectId(ngc.getKey());

        ArrayList<File> attachments = new ArrayList<File>();
        for (String id : attachIds) {
            File path = ngc.getAttachmentPathOrNull(id);
            if (path!=null) {
                attachments.add(path);
            }
        }
        mi.setAttachmentFiles(attachments);
        return mi;
    }


    /**
     * construct and store an email message for sending later.
     * For the Opt-Out Address, yuo either must include the message int he email body
     * or you must "prepare" the bject to have the message as a string.
     */
    public MailInst createEmailRecord(
                    String from,
                    String addressee,
                    String subject,
                    String emailBody) throws Exception {

        try {
            if (subject == null || subject.length() == 0) {
                throw new ProgramLogicError("createEmailRecord requires a non null 'subject' parameter");
            }
            if (emailBody == null || emailBody.length() == 0) {
                throw new ProgramLogicError("createEmailRecord requires a non null 'body' parameter");
            }
            if (addressee == null || addressee.length() == 0) {
                throw new ProgramLogicError("createEmailRecord requires a non empty 'addresses' parameter");
            }
            if (from == null || from.length() == 0) {
                throw new ProgramLogicError("createEmailRecord requires a non null 'from' parameter");
            }

            MailInst emailRec = this.createMessage();
            emailRec.setStatus(EmailRecord.READY_TO_GO);
            emailRec.setFrom(from);
            emailRec.setCreateDate(System.currentTimeMillis());
            emailRec.setAddressee(addressee);
            emailRec.setBodyText(emailBody);
            emailRec.setSubject(subject);
            return emailRec;
        }
        catch (Exception e) {
            throw new Exception("unable to compose email record from '"+from+"' on: "+subject, e);
        }
    }

    public void sendAllMail(Mailer mailer) throws Exception {

        List<MailInst> allEmail = getAllMessages();

        for (MailInst inst : allEmail) {
            if (MailInst.READY_TO_GO.equals(inst.getStatus())) {
                inst.sendPreparedMessageImmediately(mailer);
                save();
            }
        }
    }

    /**
     * This throws away old email on this schedule:
     * 3 months old -- the body is discarded, only the metadata remains
     * 9 months old -- removed entirely
     */
    public void pruneOldRecords() throws Exception {
        long THREE_MONTHS_AGO = System.currentTimeMillis() - 90*24*60*60*1000;
        long NINE_MONTHS_AGO = System.currentTimeMillis() - 270*24*60*60*1000;

        JSONArray oldList = kernel.getJSONArray("msgs");
        JSONArray newEmailList = new JSONArray();
        int last = oldList.length();
        for (int i=0; i<last; i++) {
            JSONObject mailObject = oldList.getJSONObject(i);
            MailInst mailInst = new MailInst(mailObject);
            long sendTime = mailInst.getLastSentDate();
            if (sendTime<NINE_MONTHS_AGO) {
                continue;
            }
            if (sendTime<THREE_MONTHS_AGO) {
                mailInst.setBodyText("*deleted*");
                mailInst.setAttachmentFiles(new ArrayList<File>());
            }
            newEmailList.put(mailObject);
        }
        kernel.put("msgs", newEmailList);
    }

}
