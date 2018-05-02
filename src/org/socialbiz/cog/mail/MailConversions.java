package org.socialbiz.cog.mail;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.socialbiz.cog.AddressListEntry;
import org.socialbiz.cog.Cognoscenti;
import org.socialbiz.cog.EmailRecord;
import org.socialbiz.cog.NGContainer;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.NGWorkspace;
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

    public static void moveEmails(NGContainer ngp, MailFile newArchive, Cognoscenti cog) throws Exception {
        List<EmailRecord> allEmail = ngp.getAllEmail();
        for (EmailRecord er : allEmail) {
            AddressListEntry fromAle = new AddressListEntry(er.getFromAddress());
            List<OptOutAddr> allAddressees = er.getAddressees();
            for (OptOutAddr oaa : allAddressees) {
                //create a message for each addressee ... actually there is
                //usually only one so this usually creates only a single email
                MailInst inst = newArchive.createMessage();
                inst.setAddressee(oaa.getEmail());
                inst.setStatus(er.getStatus());
                inst.setSubject(er.getSubject());
                inst.setFromAddress(fromAle.getEmail());
                inst.setFromName(fromAle.getName());
                oaa.prepareInternalMessage(cog);
                inst.setBodyText(er.getBodyText()+oaa.getUnSubscriptionAsString());
                inst.setLastSentDate(er.getLastSentDate());
                inst.setCreateDate(er.getCreateDate());
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
            }
        }

        ngp.clearAllEmail();
    }

}
