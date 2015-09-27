<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.ProcessRecord"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%><%ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can not attach a document to this project.");

    String p = ar.reqParam("p");

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ngb = ngp.getSite();
    ar.setPageAccessLevels(ngp);
    ProcessRecord process = ngp.getProcess();

    pageTitle = "Add Attachment to "+ngp.getFullName();
    ar.assertMember("Can not attach a document to this project.");%>

<%@ include file="Header.jsp"%>

<h1>Upload New Document to Workspace</h1>

<p>Use this form to attach upload a file to the project &quot;<%ar.writeHtml(ngp.getFullName());%>&quot;.</p>

<table width="600">
<col width="130">
<col width="470">
<form action="CreateAttachmentActionMime.jsp" method="post" enctype="multipart/form-data">
<input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
<input type="hidden" name="p"       value="<%ar.writeHtml(p);%>"/>
<tr>
  <td>
    Description of<br/>
    Attachment:
  </td>
  <td>
    <textarea name="comment" id="fname" style="WIDTH:95%;"></textarea>
  </td>
</tr>
<tr>
  <td>Accessibility:</td>
  <td>
        <input type="radio" name="destFolder" value="*PUB*"/> Public
        <input type="radio" name="destFolder" value="*MEM*" checked="checked"/> Member Only

  </td>
</tr>
<input type="hidden"  name="ftype" value="FILE">


<tr>
  <td>
    Local File:
  </td>
  <td>
    <input type="file"   name="fname"   id="fname" size="60"/>
  </td>
</tr>
<tr>
  <td>
    Access Name:
  </td>
  <td>
    <input type="text"   name="name"   size="60"/>
  </td>
</tr>
<tr>
   <td colspan="2">Leave the access name empty if you want to use
                   the name of the file as it is on your local disk.</td>
</tr>
<tr>
  <td></td><td>
    <input type="submit" name="action" value="Upload Attachment File">
  </td>
</tr>
</form>
</table>

<br/> <br/> <hr/><!------------------------------------------------------------->
<h1>Link URL to Workspace</h1>

<p>Use this form to attach a URL to the project &quot;<% ar.writeHtml(ngp.getFullName()); %>&quot;.</p>

<table width="600">
<col width="130">
<col width="470">

<form action="CreateAttachmentAction.jsp" method="post">
<input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
<input type="hidden" name="p"       value="<%ar.writeHtml(p);%>"/>
<tr>
  <td>
    Description of<br/>
    Web Page:
  </td>
  <td>
    <textarea name="comment" id="fname" style="WIDTH:95%;"></textarea>
  </td>
</tr>
<tr>
  <td>Accessibility:</td>
  <td>
        <input type="radio" name="destFolder" value="*PUB*"/> Public
        <input type="radio" name="destFolder" value="*MEM*" checked="checked"/> Member Only

  </td>
</tr>
<input type="hidden" name="ftype" value="URL"/>
<tr>
  <td>
    URL:
  </td>
  <td>
    <input type="text" name="taskUrl" size="60"/>
  </td>
</tr>
<tr>
  <td></td><td>
    <input type="submit" name="action" value="Attach Web URL">
  </td>
</tr>

</form>
</table>

<br/> <br/> <hr/><!------------------------------------------------------------->
<h1>Create Email to Ask Someone to Attach a File</h1>

<p>Use this form to create an email reminder asking someone to attach a file to the project.
Enter their email address, and a description of the file that they are to attach.
After you create the reminder, it will remain a in the project,
until the file the file is attached. </p>

<table width="600">
<col width="130">
<col width="470">

<form action="CreateAttachmentAction.jsp" method="post">
<input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
<input type="hidden" name="p"       value="<%ar.writeHtml(p);%>"/>
<tr>
  <td>
    To:
  </td>
  <td>
    <input type="text" name="assignee" size="60"> (email)
  </td>
</tr>
<tr>
  <td>
    Subject:
  </td>
  <td>
    Please upload file <input type="text" name="subj" size="40">
  </td>
</tr>
<tr>
  <td>
    <br/>
  </td>
  <td>
    <hr/>
  </td>
</tr>
<tr>
  <td>
    Instuctions:
  </td>
  <td>
    <textarea name="instruct" id="fname" style="WIDTH:95%;">Please upload the file requested below.  Click on the link to access the web page which will allow you to easily upload the file.</textarea>
  </td>
</tr>
<tr>
  <td>
    Description of File<br/>
    to Attach:
  </td>
  <td>
    <textarea name="comment" id="fname" style="WIDTH:95%;"></textarea>
  </td>
</tr>
<tr>
  <td>
    <br/>
  </td>
</tr>
<tr>
  <td>Accessibility:</td>
  <td>
        <input type="radio" name="destFolder" value="*PUB*"/> Public
        <input type="radio" name="destFolder" value="*MEM*" checked="checked"/> Member Only

  </td>
</tr>
<tr>
  <td>
    Proposed Name:
  </td>
  <td>
    <input type="text" name="pname" size="60">
  </td>
</tr>
<tr>
   <td></td><td>Enter a proposed name for the attachment if you wish.  This may be changed later.
   Leave empty if you don't want to specify the name.</td>
</tr>
<tr>
  <td></td><td>
    <input type="submit" name="action" value="Create Email Reminder">
  </td>
</tr>
</form>
</table>

<br/>
<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
