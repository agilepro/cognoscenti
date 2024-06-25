<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.File"
%><%@page import="java.io.InputStreamReader"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.util.Properties"
%><%@page import="com.purplehillsbooks.weaver.AuthRequest"
%><%@page import="com.purplehillsbooks.weaver.Cognoscenti"
%><%@page import="com.purplehillsbooks.weaver.NGBook"
%><%@page import="com.purplehillsbooks.weaver.ConfigFile"
%><%@page import="com.purplehillsbooks.weaver.NGPageIndex"
%><%@page import="com.purplehillsbooks.weaver.NGSession"
%><%@page import="com.purplehillsbooks.weaver.rest.ServerInitializer"
%><%

    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ServerInitializer si = ar.getCogInstance().initializer;
    if (si.serverInitState!=ServerInitializer.STATE_RUNNING) {
        throw new Exception("Server is not running???  Must be running to see log file.");
    }

    ar.assertLoggedIn("Must be logged in to run Admin page");
    if (!ar.isSuperAdmin()){
        throw new Exception("must be site administrator to use this Site Admin page");
    }

    String fileName = request.getParameter("fn");
    if (fileName==null) {
        throw new Exception("this page needs a file name parameter");
    }

    ServletContext sc = session.getServletContext();
    File rootCog = new File( sc.getRealPath("/") );
    File rootWebaps = rootCog.getParentFile();
    File rootTomcat = rootWebaps.getParentFile();
    File rootLogs = new File(rootTomcat, "logs");

    File actualFile = new File(rootLogs, fileName);
    if (!actualFile.exists()) {
        throw new Exception("File does not exist in log folder: "+fileName);
    }
    InputStreamReader isr = new InputStreamReader( new FileInputStream(actualFile), "ISO-8859-1" );

%>
<html>
<body>
<h1><% ar.writeHtml(fileName); %></h1>
<pre>
<%
    int ch = isr.read();
    while (ch>=0) {
        ar.writeHtml(""+(char)ch);
        ch = isr.read();
    }

%>
</pre>
</body>
</html>

