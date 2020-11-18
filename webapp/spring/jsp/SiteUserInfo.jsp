<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.License"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    ar.assertLoggedIn("");
    String accountId = ar.reqParam("siteId");
    String userKey = ar.reqParam("userKey");
    NGBook  ngb = ar.getCogInstance().getSiteByIdOrFail(accountId);
    String pageAddress = ar.getResourceURL(ngb,"personal.htm");
    
    
    AddressListEntry ale = new AddressListEntry(userKey);
    UserProfile user = UserManager.getStaticUserManager().lookupUserByAnyId(userKey);
    JSONObject userDetails = new JSONObject();
    if (user!=null) {
        userDetails = user.getFullJSON();
    }
    else {
        userDetails = ale.getJSON();
    }
    
    

    JSONObject userMap = new JSONObject();
    List<NGPageIndex> allWorkspaces = ar.getCogInstance().getAllProjectsInSite(accountId);
    for (NGPageIndex ngpi : allWorkspaces) {
        NGWorkspace ngw = ngpi.getWorkspace();
        JSONObject workspaceInfo = new JSONObject();
        workspaceInfo.put("name", ngpi.containerName);
        userMap.put(ngw.getKey(), workspaceInfo);
        JSONObject roleInfo = new JSONObject();
        workspaceInfo.put("roles", roleInfo);
        for (CustomRole ngr : ngw.getAllRoles()) {
            roleInfo.put(ngr.getName(), ngr.isPlayer(ale));
        }
    }
    
    JSONObject admin = ar.getUserProfile().getJSON();
    
    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }


