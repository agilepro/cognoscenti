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
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.List;
import java.util.Properties;
import java.util.Timer;
import java.util.TimerTask;

import com.purplehillsbooks.weaver.AddressListEntry;
import com.purplehillsbooks.weaver.AuthDummy;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.DOMFace;
import com.purplehillsbooks.weaver.EmailRecord;
import com.purplehillsbooks.weaver.NGBook;
import com.purplehillsbooks.weaver.NGContainer;
import com.purplehillsbooks.weaver.NGPageIndex;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.OptOutAddr;
import com.purplehillsbooks.weaver.SectionUtil;
import com.purplehillsbooks.weaver.SuperAdminLogFile;
import com.purplehillsbooks.weaver.exception.NGException;
import com.purplehillsbooks.weaver.exception.ProgramLogicError;
import com.purplehillsbooks.weaver.util.MongoDB;
import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;

/**
 * Support class for sending email messages based on an email configuration
 * file.
 */
public class EmailSender extends TimerTask {
    private static EmailSender singletonSender;
    private static Properties emailProperties = new Properties();
    private Cognoscenti cog;
    private MongoDB db;
    private long lastEmailCreateDate = 0;

    // this says where the file is, but it ALSO serves as the lock object
    // for manipulating this file.  Always use synchronized on this object
    private static File userFolder;

    // expressed in milliseconds
    private final static long TWICE_PER_MINUTE = 30000;

    /**
     * Every time the thread checks to see if it needs to send email, it marks
     * the last check time. If the value is zero you know that the thread is not
     * running. If non-zero, you know it was running at that time. This is used
     * as an indicator that the thread is still running.
     */
    public static long threadLastCheckTime = 0;

    /**
     * If the thread tries to send email, and encounters an exception, then it
     * will store that exception here so that some other page can display it. If
     * it is null, then no exception has been encountered.
     */
    public static Exception threadLastCheckException = null;

    /**
     * Store the last exception from a single message here. Messages are sent in
     * a loop, and so exceptions are caught before the next iteration. So it is
     * stored here in order to be seen.
     */
    public static Exception threadLastMsgException = null;

    /**
     * Sometimes the thread dies.  This records the last time email was checked
     * to see if there are any to send.  (It may not have sent any then.)
     * Updated only if there are no failure in processing.
     */
    public static long lastEmailProcessTime = 0;
 
    /**
     * If we got an exception while sending email record it here
     */
    public static Exception lastEmailSendFailure;
    public static long lastEmailFailureTime = 0;
    
    /**
     * This is the number of email messages sent since the last 
     * server reboot.
     */
    public static long emailSendCount = 0;


    /**
     * Initialize the EmailSender class, including background processing for
     * automatic email sending.
     */
    private EmailSender(Cognoscenti _cog) throws Exception {
        cog = _cog;
        refreshProperties(cog);
        assertEmailConfigOK();
        db = new MongoDB();
        
        //find the highest created time in the database so far
        JSONObject query = new JSONObject();
        JSONObject sort = new JSONObject();
        sort.put("CreateDate", -1);
        JSONArray maxCreateTime = db.querySortRecords(query, sort);
        if (maxCreateTime.length()>0) {
            //should always be except the first time you run
            lastEmailCreateDate = maxCreateTime.getJSONObject(0).getLong("CreateDate");
            System.out.println("EMAIL INIT: found "+maxCreateTime.length()+" records and the latest one created "+lastEmailCreateDate);
        }
        else {
            System.out.println("EMAIL INIT: the database appears to be empty???");
        }
    }
    
    
    public void migrateFromFileIfNeeded() throws Exception {
        File globalMailArchive = new File(userFolder, "GlobalEmailArchive.json");
        //if there is a global email archive file, then the records need to be 
        //transferred to the database.   If not, there is nothing to do.
        if (!globalMailArchive.exists()) {
            return;
        }
        
        MailFile globalArchive = MailFile.readOrCreate(globalMailArchive, 1);
        List<MailInst> oldMessages = globalArchive.getAllMessages();
        //returned records sorted by created date
        long lastId = System.currentTimeMillis();
        for (MailInst msg : oldMessages) {
            long id = msg.getCreateDate();
            if (id >= lastId) {
                System.out.println("EMAIL: SORT PROBLEM had to change id from "+id+" to "+(lastId-1));
                //keep them in order and unique
                id = lastId-1;
                msg.setCreateDate(id);
            }
            lastId = id;
            updateEmailInDB(msg);
        }
        
        File newName = new File( globalMailArchive.getParentFile(), globalMailArchive.getName()+".movedToDB");
        if (newName.exists()) {
            newName.delete();
        }
        globalMailArchive.renameTo(newName);
    }
    
