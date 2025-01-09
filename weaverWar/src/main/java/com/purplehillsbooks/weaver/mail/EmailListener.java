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
import java.io.IOException;
import java.io.Writer;
import java.util.HashSet;
import java.util.Properties;
import java.util.Timer;
import java.util.TimerTask;

import jakarta.mail.Address;
import jakarta.mail.Authenticator;
import jakarta.mail.BodyPart;
import jakarta.mail.FetchProfile;
import jakarta.mail.Flags.Flag;
import jakarta.mail.Folder;
import jakarta.mail.Message;
import jakarta.mail.Multipart;
import jakarta.mail.PasswordAuthentication;
import jakarta.mail.Session;
import jakarta.mail.Store;
import jakarta.mail.UIDFolder;
import jakarta.mail.internet.MimeBodyPart;
import javax.swing.text.html.HTMLEditorKit;

import com.purplehillsbooks.weaver.AuthDummy;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.Cognoscenti;
import com.purplehillsbooks.weaver.CommentContainer;
import com.purplehillsbooks.weaver.CommentRecord;
import com.purplehillsbooks.weaver.HtmlToWikiConverter;
import com.purplehillsbooks.weaver.NGPageIndex;
import com.purplehillsbooks.weaver.NGWorkspace;
import com.purplehillsbooks.weaver.SectionUtil;
import com.purplehillsbooks.weaver.SuperAdminLogFile;
import com.purplehillsbooks.weaver.UserManager;
import com.purplehillsbooks.weaver.UserProfile;
import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.weaver.util.MongoDB;
import com.purplehillsbooks.json.JSONException;

public class EmailListener extends TimerTask{

    private static EmailListener singletonListener = null;
    public MongoDB db;

    public static Exception threadLastCheckException = null;

    //expressed in milliseconds
    private final static long EVERY_MINUTE = 1000*60;

    private static Session session = null;

    private File emailPropFile = null;
    private static Properties emailProperties = null;
    private AuthRequest ar;
    private static HashSet<String> alreadyProcessed = new HashSet<String>();

    //TODO: this can probably be eliminated, and replaced with the PAUSE/REINIT model
    public static boolean propertiesChanged = false;
    public static long lastFolderRead;
    private Cognoscenti cog;

    private EmailListener(Cognoscenti _cog) throws Exception {
        this.ar = AuthDummy.serverBackgroundRequest();
        this.emailPropFile = this.ar.getCogInstance().getConfig().getFile("EmailNotification.properties");
        setEmailProperties(emailPropFile);
        db = new MongoDB();
        cog = _cog;
    }

    public static void shutDown() {
        singletonListener.db.close();
        singletonListener.db = null;
    }

    /**
     * This is an initialization routine, and should only be called once, when the
     * server starts up.  There are some error checks to make sure that this is the case.
     */
     public static void initListener(Timer timer, Cognoscenti _cog) throws Exception
     {
        /**
         * DISABLING the POP listener since we are not using it, and it makes a lot 
         * of noise in the log file
         * 
         * 
         singletonListener = new EmailListener(_cog);
         String user = emailProperties.getProperty("mail.pop3.user");
         if (user==null || user.length()==0) {
             System.out.println("Email listener: no configuration for mail.pop3.user");
             return;
         }
         String pwd = emailProperties.getProperty("mail.pop3.password");
         if (pwd==null || pwd.length()==0) {
             System.out.println("Email listener: no configuration for mail.pop3.password");
             return;
         }
         timer.scheduleAtFixedRate(singletonListener, 60000, EVERY_MINUTE);
         */
     }

     static long lastRunTime = 0;
     static Exception lastException = null;

     // this is the minimum pause since last time.   This pause is bigger when it gets
     // an error.   45 seconds if no error,   5 min if error is coming.
     static long minPause = 45000;

