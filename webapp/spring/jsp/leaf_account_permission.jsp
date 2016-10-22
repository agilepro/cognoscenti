<%@page import="org.socialbiz.cog.spring.NGWebUtils"
%><%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.springframework.web.util.WebUtils"
%><%@page import="org.socialbiz.cog.RoleRequestRecord"
%>
<%
/*
Required parameters:

    1. accountId : This is the id of a site;
*/

    ar.assertLoggedIn("");
    String accountId = ar.reqParam("accountId");
    NGBook  ngb = ar.getCogInstance().getSiteByIdOrFail(accountId);
    String go = "t/"+URLEncoder.encode(accountId, "UTF-8")+"/$/permission.htm";
    List<CustomRole> roles = ngb.getAllRoles();
    JSONObject siteInfo = new JSONObject();
    JSONArray allRoles = new JSONArray();
    for (CustomRole aRole : ngb.getAllRoles()) {
        JSONObject jo = aRole.getJSON();
        allRoles.put(jo);
    }

%>


<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.siteInfo = <%siteInfo.write(out,2,4);%>;
    $scope.allRoles = <%allRoles.write(out,2,4);%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.createRole = function() {
        alert("createRole not implemented yet");
    }

});

</script>

<div ng-app="myApp" ng-controller="myCtrl">


    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Site Permissions
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="createRole()">Create New Role</a></li>
            </ul>
          </span>

        </div>
    </div>




<script type="text/javascript">
    var roleID ="";
    function openModalDialogue(popupId,headerContent,panelWidth,id){
        roleID=id;
        var   header = headerContent+" Role "+ roleID;
        var bodyText= document.getElementById(popupId).innerHTML;
        createPanel(header, bodyText, panelWidth);
        myPanel.beforeHideEvent.subscribe(function() {
         if(!isConfirmPopup){
             window.location = "permission.htm";
         }
     });
    }

   function updateRole(op,id,formId){
         var accountId='<%ar.writeURLData(accountId);%>';
            var go='<%ar.writeURLData(go);%>';
            url='<%=ar.retPath%>PageRoleAction.jsp?p='+accountId+'&r='+roleID+'&op='+op+'&go='+go +'&id='+id;
            document.getElementById(formId).action = url;
            document.getElementById(formId).submit();


    }

    function removeRole(op,id,roleName){
      var accountId='<%ar.writeURLData(accountId);%>';
      var go='<%ar.writeURLData(go);%>';
     var r=confirm("Do you really want to remove this User '"+id+"' from Role: '"+ roleName +"'?");
     if(r==true){
        url='<%=ar.retPath%>PageRoleAction.jsp?p='+accountId+'&r='+roleName+'&op='+op+'&go='+go +'&id='+id;
          document.forms["updateRoleForm"].action = url;
          document.forms["updateRoleForm"].submit();
        }
    }

   function addRoleMember(op,id,formId){

        if(!(!id.value=='' || !id.value==null)){
            alert("Email Required");
            return false;
        }

         if(validateMultipleEmails(id)){

           id=id.value.replace(new RegExp("\n|," , "gi"), ";");
           updateRole(op,id,formId);
         }
    }

  function validateMultipleEmails(id) {
       id=id.value.replace(new RegExp(",|;" , "gi"), "\n");

       var result=new Array();
       if( id.indexOf("\n") != -1){
                result = id.split("\n");
            }
          if(result==0){
           if(!validateEmail(id)){
              alert("'"+id+ "' email id id wrong. Please provide valid Email id.");
              return false;
      }
          }

            for(var i = 0;i < result.length;i++){
          if(trimme(result[i]) != ""){
              if(!validateEmail(trimme(result[i]))){
                  alert("'"+result[i]+ "' email id id wrong. Please provide valid Email id.");
                  return false;
              }
          }
      }
       return true;
    }

   function validateEmail(field) {
        var regex=/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i;
        return (regex.test(field)) ? true : false;
  }

    </script>



        <div class="generalArea">
           <div class="generalContent">
             <!-- Tab Structure Starts Here -->
              <div id="dialog1" class="yui-pe-content" style="display: none;">

                  <form name="addMemberForm" id="addMemberForm" method="post">
                       <table>
                    <tr><td style="height: 15px"></td></tr>
                    <tr>
                      <td class="gridTableColummHeader_2">Add Player:</td>
                        <td style="width: 20px;"></td>
                        <td>
                            <input type="text" class="wickEnabled" name="rolemember" id="rolemember" onfocus="initsmartInputWindowVlaue('smartInputFloater','smartInputFloaterContent');" autocomplete="off" onkeyup="autoComplete(event,this);">
                            <div style="position: relative; text-align: left">
                                <table class="floater"
                                    style="position: absolute; top: 0; left: 0; background-color: #cecece; display: none; visibility: hidden"
                                    id="smartInputFloater" rules="none" cellpadding="0" cellspacing="0">
                                    <tr>
                                        <td id="smartInputFloaterContent" nowrap="nowrap" width="100%"></td>
                                    </tr>
                                </table>
                            </div>
                        </td>
            </tr>
                    <tr><td style="height: 5px"></td></tr>
                    <tr>
                      <td class="gridTableColummHeader_2"></td>
                        <td style="width: 20px;"></td>
                        <td><input type="button" class="btn btn-primary btn-raised"  onclick="addRoleMember('Add Member',rolemember,'addMemberForm');" value="<fmt:message key='nugen.projectsettings.button.AddMember'/>"></td>
                    </tr>
                    <tr><td style="height: 5px"></td></tr>
                </table>
                </form>
              </div>
            </div>

            <div id="container" ></div>
            <div class="generalContent">
              <table width="100%">
                  <%
                    writeAllRolesForAcct(ar, ngb);
                  %>
               </table>
            </div>
         <br><br>

         <div id="NewRole" class="yui-pe-content" style="display: none;">
            <div class="generalContent">
                  <form name="createRoleForm" id="createRoleForm" action="CreateAccountRole.form" method="post">
                         <table>
                            <tr>
                                <td class="gridTableColummHeader_2">Role Name:</td>
                                <td style="width:20px;"></td>
                                <td><input type="text" name="rolename" id="rolename" class="inputGeneral" /></td>
                             </tr>
                             <tr><td style="height:5px"></td></tr>
                             <tr>
                                <td class="gridTableColummHeader_2" valign="top"><fmt:message key="nugen.projectsettings.label.MessageCriteria"/>:</td>
                                <td style="width:20px;"></td>
                                <td style="width:20px;"><textarea name="description" id="description" class="textAreaGeneral" rows="4"></textarea></td>
                             </tr>
                             <tr><td style="height:5px"></td></tr>
                             <tr>
                                <td class="gridTableColummHeader_2"></td>
                                <td style="width:20px;"></td>
                                <td style="width:20px;"><input type="button" class="btn btn-primary btn-raised" value="<fmt:message key="nugen.button.projectsetting.addrole"/>" onclick="submitRole();"></td>
                             </tr>
                        </table>
                      </form>
            </div>



