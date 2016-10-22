<%@page import="org.socialbiz.cog.NGRole"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.RoleRequestRecord"
%><%
    UserProfile up = ar.getUserProfile();
    String userId = ar.getBestUserId();
    AddressListEntry ale = up.getAddressListEntry();
    String description = "";
    
    NGContainer ngc = ar.ngp;
    boolean isRequested = false;
    String requestState = "";
    String requestMsg = "";
    long latestDate = 0;
    
    String purpose = "";
    if (ngc instanceof NGPage) {
        purpose = ((NGPage)ngc).getProcess().getDescription();
    }
    NGRole primRole = ngc.getPrimaryRole();
    String primRoleName = primRole.getName();
    
    for (RoleRequestRecord rrr : ngc.getAllRoleRequest()) {
        if (up.hasAnyId(rrr.getRequestedBy())) {
            if (rrr.getModifiedDate()>latestDate) {
                isRequested = true;
                requestMsg = rrr.getRequestDescription();
                requestState = rrr.getState();
                latestDate = rrr.getModifiedDate();
            }
        }
    }
    
%>
<style>
.warningBox {
    margin:30px;
    font-size:14px;
    width:500px;
}
</style>
<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.atts = "ss";
    $scope.enterMode = false;
    $scope.enterRequest = "<% ar.writeJS(requestMsg); %>";
    $scope.requestState = "<% ar.writeJS(requestState); %>";
    $scope.isRequested = <%=isRequested%>;
    $scope.requestDate = <%=latestDate%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    
    $scope.takeStep = function() {
        if (!$scope.enterMode) {
            $scope.enterMode = true;
            return;
        }
        else {
            $scope.roleChange();
        }
    }

    $scope.roleChange = function() {
        var data = {};
        data.op = 'Join';
        data.roleId = '<%ar.writeJS(primRoleName);%>';
        data.desc = $scope.enterRequest;
        console.log("Requesting to ",data);
        var postURL = "rolePlayerUpdate.json";
        var postdata = angular.toJson(data);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            alert("OK, you have requested membership")
        })
        .error( function(data, status, headers, config) {
            console.log("GOT ERROR ",data);
            $scope.reportError(data);
        });
    };
    
    
});

</script>

<!--WarningNotMember.jsp-->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

  
    <div class="generalArea">
      <table><tr><td>
        <img src="<%=ar.retPath %>assets/iconAlertBig.gif" title="Alert">
      </td><td>
        <div class="generalContent warningBox">
            <% ale.writeLink(ar); %> is not in "<b class="red"><%ar.writeHtml(primRoleName);%></b>" role of this workspace.
        </div>
      </td></tr>
      <tr><td>
      </td><td>
        <div class="generalContent warningBox">
            You are currently logged in as <% ale.writeLink(ar); %>.  If this is not 
            correct then choose logout and log in as the correct user.
            In order to see this section, you need to be a member of the workspace.  
        </div>
        <div class="generalContent warningBox">
            <table class="table">
              <tr>
                <td>
                  Workspace:
                </td>
                <td>
                    <b><% ar.writeHtml(ar.ngp.getFullName()); %></b>
                </td>
              </tr>
              <tr>
                <td>
                    Run By: 
                </td>
                <td>
                <%         
                   NGRole admins = ar.ngp.getSecondaryRole(); 
                   boolean needsComma = false;
                   for (AddressListEntry player : admins.getExpandedPlayers(ar.ngp)) {
                       if (needsComma) {
                           ar.write(", ");
                       }
                       ar.write("<span>");
                       player.writeLink(ar);
                       ar.write("</span>");
                       needsComma = true;
                   }
                %>
                </td>
              </tr>
              <tr>
                <td>
                    Purpose: 
                </td>
                <td>
                   <% ar.writeHtml(purpose); %>
                </td>
              </tr>
              <tr>
                <td></td><td></td>
              </tr>
            </table>
        </div>
        <div ng-hide="enterMode" class="generalContent warningBox">
            <div ng-show="isRequested">
                 You requested membership on {{requestDate|date}}.<br/>
                 The status of that request is: <b>{{requestState}}</b>.
            </div>
            <div ng-hide="isRequested">
                If you think you should be a member then please:  
            </div>
        </div>
        <div ng-show="enterMode" class="generalContent warningBox">
            <div>Enter a reason to join the workspace:</div>
            <textarea ng-model="enterRequest" class="form-control"></textarea>
        </div>
        <div class="generalContent warningBox">
            <button class="btn btn-primary btn-raised" ng-click="takeStep()">Request Membership</button>
        </div>
      </td></tr></table>
      
      {{errorMsg}}
      
    </div>

</div>