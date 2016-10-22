<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%/*
Required parameter:

    1. pageId   : This is the id of a Workspace and used to retrieve NGPage.
    2. task     : Task id which is used to get details of a assigned task (GoalRecord).

Optional Parameter:

    1. maxStr   : This is optional parameter used to set max

*/

    String pageId = ar.reqParam("pageId");
    String maxStr = ar.defParam("max", "1");

    GoalRecord task_assign = (GoalRecord)request.getAttribute("task");

    NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);

    int max = DOMFace.safeConvertInt(maxStr);
    if (max > 4) {
        max = 4;
    }
    if (max < 1) {
        max = 1;
    }

    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();
    UserProfile uProf = ar.getUserProfile();

    Map<Integer,String> priority=new HashMap<Integer,String>();
    priority.put(1, "Normal");
    priority.put(2, "Medium");
    priority.put(3, "High");

    String allTasksPage = ar.retPath + ar.getResourceURL(ngp,"projectAllTasks.htm");%>
<script type="text/javascript">
    var flag=false;
    var emailflag=false;
    var taskNameRequired = '<fmt:message key="nugen.process.taskname.required.error.text"/>';
    var taskName = '<fmt:message key="nugen.process.taskname.textbox.text"/>';
    var emailadd='<fmt:message key="nugen.process.emailaddress.textbox.text"/>'

    function clearField(elementName) {
        var task=document.getElementById(elementName).value;
        if(task==taskName){
            document.getElementById(elementName).value="";
            document.getElementById(elementName).style.color="black";
        }
    }

    function clearFieldAssignee(elementName) {
        var assigneeEmail=document.getElementById(elementName).value;
        if(emailadd==assigneeEmail){
            document.getElementById(elementName).value="";
            document.getElementById(elementName).style.color="black";
        }
    }

    function defaultTaskValue(elementName) {
        var task=document.getElementById(elementName).value;
        if(task==""){
            flag=false;
            document.getElementById(elementName).value=taskName;
            document.getElementById(elementName).style.color = "gray";
        }
    }

    function defaultAssigneeValue(elementName) {
        var assigneeEmail=document.getElementById(elementName).value;

        if(assigneeEmail==""){
            emailflag=false;
            document.getElementById(elementName).value=emailadd;
            document.getElementById(elementName).style.color="gray";
        }
    }

    function updateTaskVal(){
        flag=true;
    }
    function updateAssigneeVal(){
        emailflag=true;
    }



    function reAssignTask(assignee){
        var assignee = prompt ("Re enter assignee",assignee);
    }


    function onFormSubmit(){
        var value = document.getElementById("assignto").value;
        if(value != "" && value != '<fmt:message key="nugen.process.emailaddress.textbox.text"/>'){
            var result = breakMultipleEmailsBySeparators(value);
            return validateMultipleEmails(result);
        }
    }
</script>

<body class="yui-skin-sam">
    <div class="generalHeading"> Reassign an Action Item</div>
    <div class="generalContent">
        <!-- Tab Structure Starts Here -->
        <div id="container">
            <div class="content tab01">
                <form name="createTaskForm" action="reassignTaskSubmit.form" method="post" onsubmit="return onFormSubmit();">
                    <input type="hidden" name="taskid" value="<%ar.writeHtml(task_assign.getId());%>"/>
                    <input type="hidden" name="go" id="go" value="<%ar.writeHtml(allTasksPage); %>"/>
                    <table width="100%" border="0" cellpadding="0" cellspacing="0">
                        <tr>
                            <td width="100px;"><b><fmt:message key="nugen.process.taskname.display.text"/></b></td>
                            <td></td>
                            <td>
                            <% ar.writeHtml(task_assign.getSynopsis()); %>
                            </td>
                        </tr>
                        <tr><td>&nbsp;</td></tr>
                        <tr>
                            <td width="200px;"><b>Current Assignee</b></td>
                            <td></td>
                            <td><%  task_assign.writeUserLinks(ar);  %></td>
                        </tr>
                        <tr>
                            <td>&nbsp;</td>
                        </tr>
                        <tr>
                            <td><b>New Assignee</b></td>
                            <td></td>
                            <td><input type="text" class="wickEnabled" name="assignto" id="assignto"
                                 size="50" tabindex=2
                                 value='<fmt:message key="nugen.process.emailaddress.textbox.text"/>'
                                 onkeydown="updateAssigneeVal();"
                                 autocomplete="off" onkeyup="autoComplete(event,this);"
                                 onfocus="clearFieldAssignee('assignto');initsmartInputWindowVlaue('smartInputFloater','smartInputFloaterContent');"
                                 onblur="defaultAssigneeValue('assignto');"/>
                            &nbsp;<input type="submit" value="Reassign" class="btn btn-primary btn-raised" tabindex=3 /></td>
                        </tr>
                        <tr>
                            <td></td>
                            <td></td>
                            <td>
                                <div style="position:relative;text-align:left">
                                    <table  class="floater" style="position:absolute;top:0;left:0;background-color:#cecece;display:none;visibility:hidden"
                                            id="smartInputFloater"  rules="none" cellpadding="0" cellspacing="0">
                                        <tr>
                                            <td id="smartInputFloaterContent"  nowrap="nowrap" width="100%"></td>
                                        </tr>
                                    </table>
                                </div>
                            </td>
                        </tr>
                    </table>
                </form>
            </div>
        </div>
    </div>
    <script>
        function submitReassignForm(formObject){
            YAHOO.util.Connect.setForm(formObject);
            YAHOO.util.Connect.asyncRequest('POST', 'reassignTaskSubmit.form',formSubmitResp);
            YAHOO.util.Connect.resetFormState();
            return false;
        }

        var formSubmitResp ={
            success: function(o) {
                var respText = o.responseText;
                if(respText== "success"){
                    window.opener.location.reload();
                    window.close();
                }
                else{
                    alert('System has generated some error. Please try after some time.');
                }
            },
            failure: function(o) {
            alert("formSubmitResp Error:" +o.responseText);
            }
        }
    </script>
</body>