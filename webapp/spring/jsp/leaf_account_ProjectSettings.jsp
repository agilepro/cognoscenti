<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="functions.jsp"
%><%@page import="java.util.ArrayList"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.RoleRequestRecord"
%>
<html xmlns="http://www.w3.org/1999/xhtml">
<%
/*
Required parameter:

    1. accountId : This is the id of a site and here it is used to retrieve NGBook.

*/

    String accountId = ar.reqParam("accountId");

%><%!
    AuthRequest ar=null;
    String pageTitle="";
    List r=null;
%>
<%
    String activeTab = "active";
    String inactiveTab = "inactive";
    NGBook  ngb = ar.getCogInstance().getSiteByIdOrFail(accountId);

    ar.setPageAccessLevels(ngb);

    String[] names = ngb.getSiteNames();
    String specialTab = "Project Settings Content";
    List roles = ngb.getAllRoles();

    String pageFullName=ngb.getFullName();

    String pageKey =ngb.getKey();
    boolean isDeleted=ngb.isDeleted();

    if(ngb!=null){
        //TODO: should be translatable
        pageTitle= "Settings for "+ngb.getFullName();
    }

    UserProfile uProf = ar.getUserProfile();

    uProf = ar.getUserProfile();
    int requestSize = 0;
    boolean isTemplate = false;
    if (uProf!=null) {
        isTemplate = uProf.findTemplate(pageKey);
        List<RoleRequestRecord> roleRequestRecordList = ngb.getAllRoleRequest();
        requestSize = roleRequestRecordList.size();
    }
%>
    <style type="text/css">
        #mycontextmenu ul li {
            list-style:none;
             height:18px;
        }

        .yuimenubaritemlabel,
        .yuimenuitemlabel {
            outline: none;

         }

    </style>
    <script type="text/javascript">
        function submitRole(){
            var rolename =  document.getElementById("rolename");

            if(!(!rolename.value=='' || !rolename.value==null)){
                alert("Role Name Required");
                return false;
            }
            <%
            if(roles!=null){
                Iterator  it=roles.iterator();
                while(it.hasNext()){
                    NGRole role = (NGRole)it.next();
                    String roleNme=role.getName();
            %>
                    if(rolename.value.toLowerCase()=='<%=roleNme.toLowerCase()%>'){
                        alert("Role Name already exist");
                        return false;
                    }
            <%    }
            }
            %>
           document.getElementById('createRoleForm').submit();
        }
        function addRoleMember(){

            var role =document.getElementById("roleList");
            var member =document.getElementById("rolemember");

            if(!(!member.value=='' || !member.value==null)){
                    alert("Member Required");
                        return false;
                }
            if(!(!role.value=='' || !role.value==null)){
                    alert("Role Required");
                        return false;
            }
            document.forms["addMemberRoleForm"].submit();
        }


        function cancelRoleRequest(roleName ){
            var transaction = YAHOO.util.Connect.asyncRequest('POST','<%=ar.retPath%>t/approveOrRejectRoleRequest.ajax?pageId=<%ar.writeHtml(accountId);%>&action=cancel&roleName='+roleName+'&roleMember=',requestResult)
        }

        function openJoinOrLeaveRoleForm(pageId,action,URL,roleName,rolDescription){
            var onClickFunction ="joinOrLeaveRole('"+pageId+"','"+action+"','"+URL+"','"+roleName+"',document.getElementById('requestDescription'))";
            var body =  '<div class="generalArea">'+
                        '<div class="generalContent">'+
                            '<table width="90%" >'+
                                '<tr>'+
                                    '<td align="left" width="35%">'+
                                        '<label id="nameLbl"><B>Role Name : </B></label>'+
                                    '</td>'+
                                    '<td class="Odd"><B>'+
                                        roleName+
                                    '</B></td>'+
                                '</tr>'+
                                '<tr><td colspan = "2">&nbsp;</td></tr>'+
                                '<tr>'+
                                    '<td align="left" width="35%">'+
                                        '<label id="nameLbl"><B>Role Description : </B></label>'+
                                    '</td>'+
                                    '<td class="Odd">'+
                                        rolDescription+
                                    '</td>'+
                                '</tr>'+
                                '<tr><td colspan = "2">&nbsp;</td></tr>'+
                                '<tr>'+
                                    '<td valign="top"><B>Reason : </B></td>'+
                                    '<td class="Odd">'+
                                        '<textarea name="requestDescription" id="requestDescription" style="WIDTH:95%; HEIGHT:74px;"></textarea>'+
                                    '</td>'+
                                '</tr>'+
                                '<tr><td colspan = "2">&nbsp;</td></tr>'+
                                '<tr>'+
                                    '<td colspan="2" align="center">'+
                                        '<input type="button" class="btn btn-primary"  value="Request to Join Role" onclick="'+onClickFunction+'">&nbsp;'+
                                        '<input type="button" class="btn btn-primary"  value="Cancel" onclick="cancel()" >'+
                                    '</td>'+
                                '</tr>'+

                            '</table>'+
                        '</div>'+
                        '</div>';
                        createPanel("Request to Join Role",body,"600px");
        }

        function joinOrLeaveRole(pageId,action,URL,roleName,requestDescriptionObj){

            var transaction = YAHOO.util.Connect.asyncRequest('POST', URL+"t/requestToJoinOrLeaveRole.ajax?pageId="+pageId+"&action="+action+"&roleName="+roleName+"&requestDescription="+requestDescriptionObj.value, joinOrLeaveRoleResult);
        }

        var joinOrLeaveRoleResult = {
            success: function(o) {
                    var respText = o.responseText;

                    var json = eval('(' + respText+')');
                    if(json.msgType == "success"){

                        var action = json.action;

                        var leave_role_div = document.getElementById("div_"+json.roleName+"_on");
                        var join_role_div = document.getElementById("div_"+json.roleName+"_off");
                        var pending_div = document.getElementById("div_"+json.roleName+"_pending");
                        var rejected_div = document.getElementById("div_"+json.roleName+"_reject");
                        rejected_div.style.display="none";
                        leave_role_div.style.display="none";
                        if(action == "join_role"){
                            join_role_div.style.display="none";
                            pending_div.style.display="block";
                        }else{
                            pending_div.style.display="none";
                            join_role_div.style.display="block";
                        }
                    }
                    else{
                        showErrorMessage("Result", json.msg , json.comments );
                    }
                    if(myPanel != null || myPanel != 'undefined' ){
                        myPanel.hide();
                    }
                },
            failure: function(o) {
                alert("joinOrLeaveRoleResult Error:" +o.responseText);
            }
        }
        function cancel(){
            myPanel.hide();
        }
        var requestResult = {
            success: function(o) {
                    var respText = o.responseText;
                    var json = eval('(' + respText+')');
                    if(json.msgType == "success"){
                        document.getElementById("div_"+json.roleName+"_off").style.display="block";
                        document.getElementById("div_"+json.roleName+"_reject").style.display="none";
                        document.getElementById("div_"+json.roleName+"_pending").style.display="none";
                   }else{
                        showErrorMessage("Result", json.msg , json.comments );
                    }
                },
            failure: function(o) {
                alert("joinOrLeaveRoleResult 2 Error:" +o.responseText);
            }
        }

        function showHideReasonDiv(divId)
        {
            var reason_div = document.getElementById(divId);
            if(reason_div != null){
                if(reason_div.style.display=="block"){
                    reason_div.style.display="none";
                }else{
                    reason_div.style.display="block";
                }
            }
            return false;
        }