<div id="AddExistingRole" class="yui-pe-content" style="display: none;">
  <div class="generalContent">
    <form name="updateRoleForm"  id="updateRoleForm" method="post">
   <table cellpadding="0" cellspacing="0" width="100%">

                      <tr>
                          <td class="gridTableColummHeader_2"><fmt:message key="nugen.projectsettings.label.AddExistingRole"/>:</td>
                          <td style="width:20px;"></td>
                          <td>
                              <select name="newRoleName" id="newRoleName" onChange="selectList();">
                                  <option value="" selected="selected">Select</option>
                                  <%
                                  if(roles!=null){
                                  Iterator  iterator=roles.iterator();
                                   while(iterator.hasNext()){
                                       NGRole ngRole = (NGRole)iterator.next();
                                       String roleNme=ngRole.getName();
                                   %>
                                       <option value="<%ar.writeHtml(roleNme);%>"><%ar.writeHtml(roleNme);%></option>
                                 <%} }%>
                              </select>
                          </td>
                      </tr>
                      <tr><td style="height:8px" colspan="3"></td></tr>
                      <tr>
                        <td class="gridTableColummHeader_2"></td>
                        <td style="width:20px;"></td>
                        <td>
                            <input type="button" class="btn btn-primary btn-raised"  onclick="updateRole('Add Role',newRoleName.value,'updateRoleForm');" value="<fmt:message key='nugen.projectsettings.button.AddRole'/>">

                        </td>
                    </tr>
    </table>
  </form>