    private void updateEmailInDB(MailInst msg) throws Exception {
        long id = msg.getCreateDate();
        JSONObject mailObj = msg.getJSON();
        JSONObject query = new JSONObject();
        //we use the create date as a key
        query.put("CreateDate", id);
        db.replaceRecord(query, mailObj);
        if (id>lastEmailCreateDate) {
            lastEmailCreateDate = id;
        }
        System.out.println("EMAIL: updated '"+mailObj.getString("Status")+"' email from "+mailObj.getString("From")+" id:"+id);
    }

    private static void refreshProperties(Cognoscenti cog) throws Exception {
        File configFile = cog.getConfig().getFile("EmailNotification.properties");

        if (!configFile.exists()) {
            throw new NGException("nugen.exception.incorrect.sys.config",
                    new Object[] { configFile.getAbsolutePath() });
        }
        FileInputStream fis = new FileInputStream(configFile);
        Properties props = new Properties();
        props.load(fis);

        // Some settings should not be settings, and should instead be fixed to
        // these values.   we always generate UTF-8 html
        props.put("mail.contenttype", "text/html;charset=UTF-8");
        emailProperties = props;

        if ("true".equals(emailProperties.getProperty("traceProperties"))) {
            dumpPropertiesToLog();
        }
    }

    /**
     * Initialize must be called if you want any background email to be sent on
     * schedule Generally it is called by the servlet initialization routines. This is
     * an initialization routine, and should only be called once, when the
     * server starts up. There are some error checks to make sure that this is
     * the case.
     */
    public static void initSender(Timer timer, Cognoscenti cog) throws Exception {

        userFolder = cog.getConfig().getUserFolderOrFail();

        // apparently a timer task can not be reused by a Timer, or in another
        // Timer.  You have to create them every time you schedule them.
        singletonSender = new EmailSender(cog);
        singletonSender.migrateFromFileIfNeeded();

        // As long as the server is up, the mail should
        // always be sent within 20 minutes of the time it was scheduled to go.

        // second parameter is the "delay" of 60 seconds.
        // The first mailing will be tested one minute from now,
        // and every 30 seconds after that.
        timer.scheduleAtFixedRate(singletonSender, 30000, TWICE_PER_MINUTE);
    }

    public static void dumpPropertiesToLog() {
        System.out.println("%%%%%%% EMAIL PROPERTY FILE %%%%%%");
        for (String key : emailProperties.stringPropertyNames()) {
            if (key.contains("password")) {
                System.out.println("    - "+key+" = ********");
            }
            else {
                System.out.println("    - "+key+" = "+emailProperties.getProperty(key));
            }
        }
        System.out.println("");
    }


    static long runCount = 0;
    static long totalTime = 0;

    // This method must be called regularly and frequently, and email is only
    // sent when it it was scheduled
    // The calling of this method has nothing to do with the email schedule /
    // frequency.
    public void run() {
        try {
            AuthRequest ar = AuthDummy.serverBackgroundRequest();
            long startTime = System.currentTimeMillis();
            ar.nowTime = startTime;
    
            // make sure that this method doesn't throw any exception
            try {
                //System.out.println("EmailSender start: "+SectionUtil.getDateAndTime(startTime)+" tid="+Thread.currentThread().getId());
                NGPageIndex.assertNoLocksOnThread();
                checkAndSendDailyDigest(ar);
                handleGlobalEmail();
                handleAllOverdueScheduledEvents(ar);
                lastEmailProcessTime = startTime;
                System.out.println("EmailSender completed: "+SectionUtil.getDateAndTime(System.currentTimeMillis()));
            } catch (Exception e) {
                Exception failure = new Exception("EmailSender-TimerTask failed in run method.", e);
                JSONException.traceException(System.out, failure, "EmailSender-TimerTask failed in run method.");
                threadLastCheckException = failure;
            }
            finally {
                //only call this when you are sure you are not holding on to any containers
                NGPageIndex.clearLocksHeldByThisThread();
            }
            long duration = System.currentTimeMillis() - startTime;
    
            //suppress the number of trace statements to one per hour.
            runCount++;
            totalTime += duration;
            if (runCount>119) {
                //this should be about 1 per hour
                long avg = totalTime / runCount;
                System.out.println("EmailSender: completed 120 scans.  Average processing time "+avg+"ms at "
                    +SectionUtil.getNicePrintDate(System.currentTimeMillis()));
                runCount = 0;
                totalTime = 0;
            }
        }
        catch (Throwable t) {
            JSONException.traceException(t, "EMAIL SENDER CRASH!");
        }
    }

