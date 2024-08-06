<%@page errorPage="/spring2/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@page import="com.purplehillsbooks.weaver.License"
%><%@page import="java.util.TimeZone"
%><%@ include file="/spring2/jsp/include.jsp"
%><%

    ar.assertLoggedIn("");
    String siteId = ar.reqParam("siteId");
    String userKey = ar.reqParam("userKey");
    Cognoscenti cog = ar.getCogInstance();
    NGBook  site = cog.getSiteByIdOrFail(siteId);
    
    
    AddressListEntry ale = new AddressListEntry(userKey);
    UserProfile user = UserManager.getStaticUserManager().lookupUserByAnyId(userKey);
    JSONObject userDetails = new JSONObject();
    if (user!=null) {
        userDetails = user.getFullJSON();
        userKey = user.getKey();
    }
    else {
        userDetails = ale.getJSON();
    }
    
    SiteUsers userMap = site.getUserMap();
    JSONObject userMapEntry = userMap.getJson().requireJSONObject(userKey);
    int editUserCount = userMap.countUpdateUsers();
    int readUserCount = userMap.countReadOnlyUsers();

    JSONObject wsMap = new JSONObject();
    List<NGPageIndex> allWorkspaces = ar.getCogInstance().getNonDelWorkspacesInSite(siteId);
    for (NGPageIndex ngpi : allWorkspaces) {
        NGWorkspace ngw = ngpi.getWorkspace();
        JSONObject workspaceInfo = new JSONObject();
        workspaceInfo.put("name", ngpi.containerName);
        wsMap.put(ngw.getKey(), workspaceInfo);
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
    
    $scope.userKey = "<%=userKey%>";
    $scope.userMapEntry = <%userMapEntry.write(out,2,4);%>;
    $scope.wsMap = <%wsMap.write(out,2,4);%>;
    $scope.wsMapFiltered = {};
    $scope.userInfo = <%ale.getJSON().write(out,2,4);%>;
    
    $scope.hasProfile = <%=user!=null%>;
    $scope.userDetails = <%userDetails.write(out,2,4);%>;
    $scope.siteId = "<%=siteId%>";
    $scope.siteSettings = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.newEmail = "";
    $scope.admin = <%admin.write(out,2,4);%>;
    $scope.showws = {};
    $scope.tzFilter = "";
    $scope.timeZoneList = <%timeZoneList.write(out,2,4);%>;
    $scope.editUserCount = <%= editUserCount %>;
    $scope.readUserCount = <%= readUserCount %>;
    
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.destUser =  $scope.admin.uid;

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
    
    $scope.changeAccess = function(makeReadOnly) {
        if (makeReadOnly && $scope.readUserCount >= $scope.siteSettings.readUserLimit) {
            alert("You have too many observers: "
            +$scope.editUserCount
            +". You are allowed only "
            +$scope.siteSettings.editUserLimit
            +" in your plan.  You will need to reduce the number of users or expand the plan.");
            return;
        }
        if (!makeReadOnly && $scope.editUserCount >= $scope.siteSettings.editUserLimit) {
            alert("You have too many full update users.  You have "
            +$scope.editUserCount
            +" but can aonly have "
            +$scope.siteSettings.editUserLimit
            +" in your payment plan.  You will probably need to remove some update users or change them to observers before you can change this user");
            return;
        }
        $scope.userMapEntry.readOnly = makeReadOnly;
        $scope.updateUserMap(["readOnly"]);
    }
    $scope.updateUserMap = function(fields) {
        var postObj = {};
        var userEntry = {};
        fields.forEach( function(item) {
            console.log("setting: "+item, $scope.userDetails[item]);
            userEntry[item] = $scope.userMapEntry[item];
        });
        postObj[$scope.userKey] = userEntry;
        var postdata = angular.toJson(postObj);
        $scope.showError=false;
        console.log("UPDATE:", postObj);
        $http.post("SiteUserMap.json" ,postdata)
        .success( function(data) {
            console.log("RESPONSE:", data);
            window.location.reload(false);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
            window.location.reload(false);
        });
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
                alert("User "+$scope.userInfo.uid+" has been removed from the role "+role);
            }
            $scope.wsMap[workspace].roles[role] = add;
            $scope.filterItems();
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
                    
        Object.keys($scope.wsMap).forEach( function(workspace) {
            var inWorkspace = false;
            Object.keys($scope.wsMap[workspace].roles).forEach( function(role) {
                if ($scope.wsMap[workspace].roles[role]==true) {
                    inWorkspace = true;
                }
            });
            if (inWorkspace) {
                proposedMessage.msg += "\n* " + $scope.wsMap[workspace].name;
                proposedMessage.return = "<%=ar.baseURL%>v/" + $scope.siteId + "/" + workspace + "/FrontPage.htm";
            }
        });
                    
        proposedMessage.msg += 
              "\n\nThe links below will make registration quick and easy, and after that you will be able to"
             +" participate directly with the others through the site.";
        proposedMessage.userId = $scope.userInfo.uid;
        proposedMessage.name   = $scope.userInfo.name;
        

        var modalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>new_assets/templates/InviteModal.html<%=templateCacheDefeater%>',
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
    
    $scope.filterItems = function() {
        var newMap = {};
        Object.keys($scope.wsMap).forEach( function(wsId) {
            var workspace = $scope.wsMap[wsId];
            var foundOne = false;
            Object.keys(workspace.roles).forEach( function(roleId) {
                if (workspace.roles[roleId]) {
                    foundOne = true;
                }
            });
            if (foundOne || $scope.showAllWorkspaces) {
                newMap[wsId] = workspace;
            }
        });
        $scope.wsMapFiltered = newMap;
    }
    $scope.filterItems();
});
app.filter('encode', function() {
  return window.encodeURIComponent;
});
</script>

