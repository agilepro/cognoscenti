<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.ProjectLink"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.StatusReport"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UserPage"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.WatchRecord"
%><%@page import="org.socialbiz.cog.rest.TaskHelper"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Hashtable"
%><%@page import="org.w3c.dom.Element"
%><%ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to see status report.");

    uProf = findSpecifiedUserOrDefault(ar);
    UserPage uPage = UserPage.findOrCreateUserPage(uProf.getKey());

    pageTitle = "User: "+uProf.getName();
    specialTab = "Multi-Status";

    String srid = ar.reqParam("srid");
    boolean isCreateCase = srid.equals("xxx");

    StatusReport stat = null;
    String statName =  "Status Report "+(System.currentTimeMillis()%1000);
    String statDesc =  "";

    if (isCreateCase) {
        //actually, this one is NOT saved in the page at this point,
        //will be saved at the next step.  This just makes the logic
        //below easier (but maybe instead should be null)
        stat = uPage.createStatusReport();
    }
    else {
        stat = uPage.findStatusReportOrFail(srid);
        statName = stat.getName();
        statDesc = stat.getDescription();
    }
    List<ProjectLink> projects = stat.getProjects();

    List<WatchRecord> watchList = uProf.getWatchList();
    List<NGPageIndex> watchedProjects = new ArrayList<NGPageIndex>();
    List seenProjects = new Hashtable();
    for (WatchRecord wr : watchList) {
        String pageKey = wr.getPageKey();
        NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(pageKey);
        if (ngpi!=null) {
            watchedProjects.add(ngpi);
            seenProjects.put(ngpi.containerKey, "dummy");
        }
    }

    TaskHelper th = new TaskHelper(uProf.getUniversalId(), "");
    th.scanAllTask(ar.getCogInstance());
    List<GoalRecord> myActive = th.getActiveTasks();
    for (GoalRecord tr : myActive)
    {
        NGContainer ngc = th.getPageForTask(tr);
        if (ngc instanceof NGPage) {
            String pageKey = ngc.getKey();
            if (!seenProjects.containsKey(pageKey)) {
                watchedProjects.add(ar.getCogInstance().getContainerIndexByKey(pageKey));
                seenProjects.put(pageKey, "dummy");
            }
        }
    }

    NGPageIndex.sortInverseChronological(watchedProjects);%>
<%@ include file="Header.jsp"%>

 <div class="section">
     <div class="section_title">
         <h1 class="left"><%if(isCreateCase){%>Creating Status Report<%}else{%>Editing Status Report <%=stat.getId()%><%}%></h1>
         <div class="section_date right"></div>
         <div class="clearer">&nbsp;</div>
     </div>
     <div class="section_body">
     <form action="PStatus2Action.jsp" method="get">
     <p><input type="submit" value="Update Project Selection">
     The following checked projects will be included in the report:
     <input type="hidden" name="srid" value="<%ar.writeHtml(srid);%>"></p>

        <table>
        <col width="30">
        <col width="400">
        <tr>
           <td align="right">Name:</td>
           <td><input type="text" name="statName" value="<%ar.writeHtml(statName);%>"></td>
        </tr>
        <tr>
           <td align="right">Description:</td>
           <td><textarea name="statDesc"><%ar.writeHtml(statDesc);%></textarea></td>
        </tr>
        <tr>
           <td></td>
           <td><b>Workspaces to Include</b></td>
        </tr>
<%

    for (NGPageIndex proj : watchedProjects)
    {
        ProjectLink found = null;
        String key = proj.containerKey;
        for (ProjectLink pl : projects) {
            if (key.equals(pl.getKey())) {
                found = pl;
            }
        }
        String checkString = "";
        if (found != null) {
            checkString = " checked=\"checked\"";
        }
        %>
        <tr>
            <td><input type="checkbox"<%=checkString%> name="watch" value="<%ar.writeHtml(proj.containerKey);%>"></td>
            <td><%ar.writeHtml(proj.containerName);%></td>
        <tr>

        <%
    }

%>
         </table>
         </form>
     </div>
 </div>




<%
    out.flush();

%>


<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