    Object globalEmailFileLock = new Integer(999);

    private void handleGlobalEmail() {
        synchronized(this) {
            try {
                sendAllMailFromDB();
            }
            catch (Exception e) {
            	if (JSONException.containsMessage(e, "Couldn't connect to host")) {
            		//avoid dumping the entire exception to the log file when
            		//the problem is that the email server is down or not reachable
            		System.out.println("EmailSender.handleGlobalEmail unable to connect to email server at "+emailProperties.getProperty("mail.smtp.host"));
            	}
            	else {
            		JSONException.traceException(System.out, e, "FATAL ERROR EmailSender.handleGlobalEmail");
            	}
            }
        }
    }
    
    private boolean sendAllMailFromDB() throws Exception {

        JSONObject query = new JSONObject();
        query.put("Status",  MailInst.READY_TO_GO);
        
        JSONArray allUnsentMail = db.queryRecords(query);
        System.out.println("MAIL SENDING: found "+allUnsentMail.length()+" records in DB ready to send");
        boolean allSentOK = true;

        for (JSONObject msgObj : allUnsentMail.getJSONObjectList()) {
            MailInst inst = new MailInst(msgObj);
            if (MailInst.READY_TO_GO.equals(inst.getStatus())) {
                if (!inst.sendPreparedMessageImmediately(emailProperties)) {
                    allSentOK=false;
                }
                updateEmailInDB(inst);
            }
        }
        return allSentOK;
    }

