<%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%@page import="java.util.StringTokenizer"
%><%@page import="java.util.Calendar"
%><%@page import="java.text.DateFormat"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%!

/*
Required Parameters:

    subprocess  : This request attribute is used to check if process is subprocess or parent-process.
    pageId      : This is the id of Project which is used to get details of Project.
    TypeOfGoalPage :  provides the title
*/

    String pageTitle = "";
    boolean displayMyTask;
    UserProfile uProf=null;

%><%
    String subprocess  = ar.defParam("subprocess", "true");
    String pageId      = ar.reqParam("pageId");

    String typeOfGoalPage = (String) request.getAttribute("TypeOfGoalPage");
    uProf = ar.getUserProfile();

    String cpath = request.getContextPath();
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();
    pageTitle = typeOfGoalPage;
    List<GoalRecord> taskList = ngp.getAllGoals();

    //Declaration  for Status report page
    ar.setPageAccessLevels(ngp);
    UserProfile uProf = ar.getUserProfile();
    String thisPageAddress = ar.getResourceURL(ngp,"projectActiveTasks.htm");
    int max=4;

    String startDate = ar.defParam("startDate", "");
    String endDate = ar.defParam("endDate", "");

    DateFormat formatter = new SimpleDateFormat("MM/dd/yyyy");  ;
    Date date;
    /*
    Calendar calendar = Calendar.getInstance();

    if(endDate.equals(null) || endDate.equals("")){
        endDate=String.valueOf(ar.nowTime);

    }else{
       date=(Date) formatter.parse(endDate);
       calendar.setTime(date);
       // Substract 23 hour from the current time
       calendar.add(Calendar.HOUR, 23);

       // Add 59 minutes to the calendar time
       calendar.add(Calendar.MINUTE, 59);

       // Add 59 seconds to the calendar time
       calendar.add(Calendar.SECOND, 59);

       endDate =String.valueOf((calendar.getTime().getTime()));
       //endDate =String.valueOf(date.getTime());
    }
    */

    if(startDate.equals(null) || startDate.equals("")){
        long startTime = ar.nowTime - (((long)7) * 24 * 60 * 60 * 1000);
        startDate=String.valueOf(startTime);

    }else{
          date=(Date) formatter.parse(startDate);
          startDate=String.valueOf((date.getTime()) );
    }

    long endTime = DOMFace.safeConvertLong(endDate);
    long startTime = DOMFace.safeConvertLong(startDate);


    //Declearation for Status report End%>

