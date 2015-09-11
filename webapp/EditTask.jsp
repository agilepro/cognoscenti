<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionTask"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.List"
%><%@page import="java.util.Vector"
%>
<%
    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't edit a goal.");

    String p = ar.reqParam("p");
    String id = ar.reqParam("id");
    String go = ar.defParam("go", null);

    assureNoParameter(ar, "s");

    if (ar.defParam("n", null)!=null)
    {
        throw new Exception("EditTask.jsp should NOT have a parameter n");
    }


    // ngp and the ar variables are defined in the Header.jsp.
    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Can not edit a goal.");
    ngb = ngp.getSite();

    uProf = ar.getUserProfile();

    if (go==null)
    {
        go = ar.retPath + ar.getResourceURL(ngp,"");
    }

    GoalRecord task = ngp.getGoalOrFail(id);

    String synopsis    = task.getSynopsis();
    String description = task.getDescription();
    String assignee    = task.getAssigneeCommaSeparatedList();
    String status      = task.getStatus();
    int    state       = task.getState();
    long   dueDate     = task.getDueDate();
    long   startDate   = task.getStartDate();
    long   endDate     = task.getEndDate();
    String sub         = task.getSub();
    int    rank        = task.getRank();
    String aScripts    = task.getActionScripts();
    long   duration    = task.getDuration();
    int    priority    = task.getPriority();
    String parentTask  = task.getParentGoalId();

    List<HistoryRecord> accomps = task.getTaskHistory(ngp);

    String fullnameList = getUserFullNameList();
    pageTitle = ngp.getFullName();

%>

<%@ include file="Header.jsp"%>

    <form name="taskForm" action="EditTaskAction.jsp" method="post">

        <input type="hidden" name="p" value="<%ar.writeHtml(p);%>">
        <input type="hidden" name="go" value="<%ar.writeHtml(go);%>">
        <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
        <input type="hidden" name="id" value="<%ar.writeHtml(id);%>">

        <center>
        <br/>
        <a href="WorkItem.jsp?p=<%ar.writeURLData(p);%>&amp;id=<%ar.writeURLData(id);%>">[Work Item]</a>

            <button type="submit" id="saveActBtn" name="action"
                value="Save Changes">Save Changes</button>

            <button type="submit" id="createSubTaskActBtn" name="action"
                value="Create Sub Goal">Create Sub Goal</button>

            <button type="submit" id="renumActBtn" name="action"
                value="Renumber Ranks">Renumber Ranks</button>
        </center>
        <br/>
        <table width="98%" class="Design8">

            <col width="20%"/>
            <col width="80%"/>

            <tr>
                <td>Subject</td>
                <td class="Odd"> <input type="text" name="synopsis" style="WIDTH: 96%;"
                    value="<%ar.writeHtml(synopsis);%>"/></td>
            </tr>
            <tr><td>Description</td>
                <td class="Odd"><textarea name="description"
                style="WIDTH:96%; HEIGHT:74px"><%
                    ar.writeHtml(description);
                %></textarea></td>
            </tr>
            <tr>
                <td><br/>Assignee<br/>&nbsp;</td>
                <td class="Odd"><div style="WIDTH: 96%;">
                    <input type="text" name="assignee" id="assignee"
                        value="<%ar.writeHtml(assignee);%>"/>
                   </div>
                </td>
            </tr>
            <tr>
                <td>State</td>
                <td class="Odd">
<%
    for (int i=0; i<=9; i++)
        {

            String checked = "";
            if (state==i)
            {
                checked = " checked=\"checked\"";
            }
%>
                <input type="radio" name="state" value="<%=i%>"<%=checked%>/>
                    <img src="<%ar.writeHtml(GoalRecord.stateImg(i));%>"/>
                    <%
                        ar.writeHtml(GoalRecord.stateName(i));
                    %><br/>
<%
    }
