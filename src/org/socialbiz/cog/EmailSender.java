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
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
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
    private final static long EVERY_MINUTE = 60000;

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


        // As long as the server is up, the mail should
        // always be sent within 20 minutes of the time it was scheduled to go.

        // second parameter is the "delay" of 60 seconds.
        // The first mailing will be tested one minute from now,
        // and every 20 minutes after that.
        // Note, if the sending of email fails, then it will
        // try again 20 minutes later, and every 20 minutes until it succeeds.
        timer.scheduleAtFixedRate(singletonSender, 60000, EVERY_MINUTE);

        //
        //commented out now we have the new way of handling all background events
        //SendEmailThread sendEmailThread = new SendEmailThread(cog);
        //check if anything needs to be sent every 10 seconds
        //after waiting an initial 60 seconds.
        //timer.scheduleAtFixedRate(sendEmailThread, 60000, 10000);
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
            checkAndSendDailyDigest(ar);
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

    private void handleAllOverdueScheduledEvents(AuthRequest ar) throws Exception{
        long nowTime = ar.nowTime;
        System.out.println("BACKGROUND EVENTS: scanning for all events due before "+new Date(nowTime));
        NGPageIndex ngpi = findOverdueContainer(nowTime);
        int count = 0;
        while (ngpi!=null) {
            if (ngpi.isProject()) {
                NGPage ngp = (NGPage) ngpi.getContainer();
                System.out.println("BACKGROUND EVENTS: found workspace ("+ngp.getFullName()+") due at "+new Date(ngp.nextActionDue()));
                EmailRecord eRec = ngp.getEmailReadyToSend();
                if (eRec!=null) {
                    //priority to sending email
                    System.out.println("BACKGROUND EVENTS: sending an email message to "+eRec.getAddressees().firstElement().getEmail());
                    sendOneEmail(ngp, eRec);
                }
                else {
                    //if no email, then call for the other scheduled actions
                    ngp.performScheduledAction(ar);
                }
                ngpi.nextScheduledAction = ngp.nextActionDue();
                ngp.save();
                System.out.println("BACKGROUND EVENTS: finished action on workspace ("+ngp.getFullName()+")");
                count++;
                NGPageIndex.clearLocksHeldByThisThread();
            }
            else {
                System.out.println("BACKGROUND EVENTS: strange non-Page object has scheduled events --- ignoring it");
                ngpi.nextScheduledAction = 0;
            }
            Thread.sleep(500);  //just small delay to avoid saturation
            ngpi = findOverdueContainer(ar.nowTime);
        }
        System.out.println("BACKGROUND EVENTS: Finished scan, handled "+count+" actions");
    }

    private NGPageIndex findOverdueContainer(long nowTime) {
        for (NGPageIndex ngpi : cog.getAllContainers()) {
            if (ngpi.nextScheduledAction>0 && ngpi.nextScheduledAction<nowTime) {
                return ngpi;
            }
        }
        return null;
    }

/**
 * note: this method has to be outside of both the EmailRecord and the NGPage object
 * because it attempts to cause the sending of email between transactions ... at a time
 * when no transaction is open.   It assumes the NGPage is in memory and gathers the info
 * that it needs.  Then it lets go of the NGPage object, sends the email, and the
 * re-acquires the NGPage object in order to mark that it has sent the mail.
 *
 * You might think this is dangerous because it could send the email, and then later fail to mark it
 * down as being sent.  This could happen in any case even holding the transaction: if you send the
 * email, and then the server fails before saving the file (committing) then you have the same
 * situation.
 *
 * If the email server take 30 or 40 seconds to respond, then
 */
    private void sendOneEmail(NGPage possiblePage, EmailRecord eRec) throws Exception {
        String pageKey = possiblePage.getKey();
        String pageName = possiblePage.getFullName();
        String id = eRec.getId();
        eRec.prepareForSending(possiblePage);
        NGPageIndex.clearLocksHeldByThisThread();
        Exception exHolder = null;

        try {
            //this is done while not holding any locks ....
            //important because some email servers are slow and block for a long time
            //however there is a danger that another thread might modify some of
            //the fields in the mean time.
            sendPreparedMessageImmediately(eRec, cog);
        }
        catch (Exception whatWentWrong) {

            System.out.println("EmailSender: FAILURE while sendOneEmail ("+pageName+") "+whatWentWrong);
            whatWentWrong.printStackTrace(System.out);
            System.out.println("EmailSender: ----------------------------------");
            exHolder = whatWentWrong;

            //slow things down a bit.  We are catching and continuing here, so if this is
            //an error in program, slow it down so it does not fill up the disk with log output.
            Thread.sleep(5000);
        }

        //START the second transaction to update that the message has been sent
        possiblePage =  cog.getProjectByKeyOrFail(pageKey);
        eRec=possiblePage.getEmail(id);

        if (exHolder==null) {
            eRec.setErrorMessage(null);
            eRec.setStatus(EmailRecord.SENT);
        }
        else {
            eRec.setErrorMessage(NGException.getFullMessage(exHolder));
            eRec.setStatus(EmailRecord.FAILED);
        }
        possiblePage.save();
        eRec.setLastSentDate(System.currentTimeMillis());
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
            sendDailyDigest(ar);
        }
    }

    /*
     * This method loops through all known users (with profiles) and sends an
     * email with their tasks on it.
     */
    public void sendDailyDigest(AuthRequest arx) throws Exception {
        DailyDigest.sendDailyDigest(arx, cog);
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

                String rawFrom = eRec.getFromAddress();
                if (rawFrom==null || rawFrom.length()==0) {
                    throw new Exception("Attempt to send an email record that does not have a from address");
                }
                message.setFrom(new InternetAddress(AddressListEntry.cleanQuotes(rawFrom)));
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

            System.out.println("ERROR sendPreparedMessageImmediately "+me);

            //TODO: temporary because someone is swallowing the exception somewhere .. need to find
            me.printStackTrace(System.out);

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

}
