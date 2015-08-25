<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.File"
%><%@page import="java.util.Properties"
%><%@page import="org.socialbiz.cog.Cognoscenti"
%><%@page import="org.socialbiz.cog.EmailSender"
%><%@page import="org.socialbiz.cog.MimeTypes"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.ConfigFile"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSession"
%><%@page import="org.socialbiz.cog.SuperAdminLogFile"
%><%@page import="org.socialbiz.cog.rest.NGLeafServlet"
%><%@page import="org.socialbiz.cog.rest.ServerInitializer"
%><%

    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    Cognoscenti cog = ar.getCogInstance();
    if (cog.initializer.serverInitState!=ServerInitializer.STATE_RUNNING) {


        %>
        <html>
        <body>
        <h1>Server Is In <%=cog.initializer.getServerStateString()%> State</h1>
        <form action="AdminAction.jsp" method="POST">
            <input type="hidden" name="encodingGuard" value="%E6%9D%B1%E4%BA%AC"/>
            <input type="hidden" name="go" value="Admin.jsp"/>
            <input type="submit" name="action" value="Restart Server"/>
        </form>
        </body>
        </html>
        <%
        return;
    }

    ar.assertLoggedIn("Must be logged in to run Admin page");
    if (!ar.isSuperAdmin()){
        throw new Exception("must be site administrator to use this Site Admin page");
    }

    //clear the session setting to force re-read of config file
    //maybe this should be done only on an error.
    ar.getSession().flushConfigCache();

    String startupProblem = "";
    if (NGLeafServlet.initializationException!=null)
    {
        startupProblem = NGLeafServlet.initializationException.toString();
    }

    long lastSentTime = ar.getSuperAdminLogFile().getLastNotificationSentTime();

    File userFolder = ar.getCogInstance().getConfig().getUserFolderOrFail();

    Runtime rt = Runtime.getRuntime();%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
    <head>
        <title>main</title>
    </head>
    <body>
        <h1>Server Is Running</h1>
            <table>
        <form action="AdminAction.jsp" method="POST">
            <input type="hidden" name="encodingGuard" value="%E6%9D%B1%E4%BA%AC"/>
            <input type="hidden" name="go" value="Admin.jsp"/>

                <tr>
                    <td>
                        <input type="submit" name="action" value="Reinitialize Index"/>
                        Discard the cached index, and create a new index from the files on the disk.
                    </td>
               </tr>
                <tr>
                    <td>
                        <input type="submit" name="action" value="Remove Disabled Users"/>
                        Discard disabled users from the list of users.
                    </td>
               </tr>
                <tr>
                    <td>
                        <input type="submit" name="action" value="Garbage Collect Pages"/>
                        Really delete the deleted pages.
                    </td>
               </tr>
                <tr>
                    <td>
                        <input type="submit" name="action" value="Purge Deleted Documents"/>
                        Walk through pages and really delete all the deleted documents.
                    </td>
               </tr>
                <tr>
                    <td>
                        <input type="submit" name="action" value="Send Test Email"/>
                        See if the server can send an email.
                    </td>
               </tr>
                <tr>
                    <td>
                        <input type="submit" name="action" value="Pause Server"/>
                        Put the server into paused mode.
                    </td>
               </tr>
                <tr>
                    <td>
                        <input type="submit" name="action" value="Restart Server"/>
                        Return to running from paused mode.
                    </td>
               </tr>
        </form>

            </table>
    <br/>
    <p><b><% ar.writeHtml(startupProblem); %></b></p>
    <ul>
    <li>Runtime.freeMemory: <% writeCommas(out, Long.toString(rt.freeMemory())); %></li>
    <li>Runtime.totalMemory: <% writeCommas(out, Long.toString(rt.totalMemory())); %></li>
    <%

    Cookie[] cs = request.getCookies();
    for (Cookie c : cs)
    {
        %>
        <li>cookie: <%= c.getName() %>, path: <%= c.getPath() %>, domain: <%= c.getDomain() %></li>
        <%
    }
    %>

    <li>Mime type for doc: <%= MimeTypes.getMimeType("xxxx.doc") %></li>
    <li>Mime type for jpg: <%= MimeTypes.getMimeType("xxxx.jpg") %></li>
    <li>Mime type for gif: <%= MimeTypes.getMimeType("xxxx.gif") %></li>
    <li>Mime type for doc: <%= MimeTypes.getMimeType("xxxx.doc") %></li>
    <li>Mime type for xls: <%= MimeTypes.getMimeType("xxxx.xls") %></li>
    <li>Mime type for ppt: <%= MimeTypes.getMimeType("xxxx.ppt") %></li>
    <li>Mime type for docx: <%= MimeTypes.getMimeType("xxxx.docx") %></li>
    <li>Mime type for xlsx: <%= MimeTypes.getMimeType("xxxx.xlsx") %></li>
    <li>Mime type for pptx: <%= MimeTypes.getMimeType("xxxx.pptx") %></li>
    </ul>
    <h3>Deleted Pages</h3>
    <ul>
    <%

    {
        for (NGPageIndex ngpi : ar.getCogInstance().getDeletedContainers())
        {
            ar.write("\n<li><a href=\"");
            ar.writeHtml(ar.getDefaultURL(ngpi));
            ar.write("\">");
            ar.writeHtml(ngpi.containerPath.toString());
            File deadFile = ngpi.containerPath;
            ar.write("</a>");
            if (deadFile.exists())
            {
                ar.write(" (file is there)");
            }
            ar.write("</li>");
        }
    }

    %>
    </ul>
    <h3>Last Notification Sent on: </h3><%SectionUtil.nicePrintDate(out,lastSentTime); %>(<%SectionUtil.nicePrintTime(ar,lastSentTime,ar.nowTime); %>)
    <ul>

    <%
        for (File child : userFolder.listFiles())
        {
            ar.write("\n<li><a href=\"unknownpage\">");
            ar.writeHtml(child.getName());
            ar.write("</a> -- ");
            ar.write(Long.toString(child.length()));
            ar.write("</li>");
        }
    %>

    </ul>
    <hr/>
    <ul>

    <%
        ServletContext sc = session.getServletContext();
        File rootCog = new File( sc.getRealPath("/") );
        File rootWebaps = rootCog.getParentFile();
        File rootTomcat = rootWebaps.getParentFile();
        File rootLogs = new File(rootTomcat, "logs");
        for (File child : rootLogs.listFiles())
        {
            ar.write("\n<li><a href=\"AdminLogFile.jsp?fn=");
            ar.writeURLData(child.getName());
            ar.write("\">");
            ar.writeHtml(child.getName());
            ar.write("</a> -- ");
            ar.write(Long.toString(child.length()));
            ar.write("</li>");
        }
    %>

    </ul>
    </body>
</html>

<%@ include file="functions.jsp"%>
<%
    NGPageIndex.clearLocksHeldByThisThread();
%>
<%!public void writeCommas(Writer out, String val)
        throws Exception
    {
        int first =  val.length()%3;
        if (first>0)
        {
            out.write(val.substring(0,first));
            val = val.substring(first);
            out.write(",");
        }
        while (val.length()>3)
        {
            out.write(val.substring(0,3));
            val = val .substring(3);
            out.write(",");
        }
        if (val.length()>0)
        {
            out.write(val);
        }
    }%>
