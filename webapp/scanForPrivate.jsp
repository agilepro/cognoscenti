<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.File"
%><%@page import="java.io.PrintWriter"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.io.FileOutputStream"
%><%@page import="java.io.OutputStreamWriter"
%><%@page import="java.util.Properties"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AttachmentVersion"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGSession"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can not run test page.");

    String attachBase = ar.getSystemProperty("attachFolder");
    String dataFolder = ar.getSystemProperty("dataFolder");%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
    <title>Check for private notes</title>
    <link href="mystyle.css" rel="stylesheet" type="text/css"/>
</head>
<body>
<h3>Check for private notes</h3>
<ul>
<%
    File thisDir = new File(dataFolder);
    File[] chilluns = thisDir.listFiles();

    int limit=800;

    for (int i=0; i<chilluns.length && limit>0; i++) {

        File chile = chilluns[i];
        if (chile.isDirectory()) {
    continue;
        }
        String cname = chile.getName();
        if (!cname.endsWith(".sp")) {
    continue;
        }
        NGPage aPage = NGPage.readPageAbsolutePath(chile);

        List<NoteRecord> notes = aPage.getAllNotes();

        int numSects = 0;

        for (NoteRecord note : notes)
        {
    if (note.getVisibility()==4)
    {
        numSects++;
    }
        }

        if (numSects==0)
        {
    continue;
        }

        ar.write("\n<li>");
        ar.write(Integer.toString(numSects));
        ar.write(" private notes in file ");
        ar.writeHtml(aPage.getFullName());
        ar.write("</li>");

        ar.write("\n<ul>");

        for (NoteRecord note : notes)
        {
    if (note.getVisibility()==4)
    {
        ar.write("\n  <li>");
        ar.writeHtml(note.getOwner());
        ar.write("</li>");
    }
        }
        ar.write("\n</ul>");


    }
%>
</ul>
</body>
</html>

<%@ include file="functions.jsp"%>