     public void run() {
        if (db == null) {
           System.out.println("INVALID CALL - EmailListener.run called after being closed.");
           return;
        }
        System.out.println("EmailListener started on thread: "+Thread.currentThread().getName() + " -- " + SectionUtil.currentTimestampString());
         // When you computer goes to sleep for a while and wakes up, the Java
         // system will send you all the events to make up for all the events it
         // missed while asleep.   We don't really need that.  Every time we get an
         // event we pick up all the email.  We expect a tick every minute, so
         // ignore any timer ticks if it has not been at least 45 seconds.
         long nowTime = System.currentTimeMillis();
         if (nowTime - lastRunTime < minPause) {
             //less than 45 seconds since last run, just exit quickly
             return;
         }
         lastRunTime = nowTime;

         // make sure that this method doesn't throw any exception
         try
         {
             // start by checking the configuration, and just skip out if not configured
             // TODO: need a better way to report these configuration problem
             // for now, just exit without a fuss
             if(emailProperties == null) {
                 System.out.println("Email listener: is not configured");
                 return;
             }
             String user = emailProperties.getProperty("mail.pop3.user");
             if (user==null || user.length()==0) {
                 System.out.println("Email listener: no configuration for mail.pop3.user");
                 return;
             }
             String pwd = emailProperties.getProperty("mail.pop3.password");
             if (pwd==null || pwd.length()==0) {
                 System.out.println("Email listener: no configuration for mail.pop3.password");
                 return;
             }

             //the same AuthRequest object is used over and over.  Need to
             //refresh the time setting for this use so trace shows a good time.
             ar.nowTime = nowTime;

             //now really attempt to read the email.  Errors after this point recorded in file
             handlePOP3Folder();

             //if you make it here, then no exception thrown, so clear out any cache that is there
             //and make the delay to be 45 seconds.
             lastException = null;
             minPause = 45000;
         }
         catch(Exception e) {
             if (exceptionsAreEqual(lastException, e)) {
                 System.out.println("EMAIL LISTENER PROBLEM: same failure. "+SectionUtil.currentTimestampString());
                 //make the delay 5 minutes before trying again
                 minPause = 300000;
                 return;
             }
             lastException = e;
             Exception failure = new Exception("Failure in the EmailListener TimerTask run method.", e);
             ar.logException("EMAIL LISTENER PROBLEM: ", failure);
             threadLastCheckException = failure;
             try {
                 SuperAdminLogFile salf = ar.getSuperAdminLogFile();
                 salf.setEmailListenerWorking(false);
                 salf.setEmailListenerProblem(failure);
             }
             catch (Exception ex) {
                 ar.logException("Could not set EmailListenerPropertiesFlag in superadmin.logs file.", ex);
             }
         }
     }


    public boolean exceptionsAreEqual(Exception e1, Exception e2) {
        Throwable t1 = e1;
        Throwable t2 = e2;
        while (t1!=null && t2!=null) {
            String m1 = t1.getMessage();
            if (m1==null) {
                m1="~";
            }
            String m2 = t2.getMessage();
            if (m2==null) {
                m2="~";
            }
            if (!m1.equals(m2)) {
                return false;
            }
            t1 = t1.getCause();
            t2 = t2.getCause();
        }
        if (t1 != null || t2!=null) {
            return false;
        }
        return true;
    }

    public Session getSession()throws Exception {
        try {
            if(emailProperties == null){
                throw WeaverException.newBasic("Email Configuration not initialized from: %s", emailPropFile.getAbsolutePath());
            }

            String user = emailProperties.getProperty("mail.pop3.user");
            if (user==null || user.length()==0) {
                throw WeaverException.newBasic("In order to read email, there must be a setting for 'mail.pop3.user' in %s.",emailPropFile.getAbsolutePath());
            }
            String pwd = emailProperties.getProperty("mail.pop3.password");
            if (pwd==null || pwd.length()==0) {
                throw WeaverException.newBasic("In order to read email, there must be a setting for 'mail.pop3.password' in %s.",emailPropFile.getAbsolutePath());
            }

            return Session.getInstance(emailProperties, new EmailAuthenticator(user, pwd));
        }
        catch (Exception e) {
            throw WeaverException.newWrap("Unable to get the user session", e);
        }
    }

