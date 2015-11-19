package org.socialbiz.cog.mail;

import org.socialbiz.cog.AuthRequest;

public interface ScheduledNotification {

    public boolean isSent() throws Exception;

    public long timeToSend() throws Exception;

    /**
     * The method sendIt is passed a mailFile so that the called code can add an
     * email message directly into the mail file for sending.  Remember, this method
     * should ONLY be called on the background email processing thread because
     * MailFile is not thread safe.
     */
    public void sendIt(AuthRequest ar, MailFile mailFile) throws Exception;

    public String selfDescription() throws Exception;

}
