<%@page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8"
%><%@include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.rest.ServerInitializer"
%><%

    // AuthRequest ar = AuthRequest.getOrCreateWithWriter(request, response, out);
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
    InputStreamReader isr = new InputStreamReader( new FileInputStream(actualFile), "UTF-8" );

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