%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Manage User");
    $scope.userInfo = <%ale.getJSON().write(out,2,4);%>;
    $scope.hasProfile = <%=user!=null%>;
    $scope.userDetails = <%userDetails.write(out,2,4);%>;
    $scope.userMap = <%userMap.write(out,2,4);%>;
    $scope.newEmail = "";
    $scope.admin = <%admin.write(out,2,4);%>;
    $scope.showws = {};
    
    $scope.inviteMsg = "Hello,\n\nYou have been asked by '"+$scope.admin.name+"' to"
                    +" participate in a role of a Weaver project."
                    +"\n\nThe links below will make registration quick and easy, and after that you will be able to"
                    +" participate directly with the others through the site.";

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.replaceUsers = function() {
        if (!$scope.replaceConfirm) {
            alert("If you want to replace the email ids, please check the confirm box");
            return;
        }
        var postObj = {};
        postObj.sourceUser = $scope.userInfo.uid;
        postObj.destUser = $scope.destUser;
        var postdata = angular.toJson(postObj);
        $scope.showError=false;
        $http.post("replaceUsers.json" ,postdata)
        .success( function(data) {
            console.log(JSON.stringify(data));
            alert("Operation changed user in "+data.updated+" places.");
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.createUserProfile = function() {
        var postObj = {};
        postObj.uid = $scope.userInfo.uid;
        var postdata = angular.toJson(postObj);
        $scope.showError=false;
        $http.post("assureUserProfile.json" ,postdata)
        .success( function(data) {
            console.log(JSON.stringify(data));
            alert("User profile for "+$scope.userInfo.uid+" has been created.");
            window.location.reload(false);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.updateUserProfile = function(fields) {
        var postObj = {};
        postObj.uid = $scope.userInfo.uid;
        fields.forEach( function(item) {
            console.log("setting: "+item, $scope.userDetails[item]);
            postObj[item] = $scope.userDetails[item];
        });
        var postdata = angular.toJson(postObj);
        $scope.showError=false;
        console.log("UPDATE:", postObj);
        $http.post("updateUserProfile.json" ,postdata)
        .success( function(data) {
            console.log("RESPONSE:", data);
            alert("User profile for "+$scope.userInfo.uid+" has been updated.");
            window.location.reload(false);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.addEmail = function() {
        //preferred is a pseudofield for adding email.
        $scope.userDetails.preferred = $scope.newEmail;
        $scope.updateUserProfile(["preferred"]);
    }
    $scope.manageUserRoles = function(workspace, role, add) {
        var postObj = {};
        postObj.uid = $scope.userInfo.uid;
        postObj.workspace = workspace;
        postObj.role = role;
        postObj.add = add;
        var postdata = angular.toJson(postObj);
        $scope.showError=false;
        $http.post("manageUserRoles.json" ,postdata)
        .success( function(data) {
            console.log(JSON.stringify(data));
            if (add) {
                alert("User "+$scope.userInfo.uid+" has been added to role "+role);
            }
            else {
                alert("User "+$scope.userInfo.uid+" has been added to role "+role);
            }
            $scope.userMap[workspace].roles[role] = add;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.openInviteSender = function (player) {

        var proposedMessage = {}
        proposedMessage.msg = $scope.inviteMsg;
        proposedMessage.userId = $scope.userInfo.uid;
        proposedMessage.name   = $scope.userInfo.name;
        proposedMessage.return = "<%=ar.baseURL%><%=ar.getResourceURL(ngb, "frontPage.htm")%>";

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/InviteModal.html<%=templateCacheDefeater%>',
            controller: 'InviteModalCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                email: function () {
                    return proposedMessage.userId;
                },
                msg: function() {
                    return proposedMessage;
                }
            }
        });

        modalInstance.result.then(function (actualMessage) {
            $scope.inviteMsg = actualMessage.msg;
        }, function () {
            //cancel action - nothing really to do
        });
    };

});
app.filter('encode', function() {
  return window.encodeURIComponent;
});
</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>


    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem"
              href="SiteAdmin.htm">Site Admin</a></li>
          <li role="presentation"><a role="menuitem"
              href="roleRequest.htm">Role Requests</a></li>
          <li role="presentation"><a role="menuitem"
              href="SiteUsers.htm">User List</a></li>
          <li role="presentation"><a role="menuitem"
              href="SiteStats.htm">Site Statistics</a></li>
        </ul>
      </span>
    </div>

<style>
.paddedCell {
    padding:8px;
}
.labelColumn {
    width:150px;
}
.labelColumn:hover {
    background-color:#ECB6F9;
    cursor:pointer;
    width:150px;
}
.workspacerow {
    background-color:#F7E0FF;
    cursor:pointer;
    font-weight: bold;
}
</style>

    <table class="table" ng-hide="hasProfile">
      <tr>
        <td class="labelColumn">Universal ID</td>
        <td>{{userInfo.uid}}</td>
      </tr>
      <tr>
        <td class="labelColumn">Profile</td>
        <td ng-hide="hasProfile">
           <p>This user does not have a user profile yet.</p>
           <button class="btn btn-primary btn-raised" ng-click="createUserProfile()">Create Profile</button>
        </td>
      </tr>
    </table>
    
    
    
    <table class="table" ng-show="hasProfile">
      <tr>
        <td class="labelColumn">Internal Key</td>
        <td>{{userInfo.key}}</td>
      </tr>
      <tr>
        <td class="labelColumn">Universal ID</td>
        <td>{{userInfo.uid}}</td>
      </tr>
      <tr>
        <td class="labelColumn" ng-click="showNamePanel=!showNamePanel">Name</td>
        <td ng-hide="showNamePanel">{{userDetails.name}}</td>
        <td ng-show="showNamePanel">
           <input type="text" ng-model="userDetails.name" class="form-control"/>
           <button class="btn btn-primary btn-raised" ng-click="updateUserProfile(['name'])">Set User Name</button>
        </td>
      </tr>
      <tr>
        <td class="labelColumn">EMail</td>
        <td>
          <div ng-repeat="id in userDetails.ids">{{id}}</div>
        </td>
      </tr>
      <tr>
        <td class="labelColumn" ng-click="showAddEmailPanel=!showAddEmailPanel"></td>
        <td ng-hide="showAddEmailPanel">
           <button class="btn btn-primary btn-raised" ng-click="showAddEmailPanel=true">Add Email</button>
        </td>
        <td ng-show="showAddEmailPanel">
           <input type="text" ng-model="newEmail" class="form-control"/>
           <button class="btn btn-primary btn-raised" ng-click="addEmail()">Add New Primary Email</button>
        </td>
      </tr>
      <tr>
        <td class="labelColumn">Last Access</td>
        <td ng-hide="userDetails.lastLogin>100000">Has never logged in.</td>
        <td ng-show="userDetails.lastLogin>100000">{{userDetails.lastLogin|date}}</td>
      </tr>
      <tr>
        <td class="labelColumn">Time Zone</td>
        <td>{{userDetails.timeZone}}</td>
      </tr>
      <tr>
        <td class="labelColumn" ng-click="showInvitePanel=!showInvitePanel"></td>
        <td>
           <button class="btn btn-primary btn-raised" ng-click="openInviteSender()">
               Send invitation Email</button>
        </td>
      </tr>
    </table>
    
    <h3>Assign to Roles</h3>
    
    <table class="table">
      <tbody ng-repeat="(key,ws) in userMap">
        <tr class="workspacerow" ng-click="showws[key] = !showws[key]">
          <td colspan="4">{{ws.name}} &nbsp; ({{key}})
             <div style="float:right"><a href="../{{key}}/roleManagement.htm">
                 <i class="fa fa-external-link-square"></i></div>
          </td>
        </tr>        
        <tr ng-repeat="(role,avail) in ws.roles" ng-show="showws[key] || avail">
          <td></td>
          <td>{{role}}</td>
          <td ><div ng-show="avail">
              <button ng-click="manageUserRoles(key,role,false)" class="btn btn-sm btn-raised">
              Remove</button>
          </div></td>
          <td><div ng-hide="avail">
              <button ng-click="manageUserRoles(key,role,true)" class="btn btn-sm btn-raised">
              Add</button>
          </div></td>
        </tr>        
      </tbody>
    </table>
    
    <h3>Remove</h3>    
    
    <table class="table">
      <tr>
        <td class="labelColumn" ng-click="showRemovePanel=!showRemovePanel">Remove</td>
        <td ng-hide="showRemovePanel">
           <button class="btn btn-primary btn-raised" ng-click="showRemovePanel=true">Remove This User</button>
        </td>
        <td ng-show="showRemovePanel">
            <div class="well">
                <h3>Eliminate all References to this User</h3>
                <table >
                  <tr>
                    <td class="paddedCell">Replace With:</td>
                    <td class="paddedCell">
                    <input ng-model="destUser" class="form-control" placeholder="Enter an email address">
                    </td>
                  </tr>
                  <tr>
                    <td class="paddedCell"></td>
                    <td class="paddedCell">
                        <input type="checkbox" ng-model="replaceConfirm">
                        Check here to confirm, there is no way to UNDO this change
                    </td>
                  </tr>
                  <tr>
                    <td class="paddedCell"></td>
                    <td class="paddedCell">
                        <button ng-click="replaceUsers()" class="btn btn-primary btn-raised">
                        Replace First With Second</button>
                        <button class="btn btn-primary btn-raised" ng-click="showRemovePanel=false">
                        Cancel</button>
                    </td>
                  </tr>
                </table>
            </div>
        </td>
      </tr>
    </table>



<style>
.workspaceButton {
    border: 2px solid white;
    border-radius: 6px;
    background-color: lightgray;
    padding: 5px;
    padding-left: 10px;
    padding-right: 10px;
}
.workspaceButton:hover {
    background-color: lightskyblue;
}
</style>

</div>


<script src="<%=ar.retPath%>templates/InviteModal.js"></script>