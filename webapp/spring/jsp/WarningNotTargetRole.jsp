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
    NGBook site;
    if (!(ngc instanceof NGPage)) {
        site = (NGBook)ngc;
    }
    else {
        site = ((NGPage)ngc).getSite();
    }
    
    String purpose = "";
    if (ngc instanceof NGPage) {
        purpose = ((NGPage)ngc).getProcess().getDescription();
    }
    String objectName = ar.reqParam("objectName");
    String roleName = ar.reqParam("roleName");
    NGRole primRole = ngc.getRole(roleName);
    
    for (RoleRequestRecord rrr : ngc.getAllRoleRequest()) {
        if (rrr.getRoleName().equals(roleName) && up.hasAnyId(rrr.getRequestedBy())) {
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

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Not Playing Role");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.atts = "ss";
    $scope.enterMode = false;
    $scope.enterRequest = "<% ar.writeJS(requestMsg); %>";
    $scope.requestState = "<% ar.writeJS(requestState); %>";
    $scope.isRequested = <%=isRequested%>;
    $scope.requestDate = <%=latestDate%>;
    $scope.roleDescription = "<% ar.writeJS(primRole.getDescription()); %>";

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
        data.roleId = '<%ar.writeJS(roleName);%>';
        data.desc = $scope.enterRequest;
        console.log("Requesting to ",data);
        var postURL = "rolePlayerUpdate.json";
        var postdata = angular.toJson(data);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            alert("OK, you have requested to join <%ar.writeJS(roleName);%>")
        })
        .error( function(data, status, headers, config) {
            console.log("GOT ERROR ",data);
            $scope.reportError(data);
        });
    };
    
    
});

</script>

<!--WarningNotTargetRole.jsp-->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

  
    <div class="generalArea">
      <table><tr><td>
        <img src="<%=ar.retPath %>assets/iconAlertBig.gif" title="Alert">
      </td><td>
        <div class="generalContent warningBox">
            <% ale.writeLink(ar); %> is not in "<b class="red"><%ar.writeHtml(roleName);%></b>" role which is required in order to access this <%ar.writeHtml(objectName);%>.
        </div>
      </td></tr>
      <tr><td>
      </td><td>
        <div class="generalContent warningBox">
            You are currently logged in as <% ale.writeLink(ar); %>.  If this is not 
            correct then choose logout and log in as the correct user.
            In order to see this section, you need to be a player of the <%ar.writeHtml(roleName);%> role.  
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
                <td>
                    Role: 
                </td>
                <td>
                   <% ar.writeHtml(roleName); %>
                </td>
              </tr>
              <tr>
                <td>
                    Description: 
                </td>
                <td>
                {{roleDescription}}
                </td>
              </tr>
              <tr>
                <td></td><td></td>
              </tr>
            </table>
        </div>
        <div ng-hide="enterMode" class="generalContent warningBox">
            <div ng-show="isRequested">
                 You requested to join <%ar.writeHtml(roleName);%> on {{requestDate|date}}.<br/>
                 The status of that request is: <b>{{requestState}}</b>.
            </div>
            <div ng-hide="isRequested">
                If you think you should join the <%ar.writeHtml(roleName);%> role then please:  
            </div>
        </div>
        <div ng-show="enterMode" class="generalContent warningBox">
            <div>Enter a reason to join the <%ar.writeHtml(roleName);%> role:</div>
            <textarea ng-model="enterRequest" class="form-control"></textarea>
        </div>
        <div class="generalContent warningBox">
            <button class="btn btn-primary btn-raised" ng-click="takeStep()">Request to Join</button>
        </div>
      </td></tr></table>
      
      {{errorMsg}}
      
    </div>

</div>