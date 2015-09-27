<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.rest.DataFeedServlet"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.NGSession"
%><%@page import="org.socialbiz.cog.rest.RssServlet"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.RemoteGoal"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.rest.TaskHelper"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't manage Task list.");

    uProf = ar.getUserProfile();
    UserPage uPage = UserManager.findOrCreateUserPage(uProf.getKey());

    String mode=ar.defParam("mode", "show");
    boolean isFull = ("show".equals(mode));
    String otherMode = "hide";
    String modeLable = "Hide Status";
    if (!isFull) {
        otherMode = "show";
        modeLable = "Show Status";
    }


    String filter = ar.defParam(DataFeedServlet.OPERATION_GETTASKLIST, DataFeedServlet.MYACTIVETASKS);

    pageTitle = "Manage Action Items: "+uProf.getName();
    specialTab = "Manage Action Items";

    TaskHelper th = new TaskHelper(uProf.getUniversalId(), "");
    th.scanAllTask(ar.getCogInstance());

    String thisPage = "ManageTasks.jsp?mode="+mode;%>
<%@ include file="Header.jsp"%>

    <table><tr>
        <form action="SyncTasksAction.jsp">
        <td>
            <input type="submit" value="Synchronize Action Items from Workspaces to Personal Action Item List"> &nbsp;
            <input type="hidden" name="go"  value="<%ar.writeHtml(thisPage);%>">
        </td>
        </form>
        <form action="ManageTasks.jsp">
        <td>
            <input type="submit" value="<%=modeLable%>">
            &nbsp; <input type="hidden" name="mode" value="<%=otherMode%>">
        </td>
        </form>
    </table>
    <p>&nbsp;</p>
    <hr/>

    <table>
    <col width="100">
    <col width="460">
    <col width="150">
<%
    List<RemoteGoal> myActive = uPage.getRemoteGoals();
    RemoteGoal.sortTasksByRank(myActive);
    String lastKey ="";
    for (RemoteGoal tr : myActive)
    {
        String projectURL = tr.getProjectAccessURL();

        String projectPath = projectURL;
        String taskPath = tr.getUserInterfaceURL();
%>
        <form action="ManageTasksAction.jsp" method="post">
        <input type="hidden" name="taskid" value="<%ar.writeHtml(tr.getId());%>">
        <input type="hidden" name="projid" value="<%ar.writeHtml(projectURL);%>">
        <input type="hidden" name="go" value="<%ar.writeHtml(thisPage);%>">
        <tr bgcolor="#EEEEFF">
            <td align="right"><a name="<%ar.writeHtml(tr.getId());%>"></a>Project:</td>
            <td><a href="<%ar.writeHtml(projectPath);%>"><%ar.writeHtml(tr.getProjectName());%></a></td>
            <td>Rank:<input type="text" name="rank" value="<%=tr.getRank()%>" size="5"></td></tr>
        <tr>
            <td align="right"><img src="<%ar.writeHtml(BaseRecord.stateImg(tr.getState()));%>">&nbsp;</td>
            <td><b><a href="<%ar.writeHtml(taskPath);%>"><%ar.writeHtml(tr.getSynopsis());%></a></b></td>
            <td><input type="submit" name="op" value="Move Up">&nbsp;
            <input type="submit" name="op" value="Move Down"></td>
        </tr>
        <%
        if (isFull) {
        %>
        <tr>
        <td align="right">Status: </td>
        <td><textarea name="status" cols="5" rows="5"><% ar.writeHtml(tr.getStatus());%></textarea></td>
        </tr>
        <tr>
        <td align="right">Accomplishment: </td>
        <td><textarea name="accomp" cols="5" rows="5"></textarea></td>
        </tr>
        <tr><td></td>
            <td><input type="submit" name="op" value="Update Status"> &nbsp;</td>
            </tr>
        <%
        }
        NGPage ngpx = ar.getCogInstance().getProjectByUpstreamLink(projectURL);
        %>
        <tr>
        <td align="right">Local Clone: </td>
        <td>
        <% if (ngpx==null) { %>
            <i>does not exist</i>
        <% } else { %>
            exists: <%=ngpx.getKey()%>
        <% } %>
        </td></tr>
        </form>
        <tr><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>
        <%


    }

%>
</table>

<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>

