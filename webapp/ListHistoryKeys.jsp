<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.HistoryRecord"
%><%@page import="org.socialbiz.cog.MimeTypes"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGContainer"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSession"
%><%@page import="java.io.File"
%><%@page import="java.util.Collections"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Properties"
%><%@page import="java.util.Vector"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can not run Admin page");

    Hashtable<String,String> allKeys = new Hashtable<String,String>();
    Vector<String> results = new Vector();

    for (NGPageIndex ngpi : ar.getCogInstance().getAllContainers())
    {
        NGContainer ngc = ngpi.getContainer();
        for (HistoryRecord hr : ngc.getAllHistory())
        {
            String cKey = hr.getCombinedKey();
            if (allKeys.get(cKey)==null)
            {
                allKeys.put(cKey, cKey);
                results.add(cKey);
            }
        }
    }

%>
<html>
<body>
<h3>list if all history combined keys</h3>

<ul>
<%
    Collections.sort(results);

    for (String val : results)
    {
        ar.write("\n<li>");
        ar.writeHtml(val);
        ar.write("\n</li>");
    }

%>

<hr/>
</body>
</html>