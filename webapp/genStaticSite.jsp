<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AttachmentVersion"
%><%@page import="org.socialbiz.cog.AuthDummy"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGSession"
%><%@page import="org.socialbiz.cog.util.UnclosableWriter"
%><%@page import="org.socialbiz.cog.spring.SpringServletWrapper"
%><%@page import="java.io.File"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.io.FileOutputStream"
%><%@page import="java.io.OutputStreamWriter"
%><%@page import="java.io.PrintWriter"
%><%@page import="java.util.Properties"
%><%@page import="org.apache.jasper.runtime.JspWriterImpl"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can not run test page.");

    String attachBase = ar.getSystemProperty("attachFolder");
    String dataFolder = ar.getSystemProperty("dataFolder");
    String staticSite = ar.getSystemProperty("staticSite");
    String limitStr   = ar.defParam("limit","5");

    int limit=Integer.parseInt(limitStr);


    if (staticSite==null)
    {
        throw new Exception("Must define staticSite in config file in order to generate a static site.");
    }

    File siteBase = new File(staticSite);
    if (!siteBase.exists())
    {
        throw new Exception("Static site location must point to a folder that exists.  Currently set to: "+staticSite);
    }

    File pbase = new File(siteBase, "p");
    pbase.mkdirs();

    String singleFile = ar.defParam("p", null);



%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
    <title>Generate Static Site</title>
    <link href="mystyle.css" rel="stylesheet" type="text/css"/>
</head>
<body>
<h3>Generate Static Site</h3>
<ul>
<li>getRequestURI() = <%ar.writeHtml(request.getRequestURI());%></li>
<li>getServletPath() = <%ar.writeHtml(request.getServletPath());%></li>
<li>getRequestURL() = <%ar.writeHtml(request.getRequestURL().toString());%></li>
<li>getContextPath() = <%ar.writeHtml(request.getContextPath());%></li>

<% dumpPaths(ar,ar); %>

<li>Starting the file scan
<%

    File thisDir = new File(dataFolder);
    File[] chilluns = thisDir.listFiles();

    if (singleFile!=null)
    {
        File single = new File(thisDir, singleFile);
        if (single.exists())
        {
            chilluns = new File[1];
            chilluns[0] = single;
        }
    }
    for (int ix=0; ix<chilluns.length && limit>0; ix++)
    {
        File chile = chilluns[ix];
        %></li><li><%=ix%>: <%=chile.toString()%><%
        try {
            ar.flush();
            if (chile.isDirectory())
            {
                %>Directory (ix=<%=ix%>)<%
                continue;
            }
            String cname = chile.getName();
            if (!cname.endsWith(".sp"))
            {
                %>Not SP file (ix=<%=ix%>)<%
                continue;
            }
            NGPage aPage = NGPage.readPageAbsolutePath(chile);
            if (aPage.isDeleted())
            {
                %>DELETED PAGE: <%
    ar.writeHtml(aPage.getOldUIPermaLink());
%>(ix=<%=ix%>)<%
    continue;
    }
%>(ix=<%=ix%>)
            <a href="<%ar.writeHtml(ar.getResourceURL(aPage,""));%>"><%
    ar.writeHtml(aPage.getOldUIPermaLink());
%></a>
                <a href="genStaticSite.jsp?p=<%ar.writeURLData(cname);%>"><img src="createicon.gif" border="0"></a></li>
            <%
            ar.flush();
            Thread.sleep(200);   //wait a second so you don't starve the other threads
            ar.flush();

            --limit;

            String key = aPage.getKey();
            File projectFolder = new File(pbase, key);
            projectFolder.mkdirs();

            ar.flush();
            generatePage("public.htm",     "leaf_public.jsp",     aPage, projectFolder, ar);
            ar.flush();
            generatePage("attach.htm",     "leaf_attach.jsp",     aPage, projectFolder, ar);
            ar.flush();
            generatePage("process.htm",    "leaf_process.jsp",    aPage, projectFolder, ar);
            ar.flush();
            generatePage("history.htm",    "leaf_history.jsp",    aPage, projectFolder, ar);

            ar.flush();

            List<AttachmentRecord> attachments = aPage.getAllAttachments();
            ar.flush();

            if (attachments.size()>0)
            {
                %><ul><%
                File attachFolder = new File(projectFolder, "a");
                attachFolder.mkdirs();
                for (AttachmentRecord att : attachments)
                {
                    String aName = att.getNiceName();
                    %><li>Copying Attachment: <%ar.writeHtml(aName+"("+att.getId()+")"+att.getType());%></li><%
                    try {
                        String sourceFileName = att.getStorageFileName();
                        if (sourceFileName==null || sourceFileName.length()==0)
                        {
                            %><ul><li>No file name given for this file!  -- ignored</li></ul><%
                            continue;
                        }
                        File source = new File(attachBase, sourceFileName);
                        if (!source.exists())
                        {
                            %><ul><li>File missing!:  <% ar.writeHtml(source.toString()); %> </li></ul><%
                            continue;
                        }
                        if (!"FILE".equals(att.getType()))
                        {
                            %><ul><li>Not a file, is a <%=att.getType()%>:  <% ar.writeHtml(source.toString()); %> </li></ul><%
                            continue;
                        }
                        if (source.isDirectory())
                        {
                            %><ul><li>This is a directory!:  <% ar.writeHtml(source.toString()); %> </li></ul><%
                            continue;
                        }
                        File aFile = new File(attachFolder, aName);
                        FileOutputStream fos = new FileOutputStream(aFile);
                        FileInputStream fis = new FileInputStream(source);
                        byte[] buf = new byte[4096];
                        int amt = fis.read(buf);
                        while (amt>0)
                        {
                            fos.write(buf, 0, amt);
                            amt = fis.read(buf);
                        }
                        fos.close();
                        fis.close();
                    }
                    catch (Exception e)
                    {
                        %>
                        <ul>
                        <li>Cant copy file "<% ar.writeHtml( aName ); %>": <% ar.writeHtml( e.toString()); %>
                        <pre>
                        <%
                        PrintWriter pw = new PrintWriter(new HTMLWriter(out));
                        e.printStackTrace(pw);
                        pw.flush();
                        limit--;
                        %>
                        </pre>
                        </ul>
                        <%
                    }
                }
                %></ul><%
            }
        }
        catch (Exception e)
        {
            %>
            <ul>
            <li>EXCEPTION: (ix=<%=ix%>) <%ar.writeHtml(e.toString());%>
            <pre>
            <%
            PrintWriter pw = new PrintWriter(new HTMLWriter(out));
            e.printStackTrace(pw);
            pw.flush();
            limit -= 100;
            %>
            </pre>
            </ul>
            <%
        }

    }


    if (limit<=0) {
        %>
        <li>Run limit <%=limitStr%> reached.  Set 'limit' parameter to get full output</li>
        <%
    }
