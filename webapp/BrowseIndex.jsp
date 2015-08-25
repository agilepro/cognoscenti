<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGTerm"
%><%@page import="java.io.File"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Properties"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can not run Index Browser page");

    String p = ar.reqParam("p");
    String key = p;

    NGPageIndex iEntry = ar.getCogInstance().getContainerIndexByKeyOrFail(p);
    NGPage ngp = iEntry.getPage();

%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
    <title>Dump Index</title>
    <link href="PageViewer.css" rel="stylesheet" type="text/css"/>
</head>
<body>

<h3>Browse "<%ar.writeHtml(p);%>"</h3>
<%
        NGTerm term = NGTerm.findTerm(p);

        %><p>Term <%ar.writeHtml(key);%> Source:<%=term.sourceLeaves.size()%>  Target:<%=term.targetLeaves.size()%></p><ol><%
        Enumeration t0 = term.sourceLeaves.elements();
        while (t0.hasMoreElements())
        {
            NGPageIndex sn = (NGPageIndex) t0.nextElement();
            out.write("<li>NGPI Source: ");
            ar.writeHtml(sn.pageKey);
            out.write(" - - ");
            ar.writeHtml(sn.pageName);
            out.write("</li>\n");
        }
        t0 = term.targetLeaves.elements();
        while (t0.hasMoreElements())
        {
            NGPageIndex sn = (NGPageIndex) t0.nextElement();
            out.write("<li>NGPI Target: ");
            ar.writeHtml(sn.pageKey);
            out.write(" - - ");
            ar.writeHtml(sn.pageName);
            out.write("</li>\n");
        }
        %></ol><%


        %><p>Name Terms of NGPageIndex:</p><ol><%
        Enumeration en = iEntry.nameTerms.elements();
        while (en.hasMoreElements())
        {
            NGTerm t = (NGTerm) en.nextElement();
            %><li>Term: <a href="BrowseIndex.jsp?p=<%ar.writeURLData(t.sanitizedName);%>"><%
            ar.writeHtml(t.sanitizedName);
            if (t.sanitizedName.length()==0)
            {
                %>(ghasp!) An Empty String!<%
            }
            out.write("</a></li>\n");
        }
        %></ol><%

        %><p>NGPage Names<b></b></p><ol><%
        String[] pageNames = ngp.getPageNames();
        for (int i=0; i<pageNames.length; i++)
        {
            %><li>String: <a href="BrowseIndex.jsp?p=<%ar.writeURLData(pageNames[i]);%>"><%
            ar.writeHtml(pageNames[i]);
            %></a></li><%
        }
        %></ol><%


        %><p>Ref Terms of NGPageIndex:</p><ol><%
        en = iEntry.refTerms.elements();
        while (en.hasMoreElements())
        {
            NGTerm t = (NGTerm) en.nextElement();
            %><li>Term: <a href="BrowseIndex.jsp?p=<%ar.writeURLData(t.sanitizedName);%>"><%
            ar.writeHtml(t.sanitizedName);
            if (t.sanitizedName.length()==0)
            {
                %>(ghasp!) An Empty String!<%
            }
            out.write("</a></li>\n");
        }
        %></ol><%


        %><p>Inlinks of <b><%ar.writeHtml(key);%></b></p><ol><%
        Enumeration e0 = iEntry.getInLinkPages().elements();
        while (e0.hasMoreElements())
        {
            NGPageIndex pi0 = (NGPageIndex)e0.nextElement();
            %><li>NGPI: <a href="BrowseIndex.jsp?p=<%ar.writeURLData(pi0.pageKey);%>"><%
            ar.writeHtml(pi0.pageName);
            %></a></li><%
        }
        %></ol><%


        %><p>Outlinks from  <%ar.writeHtml(key);%></p><ul><%
        Enumeration e1 = iEntry.getOutLinkPages().elements();
        while (e1.hasMoreElements())
        {
            NGPageIndex pi1 = (NGPageIndex)e1.nextElement();
            %><li><a href="BrowseIndex.jsp?p=<%ar.writeURLData(pi1.pageKey);%>"><%
            ar.writeHtml(pi1.pageName);
            %></a></li><%
        }
        %></ul><%


        %><p>Pages with References to <%ar.writeHtml(key);%></p><ul><%
        NGPage aPage = iEntry.getPage();
        %></ul><%


        %><p>Direct Page: <%
        ar.writeHtml(aPage.getFullName());
        %></p><%

        %><p>Page Path: <%
        ar.writeHtml(iEntry.pagePath);
        %></p><%

        %><p>Links On <%
        Vector pageSections = aPage.getAllSections();
        out.write(Integer.toString(pageSections.size()));
        %> Sections </p><ul><%
        en = pageSections.elements();
        while (en.hasMoreElements())
        {
            Vector tmpRef = new Vector();
            NGSection sec = (NGSection) en.nextElement();
            sec.findLinks(tmpRef);
            %><li><%
            ar.writeHtml(sec.getName());
            %><ul><%
            Enumeration e3 = tmpRef.elements();
            while (e3.hasMoreElements())
            {
                String refVal = (String) e3.nextElement();
                %><li><%
                ar.writeHtml(refVal);
            }
            %></ul><%
        }

        %></ul><%

%>


</body>
</html>

<%@ include file="functions.jsp"%>
