<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.TopicRecord"
%><%@page import="org.socialbiz.cog.SectionForNotes"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.net.URLEncoder"
%><%@page import="org.w3c.dom.Element"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can not invite players to a project.");

    String p = ar.reqParam("p");
    String note = ar.defParam("note", "Sending this note to let you know about a recent update to this web page has information that is relevant to you.  Follow the link to see the most recent version.");

    ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Can not invite players to the project.");
    uProf = ar.getUserProfile();


    String r = ar.reqParam("r");
    NGRole ngr = ngp.getRole(r);
    if (ngr==null)
    {
        throw new Exception("Can not invite people, because the role '"+r+"' does not exist on the page '"+ngp.getFullName()+"'");
    }

    if (!ngr.isExpandedPlayer(uProf, ngp))
    {
        throw new Exception("Can not invite people to role '"+r+"', because you are not a member of that role");
    }

    pageTitle = "Invite Players to role: "+r;

    ProcessRecord process = ngp.getProcess();
    String goal = process.getSynopsis();
    String purpose = process.getDescription();

%>

<%@ include file="Header.jsp"%>

<table width="600">
<col width="130">
<col width="470">

<form action="InvitePlayersAction.jsp" method="post">
<input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
<input type="hidden" name="p"       value="<%ar.writeHtml(p);%>"/>
<input type="hidden" name="go"      value="closeWindow.htm"/>
<tr>
  <td></td>
  <td>
    <input type="submit" name="action"  value="Invite Players"/> &nbsp;
  </td>
</tr>
<%
    int i=0;
    List<AddressListEntry> players = ngr.getExpandedPlayers(ngp);
    AddressListEntry.sortByName(players);
    for (AddressListEntry ale : players)
    {
        ++i;
%>
<tr>
  <td></td>
  <td>
    <input type="checkbox" name="include_<%=i%>" value="<% ar.writeHtml(ale.getUniversalId());%>"/> <% ale.writeLink(ar);%>
  </td>
</tr>
<%
    }
%>
<tr>
  <td>Note:</td><td>
    <textarea rows="4" cols="50" name="note"><%ar.writeHtml(note);%></textarea>
  </td>
</tr>
<tr>
  <td>
    Goal:
  </td>
  <td>
    <b><%ar.writeHtml(goal);%></b>
  </td>
</tr>
<tr>
  <td>
    Purpose:
  </td>
  <td>
    <b><%ar.writeHtml(purpose);%></b>
  </td>
</tr>
<tr>
  <td colspan="2">
    <hr/>
  </td>
</tr>
</form>
<tr>
  <td></td>
  <td>
    <%writeInviteEmail(ar, ngp, ngr, uProf);%>
  </td>
</tr>
</table>

<br/>
<%@ include file="FooterNoLeft.jsp"%>
<%@ include file="functions.jsp"%>
