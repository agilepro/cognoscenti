<%@page import="java.util.StringTokenizer"
%><%@page import="java.util.Calendar,java.text.DateFormat"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%/*

Required Parameters:

    subprocess  : This request attribute is used to check if process is subprocess or parent-process.
    pageId      : This is the id of Project which is used to get details of Project.

*/

    String subprocess  = ar.defParam("subprocess", "true");
    String pageId      = ar.reqParam("pageId");%><%!String pageTitle = "";
    boolean displayMyTask;
    UserProfile uProf=null;%><%uProf = ar.getUserProfile();

    String cpath = request.getContextPath();
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();
    pageTitle = ngp.getFullName();
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
    }

    if(startDate.equals(null) || startDate.equals("")){
        long startTime = ar.nowTime - (((long)7) * 24 * 60 * 60 * 1000);
        startDate=String.valueOf(startTime);

    }
    else{
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
                            if(li.parentNode.id!=this.idOfTree)saveString = saveString + numericParentID; else saveString = saveString ;
                        }

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

            if(json.msgType == "success"){
                if(json.taskId != "" ){
                    var taskId = json.taskId;
                    var index=json.index;
                    var status = json.taskState;
                    document.getElementById(taskId+"_"+index).src= "<%=ar.retPath%>assets/goalstate/small"+status+".gif";

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
                }
                else{
                    window.location.reload();
                }
            }
            else{
                alert(json.comments);
                showErrorMessage("Unable to Perform Action", json.msg , json.comments );
            }
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
        case BaseRecord.STATE_REVIEW:
            return "Review Activity: ";
        default:
            return "Unspecified State";
        }
    }


    public String getKeyFromURL(String url) {
        int ppos = url.indexOf("/p/")+3;
        if (ppos<3) {
            if (!url.startsWith("p/")) {
                return null;   //no p slashes, ignore this
            }
            ppos = 2;
        }
        int secondSlash = url.indexOf("/", ppos);
        if (secondSlash<=0) {
            return null;   //no second slash, ignore this
        }
        return url.substring(ppos, secondSlash);
    }


    public void writeTaskStateIcon(AuthRequest ar, GoalRecord task) throws Exception {
        int state = task.getState();
        ar.write("<a href=\"task");
        ar.write(task.getId());
        ar.write(".htm\"><img src=\"");
        ar.write(ar.retPath);
        ar.write(BaseRecord.stateImg(state));
        ar.write(" \" alt=\"");
        ar.write(BaseRecord.stateName(state));
        ar.write("\"/></a>");
    }


    public void writeAssignees(AuthRequest ar, GoalRecord task, NGPage ngp) throws Exception {
        StringTokenizer st = new StringTokenizer(task.getAssigneeCommaSeparatedList(), ",");
        boolean needsComma = false;
        int size = st.countTokens();
        if (size==0) {
            ar.write(" -nobody- ");
        }
        while(st.hasMoreTokens()) {
            String userId =(String)st.nextToken();
            AddressListEntry ale = new AddressListEntry(userId);
            String userKey=UserManager.getKeyByUserId(userId);
            if(needsComma){
                ar.write(",&nbsp;");
            }

            ale.writeLink(ar);
            needsComma = true;
        }
    }%>


