<%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.RoleRequestRecord"
%><%
    UserProfile up = ar.getUserProfile();
    String userId = ar.getBestUserId();
    AddressListEntry ale = up.getAddressListEntry();
    String description = "";
    
    NGWorkspace ngc = (NGWorkspace) ar.ngp;
    NGBook site = ngc.getSite();
    
    boolean isRequested = false;
    String requestState = "";
    String requestMsg = "";
    long latestDate = 0;

    
    String purpose = "";
    if (ngc instanceof NGWorkspace) {
        purpose = ((NGWorkspace)ngc).getProcess().getDescription();
    }
    NGRole primRole = ngc.getPrimaryRole();
    String primRoleName = primRole.getName();
    String oldRequestEmail = "";
    
    for (RoleRequestRecord rrr : ngc.getAllRoleRequest()) {
        if (up.hasAnyId(rrr.getRequestedBy())) {
            if (rrr.getModifiedDate()>latestDate) {
                isRequested = true;
                requestMsg = rrr.getRequestDescription();
                requestState = rrr.getState();
                latestDate = rrr.getModifiedDate();
                oldRequestEmail = rrr.getRequestedBy();
            }
        }
    }
    
%>
<!-- *************************** ltd / Warning.jsp *************************** -->
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
    window.setMainPageTitle("Not Member");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.atts = "ss";
    $scope.enterMode = false;
    $scope.alternateEmailMode = false;
    $scope.enterRequest = "<% ar.writeJS(requestMsg); %>";
    $scope.requestState = "<% ar.writeJS(requestState); %>";
    $scope.oldRequestEmail = "<% ar.writeJS(oldRequestEmail); %>";
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
        $scope.enterMode = true;
        $scope.alternateEmailMode = false;
    }
    $scope.anotherAddress = function() {
        $scope.enterMode = false;
        $scope.alternateEmailMode = true;
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
            alert("OK, you have requested membership");
            $scope.enterMode=false;
        })
        .error( function(data, status, headers, config) {
            console.log("GOT ERROR ",data);
            $scope.reportError(data);
        });
    };
    $scope.requestEmail = function() {
        var url="../../../v/<%ar.writeURLData(up.getKey());%>/addEmailAddress.htm?newEmail="+encodeURIComponent($scope.newEmail);
        console.log("GET to:", url);
        promise = $http.get(url);
        promise.success( function(data) {
            console.log("EMAIL: ", data);
            $scope.addingEmail=false;
            alert("Email has been sent to '"+$scope.newEmail+"'.  Find that email in your mailbox "+
                  "and click on the link to add the email to your profile.\n"
                  +"Then return and try to access workspace.");
        })
        .error( function(data) {
            $scope.reportError(data);
        });
        
    }
    
    
});

</script>


<div>

<%@include file="ErrorPanel.jsp"%>


    <div class="generalArea">
      <table><tr><td>
        <img src="<%=ar.retPath %>assets/iconAlertBig.gif" title="Alert">
      </td><td>
        <div class="warningBox">
            <% ale.writeLink(ar); %> ( <% ar.writeHtml(up.getPreferredEmail()); %> ) is not in "<b class="red"><%ar.writeHtml(primRoleName);%></b>" role of this workspace.
        </div>
      </td></tr>
      <tr><td>
      </td><td>
        <div class="warningBox">
            You are currently logged in as <% ale.writeLink(ar); %>.  If this is not 
            correct then choose logout and log in as the correct user.
            In order to see this section, you need to be a member of the workspace.  
        </div>
        <div class="warningBox">
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
        <div ng-hide="enterMode || alternateEmailMode" class="warningBox">
            <div ng-show="isRequested">
                 You requested membership on {{requestDate|cdate}} as {{oldRequestEmail}}.<br/>
                 The status of that request is: <b>{{requestState}}</b>.
            </div>
            <div ng-hide="isRequested">
                If you think you should be a member then please:  
            </div>
            <button class="btn btn-primary btn-raised" ng-click="takeStep()">Request Membership</button>
        </div>
        <div ng-show="enterMode && !alternateEmailMode" class="warningBox well">
            <div>Enter a reason to join the workspace:</div>
            <textarea ng-model="enterRequest" class="form-control"></textarea>
            <button class="btn btn-primary btn-raised" ng-click="roleChange()">Request Membership</button>
            <button class="btn btn-warning btn-raised" ng-click="enterMode=false">Cancel</button>
        </div>
        <div class="warningBox" ng-hide="enterMode || alternateEmailMode">
        Or maybe someone entered a different email address for you?
            <button class="btn btn-primary btn-raised" ng-click="anotherAddress()">I have another Email Address</button>
        </div>
        <div ng-show="alternateEmailMode" class="warningBox well">
            <div>We can't give you access to the workspace until you verify that you 
            actually have the other email address.   
            After you add that email address to your profile, if that email address is 
            assigned to this workspace, you will be able to access the workspace.</div>
            <input ng-model="newEmail" class="form-control"/>
            Enter an email address, a confirmation message will be sent. When you receive that, click the link to add the email address to your profile.
            <button class="btn btn-primary btn-raised" ng-click="requestEmail()">Request Confirmation Message</button>
            <button class="btn btn-warning btn-raised" ng-click="alternateEmailMode=false">Cancel</button>
        </div>
      </td></tr></table>
      
      {{errorMsg}}
      
    </div>

</div>