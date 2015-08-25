<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page errorPage="error.jsp"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AttachmentVersion"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.HistoryRecord"
%><%@page import="org.socialbiz.cog.MimeTypes"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.ProcessRecord"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.List"
%><%@page import="java.util.Vector"
%><%

    ar = AuthRequest.getOrCreate(request, response, out);

    String p        = ar.reqParam("p");
    String aid      = ar.reqParam("aid");

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);

    AttachmentRecord attachment = ngp.findAttachmentByID(aid);

    if (attachment == null) {
        throw new Exception("Unable to find the attachment with the id : " + aid);
    }

    ngb = ngp.getSite();

    String type     = attachment.getType();
    String access = "Member Only";
    if (attachment.getVisibility()<=1)
    {
        access = "Public";
    }

    if (type.length() == 0)  { throw new Exception("Attachment type is not set"); }
    boolean isURL = (type.equals("URL"));
    boolean isFile = !isURL;

    String relativeLink = "a/" + SectionUtil.encodeURLData(attachment.getNiceName());
    String permaLink = ar.getResourceURL(ngp, relativeLink);

    AddressListEntry ale = new AddressListEntry(attachment.getModifiedBy());

    pageTitle = ngp.getFullName() + " / "+ attachment.getNiceNameTruncated(48);%>

<%@ include file="Header.jsp"%>


<h2>Access Document from Project</h2>
<br/>

<table>
<col width="120">
<col width="600">

<tr>
  <td>Document:</td>
  <td><b><% ar.writeHtml(attachment.getNiceName()); %></b></td>
</tr>
<tr>
  <td></td>
  <td><%
  	ar.writeHtml(attachment.getDescription());
  %></td>
</tr>
<tr>
  <td>Uploaded:</td>
  <td><% SectionUtil.nicePrintTime(ar, attachment.getModifiedDate(), ar.nowTime); %>
      by <% ale.writeLink(ar); %></td>
</tr>
<tr>
  <td>Accesibility:</td>
  <td><%ar.writeHtml(access);%></td>
</tr>
<tr>
  <td></td>
  <td><br/>
      <a href="<%=permaLink%>"><img src="download.gif" border="0"></a>
      <br/>&nbsp;</td>
</tr>
<tr>
  <td>Project:</td>
  <td><%ar.writeHtml(ngp.getFullName());%></td>
</tr>
</table>
<br/>

<p>This web page is a secure and convenient way to send documents to others
collaborating on projects.
The email message does not carry the document, but
only a link to this page, so the email is small.
Then, from this page, you can get the very latest
version of the document.  Documents can be protected
by access controls.
</p>

<%
if (ar.isLoggedIn())
{
    ar.write("<p>You are logged in.");
    if (ngp.primaryOrSecondaryPermission(ar.getUserProfile()))
    {
        ar.write(" You are a member of the project, so you can access other tabs across the top to see other information about the project.");
    }
    if (ngp.secondaryPermission(ar.getUserProfile()))
    {
        ar.write(" You are an administrator of the project.");
    }
    ar.write("</p>");
} else {
%>
    <p>Since you are not logged in we can not tell if you are a member of this project or not.
    Log in, and there may be other options available to you.</p>
<%
}
%>
</p>
<br/>
<br/>


<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>

