<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.HTMLWriterLineFeed"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.StringTokenizer"
%><%@page import="java.util.Vector"
%><%@page import="java.io.PrintWriter"
%><%@page import="org.apache.commons.httpclient.HttpException"
%><%@page import="org.apache.commons.httpclient.HttpURL"
%><%@page import="org.apache.commons.httpclient.NTCredentials"
%><%@page import="org.apache.webdav.lib.Property"
%><%@page import="org.apache.webdav.lib.PropertyName"
%><%@page import="org.apache.webdav.lib.ResponseEntity"
%><%@page import="org.apache.webdav.lib.WebdavResource"
%><%@page import="org.apache.webdav.lib.methods.DepthSupport"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can not test web dav uness you are logged in.");

    String user = ar.defParam("user", "squader");
    String pass = ar.defParam("pass", "");
    String url = ar.defParam("url", "http://deliveryuskm.fc.fujitsu.com/Interstage/PM%20Deliverables/AvatarTest");
    String act = ar.defParam("act", "Show");
    String domain = ar.defParam("domain", "corp");

%>

    <html><body>
    <h3>WebDAV Test Page</h3>
    <table>
    <form action="WebDAVTest.jsp" method="get">
    <tr><td>URL     </td><td><input type="text"     name="url"    value="<%ar.writeHtml(url);%>"  size="80">   </td></tr>
    <tr><td>Domain  </td><td><input type="text"     name="domain" value="<%ar.writeHtml(domain);%>"></td></tr>
    <tr><td>User    </td><td><input type="text"     name="user"   value="<%ar.writeHtml(user);%>">  </td></tr>
    <tr><td>Password</td><td><input type="password" name="pass"   value="<%ar.writeHtml(pass);%>">  </td></tr>
    <tr><td><input type="submit" name="act" value="Test"></td></tr>
    </form>
    </table>
    <hr/>
<%
    ar.flush();

    if ("Test".equals(act)) {
        WebdavResource wRes = null;
        try {

            //HttpURL urlObj = new HttpURL(url);
            HttpURL urlObj = new HttpURL(url.toCharArray());
            String hostName = urlObj.getHost();

            ar.write("Testing<br/>Hostname: ");
            ar.writeHtml(hostName);
            ar.write("<br/>userName: ");
            ar.writeHtml(user );
            ar.write("<br/>URL1: ");
            ar.writeHtml(url);
            ar.write("<br/>URL2: ");
            ar.writeHtml(urlObj.toString() );
            ar.write("<br/>Domain: ");
            ar.writeHtml(domain );
            ar.write("<br/>");
            ar.flush();

            NTCredentials cred = new NTCredentials(user, pass, hostName, domain);

            if (true) {
                wRes = new WebdavResource(urlObj, cred,
                    WebdavResource.getDefaultAction(), WebdavResource.getDefaultDepth() );
            }
            else {
                wRes = new WebdavResource(url, cred);
            }
            ar.write("<br/><b><font color=\"green\">OK</font></b>");
            ar.write("<br/>getName: ");
            ar.writeHtml(wRes.getName());
            ar.write("<br/>getCreationDate: ");
            ar.writeHtml(Long.toString(wRes.getCreationDate()));
            ar.write("<br/>getPath: ");
            ar.writeHtml(wRes.getPath());
            ar.write("<br/>isCollection: ");
            if (wRes.isCollection()) {ar.write("true");} else {ar.write("false");}
            ar.write("<br/>contentLength: ");
            ar.writeHtml(Long.toString(wRes.getGetContentLength()));
            ar.flush();

            if (wRes.isCollection()) {
                ar.write("\n<ul>");
                WebdavResource[] allChildren = wRes.listWebdavResources();
                for (WebdavResource child : allChildren) {
                    ar.write("\n  <li>");
                    ar.writeHtml(child.getName());
                    ar.write("\n  </li>");
                }
                ar.write("\n</ul>");
            }

        } catch (Exception e) {
            ar.write("<h3><font color=\"red\">ERROR</font></h3>");
            writeHtmlException(ar, e);
        }
    }

%>

<hr/>
<h3>INSTRUCTION</h3>

<p>The purpose of this page is to test the JAva WebDAV capability against various
servers to assure that this absic capability works, and that authentication is
being done correctly.</p>

<p>Enter in the URL that you want to access.  Enter the NT domain, the username,
the password as well, and click the Test button</p>

<p>If it is able to successfully access the resource, it will print out the resource name,
creation date, and path.</p>
</body></html>
<%!

    public void writeHtmlException(AuthRequest ar, Exception exp) throws Exception
    {
        if (exp!=null)
        {
            Throwable exprun = exp;
            int count = 1;
            while (exprun!=null)
            {
                String msg = exp.getMessage();
                if (msg==null || msg.length()==0) {
                    msg = exp.toString();
                }
                if (msg==null || msg.length()==0) {
                    msg = "Exception Object does not have string version!?!";
                }
                ar.write("\n#");
                ar.write(Integer.toString(count++));
                ar.write(" - ");
                ar.writeHtml(msg);
                ar.write("\n<br/>");
                exprun = exprun.getCause();
            }
            ar.write("\n<hr/>\n<font size=\"-4\">");
            exp.printStackTrace(new PrintWriter(new HTMLWriterLineFeed(ar.w)));
            ar.write("\n</font>");
        }
    }

%>
