package org.socialbiz.cog.mail;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.Cognoscenti;
import org.socialbiz.cog.EmailRecord;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.OptOutAddr;

public class MailConversions {

    public static void moveEmails(NGPage ngp, File projectfolder, Cognoscenti cog) throws Exception {
        File folder = ngp.getFilePath().getParentFile();
        File emailFilePath = new File(folder, "mailArchive.json");

        MailFile newArchive = MailFile.readOrCreate(emailFilePath);
        moveEmails(ngp, newArchive, cog);

        newArchive.save();
        ngp.save();
    }

    public static void moveEmails(NGPage ngp, MailFile newArchive, Cognoscenti cog) throws Exception {
        List<EmailRecord> allEmail = ngp.getAllEmail();
        for (EmailRecord er : allEmail) {
            List<OptOutAddr> allAddressees = er.getAddressees();
            for (OptOutAddr oaa : allAddressees) {
                //create a message for each addressee ... actually there is
                //usually only one so this usually creates only a single email
                MailInst inst = newArchive.createMessage();
                inst.setAddressee(oaa.getEmail());
                inst.setStatus(er.getStatus());
                inst.setSubject(er.getSubject());
                inst.setFrom(er.getFromAddress());
                oaa.prepareInternalMessage(cog);
                inst.setBodyText(er.getBodyText()+oaa.getUnSubscriptionAsString());
                inst.setLastSentDate(er.getLastSentDate());
                inst.setExceptionMessage(er.getExceptionMessage());
                inst.setCreateDate(er.getCreateDate());
                ArrayList<File> attachments = new ArrayList<File>();
                for (String id : er.getAttachmentIds()) {
                    File path = ngp.getAttachmentPathOrNull(id);
                    if (path!=null) {
                        attachments.add(path);
                    }
                }
                inst.setAttachmentFiles(attachments);
                System.out.println("MAILConverter: moved email from workspace to archive:  "+inst.getSubject());
            }
        }

        ngp.clearAllEmail();
    }

    public static void sendAllMail(File projectfolder, AuthRequest ar) throws Exception {

        File emailFilePath = new File(projectfolder, "mailArchive.json");
        if (!emailFilePath.exists()) {
            throw new Exception("the mail archieve does ont exist: "+emailFilePath);
        }
        MailFile newArchive = MailFile.readOrCreate(emailFilePath);

        Mailer mailer = new Mailer(ar.getCogInstance().getConfig().getFile("EmailNotification.properties"));

        List<MailInst> allEmail = newArchive.getAllMessages();

        for (MailInst inst : allEmail) {

            if (MailInst.READY_TO_GO.equals(inst.getStatus())) {
                inst.sendPreparedMessageImmediately(mailer);
            }
        }
    }



}
