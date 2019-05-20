package org.socialbiz.cog.mail;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.socialbiz.cog.AddressListEntry;
import org.socialbiz.cog.Cognoscenti;
import org.socialbiz.cog.EmailRecord;
import org.socialbiz.cog.NGContainer;
import org.socialbiz.cog.NGWorkspace;
import org.socialbiz.cog.OptOutAddr;

public class MailConversions {

    /*
    public static void moveEmails(NGPage ngp, File projectfolder, Cognoscenti cog) throws Exception {
        File folder = ngp.getFilePath().getParentFile();
        File emailFilePath = new File(folder, "mailArchive.json");

        MailFile newArchive = MailFile.readOrCreate(emailFilePath, 3);
        moveEmails(ngp, newArchive, cog);

        newArchive.save();
        ngp.save();
    }
    */

    /**
     * returns TRUE if some email was converted, false if not
     */
    public static boolean moveEmails(NGContainer ngp, MailFile newArchive, Cognoscenti cog) throws Exception {
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
        return true;
    }

}
