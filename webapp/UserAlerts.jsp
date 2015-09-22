<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AuthRequest"
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
    ar.assertLoggedIn("Unable to see user alerts. ");

    uProf = findSpecifiedUserOrDefault(ar);

    pageTitle = "User: "+uProf.getName();
    specialTab = "Alerts";

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
         <h1 class="left">Active Action Items <a href="UserEmailSample.jsp?u=<%ar.writeHtml(uProf.getKey());%>"><img src="emailIcon.gif"></a></h1>
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
    Vector myActive = th.getActiveTasks();
    Enumeration e = myActive.elements();
    while (e.hasMoreElements())
    {
        GoalRecord tr = (GoalRecord) e.nextElement();
        int state = tr.getState();
        NGPage taskPage = tr.getProject();
%>
        <tr>
           <td><a href="WorkItem.jsp?p=<%=URLEncoder.encode(taskPage.getKey(),"UTF-8")%>&s=Tasks&id=<%=tr.getId()%>"
                title="view and modify details of the task"><img src="<%=GoalRecord.stateImg(state)%>"></a> </td>
           <td><%ar.writeHtml( tr.getSynopsis());%>
                - <a href="<%=ar.retPath%><%=ar.getResourceURL(taskPage,"")%>" title="see the page this task is on">
                <%ar.writeHtml( taskPage.getFullName());%></a></td>
           <td><%SectionUtil.nicePrintDate(out, tr.getDueDate());%></td>
        </tr>
        <%
    }

%>
         </table>
     </div>
 </div>



 <div class="section">
     <div class="section_title">
         <h1 class="left">Watched Page Changes</h1>
         <div class="section_date right"></div>
         <div class="clearer">&nbsp;</div>
     </div>
     <div class="section_body">
        <table>
<%

        Vector<WatchRecord> watchList = uProf.getWatchList();
        if (watchList != null)
        {
            Enumeration e2 = watchList.elements();
            while (e2.hasMoreElements())
            {
                WatchRecord wr = (WatchRecord)e2.nextElement();
                NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(wr.getPageKey());
                long  changeTime = 0;
                if (ngpi==null)
                {
                    continue;  //skip pages that don't exist
                }
                if (ngpi.lastChange<wr.getLastSeen())
                {
                    continue;  //skip pages that have not been changed
                }
                ar.write("<tr><td><a href=\"");
                ar.writeHtml(ar.retPath);
                ar.writeHtml(ar.getResourceURL(ngpi,"public.htm"));
                ar.write("\" title=\"navigate to the page itself\">");
                ar.writeHtml(ngpi.containerName);
                ar.write("</a>");
                ar.write(" has changed since you last saw it ");
                SectionUtil.nicePrintTime(ar, wr.getLastSeen(), ar.nowTime);
                ar.write("</td></tr>");
            }
        }


%>
        </table>
     </div>
 </div>


 <div class="section">
     <div class="section_title">
         <h1 class="left">Page Member Requests</h1>
         <div class="section_date right"></div>
         <div class="clearer">&nbsp;</div>
     </div>
     <div class="section_body">
        <table>
<%

    Vector adms = ar.getCogInstance().getAllPagesForAdmin(uProf);
    Enumeration admse = adms.elements();
    while(admse.hasMoreElements())
    {
        NGPageIndex ngpi = (NGPageIndex)admse.nextElement();
        if (!ngpi.requestWaiting)
        {
            continue;
        }
        NGPage aPage = ngpi.getPage();
        %>
        <tr>
           <td><a href="<%=ar.retPath%><%ar.writeHtml( ar.getResourceURL(aPage,"permission.htm"));%>">
           !@!</a></td>
           <td>User Requested Access to <a href="<%=ar.retPath%><%=ar.getResourceURL(aPage,"permission.htm")%>">
                <%ar.writeHtml( aPage.getFullName());%></a></td>
        </tr>
        <%
        NGPageIndex.releaseLock(aPage);
    }


%>
        </table>
     </div>
 </div>
        <hr/>
        <p>View the <a href="UserEmailSample.jsp?u=<%=uProf.getKey()%>">Email Version</a>
           which is sent to the user as a notification.</p>


<%
    out.flush();

%>


<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