    public Store getPOP3Store() throws Exception {
        try {
            if(session == null || propertiesChanged ){
                session = getSession();
                propertiesChanged = false;
            }
            return session.getStore("pop3");

        }
        catch (Exception e) {
            throw WeaverException.newWrap("Unable to initialize the POP3 store", e);
        }
    }

    private Folder connectToMailServer()throws Exception {
        Store store = null;
        try {

            store = getPOP3Store();
            store.connect();

            Folder popFolder = store.getFolder("INBOX");
            popFolder.open(Folder.READ_WRITE);
            if (!popFolder.isOpen()) {
                throw WeaverException.newBasic("for some reason the 'INBOX' folder was not opened.");
            }

            ar.getSuperAdminLogFile().setEmailListenerWorking(true);

            return popFolder;

        }
        catch (Exception e) {
            throw WeaverException.newWrap("Unable to connect to mail server", e);
        } finally {
            // close the store.
            // but wait!  Won't that close the folder?
            if (store != null) {
                /*
                try {
                    store.close();
                }
                catch (Exception me) {
                    // ignore this exception
                }
                */
            }
        }
    }

    private void handlePOP3Folder() throws Exception {
        Folder popFolder = null;
        try {
            System.out.println("WEAVERPOP handlePOP3Folder "+SectionUtil.getDateAndTime(System.currentTimeMillis()));
            popFolder = connectToMailServer();

            if (!popFolder.isOpen()) {
                throw WeaverException.newBasic("for some reason the 'INBOX' folder was not opened.");
            }
            Message[] messages = popFolder.getMessages();
            if (messages == null || messages.length == 0) {
                // nothing to process.
                return;
            }

            FetchProfile fp = new FetchProfile();
            fp.add(UIDFolder.FetchProfileItem.UID);
            popFolder.fetch(messages, fp);

            System.out.println("WEAVERPOP handlePOP3Folder found "+messages.length+" messages.");
            for (int i = 0; i < messages.length; i++) {
                Message message = messages[i];
                String subject = message.getSubject();

                // most of the POP mail servers/providers does not support flags
                // for other then delete
                if (message.isSet(Flag.DELETED)) {
                    continue;
                }

                //this just makes sure we avoid multiple processing when DELETE is not working
                String signature = subject + message.getSentDate();
                if (alreadyProcessed.contains(signature)) {
                    //skip processing of messages already seen
                    continue;
                }
                alreadyProcessed.add(signature);



                MailInst msg = new MailInst();
                msg.setSiteKey("~");
                msg.setWorkspaceKey("~");
                msg.setSubject(subject);
                msg.setStatus(MailInst.RECEIVED);

                //returns an array, but keep just the first one if any
                Address[] from = message.getFrom();
                if (from!=null) {
                    for (Address oneFrom : from) {
                        msg.setFromAddress(oneFrom.toString());
                        break;
                    }
                }

                parseAndSetBody(msg, message);
                parseLinkKey(msg, subject);

                System.out.println("WEAVERPOP handlePOP3Folder message "+i+"-----------------\n"+msg.getListableJSON().toString(2)+"\n-----------------");


                try {
                    processEmailMsg(msg);
                    message.setFlag(Flag.DELETED, true);
                }
                catch (Exception e) {
                    //failure of one message should not stop the processing of other email messages
                    //this is kind of dangerous...should have a list of previously processed
                    //messages someplace.
                    ar.logException("Error Processing Message "+i, e);
                }
            }
            lastFolderRead = System.currentTimeMillis();

        }
        catch (Exception e) {
            throw WeaverException.newWrap("Failure while reading the POP3 mail server", e);
        }
        finally {
            try {
                if(popFolder != null){
                    popFolder.close(true);
                }
            }
            catch (Exception e) {
                /* ignore this exception */
            }
        }
    }

