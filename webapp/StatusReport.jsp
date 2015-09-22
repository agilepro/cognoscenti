<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.WatchRecord"
%><%@page import="org.socialbiz.cog.rest.TaskHelper"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%><%ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to see status report.");

    uProf = findSpecifiedUserOrDefault(ar);

    pageTitle = "User: "+uProf.getName();
    specialTab = "Status Report";

    TaskHelper th = new TaskHelper(uProf.getUniversalId(), "");
    th.scanAllTask(ar.getCogInstance());%>
<%@ include file="Header.jsp"%>

            <div class="pagenavigation">
                <div class="pagenav">
                    <div class="left"><%
                        ar.writeHtml( uProf.getName());
                    %> &raquo; Active Action Items </div>
                    <div class="right"></div>
                    <div class="clearer">&nbsp;</div>
                </div>
                <div class="pagenav_bottom"></div>
            </div>

 <div class="section">
     <div class="section_title">
         <h1 class="left">Status Report</h1>
         <div class="section_date right"></div>
         <div class="clearer">&nbsp;</div>
     </div>
     <div class="section_body">
        <table>
        <tr>
           <td></td>
           <td>Task</td>
           <td>Due</td>
        </tr>
<%
    Vector<GoalRecord> myActive = th.getActiveTasks();
    String lastKey ="";
    for (GoalRecord goal : myActive)
    {
        int state = goal.getState();
        if (state != BaseRecord.STATE_ACCEPTED)
        {
            continue;
        }
        NGPage taskPage = goal.getProject();
        String pageKey = taskPage.getKey();
        List<HistoryRecord> histRecs = goal.getTaskHistory(taskPage);

        if (!lastKey.equals(pageKey))
        {
%>
            <tr><td colspan="3"><b>
                <a href="<%=ar.retPath%><%=ar.getResourceURL(taskPage,"")%>" title="see the page this action item is on">
                <%ar.writeHtml( taskPage.getFullName());%></a></b></td></tr>
            <%
            lastKey = pageKey;
        }

        %>
        <tr>
           <td><a href="WorkItem.jsp?p=<%ar.writeURLData(taskPage.getKey());%>&s=Tasks&id=<%=goal.getId()%>&go=<%ar.writeURLData(ar.getRequestURL());%>"
                title="view and modify details of the task"><img src="<%=GoalRecord.stateImg(state)%>"></a> </td>
           <td><%ar.writeHtml( goal.getSynopsis());%>
                - <%
            NGRole aRole = goal.getAssigneeRole();
            for (AddressListEntry player : aRole.getExpandedPlayers(taskPage)) {
                player.writeLink( ar );
            }
           %></td>
           <td><%SectionUtil.nicePrintDate(out, goal.getDueDate());%></td>
        </tr>
        </tr>
        <tr>
           <td></td><td/>status:<%ar.writeHtml( goal.getStatus());%></td>
        </tr>
        <%
        for (HistoryRecord history : histRecs)
        {
            String msg = history.getComments();
            if(msg==null || msg.length()==0)
            {
                msg=HistoryRecord.convertEventTypeToString(history.getEventType());
            }
            %><tr>
              <td></td><td/><%SectionUtil.nicePrintTime(ar, history.getTimeStamp(), ar.nowTime);%> -
                  <%ar.writeHtml(msg);%></td>
              </tr><%
        }
    }

%>
         </table>
     </div>
 </div>




<%
    out.flush();

%>


<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
