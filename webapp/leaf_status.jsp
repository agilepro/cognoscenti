<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.List"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.LicensedURL"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.w3c.dom.Element"
%><%ar = AuthRequest.getOrCreate(request, response, out);
    ar.retPath="../../";

    String p = ar.reqParam("p");
    String daysStr = ar.defParam("days", "7");
    int days = DOMFace.safeConvertInt(daysStr);
    long endTime = ar.nowTime;
    long startTime = endTime - (((long)days) * 24 * 60 * 60 * 1000);
    int max = 4;

    ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    boolean isMember = ar.isMember();
    boolean isAdmin = ar.isAdmin();

    ngb = ngp.getSite();
    pageTitle = ngp.getFullName() + ": Status Report";
    specialTab = "Status";
    newUIResource = "projectAllTasks.htm";

    String thisPageAddress = ar.getResourceURL(ngp,"process.htm");%>

<%@ include file="Header.jsp"%>
<%
    headlinePath(ar, "Status Report");

    if (!ar.isLoggedIn())
    {
        mustBeLoggedInMessage(ar);
    }
    else if (!isMember)
    {
        mustBeMemberMessage(ar);
    }
    else
    {
%>
<div class="section">
    <div class="section_title">
        <h1 class="left">Status Report</h1>
        <div class="section_date right"></div>
        <div class="clearer">&nbsp;</div>
    </div>
    <div class="section_body">
        <table><tr><td>Process status from
        <% SectionUtil.nicePrintDateAndTime(ar.w, startTime);%>
        to
        <% SectionUtil.nicePrintDateAndTime(ar.w, endTime); %> - - </td>
        <form action="status.htm" method="get">
        <td>
           <input type="submit" value="Refresh">
           <input type="text" name="days" value="<% ar.writeHtml( Integer.toString(days) ); %>" size="5">
           days
        </td></form></tr>
        </table>

        <table>
        <col width="300">
        <col width="100">
        <col width="100">
        <col width="100">
        <tr>
           <td></td>
           <td>Assigned</td>
           <td>Due</td>
           <td>Est/Actual</td>
        </tr>
        <% outputProcess(ar, ngp, 1, thisPageAddress, max, startTime, endTime);%>

        </table>
        <hr/>
    </div>
</div>
<%   } %>

<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>