    private void handleAllOverdueScheduledEvents(AuthRequest ar) throws Exception{
        NGPageIndex.assertNoLocksOnThread();

        //default delay is 0 minutes AFTER the scheduled time.  This delay is to allow people who
        //create something a few minutes to edit before it is sent.
        int delayTime = 0;
        String delayStr = emailProperties.getProperty("automated.email.delay");
        if (delayStr!=null) {
            //delay time config parameter is in minutes
            delayTime = DOMFace.safeConvertInt(delayStr)*1000*60;
        }

        long nowTime = ar.nowTime;
        List<NGPageIndex> allOverdue = listOverdueContainers(nowTime-delayTime);
        int iCount = 0;
        for (NGPageIndex ngpi : allOverdue) {
            iCount++;

            File workspaceCogFolder = ngpi.containerPath.getParentFile();
            File emailArchiveFile = new File(workspaceCogFolder, "mailArchive.json");

            //open and read the archive first .. it is safe because this is the only thread
            //that reads the email archive.
            //MailFile emailArchive = MailFile.readOrCreate(emailArchiveFile, 3);


            if (ngpi.isWorkspace()){
                NGWorkspace ngw = ngpi.getWorkspace();
                ar.ngp = ngw;

                try {
                    //first, move all the email messages that have been stored in the project from foreground events.
                    if (moveEmails(ngw)) {

                        ngpi.nextScheduledAction = ngw.nextActionDue();
                        ngw.saveWithoutAuthenticatedUser(ar.getBestUserId(), ar.nowTime,
                                "Processing handleAllOverdueScheduledEvents", cog);
                        NGPageIndex.clearLocksHeldByThisThread();
                    }
                }
                catch (Exception e) {
                    throw new JSONException("Problem with email file: {0}", e, emailArchiveFile);
                }

                //now open the page and generate all the email messages, remember this
                //locks the file blocking all other threads, so be quick
                ArrayList<ScheduledNotification> resList = new ArrayList<ScheduledNotification>();
                ngw.gatherUnsentScheduledNotification(resList, nowTime);

                for (ScheduledNotification sn : resList) {
                    if (sn.needsSendingBefore(nowTime)) {
                        sn.sendIt(ar, this);
                    }
                }

                ngpi.nextScheduledAction = ngw.nextActionDue();
                ngw.save(); //save all the changes from the removal of email and scheduling of events
                NGPageIndex.clearLocksHeldByThisThread();

                //now we can go an actually send the email in the mailArchive
                //emailArchive.save();
            }
            else {
                //on the site the only thing currently is the SiteMail messages
                System.out.println("Now checkin on Site: "+ngpi.containerName);
                NGBook site = ngpi.getSite();
                ArrayList<ScheduledNotification> resList = new ArrayList<ScheduledNotification>();
                site.gatherUnsentScheduledNotification(resList, nowTime);
                for (ScheduledNotification sn : resList) {
                    System.out.println("  Site: "+ngpi.containerName+" notification: "+sn.selfDescription());
                    if (sn.needsSendingBefore(nowTime)) {
                        System.out.println("  Site: "+ngpi.containerName+" has email due: "+sn.selfDescription());
                        sn.sendIt(ar, this);
                    }
                }

                ngpi.nextScheduledAction = site.nextActionDue();
                site.save(); //save all the changes from the removal of email and scheduling of events
                NGPageIndex.clearLocksHeldByThisThread();
            }


            //now we can go an actually send the email in the mailArchive
            if (!sendAllMailFromDB()) {
                //mark project as needing to try again in 5 minutes.
                long nextCycle = System.currentTimeMillis()+300000;
                if (ngpi.nextScheduledAction>nextCycle) {
                    ngpi.nextScheduledAction = nextCycle;
                }
            }

            Thread.sleep(200);  //just small delay to avoid saturation
        }
        if (iCount>0) {
            System.out.println("BACKGROUND: Processed "+iCount+" background events at "
                +SectionUtil.currentTimeString());
        }
    }

    private ArrayList<NGPageIndex> listOverdueContainers(long cutoffTime) throws Exception {
        ArrayList<NGPageIndex> ret = new ArrayList<NGPageIndex>();
        for (NGPageIndex ngpi : cog.getAllContainers()) {
            if (ngpi.isDeleted) {
                continue;
            }
            if (ngpi.nextScheduledAction>0 && ngpi.nextScheduledAction<=cutoffTime) {
                ret.add(ngpi);
            }
        }
        return ret;
    }



    /**
     * This method is designed to be called repeatedly ... every 20 minutes.
     * What it then does is calculate the next due date. If it is currently
     * after the due date, then the sendDailyDigest is sent.
     *
     * The duedate is calculated as the next occurrence of 3am after the time
     * sent in.
     *
     * ~3 hours is added to the last time email was sent and then the next
     * scheduled time is calculated from that. The reason for the three hours is
     * because if the mail happens to be sent just before a scheduled time
     * (within 3 hours) we don't want it sending then, it should wait for the
     * next day. Adding 3 hours (10 million milliseconds) will avoid scheduling
     * anything within three hours of the last send time.
     *
     * If the current time is after that calculated time, it sends. If not, it
     * just returns, and waits for the next call.
     *
     * Since the scheduled time is calculated from the last sent time, if you
     * ever find that the current time is after that time, the mail is sent.
     * Thus if the server is down for a couple of days, then the email is sent
     * on the first cycle after starting. That resets the lastSentTime.
     *
     * Then, if the last sent time is within three hours of the next send time,
     * then that send time will be skipped, and it will be 27 hours before the
     * next sending. If the last sent time is more than three hour before the
     * next time, then it will be sent on schedule.
     */
    public void checkAndSendDailyDigest(AuthRequest ar) throws Exception {
        SuperAdminLogFile salf = SuperAdminLogFile.getInstance(cog);
        long lastNotificationSentTime = salf.getLastNotificationSentTime();
        long nextScheduledTime = getNextTime(lastNotificationSentTime + 10000000);
        threadLastCheckTime = System.currentTimeMillis();
        if (threadLastCheckTime > nextScheduledTime) {
            DailyDigest.sendDailyDigest(ar, cog);
        }
    }