%>
                </td>
            </tr>
            <tr>
                <td>Sub Process</td>
                <td class="Odd">
                    <input type="text" name="sub" style="WIDTH: 96%;" value="<%ar.writeHtml(sub);%>"/>
                </td>
            </tr>
            <tr>
                <td>Parent Goal</td>
                <td class="Odd">
                    <input type="text" name="sub" style="WIDTH: 96%;" value="<%ar.writeHtml(parentTask);%>"/>
                </td>
            </tr>
            <tr><td>Action Scripts</td>
                <td class="Odd"><textarea name="ascripts" style="WIDTH:96%; HEIGHT:74px"><%
                    ar.writeHtml(aScripts);
                %></textarea></td>
            </tr>
            <tr>
                <td>Priority</td>
                <td class="Odd">
                    <select style="width:155px" name="priority" id="priority">
<%
    for (int i=1; i<=GoalRecord.MAX_TASK_PRIORITY; i++)
    {
        String selected = "";
        if (i==priority) {
            selected = "selected=\"selected\"";
        }
        ar.write("     <option " + selected + " value=\"" + i + "\" >" + i + "</option>");
    }
%>
                    </select>
                </td>
            </tr>
            <tr>
                <td>Due Date</td>
                <td class="Odd"><input type="text" name="dueDate" id="dueDate" size="20" value="<%SectionUtil.nicePrintDate(out, dueDate);%>" />
                </td>
            </tr>
            <tr>
                <td>Start Date</td>
                <td class="Odd"><input type="text" name="startDate" id="startDate" size="20" value="<%SectionUtil.nicePrintDate(out, startDate);%>" />
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
        if (i==duration) {
            selected = "selected=\"selected\"";
        }
        ar.write("     <option " + selected + " value=\"" + i + "\" >" + i + "</option>");
    }
%>
                    </select>
                </td>
            </tr>
            <tr>
                <td>End Date</td>
                <td class="Odd">
                    <input type="text" name="endDate" id="endDate" size="20" value="<% SectionUtil.nicePrintDate(out, endDate); %>"
                    onChange="calculateDuration()" />
                </td>
            </tr>
            <tr>
                <td>Rank</td>
                <td class="Odd">
                    <input type="text" name="rank" size="20" value="<% ar.write(Integer.toString(rank)); %>"/>
                </td>
            </tr>
            <tr>
                <td>Status</td>
                <td class="Odd"><input type="text" name="status" style="WIDTH: 96%;" value="<% ar.writeHtml(status); %>"/></td>
            </tr>
            <tr>
                <td>Accomplishment</td>
                <td class="Odd"><textarea name="accomp" style="WIDTH: 96%; HEIGHT:74px"></textarea></td>
             </tr>
        </table>
        <br/>

    </form>
    <br/>
    <br/>

<%

if (accomps != null)
{
%>

    <table width="80%" class="Design8">
        <col width="5%"/>
        <col width="95"/>
        <th align="left">No.</th>
        <th align="left">Previous Accomplishments (Top to Bottom order.)</th>
<%
        int i=0;
        for (HistoryRecord history : accomps)
        {
            String msg = history.getComments();
            if(msg==null || msg.length()==0)
            {
                msg=HistoryRecord.convertEventTypeToString(history.getEventType());
            }
            ar.write("<tr " + ((++i%2!=0)? "class=\"Odd\"" : " ") + ">");
            ar.write("<td>");
            ar.write(Integer.toString(i));
            ar.write(".</td><td>");
            SectionUtil.nicePrintTime(ar, history.getTimeStamp(), ar.nowTime);
            ar.write(" - ");
            ar.writeHtml(msg);
            ar.write("</td>");
            ar.write("</tr>");
        }
%>
    </tr>
</table>
<br/>

<%
}
%>

<script>
    var approveActBtn = new YAHOO.widget.Button("approveActBtn");
    var rejectActBtn = new YAHOO.widget.Button("rejectActBtn");
    var saveActBtn = new YAHOO.widget.Button("saveActBtn");
    var createSubPageActBtn = new YAHOO.widget.Button("createSubPageActBtn");
    var renumActBtn = new YAHOO.widget.Button("renumActBtn");
    var createSubTaskActBtn = new YAHOO.widget.Button("createSubTaskActBtn");
</script>

<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
