<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.NoteRecord"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.ProcessRecord"
%><%@page import="org.socialbiz.cog.SectionForNotes"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);

    String p = ar.reqParam("p");

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);

    pageTitle = "Send Task List Email: "+ngp.getFullName();
    ar.assertMember("Can not send email.");

    String thisPageAddress = ar.getResourceURL(ngp,"process.htm");

%>

<%@ include file="Header.jsp"%>

<!--  here is where the content goes -->


<table width="650">
<col width="80">
<col width="570">

<form action="ProjectTasksEmailAction.jsp" method="post">
<input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
<input type="hidden" name="p"       value="<%ar.writeHtml(p);%>"/>
<input type="hidden" name="go"      value="<%ar.writeHtml(ar.getResourceURL(ngp,"process.htm"));%>"/>
<tr>
  <td></td>
  <td>
    <input type="submit" name="action"  value="Send Mail"/> &nbsp;
    <input type="checkbox" name="pagemem" value="pagemem"> Project Members,
    <input type="checkbox" name="assignees" value="assignees" checked="checked"> Task Assignees
  </td>
</tr>
<tr>
  <td></td>
  <td>
    <input type="checkbox" name="tempmem" value="tempmem"> Provide Temporary Membership
  </td>
</tr>
<tr>
  <td>Also To:</td><td>
    <textarea rows="2" cols="50" name="emailto"></textarea>
  </td>
</tr>
<tr>
  <td>
    Subject:
  </td>
  <td>
    <b>Goals for: <%ar.writeHtml(ngp.getFullName());%></b>
  </td>
</tr>
<tr>
  <td colspan="2">
    <hr/>
  </td>
</tr>
<tr>
  <td>
    Msg:
  </td>
  <td>
    <textarea name="msg">Below are the currently active tasks for the page <%ar.writeHtml(ngp.getFullName());%>.</textarea>
  </td>
</tr>
<tr>
  <td></td>
  <td>
    <% ProjectTasksEmailBody(ar, ngp, 1, thisPageAddress, 1); %>
  </td>
</tr>
</table>
</form>

<br/>
<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
<%@ include file="ProjectTasksEmailFormatter.jsp"%>



