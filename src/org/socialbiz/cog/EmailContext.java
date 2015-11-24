package org.socialbiz.cog;

public interface EmailContext {

    public String emailSubject() throws Exception;

    public String getTargetRole()  throws Exception;
    
    public String getResourceURL(AuthRequest ar, NGPage ngp) throws Exception;

    public String selfDescription() throws Exception;

}
