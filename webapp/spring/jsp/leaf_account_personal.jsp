<%@page import="org.socialbiz.cog.spring.NGWebUtils"
%><%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.CustomRole"
%><%@page import="org.socialbiz.cog.RoleRequestRecord"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    ar.assertLoggedIn("must be logged in to see site settings");
    String accountId = ar.reqParam("accountId");
    NGBook  ngb = ar.getCogInstance().getSiteByIdOrFail(accountId);
    List<CustomRole> roles = ngb.getAllRoles();
    JSONObject siteInfo = new JSONObject();
%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.siteInfo = <%siteInfo.write(out,2,4);%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

});

</script>

<div ng-app="myApp" ng-controller="myCtrl">


    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Site Personal
        </div>
        <!--div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="">Do Nothing</a></li>
            </ul>
          </span>

        </div-->
    </div>


    <div class="generalContent">
        <fmt:message key="nugen.projecthome.privatelogin">
            <fmt:param value='<%= ar.getBestUserId() %>'></fmt:param>
        </fmt:message>
    </div>


        <div class="generalContent">
            <br>
            <table width="100%" class="gridTable" >
                <tr>
                    <td colspan="2" ><b>Roles of site:</b><br></td>
                </tr>

    <%
        if(roles!=null){
            UserProfile up = ar.getUserProfile();
            String roleMember = up.getUniversalId();
            String roleRequestState = "";
            Iterator  iterator=roles.iterator();
            RoleRequestRecord roleRequestRecord = null;
            String requestDescription = "";
            String responseDescription = "";
            while(iterator.hasNext()){
                roleRequestState = "";
                NGRole role = (NGRole)iterator.next();

                String roleName=role.getName();
                String roleDescription = role.getDescription();
                boolean isPlayer = role.isExpandedPlayer(up, ngb);

                String leaveRole = "display: block;";
                String joinRole = "display: none;";
                String pending =  "display: none;";
                String rejected =  "display: none;";
                roleRequestRecord = ngb.getRoleRequestRecord(roleName,roleMember);
                if(roleRequestRecord != null){
                    roleRequestState = roleRequestRecord.getState();
                    requestDescription = roleRequestRecord.getRequestDescription();
                    responseDescription =roleRequestRecord.getResponseDescription();

                }
                if(!isPlayer){
                    if("Requested".equalsIgnoreCase(roleRequestState )){
                        pending =  "display: block;";
                        joinRole = "display: none;";
                        rejected =  "display: none;";
                        leaveRole = "display: none;";
                    }else  if("Rejected".equalsIgnoreCase(roleRequestState)){
                        pending =  "display: none;";
                        joinRole = "display: none;";
                        leaveRole = "display: none;";
                        rejected =  "display: block;";
                    }else  if("Cancelled".equalsIgnoreCase(roleRequestState)){
                        pending =  "display: none;";
                        joinRole = "display: block;";
                        leaveRole = "display: none;";
                        rejected =  "display: none;";
                    }else{
                        joinRole = "display: block;";
                        leaveRole = "display: none;";
                    }
                }
        %>
                <tr>
                    <td class="gridTableColummHeader"  width="35%" valign="top">
                        <%ar.writeHtml(roleName);%>
                    </td>
                    <td width="65%">
                        <div id="div_<%=roleName%>_on" style="<%=leaveRole %>">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                            <input type="button" name="action"  class="btn btn-primary btn-raised" value="Leave the Role"  onclick="return joinOrLeaveRole(<%ar.writeQuote4JS(accountId);%>,'leave_role','<%=ar.retPath %>',<%ar.writeQuote4JS(roleName); %>,'');">
                        </div>
                        <div id="div_<%=roleName%>_off" style="<%=joinRole %>">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                            <input type="button" name="action"  class="btn btn-primary btn-raised" value="Join the Role   "  onclick="return openJoinOrLeaveRoleForm(<%ar.writeQuote4JS(accountId);%>,'join_role','<%=ar.retPath %>',<%ar.writeQuote4JS(roleName); %>,<%ar.writeQuote4JS(roleDescription);%>);">
                        </div>
                        <div id="div_<%=roleName%>_pending" style="<%=pending %>">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                            Request is pending...&nbsp;&nbsp;&nbsp;<input type="button" name="action"  class="btn btn-primary btn-raised" value="Cancel Request"  onclick="return cancelRoleRequest(<%ar.writeQuote4JS(roleName); %>);">
                        </div>
                        <div id="div_<%=roleName%>_reject" style="<%=rejected %>">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                            Request has been rejected.<a href="#" onclick="return showHideReasonDiv('div_<%=roleName%>_reason');">(See Reason)</a>&nbsp;&nbsp;&nbsp;<input type="button" name="action"  class="btn btn-primary btn-raised" value="Make New Request"  onclick="return openJoinOrLeaveRoleForm(<%ar.writeQuote4JS(accountId);%>,'join_role','<%=ar.retPath %>',<%ar.writeQuote4JS(roleName); %>,'');"/>
                            <font color="red">
                                <div id="div_<%=roleName%>_reason" style="display: none;" >
                                    <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Reason : </B>
                                    <div align="right" style="">
                                        <div  style="width:80%;border: red 1px dashed;height:35px;overflow-x:auto;overflow-y:scroll" title="Reason" align="left" >
                                            <I>&nbsp;<% ar.writeHtml(roleRequestRecord != null? roleRequestRecord.getResponseDescription():"" ); %></I>
                                        </div>
                                    </div>
                                </div>
                            </font>
                        </div>
                    </td>
                </tr>
    <%
            }
        }
    %>
            </table>
        </div>
    </div>
</div>
</div>
</body>
</html>
