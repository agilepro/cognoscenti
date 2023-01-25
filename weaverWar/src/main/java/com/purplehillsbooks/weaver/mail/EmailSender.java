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
import com.purplehillsbooks.weaver.NGBook;
import com.purplehillsbooks.weaver.NGContainer;
import com.purplehillsbooks.weaver.NGPageIndex;
import com.purplehillsbooks.weaver.NGWorkspace;
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
        
        long thirtyDaysAgo = System.currentTimeMillis() - 30L * 24 * 3_600_000;
        
        //find the highest created time in the database so far
        //but limit the query to the last 30 days
        JSONObject query = new JSONObject();
        JSONObject gteCondition = new JSONObject();
        gteCondition.put("$gte", thirtyDaysAgo);
        query.put("CreateDate", gteCondition);
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
    
    
    public void updateEmailInDB(MailInst msg) throws Exception {
        System.out.println(" EMAIL DB: msg "+msg.getCreateDate()+" has comment container: "+msg.getCommentContainer());
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
            throw new JSONException("Email config file does not exist: {0}", configFile.getAbsolutePath());
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

        // apparently a timer task can not be reused by a Timer, or in another
        // Timer.  You have to create them every time you schedule them.
        singletonSender = new EmailSender(cog);

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
                handleAllOverdueScheduledEvents(ar);
                handleGlobalEmail();
                lastEmailProcessTime = startTime;
                //System.out.println("EmailSender completed: "+SectionUtil.getDateAndTime(System.currentTimeMillis()));
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
        boolean allSentOK = true;

        for (JSONObject msgObj : allUnsentMail.getJSONObjectList()) {
            MailInst inst = new MailInst(msgObj);
            
            //check that the query worked.
            if (!MailInst.READY_TO_GO.equals(inst.getStatus())) {
                System.out.println("MAIL DB ERROR: query for 'Ready' email, but got '"+inst.getStatus()+"' instead.");
                continue;
            }
            
            if (inst.sendPreparedMessageImmediately(emailProperties)) {
                updateEmailInDB(inst);
            }
            else {
                //this will be retried later
                System.out.println("MAIL DB FAILURE: email '"+inst.getCreateDate()+"' to '"+inst.getAddressee()+"' failed to send, will try again later.");
                allSentOK=false;
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

            if (ngpi.isWorkspace()){
                System.out.println("OVERDUE EMAIL on Workspace: "+ngpi.containerName);
                NGWorkspace ngw = ngpi.getWorkspace();
                ar.ngp = ngw;
                boolean sentMsg = ngw.transferEmailToDB(cog, this);
                
                if (ngw.generateNotificationEmail(ar, this, nowTime)) {
                    sentMsg = true;
                }

                ngpi.nextScheduledAction = ngw.nextActionDue();
                if (sentMsg) {
                    ngw.save(); //save all the changes from the removal of email and scheduling of events
                }
            }
            else {
                //on the site the only thing currently is the SiteMail messages
                System.out.println("OVERDUE EMAIL on Site: "+ngpi.containerName);
                NGBook site = ngpi.getSite();
                boolean sentMsg = site.generateNotificationEmail(ar, this, nowTime);

                ngpi.nextScheduledAction = site.nextActionDue();
                if (sentMsg) {
                    site.save(); //save all the changes from the removal of email and scheduling of events
                }
                
            }
            NGPageIndex.clearLocksHeldByThisThread();

            Thread.sleep(200);  //just small delay to avoid saturation
        }
        
        if (iCount>0) {
            System.out.println("EMAIL SENDER: Processed "+iCount+" background events at "
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
     * generalMailToOne - Send a email to a single email address (as an
     * AddressListEntry) in the scope of the entire system (not any specific
     * project or other context).
     *
     * This method sends a single email message to the addressee
     * with the given subject and body. You can specify the from
     * address as well.
     *
     * Email is stored in the GlobalMailArchive momentarily before actually
     * sending it.
     */
    public static void generalMailToOne(MailInst msg, AddressListEntry from, OptOutAddr addressee) throws Exception {
        singletonSender.createEmailRecordInDB(msg, from, addressee.getEmail());
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
    public static void generalMailToList(MailInst msg, AddressListEntry from, List<OptOutAddr> addresses) throws Exception {
        try {
            for (OptOutAddr ooa : addresses) {
                MailInst msgCopy = msg.cloneMsg();
                singletonSender.createEmailRecordInDB(msgCopy, from, ooa.getEmail());
            }
        }
        catch (Exception e) {
            throw new Exception("Failure while composing an email message for the global archive", e);
        }
    }


    public static String composeFromAddress(NGContainer ngc) throws Exception {
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
            throw new Exception("Email config file is missing the protocol setting");
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
                MailInst emailRec,
                AddressListEntry from,
                String addressee) throws Exception {
        try {
            if (emailRec.getSubject() == null || emailRec.getSubject().length() == 0) {
                throw new ProgramLogicError("createEmailRecord requires a non null 'subject' parameter");
            }
            if (emailRec.getBodyText() == null || emailRec.getBodyText().length() == 0) {
                throw new ProgramLogicError("createEmailRecord requires a non null 'body' parameter");
            }
            if (addressee == null || addressee.length() == 0) {
                throw new ProgramLogicError("createEmailRecord requires a non empty 'addresses' parameter");
            }
            if (from == null) {
                throw new ProgramLogicError("createEmailRecord requires a non null 'from' parameter");
            }

            emailRec.setFromName(from.getName());
            emailRec.setFromAddress(from.getEmail());
            emailRec.setAddressee(addressee);
        
            
            updateEmailInDB(emailRec);
            return emailRec;
        }
        catch (Exception e) {
            throw new JSONException("Unable to compose email record from '{0}' on: {1}", e, from, addressee);
        }
    }
    
    
    /*
     * following fields are allowed in the query
     * 
     * offset: starting point in the list of records
     * batch: size of the batch, default 50
     * includeBody: whether email body should be included for size reasons
     * searchValue: thing being searched for
     */
    public static JSONObject queryWorkspaceEmail(NGWorkspace ngw, JSONObject query) throws Exception {
        
        int offset = query.optInt("offset", 0);
        if (offset<0) {
            offset = 0;
        }
        int batch  = query.optInt("batch", 50);
        //boolean includeBody = query.has("includeBody") && query.getBoolean("includeBody");
        String searchValue  = query.optString("searchValue", "");
        long msgId  = query.optLong("msgId", 0);
        
        JSONObject sort = new JSONObject().put("CreateDate", -1);
        
        //the query is to find all email messages for that site,
        //and that workspace, where either the subject or the 
        //address contains the search value using regex
        JSONObject mongoQuery = new JSONObject();
        JSONArray basicAnd = mongoQuery.requireJSONArray("$and");
        basicAnd.put( new JSONObject().put("Site", ngw.getSiteKey()));
        basicAnd.put( new JSONObject().put("Workspace", ngw.getKey()));
        if (msgId>0) {
            basicAnd.put( new JSONObject().put("CreateDate", msgId));
        }
        else if (searchValue.length()>0){
            JSONObject fieldsOr = new JSONObject();
            JSONArray orArray = fieldsOr.requireJSONArray("$or");
            orArray.put( new JSONObject().put("Subject", new JSONObject().put("$regex", searchValue)));
            orArray.put( new JSONObject().put("Addressee", new JSONObject().put("$regex", searchValue)));
            basicAnd.put(fieldsOr);
        }

        JSONObject res = new JSONObject();
        res.put("query", mongoQuery);
        res.put("list", singletonSender.db.querySortRecords(mongoQuery, sort, offset, batch));
        return res;
    }
    
    public static JSONObject querySiteEmail(NGBook ngb, JSONObject query) throws Exception {
        
        int offset = query.optInt("offset", 0);
        if (offset<0) {
            offset = 0;
        }
        int batch  = query.optInt("batch", 50);
        //boolean includeBody = query.has("includeBody") && query.getBoolean("includeBody");
        String searchValue  = query.optString("searchValue", "");
        long msgId  = query.optLong("msgId", 0);
        
        JSONObject sort = new JSONObject().put("CreateDate", -1);
        
        //the query is to find all email messages for that site,
        //and that workspace, where either the subject or the 
        //address contains the search value using regex
        JSONObject mongoQuery = new JSONObject();
        JSONArray basicAnd = mongoQuery.requireJSONArray("$and");
        basicAnd.put( new JSONObject().put("Site", ngb.getKey()));
        basicAnd.put( new JSONObject().put("Workspace", "$"));
        if (msgId>0) {
            basicAnd.put( new JSONObject().put("CreateDate", msgId));
        }
        else if (searchValue.length()>0){
            JSONObject fieldsOr = new JSONObject();
            JSONArray orArray = fieldsOr.requireJSONArray("$or");
            orArray.put( new JSONObject().put("Subject", new JSONObject().put("$regex", searchValue)));
            orArray.put( new JSONObject().put("Addressee", new JSONObject().put("$regex", searchValue)));
            basicAnd.put(fieldsOr);
        }

        JSONObject res = new JSONObject();
        res.put("query", mongoQuery);
        res.put("list", singletonSender.db.querySortRecords(mongoQuery, sort, offset, batch));
        return res;
    }    
    
    public static JSONObject queryUserEmail(JSONObject query) throws Exception {
        
        int offset = query.optInt("offset", 0);
        if (offset<0) {
            offset = 0;
        }
        int batch  = query.optInt("batch", 50);
        //boolean includeBody = query.has("includeBody") && query.getBoolean("includeBody");
        String searchValue  = query.optString("searchValue", "");
        long msgId  = query.optLong("msgId", 0);
        String userKey  = query.optString("userKey", null);
        String userEmail  = query.optString("userEmail", null);
        if (userKey==null && userEmail==null) {
            throw new Exception("Must specify either a 'userKey' or a 'userEmail' for the user being searched in queryUserEmail");
        }
        
        JSONObject sort = new JSONObject().put("CreateDate", -1);
        
        //the query is to find all email messages for that site,
        //and that workspace, where either the subject or the 
        //address contains the search value using regex
        JSONObject mongoQuery = new JSONObject();
        JSONArray basicAnd = mongoQuery.requireJSONArray("$and");
        
        JSONObject userOr = new JSONObject();
        JSONArray userOrArray = userOr.requireJSONArray("$or");
        if (userKey!=null) {
            userOrArray.put( new JSONObject().put("UserKey", userKey));
        }
        if (userEmail!=null) {
            userOrArray.put( new JSONObject().put("Addressee", userEmail));
        }
        basicAnd.put(userOr);
        
        if (msgId>0) {
            basicAnd.put( new JSONObject().put("CreateDate", msgId));
        }
        else if (searchValue.length()>0){
            JSONObject fieldsOr = new JSONObject();
            JSONArray orArray = fieldsOr.requireJSONArray("$or");
            orArray.put( new JSONObject().put("Subject", new JSONObject().put("$regex", searchValue)));
            orArray.put( new JSONObject().put("Addressee", new JSONObject().put("$regex", searchValue)));
            basicAnd.put(fieldsOr);
        }

        JSONObject res = new JSONObject();
        res.put("query", mongoQuery);
        res.put("list", singletonSender.db.querySortRecords(mongoQuery, sort, offset, batch));
        return res;
    }    
   
    public static JSONObject querySuperAdminEmail(JSONObject query) throws Exception {
        
        int offset = query.optInt("offset", 0);
        if (offset<0) {
            offset = 0;
        }
        int batch  = query.optInt("batch", 50);
        //boolean includeBody = query.has("includeBody") && query.getBoolean("includeBody");
        String searchValue  = query.optString("searchValue", "");
        long msgId  = query.optLong("msgId", 0);
        String site  = query.optString("site", "");
        String workspace  = query.optString("workspace", "");
        if (site.length()==0 && workspace.length()==0 && searchValue.length()==0 && msgId<=0) {
            //there has to be at least one condition . . .
            workspace = "$";
        }
        
        JSONObject sort = new JSONObject().put("CreateDate", -1);
        
        //the query is to find all email messages for that site,
        //and that workspace, where either the subject or the 
        //address contains the search value using regex
        JSONObject mongoQuery = new JSONObject();
        JSONArray basicAnd = mongoQuery.requireJSONArray("$and");
        if (site.length()>0) {
            basicAnd.put( new JSONObject().put("Site", site));
        }
        if (workspace.length()>0) {
            basicAnd.put( new JSONObject().put("Workspace", workspace));
        }
        if (msgId>0) {
            basicAnd.put( new JSONObject().put("CreateDate", msgId));
        }
        else if (searchValue.length()>0){
            JSONObject fieldsOr = new JSONObject();
            JSONArray orArray = fieldsOr.requireJSONArray("$or");
            orArray.put( new JSONObject().put("Subject", new JSONObject().put("$regex", searchValue)));
            orArray.put( new JSONObject().put("Addressee", new JSONObject().put("$regex", searchValue)));
            basicAnd.put(fieldsOr);
        }

        JSONObject res = new JSONObject();
        res.put("query", mongoQuery);
        res.put("list", singletonSender.db.querySortRecords(mongoQuery, sort, offset, batch));
        return res;
    }    
   
    
    public static MailInst findEmailById(NGWorkspace ngw, long msgId) throws Exception {
        
        JSONObject query = new JSONObject().put("msgId", msgId);
        
        JSONObject res = queryWorkspaceEmail(ngw, query);
        
        JSONArray list = res.requireJSONArray("list");
        if (list.length()>0) {
            return new MailInst(list.getJSONObject(0));
        }
        return null;
    }
    public static MailInst findEmailById(long msgId) throws Exception {
        
        JSONObject query = new JSONObject().put("msgId", msgId);
        
        JSONObject res = querySuperAdminEmail(query);
        
        JSONArray list = res.requireJSONArray("list");
        if (list.length()>0) {
            return new MailInst(list.getJSONObject(0));
        }
        return null;
    }

}