<div>

<%@include file="../jsp/ErrorPanel.jsp"%>

<div class="container-fluid">
    <div class="row">
      	<div class="col-md-auto fixed-width border-end border-1 border-secondary">
            <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" href="SiteAdmin.htm">Site Admin</a></span>
            <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" role="menuitem"
              href="SiteUsers.htm">User List</a></span>
            <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" role="menuitem"
            href="SiteStats.htm">Site Statistics</a></span>
        </div>
        <div class="d-flex col-9">
		    <div class="contentColumn">
		        <div class="container-fluid">
                    <div class="generalContent">
    <div class="table" ng-hide="hasProfile">
        <div class="row col-10 d-flex my-2 align-items-baseline" >
            <span class="h6 col-2">Universal ID</span>
            <span class="col-8">{{userInfo.uid}}</span>
        </div>
        <div class="row col-10 d-flex my-2 align-items-baseline" >
        <span class="h6 col-2">Permission</span>
        <span class="col-8">
            <span class="h6"><em>User can not update without a profile</em></span>
        </span>
    </div>
      <div class="row col-10 d-flex my-2 align-items-baseline" >
        <td class="h6">Profile</td>
        <td ng-hide="hasProfile">
           <p>This user does not have a user profile yet.</p>
           <button class="btn btn-primary btn-raised" ng-click="createUserProfile()">Create Profile</button>
        </td>
    </div>
    </div>

    <div class="table" ng-show="hasProfile">
        <div class="row col-10 d-flex my-2 align-items-baseline" >
        <span class="h6 col-2">Internal Key</span>
        <span class="col-8"><a href="../../{{userInfo.key}}/UserSettings.htm">{{userInfo.key}}</a></span>
    </div>
    <div class="row col-10 d-flex my-2 align-items-baseline" >
        <span class="h6 col-2">Permission</span>
        <span class="col-8">
            <div ng-hide="userMapEntry.readOnly">
              <div>Allowed to update in this site.</div>
              <div ng-show="userMapEntry.lastAccess < 1000000">
                This user has never logged in, and will be counted as observer until they do.</div>
              <div class="my-2">
                <span class="fs-6">
                <b><em>Creator &nbsp;</em></b></span>
                <button ng-click="changeAccess(true)" class="btn btn-sm btn-comment btn-secondary btn-raised">
                Make Observer</button>
              </div>
            </div>
            <div ng-show="userMapEntry.readOnly">
              <div>Observer, cannot update the site</div>
              <div class="my-2">
                <span class="fs-6">
                <b><em>Observer &nbsp;</em></b></span>
                <button ng-click="changeAccess(false)" class="btn btn-sm btn-comment btn-secondary btn-raised">
                Make Creator</button>
                
              </div>
            </div>
            <div class="fs-6 fw-medium"> Site Creator Users: ({{editUserCount}} / {{siteSettings.editUserLimit}}), Site Observers: ({{readUserCount}} / {{siteSettings.viewUserLimit}}) </div>
        </span>
    </div>
      <div class="row col-10 d-flex my-2 align-items-baseline" >
        <span class="h6 col-2">Universal ID</span>
        <span class="col-8">{{userInfo.uid}}</span>
      </div>
      <div class="row col-10 d-flex my-2 align-items-baseline"  style="cursor:pointer">
        <span class="h6 col-2" ng-click="showNamePanel=!showNamePanel">Name</span>
        <span class="col-4" ng-hide="showNamePanel" ng-click="showNamePanel=true">{{userDetails.name}}</span>
        <span class="col-4" ng-show="showNamePanel">
           <input type="text" ng-model="userDetails.name" class="form-control"/>
           <button class=" my-2 py-1 btn btn-sm btn-comment btn-secondary btn-raised"  ng-click="updateUserProfile(['name']);showNamePanel=false"> Set User Name</button>
        </span>
    </div>
      <div class="row col-10 d-flex my-2 align-items-baseline" style="cursor:pointer">
        <span class="h6 col-2" ng-click="showDescPanel=!showDescPanel">Description</span>
        <span class="col-4" ng-hide="showDescPanel" ng-click="showDescPanel=true">{{userDetails.description}}</span>
        <span class="col-4" ng-show="showDescPanel">
           <textarea ng-model="userDetails.description" class="form-control"></textarea>
           <button class="py-1 btn btn-sm btn-comment btn-secondary btn-raised" 
                   ng-click="updateUserProfile(['description']);showDescPanel=false">
                   Set User Description</button>
        </span>
    </div>
      <div class="row col-10 d-flex my-2 align-items-baseline" >
        <span class="h6 col-2 align-baseline">EMail</span>
        <span class="col-4">
          <div ng-repeat="id in userDetails.ids">{{id}}</div>
        </span>
        <span class="h6 col-2" ng-click="showAddEmailPanel=!showAddEmailPanel"></span>
        <span class="col-4" ng-hide="showAddEmailPanel">
           <button class="py-1 btn btn-sm btn-comment btn-secondary btn-raised" ng-click="showAddEmailPanel=true">Add Email</button>
        </span>
        <span class="col-4" ng-show="showAddEmailPanel">
           <input type="text" ng-model="newEmail" class="form-control"/>
           <button class="py-1 my-2 btn btn-sm btn-wide btn-comment btn-secondary btn-raised" ng-click="addEmail()">Add New Primary Email</button>
        </span>
    </div>
      <div class="row col-10 d-flex my-2 align-items-baseline" style="cursor: pointer;">
        <span class="h6 col-2" ng-click="showImagePanel=!showImagePanel">Image</span>
        <span class="col-4" ng-hide="showImagePanel"  ng-click="showImagePanel=true">
            <img class="rounded-5" src="../../../icon/{{userDetails.image}}"/>
        </span>
        <span class="col-4 " ng-show="showImagePanel">{{userDetails.image}}<br/>
            <img class="rounded-5" src="../../../icon/{{userDetails.image}}"/>
        </span>
    </div>
      <div class="row col-10 d-flex my-2 align-items-baseline" style="cursor: pointer;">
        <span class="h6 col-2" ng-click="showTimeZonePanel=!showTimeZonePanel">Time Zone</span>
        <span class="col-6" ng-hide="showTimeZonePanel" ng-click="showTimeZonePanel=true">{{userDetails.timeZone}}</span>
        <span class="col-6" ng-show="showTimeZonePanel">
          <div class="well">
            <div class="form-inline"><span class="text-secondary">
                Currently set to: <b>{{userDetails.timeZone}}</b></span>
            </div>
            <div class="form-inline"><span class="text-secondary"> 
                <em><b>Filter:</b> Enter a few letters of the time zone you need.</em></span>
                <input ng-model="tzFilter" class="form-control " style="width:300px"/>
            </div>
            <div ng-repeat="item in filteredTimeZones()">
                <b>{{item}}</b> <button ng-click="selectTimeZone(item)" class="btn-sm btn-comment py-0 px-1 m-2">Select</button> 
            </div>
          </div>
        </span>
    </div>
    <div class="row col-10 d-flex my-2 align-items-baseline" >
        <span class="h6 col-2">Last Access</span>
        <span class="col-4" ng-hide="userDetails.lastLogin>100000">Has never logged in.</span>
        <span class="col-4" ng-show="userDetails.lastLogin>100000">{{userDetails.lastLogin|cdate}} as '{{userDetails.lastLoginId}}'</span>
      </div>
      <div class="row col-10 d-flex my-2 align-items-baseline" >
        <span class="h6 col-2" style="cursor: pointer;" ng-click="showUserDisabledPanel=!showUserDisabledPanel">Disabled</span>
        <span class="col-6"  >
          <div ng-hide="userInfo.disabled">User is NOT Disabled</div>
          <div ng-show="userInfo.disabled" style="background-color:yellow">User is Disabled</div>
          <div ng-show="showUserDisabledPanel"><i>Users can not be enabled or disabled at the site level.  Only the global administrator can enable and disable a user's global access.   Instead, at the site level, consider simply removing them from each/any workspace, or the entire site (bottom).</i></div>
        </span>
        <span class="h6 col-2" ng-click="showInvitePanel=!showInvitePanel"></span>
        <span class="col-2" >
           <button class="py-1 btn btn-sm btn-wide btn-comment btn-secondary btn-raised" ng-click="openInviteSender()">
               Send invitation Email</button>
        </span>
      </div>
    </div>
    
    <div class="h5">Assign to Roles - </div>
    <div class="h6 ms-3"><input type="checkbox" ng-model="showAllWorkspaces" ng-click="filterItems()"> Show All Workspaces</div>
    
    <table class="table">
      <tbody ng-repeat="(key,ws) in wsMapFiltered">
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
              <button ng-click="manageUserRoles(key,role,false)" class="py-1 btn btn-sm btn-wide btn-comment btn-outline-secondary btn-raised">
              Remove</button>
          </div></td>
          <td><div ng-hide="avail">
              <button ng-click="manageUserRoles(key,role,true)" class="py-1 btn btn-sm btn-wide btn-comment btn-secondary btn-raised">
              Add</button>
          </div></td>
        </tr>        
      </tbody>
    </table>
    
    <span class="h5">Remove</span>    
    

    <div ng-hide="showRemovePanel">
        <button class="py-1 btn btn-sm btn-wide btn-comment btn-secondary btn-raised m-3" ng-click="showRemovePanel=true">Completely Remove This User</button>
    </div>
    <div class="well" ng-show="showRemovePanel" style="max-width:600px">
        <span class="h5">Eliminate all References to this User</span>
        <p><i>Existing objects owned or managed by this user need to be transferred to another user
              specified by email in the box below.  All workspaces will be searched,
              and all ownership/rights/permissions will be transferred to the designated new user.
              This is the only way to truly eliminate a user id from the site.
        </i></p>
        <div  >
          <div class="row form-group d-flex col-12 m-2">
            <span class="col-3 paddedCell h6">Replace With:&nbsp;</span>
            <span class="col-6 paddedCell">
            <input ng-model="destUser" class="form-control" placeholder="Enter an email address">
            </span>
          </div>
          <div class="row form-group d-flex col-12 m-2">
            <span class="col-12 paddedCell h6">
                <input type="checkbox" ng-model="replaceConfirm">
                <b><i>Check here to confirm, there is no way to UNDO this change</i></b>
            </span>
        </div>
        <div class="row form-group d-flex col-12 m-2">
            <span class="d-flex">
                <button class="py-1 btn btn-sm btn-wide btn-comment btn-danger" ng-click="showRemovePanel=false">
                Cancel</button>
                <button ng-click="replaceUsers()" class="py-1 btn btn-sm btn-wide btn-comment btn-danger ms-auto">
                Transfer All Responsibilities</button>
                
            </span>
        </div>
        </div>
    </div>

    <div style="height:400px"></div>


</div>


<script src="<%=ar.retPath%>new_assets/templates/InviteModal.js"></script>