    /**
     * This static method returns the property from the current properties
     * stored in memory. This must be initialized by a call to initSender. This
     * gets "refreshed" by reading the property file again everytime an email
     * sender object is created.
     */
    public static String getProperty(String key, String defaultValue) {
        String value = emailProperties.getProperty(key, defaultValue).trim();
        return value;
    }

    public static String getProperty(String key) {
        return getProperty(key, "");
    }

    public void setProperty(String key, String value) {
        emailProperties.setProperty(key, value);
    }

    public static long getNextTime(long startTime) throws Exception {
        Calendar tomorrow = new GregorianCalendar();
        tomorrow.setTimeInMillis(startTime);

        int hour = tomorrow.get(Calendar.HOUR_OF_DAY);
        if (hour > 2) {
            // if current time is AFTER 3am, then add a day
            tomorrow.add(Calendar.DATE, 1);
        }

        // this of course does not work because we have not specified the
        // timezone within which to calculate the time of date. Will use
        // the default timezone that the server is in.
        // Good enough for now.
        Calendar cal = new GregorianCalendar(tomorrow.get(Calendar.YEAR),
                tomorrow.get(Calendar.MONTH), tomorrow.get(Calendar.DATE),
                3, // 3 AM
                0 // zero minutes.
        );

        // first getTime returns a Date, the second gets the long value from the
        // Date
        return cal.getTime().getTime();
    }

    /**
    * Stores an email message in the NGWorkspace project workspace, that will LATER be moved to the
    * MailFile archive and sent.
    */
    public static void containerEmail(OptOutAddr ooa, NGContainer ngc,
            String subject, File templateFile, JSONObject data, String from,
            List<String> attachIds, Cognoscenti cog) throws Exception {
        if (subject == null || subject.length() == 0) {
            throw new ProgramLogicError("containerEmail requires a non null subject parameter");
        }
        if (!templateFile.exists()) {
            throw new ProgramLogicError("containerEmail was passed a template that does not exist: "
                      +templateFile.toString());
        }
        if (ngc == null) {
            throw new ProgramLogicError("containerEmail requires a non null ngc parameter");
        }
        if (from == null) {
            from = composeFromAddress(ngc);
        }

        String body = ChunkTemplate.streamToString(templateFile, data, ooa.getCalendar());

        createEmailRecordInternal(ngc, from, ooa, subject, body, attachIds, cog);
    }


    /**
     * Stores an email message in the NGWorkspace project workspace, that will LATER be moved to the
     * MailFile archive and sent.
     */
    private static void createEmailRecordInternal(NGContainer ngc, String from,
            OptOutAddr ooa, String subject, String bodyValue, List<String> attachIds,
            Cognoscenti cog)
            throws Exception {
       try {

            ooa.assertValidEmail();

            EmailRecord emailRec = ngc.createEmail();
            emailRec.setStatus(EmailRecord.READY_TO_GO);
            emailRec.setFromAddress(from);
            emailRec.setCreateDate(System.currentTimeMillis());
            emailRec.setAddress(ooa);
            emailRec.setBodyText(bodyValue);
            emailRec.setSubject(subject);
            emailRec.setProjectId(ngc.getKey());
            emailRec.setAttachmentIds(attachIds);
            ngc.saveWithoutAuthenticatedUser("SERVER", System.currentTimeMillis(), "Sending an email message", cog);
        } catch (Exception e) {
            throw new NGException("nugen.exception.unable.to.send.simple.msg",
                    new Object[] { from, subject }, e);
        }
    }


    /**
     * generalMailToOne - Send a email to a single email address (as an
     * AddressListEntry) in the scope of the entire product (not any specific
     * project or other context).
     *
     * This method sends a single email message to the addressee
     * with the given subject and body. You can specify the from
     * address as well.
     *
     * Email is stored in the GlobalMailArchive momentarily before actually
     * sending it.
     */
    public static void generalMailToOne(OptOutAddr ooa, AddressListEntry from, String subject,
            String emailBody, Cognoscenti cog) throws Exception {
        List<OptOutAddr> v = new ArrayList<OptOutAddr>();
        v.add(ooa);
        generalMailToList(v, from, subject, emailBody, cog);
    }