</div>
</div>

    <script type="text/javascript">

        YAHOO.util.Event.addListener(window, "load", function()
        {

            YAHOO.example.EnhanceFromMarkup = function()
            {
                var myColumnDefs = [
                    {key:"requestId",label:"Request Id",sortable:false,resizeable:true,hidden:true},
                    {key:"roleName",label:"Role Name",sortable:false,resizeable:true},
                    {key:"date",label:"<fmt:message key='nugen.attachment.Date'/>",sortable:true,resizeable:true},
                    {key:"requestedby",label:"Requested By",sortable:true,resizeable:true},
                    {key:"description",label:"Description",sortable:true,resizeable:true},
                    {key:"state",label:"<fmt:message key='nugen.attachment.State'/>",sortable:true,resizeable:true}
                    ];

                var myDataSource = new YAHOO.util.DataSource(YAHOO.util.Dom.get("pagelist"));
                myDataSource.responseType = YAHOO.util.DataSource.TYPE_HTMLTABLE;
                myDataSource.responseSchema = {
                    fields: [
                            {key:"requestId"},
                            {key:"roleName"},
                            {key:"date"},
                            {key:"requestedby"},
                            {key:"description"},
                            {key:"state"}
                            ]
                };

                var oConfigs = {
                    paginator: new YAHOO.widget.Paginator({
                        rowsPerPage: 200
                    }),
                    initialRequest: "results=999999"

                };


                var myDataTable = new YAHOO.widget.DataTable("listofpagesdiv", myColumnDefs, myDataSource, oConfigs,
                {caption:"",sortedBy:{key:"requestedby",dir:"date"}});

                var onContextMenuClick = function(p_sType, p_aArgs, p_myDataTable) {
                    var task = p_aArgs[1];
                  if(task) {
                        // Extract which TR element triggered the context menu

                        var elRow = this.contextEventTarget;
                        elRow = p_myDataTable.getTrEl(elRow);
                        myDataTable2=p_myDataTable;
                        elRow2=elRow;
                        var oRecord = p_myDataTable.getRecord(elRow);
                        var roleName = oRecord.getData("roleName");
                        var requestId = oRecord.getData("requestId");
                        var state = oRecord.getData("state");
                        var date = oRecord.getData("date");
                        var requestedby = oRecord.getData("requestedby");
                        var requestedDescription = oRecord.getData("description");
                        if(elRow) {
                           switch(task.index) {

                                case 0:
                                        openApprovalRejectionForm('approved',accountId,'<%=ar.retPath%>',roleName,requestedby,requestId,requestedDescription);
                                        break;
                                case 1:
                                        openApprovalRejectionForm('rejected',accountId,'<%=ar.retPath%>',roleName,requestedby,requestId,requestedDescription);
                                        break;
                                }
                            }
                        }
                    };


                var myContextMenu = new YAHOO.widget.ContextMenu("mycontextmenu",
                        {trigger:myDataTable.getTbodyEl()});

                 myContextMenu.addItems(
                                        [
                                        { text: "Approve Request"},
                                        { text: "Reject Request"}
                                        ]
                                       );

                // Render the ContextMenu instance to the parent container of the DataTable
                myContextMenu.render("listofpagesdiv");
                myContextMenu.clickEvent.subscribe(onContextMenuClick, myDataTable);

                return {
                    oDS: myDataSource,
                    oDT: myDataTable
                };
            }();
        });


        function openApprovalRejectionForm(action,accountId,URL,roleName,requestedby,requestId,reqDescription){
            var onClickFunction ="makeRoleRequest('"+action+"','"+URL+"t/approveOrRejectRoleRequest.ajax?pageId="+accountId+"&action="+action+"&requestId="+requestId+"',document.getElementById('responseDescription'),approveOrRejectRoleRequestResult)";
            var body =  '<div class="generalArea">'+
                        '<div class="generalContent">'+
                            '<table width="90%" >'+
                                '<tr>'+
                                    '<td align="left" width="40%">'+
                                        '<label id="nameLbl"><B>Role Name : </B></label>'+
                                    '</td>'+
                                    '<td class="Odd">'+
                                        roleName+
                                    '</td>'+
                                '</tr>'+
                                '<tr><td colspan = "2">&nbsp;</td></tr>'+
                                '<tr>'+
                                    '<td align="left" width="40%">'+
                                        '<label id="nameLbl"><B>Requested by : </B></label>'+
                                    '</td>'+
                                    '<td class="Odd">'+
                                        requestedby+
                                    '</td>'+
                                '</tr>'+
                                '<tr><td colspan = "2">&nbsp;</td></tr>'+
                                '<tr>'+
                                    '<td valign="top"><B>Requestee Comment : </B></td>'+
                                    '<td class="Odd">'
                                        +reqDescription+
                                    '</td>'+
                                '</tr>'+
                                '<tr><td colspan = "2">&nbsp;</td></tr>'+
                                '<tr>'+
                                    '<td valign="top"><B>Reason of Approval / Rejection : </B></td>'+
                                    '<td class="Odd">'+
                                        '<textarea name="responseDescription" id="responseDescription" style="WIDTH:95%; HEIGHT:74px;"></textarea>'+
                                    '</td>'+
                                '</tr>'+
                                '<tr><td colspan = "2">&nbsp;</td></tr>'+
                                '<tr>'+
                                    '<td colspan="2" align="center">'+
                                        '<input type="button" class="btn btn-primary btn-raised"  value="Approve / Reject" onclick="'+onClickFunction+'">&nbsp;'+
                                        '<input type="button" class="btn btn-primary btn-raised"  value="Cancel" onclick="cancel()" >'+
                                    '</td>'+
                                '</tr>'+

                            '</table>'+
                        '</div>'+
                        '</div>';
            createPanel("Request Approval / Rejection Form",body,"600px");
        }
        function trim(s) {
            var temp = s;
            return temp.replace(/^s+/,'').replace(/s+$/,'');
        }
        function makeRoleRequest(action,URL,responseDescriptionObj,resultFunction){
            if(responseDescriptionObj != null){
                if(action =="rejected" && trim(responseDescriptionObj.value) == ""){
                    alert("Please provide the reason of rejection");
                    responseDescriptionObj.focus();
                    return false;
                }else{

                    URL  = URL+"&responseDescription="+responseDescriptionObj.value
                    var transaction = YAHOO.util.Connect.asyncRequest('POST',URL,resultFunction);
                }
            }
        }


    </script>

        <%!

        public void writeAllRolesForAcct(AuthRequest ar, NGBook ngb)
        throws Exception
        {
            for (NGRole aRole : ngb.getAllRoles())
            {

              ar.write("<tr>");
                ar.write("<td valign=\"top\" class=\"columnRole\" width=\"40%\">");

                ar.write("<div class=\"pageRedHeading\"><a name=\"");
                ar.writeHtml(aRole.getName());
                ar.write("\">");
                ar.writeHtml(aRole.getName());
                ar.write("</a>");
                ar.write("</div>");



                ar.writeHtml(aRole.getDescription());
                ar.write("<br /><br />");
                ar.write("<b>Eligibility:</b><br />");
                ar.writeHtml(aRole.getRequirements());
                ar.write("<br /><br />");

                ar.write("<a href=\"");
                ar.write(ar.retPath);
                ar.write("t/");
                ar.writeURLData(ngb.getKey().toString());
                ar.write("/$/EditRoleBook.htm?projectName=" );
                ar.writeURLData(ngb.getKey());
                ar.write("&roleName=");
                ar.writeURLData(aRole.getName());
                ar.write("\">Edit Role</a>");
                ar.write("</td>");
                ar.write("<td valign=\"top\" width=\"60%\">");
                ar.write("<table class=\"gridTable3\" width=\"100%\">");
                ar.write("<tr><th colspan=\"3\">");
                ar.write("</th></tr>");

                List<AddressListEntry> allUsersRole = aRole.getDirectPlayers();
                for (AddressListEntry ale : allUsersRole)
                {
                    if(!ale.isRoleRef())
                    {
                        String nameToRemove = ale.getStorageRepresentation();
                        UserProfile uProf = ale.getUserProfile();
                        if (uProf!=null) {
                            nameToRemove = aRole.whichIDForUser(uProf);
                        }
                        ar.write("<tr><th width=\"40%\">");
                        ale.writeLink(ar);
                        ar.write("</th><td width=\"58%\">");
                        ar.writeHtml(ale.getEmail());
                        ar.write("</td><td width=\"2%\" style=\"text-align:center\">");
                        ar.write("<a href=\"javascript:removeRole('Remove','");
                        ar.writeHtml(nameToRemove);
                        ar.write("','");
                        ar.writeHtml(aRole.getName());
                        ar.write("')\">");
                        ar.write("<img src=\"");
                        ar.writeHtml(ar.retPath);
                        ar.write("/assets/iconDelete.gif\" alt=\"Delete\"/> ");
                        ar.write("</a></td></tr>");

                    }
                }

                for (AddressListEntry ale : allUsersRole)
                {
                   if(ale.isRoleRef()){

                    ar.write("<tr><td colspan=\"3\" class=\"noBorder\"><table width=\"100%\"><tr><th colspan=\"3\">");
                    ar.write("<b>Role: <a href=\"#");
                    ar.writeHtml(ale.getInitialId());
                    ar.write("\">");
                    ar.writeHtml(ale.getInitialId());
                    ar.write("</a></b>");
                    ar.write("</th></tr></table></td></tr>");
                  }
                }

                ar.write("<tr><td colspan=\"3\" class=\"noBorder\">");
                ar.write("</td></tr>");
                ar.write("</table>");
                ar.write("</tr>");
                ar.write("<tr><td colspan=\"2\" class=\"horizontalSeperatorBlue\"></td></tr>");
            }
            }
           %>