<style type="text/css" media="all">
<!--
    .hiddenlink {
        display: none;
        text-decoration: none; /* to remove the underline */
-->
</style>

<!-- D&D Tree View BEGIN -->

<script type="text/javascript" src="<%=ar.baseURL%>jscript/jquery.ui.js"></script>
<script type="text/javascript" src="<%=ar.baseURL%>jscript/jquery-plugin-treeview.js"></script>

<link rel="stylesheet" href="<%=ar.baseURL%>css/jquery.treeview.css" type="text/css" />

<!-- D&D Tree View END-->



<script type="text/javascript">
    var isfreezed = '<%=ngp.isFrozen() %>';
    var buttonIndex;
    var flag=false;
    var emailflag=false;
    var taskNameRequired = '<fmt:message key="nugen.process.taskname.required.error.text"/>';
    var taskName = '<fmt:message key="nugen.process.taskname.textbox.text"/>';
    var emailadd='<fmt:message key="nugen.process.emailaddress.textbox.text"/>'

    var specialSubTab = '<fmt:message key="${requestScope.subTabId}"/>';

    var tab0_projectTasks = '<fmt:message key="nugen.projecttasks.subtab.active.tasks"/>';
    var tab1_projectTasks = '<fmt:message key="nugen.projecttasks.subtab.completed.tasks"/>';
    var tab2_projectTasks = '<fmt:message key="nugen.projecttasks.subtab.future.tasks"/>';
    var tab3_projectTasks = '<fmt:message key="nugen.projecttasks.subtab.all.tasks"/>';
    var tab4_projectTasks = '<fmt:message key="nugen.projecttasks.subtab.status.report"/>';


    function clearField(elementName) {
        var task=document.getElementById(elementName).value;
        if(task==taskName){
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



    function updateTaskVal(){
        flag=true;
    }

    function updateAssigneeVal(){
        emailflag=true;
    }

    function submitTask(){
        var taskname =  document.getElementById("taskname");
        var assignto =  document.getElementById("assignto");
        var dueDate =  document.getElementById("dueDate");
        if(!(flag && !taskname.value=='' || !taskname.value==null)){
            alert(taskNameRequired);
                return false;
        }

        if(assignto.value==emailadd){
            document.getElementById("assignto").value="";
        }
        document.forms["createTaskForm"].submit();
    }


    function reAssignTask(assignee){
        var assignee = prompt ("Re enter assignee",assignee);
    }

    function createSubTask(id,pageId,bookId){
        if(isfreezed == 'false'){
            window.open('subtask.htm?taskId='+id ,TARGET="_parent")
        }else{
            return openFreezeMessagePopup();
        }
    }

    function userProfile(url)
    {
        var uri='<%=ar.retPath%>'+"v/"+url+"/userProfile.htm?active=1";
        window.open(uri,TARGET="_parent");
    }

    function goToProject(url)
    {
        var uri='<%=ar.retPath%>'+url;
        window.open(uri,TARGET="_parent");
    }

    function openFreezePopup(msg){
            var popup_title = "Project Frozen";
            var popup_body = '<div class="generalArea">'+
                '<div class="generalContent" align="center">'+
                    msg+
                    '<br>'+
                    '<br>'+
                    '<input type="button" class="btn btn-primary"  value="Ok" onclick="cancelPanel()" >'+
                '</div>'+
            '</div>';
            createPanel(popup_title,popup_body, (popup_title.length+popup_body.length+350)+'px');
            return false;
        }

    function alertselected(selectobj){
        window.open('subprocess.htm?subprocess='+selectobj.value ,TARGET="_parent");
    }

    function makeAjaxProcessCall(){
        if(isfreezed == 'false'){
            var accIdProjId = document.getElementById("projectNames").value;
            if(accIdProjId.length>0){
                var transaction = YAHOO.util.Connect.asyncRequest('POST', "<%=ar.retPath%>t/subProcess.ajax?processURL=local:"+accIdProjId, callbackprocess);
            }else {
                submitTask();
            }
        }else{
            return openFreezeMessagePopup();
        }
    }

    var callbackprocess = {
           success: function(o) {
               var respText = o.responseText;
               var json = eval('(' + respText+')');
               if(json.msgType == "success_local"){
                   if(json.Local_Process != "No project found"){
                        document.getElementById('processLink').value = json.Local_Project;
                        submitTask();
                   }else if(json.Local_Process == "No project found"){
                       showErrorMessage("Result", json.msg , json.comments );
                   }
               }else{
                   showErrorMessage("Result", json.msg , json.comments );
              }
           },
           failure: function(o) {
                   alert("callbackprocess Error:" +o.responseText);
           }
    }

    function searchProjectNames(){
        var matchkey = document.getElementById('projectName').value;
        if(matchkey.length >3){
        removeAllOptions(document.createTaskForm.projectNames);
        var bookKey = '<%= ngb.getKey() %>';
        var postURL = "<%=request.getContextPath()%>/t/getProjectNames.ajax?book="+bookKey+"&matchkey="+matchkey;
        var transaction = YAHOO.util.Connect.asyncRequest('POST', postURL, searchProjectNamesResult);
        }
    }
    var searchProjectNamesResult = {
            success: function(o) {
                var respText = o.responseText;

                var json = eval('(' + respText+')');
                if(json.msgType == "success"){
                    var name_value_pair = json.msg.split(",");
                    for (var i=0; i < name_value_pair.length;i++){
                        var respArrayKeyValue = name_value_pair[i].split(":");
                        addOption(document.createTaskForm.projectNames, respArrayKeyValue[0], respArrayKeyValue[1]);
                    }
                }else{
                    showErrorMessage("Result", json.msg , json.comments );
                }
            },
            failure: function(o) {
                    alert("searchProjectNamesResult Error:" +o.responseText);
            }
        }
    function addOption(selectbox,text,value )
    {
        var optn = document.createElement("OPTION");
        optn.text = text;
        optn.value = value;
        selectbox.options.add(optn);
    }

    function removeAllOptions(selectbox)
    {
        var i;
        for(i=selectbox.options.length-1;i>=0;i--)
        {
            selectbox.remove(i);
        }
    }


    $(document).ready(function(){
        $("#ActiveTask").treeview({
            collapsed: true
        })

          $("#CompletedTask").treeview({
            collapsed: true
        })
          $("#FutureTask").treeview({
            collapsed: true
        })
          $("#AllTask").treeview({
            collapsed: true
        })

    });

    $(function() {
        $( "#ActiveTask" ).sortable();
        $( "#ActiveTask" ).disableSelection();

        $( "#CompletedTask" ).sortable();
        $( "#CompletedTask" ).disableSelection();

        $( "#FutureTask" ).sortable();
        $( "#FutureTask" ).disableSelection();

        $( "#AllTask" ).sortable();
        $( "#AllTask" ).disableSelection();


    });

    function showhide(id){
    if(document.getElementById(id).style.display == "none")
        {
         document.getElementById(id).style.display = "";
        }
        else
        {
         document.getElementById(id).style.display = "none";
        }
    }



     function getNodeOrders(id){
            this.idOfTree=id;
            var saveString = '';
            var initObj = document.getElementById(this.idOfTree);


            var lis = initObj.getElementsByTagName('LI');

            if(lis.length>0){

                var li = lis[0];

                while(li){
                    if(li.id){

                        if(saveString.length>0)saveString = saveString + ',';
                        var numericID = li.id.replace(/[^0-9]/gi,'');
                        if(numericID.length==0)numericID='A';
                        var numericParentID = li.parentNode.parentNode.id.replace(/[^0-9]/gi,'');


                        if(numericID!='0'){
                            saveString = saveString + numericID;
                            //saveString = saveString + '-';


                            if(li.parentNode.id!=this.idOfTree)saveString = saveString + numericParentID; else saveString = saveString ;
                        }

                        /*var ul = li.getElementsByTagName('UL');
                        if(ul.length>0){
                            saveString = this.getNodeOrders(ul[0],saveString);
                        }   */
                    }
                    li = li.nextSibling;
                }
            }

            if(initObj.id == this.idOfTree){
                return saveString;

            }

            return saveString;
        }
  function showHideReOrder(value){
    if (document.getElementById){
        obj = document.getElementById(buttonIndex);
        obj.style.display = value;
    }
}

function buttononIndex(index){
    buttonIndex="orderIndex"+index;
}

function generateReoprt(){
     document.forms["statusReport"].submit();
 }

 function checkFreezed(){
        if(isfreezed == 'false'){
            return true;
        }else{
            return openFreezeMessagePopup();
        }
    }
</script>


<body class="yui-skin-sam">

    <%
    if (!ar.isLoggedIn()) {
    %>
    <div class="generalArea">
        <div class="generalContent">In order to see the process section of
        the project, you need to be logged in, and you need to be an member of
        the project.</div>
    </div>
    <%
    } else {
    %>

    <!-- Content Area Starts Here -->
    <div class="generalArea">
        <div class="pageHeading"><%=typeOfGoalPage%></div>
        <div class="pageSubHeading">
            <table width="100%">
                <tr>
                    <td>You can create and reassign goals & subgoals of the project.</td>
                    <td></td>
                    <td align="right">
                        <img src="<%=ar.retPath %>/assets/iconCSV.gif" style="cursor:pointer;" title="Export to Spreadsheet"/>
                        <a href="tasks.csv">Export to Spreadsheet</a>
                    </td>
                </tr>
            </table>
        </div>
        <div class="generalContent">

            <form name="createTaskForm" action="CreateTask.form" method="post" autocomplete="off" onsubmit="return checkFreezed();">
                <table class="popups">
                    <tr><td height="30px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2 bigHeading">Create New Goal:</td>
                        <td style="width:20px;"></td>
                        <td>
                            <table cellpadding="0" cellspacing="0">
                                <tr>
                                    <td class="createInput" style="padding:0px;">
                                        <input type="text" class="inputCreateButton" name="taskname" id="taskname" value ='<fmt:message key="nugen.process.taskname.textbox.text"/>' onKeyup="updateTaskVal();" onfocus="clearField('taskname');" onblur="defaultTaskValue('taskname');" onclick="expandDiv('assignTask')" />
                                    </td>
                                    <td class="createButton" onclick="makeAjaxProcessCall();">&nbsp;</td>
                                </tr>
                            </table>
                        </td>
                     </tr>
                     <tr>
                        <td colspan="3">
                            <table id="assignTask" style="display:none">
                                <tr><td width="148" class="gridTableColummHeader_2" style="height:20px"></td></tr>
                                <tr>
                                    <td width="148" class="gridTableColummHeader_2"><fmt:message key="nugen.process.assignto.text"/></td>
                                    <td width="39" style="width:20px;"></td>
                                    <td><input type="text" class="wickEnabled" name="assignto" id="assignto" size="69" style="height:20px" value='<fmt:message key="nugen.process.emailaddress.textbox.text"/>' onkeydown="updateAssigneeVal();" autocomplete="off" onkeyup="autoComplete(event,this);"  onfocus="clearFieldAssignee('assignto'); initsmartInputWindowVlaue('smartInputFloater','smartInputFloaterContent');" onblur="defaultAssigneeValue('assignto');"/>
                                        <div style="position:relative;text-align:left">
                                            <table  class="floater" style="position:absolute;top:0;left:0;background-color:#cecece;display:none;visibility:hidden;width:397px"  id="smartInputFloater"  rules="none" cellpadding="0" cellspacing="0">
                                            <tr><td id="smartInputFloaterContent"  nowrap="nowrap" width="100%"></td></tr>
                                            </table>
                                        </div>
                                    </td>
                                 </tr>
                                <tr><td style="height:15px"></td></tr>
                                <tr>
                                    <td class="gridTableColummHeader_2" style="vertical-align:top"><fmt:message key="nugen.project.desc.text"/></td>
                                    <td style="width:20px;"></td>
                                    <td><textarea name="description" id="description" class="textAreaGeneral" rows="4" tabindex=7></textarea></td>
                                </tr>
                                <tr><td style="height:20px"></td></tr>
                                <tr>
                                    <td width="148" class="gridTableColummHeader_2"><fmt:message key="nugen.process.priority.text"/></td>
                                    <td width="39" style="width:20px;"></td>
                                    <td><select name="priority" class="selectGeneral" tabindex=5>
                                        <option value ="0"><%=BaseRecord.getPriorityStr(0)%></option>
                                        <option selected="selected" value="1"><%=BaseRecord.getPriorityStr(1)%></option>
                                        <option value="2"><%=BaseRecord.getPriorityStr(2)%></option>
                                        </select>
                                    </td>
                                </tr>
                                <tr><td style="height:10px"></td></tr>
                                <tr>
                                    <td width="148" class="gridTableColummHeader_2"><fmt:message key="nugen.project.duedate.text"/></td>
                                    <td width="39" style="width:20px;"></td>
                                    <td><input type="text" class="inputGeneralSmall" style="width:368px" size="50" name="dueDate" id="dueDate"  value="" />
                                    </td>
                                </tr>
                                <tr><td style="height:20px"></td></tr>
                                <tr>
                                    <td width="148" class="gridTableColummHeader_2">(Optional)</td>
                                    <td width="39" style="width:20px;"></td>
                                    <td><img src="<%=ar.retPath %>/assets/goalstate/small1.gif" alt="accepted"/>
                                    <b><input type="checkbox" name="startActivity" id="startActivity" checked="checked" onclick="return selectAll('public')" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Start & Offer the Activity </b>
                                    </td>
                                </tr>
                               <tr><td style="height:20px"></td></tr>
                               <tr>
                                    <td width="148" class="gridTableColummHeader_2">Link to Other Project:</td>
                                    <td width="39" style="width:20px;"></td>
                                    <td>
                                        <input type="text" name="projectName" id="projectName" tabindex=2   value='' class="inputGeneral" onkeyup="searchProjectNames();"/>
                                        <input type="hidden" name="processLink" id="processLink" value="">
                                    </td>
                                </tr>
                                <tr><td style="height:15px"></td></tr>
                                <tr>
                                    <td width="148" class="gridTableColummHeader_2">Select Project:</td>
                                    <td width="39" style="width:20px;"></td>
                                    <td><select class="selectGeneral" tabindex=5 id="projectNames"></select>
                                    </td>
                                </tr>
                                <tr><td style="height:15px"></td></tr>
                            </table>
                        </td>
                     </tr>
                     <tr>
                        <td width="148" class="gridTableColummHeader_2"></td>
                        <td width="39" style="width:20px;"></td>
                        <td style="cursor:pointer">
                            <span id="showDiv" style="display:inline" onclick="setVisibility('assignTask')"><img src="<%=ar.retPath %>/assets/createSeperatorDown.gif" width="398" height="13" title="Expand" alt="" /></span>
                            <span id="hideDiv" style="display:none" onclick="setVisibility('assignTask')"><img src="<%=ar.retPath %>/assets/createSeperatorUp.gif" width="398" height="13" title="Collapse" alt="" /></span>
                        </td>
                     </tr>
                </table>
            </form>
        </div>
    </div>
    <body class="yui-skin-sam">
    <!-- for the tab view -->
    <div id="container">
        <ul id="subTabs" class="menu">

        </ul>
    </div>
<%
    }

    %>

</body>
<script>
    function openReassignWindow(taskid,pageId,bookId){
        if(isfreezed == 'false'){
            window.open('reassignTask.htm?taskid='+taskid ,TARGET="_parent");
        }else{
            openFreezeMessagePopup();
        }
    }

    function updateStatusAjaxCall(id,pageId,bookId,action,index){
        if(isfreezed == 'false'){
            var transaction = YAHOO.util.Connect.asyncRequest('POST',"updateTaskStatus.ajax?id="+id+"&pId="+pageId+"&bId="+bookId+"&action="+action+"&index="+index, updatedStatus);
            return false;
        }else{
            openFreezeMessagePopup();
        }
    }

    var updatedStatus = {
        success: function(o) {
            var respText = o.responseText;

            var json = eval('(' + respText+')');

            if(json.msgType != "success"){
                alert(json.comments);
                showErrorMessage("Unable to Perform Action", json.msg , json.comments );
                return false;
            }
            if(json.taskId == "" ){
                window.location.reload();
                return false;
            }

            var taskId = json.taskId;
            var index=json.index;
            var status = json.taskState;
            var taskImageElement = document.getElementById(taskId+"_stimg");
            taskImageElement.src= "<%=ar.retPath%>assets/goalstate/small"+status+".gif";

            var startActBtn = document.getElementById(taskId+'_startActBtn');
            var acceptActBtn = document.getElementById(taskId+'_acceptActBtn');
            var completeActBtn = document.getElementById(taskId+'_completeActBtn');
            var rejectActBtn = document.getElementById(taskId+'_rejectActBtn');
            var approveActBtn = document.getElementById(taskId+'_approveActBtn');


            if(status == '<%=BaseRecord.STATE_UNSTARTED%>'){
                startActBtn.setAttribute("class", "");
                acceptActBtn.setAttribute("class", "");
                completeActBtn.setAttribute("class","");
                rejectActBtn.setAttribute("class", "hiddenlink");
                approveActBtn.setAttribute("class", "hiddenlink");
            }
            else if(status == '<%=BaseRecord.STATE_STARTED%>'){
                startActBtn.setAttribute("class", "hiddenlink");
                acceptActBtn.setAttribute("class", "");
                completeActBtn.setAttribute("class","");
                rejectActBtn.setAttribute("class", "hiddenlink");
                approveActBtn.setAttribute("class", "hiddenlink");
            }
            else if(status == '<%=BaseRecord.STATE_ACCEPTED%>'){
                startActBtn.setAttribute("class", "hiddenlink");
                acceptActBtn.setAttribute("class", "hiddenlink");
                completeActBtn.setAttribute("class","");
                rejectActBtn.setAttribute("class", "hiddenlink");
                approveActBtn.setAttribute("class", "hiddenlink");
            }
            else if(status == '<%=BaseRecord.STATE_COMPLETE%>'){
                startActBtn.setAttribute("class", "");
                acceptActBtn.setAttribute("class", "hiddenlink");
                completeActBtn.setAttribute("class","hiddenlink");
                rejectActBtn.setAttribute("class", "");
                approveActBtn.setAttribute("class", "");
            }
            else if(status == '<%=BaseRecord.STATE_WAITING%>'){
                startActBtn.setAttribute("class", "hiddenlink");
                acceptActBtn.setAttribute("class", "hiddenlink");
                completeActBtn.setAttribute("class","");
                rejectActBtn.setAttribute("class", "hiddenlink");
                approveActBtn.setAttribute("class", "hiddenlink");
            }

            return false;
        },
        failure: function(o) {
            alert("updatedStatus Error:" +o.responseText);
        }
    }
</script>
<script type="text/javascript">


function reOrderIndex(id){
      showHideReOrder("none");
      var indexString = getNodeOrders(id);
      var pageId='<%=pageId%>';
      var bookKey = '<%= ngb.getKey() %>';
      var servletURL = '<%=ar.retPath%>'+"t/"+bookKey+"/"+pageId+"/setOrderTasks.ajax?indexString="+indexString;
      YAHOO.util.Connect.asyncRequest("POST",servletURL, connectionCallback);

      var connectionCallback =  {
        success: function(o) {
           var respText = o.responseText;
           var json = eval('(' + respText+')');
             if(json.msgType == "success_local"){
             alert(respText);
             }
       },
       failure: function(o) {
               alert("setReOrderTasks.ajax Error:" +o.responseText+" unable to update data.");
       }
    }

    }
</script>


<%!private String getHeadingForState(int state)
    {
        switch (state)
        {
        case BaseRecord.STATE_ERROR:
            return "Interrupted Activity: ";
        case BaseRecord.STATE_UNSTARTED:
            return "Future Activity: ";
        case BaseRecord.STATE_STARTED:
            return "Offered Activity: ";
        case BaseRecord.STATE_ACCEPTED:
            return "Accepted Activity: ";
        case BaseRecord.STATE_WAITING:
            return "Suspended (Waiting) Activity: ";
        case BaseRecord.STATE_COMPLETE:
            return "Completed Activity: ";
        case BaseRecord.STATE_SKIPPED:
            return "Skipped Activity: ";
        default:
            return "Unspecified State";
        }

    }


    public void outputTaskX(AuthRequest ar, GoalRecord task ,NGPage ngp,
            String subprocess, int tabIndex, List<GoalRecord> taskList,
            boolean root,      int index,    boolean noDrag)
    throws Exception {


        int state = task.getState();
        String heading = getHeadingForState(state);
        String assignPrompt = "Assigned to";
        boolean isAssignee = false;
        boolean isClaimable = false;
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
        case BaseRecord.STATE_STARTED:
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
        }


        ar.write("\n<li id=\"node");
        ar.write(task.getId());
        ar.write("\" class=\"ui-state-default\">");
        ar.write("&nbsp;");

        writeTaskStateIcon(ar, task);

        ar.write("\n <span class=\"taskHeading\" title=\"Click here to see details\" onclick=\"showhide(\'");
        ar.write(task.getId());
        ar.write("_");
        ar.write(Integer.toString(index));
        ar.write("\')\">");
        ar.writeHtml(task.getSynopsis());

        ar.write("</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");


        String isSubProcess = task.getSub();
        if((isSubProcess.length() != 0) ){

            String pageidValue = getKeyFromURL(isSubProcess);
            if (pageidValue==null)
            {
                throw new ProgramLogicError("pageid is null for sub="+isSubProcess);
            }

            NGPageIndex isSubpage = ar.getCogInstance().getContainerIndexByKey(pageidValue);
            if (isSubpage!=null){
                NGPageIndex ngpIndex = ar.getCogInstance().getContainerIndexByKey(isSubpage.getPage().getKey());
                String projectUrl = ar.getResourceURL(ngpIndex, "history.htm");
                ar.write("\n    <img src=\"");
                ar.writeHtml(ar.retPath);
                ar.write("assets/images/leaf.gif\">\n    <span>");

                ar.write("\n    &nbsp;<a href=\"");
                ar.writeHtml(ar.retPath);
                ar.writeHtml(projectUrl);
                ar.write("\" onclick=\"javascript:goToProject('");
                ar.writeHtml(projectUrl);
                ar.write("');\">");
                ar.writeHtml(ngpIndex.containerName);
                ar.write("</a>");

                ar.write("\n    </span>");
            }
        }

        ar.write("\n <div class=\"taskOverview\">assigned to: ");
        writeAssignees(ar, task, ngp);

        if (task.getDueDate()>0) {
            ar.write("\ndue date:");
            ar.write("  <span style=\"color:red\">");
            ar.write(new SimpleDateFormat("MM/dd/yyyy").format(new Date(task.getDueDate())));
            ar.write("</span>");
        }
        if (task.getEndDate()>0) {
            ar.write("\nend date:");
            ar.write("  <span style=\"color:red\">");
            ar.write(new SimpleDateFormat("MM/dd/yyyy").format(new Date(task.getEndDate())));
            ar.write("</span>");
        }

        int priorVal = task.getPriority();
        if (priorVal != 1) {
            ar.write("\npriority:");
            ar.write("  <span style=\"color:red\">");
            ar.writeHtml(BaseRecord.getPriorityStr(priorVal));
            ar.write("</span>");
        }

        ar.write("\n</div>");

        ar.write("\n <div class=\"taskDescription\" style=\"display:none\" id=\"");

        ar.write(task.getId()+"_"+index +"\">");
        ar.writeHtmlWithLines(task.getDescription());

        ar.write("\n<div class=\"taskStatus\">");

        ar.write("<b>Status:</b>&nbsp;");
        ar.writeHtmlWithLines(task.getStatus());
        ar.write(" </div>");

        ar.write("\n<div class=\"taskToolBar\">");
        if (task.isPassive()) {
            ar.write("This goal is not defined on this server.  Access the <a href=\""+task.getRemoteUpdateURL()+"\">Updatable Goal Page</a>.");
        }
        else {
            ar.write("<img src=\"");
            ar.writeHtml(ar.retPath);
            ar.write("/assets/iconEdit.gif\" alt=\"Edit\" />  ");
            ar.write("\n    <a href=\"task");
            ar.write(task.getId());
            ar.write(".htm\"><b>Details</b></a>&nbsp;&nbsp;&nbsp;&nbsp;<img src=\"");
            ar.writeHtml(ar.retPath);
            ar.write("assets/iconReassign.gif\" width=\"15\" height=\"15\" alt=\"Reassign\"  />  ");

            ar.write("\n    <a href=\"#\"");
            ar.write(" onclick=\"openReassignWindow(\'");
            ar.writeHtml(task.getId());
            ar.write("\',\'");
            ar.writeHtml(ngp.getKey());
            ar.write("\',\'");
            ar.writeHtml(ngp.getSite().getKey());
            ar.write("\');\" title=\"View details and modify activity state\">");

            ar.write("<b>Reassign</b>");
            ar.write("</a>");

            ar.write("&nbsp;&nbsp;&nbsp;&nbsp;<img src=\"");
            ar.writeHtml(ar.retPath);
            ar.write("/assets/iconAddSubtask.gif\" alt=\"Add Subtask\"  />  \n<a href=\"#\"");

            ar.write(" onclick=\"createSubTask('");
            ar.writeHtml(task.getId());
            ar.write("\',\'");
            ar.writeHtml(ngp.getKey());
            ar.write("\',\'");
            ar.writeHtml(ngp.getSite().getKey());

            ar.write("')\"");
            ar.write(">");
            ar.write("<b>Add Subtask</b>");
            ar.write("</a>");

            /*Started editing for links like accept and reject*/
            ar.write("\n<a id =\"");
            ar.writeHtml(task.getId());
            ar.write("_startActBtn\" href=\"#\"");
            ar.write(" onclick=\"return updateStatusAjaxCall(\'");
            ar.writeHtml(task.getId());
            ar.write("\',\'");
            ar.writeHtml(ngp.getKey());
            ar.write("\',\'");
            ar.writeHtml(ngp.getSite().getKey());
            ar.write("\','Start Offer','");
            ar.writeHtml(String.valueOf(index));
            ar.write("');\"");
            if(state == BaseRecord.STATE_STARTED){
                ar.write(" class=\"hiddenlink\"");
            }
            ar.write(" title=\"Start & Offer the Activity\"/>");
            ar.write("&nbsp;&nbsp;&nbsp;&nbsp;<img src=\"");
            ar.writeHtml(ar.retPath);
            ar.write("assets/goalstate/small"+state+".gif\" alt=\"accepted\"  /> <b>Start/Offer</b>");
            ar.write("</a>");


            ar.write("\n<a id =\"");
            ar.writeHtml(task.getId());
            ar.write("_acceptActBtn\" href=\"#\"");
            ar.write(" onclick=\"return updateStatusAjaxCall(\'");
            ar.writeHtml(task.getId());
            ar.write("\',\'");
            ar.writeHtml(ngp.getKey());
            ar.write("\',\'");
            ar.writeHtml(ngp.getSite().getKey());
            ar.write("\','Mark Accepted','");
            ar.writeHtml(String.valueOf(index));
            ar.write("');\"");

            if(state == BaseRecord.STATE_ACCEPTED){
                ar.write(" class=\"hiddenlink\"");
            }
            ar.write(" title=\"Accept the activity\"/>");
            ar.write("&nbsp;&nbsp;&nbsp;&nbsp;<img src=\"");
            ar.writeHtml(ar.retPath);
            ar.write("assets/goalstate/small3.gif\" alt=\"accepted\"  /> <b>Mark Accepted</b>");
            ar.write("</a>");


            ar.write("\n<a id =\"");
            ar.writeHtml(task.getId());
            ar.write("_completeActBtn\" href=\"#\"");
            ar.write(" onclick=\"return updateStatusAjaxCall(\'");
            ar.writeHtml(task.getId());
            ar.write("\',\'");
            ar.writeHtml(ngp.getKey());
            ar.write("\',\'");
            ar.writeHtml(ngp.getSite().getKey());
            ar.write("\','Complete Activity','");
            ar.writeHtml(String.valueOf(index));
            ar.write("');\"");
            if(state == BaseRecord.STATE_COMPLETE){
                ar.write(" class=\"hiddenlink\"");
            }
            ar.write(" title=\"Complete this activity\"/>");
            ar.write("&nbsp;&nbsp;&nbsp;&nbsp;<img src=\"");
            ar.writeHtml(ar.retPath);
            ar.write("assets/goalstate/small5.gif\" alt=\"completed\"  />&nbsp;<b>Mark Completed</b>");
            ar.write("</a>");

            ar.write("\n<a id =\"");
            ar.writeHtml(task.getId());
            ar.write("_approveActBtn\" href=\"#\"");

            ar.write(" onclick=\"return updateStatusAjaxCall(\'");
            ar.writeHtml(task.getId());
            ar.write("\',\'");
            ar.writeHtml(ngp.getKey());
            ar.write("\',\'");
            ar.writeHtml(ngp.getSite().getKey());

            ar.write("\','Approve','");
            ar.writeHtml(String.valueOf(index));
            ar.write("');\"");


            if(state != BaseRecord.STATE_COMPLETE){
                ar.write(" class=\"hiddenlink\"");
            }
            ar.write(" title=\"Review/Approve results of activity\"/>");
            ar.write(" &nbsp;&nbsp;&nbsp;&nbsp;<img src=\"");
            ar.writeHtml(ar.retPath);
            ar.write("/assets/iconApprove.gif\" alt=\"Approve\"  /><b>&nbsp;Approve</b>");

            ar.write("</a>");

            ar.write("\n<a id =\"");
            ar.writeHtml(task.getId());
            ar.write("_rejectActBtn\" href=\"#\"");

            ar.write(" onclick=\"return updateStatusAjaxCall(\'");
            ar.writeHtml(task.getId());
            ar.write("\',\'");
            ar.writeHtml(ngp.getKey());
            ar.write("\',\'");
            ar.writeHtml(ngp.getSite().getKey());

            ar.write("\','Reject','");
            ar.writeHtml(String.valueOf(index));
            ar.write("');\"");

            if(state != BaseRecord.STATE_COMPLETE){
                ar.write(" class=\"hiddenlink\"");
            }
            ar.write(" title=\"Review/Reject results of activity\"/>");
            ar.write("&nbsp;&nbsp;&nbsp;&nbsp;<img src=\"");
            ar.writeHtml(ar.retPath);
            ar.write("/assets/iconReject.gif\" alt=\"Approve\"  /><b>&nbsp;Reject</b>");

            ar.write("</a>");
        }

        ar.write(" </div> </div>\n");



        //check for subtasks
        String myId = task.getId();
        for (GoalRecord child : taskList) {


            if (myId.equals(child.getParentGoalId()))
            {
                if(tabIndex<1 || tabIndex>3 || isAtLevel(child, taskList, tabIndex))
                {
                    ar.write("\n<ul>");
                    ar.write("\n<div class=\"taskSeperator\"></div>");
                    outputTaskX(ar, child, ngp, subprocess, tabIndex, taskList, false, index, true);
                    ar.write("\n</ul>");
                }
            }

        }

        ar.write(" </li>");


    }


    public void outputProcess(AuthRequest ar, NGPage ngp, List<GoalRecord> taskList,
                              String subprocess,int tabIndex)
        throws Exception
    {
        boolean root=true;
        for (GoalRecord task : taskList)
        {
            int state = task.getState();
            //goals with parents will be handled recursively
            //as long as parent setting is valid
            if (!task.hasParentGoal())
            {
                if(tabIndex<1 || tabIndex>3 || isAtLevel(task, taskList, tabIndex))
                {
                    outputTaskX(ar, task, ngp, subprocess, tabIndex, taskList, root, tabIndex, false);
                    root =false;
                }
            }
        }
    }


    /*
    * level = 1  -> started, accepted, review, frozen, error
    * level = 2  -> completed, skipped
    * level = 3  -> unstarted, future
    */
    public boolean isAtLevel(GoalRecord task, List<GoalRecord> taskList, int level)
        throws Exception
    {
        int state = task.getState();

        switch (level)
        {
            case 1:
                if(state == BaseRecord.STATE_ERROR ||
                    state == BaseRecord.STATE_ACCEPTED ||
                    state == BaseRecord.STATE_STARTED ||
                    state == BaseRecord.STATE_FROZEN)
                {
                    return true;
                }
                break;
            case 2:
                if(state == BaseRecord.STATE_COMPLETE || state == BaseRecord.STATE_SKIPPED ){
                    return true;
                }
                break;
            case 3:
                if(state == BaseRecord.STATE_UNSTARTED)
                {
                    return true;
                }
        }

        //if there are any subtasks that need to be shown, then go by that
        String thisId = task.getId();
        for (GoalRecord subtask : taskList)
        {
            if (thisId.equals(subtask.getParentGoalId()))
            {
                if (isAtLevel(subtask, taskList, level))
                {
                    return true;
                }
            }
        }
        return false;
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

        public void writeTaskStateIcon(AuthRequest ar, GoalRecord task) throws Exception
        {
            int state = task.getState();
            ar.write("<a href=\"task");
            ar.write(task.getId());
            ar.write(".htm\"><img src=\"");
            ar.write(ar.retPath);
            ar.write("assets/goalstate/small"+state+".gif\" alt=\"");
            ar.writeHtml(BaseRecord.stateName(state));
            ar.write("\" id=\"");
            ar.write(task.getId());
            ar.write("_stimg\"/></a>");
        }


        public void writeAssignees(AuthRequest ar, GoalRecord task, NGPage ngp) throws Exception
        {
            StringTokenizer st = new StringTokenizer(task.getAssigneeCommaSeparatedList(), ",");
            boolean needsComma = false;
            int size = st.countTokens();
            if (size==0) {
                ar.write(" -nobody- ");
            }
            while(st.hasMoreTokens())
            {
                String userId =(String)st.nextToken();
                AddressListEntry ale = new AddressListEntry(userId);
                String userKey=UserManager.getKeyByUserId(userId);
                if(needsComma){
                    ar.write(",&nbsp;");
                }

                //ar.write("\n    ");
                ale.writeLink(ar);
                needsComma = true;
            }
        }%>


