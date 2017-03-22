<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.Cognoscenti"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UserManager"
%><%@page import="org.socialbiz.cog.rest.ServerInitializer"
%><%@page import="org.socialbiz.cog.mail.DailyDigest"
%><%

    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    Cognoscenti cog = ar.getCogInstance();

    //to restart server have to skip all the normal stuff
    //assume server un-pause is the only possible option here
    if (cog.initializer.serverInitState==ServerInitializer.STATE_PAUSED) {
        cog.resumeServer();
        response.sendRedirect("Admin.jsp");
        return;
    }
    ar.assertLoggedIn("Can't use administration functions.");
    boolean createNewSubPage = false;

    String go = ar.reqParam("go");
    String action = ar.reqParam("action");

    if (action.equals("Garbage Collect Pages")) {
        deleteMarkedPages(ar);
        action = "Reinitialize Index";
    }

    if (action.equals("Reinitialize Index") || action.equals("Start Email Sender")) {
        ar.getSession().flushConfigCache();

        // Only if the server is running, then this code will
        // set it into paused mode, wait a few seconds, and then
        // cause the server to be completely reinitialized.
        if (cog.isRunning()) {
            cog.pauseServer();
            Thread.sleep(20);
            cog.resumeServer();
        }
    }
    else if (action.equals("Remove Disabled Users")) {
        cog.getUserManager().removeDisabledUsers();
        cog.getUserManager().reloadUserProfiles(cog);
    }
    else if (action.equals("Pause Server")) {
        cog.pauseServer();
    }
    else if (action.equals("Restart Server")) {
        cog.resumeServer();
    }
    else if (action.equals("Purge Deleted Documents")) {
        for (NGPageIndex ngpi : ar.getCogInstance().getAllContainers())
        {
            if (!ngpi.isDeleted && ngpi.isProject()) {
                NGPage ngp = ngpi.getPage();
                ngp.purgeDeletedAttachments();
            }
        }
    }
    else if ("Send Daily Digest".equals(action)) {
        DailyDigest.forceDailyDigest(ar, cog);
    }
    else {
        throw new Exception ("Unrecognized command: "+action);
    }

    response.sendRedirect(go);

%><%!


public void deleteMarkedPages(AuthRequest ar)
        throws Exception
{
    for (NGPageIndex ngpi : ar.getCogInstance().getDeletedContainers())
    {
        File deadFile = ngpi.containerPath;
        if (deadFile.exists()) {
            deadFile.delete();
        }
    }
}%><%@ include file="functions.jsp"
%><%

    NGPageIndex.clearLocksHeldByThisThread();
%>
