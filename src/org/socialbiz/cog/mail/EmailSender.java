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
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.List;
import java.util.Properties;
import java.util.Timer;
import java.util.TimerTask;

import org.socialbiz.cog.AuthDummy;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.Cognoscenti;
import org.socialbiz.cog.DOMFace;
import org.socialbiz.cog.EmailRecord;
import org.socialbiz.cog.NGContainer;
import org.socialbiz.cog.NGPageIndex;
import org.socialbiz.cog.NGWorkspace;
import org.socialbiz.cog.OptOutAddr;
import org.socialbiz.cog.SuperAdminLogFile;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;

/**
 * Support class for sending email messages based on an email configuration
 * file.
 *
 * Use EmailSender.quickEmail(to, from, subj, body) whenever possible because
 * this is the essential method for sending email and will be supported in the
 * long run.
 */
public class EmailSender extends TimerTask {
    private static Properties emailProperties = new Properties();
    private Cognoscenti cog;

    // this says where the file is, but it ALSO serves as the lock object
    // for manipulating this file.  Always use synchronized on this object
    private static File globalMailArchive;

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
     * Initialize the EmailSender class, including background processing for
     * automatic email sending.
     */
    private EmailSender(Cognoscenti _cog) throws Exception {
        cog = _cog;
        refreshProperties(cog);
        assertEmailConfigOK();
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
    }

    /**
     * Initialize must be called if you want any background email to be sent on
     * schedule Generally it is called by the servlet initialization routines,
     * passing the ServletContext and the ApplicationContext objects in. This is
     * an initialization routine, and should only be called once, when the
     * server starts up. There are some error checks to make sure that this is
     * the case.
     */
    public static void initSender(Timer timer, Cognoscenti cog) throws Exception {

        File userFolder = cog.getConfig().getUserFolderOrFail();
        globalMailArchive = new File(userFolder, "GlobalEmailArchive.json");

        // apparently a timer task can not be reused by a Timer, or in another
        // Timer.  You have to create them every time you schedule them???
        // TODO: no reason to make these static then
        EmailSender singletonSender = new EmailSender(cog);


        // As long as the server is up, the mail should
        // always be sent within 20 minutes of the time it was scheduled to go.

        // second parameter is the "delay" of 60 seconds.
        // The first mailing will be tested one minute from now,
        // and every 30 seconds after that.
        timer.scheduleAtFixedRate(singletonSender, 30000, TWICE_PER_MINUTE);
        //timer.scheduleAtFixedRate(singletonSender, 10000, 5000);

    }

    // This method must be called regularly and frequently, and email is only
    // sent when it it was scheduled
    // The calling of this method has nothing to do with the email schedule /
    // frequency.
    public void run() {
        AuthRequest ar = AuthDummy.serverBackgroundRequest();
        ar.nowTime = System.currentTimeMillis();

        // make sure that this method doesn't throw any exception
        try {
            NGPageIndex.assertNoLocksOnThread();
            checkAndSendDailyDigest(ar);
            handleGlobalEmail();
            handleAllOverdueScheduledEvents(ar);
        } catch (Exception e) {
            Exception failure = new Exception(
                    "Failure in the EmailSender thread run method.  Thread died.",
                    e);
            System.out.println("BACKGROUND EVENTS: FATAL FAILURE - " + e);
            failure.printStackTrace(System.out);
            threadLastCheckException = failure;
            System.out.println("BACKGROUND EVENTS: ---------------------------- ");
        }
        finally {
            //only call this when you are sure you are not holding on to any containers
            NGPageIndex.clearLocksHeldByThisThread();
        }
    }

    Object globalEmailFileLock = new Integer(999);

    private void handleGlobalEmail() {
        synchronized(globalMailArchive) {
            try {
                Mailer mailer = new Mailer(cog.getConfig().getFile("EmailNotification.properties"));
                MailFile globalArchive = MailFile.readOrCreate(globalMailArchive);
                globalArchive.sendAllMail(mailer);
                globalArchive.save();
            }
            catch (Exception e) {
                System.out.println("FATAL ERROR HANDLING GLOBAL EMAIL: "+e.toString());
                e.printStackTrace(System.out);
            }
        }
    }

