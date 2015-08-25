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
import java.io.StringWriter;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.List;
import java.util.Properties;
import java.util.Timer;
import java.util.TimerTask;
import java.util.Vector;

import javax.activation.DataHandler;
import javax.mail.Authenticator;
import javax.mail.Message;
import javax.mail.Multipart;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeMultipart;
import javax.mail.internet.MimeUtility;

import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.workcast.streams.HTMLWriter;
import org.workcast.streams.MemFile;

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

    // expressed in milliseconds
    private final static long EVERY_TWENTY_MINUTES = 1000 * 60 * 20;

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
     * quickEmail - Send a email to a single email address (as an
     * AddressListEntry) This method sends a single email message to the list of
     * addressees with the given subject and body. You can specify the from
     * address as well.
     *
     * Use this method WHENEVER POSSIBLE. If you don't have an AddressListEntry
     * then use the other form with a string email address.
     */
    public static void quickEmail(OptOutAddr ooa, String from, String subject,
            String emailBody, Cognoscenti cog) throws Exception {
        Vector<OptOutAddr> v = new Vector<OptOutAddr>();
        v.add(ooa);
        simpleEmail(v, from, subject, emailBody, cog);
    }

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

        // apparently a timer task can not be reused by a Timer, or in another
        // Timer.  You have to create them every time you schedule them???
        // TODO: no reason to make these static then
        EmailSender singletonSender = new EmailSender(cog);
        SendEmailThread sendEmailThread = new SendEmailThread(cog);

        // As long as the server is up, the mail should
        // always be sent within 20 minutes of the time it was scheduled to go.

        // second parameter is the "delay" of 60 seconds.
        // The first mailing will be tested one minute from now,
        // and every 20 minutes after that.
        // Note, if the sending of email fails, then it will
        // try again 20 minutes later, and every 20 minutes until it succeeds.
        timer.scheduleAtFixedRate(singletonSender, 60000, EVERY_TWENTY_MINUTES);

        //check if anything needs to be sent every 10 seconds
        //after waiting an initial 60 seconds.
        timer.scheduleAtFixedRate(sendEmailThread, 60000, 10000);
    }

    // This method must be called regularly and frequently, and email is only
    // sent when it it was scheduled
    // The calling of this method has nothing to do with the email schedule /
    // frequency.
    public void run() {
        // make sure that this method doesn't throw any exception
        try {
            checkAndSendDailyDigest();
        } catch (Exception e) {
            Exception failure = new Exception(
                    "Failure in the EmailSender thread run method.  Thread died.",
                    e);
            System.out.println("FATAL FAILURE in EmailSender thread:" + e);
            failure.printStackTrace();
            threadLastCheckException = failure;
        }
        finally {
            //only call this when you are sure you are not holding on to any containers
            NGPageIndex.clearLocksHeldByThisThread();
        }
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
    public void checkAndSendDailyDigest() throws Exception {
        SuperAdminLogFile salf = SuperAdminLogFile.getInstance(cog);
        long lastNotificationSentTime = salf.getLastNotificationSentTime();
        long nextScheduledTime = getNextTime(lastNotificationSentTime + 10000000);
        threadLastCheckTime = System.currentTimeMillis();
        if (threadLastCheckTime > nextScheduledTime) {
            System.out.println("EmailSender: Checked and decided to send the daily digest");
            sendDailyDigest();
        }
        else {
            System.out.println("EmailSender: Checked and decided NOT to send the daily digest "+SectionUtil.getNicePrintDate(threadLastCheckTime));
        }
    }

    /*
     * This method loops through all knowns users (with profiles) and sends an
     * emails with their tasks on it.
     */
    public void sendDailyDigest() throws Exception {
        AuthRequest arx = AuthDummy.serverBackgroundRequest();
        Writer debugEvidence = new StringWriter();

        try {
            // we pick up the time here, at the beginning, so that any new
            // events
            // created AFTER this time, but before the end of this routine are
            // not
            // lost during the processing.
            long processingStartTime = System.currentTimeMillis();
            long lastNotificationSentTime = arx.getSuperAdminLogFile().getLastNotificationSentTime();

            debugEvidence.write("\n<li>Previous send time: ");
            SectionUtil.nicePrintDateAndTime(debugEvidence,lastNotificationSentTime);
            debugEvidence.write("</li>\n<li>Email being sent at: ");
            SectionUtil.nicePrintDateAndTime(debugEvidence, processingStartTime);
            debugEvidence.write("</li>");

            assertEmailConfigOK();

            // if this address is configured, then all email will go to that
            // email address, instead of the address in the profile.
            String overrideAddress = getProperty("overrideAddress");

            Authenticator authenticator = new MyAuthenticator(emailProperties);
            Session mailSession = Session.getInstance(emailProperties,
                    authenticator);

            mailSession.setDebug(Boolean.valueOf(getProperty("mail.debug"))
                    .booleanValue());

            StringWriter bodyOut = null;
            // loop thru all the profiles to send out the email.
            UserProfile[] ups = UserManager.getAllUserProfiles();
            for (UserProfile up : ups) {
                try {
                    String realAddress = up.getPreferredEmail();
                    if (realAddress == null || realAddress.length() == 0) {
                        debugEvidence.write("\n<li>User has no email address: ");
                        HTMLWriter.writeHtml(debugEvidence, up.getUniversalId());
                        debugEvidence.write("</li>");
                        continue;
                    }
                    String toAddress = overrideAddress;
                    if (toAddress == null || toAddress.length() == 0) {
                        toAddress = realAddress;
                    }
                    OptOutAddr ooa = new OptOutAddr(
                            AddressListEntry.parseCombinedAddress(realAddress));

                    // set the body.
                    bodyOut = new StringWriter();
                    AuthDummy clone = new AuthDummy(up, bodyOut, arx.getCogInstance());
                    clone.nowTime = processingStartTime;

                    int numberOfUpdates = 0;

                    clone.write("<html><body>\n");
                    clone.write("<p>Hello ");
                    up.writeLinkAlways(clone);
                    clone.write(",</p>\n");

                    clone.write("<p>This is a daily digest from Cognoscenti for the time period starting <b>");
                    SectionUtil.nicePrintDateAndTime(clone.w,
                            lastNotificationSentTime);
                    clone.write("</b> and ending <b>");
                    SectionUtil.nicePrintDateAndTime(clone.w,
                            processingStartTime);
                    clone.write("</b></p>\n");

                    List<NGContainer> containers = new ArrayList<NGContainer>();
                    for (NotificationRecord record : up.getNotificationList()) {
                        NGContainer ngc = clone.getCogInstance().getProjectByKeyOrFail(record.getPageKey());

                        // users might have items on the notification list that
                        // don't exist, because
                        // they signed up for notification, and then the project
                        // was deleted.
                        if (ngc != null) {
                            containers.add(ngc);
                        }
                    }

                    if (containers.size() > 0) {
                        clone.write("<div style=\"margin-top:15px;margin-bottom:20px;\"><span style=\"font-size:24px;font-weight:bold;\">Project Updates</span>&nbsp;&nbsp;&nbsp;");
                        numberOfUpdates += constructDailyDigestEmail(clone, containers,
                                        lastNotificationSentTime,
                                        processingStartTime);
                    }

                    if (clone.isSuperAdmin(up.getKey())) {
                        String doublecheck = clone
                                .getSystemProperty("superAdmin");
                        if (up.getKey().equals(doublecheck)) {
                            List<SiteRequest> delayedSites = SiteReqFile
                                    .scanAllDelayedSiteReqs();
                            numberOfUpdates += delayedSites.size();
                            writeDelayedSiteList(clone, delayedSites);
                        } else {
                            debugEvidence
                                    .write("\n<li>isSuperAdmin returned wrong result in double check test</li>");
                        }
                    }
                    int numTasks = formatTaskListForEmail(clone, up);

                    int numReminders = writeReminders(clone, up);

                    clone.write("</body></html>");
                    clone.flush();

                    //very important.  Don't hold on to the locks while sending the email because if the
                    //email server is slow (and we have one that is) then all those pages are locked
                    //while talking to the email server.   This frees the locks that are no longer needed.
                    NGPageIndex.clearLocksHeldByThisThread();

                    if ((numberOfUpdates > 0) || numTasks > 0) {
                        String thisSubj = "Daily Digest - " + numberOfUpdates
                                + " updates, " + numTasks + " tasks, "
                                + numReminders + " reminders.";

                        //Actually SEND the email here
                        quickEmail(ooa, null, thisSubj, bodyOut.toString(), cog);


                        debugEvidence.write("\n<li>");
                        HTMLWriter.writeHtml(debugEvidence, thisSubj);
                        debugEvidence.write(" for ");
                        HTMLWriter.writeHtml(debugEvidence,
                                up.getPreferredEmail());
                        debugEvidence.write("</li>");
                    } else {
                        debugEvidence.write("\n<li>nothing for ");
                        HTMLWriter.writeHtml(debugEvidence,
                                up.getPreferredEmail());
                        debugEvidence.write("</li>");
                    }
                } catch (Exception e) {
                    threadLastMsgException = e;
                    arx.logException(
                            "Error while sending daily update message", e);
                    // for some reason if there an error sending an email to a
                    // particular person,
                    // then just ignore that request and proceed with the other
                    // requests.
                    debugEvidence
                            .write("\n\n<li>Unable to send the Email notification to the User : ");
                    HTMLWriter.writeHtml(debugEvidence, up.getName());
                    debugEvidence.write("[");
                    HTMLWriter.writeHtml(debugEvidence, up.getUniversalId());
                    debugEvidence.write("] because ");
                    HTMLWriter.writeHtml(debugEvidence, e.toString());
                }

                //this clears locks if there was an error during sending
                NGPageIndex.clearLocksHeldByThisThread();

            }// for.

            // at the very last moment, if all was successful, mark down the
            // time that we sent it all.
            SuperAdminLogFile.getInstance(cog).setLastNotificationSentTime(processingStartTime,
                    debugEvidence.toString());

        } catch (Exception e) {
            throw new NGException(
                    "nugen.exception.unable.to.send.daily.digest", null, e);
        } finally {
            NGPageIndex.clearLocksHeldByThisThread();
        }
    }


    /**
     * Returns the total number of history records actually found.
     */
    public static int constructDailyDigestEmail(AuthRequest clone,
            List<NGContainer> containers,
            long historyRangeStart, long historyRangeEnd) throws Exception {
        int totalHistoryCount = 0;
        boolean needsFirst = true;

        for (NGContainer container : containers) {
            List<HistoryRecord> histRecs = container.getHistoryRange(
                    historyRangeStart, historyRangeEnd);
            if (histRecs.size() == 0) {
                // skip this if there is nothing to show
                continue;
            }
            String url = clone.retPath
                    + clone.getDefaultURL(container);

            if (needsFirst) {
                clone.write("<a href=\"");
                clone.write(clone.baseURL);
                clone.write("v/");
                clone.writeURLData(clone.getUserProfile().getKey());
                clone.write("/userAlerts.htm\">View Latest</a></div>");

                needsFirst = false;
            }

            clone.write("\n<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\">");
            clone.write("<thead>");
            clone.write("\n<tr>");
            clone.write("\n<td style=\"height:30px\" colspan=\"2\" valign=\"top\">");

            clone.write("<h4><img border=\"0\" align=\"middle\" src=\"");
            clone.write(clone.baseURL);
            clone.write("assets/iconProject.png");
            clone.write("\" alt=\"Project");
            clone.write("\"/>&nbsp;&nbsp;<a href=\"");

            clone.write(url);
            clone.write("\">");
            clone.writeHtml(container.getFullName());
            clone.write("</a></h4></td>");
            clone.write("\n</tr>");
            clone.write("\n</thead>");
            clone.write("<tbody>");

            for (HistoryRecord history : histRecs) {
                ++totalHistoryCount;

                clone.write("<tr>");
                clone.write("<td style=\"width:25px\"></td><td>&bull;&nbsp;&nbsp;");
                // dummy link for the sorting purpose.
                clone.write("<a href=\"");
                clone.write(Long.toString(history.getTimeStamp()));
                clone.write("\"></a>");

                // Get Localized string
                history.writeLocalizedHistoryMessage(container, clone);
                SectionUtil.nicePrintTime(clone.w, history.getTimeStamp(),
                        clone.nowTime);
                if (history.getContextType() != HistoryRecord.CONTEXT_TYPE_PERMISSIONS
                        && history.getComments() != null
                        && history.getComments().length() > 0) {
                    clone.write("<br/>Comments: &raquo;&nbsp;");
                    clone.writeHtml(history.getComments());
                }

                clone.write("</td>");
                clone.write("</tr>");
                clone.write("\n<tr>");
                clone.write("\n  <td style=\"height:5px\"></td>");
                clone.write("\n</tr>");
            }
            clone.write("\n<tr>");
            clone.write("\n  <td style=\"height:15px\"></td>");
            clone.write("\n</tr>");
            clone.write("</tbody>");
            clone.write("</table>");
        }
        return totalHistoryCount;
    }

    private static void writeDelayedSiteList(AuthRequest clone,
            List<SiteRequest> delayedSites) throws Exception {
        clone.write("<table width=\"80%\" class=\"Design8\">");
        clone.write("<thead>");
        clone.write("<tr>");
        clone.write("<th>Site Name</th>");
        clone.write("<th>Requested By</th>");
        clone.write("<th>Requested Date</th>");
        clone.write("<th>Action</th>");
        clone.write("</tr>");
        clone.write("</thead>");
        clone.write("<tbody>");
        for (int i = 0; i < delayedSites.size(); i++) {
            SiteRequest details = delayedSites.get(i);
            clone.write("\n <tr " + ((i % 2 == 0) ? "class=\"Odd\"" : " ")
                    + ">");
            clone.write("<td>");
            clone.write(details.getName());
            clone.write("</td>");
            clone.write("<td>");
            clone.write(details.getUniversalId());
            clone.write("</td>");
            clone.write("<td>");
            clone.writeHtml(SectionUtil.getNicePrintDate(details.getModTime()));
            clone.write("</td>");
            clone.write("<td>");
            clone.write("<a href=\"");
            clone.write(clone.baseURL);
            clone.write("v/approveAccountThroughMail.htm?requestId=");
            clone.writeURLData(details.getRequestId());
            clone.write("\">Click here to Accept/Deny this request</a>");
            clone.write("</td>");
            clone.write("</tr>");
        }
        clone.write("</tbody>");
        clone.write("</table>");
    }

    public static int formatTaskListForEmail(AuthRequest ar, UserProfile up)
            throws Exception {
        int taskNum = 0;
        List<ProjectGoal> tasks = getActiveTaskList(up, ar.getCogInstance());
        if (tasks.size() == 0) {
            return 0;
        }
        ar.write("<div style=\"margin-top:25px;margin-bottom:5px;\"><span style=\"font-size:24px;font-weight:bold;\">Task Updates</span>&nbsp;&nbsp;&nbsp;");

        ar.write("<a href=\"");
        ar.write(ar.baseURL);
        ar.write("v/");
        ar.writeURLData(up.getKey());
        ar.write("/userActiveTasks.htm\">View Latest</a></div>");
        ar.write("\n <table width=\"600\" class=\"Design8\">");
        ar.write("\n <col width=\"30\"/>");
        ar.write("\n <col width=\"500\"/>");
        ar.write("\n <col width=\"100\"/>");
        ar.write("\n <thead> ");
        ar.write("\n <tr>");
        ar.write("\n <th> </th> ");
        ar.write("\n <th>Name</th> ");
        ar.write("\n <th>Due</th>");
        ar.write("\n </tr> ");
        ar.write("\n </thead> ");
        ar.write("\n <tbody>");
        for (ProjectGoal pg : tasks) {
            taskNum++;
            NGPageIndex ngpi = pg.ngpi;
            GoalRecord task = pg.goal;

            ar.write("\n <tr");
            if (taskNum % 2 == 0) {
                ar.write(" class=\"Odd\"");
            }
            ar.write(" valign=\"top\">");

            // task state, name and the page link.
            ar.write("\n <td>");
            ar.write("<a href=\"");
            writeGoalLinkUrl(ar, ngpi, task, up);
            ar.write("\" title=\"access current status of task\">");
            ar.write("<img border=\"0\" align=\"absbottom\" src=\"");
            ar.write(ar.baseURL);
            ar.write(BaseRecord.stateImg(task.getState()));
            ar.write("\" alt=\"");
            ar.writeHtml(GoalRecord.stateName(task.getState()));
            ar.write("\"/></a>&nbsp;</td><td>");
            ar.write("<a href=\"");
            writeGoalLinkUrl(ar, ngpi, task, up);
            ar.write("\" title=\"access current status of task\">");
            ar.writeHtml(task.getSynopsis());
            ar.write("</a> - <a href=\"");
            writeProcessLinkUrl(ar, ngpi);
            ar.write("\" title=\"See the project containing this task\">");
            ar.writeHtml(ngpi.containerName);
            ar.write("</a>");
            ar.write("\n<br/>Status: ");
            ar.writeHtml(task.getStatus());
            ar.write("\n </td>");

            // due date column.
            ar.write("\n <td>");
            if (task.getDueDate() > 0) {
                ar.write(SectionUtil.getNicePrintDate(task.getDueDate()));
            }
            ar.write("\n </td>");
            ar.write("\n </tr>");
        }
        ar.write("\n </tbody>");
        ar.write("\n </table>");
        return taskNum;
    }

    /**
     * Writes a URL of the task details page for a given task
     * along with the magic number and user key for anonymous access.
     */
    private static void writeGoalLinkUrl(AuthRequest ar, NGPageIndex ngpi,
            GoalRecord gr, UserProfile up) throws Exception {
        ar.write(ar.baseURL);
        ar.write("t/");
        ar.writeURLData(ngpi.pageBookKey);
        ar.write("/");
        ar.writeURLData(ngpi.containerKey);
        ar.write("/task");
        ar.writeURLData(gr.getId());
        ar.write(".htm");
        ar.write("?");
        NGPage ngp = (NGPage) ngpi.getContainer();
        ar.write(AccessControl.getAccessGoalParams(ngp, gr));
        ar.write("&ukey=");
        ar.writeURLData(up.getKey());
    }

    private static void writeProcessLinkUrl(AuthRequest ar, NGPageIndex ngpi)
            throws Exception {
        ar.write(ar.baseURL);
        ar.write("t/");
        ar.writeURLData(ngpi.pageBookKey);
        ar.write("/");
        ar.writeURLData(ngpi.containerKey);
        ar.write("/projectAllTasks.htm");
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

    public static void containerEmail(OptOutAddr ooa, NGContainer ngc,
            String subject, String emailBody, String from, Vector<String> attachIds, Cognoscenti cog) throws Exception {
        ooa.assertValidEmail();
        Vector<OptOutAddr> addressList = new Vector<OptOutAddr>();
        addressList.add(ooa);
        queueEmailNGC(addressList, ngc, subject, emailBody, from, attachIds, cog);
    }

    public static void queueEmailNGC(Vector<OptOutAddr> addresses,
            NGContainer ngc, String subject, String emailBody, String from, Vector<String> attachIds, Cognoscenti cog)
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
     * TODO: This should probable be on the NGPage object.
     */
    private static void createEmailRecordInternal(NGContainer ngc, String from,
            Vector<OptOutAddr> addresses, String subject, String emailBody, Vector<String> attachIds, Cognoscenti cog)
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
            ngc.save("SERVER", System.currentTimeMillis(), "Sending an email message", cog);

            //note, this is a little dangerous because there must not be any modifications
            //of ngc after this point!
            NGPageIndex.releaseLock(ngc);

            EmailRecordMgr.triggerNextMessageSend();
        } catch (Exception e) {
            throw new NGException("nugen.exception.unable.to.send.simple.msg",
                    new Object[] { from, subject }, e);
        }
    }

    private static String getUnSubscriptionAsString(OptOutAddr ooa, Cognoscenti cog)
            throws Exception {

        StringWriter bodyWriter = new StringWriter();
        UserProfile up = UserManager.findUserByAnyId(ooa.getEmail());
        AuthRequest clone = new AuthDummy(up, bodyWriter, cog);
        ooa.writeUnsubscribeLink(clone);
        return bodyWriter.toString();
    }

    /**
     * Static version that actually talks to SMTP server and sends the email
     */
    public static void simpleEmail(Vector<OptOutAddr> addresses, String from,
            String subject, String emailBody, Cognoscenti cog) throws Exception {
        EmailSender.instantEmailSend(addresses, subject, emailBody, from, cog);
    }

    /**
     * Creates an email record and then sends it immediately
     * Does NOT associate this with a NGPage object.
     * TODO: check if this should be on a project
     */
    private static void instantEmailSend(Vector<OptOutAddr> addresses, String subject,
            String emailBody, String fromAddress, Cognoscenti cog) throws Exception {
        if (subject == null || subject.length() == 0) {
            throw new ProgramLogicError(
                    "instantEmailSend requires a non null subject parameter");
        }
        if (emailBody == null || emailBody.length() == 0) {
            throw new ProgramLogicError(
                    "instantEmailSend requires a non null body parameter");
        }
        if (addresses == null || addresses.size() == 0) {
            throw new ProgramLogicError(
                    "instantEmailSend requires a non empty addresses parameter");
        }
        if (fromAddress == null || fromAddress.length() == 0) {
            fromAddress = getProperty("mail.smtp.from", "xyz@example.com");
        }

        EmailRecord eRec = EmailRecordMgr.createEmailRecord("TEMP"
                + IdGenerator.generateKey());
        eRec.setAddressees(addresses);
        eRec.setSubject(subject);
        eRec.setBodyText(emailBody);
        eRec.setFromAddress(fromAddress);

        sendPreparedMessageImmediately(eRec, cog);
    }



    public static void sendPreparedMessageImmediately(EmailRecord eRec, Cognoscenti cog)
            throws Exception {
        if (eRec == null) {
            throw new ProgramLogicError(
                    "sendPreparedMessageImmediately requires a non null eRec parameter");
        }

        long sendTime = System.currentTimeMillis();

        //check that server is configured to send email
        if (!"smtp".equals(getProperty("mail.transport.protocol"))) {
            //if protocol is set to anything else, then just ignore this request
            //this is an easy way to disable the sending of email across board
            eRec.setStatus(EmailRecord.SKIPPED);
            eRec.setLastSentDate(sendTime);
            System.out.println("Email skipped, not sent, mail.transport.protocol!=smtp ");
            return;
        }

        String addressForErrorReporting = "(Initial value)";

        Transport transport = null;
        try {
            Authenticator authenticator = new MyAuthenticator(emailProperties);
            Session mailSession = Session.getInstance(emailProperties, authenticator);
            mailSession.setDebug("true".equals(getProperty("mail.debug")));

            transport = mailSession.getTransport();
            transport.connect();

            String overrideAddress = getProperty("overrideAddress");
            Vector<OptOutAddr> addresses = eRec.getAddressees();
            int addressCount = 0;

            // send the message to each addressee individually so they each get
            // their own op-out unsubscribe line.
            for (OptOutAddr ooa : addresses) {

                addressForErrorReporting = ooa.getEmail();

                MimeMessage message = new MimeMessage(mailSession);
                message.setSentDate(new Date(sendTime));

                message.setFrom(new InternetAddress(AddressListEntry.cleanQuotes(eRec.getFromAddress())));
                String encodedSubjectLine = MimeUtility.encodeText(
                        eRec.getSubject(), "utf-8", "B");
                message.setSubject(encodedSubjectLine);

                MimeBodyPart textPart = new MimeBodyPart();
                textPart.setHeader("Content-Type", "text/html; charset=\"utf-8\"");
                textPart.setText(eRec.getBodyText() + getUnSubscriptionAsString(ooa, cog), "UTF-8");
                textPart.setHeader("Content-Transfer-Encoding", "quoted-printable");
                // apparently using 'setText' can change the content type for
                // you automatically, so re-set it.
                textPart.setHeader("Content-Type", "text/html; charset=\"utf-8\"");

                Multipart mp = new MimeMultipart();
                mp.addBodyPart(textPart);
                message.setContent(mp);

                attachFiles(mp, eRec);


                // set the to address.
                InternetAddress[] addressTo = new InternetAddress[1];

                try {
                    // if overrideAddress is configured, then all email will go
                    // to that email address, instead of the address in the profile.
                    if (overrideAddress != null && overrideAddress.length() > 0) {
                        addressTo[0] = new InternetAddress(overrideAddress);
                    } else {
                        addressTo[0] = new InternetAddress(AddressListEntry.cleanQuotes(ooa.getEmail()));
                    }
                } catch (Exception ex) {
                    throw new NGException("nugen.exception.problem.with.address",
                            new Object[] { addressCount, ooa.getEmail() }, ex);
                }

                message.addRecipients(Message.RecipientType.TO, addressTo);
                transport.sendMessage(message, message.getAllRecipients());

                addressCount++;
            }

            eRec.setStatus(EmailRecord.SENT);
            eRec.setLastSentDate(sendTime);
        } catch (Exception me) {
            eRec.setStatus(EmailRecord.FAILED);
            eRec.setLastSentDate(sendTime);
            eRec.setExceptionMessage(me);

            System.out.println("ERROR sendPreparedMessageImmediately");
            dumpProperties(emailProperties);
            throw new NGException("nugen.exception.unable.to.send.simple.msg",
                    new Object[] { addressForErrorReporting, eRec.getSubject() }, me);
        } finally {
            if (transport != null) {
                try {
                    transport.close();
                } catch (Exception ce) { /* ignore this exception */
                    System.out.println("transport.close() threw an exception in a finally block!  Ignored!");
                }
            }
        }
    }

    /**
     * Note that this method needs to work without accessing the NGPage object
     * directly.  We must use only the EmailRecord object alone, by using
     * the attachment contents inside the object.
     */
    private static void attachFiles(Multipart mp, EmailRecord eRec) throws Exception {
        Vector<String> attachids = eRec.getAttachmentIds();
        for (String oneId : attachids) {

            File path = eRec.getAttachPath(oneId);
            MemFile mf = eRec.getAttachContents(oneId);

            MimeBodyPart pat = new MimeBodyPart();
            MemFileDataSource mfds = new MemFileDataSource(mf, path.toString(),
                            MimeTypes.getMimeType(path.getName()));
            pat.setDataHandler(new DataHandler(mfds));
            pat.setFileName(path.getName());
            mp.addBodyPart(pat);
        }
    }

    public static Vector<AddressListEntry> parseAddressList(String list) {
        Vector<AddressListEntry> res = new Vector<AddressListEntry>();
        if (list == null || list.length() == 0) {
            return res;
        }
        String[] values = UtilityMethods.splitOnDelimiter(list, ',');

        for (String value : values) {
            String trimValue = value.trim();
            if (trimValue.length() > 0) {
                res.add(AddressListEntry.parseCombinedAddress(trimValue));
            }
        }
        return res;
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
     * A simple authenticator class that gets the username and password
     * from the properties object if mail.smtp.auth is set to true.
     *
     * documentation on javax.mail.Authenticator says that if you want
     * authentication, return an object, otherwise return null.  So
     * null is returned if no auth setting or user/password.
     */
    private static class MyAuthenticator extends javax.mail.Authenticator {
        private Properties props;

        public MyAuthenticator(Properties _props) {
            props = _props;
        }

        protected PasswordAuthentication getPasswordAuthentication() {
            if ("true".equals(props.getProperty("mail.smtp.auth"))) {
                return new PasswordAuthentication(
                        props.getProperty("mail.smtp.user"),
                        props.getProperty("mail.smtp.password"));
            }
            return null;
        }
    }

    public static int writeReminders(AuthRequest ar, UserProfile up)
            throws Exception {

        int noOfReminders = 0;

        for (NGPageIndex ngpi : ar.getCogInstance().getAllContainers()) {
            // start by clearing any outstanding locks in every loop
            NGPageIndex.clearLocksHeldByThisThread();

            if (!ngpi.isProject()) {
                continue;
            }
            int count = 0;
            NGPage aPage = ngpi.getPage();

            ReminderMgr rMgr = aPage.getReminderMgr();
            Vector<ReminderRecord> rVec = rMgr.getUserReminders(up);
            for (ReminderRecord reminder : rVec) {
                if ("yes".equals(reminder.getSendNotification())) {
                    if (noOfReminders == 0) {
                        ar.write("<div style=\"margin-top:25px;margin-bottom:5px;\">");
                        ar.write("<span style=\"font-size:24px;font-weight:bold;\">");
                        ar.write("Reminders To Share Document</span>&nbsp;&nbsp;&nbsp;");

                        ar.write("<a href=\"");
                        ar.write(ar.baseURL);
                        ar.write("v/");
                        ar.writeURLData(up.getKey());
                        ar.write("/userActiveTasks.htm\">View Latest </a>");
                        ar.write("(Below is list of reminders of documents which you are requested to upload.)</div>");
                        ar.write("\n <table width=\"800\" class=\"Design8\">");
                        ar.write("\n <thead> ");
                        ar.write("\n <tr>");
                        ar.write("\n <th></th> ");
                        ar.write("\n <th>Document to upload</th> ");
                        ar.write("\n <th>Requested By</th> ");
                        ar.write("\n <th>Sent On</th>");
                        ar.write("\n <th>Project</th>");
                        ar.write("\n </tr> ");
                        ar.write("\n </thead> ");
                        ar.write("\n <tbody>");
                    }

                    ar.write("\n <tr");
                    if (count % 2 == 0) {
                        ar.write(" class=\"Odd\"");
                    }
                    ar.write(" valign=\"top\">");

                    ar.write("\n <td>");
                    ar.write("<a href=\"");
                    writeReminderLink(ar, up, aPage, reminder);
                    ar.write("\" title=\"access details of reminder\">");
                    ar.write("<img src=\"");
                    ar.write(ar.baseURL);
                    ar.write("assets/iconUpload.png\" />");
                    ar.write("</a> ");
                    ar.write("</td>");

                    ar.write("\n <td>");

                    ar.write("<a href=\"");
                    writeReminderLink(ar, up, aPage, reminder);
                    ar.write("\" title=\"access details of reminder\">");
                    ar.writeHtml(reminder.getSubject());
                    ar.write("</a> ");

                    ar.write("\n </td>");

                    ar.write("\n <td>");
                    (new AddressListEntry(reminder.getModifiedBy()))
                            .writeLink(ar);
                    // ar.write(reminder.getModifiedBy());
                    ar.write("\n </td>");

                    ar.write("\n <td>");
                    SectionUtil.nicePrintTime(ar, reminder.getModifiedDate(),
                            ar.nowTime);
                    ar.write("\n </td>");

                    ar.write("\n <td>");
                    ar.write("<a href='");
                    ar.write(ar.baseURL);
                    ar.write("t/");
                    ar.writeURLData(ngpi.pageBookKey);
                    ar.write("/");
                    ar.writeURLData(ngpi.containerKey);
                    ar.write("/reminders.htm' >");
                    ar.writeHtml(aPage.getFullName());
                    ar.write("</a>");
                    ar.write("\n </td>");

                    ar.write("\n </tr>");

                    noOfReminders++;
                }
            }
        }
        ar.write("\n </tbody>");
        ar.write("\n </table>");
        return noOfReminders;
    }

    private static void writeReminderLink(AuthRequest ar, UserProfile up,
            NGPage aPage, ReminderRecord reminder) throws Exception {
        ar.write(ar.baseURL);
        ar.write("t/");
        ar.writeURLData(aPage.getSiteKey());
        ar.write("/");
        ar.writeURLData(aPage.getKey());
        ar.write("/remindAttachment.htm?rid=");
        ar.writeURLData(reminder.getId());
        ar.write("&");
        ar.write(AccessControl.getAccessReminderParams(aPage, reminder));
        ar.write("&emailId=");
        ar.writeURLData(up.getPreferredEmail());
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

    public static void dumpProperties(Properties props) {

        for (String key : props.stringPropertyNames()) {
            System.out.println("  ** Property "+key+" = "+props.getProperty(key));
        }
    }

    /**
     * use this to send a quick test message
     * using the server configuration
     */
    public static void sendTestEmail() throws Exception {
        Properties props = emailProperties;

        try {
            final String fromAddress = props.getProperty("mail.smtp.from");
            if (fromAddress==null) {
                throw new Exception("In order to send a test email, configure a setting for mail.smtp.from in the email properties file");
            }
            final String destAddress = props.getProperty("mail.smtp.testAddress");
            if (destAddress==null) {
                throw new Exception("In order to send a test email, configure a setting for mail.smtp.testAddress in the email properties file");
            }
            final String msgText = "This is a sample email message sent "+(new Date()).toString();

            // these should be set already -- for GOOGLE
            // props.put("mail.smtp.starttls.enable", "true");
            // props.put("mail.smtp.auth", "true");
            // props.put("mail.smtp.host", "smtp.gmail.com");
            // props.put("mail.smtp.port", "587");

            Authenticator authenticator = new MyAuthenticator(props);
            Session session = Session.getInstance(props, authenticator);

            Message message = new MimeMessage(session);
            message.setFrom(new InternetAddress(fromAddress));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(destAddress));
            message.setSubject("Testing Subject");
            message.setText(msgText);

            Transport.send(message);

            System.out.println("Sent test mail to " + destAddress);
        }
        catch (Exception e) {
            System.out.println("ERROR sending email message");
            dumpProperties(props);
            e.printStackTrace();
            throw e;
        }

    }

    /**
     * Sometimes testing email settings can be a pain, so this main routine
     * allows for an easy way, in Eclipse or on the command line to
     * test email sending without TomCat or anything else around.
     *
     * Parameters are:
     * 0: your user name
     * 1: your password
     *
     * Enter the other test values (destination address, from address, host, port)
     * directly into the code below.
     */
    public static void main(String[] args) {
        if (args.length < 2) {
            System.out.println("Format: EmailSender <user> <password>");
            return;
        }
        emailProperties = new Properties();

        emailProperties.put("mail.smtp.starttls.enable", "true");
        //emailProperties.put("mail.smtp.starttls.require", "true");
        emailProperties.put("mail.smtp.auth", "true");
        emailProperties.put("mail.smtp.host", "smtp.gmail.com");
        emailProperties.put("mail.smtp.port", "587");
        emailProperties.put("mail.smtp.user", args[0]);
        emailProperties.put("mail.smtp.password",args[1]);
        emailProperties.put("mail.smtp.from", "keith2010@kswenson.oib.com");
        emailProperties.put("mail.smtp.testAddress", "demotest@kswenson.oib.com");

        try {
            sendTestEmail();
            return ;
        }
        catch(Exception e) {
            e.printStackTrace();
            return ;
        }
    }


    // operation get task list.
    public static List<ProjectGoal> getActiveTaskList(UserProfile up, Cognoscenti cog) throws Exception {

        Vector<ProjectGoal> activeTask = new Vector<ProjectGoal>();

        if (up == null) {
            throw new Exception("can not get list of goals for userwhich is null");
        }

        for (NGPageIndex ngpi : cog.getAllContainers()) {
            // start by clearing any outstanding locks in every loop
            NGPageIndex.clearLocksHeldByThisThread();

            if (!ngpi.isProject()) {
                continue;
            }
            NGPage aPage = ngpi.getPage();
            for (GoalRecord gr : aPage.getAllGoals()) {
                if (gr.isPassive()) {
                    //ignore tasks that are from other servers
                    continue;
                }
                if (!gr.isAssignee(up)) {
                    continue;
                }
                int state = gr.getState();
                if (state == BaseRecord.STATE_ERROR) {
                    if (gr.isAssignee(up)) {
                        activeTask.add(new ProjectGoal(gr, aPage, cog));
                    }
                }
                else if (state == BaseRecord.STATE_ACCEPTED || state == BaseRecord.STATE_STARTED
                        || state == BaseRecord.STATE_WAITING) {
                    // the assignee should see this task in the active task list.
                    if (gr.isAssignee(up)) {
                        activeTask.add(new ProjectGoal(gr, aPage, cog));
                    }
                }
            }
        }

        return activeTask;
    }


    static class ProjectGoal {

        public GoalRecord goal;
        public NGPageIndex ngpi;


        public ProjectGoal(GoalRecord aGoal, NGPage aPage, Cognoscenti cog) throws Exception {
            goal = aGoal;
            ngpi = cog.getContainerIndexByKey(aPage.getKey());
        }
    }
}