    /**
     * generalMailToList - Send a email to a list of email address
     * in the scope of the entire product (not any specific
     * project or other context).
     *
     * This method sends a single email message to the addressee
     * with the given subject and body. You can specify the from
     * address as well.
     *
     * Email is stored in the GlobalMailArchive momentarily before actually
     * sending it.
     */
    public static void generalMailToList(List<OptOutAddr> addresses, AddressListEntry from,
            String subject, String emailBody, Cognoscenti cog) throws Exception {
        if (subject == null || subject.length() == 0) {
            throw new ProgramLogicError("simpleEmail requires a non null subject parameter");
        }
        if (emailBody == null || emailBody.length() == 0) {
            throw new ProgramLogicError("simpleEmail requires a non null body parameter");
        }
        if (addresses == null || addresses.size() == 0) {
            throw new ProgramLogicError("simpleEmail requires a non empty addresses parameter");
        }
        if (from == null) {
            throw new ProgramLogicError("simpleEmail requires a non empty from parameter");
        }
        synchronized(singletonSender) {
            try {
                for (OptOutAddr ooa : addresses) {
                    singletonSender.createEmailRecordInDB(from, ooa.getEmail(), subject, emailBody);
                }
            }
            catch (Exception e) {
                throw new Exception("Failure while composing an email message for the global archive", e);
            }
        }
    }

    public static MailInst createEmailFromTemplate( OptOutAddr ooa, String addressee,
            String subject, File templateFile, JSONObject data) throws Exception {
        synchronized(singletonSender) {
            try {
                MailInst mi = singletonSender.internalCreateEmailFromTemplate(ooa, addressee, subject, templateFile, data);
                return mi;
            }
            catch (Exception e) {
                throw new Exception("Failure while composing an email message for the global archive", e);
            }
        }
    }
    public MailInst internalCreateEmailFromTemplate( OptOutAddr ooa, String addressee,
            String subject, File templateFile, JSONObject data) throws Exception {
        String body = ChunkTemplate.streamToString(templateFile, data, ooa.getCalendar());
        return createEmailRecordInDB( ooa.getAssignee(), addressee, subject, body);
    }


    private static String composeFromAddress(NGContainer ngc) throws Exception {
        StringBuilder sb = new StringBuilder("^");
        String baseName = ngc.getFullName();
        int last = baseName.length();
        for (int i = 0; i < last; i++) {
            char ch = baseName.charAt(i);
            if ((ch >= '0' && ch <= '9') || (ch >= 'A' && ch <= 'Z')
                    || (ch >= 'a' && ch <= 'z') || (ch == ' ')) {
                sb.append(ch);
            }
        }
        String baseEmail = getProperty("mail.smtp.from", "xyz@example.com");
        if (baseEmail.contains("Project-Id")) {
            baseEmail = baseEmail.replace("Project-Id", ngc.getKey());
        }
        // if there is angle brackets, take the quantity within the angle
        // brackets
        int anglePos = baseEmail.indexOf("<");
        if (anglePos >= 0) {
            baseEmail = baseEmail.substring(anglePos + 1);
        }
        anglePos = baseEmail.indexOf(">");
        if (anglePos >= 0) {
            baseEmail = baseEmail.substring(0, anglePos);
        }

        // now add email address in angle brackets
        sb.append(" <");
        sb.append(baseEmail);
        sb.append(">");
        return sb.toString();
    }


    /**
     * Use this to attempt to detect mis-configurations, and give a reasonable
     * error message when something important is missing.
     */
    private void assertEmailConfigOK() throws Exception {

        String proto = getProperty("mail.transport.protocol");
        if (proto == null || proto.length() == 0) {
            throw new NGException("nugen.exception.email.config.issue", null);
        }
        if (!proto.equals("smtp") && !proto.equals("none")) {
            throw new NGException(
                    "nugen.exception.email.config.file.smtp.issue",
                    new Object[] { proto });
        }
        String auth = getProperty("mail.smtp.auth");
        if ("true".equals(auth)) {
            //in this case you need both a user name and a password
            String user = getProperty("mail.smtp.user");
            if (user==null){
                throw new Exception("When mail.smtp.auth=true you need to specify a user name:  mail.smtp.user");
            }
            String password = getProperty("mail.smtp.password");
            if (password==null){
                throw new Exception("When mail.smtp.auth=true you need to specify a password:  mail.smtp.password");
            }
        }
        else if (!"false".equals(auth)) {
            throw new Exception("mail.smtp.auth must be set to 'true' or 'false' - value ("+auth+") is not allowed.");
        }
    }
    
