package org.socialbiz.cog;

public interface EmailContext {

    public String emailSubject() throws Exception;

    public String getTargetRole()  throws Exception;

    public String getResourceURL(AuthRequest ar, NGPage ngp) throws Exception;

    public String selfDescription() throws Exception;

    /*
     * The comment will call this when the email is sent, which is the official
     * time of the change, allowing the note to mark that it has been changed
     * because of the sending of the comment.  Draft comments don't count.
     * Only posted comments at the time of the sending of the email.
     * Meetings don't care about this.
     */
    public void markTimestamp(long newTime) throws Exception;

}