    private MailInst parseLinkKey(MailInst msg, String subject) throws Exception {

        int bracketPos = subject.indexOf("[$");
        if (bracketPos < 0) {
            System.out.println("WEAVERPOP ******* FAIL: No start token in subject: "+subject);
            return null;
        }
        int endPos = subject.indexOf("]", bracketPos);
        if (endPos<0) {
            System.out.println("WEAVERPOP ******* FAIL: No end token in subject: "+subject);
            return null;
        }
        String emailLocator = subject.substring(bracketPos+2, endPos);

        long oldMsgId = MailInst.getCreateDateFromLocator(emailLocator);

        MailInst oldMail = EmailSender.findEmailById(oldMsgId);

        if (oldMail==null) {
            System.out.println("WEAVERPOP ********** FAIL: got email reply, but original email not found: "+oldMsgId);
            return null;
        }


        System.out.println("WEAVERPOP  Found old email and processing: "+emailLocator);
        msg.setCommentContainer(oldMail.getCommentContainer());
        msg.setSiteKey(oldMail.getSiteKey());
        msg.setWorkspaceKey(oldMail.getWorkspaceKey());
        return oldMail;
    }

    private void parseAndSetBody(MailInst msg, Message message) throws Exception {
        String body = null;
        Object messageContent = message.getContent();
        if (!(messageContent instanceof Multipart)) {
            System.out.println("WEAVERPOP ********** FAIL: unknown message type: "+messageContent.getClass().getCanonicalName());
            msg.setBodyText("Message received had an unknown message type: "+messageContent.getClass().getCanonicalName());
            return;
        }
        Multipart multipart = (Multipart) messageContent;
        int count = multipart.getCount();
        for (int ii=0; ii<count; ii++) {
            BodyPart bp = multipart.getBodyPart(ii);
            if (!(bp instanceof MimeBodyPart))  {
                System.out.println("WEAVERPOP ********** FAIL: unknown body part type: "+bp.getClass().getCanonicalName());
                continue;
            }
            MimeBodyPart mbp = (MimeBodyPart) bp;
            Object mbpContent = mbp.getContent();
            if (!(mbpContent instanceof String)) {
                System.out.println("WEAVERPOP ********** FAIL: unknown body part content type: "+mbpContent.getClass().getCanonicalName());
                continue;
            }
            body = (String) mbpContent;
        }

        if (body==null) {
            System.out.println("WEAVERPOP ********** FAIL: message did not have any body parts: ");
            msg.setBodyText("Message received did not have any body parts: ");
            return;
        }

        //System.out.println("WEAVERPOP DUMP body text\n"+body+"\n=========================");

        //This is currently the text that we put at the start of the bottom of the comment message
        //if we find this exact phrase, then delete it and everything after it.
        //we can be somewhat confident that everything after this is not user text.
        String trailerBlock = "<b>ACTION: <a href";
        int trailerPos = body.indexOf(trailerBlock);
        if (trailerPos>0) {
            body = body.substring(0,trailerPos);
        }
        trailerBlock = "<div style=\"color:grey;font-weight:bold;\">ACTION:";
        trailerPos = body.indexOf(trailerBlock);
        if (trailerPos>0) {
            body = body.substring(0,trailerPos);
        }
        trailerBlock = "<div id=\"trimPoint\"";
        trailerPos = body.indexOf(trailerBlock);
        if (trailerPos>0) {
            body = body.substring(0,trailerPos);
        }


        msg.setBodyText(body);
    }