    public synchronized long getUniqueTime() {
        long newTime = System.currentTimeMillis();
        if (newTime<=lastEmailCreateDate) {
            newTime = lastEmailCreateDate+1;
        }
        lastEmailCreateDate = newTime;
        return newTime;
    }

    public MailInst createEmailRecordInDB (
            AddressListEntry from,
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
            if (from == null) {
                throw new ProgramLogicError("createEmailRecord requires a non null 'from' parameter");
            }
        
            MailInst emailRec = new MailInst(new JSONObject());
            emailRec.setStatus(EmailRecord.READY_TO_GO);
            emailRec.setFromName(from.getName());
            emailRec.setFromAddress(from.getEmail());
            long id = getUniqueTime();
            emailRec.setCreateDate(id);
            emailRec.setAddressee(addressee);
        
            //for some reason email is not able to handle the upper ascii
            //even though it seems to correctly encoded, the decoding seems to
            //be confused on the other end.   Just escape for HTML and all
            //should be OK.
            //This is a horrible horrible hack ... but it works reliably.
            //The problem seems to be the order of decoding the stream and the
            //quoted printable encoding.
            StringBuilder sb = new StringBuilder();
            for (int i=0; i<emailBody.length(); i++) {
                char ch = emailBody.charAt(i);
                if (ch<128) {
                    sb.append(ch);
                }
                else {
                    sb.append("&#");
                    sb.append(Integer.toString(ch));
                    sb.append(';');
                }
            }
            emailRec.setBodyText(sb.toString());
            emailRec.setSubject(subject);
            
            updateEmailInDB(emailRec);
            
            return emailRec;
        }
        catch (Exception e) {
            throw new JSONException("Unable to compose email record from '{0}' on: {1}", e, from, subject);
        }
    }
    
    public MailInst createEmailWithAttachments(
            AddressListEntry from,
            String addressee,
            String subject,
            String emailBody,
            List<File> attachments) throws Exception {

        MailInst mi = createEmailRecordInDB(from, addressee, subject, emailBody);

        mi.setAttachmentFiles(attachments);
        return mi;
    }
    
    
    public boolean moveEmails(NGContainer ngp) throws Exception {
        List<EmailRecord> allEmail = ngp.getAllEmail();
        if (allEmail.size()==0) {
            return false;
        }
        for (EmailRecord er : allEmail) {
            String fullFromAddress = er.getFromAddress();
            AddressListEntry fromAle = AddressListEntry.parseCombinedAddress(fullFromAddress);
            List<OptOutAddr> allAddressees = er.getAddressees();
            for (OptOutAddr oaa : allAddressees) {
                //create a message for each addressee ... actually there is
                //usually only one so this usually creates only a single email
                MailInst inst = new MailInst(new JSONObject());
                inst.setAddressee(oaa.getEmail());
                inst.setStatus(er.getStatus());
                inst.setSubject(er.getSubject());
                inst.setFromAddress(fromAle.getEmail());
                inst.setFromName(fromAle.getName());
                oaa.prepareInternalMessage(cog);
                inst.setBodyText(er.getBodyText()+oaa.getUnSubscriptionAsString());
                inst.setLastSentDate(er.getLastSentDate());
                inst.setCreateDate(getUniqueTime());
                ArrayList<File> attachments = new ArrayList<File>();
                if (ngp instanceof NGWorkspace) {
                    NGWorkspace ngw = (NGWorkspace) ngp;
                    for (String id : er.getAttachmentIds()) {
                        File path = ngw.getAttachmentPathOrNull(id);
                        if (path!=null) {
                            attachments.add(path);
                        }
                    }
                }
                inst.setAttachmentFiles(attachments);
                updateEmailInDB(inst);
            }
        }
        ngp.clearAllEmail();
        return true;
    }

}