    private void handleAllOverdueScheduledEvents(AuthRequest ar) throws Exception{
        NGPageIndex.assertNoLocksOnThread();
        Mailer mailer = new Mailer(cog.getConfig().getFile("EmailNotification.properties"));

        //default delay is 5 minutes AFTER the scheduled time.  This 5 minutes is to allow people who
        //create something a few minutes to edit before it is sent.  However, this can be set in the
        //properties to be more or less than that.
        int delayTime = 5*60*1000;
        //int delayTime = 0;
        String delayStr = mailer.getProperty("automated.email.delay");
        if (delayStr!=null) {
            //delay time config parameter is in minutes
            delayTime = DOMFace.safeConvertInt(delayStr)*1000*60;
        }

        //System.out.println("BACKGROUND: ----------- begining scan at "
        //        +new Date()+"-------------");

        long nowTime = ar.nowTime;
        List<NGPageIndex> allOverdue = listOverdueContainers(nowTime-delayTime);
        int iCount = 0;
        for (NGPageIndex ngpi : allOverdue) {
            iCount++;
            System.out.println("BACKGROUND: workspace ("+ngpi.containerName+") due since "
                    +new Date(ngpi.nextScheduledAction));
            if (!ngpi.isProject()) {
                System.out.println("BACKGROUND: strange non-Page object has scheduled events --- ignoring it");
                ngpi.nextScheduledAction = 0;
                continue;
            }

            File workspaceCogFolder = ngpi.containerPath.getParentFile();
            File emailArchiveFile = new File(workspaceCogFolder, "mailArchive.json");

            //open and read the archive first .. it is safe becasue this is the only thread
            //that reads the email archive.
            MailFile emailArchive = MailFile.readOrCreate(emailArchiveFile);

            {
                //now open the page and generate all the email messages, remember this
                //locks the file blocking all other threads, so be quick
                NGWorkspace ngw = ngpi.getPage();

                //first, move all the email messages that have been stored in the project from foreground events.
                MailConversions.moveEmails(ngw, emailArchive, cog);

                ngpi.nextScheduledAction = ngw.nextActionDue();
                ngw.save();
                NGPageIndex.clearLocksHeldByThisThread();
                emailArchive.save();
            }

            {
                //now open the page and generate all the email messages, remember this
                //locks the file blocking all other threads, so be quick
                NGWorkspace ngw = ngpi.getPage();

                ArrayList<ScheduledNotification> resList = new ArrayList<ScheduledNotification>();
                ngw.gatherUnsentScheduledNotification(resList);

                int total = resList.size();
                int count = 0;
                for (ScheduledNotification sn : resList) {
                    count++;
                    System.out.println("BACKGROUND: Notification "+count+" of "+total+": "+sn.selfDescription());
                    if (sn.timeToSend()<nowTime) {
                        sn.sendIt(ar, emailArchive);
                    }
                }

                ngpi.nextScheduledAction = ngw.nextActionDue();
                ngw.save(); //save all the changes from the removal of email and scheduling of events
                NGPageIndex.clearLocksHeldByThisThread();

                //now we can go an actually send the email in the mailArchive
                emailArchive.save();
            }


            //now we can go an actually send the email in the mailArchive
            emailArchive.sendAllMail(mailer);

            Thread.sleep(200);  //just small delay to avoid saturation
        }
        if (iCount>0) {
            System.out.println("BACKGROUND: Processed "+iCount+" background events at "+(new Date()));
        }
    }

