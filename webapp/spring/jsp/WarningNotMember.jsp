<%@page import="org.socialbiz.cog.NGRole"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.RoleRequestRecord"
%><%
    UserProfile up = ar.getUserProfile();
    AddressListEntry ale = up.getAddressListEntry();
    String description = "";
    
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
    $scope.enterRequest = "";
    
    $scope.takeStep = function() {
        if (!$scope.enterMode) {
            $scope.enterMode = true;
            return;
        }
        else {
            alert("Sorry, not implemented yet.");
        }
    }
});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

    <div class="generalArea">
      <table><tr><td>
        <img src="<%=ar.retPath %>assets/iconAlertBig.gif" title="Alert">
      </td><td>
        <div class="generalContent warningBox">
            <% ale.writeLink(ar); %> is not a "<b class="red">Member</b>" of this workspace.
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
                   for (AddressListEntry player : admins.getExpandedPlayers(ar.ngp)) {
                       ar.write("<span>");
                       player.writeLink(ar);
                       ar.write(", </span>");
                   }
                %>
                </td>
              </tr>
              <tr>
                <td>
                    Purpose: 
                </td>
                <td>
                   <% ar.writeHtml(((NGPage)ar.ngp).getProcess().getDescription()); %>
                </td>
              </tr>
              <tr>
                <td></td><td></td>
              </tr>
            </table>
        </div>
        <div ng-hide="enterMode" class="generalContent warningBox">
            If you think you should be a member then please:  
        </div>
        <div ng-show="enterMode" class="generalContent warningBox">
            <div>Enter a reason to join the workspace:</div>
            <textarea ng-model="enterRequest" class="form-control"></textarea>
        </div>
        <div class="generalContent warningBox">
            <button class="btn btn-primary" ng-click="takeStep()">Request Membership</button>
        </div>
      </td></tr></table>
    </div>

</div>