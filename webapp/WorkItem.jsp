<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.BaseRecord"
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
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.List"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%><%ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can not see the work item page");

    String p = ar.reqParam("p");
    String id  = ar.reqParam("id");

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ProcessRecord process = ngp.getProcess();
    ngb= ngp.getSite();
    uProf = ar.getUserProfile();

    String go = ar.defParam("go", null);
    if (go==null)
    {
        //if nothing else, come back to this page.
        go = ar.getCompleteURL();
    }

    GoalRecord task = ngp.getGoalOrFail(id);

    boolean isAssignee = false;
    boolean isClaimable = false;
    if (uProf!=null)
    {
        isAssignee = task.isAssignee(uProf);
    }
    pageTitle = "Activity on "+ngp.getFullName();
    String heading = "Activity Details";
    String assignPrompt = "Assigned to";
    int state = task.getState();
    boolean isReview = false;
    boolean isCompleted = false;
    switch (state)
    {
        case BaseRecord.STATE_ERROR:
            heading = "Interrupted Activity: ";
            break;
        case BaseRecord.STATE_UNSTARTED:
            heading = "Future Activity: ";
            isClaimable = true;
            break;
        case BaseRecord.STATE_OFFERED:
            heading = "Offered Activity: ";
            isClaimable = true;
            break;
        case BaseRecord.STATE_ACCEPTED:
            heading = "Accepted Activity: ";
            isClaimable = true;
            break;
        case BaseRecord.STATE_WAITING:
            heading = "Suspended (Waiting) Activity: ";
            break;
        case BaseRecord.STATE_COMPLETE:
            heading = "Completed Activity: ";
            assignPrompt = "Completed by";
            isCompleted = true;
            break;
        case BaseRecord.STATE_SKIPPED:
            heading = "Skipped Activity: ";
            break;
        default:
    }%>

<%@ include file="Header.jsp"%>


        <div class="pagenavigation">
            <div class="pagenav">

<h1><%ar.writeHtml(heading);%> <%ar.writeHtml(task.getSynopsis());%></h1>

<p></p>

<form action="WorkItemAction.jsp" method="post">
<input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
<table width="600">
<col width="130">
<col width="470">

<tr>
    <td>Subject:</td>
    <td><%ar.writeHtml(task.getSynopsis());%></td>
</tr>
<tr>
    <td>Description:</td>
    <td><%ar.writeHtml(task.getDescription());%></td>
</tr>


<input type="hidden" name="p"       value="<%ar.writeHtml(p);%>"/>
<input type="hidden" name="id"      value="<%ar.writeHtml(id);%>"/>
<input type="hidden" name="go"      value="<%ar.writeHtml(go);%>"/>
<tr>
  <td><%ar.writeHtml(assignPrompt);%>:</td>
  <td><%task.writeUserLinks(ar);%> (<%
    ar.writeHtml(task.getAssigneeCommaSeparatedList());
  %>)
<%
long dueDate = task.getDueDate();
if (!isAssignee && ar.isLoggedIn() && isClaimable)
{
%>
         &nbsp; &nbsp; <input type="checkbox" name="claim" value="yes">
        Claim Activity -- This activity is not assigned to you;
        check this box to assign this activity to yourself.
<%
}
%>
  </td>
</tr>
<tr>
  <td>Current State</td>
  <td><%ar.writeHtml(BaseRecord.stateName(state));%>
  [ <img align="absbottom" src = "<%=ar.retPath%><%=BaseRecord.stateImg(state)%>"> ] &nbsp; &nbsp;
  <a href="<%=ar.retPath%>EditTask.jsp?p=<%ar.writeURLData(p);%>&amp;id=<%ar.writeURLData(id);%>&amp;go=<%ar.writeURLData(go);%>">
          Edit Activity Details</a><% if(task.isPassive()) {%> (passive)<% } %></td>
</tr>
<%
String sub = task.getSub();
if (sub!=null && sub.length()>0)
{
    String subURL = task.getDisplayLink().trim();
    if (!subURL.startsWith("http") && false);
    {
        subURL = ar.retPath+subURL;
    }

%>
<tr>
    <td>Subprocess:</td>
    <td><a href="<%ar.writeHtml(subURL);%>" title="naviagate to the subprocess"><%ar.writeHtml(subURL);%></a></td>
</tr>
<%
}
if (isReview)
{
%>
<%
}

