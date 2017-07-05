<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="java.util.Date"
%><%@page import="java.text.SimpleDateFormat"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%!
    String pageTitle = "";
%><%
/*
   Required parameters:

    1. pageId   : This is the id of an Workspace and here it is used to retrieve NGPage.
    2. taskId   : This parameter is id of a task and here it is used to get current task detail (GoalRecord)
                  and to pass current task id value when submitted.

*/
    if (!ar.isLoggedIn()) {
        throw new Exception("Program Logic Error: This view should be invoked ONLY when logged in.");
    }

    String pageId = ar.reqParam("pageId");
    String taskId = ar.reqParam("taskId");
    String ukey = ar.defParam("ukey", "XXX");
    UserProfile uProf = UserManager.getUserProfileByKey(ukey);

    NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);

    ar.setPageAccessLevels(ngp);
    pageTitle = ngp.getFullName();

    GoalRecord currentGoalRecord = ngp.getGoalOrFail(taskId);
    if (!currentGoalRecord.isPassive()) {
        throw new Exception("Program Logic Error: this view should only be invoked on passive action items");
    }
    NGRole assignees = currentGoalRecord.getAssigneeRole();
    boolean isAssignee = uProf!=null && assignees.isPlayer(uProf);
    int goalState = currentGoalRecord.getState();
    boolean canComplete = (goalState!=GoalRecord.STATE_COMPLETE) && isAssignee;
    List<HistoryRecord> histRecs = currentGoalRecord.getTaskHistory(ngp);
%>
<script src="<%=ar.baseURL%>jscript/jquery.dd.js" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" href="<%=ar.retPath%>css/dd.css" />
<style>
table.datatable {
    width:700px;
}
.datestyle {
    color: red;
}
.labelcolumn {
    width:90px;
    color:#888;
    font-weight:bold;
    text-align:right;
    height:30px;
}
.datacolumn {
    color:#000;
    height:30px;
    width:590px;
}
.buttoncolumn {
    color:#666;
    height:30px;
    padding:5px;
}
</style>
<body>
<script>
window.setMainPageTitle("Remote Action Item");
</script>
    <!-- Content Area Starts Here -->
    <div class="generalArea">
        <div class="pageHeading">
            <img src="<%=ar.retPath %><%=BaseRecord.stateImg(currentGoalRecord.getState())%>" />
            <span style="color:#5377ac"> <%=BaseRecord.stateName(currentGoalRecord.getState())%> Synopsis:</span>
            <%ar.writeHtml(currentGoalRecord.getSynopsis());%>
        </div>

        <div class="pageSubHeading">
            <table class="datatable">
                <tr>
                    <td class="labelcolumn">Assigned To:</td>
                    <td style="width:20px;"></td>
                    <td style="datacolumn">
                    <%
                        List<AddressListEntry> allUsers = currentGoalRecord.getAssigneeRole().getDirectPlayers();
                        boolean needComma = false;
                        for (AddressListEntry ale : allUsers)
                        {
                            if (needComma) {
                                %>, <%
                            }
                            %><span class="datestyle"><%
                            ale.writeLink(ar);
                            %></span><%
                            needComma = true;
                        }

                        %>&nbsp;&nbsp;&nbsp;&nbsp;<%

                        if(currentGoalRecord.getDueDate()!=0){
                            %> due date: <span class="datestyle"><%
                            ar.write(new SimpleDateFormat("MM/dd/yyyy").format(new Date(currentGoalRecord.getDueDate())));
                            %></span><%
                        }
                        if(currentGoalRecord.getStartDate()!=0){
                            %> start date: <span class="datestyle"><%
                            ar.write(new SimpleDateFormat("MM/dd/yyyy").format(new Date(currentGoalRecord.getStartDate())));
                            %></span><%
                        }
                        if(currentGoalRecord.getEndDate()!=0){
                            %> end date: <span class="datestyle"><%
                            ar.write(new SimpleDateFormat("MM/dd/yyyy").format(new Date(currentGoalRecord.getEndDate())));
                            %></span><%
                        }
                        %>
                    </td>
                </tr>
            </table>
        </div>
        <div >
            <table  class="datatable">
                <tr><td height="15px"></td></tr>
                <tr><td colspan="3">
                    <form action="<%=currentGoalRecord.getRemoteUpdateURL()%>" method="get">
                        <input type="submit" class="btn btn-primary btn-raised" name="op" value="Access Action Item on Remote Workspace">
                    </form>
                    </td>
                </tr>
                <tr><td height="15px"></td></tr>
                <tr>
                    <td class="labelcolumn">
                        Upstream:
                    </td>
                    <td style="width:20px;"></td>
                    <td class="datacolumn">
                        <a href="<%ar.writeHtml(currentGoalRecord.getRemoteProjectURL());%>">
                            <%ar.writeHtml(currentGoalRecord.getRemoteProjectName());%></a> on site
                        <a href="<%ar.writeHtml(currentGoalRecord.getRemoteSiteURL());%>">
                            <%ar.writeHtml(currentGoalRecord.getRemoteSiteName());%></a>
                    </td>
                </tr>
                <tr><td height="15px"></td></tr>
                <tr>
                    <td class="labelcolumn">
                        <fmt:message key="nugen.project.description.text"/>
                    </td>
                    <td style="width:20px;"></td>
                    <td class="datacolumn">
                        <%ar.writeHtmlWithLines(currentGoalRecord.getDescription());%>
                    </td>
                </tr>

                <tr><td height="10px"></td></tr>

                <tr>
                    <td class="labelcolumn"><fmt:message key="nugen.project.status.text"/></td>
                    <td style="width:20px;"></td>
                    <td class="datacolumn" style="width:20px;"><%ar.writeHtmlWithLines(currentGoalRecord.getStatus());%></td>
                </tr>

                <tr><td height="10px"></td></tr>
                <tr>
                    <td class="labelcolumn">Workspace:</td>
                    <td style="width:20px;"></td>
                    <td class="datacolumn" style="width:20px;"><%ar.writeHtml(ngp.getFullName());%></td>
                </tr>


