<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.DOMFace"
%><%@page import="org.socialbiz.cog.LicensedURL"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.ProcessRecord"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%><%ar = AuthRequest.getOrCreate(request, response, out);
    ar.retPath="../../";

    String p = ar.reqParam("p");
    String maxStr = ar.defParam("max", "1");
    int max = DOMFace.safeConvertInt(maxStr);
    if (max>4 || ar.isStaticSite())
    {
        max = 4;
    }
    if (max<1)
    {
        max = 1;
    }

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    boolean isMember = ar.isMember();
    boolean isAdmin = ar.isAdmin();

    ngb = ngp.getSite();
    pageTitle = ngp.getFullName();
    specialTab = "Process";
    newUIResource = "projectAllTasks.htm";

    String thisPageAddress = ar.getResourceURL(ngp,"process.htm");
    String beLink = ar.retPath + "t/" + ngb.getKey() + "/" + ngp.getKey() + "/project.htm";%>

<%@ include file="Header.jsp"%>
<%
    headlinePath(ar, "Process Section");

    if (!ar.isLoggedIn()  && !ar.isStaticSite())
    {
        mustBeLoggedInMessage(ar);
    }
    else if (!isMember  && !ar.isStaticSite())
    {
        mustBeMemberMessage(ar);
    }
    else
    {
%>
<div class="section">
    <div class="section_title">
        <h1 class="left">Process
        <% if (!ar.isStaticSite()) { %>
        <a href="<%=ar.retPath%>Edit.jsp?s=Tasks&p=<%=URLEncoder.encode(ngp.getKey(), "UTF-8")%>">
            <img src="<%=ar.retPath%>update.gif"></a>

            <% if (max==1) { %>
            <a href="process4.htm">Include Sub-Projects</a>
            <% } else { %>
            <a href="process.htm">Only This Project</a>
            <% } %>

        <a href="<%=ar.retPath%>ProjectTasksEmail.jsp?p=<%=URLEncoder.encode(ngp.getKey(), "UTF-8")%>">
            <img src="<%=ar.retPath%>emailIcon.gif"></a>
        <% } /* static site */ %>
            </h1>
        <div class="section_date right"></div>
        <div class="clearer">&nbsp;</div>
    </div>
    <div class="section_body">
        <table width="100%">
        <col width="30">
        <col width="30">
        <col width="30">
        <col width="30">
        <col width="30">
        <col width="30">
        <col width="220">
        <col width="200">
        <col width="100">
        <col width="100">
        <% outputParentGoal(ar, ngp, thisPageAddress);%>
        <tr><td colspan="10">&nbsp;<br/></td></tr>
        <tr><td colspan="10"><hr/></td></tr>
        <tr><td colspan="7">Task</td>
            <td>assignee</td>
            <td>ModDate</td>
            <td>ModUser</td>
<!--            <td>due</td>
            <td>estimated</td> -->
        </tr>
        <tr><td colspan="10"><hr/></td></tr>
        <% outputProcess(ar, ngp, 1, thisPageAddress, max);%>

        </table>

        <br/><br/>
            <% if (!ar.isStaticSite()) { %>
            <a href="<%=beLink%>" target="_blank"><h2>Open GWT Notes</h2></a>
            <% } %>
        <br/><br/>

        <hr/>
    </div>
</div>
<%   } %>

<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>


