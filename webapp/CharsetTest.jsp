<%@ page contentType="text/html;charset=UTF-8"
%><%@ page import="java.io.Writer"
%><%
    request.setCharacterEncoding("UTF-8");

    String mydata = request.getParameter("mydata");
    String confTest = request.getParameter("confTest");
    boolean needTomcatKludge = !(confTest==null || "\u6771\u4eac".equals(confTest));
    String correctedValue = mydata;
    if (needTomcatKludge)
    {
        correctedValue = new String(correctedValue.getBytes("iso-8859-1"), "UTF-8");
    }
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html;charset=UTF-8"/>
<title>Character encoding test page</title>
</head>
<body>
<h1>Character Encoding Test Page</h1>
<table>
<%
    if (mydata!=null)
    {
%>
<tr>
  <td>Data sent to this form:</td>
  <td><% ar.writeHtml(mydata);%></td>
</tr>
<tr>
  <td>code values:</td>
  <td><%writeCode(out, mydata);%></td>
</tr>
<%
        if (confTest==null)
        {
            //ignore the standard value if not present
        }
        else if ("\u6771\u4eac".equals(confTest))
        {
%>
<tr>
  <td>Standard Test</td>
  <td>TomCat has correctly decoded the UTF-8 Code</td>
</tr>
<%
        }
        else if ("\u00E6\u009D\u00B1\u00E4\u00BA\u00AC".equals(confTest))
        {
%>
<tr>
  <td>Standard Test</td>
  <td>TomCat has incorrectly used ISO-8859-1 encoding</td>
</tr>
<tr>
  <td>Corrected Value:</td>
  <td><% ar.writeHtml(correctedValue);%></td>
</tr>
<%
        }
        else
        {
%>
<tr>
  <td>Standard value expected:</td>
  <td><%writeCode(out, "\u6771\u4eac");%></td>
</tr>
<tr>
  <td>Standard value received:</td>
  <td><%writeCode(out, confTest);%></td>
</tr>
<%
        }
    }
%>
</table>

</p>
<hr/>
<form method="post" action="CharsetTest.jsp" enctype="application/x-www-form-urlencoded; charset=utf-8">
<input type="text" name="mydata" value="<% ar.writeHtml(correctedValue);%>">
<input type="hidden" name="confTest" value="<% ar.writeHtml("\u6771\u4eac");%>">
<input type="submit" value="Send with POST" />
</form>
<hr/>
<form method="get" action="CharsetTest.jsp">
<input type="text" name="mydata"  value="<% ar.writeHtml(correctedValue);%>">
<input type="hidden" name="confTest" value="<% ar.writeHtml("\u6771\u4eac");%>">
<input type="submit" value="Send with GET" />
</form>
<hr/>
</body>
</html>

<%!

    public static void writeHtml(Writer out, String t)
        throws Exception
    {
        if (t==null) {
            return;  //treat it like an empty string
        }
        for (int i=0; i<t.length(); i++) {

            char c = t.charAt(i);
            switch (c) {
                case '&':
                    out.write("&amp;");
                    continue;
                case '<':
                    out.write("&lt;");
                    continue;
                case '>':
                    out.write("&gt;");
                    continue;
                case '"':
                    out.write("&quot;");
                    continue;
                default:
                    out.write(c);
                    continue;
            }

        }
    }

    public static void writeCode(Writer out, String t)
        throws Exception
    {
        int last = t.length();
        for (int i=0; i<last; i++)
        {
            char c = t.charAt(i);
            out.write(Integer.toString(c));
            out.write(" ");
        }
    }


%>