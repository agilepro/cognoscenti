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

import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import java.io.File;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.TimeUnit;
import org.w3c.dom.Document;

public class EmailRecordMgr {

    private static DOMFile  emailRecordFile;
    private static Hashtable<String, EmailRecord> emailRecordsTable = new Hashtable<String, EmailRecord>();

    public synchronized static void initializeEmailRecordMgr() throws Exception
    {
        File theFile = NGPage.getPathInDataFolder("email_records.record");

        Document newDoc = DOMFile.readOrCreateFile(theFile, "email_records");
        emailRecordFile = new DOMFile(theFile, newDoc);

        emailRecordsTable = new Hashtable<String, EmailRecord>();

        for (EmailRecord emailRecord : getAllEmailRecords()){
            emailRecordsTable.put(emailRecord.getId(), emailRecord);
        }
    }

    public static void refreshEmailRecordsHashTable() throws Exception
    {
        emailRecordsTable = new Hashtable<String, EmailRecord>();

        for (EmailRecord emailRecord : getAllEmailRecords()){
            emailRecordsTable.put(emailRecord.getId(), emailRecord);
        }
    }

    public static Vector<EmailRecord> getAllEmailRecords() throws Exception
    {
        if (emailRecordFile==null) {
            throw new ProgramLogicError("emailRecordFile is null when it should not be.  May not have been initialized correctly.");
        }
        Vector<EmailRecord> vc = emailRecordFile.getChildren("email-record", EmailRecord.class);
        return vc;
    }

    public static EmailRecord getEmailReadyToSend() throws Exception
    {
        for (EmailRecord er : getAllEmailRecords()) {
            if (er.statusReadyToSend()) {
                return er;
            }
        }
        return null;
    }


    public synchronized static void save() throws Exception{
        if (emailRecordFile==null) {
            throw new ProgramLogicError("emailRecordFile is null when it should not be.  May not have been initialized correctly.");
        }
        emailRecordFile.save();
    }

    public synchronized static EmailRecord createEmailRecord(String id) throws Exception
    {
        if (emailRecordFile==null) {
            throw new ProgramLogicError("emailRecordFile is null when it should not be.  May not have been initialized correctly.");
        }

        EmailRecord emailRecord =emailRecordFile.createChildWithID("email-record", EmailRecord.class, "id", id);
        emailRecordsTable.put(emailRecord.getId(), emailRecord);
        return emailRecord;
    }


    public synchronized static boolean removeEmailRecord(String id) throws Exception
    {
        if (emailRecordFile==null) {
            throw new ProgramLogicError("emailRecordFile is null when it should not be.  May not have been initialized correctly.");
        }
        Vector<EmailRecord> vc = emailRecordFile.getChildren("email_record", EmailRecord.class);
        Enumeration<EmailRecord> e = vc.elements();
        while (e.hasMoreElements())
        {
            EmailRecord child = e.nextElement();
            if (id.equals(child.getAttribute("id")))
            {
                emailRecordFile.removeChild(child);
                refreshEmailRecordsHashTable();
                return true;
            }
        }
        return false;
    }

    public static EmailRecord findEmailRecordByID(String id)throws Exception
    {
        if (emailRecordFile==null) {
            throw new ProgramLogicError("emailRecordFile is null when it should not be.  May not have been initialized correctly.");
        }
        if (id == null || id.length()==0)
        {
            throw new Exception("findEmailRecordByID was called with a bogus ID");
        }

        EmailRecord emailRecord = emailRecordsTable.get(id);
        if (emailRecord != null)
        {
            return emailRecord;

        }else{
            //reloading hashtable again
            refreshEmailRecordsHashTable();
        }

        //Again check in reloaded hashtable.
        emailRecord = emailRecordsTable.get(id);
        if (emailRecord != null)
        {
            return emailRecord;

        }
        throw new Exception("findEmailRecordByID was unable to find an email with ID = "+id);
    }

    public static EmailRecord findEmailRecordByIDOrFail(String id) throws Exception {

        EmailRecord record =  findEmailRecordByID( id );
        if (record == null)
        {
            throw new NGException("nugen.exception.unable.to.locate.emailid", new Object[]{id});
        }
        return record;
    }

    public static Vector<EmailRecord> findEmailRecordByProjectId(String projectId)throws Exception
    {
        if (emailRecordFile==null) {
            throw new ProgramLogicError("emailRecordFile is null when it should not be.  May not have been initialized correctly.");
        }
        Vector<EmailRecord> vc = new Vector<EmailRecord>();
        Enumeration<EmailRecord> e = emailRecordsTable.elements();
        while (e.hasMoreElements())
        {
            EmailRecord record = e.nextElement();
            if (projectId.equals(record.getProjectId()))
            {
                vc.add(record);
            }
        }
        return vc;
    }


    private static ArrayBlockingQueue<String> blq = new ArrayBlockingQueue<String>(1000);
    private final static long WAITING_TIME_IF_NO_ELEMENT = 5;

    public static void blockUntilNextMessage() throws Exception {
        blq.poll(WAITING_TIME_IF_NO_ELEMENT, TimeUnit.SECONDS);
    }
    public static void triggerNextMessageSend() throws Exception {
        blq.put("");
    }



}