    private ArrayList<NGPageIndex> listOverdueContainers(long cutoffTime) {
        ArrayList<NGPageIndex> ret = new ArrayList<NGPageIndex>();
        for (NGPageIndex ngpi : cog.getAllContainers()) {
            if (ngpi.nextScheduledAction>0 && ngpi.nextScheduledAction<cutoffTime) {
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
            System.out.println("EmailSender: Checked, it is time to send the daily digest");
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
                // TODO: Change it back to 3 AM after testing
                3, // 3 AM
                0 // zero minutes.
        );

        // first getTime returns a Date, the second gets the long value from the
        // Date
        return cal.getTime().getTime();
    }

    /**
    * Stores an email message in the NGPage project workspace, that will LATER be moved to the
    * MailFile archive and sent.
    */
    public static void containerEmail(OptOutAddr ooa, NGContainer ngc,
            String subject, String emailBody, String from, List<String> attachIds, Cognoscenti cog) throws Exception {
        ooa.assertValidEmail();
        ArrayList<OptOutAddr> addressList = new ArrayList<OptOutAddr>();
        addressList.add(ooa);
        queueEmailNGC(addressList, ngc, subject, emailBody, from, attachIds, cog);
    }

    /**
    * Stores an email message in the NGPage project workspace, that will LATER be moved to the
    * MailFile archive and sent.
    */
    public static void queueEmailNGC(List<OptOutAddr> addresses,
            NGContainer ngc, String subject, String emailBody, String from, List<String> attachIds, Cognoscenti cog)
            throws Exception {
        if (subject == null || subject.length() == 0) {
            throw new ProgramLogicError(
                    "queueEmailNGC requires a non null subject parameter");
        }
        if (emailBody == null || emailBody.length() == 0) {
            throw new ProgramLogicError(
                    "queueEmailNGC requires a non null body parameter");
        }
        if (addresses == null || addresses.size() == 0) {
            throw new ProgramLogicError(
                    "queueEmailNGC requires a non empty addresses parameter");
        }
        if (ngc == null) {
            throw new ProgramLogicError(
                    "queueEmailNGC requires a non null ngc parameter");
        }
        if (from == null) {
            from = composeFromAddress(ngc);
        }
        EmailSender.createEmailRecordInternal(ngc, from, addresses, subject, emailBody, attachIds, cog);
    }


    /**
     * Stores an email message in the NGPage project workspace, that will LATER be moved to the
     * MailFile archive and sent.
     */
    private static void createEmailRecordInternal(NGContainer ngc, String from,
            List<OptOutAddr> addresses, String subject, String emailBody, List<String> attachIds,
            Cognoscenti cog)
            throws Exception {

        try {

            // just checking here that all the addressees have a valid email address.
            // they should not have gotten into the sendTo list without one.
            for (OptOutAddr ooa : addresses) {
                ooa.assertValidEmail();
            }

            EmailRecord emailRec = ngc.createEmail();
            emailRec.setStatus(EmailRecord.READY_TO_GO);
            emailRec.setFromAddress(from);
            emailRec.setCreateDate(System.currentTimeMillis());
            emailRec.setAddressees(addresses);
            emailRec.setBodyText(emailBody);
            emailRec.setSubject(subject);
            emailRec.setProjectId(ngc.getKey());
            emailRec.setAttachmentIds(attachIds);
            ngc.saveWithoutAuthenticatedUser("SERVER", System.currentTimeMillis(), "Sending an email message", cog);

//            EmailRecordMgr.triggerNextMessageSend();
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
    public static void generalMailToOne(OptOutAddr ooa, String from, String subject,
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
    public static void generalMailToList(List<OptOutAddr> addresses, String from,
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
        if (from == null || from.length() == 0) {
            from = emailProperties.getProperty("mail.smtp.from");
        }
        synchronized(globalMailArchive) {
            try {
                MailFile globalArchive = MailFile.readOrCreate(globalMailArchive);
                for (OptOutAddr ooa : addresses) {
                    globalArchive.createEmailRecord(from, ooa.getEmail(), subject, emailBody);
                }
                globalArchive.save();
            }
            catch (Exception e) {
                throw new Exception("Failure while composing an email message for the global archive", e);
            }
        }
    }



    private static String composeFromAddress(NGContainer ngc) throws Exception {
        StringBuffer sb = new StringBuffer("^");
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


}