%>
</ul>
</body>
</html>

<%@ include file="functions.jsp"%>
<%!public void generatePage(String resourceName, String jspName, NGPage ngp, File projectFolder, AuthRequest ar)
        throws Exception
    {
        try
        {
            ar.retPath="../../";
            File destFile = new File(projectFolder, resourceName);
            FileOutputStream fos = new FileOutputStream(destFile);
            Writer osw = new OutputStreamWriter(fos, "UTF-8");

            String path = "/p/"+ngp.getKey()+"/"+resourceName;
            AuthRequest ar4test = ar.getNestedRequest(path, osw);
            ar4test.setStaticSite(true);
            ar4test.retPath="../../";
            ar4test.setParam("p", ngp.getKey());
            ar4test.invokeJSP(jspName);

            osw.flush();
            osw.close();
        }
        catch (Exception e)
        {
            throw new Exception("Unable to generate static page for resource '"
                    +jspName+"' ("+resourceName+") for page '"
                    +ngp.getKey()+"'.", e);
        }
    }

    public void generateNewPage(String resourcePath, NGPage ngp, File tbase, AuthRequest ar)
        throws Exception
    {
        try
        {
            NGBook book = ngp.getSite();

            resourcePath = resourcePath.replace("{account}", book.getKey());
            resourcePath = resourcePath.replace("{project}", ngp.getKey());

            File destFile = new File(tbase, resourcePath);
            destFile.getParentFile().mkdirs();
            FileOutputStream fos = new FileOutputStream(destFile);
            Writer osw = new OutputStreamWriter(fos, "UTF-8");

            AuthRequest ar4test = ar.getNestedRequest(resourcePath, osw);
            ar4test.setStaticSite(true);
            ar4test.retPath="../../../";
            dumpPaths(ar, ar4test);

            SpringServletWrapper.generatePage(ar);

            osw.flush();
            osw.close();
        }
        catch (Exception e)
        {
            throw new Exception("Unable to generate NEW page for resource '"
                    +resourcePath+" for page '"
                    +ngp.getKey()+"'.", e);
        }
    }


    public void dumpPaths(AuthRequest ar, AuthRequest arToView)
        throws Exception
    {
        ar.write("<li>getRequestURI() = ");
        ar.writeHtml(arToView.req.getRequestURI());
        ar.write("</li>");
        ar.write("<li>getServletPath() = ");
        ar.writeHtml(arToView.req.getServletPath());
        ar.write("</li>");
        ar.write("<li>getRequestURL() = ");
        ar.writeHtml(arToView.req.getRequestURL().toString());
        ar.write("</li>");
        ar.write("<li>getContextPath() = ");
        ar.writeHtml(arToView.req.getContextPath());
        ar.write("</li>");
    }%>