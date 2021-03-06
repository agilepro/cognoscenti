<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.License"
%><%@page import="java.util.TimeZone"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    ar.assertLoggedIn("");
    String siteId = ar.reqParam("siteId");
    String userKey = ar.reqParam("userKey");
    NGBook  ngb = ar.getCogInstance().getSiteByIdOrFail(siteId);
    String pageAddress = ar.getResourceURL(ngb,"Personal.htm");
    
    
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
    List<NGPageIndex> allWorkspaces = ar.getCogInstance().getAllProjectsInSite(siteId);
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
    JSONArray timeZoneList = new JSONArray();
    for (String tz : TimeZone.getAvailableIDs()) {
        timeZoneList.put(tz);
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
    $scope.siteId = "<%=siteId%>";
    $scope.newEmail = "";
    $scope.admin = <%admin.write(out,2,4);%>;
    $scope.showws = {};
    $scope.tzFilter = "";
    $scope.timeZoneList = <%timeZoneList.write(out,2,4);%>;
    
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
        proposedMessage.return = "<%=ar.baseURL%>";
        proposedMessage.msg = "Hello,\n\nYou have been asked by '"+$scope.admin.name+"' to"
                    +" participate in a role of a Weaver project.\n";
                    
        Object.keys($scope.userMap).forEach( function(workspace) {
            var inWorkspace = false;
            Object.keys($scope.userMap[workspace].roles).forEach( function(role) {
                if ($scope.userMap[workspace].roles[role]==true) {
                    inWorkspace = true;
                }
            });
            if (inWorkspace) {
                proposedMessage.msg += "\n* " + $scope.userMap[workspace].name;
                proposedMessage.return = "<%=ar.baseURL%>v/" + $scope.siteId + "/" + workspace + "/frontPage.htm";
            }
        });
                    
        proposedMessage.msg += 
              "\n\nThe links below will make registration quick and easy, and after that you will be able to"
             +" participate directly with the others through the site.";
        proposedMessage.userId = $scope.userInfo.uid;
        proposedMessage.name   = $scope.userInfo.name;
        

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
    $scope.filteredTimeZones = function() {
        if (!$scope.tzFilter) {
            return $scope.timeZoneList.slice(0,8);
        }
        var rez = [];
        var filterList = parseLCList($scope.tzFilter);
        console.log("filterList:", filterList);
        $scope.timeZoneList.forEach( function(item) {
            var found = true;
            var lcItem = item.toLowerCase();
            filterList.forEach( function(filterTerm) {
                if (lcItem.indexOf(filterTerm)<0) {
                    found = false;
                }
            });
            if (found) {
                rez.push(item);
            }
        });
        if (rez.length>8) {
            rez = rez.slice(0,8);
        }
        console.log("Filtered RTZ:", rez);
        return rez;
    }
    $scope.selectTimeZone = function(newTimeZone) {
        $scope.userDetails.timeZone = newTimeZone;
        $scope.updateUserProfile(["timeZone"]);
    }

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
              href="SiteRoleRequest.htm">Role Requests</a></li>
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

.workspaceButton {
    border-radius: 6px;
    background-color: lightgray;
    padding: 0px;
}
.workspaceButton:hover {
    background-color: lightskyblue;
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
        <td><a href="../../{{userInfo.key}}/userSettings.htm">{{userInfo.key}}</a></td>
      </tr>
      <tr>
        <td class="labelColumn">Universal ID</td>
        <td>{{userInfo.uid}}</td>
      </tr>
      <tr>
        <td class="labelColumn" ng-click="showNamePanel=!showNamePanel">Name</td>
        <td ng-hide="showNamePanel" ng-dblclick="showNamePanel=true">{{userDetails.name}}</td>
        <td ng-show="showNamePanel">
           <input type="text" ng-model="userDetails.name" class="form-control"/>
           <button class="btn btn-primary btn-raised" 
                   ng-click="updateUserProfile(['name']);showNamePanel=false">
                   Set User Name</button>
        </td>
      </tr>
      <tr>
        <td class="labelColumn" ng-click="showDescPanel=!showDescPanel">Description</td>
        <td ng-hide="showDescPanel" ng-dblclick="showDescPanel=true">{{userDetails.description}}</td>
        <td ng-show="showDescPanel">
           <textarea ng-model="userDetails.description" class="form-control"></textarea>
           <button class="btn btn-primary btn-raised" 
                   ng-click="updateUserProfile(['description']);showDescPanel=false">
                   Set User Description</button>
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
        <td class="labelColumn" ng-click="showImagePanel=!showImagePanel">Image</td>
        <td ng-hide="showImagePanel"  ng-dblclick="showImagePanel=true">
            <img src=../../../icon/{{userDetails.image}}"/>
        </td>
        <td ng-show="showImagePanel">{{userDetails.image}}<br/>
            <img src=../../../icon/{{userDetails.image}}"/>
        </td>
      </tr>
      <tr>
        <td class="labelColumn" ng-click="showTimeZonePanel=!showTimeZonePanel">Time Zone</td>
        <td ng-hide="showTimeZonePanel" ng-dblclick="showTimeZonePanel=true">{{userDetails.timeZone}}</td>
        <td ng-show="showTimeZonePanel">
          <div class="well">
            <div class="form-inline">
                Currently set to: <b>{{userDetails.timeZone}}</b>
            </div>
            <div class="form-inline">
                Filter: <input ng-model="tzFilter" class="form-control" style="width:200px"/>
                Enter a few letters of the time zone you need.
            </div>
            <div ng-repeat="item in filteredTimeZones()">
                <b>{{item}}</b> <button ng-click="selectTimeZone(item)" class="btn btn-sm btn-default btn-raised">Select</button> 
            </div>
          </div>
        </td>
      </tr>
      <tr>
        <td class="labelColumn">Last Access</td>
        <td ng-hide="userDetails.lastLogin>100000">Has never logged in.</td>
        <td ng-show="userDetails.lastLogin>100000">{{userDetails.lastLogin|cdate}} as '{{userDetails.lastLoginId}}'</td>
      </tr>
      <tr>
        <td class="labelColumn">Disabled</td>
        <td ng-hide="userInfo.disabled">User is NOT Disabled</td>
        <td ng-show="userInfo.disabled" style="background-color:yellow">User is Disabled</td>
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
             <div style="float:right"><a href="../{{key}}/RoleManagement.htm">
                 <i class="fa fa-external-link-square"></i></div>
          </td>
        </tr>        
        <tr ng-repeat="(role,avail) in ws.roles" ng-show="showws[key] || avail">
          <td></td>
          <td>{{role}}</td>
          <td ><div ng-show="avail">
              <button ng-click="manageUserRoles(key,role,false)" class="btn btn-sm btn-raised workspaceButton">
              Remove</button>
          </div></td>
          <td><div ng-hide="avail">
              <button ng-click="manageUserRoles(key,role,true)" class="btn btn-sm btn-raised workspaceButton">
              Add</button>
          </div></td>
        </tr>        
      </tbody>
    </table>
    
    <h3>Remove</h3>    
    

    <div ng-hide="showRemovePanel">
        <button class="btn btn-raised" ng-click="showRemovePanel=true">Remove This User</button>
    </div>
    <div class="well" ng-show="showRemovePanel">
        <h3>Eliminate all References to this User</h3>
        <p>Existing objects owned or managed by this user need to be transferred to another.</p>
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
                Transfer All Responsibilities</button>
                <button class="btn btn-raised" ng-click="showRemovePanel=false">
                Cancel</button>
            </td>
          </tr>
        </table>
    </div>

    <div style="height:400px"></div>


</div>


<script src="<%=ar.retPath%>templates/InviteModal.js"></script>