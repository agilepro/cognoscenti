<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.LicensedURL"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.ProcessRecord"
%><%@page import="org.socialbiz.cog.ProjectLink"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.StatusReport"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.WatchRecord"
%><%@page import="org.socialbiz.cog.rest.TaskHelper"
%><%@page import="java.io.StringWriter"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.List"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);

    uProf = findSpecifiedUserOrDefault(ar);
    UserPage uPage = UserPage.findOrCreateUserPage(uProf.getKey());

    String daysStr = ar.defParam("days", "7");
    int days = DOMFace.safeConvertInt(daysStr);
    long endTime = ar.nowTime;
    long startTime = endTime - (((long)days) * 24 * 60 * 60 * 1000);
    int max = 4;

    pageTitle = "Multi Project Status Report";
    specialTab = "Multi-Status";
    newUIResource = "projectAllTasks.htm";

    Vector<WatchRecord> watchList = uProf.getWatchList();
    Vector<NGPageIndex> watchedProjects = new Vector<NGPageIndex>();


    String srid = ar.reqParam("srid");
    StatusReport stat = uPage.findStatusReportOrFail(srid);
    List<ProjectLink> allProjs = stat.getProjects();
    for (ProjectLink pl : allProjs) {
        String pageKey = pl.getKey();
        NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(pageKey);
        if (ngpi!=null) {
            watchedProjects.add(ngpi);
        }
    }

    StringWriter wikiNote = new StringWriter();
    NGPageIndex.sortInverseChronological(watchedProjects);
%>

<%@ include file="Header.jsp"%>
<%
    headlinePath(ar, "Status Report");

    if (!ar.isLoggedIn())
    {
        mustBeLoggedInMessage(ar);
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
        <% SectionUtil.nicePrintDateAndTime(ar.w, endTime); %> </td>
        </tr>
        </table>
        <hr/><br/>

        <%
        for (NGPageIndex proj : watchedProjects)
        {
            NGPage ngp = proj.getPage();
            String thisPageAddress = ar.getResourceURL(ngp,"process.htm");
            gatherWikiProcess(ar, ngp, 1, thisPageAddress, max, startTime, endTime, wikiNote);
        }
        String wikiString = wikiNote.toString();
        %>

        <%

            WikiConverter.writeWikiAsHtml(ar, wikiString);

        %>
        <hr/>
        <p>Wiki Format:</p>
        <textarea cols="80" rows="10"><%

            ar.writeHtml(wikiString);

        %></textarea>
        <br/>
        <hr/>
    </div>
</div>
<%   } %>

<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>


