package org.socialbiz.cog.mail;

import org.socialbiz.cog.AuthRequest;

public interface ScheduledNotification {

    /**
     * @return true when there is something to send before the timeout
     *         return false if there is no need to send anything more
     */
    public boolean needsSendingBefore(long timeout) throws Exception;

    /**
     * If something still needs sending, then return the date that 
     * it should be sent.    
     * If nothing to send return -1;
     */
    public long futureTimeToSend() throws Exception;

    /**
     * The method sendIt is passed a mailFile so that the called code can add an
     * email message directly into the mail file for sending.  Remember, this method
     * should ONLY be called on the background email processing thread because
     * MailFile is not thread safe.
     */
    public void sendIt(AuthRequest ar, MailFile mailFile) throws Exception;

    public String selfDescription() throws Exception;

}