<% if(currentGoalRecord.getDueDate()!=0){ %>
                <tr><td height="10px"></td></tr>
                <tr>
                    <td class="labelcolumn">Due Date:</td>
                    <td style="width:20px;"></td>
                    <td class="datacolumn" style="width:20px;"><%SectionUtil.nicePrintDate(ar.w, currentGoalRecord.getDueDate(),null);%></td>
                </tr>
<% } %>
                <tr><td height="20px"></td></tr>
<% if (uProf!=null) { %>
                <tr>
                    <td colspan="3">
                        <form action="updateGoalSpecial.form" method="post">
                        <input type="hidden" name="taskId" value="<%ar.writeHtml(taskId);%>">
                        <input type="hidden" name="ukey" value="<%ar.writeHtml(uProf.getKey());%>">
                        <input type="hidden" name="go" value="<%ar.writeHtml(ar.getCompleteURL());%>">
                        <table>
<% if (isAssignee) { %>
                            <tr><td class="buttoncolumn">
                                <input type="submit" name="cmd" value="Remove Me" class="btn btn-primary btn-raised"/>
                            </td><td class="buttoncolumn">
                                Unassign <%ar.writeHtml(uProf.getUniversalId());%> from this action item.
                                Use this if for any reason you do not plan to complete the action item,
                                and instead open it up for someone else to do.
                                You will stop getting reminders about it.
                            </td></tr>
<% } %>
<% if (canComplete) { %>
                            <tr><td class="buttoncolumn">
                                <input type="submit" name="cmd" value="Complete" class="btn btn-primary btn-raised"/>
                            </td><td class="buttoncolumn">
                                Mark this action item as completed so that everyone knows that the
                                action item has been accomplished.
                                You will stop getting reminders about it.
                            </td></tr>
<% } %>
                            <tr><td class="buttoncolumn">
                                <input type="submit" name="cmd" value="Other" class="btn btn-primary btn-raised"/>
                            </td><td class="buttoncolumn">
                                Log in in order to perform all other modification or updates
                                to this action item.
                            </td></tr>
                        </table>
                        </form>
                    </td>
                </tr>
                <tr><td height="30px"></td></tr>
<% } %>

            </table>
            <table class="datatable">
                <%
                if (histRecs.size()>0)
                {
                %>
                <tr>
                    <td colspan="3" class="generalHeading">Previous Accomplishments</td>
                </tr>
                <tr>
                    <td colspan="3" id="prevAccomplishments">
                        <table >
                            <tr><td style="height:10px"></td></tr>
                <%
                    int i=0;
                    for (HistoryRecord history : histRecs)
                    {
                        i++;
                        AddressListEntry ale = new AddressListEntry(history.getResponsible());
                        UserProfile responsible = ale.getUserProfile();
                        String photoSrc = ar.retPath+"assets/photoThumbnail.gif";
                        if(responsible!=null && responsible.getImage().length() > 0){
                            photoSrc = ar.retPath+"users/"+responsible.getImage();
                        }
                %>
                            <tr valign="top">
                                <td class="projectStreamIcons"><a href="#"><img src="<%=photoSrc%>" alt="" width="50" height="50" /></a></td>
                                <td colspan="2" class="projectStreamText">
                                    <%

                                    history.writeLocalizedHistoryMessage(ngp, ar);
                                    ar.write("<br/>");
                                    SectionUtil.nicePrintTime(out, history.getTimeStamp(), ar.nowTime);
                                    %>
                                </td>
                           </tr>
                           <tr><td style="height:10px"></td></tr>
                 <%
                    }
                 %>
                        </table>
                    </td>
                </tr>
            <%  } %>
            </table>
        </div>
    </div>
    </div>
</body>