long completedDate = task.getEndDate();
if (isCompleted && completedDate!=0)
{

%>
    <tr><td>Completed</td>
        <td><%SectionUtil.nicePrintDate(out, completedDate);%></td>
    </tr>
<%
}

if (!isCompleted && dueDate!=0)
{
%>
    <tr><td>Due Date</td>
        <td><%SectionUtil.nicePrintDate(out, dueDate);%></td>
    </tr>
<%

}
%>
<tr>
    <td>Universal:</td>
    <td><%ar.writeHtml(task.getUniversalId());%></td>
</tr>
<tr><td colspan="2">&nbsp;</td></tr>
<tr><td>Remote UI</td>
    <td>
    <%=task.getRemoteUpdateURL()%>
    </td>
</tr>
<tr><td colspan="2"><hr/></td></tr>
<%

boolean showStartControl = false;
boolean showAcceptControl = false;
boolean showCompleteControl = false;
boolean showStatusControl = false;
boolean showSubtaskControl = false;
boolean showSubprojectControl = false;
boolean showReviewControl = false;

if (task.isPassive()) {
    //don't do the other things
}
else if (state==BaseRecord.STATE_UNSTARTED)
{
    showStartControl = false;
    showAcceptControl = true;
    showCompleteControl = true;
    showSubtaskControl = true;
    showSubprojectControl = true;
}
else if (state==BaseRecord.STATE_OFFERED)
{
    showAcceptControl = true;
    showCompleteControl = true;
    showStatusControl = true;
    showSubtaskControl = true;
    showSubprojectControl = true;
}
else if (state==BaseRecord.STATE_ACCEPTED)
{
    showCompleteControl = true;
    showStatusControl = true;
    showSubtaskControl = true;
    showSubprojectControl = true;
}
else if (state==BaseRecord.STATE_WAITING)
{
    showCompleteControl = true;
    showSubtaskControl = true;
}

if (showStartControl)
{
%>
    <tr><td colspan="2">&nbsp;</td></tr>
    <tr><td><input type="submit" id="startActBtn" name="action" value="Start Activity"/></td>
        <td>This activity is unstarted.  This option will start the activity,
        officially offering the action item to the assignees, and will make the
        action item appear on their current worklist.
        </td>
    </tr>
<%
}


if (showAcceptControl)
{
%>
    <tr><td colspan="2">&nbsp;</td></tr>
    <tr><td><input type="submit" id="acceptActBtn" name="action" value="Accept Activity"/></td>
        <td>
        <% if (isAssignee) { %>
        Use this option to accept the activity, confirming that you have
        see it and are planning to do it.
        <% } else { %>
        You are not assigned to this activity, but you can use this option
        if you know that the assignee has accepted the activity, or if you
        are claiming this activity as your own and want to accept it.
        <% } %>
        </td>
    </tr>
<%
}

if (showCompleteControl)
{
%>
    <tr><td colspan="2">&nbsp;</td></tr>
    <tr><td><input type="submit" id="completeActBtn" name="action" value="Complete Activity"/></td>
        <td>In some cases an activity is already completed before it is marked
            as started.  Use this option to indicate that the activity is
            already completed, and to move the process to the next step.
        </td>
    </tr>
<%
}

if (showStatusControl)
{
%>
    <tr><td colspan="2">&nbsp;</td></tr>
    <tr><td></td>
        <td>If the action item is not yet completed, you can update the status below:
        </td>
    </tr>
    <tr><td><input type="submit" id="updateStatusActBtn" name="action" value="Update Status"/></td>
        <td><textarea name="status" cols="80" rows="3"><%ar.writeHtml(task.getStatus());%></textarea>
        </td>
    </tr>
    <tr><td colspan="2">&nbsp;</td></tr>
    <tr><td></td>
        <td><input type="checkbox" name="addAcc"> Add Accomplishment: Record progress on this Activity below.
        </td>
    </tr>
    <tr><td></td>
        <td><textarea name="accomp" cols="80" rows="3"></textarea>
        </td>
    </tr>
<%
}