</script>
<head>
    <title><% ar.writeHtml(pageTitle); %></title>
    <link href="<%=ar.baseURL%>css/tabs.css" rel="styleSheet" type="text/css" media="screen" />
    <link href="<%=ar.baseURL%>css/tables.css" rel="styleSheet" type="text/css" media="screen" />

    <script type="text/javascript" src="<%=ar.baseURL%>jscript/nugen_utils.js"></script>
    <script type="text/javascript" src="<%=ar.baseURL%>jscript/yahoo-dom-event.js"></script>

    <script>
    var specialSubTab = '<fmt:message key="${requestScope.subTabId}"/>';
        <%
        if (accountId != null)
        {
        %>
        var accountId='<%=accountId%>';
        <%
        }
        %>
        var tab0_settings = '<fmt:message key="nugen.projectsettings.subtab.personal"/>';
        var tab1_settings = '<fmt:message key="nugen.projectsettings.subtab.Permissions"/>';
        var tab2_settings = '<fmt:message key="nugen.projectsettings.subtab.Admin"/>';
        var tab3_settings = '<fmt:message key="nugen.projectsettings.subtab.role.request"/>(<%=requestSize%>)';
        var retPath ='<%=ar.retPath%>';

    </script>

</head>
<body class="yui-skin-sam">
    <div>
        <!-- Content Area Starts Here -->
        <div class="generalArea">
            <div class="generalContent tabContainer">
                <!-- Tab Structure Starts Here -->
                <div id="container">
                    <div>
                        <ul id="subTabs" class="menu">
                        </ul>
                    </div>

    <script>
        var time = null;
        var pageChangeTime = null;
        if(document.getElementById('subTime')!=null){
        time = document.getElementById('subTime').value;
        }
        if(document.getElementById('pageChangeTime')!=null){
        pageChangeTime = document.getElementById('pageChangeTime').value;
        }
        if (time>pageChangeTime){
            document.getElementById("01").style.display="";
        }
        else if(time>0){
            document.getElementById("02").style.display="";
        }
        else{
            if(document.getElementById("03")!=null)
                document.getElementById("03").style.display="";
        }
    </script>