    private void processEmailMsg(MailInst msg) throws Exception {
        try{

            storeInboundMsg(msg);

            String siteKey = msg.getSiteKey();
            String workspaceKey = msg.getWorkspaceKey();
            if (siteKey==null || siteKey.length()==0) {
                System.out.println("WEAVERPOP: email did not have a site key");
                return;
            }
            if (workspaceKey==null || workspaceKey.length()==0) {
                System.out.println("WEAVERPOP: email did not have a workspace key");
                return;
            }
            NGPageIndex ngpi = cog.getWSBySiteAndKey(siteKey,workspaceKey);
            if (ngpi==null) {
                System.out.println("WEAVERPOP: could not find workspace with "+siteKey+" and "+workspaceKey);
                return;
            }
            NGWorkspace ngw = ngpi.getWorkspace();
            String containerKey = msg.getCommentContainer();
            if (containerKey==null) {
                System.out.println("WEAVERPOP: did not find  a containerKey");
                return;
            }

            CommentContainer cc = ngw.findContainerByKey(containerKey);
            if (cc == null) {
                System.out.println("WEAVERPOP: did not find container with "+containerKey);
                return;
            }

            String userEmail = msg.getFromAddress();
            if (userEmail==null) {
                System.out.println("WEAVERPOP: did not find the from address from the message");
                return;
            }

            cog.getUserManager();
            UserProfile hintedUser = UserManager.lookupUserByAnyId(userEmail);
            if (hintedUser == null) {
                return;
            }
            ar.setPossibleUser(hintedUser);
            ar.nowTime = System.currentTimeMillis();

            CommentRecord cr = cc.addComment(ar);
            String markdown = HtmlToWikiConverter.htmlToWiki(msg.getBodyText());
            cr.setContent(markdown);
            cr.setState(CommentRecord.COMMENT_STATE_CLOSED);

            ngw.saveFile(ar, "received email");
            //this should re-send the email back out again to the others.


        }
        catch (Exception e) {
            //May be in this case we should also send reply to sender stating that 'topic could not be created due to some reason'.
            throw WeaverException.newWrap("Unable to process email message subject=%s", e, msg.getSubject());
        }
        finally {
            NGPageIndex.clearLocksHeldByThisThread();
        }
    }

    private void storeInboundMsg(MailInst message) throws Exception {

        System.out.println("WEAVERPOP storeInboundMsg "+message.toString());

        db.createRecord(message.getJSON());
    }



    private Properties setEmailProperties(File emailPropFile) throws Exception {

        if (!emailPropFile.exists()) {
            throw WeaverException.newBasic("Email configuration not initialized: %s", emailPropFile.getAbsolutePath());
        }

        emailProperties = new Properties();
        FileInputStream fis = new FileInputStream(emailPropFile);
        emailProperties.load(fis);

        emailProperties.setProperty("mail.pop3.connectionpooltimeout", "500");
        emailProperties.setProperty("mail.pop3.connectiontimeout", "500");
        emailProperties.setProperty("mail.pop3.timeout", "500");

        return emailProperties;
    }

    public static EmailListener getEmailListener(){
        return singletonListener;
    }

    public static Properties getEmailProperties(){
        return emailProperties;
    }
    public File getEmailPropertiesFile(){
        return emailPropFile;
    }

    public void reStart() {
        propertiesChanged = true;
        run();
    }

}

class EmailAuthenticator extends Authenticator {
    private PasswordAuthentication auth;

    public EmailAuthenticator(String username, String password) {
        auth = new PasswordAuthentication(username, password);
    }

    protected PasswordAuthentication getPasswordAuthentication() {
        return auth;
    }
}

class Outliner extends HTMLEditorKit.ParserCallback {

    private Writer out;

    public Outliner(Writer out) {
        this.out = out;
    }

    public void handleText(char[] text, int position) {
        try {
            out.write(text);
            out.flush();
        }
        catch (IOException ioe) {
            JSONException.traceException(ioe, "Outliner.handleText extended from HTMLEditorKit.ParserCallback.handleText");
            /* Ignore this Exception */
        }
    }
}
