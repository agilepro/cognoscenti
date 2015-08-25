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
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%>
<%
    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't create a task.");

    String p = ar.reqParam("p");

    assureNoParameter(ar, "s");

    String ptid = ar.defParam("ptid", null);
    String n = ar.defParam("n", null);

    if (n!=null)
    {
        throw new Exception("EditTask.jsp should NOT have a parameter n");
    }

    boolean creatingSubTask = (ptid != null && ptid.length() > 0);

    // ngp the ar variables are defined in the Header.jsp.
    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Can not create a new task.");

    uProf = ar.getUserProfile();

    String go = ar.defParam("go", ar.getResourceURL(ngp,""));

    GoalRecord parentTask = null;
    String synopsis = "";

    if (creatingSubTask) {
        parentTask = ngp.getGoalOrFail(ptid);
    }

    String fullnameList = getUserFullNameList();
    pageTitle = ngp.getFullName();
%>

<%@ include file="Header.jsp"%>

    <form name="taskForm" action="EditTaskAction.jsp" method="post">

        <input type="hidden" name="p" value="<%ar.writeHtml(p);%>">
        <input type="hidden" name="go" value="<%ar.writeHtml(go);%>">
        <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
        <input type="hidden" name="ptid" value="<%ar.writeHtml(ptid);%>">

<%
    if (creatingSubTask)
    {
%>
        <b>Creating Sub Task for the Task - <%
            ar.writeHtml(parentTask.getSynopsis());
        %></b>
<%
    }
    else
    {
%>
        <b>Creating New Task</b>
<%
    }
%>
        <center>
        <br/>

            <button type="submit" id="saveActBtn" name="action"
                value="Create New Task">Save Changes</button>

            <button type="submit" id="createSubPageActBtn" name="action"
                value="Create Sub Page for this Task">Create Sub Page for this Task</button>

        </center>
        <br/>
        <table width="98%" class="Design8">

            <col width="20%"/>
            <col width="80%"/>

<%
    if (creatingSubTask)
    {
%>
            <tr>
                <td>Parent Task</td>
                <td class="Odd"><%
                    ar.writeHtml(parentTask.getSynopsis());
                %>&nbsp;(<%=parentTask.getId()%>)</td>
            </tr>
<%
    }
%>
            <tr>
                <td>Subject</td>
                <td class="Odd"> <input type="text" name="synopsis" style="WIDTH: 96%;"
                    value="Change the SubTask Name"/></td>
            </tr>
            <tr><td>Description</td>
                <td class="Odd"><textarea name="description"
                style="WIDTH:96%; HEIGHT:74px"></textarea></td>
            </tr>
            <tr>
                <td><br/>Assignee<br/>&nbsp;</td>
                <td class="Odd"><div style="WIDTH: 96%;">
                    <input type="text" name="assignee" id="assignee"
                        value=""/>
                   </div>
                </td>
            </tr>
            <tr>
                <td>State</td>
                <td class="Odd">
                <input type="radio" name="state" value="<%=BaseRecord.STATE_UNSTARTED%>"/>
                    <img src="assets/goalstate/small1.gif"/>
                    <%
                        ar.writeHtml(GoalRecord.stateName(BaseRecord.STATE_UNSTARTED));
                    %><br/>

                <input type="radio" name="state" value="<%=BaseRecord.STATE_STARTED%>" checked="checked" />
                    <img src="assets/goalstate/small2.gif"/>
                    <%
                        ar.writeHtml(GoalRecord.stateName(BaseRecord.STATE_STARTED));
                    %><br/>

                <input type="radio" name="state" value="<%=BaseRecord.STATE_ACCEPTED%>"/>
                    <img src="assets/goalstate/small3.gif"/>
                    <%
                        ar.writeHtml(GoalRecord.stateName(BaseRecord.STATE_ACCEPTED));
                    %><br/>
                </td>
            </tr>

            <tr>
                <td>Sub Process</td>
                <td class="Odd">
                    <input type="text" name="sub" style="WIDTH: 96%;" value=""/>
                </td>
            </tr>
            <tr>
                <td>Priority</td>
                <td class="Odd">
                    <select style="width:155px" name="priority" id="priority">
<%
    for (int i=1; i<=GoalRecord.MAX_TASK_PRIORITY; i++)
    {
        String selected = "";
        if (i==0) {
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
                <td class="Odd"><input type="text" name="dueDate" id="dueDate" size="20" value="" />
                </td>
            </tr>
            <tr>
                <td>Start Date</td>
                <td class="Odd"><input type="text" name="startDate" id="startDate" size="20" value="" />
                </td>
            </tr>
            <tr>
                <td>Duration (Days)</td>
                <td class="Odd">
                    <select style="width:155px" name="duration" id="duration" onChange="calculateTaskEndDate()">
<%
    for (int i=1; i<=GoalRecord.MAX_TASK_DURATION; i++)
    {
        String selected = "";
        if (i==0) {
            selected = "selected=\"selected\"";
        }
        out.write("     <option " + selected + " value=\"" + i + "\" >" + i + "</option>");
    }
%>
                    </select>
                </td>
            </tr>
            <tr>
                <td>End Date</td>
                <td class="Odd">
                    <input type="text" name="endDate" id="endDate" size="20" value=""
                    onChange="calculateDuration()" />
                </td>
            </tr>
            <tr>
                <td>Status</td>
                <td class="Odd"><input type="text" name="status" style="WIDTH: 96%;" value=""/></td>
            </tr>
            <tr>
                <td>Accomplishment</td>
                <td class="Odd"><textarea name="accomp" style="WIDTH: 96%; HEIGHT:74px"></textarea></td>
             </tr>
            <tr><td>Action Scripts</td>
                <td class="Odd"><textarea name="ascripts" style="WIDTH:96%; HEIGHT:74px"></textarea></td>
            </tr>
        </table>
        <br/>

    </form>
    <br/>
    <br/>

<script>
    var saveActBtn = new YAHOO.widget.Button("saveActBtn");
    var createSubPageActBtn = new YAHOO.widget.Button("createSubPageActBtn");
</script>


<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
