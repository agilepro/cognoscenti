<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionTask"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.ProcessRecord"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't edit a process.");

    String p = ar.reqParam("p");
    String id = ar.defParam("id", null);

    assureNoParameter(ar, "s");

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);

    String go = ar.defParam("go", null);
    if (go==null)
    {
        go = ar.getResourceURL(ngp,"");
    }

    String synopsis = "";
    String desc = "";
    int state = 0;
    long dueDate = 0;
    long startDate = 0;
    long endDate = 0;
    int priority = 0;

    ProcessRecord process = ngp.getProcess();
    synopsis = process.getSynopsis();
    desc = process.getDescription();
    state = process.getState();
    dueDate = process.getDueDate();
    startDate = process.getStartDate();
    endDate = process.getEndDate();
    priority = process.getPriority();

    pageTitle = ngp.getFullName();
%>

<%@ include file="Header.jsp"%>


    <form action="EditProcessAction.jsp" method="post">
        <input type="hidden" name="p" value="<% ar.writeHtml(p); %>"/>
        <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
        <center><button type="submit" id="actBtn" name="action" value="Save Changes">Save Goal Changes</button></center>
        <br/>

        <table width="95%" class="Design8">
            <col width="20%"/>
            <col width="80%"/>

<% if (id!=null) {  %>
            <input type="hidden" name="id" value="<%ar.writeHtml(id);%>">
<% } %>
            <input type="hidden" name="go" value="<% ar.writeHtml(go); %>">

                <tr>
                    <td>Subject</td>
                    <td class="odd"><input type="text" name="synopsis" value="<% ar.writeHtml(synopsis);%>" style="WIDTH: 96%;"></td>
                </tr>
                <tr>
                    <td>Description</td>
                    <td class="odd"><textarea name="desc" style="WIDTH: 96%; HEIGHT:74px"><% ar.writeHtml(desc);%></textarea></td>
                </tr>
                <tr>
                    <td>State</td>
                    <td class="odd">
<%
for (int i=0; i<7; i++)
{

    String checked = "";
    if (state==i)
    {
        checked = " checked=\"checked\"";
    }
%>
                    <input type="radio" name="state" value="<%=i%>"<%=checked%>/>&nbsp;
                    <img src="<% ar.writeHtml(ProcessRecord.stateImg(i)); %>"/>&nbsp;
                    <% ar.writeHtml(ProcessRecord.stateName(i)); %>
                    <br/>

<%
    }
%>
                </td>
            </tr>

            <tr>
                <td>Priority</td>
                <td class="odd">
                    <select style="width:155px" name="priority" id="priority">
<%
    for (int i=1; i<=ProcessRecord.MAX_TASK_PRIORITY; i++)
    {
        String selected = "";
        if (i==priority) {
            selected = "selected=\"selected\"";
        }
        out.write("     <option " + selected + " value=\"" + i + "\" >" + i + "</option>");
    }
%>
                    </select>
                </td>
            </tr>

            <tr>
                <td>Due Date</td>
                <td class="odd"><input type="text" name="dueDate" id="dueDate" size="20" value="<% SectionUtil.nicePrintDate(out, dueDate); %>" />
                </td>
            </tr>
            <tr>
                <td>Start Date</td>
                <td class="odd">
                    <input type="text" name="startDate" id="startDate" size="20" value="<% SectionUtil.nicePrintDate(out, startDate); %>" />
                </td>
            </tr>
            <tr>
                <td>End Date</td>
                <td class="odd">
                    <input type="text" name="endDate" id="endDate" size="20" value="<% SectionUtil.nicePrintDate(out, endDate); %>" />
                </td>
            </tr>
        </table>
    </form>
    <br/>


<script>
    var actBtn = new YAHOO.widget.Button("action");
</script>


<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
