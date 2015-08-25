<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.File"
%><%@page import="java.util.Properties"
%><%@page import="java.util.List"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Set"
%><%@page import="java.util.Collections"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.HistoryRecord"
%><%@page import="org.socialbiz.cog.NGPage"
%><%

    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Must be logged in to run Admin page");
    if (!ar.isSuperAdmin()){
        throw new Exception("must be site administrator to use this Site Admin page");
    }

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
    <title>main</title>
</head>
<body>

<h2>Get all the history in the server</h2>

<pre>
<%

    Hashtable<String,Integer> count = new Hashtable<String,Integer>();

    for (NGPageIndex ngpi : ar.getCogInstance().getAllContainers() ) {
        if (!ngpi.isProject()) {
            continue;
        }

        NGPage ngp = ngpi.getPage();

        List<HistoryRecord> histRecs = ngp.getAllHistory();

        for (HistoryRecord hist : histRecs) {

            String ck = hist.getCombinedKey();

            Integer foo = count.get(ck);
            if (foo==null) {
                count.put(ck, new Integer(1));
            }
            else {
                count.put(ck, new Integer(foo.intValue()+1));
            }
        }
    }

    Set<String> keys = count.keySet();
//    Collections.sort(keys);
    for (String key : keys) {
        Integer val = count.get(key);
        ar.write("\n");
        ar.writeHtml(key);
        ar.write("\t"+val);
    }
    out.write("</pre>\n<table>");

    for (String key : keys) {
        if ("history.process.state.error".equals(key)) {
            //this was causing an error, so skip for now
            //should be added soon.
            continue;
        }
        String template = ar.getMessageFromPropertyFile(key, null);
        ar.write("\n<tr><td>");
        ar.writeHtml(key);
        ar.write("</td><td>");
        ar.writeHtml(template);
        ar.write("</td></tr>");
    }




%>
</table>

</body>