<%!


    public void gatherWikiProcess(AuthRequest ar, NGPage ngp, int level, String thisPageAddress,
        int max, long startTime, long endTime, StringWriter wikiNote)
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
                    gatherWikiGoal(ar, ngp, goal, level, thisPageAddress, max, startTime, endTime, wikiNote);
                }
            }
        }
    }

    public void gatherWikiGoal(AuthRequest ar, NGPage ngp,
                  GoalRecord task, int level, String thisPageAddress, int max,
                  long startTime, long endTime, StringWriter wikiNote)
        throws Exception
    {
        List<HistoryRecord> histRecs = task.getTaskHistoryRange(ngp, startTime, endTime);

        if (task.getState() == BaseRecord.STATE_ACCEPTED || histRecs.size()>0)
        {
            if (!lastKey.equals(ngp.getKey()))
            {
                //put out Page title if not already output
                lastKey = ngp.getKey();
                wikiNote.write("\n!Project: ");
                convertToWiki(wikiNote, ngp.getFullName());
            }

            //get task name
            wikiNote.write("\n*Action Item: ");
            convertToWiki(wikiNote, task.getSynopsis());

            //add assignees
            wikiNote.write(" (");
            NGRole ass = task.getAssigneeRole();
            boolean multiple = false;
            for (AddressListEntry ae : ass.getExpandedPlayers(ngp)) {
                if (multiple) {
                    wikiNote.write(", ");
                }
                convertToWiki(wikiNote, ae.getName());
                multiple = true;
            }
            wikiNote.write(") - ");
            wikiNote.write(task.stateName(task.getState()));

            String status = task.getStatus();
            if (status!=null && status.length()>0) {
                wikiNote.write("\n**Status: ");
                convertToWiki(wikiNote, status);

            }


            for (HistoryRecord history : histRecs)
            {
                String msg = history.getComments();
                if(msg==null || msg.length()==0)
                {
                    msg=HistoryRecord.convertEventTypeToString(history.getEventType());
                }
                else
                {
                    wikiNote.write("\n**");
                    SectionUtil.nicePrintDate(wikiNote, history.getTimeStamp());
                    wikiNote.write(": ");
                    convertToWiki(wikiNote, msg);
                }
            }

        }

        //check for subtasks
        List<GoalRecord> children = task.getSubGoals();
        for (GoalRecord child : children) {
            gatherWikiGoal(ar, ngp, child, level+1, thisPageAddress, max, startTime, endTime, wikiNote);
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

        gatherWikiProcess(ar, subpage.getPage(), level+1, thisPageAddress, max, startTime, endTime, wikiNote);

    }

    public void outputProcess(AuthRequest ar, NGPage ngp, int level, String thisPageAddress,
        int max, long startTime, long endTime, StringWriter wikiNote)
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
                    outputTask(ar, ngp, goal, level, thisPageAddress, max, startTime, endTime, wikiNote);
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
                  long startTime, long endTime, StringWriter wikiNote)
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
                ar.write("\" title=\"see the page this action item is on\">");
                ar.writeHtml(ngp.getFullName());
                ar.write("</a></b></td></tr>");
                lastKey = ngp.getKey();

                wikiNote.write("\n!Project: ");
                convertToWiki(wikiNote, ngp.getFullName());
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

            //get task name
            wikiNote.write("\n*Action Item: ");
            convertToWiki(wikiNote, task.getSynopsis());

            //add assignees
            wikiNote.write(" (");
            NGRole ass = task.getAssigneeRole();
            boolean multiple = false;
            for (AddressListEntry ae : ass.getExpandedPlayers(ngp)) {
                if (multiple) {
                    wikiNote.write(", ");
                }
                convertToWiki(wikiNote, ae.getName());
                multiple = true;
            }
            wikiNote.write(") - ");
            wikiNote.write(task.stateName(task.getState()));

            String status = task.getStatus();
            if (status!=null && status.length()>0) {
                wikiNote.write("\n**Status: ");
                convertToWiki(wikiNote, status);

            }


            for (HistoryRecord history : histRecs)
            {
                String msg = history.getComments();
                if(msg==null || msg.length()==0)
                {
                    msg=HistoryRecord.convertEventTypeToString(history.getEventType());
                }
                else
                {
                    wikiNote.write("\n**");
                    SectionUtil.nicePrintDate(wikiNote, history.getTimeStamp());
                    wikiNote.write(": ");
                    convertToWiki(wikiNote, msg);
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
            outputTask(ar, ngp, child, level+1, thisPageAddress, max, startTime, endTime, wikiNote);
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

        outputProcess(ar, subpage.getPage(), level+1, thisPageAddress, max, startTime, endTime, wikiNote);

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
    }

    public static void convertToWiki(StringWriter wikiNote, String value)
    {
        int last = value.length();
        for (int i=0; i<last; i++) {
            char c = value.charAt(i);
            switch (c) {
                case '\n':
                    //need to indent lines so that converted text stays part of a single paragraph
                    wikiNote.write(" ");
                    break;
                case '_':
                    wikiNote.write("บ_");
                    break;
                case '\'':
                    wikiNote.write("บ\'");
                    break;
                case '[':
                    wikiNote.write("บ[");
                    break;
                case 'บ':
                    wikiNote.write("บบ");
                    break;
                default:
                    wikiNote.write(c);
            }
        }
    }%>