<%!public void outputProcess(AuthRequest ar, NGPage ngp, int level, String thisPageAddress,
        int max, long startTime, long endTime)
        throws Exception
    {
        List<GoalRecord> grlist = ngp.getAllGoals();
        GoalRecord.sortTasksByRank(grlist);

        if (grlist.size()>0)
        {
            for (GoalRecord goal : grlist)
            {
                //tasks with parents will be handled recursively
                //as long as parent setting is valid
                if (!goal.hasParentGoal())
                {
                    outputTask(ar, ngp, goal, level, thisPageAddress, max, startTime, endTime);
                }
            }
        }
        else
        {
            indentToLevel(ar, level);
            ar.write("<i>no tasks in this process</i></td></tr>");
        }
    }

    public void indentToLevel(AuthRequest ar, int level)
        throws Exception
    {
        ar.write("\n<tr>");
        ar.write("<td>");
    }



    String lastKey = "";

    public void outputTask(AuthRequest ar, NGPage ngp,
                  GoalRecord task, int level, String thisPageAddress, int max,
                  long startTime, long endTime)
        throws Exception
    {
        List<HistoryRecord> histRecs = task.getTaskHistoryRange(ngp, startTime, endTime);

        if (task.getState() == BaseRecord.STATE_ACCEPTED || histRecs.size()>0)
        {
            if (!lastKey.equals(ngp.getKey()))
            {
                //put out Page title if not already output
                ar.write("<tr><td colspan=\"8\"><br/><hr/>Project: <b><a href=\"");
                ar.write(ar.retPath);
                ar.write(ar.getResourceURL(ngp,""));
                ar.write("\" title=\"see the page this task is on\">");
                ar.writeHtml(ngp.getFullName());
                ar.write("</a></b></td></tr>");
                lastKey = ngp.getKey();
            }

            ar.write("<tr><td>&nbsp;</td></tr>");  // a little space

            indentToLevel(ar, 1);
            ar.write("<a href=\"");
            ar.writeHtml(ar.retPath);
            ar.write("WorkItem.jsp?p=");
            ar.writeURLData(ngp.getKey());
            ar.write("&amp;s=Tasks&amp;id=");
            ar.write(task.getId());
            ar.write("&amp;go=");
            ar.writeURLData(thisPageAddress);
            ar.write("\" title=\"View details and modify activity state\"><img src=\"");
            ar.writeHtml(ar.retPath);
            ar.writeHtml(task.stateImg(task.getState()));
            ar.write("\"></a> <b>");
            ar.writeHtml(task.getSynopsis());
            ar.write("</b>");

            String dlink = task.getDisplayLink();
            if (dlink!=null && dlink.length()>0)
            {
                ar.write(" <a href=\"");
                ar.writeHtml(task.getDisplayLink());
                ar.write("\"><img src=\"");
                ar.writeHtml(ar.retPath);
                ar.write("drilldown.gif\"></a>");
            }
            ar.write("</td><td>");
            task.writeUserLinks(ar);
            ar.write("</td><td>");
            SectionUtil.nicePrintDate(ar.w, task.getDueDate());
            ar.write("</td><td>");
            SectionUtil.nicePrintDate(ar.w, task.getEndDate());
            ar.write("</td></tr>");

            ar.write("<tr><td colspan=\"3\">status: <i>");
            ar.writeHtml( task.getStatus());
            ar.write("</i></td></tr>");

            for (HistoryRecord history : histRecs)
            {
                String msg = history.getComments();
                if(msg==null || msg.length()==0)
                {
                    msg=HistoryRecord.convertEventTypeToString(history.getEventType());
                }
                ar.write("<tr><td colspan=\"3\">");
                SectionUtil.nicePrintDateAndTime(ar.w, history.getTimeStamp());
                ar.write(" -");
                ar.writeHtml(msg);
                ar.write("</td></tr>");
            }

        }

        //check for subtasks
        List<GoalRecord> children = task.getSubGoals();
        for (GoalRecord child : children) {
            outputTask(ar, ngp, child, level+1, thisPageAddress, max, startTime, endTime);
        }

        String sub = task.getSub();
        if (sub==null ||sub.length()==0)
        {
            return;
        }

        if (level>=max)
        {
            return;  //don't even try to go that many levels, avoid infinite recursion
        }

        //fake it without doing the HTTP fetch, instead get the id from the URL

        String pageid = getKeyFromURL(sub);
        if (pageid==null)
        {
            throw new Exception("pageid is null for sub="+sub);
        }

        NGPageIndex subpage = ar.getCogInstance().getContainerIndexByKey(pageid);

        if (subpage==null)
        {
            //try again with lower case ... old URL with uppercase in data still
            //in the data set.   Should clean up data.
            subpage = ar.getCogInstance().getContainerIndexByKey(pageid.toLowerCase());
            if (subpage==null)
            {
                return;  //ignore it, bad URL
            }
        }

        outputProcess(ar, subpage.getPage(), level+1, thisPageAddress, max, startTime, endTime);

    }

    public String getKeyFromURL(String url)
    {
        int ppos = url.indexOf("/p/")+3;
        if (ppos<3)
        {
            if (!url.startsWith("p/"))
            {
                return null;   //no p slashes, ignore this
            }
            ppos = 2;
        }
        int secondSlash = url.indexOf("/", ppos);
        if (secondSlash<=0)
        {
            return null;   //no second slash, ignore this
        }
        return url.substring(ppos, secondSlash);
    }%>
