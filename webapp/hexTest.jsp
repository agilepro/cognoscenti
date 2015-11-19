<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.MimeTypes"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.util.PasswordEncrypter"
%><%@page import="org.socialbiz.cog.rest.NGLeafServlet"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%@page import="java.io.File"
%><%@page import="java.util.Properties"
%><%@page import="java.util.Random"
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
    <head>
        <title>Hex Test</title>
    </head>
    <body>
    <h1>Hex Test</h1>


<%

    byte[] testVal = new byte[5];
    testVal[0] = 0;
    testVal[1] = 11;
    testVal[2] = 22;
    testVal[3] = 33;
    testVal[4] = 44;


    String xxx = PasswordEncrypter.hexEncode(testVal);

    byte[] answer = PasswordEncrypter.hexDecode(xxx);




%>
result is:
    <h3><%=xxx%></h3>
    <ul>
<%

    for (int i=0; i<answer.length; i++) {
        out.write("<li>"+testVal[i]+"</li>");
    }
    out.flush();

    Random rand = new Random();
    for (int iteration=0; iteration<100; iteration++)  {
        StringBuffer rPass = new StringBuffer();
        int last = 5+(iteration%10);
        for (int i=0; i<last; i++) {
            rPass.append((char) (32 + rand.nextInt(96)));
        }
        String rPassword = rPass.toString();

        String store = PasswordEncrypter.getSaltedHash(rPassword);
        boolean passed = PasswordEncrypter.check(rPassword, store);

        out.write("<li>");
        if (passed) {
            out.write(". . . pass: ");
        }
        else {
            out.write("FAIL . . .: ");
        }
        HTMLWriter.writeHtml(out, rPassword);
        out.write("</li>");
    }

%>
</ul>

<% PasswordEncrypter.testThis(); %>
</body>
</html>