if (showSubtaskControl)
{
%>
    <tr><td colspan="2">&nbsp;</td></tr>
    <tr><td><input type="submit" id="createSubTaskActBtn" name="action" value="Create SubTask"/></td>
        <td>Use this option to create a sub action item for the purpose of
            completing this action item.  The sub action item will be connected
            to this action item, and will be completed when the sub action item
            is completed.
        </td>
    </tr>
<%
}

if (showSubprojectControl)
{
%>
    <tr><td colspan="2">&nbsp;</td></tr>
    <tr><td><input type="submit" id="createSubLeafActBtn" name="action" value="Create Subleaf"/></td>
        <td>Use this option to create a subproject for the purpose of
            completing this activity.  The subproject will be connected
            to this activity, and will be completed when the subproject
            process is completed.
        </td>
    </tr>
<%
}

if (task.isPassive()) {
%>
    <tr><td colspan="2">&nbsp;</td></tr>
    <tr><td></td>
        <td>This is a passive action item which means that it was not created in this copy
        of the project folder, and was replicated from another folder.
        The action item can only be manipulated by accessing the original server that it was
        creatd on.
        <br/><br/>
        <a href="<%=task.getRemoteUpdateURL()%>">Visit Site of Action Item<a/>
        </td>
    </tr>
<%

}







if (showReviewControl)
{
%>
    <tr><td colspan="2">&nbsp;</td></tr>
    <tr><td><input type="submit" id="approveActBtn" name="action" value="Approve"/></td>
        <td>Mark that you have reviewed the activity and approve for further distribution.
        </td>
    </tr>
    <tr><td colspan="2">&nbsp;</td></tr>
    <tr><td><input type="submit" id="rejectActBtn" name="action" value="Reject"/></td>
        <td>Mark that you do not approve this, and send the action item back to the
            assignee for further work.
        </td>
    </tr>
    <tr><td>Reason</td>
        <td><textarea name="reason" cols="80" rows="3"></textarea>
        </td>
    </tr>
    <tr><td colspan="2">&nbsp;</td></tr>
<%
}

if (state==BaseRecord.STATE_DELETED)
{
    String mpkey = task.getMovedToProjectKey();
    String mtid = task.getMovedToTaskId();

    if (mpkey!=null && mtid!=null) {

        NGPage oProj = ar.getCogInstance().getProjectByKeyOrFail(mpkey);

        %>
        <tr><td>Deleted & Moved:</td>
            <td>This action item has been moved to project:  <%oProj.writeContainerLink(ar, 40);%>
            </td>
        </tr>
        <%
    }
}

List<HistoryRecord> histRecs = task.getTaskHistory(ngp);
if (histRecs.size()>0)
{
%>
<tr><td colspan="2">
    <h3>Accomplishments to date</h3>
    <ul>
        <%
        for (HistoryRecord history : histRecs)
        {
            String msg = history.getComments();
            if(msg==null || msg.length()==0)
            {
                msg=HistoryRecord.convertEventTypeToString(history.getEventType());
            }
            %><li><%SectionUtil.nicePrintTime(ar, history.getTimeStamp(), ar.nowTime);%> -
                  <%ar.writeHtml(msg);%>
              </li><%
        }
        %>
    </ul>
    </td>
</tr>
<%
}
%>
<tr><td colspan="2">&nbsp;</td></tr>
<tr><td colspan="2"><hr/></td></tr>
</table>

<script>
    var startActBtn = new YAHOO.widget.Button("startActBtn");
    var acceptActBtn = new YAHOO.widget.Button("acceptActBtn");
    var completeActBtn = new YAHOO.widget.Button("completeActBtn");
    var createSubLeafActBtn = new YAHOO.widget.Button("createSubLeafActBtn");
    var createSubTaskActBtn = new YAHOO.widget.Button("createSubTaskActBtn");
    var approveActBtn = new YAHOO.widget.Button("approveActBtn");
    var rejectActBtn = new YAHOO.widget.Button("rejectActBtn");
    var updateStatusActBtn = new YAHOO.widget.Button("updateStatusActBtn");

</script>
</form>

<!--  -->

            </div>
            <div class="pagenav_bottom"></div>
        </div>
        <%
        out.flush();

%>
<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