<%!public void outputParentGoal(AuthRequest ar, NGPage ngp, String thisPageAddress)
        throws Exception
    {
        NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKeyOrFail(ngp.getKey());
        ProcessRecord pr = ngp.getProcess();
        if (pr==null)
        {
            throw new Exception("No process????");
        }
        LicensedURL[] parents = pr.getLicensedParents();
        if (parents==null)
        {
            throw new Exception("No parents????");
        }

        for (LicensedURL lu : parents)
        {
            String url = lu.getCombinedRepresentation();

            //this works only on a single site
            String pageid = getKeyFromURL(url);
            NGPageIndex subpage = ar.getCogInstance().getContainerIndexByKey(pageid);

            indentToLevel(ar,1);
            ar.write("Parent: ");
            if (subpage!=null)
            {
                subpage.writeTruncatedLink(ar, 30);
            }
            else
            {
                ar.write("could not find: ");
                ar.writeHtml(url);
            }
            ar.write("</td></tr>");
        }

    }

    public void outputProcess(AuthRequest ar, NGPage ngp, int level, String thisPageAddress, int max)
        throws Exception
    {
        NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKeyOrFail(ngp.getKey());

        ProcessRecord pr = ngp.getProcess();
        List<GoalRecord> grlist = ngp.getAllGoals();
        GoalRecord.sortTasksByRank(grlist);

        {
            indentToLevel(ar, level);
            ar.write("<img src=\"");
            ar.write(ar.retPath);
            ar.write("leaf.gif\">: ");
            ngpi.writeTruncatedLink(ar, 30);
            String goal = pr.getSynopsis();
            if (goal!=null && goal.length()>0)
            {
                ar.write(" (Goal: ");
                ar.writeHtml(goal);
                ar.write(")");
            }
            ar.write("</td><td>");
            ar.write("</td></tr>");

        }

        if (grlist.size()>0)
        {
            for (GoalRecord goal : grlist)
            {
                //tasks with parents will be handled recursively
                //as long as parent setting is valid
                if (!goal.hasParentGoal())
                {
                    outputTask(ar, ngp, goal, level, thisPageAddress, max);
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
        for (int j=1; j<level; j++)
        {
            ar.write("<td></td>");
        }
        ar.write("<td colspan=\"");
        ar.write(Integer.toString(8-level));
        ar.write("\">");
    }


    public void outputTask(AuthRequest ar, NGPage ngp,
                  GoalRecord task, int level, String thisPageAddress, int max)
        throws Exception
    {
        indentToLevel(ar, level);
        if (!ar.isStaticSite())
        {
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
            ar.write("\"></a> ");

            ar.writeHtml(AccessControl.getAccessGoalParams(ngp,task));
            ar.write("|");
            if (AccessControl.canAccessGoal(ar, ngp, task)) {
                ar.write("yes|");
            }
            else {
               ar.write("no|");
            }
            if (task.isPassive()) {
                ar.write(" (passive)");
            }
        }
        else
        {
            ar.write("<img src=\"");
            ar.writeHtml(ar.retPath);
            ar.writeHtml(task.stateImg(task.getState()));
            ar.write("\"> ");
        }



        ar.writeHtml(task.getSynopsis());

        String dlink = task.getDisplayLink();
        if (dlink!=null && dlink.length()>0)
        {
            String pageid = getKeyFromURL(dlink);
            NGPageIndex subpage = ar.getCogInstance().getContainerIndexByKey(pageid);

            if (subpage!=null) {
                ar.write(" <a href=\"");
                ar.writeHtml(ar.retPath);
                ar.writeHtml(ar.getResourceURL(subpage, "process.htm"));
                ar.write("\"><img src=\"");
                ar.writeHtml(ar.retPath);
                ar.write("drilldown.gif\"></a>");
            }
            else {
                ar.write("<img src=\"");
                ar.writeHtml(ar.retPath);
                ar.write("ts_error.gif\">");
            }
        }
        ar.write("</td><td>");
        task.writeUserLinks(ar);
        ar.write("</td><td>");
        SectionUtil.nicePrintDate(ar.w, task.getModifiedDate());
        ar.write("</td><td>");
        ar.writeHtml(task.getModifiedBy());
        ar.write("</td></tr>");

        //check for subtasks
        List<GoalRecord> children = task.getSubGoals();
        for (GoalRecord child : children)
        {
            outputTask(ar, ngp, child, level+1, thisPageAddress, max);
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

        outputProcess(ar, subpage.getPage(), level+1, thisPageAddress, max);

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
