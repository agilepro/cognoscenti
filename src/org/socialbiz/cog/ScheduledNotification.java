package org.socialbiz.cog;

public interface ScheduledNotification {

    public boolean isSent() throws Exception;

    public long timeToSend() throws Exception;

    public void sendIt(AuthRequest ar) throws Exception;

    public String selfDescription() throws Exception;

}
