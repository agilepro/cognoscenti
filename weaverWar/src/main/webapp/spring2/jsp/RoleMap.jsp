<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to edit roles");

    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    
    //page must work for both workspaces and for sites

    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    NGBook site = ngw.getSite();

    ar.setPageAccessLevels(ngw);
    
    UserProfile uProf = ar.getUserProfile();
    
    String frontPageResource = "FrontPage.htm";
    if ("$".equals(pageId)) {
        frontPageResource = "SiteWorkspaces.htm";
    }

    JSONArray allRoles = new JSONArray();
    JSONObject allMap = new JSONObject();
    List<AddressListEntry> allUsers = new ArrayList<>();
    
    for (WorkspaceRole aRole : ngw.getWorkspaceRoles()) {
        allRoles.put(aRole.getJSONDetail());
        JSONObject userMap = allMap.requireJSONObject(aRole.getName());
        
        for (AddressListEntry ale : aRole.getExpandedPlayers(ngw)) {
            AddressListEntry.addIfNotPresent(allUsers, ale);
            userMap.put(ale.getKey(), true);
        }
    }
    
    JSONArray allUserArray = AddressListEntry.getJSONArray(allUsers);

    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }

    boolean canUpdate = ar.canUpdateWorkspace();

%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("User Map");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.allRoles = <%allRoles.write(out,2,4);%>;
    $scope.allUsers = <%allUserArray.write(out,2,4);%>;
    $scope.allMap   = <%allMap.write(out,2,4);%>;
    $scope.isFrozen = <%= ngw.isFrozen() %>;
    $scope.showInput = false;
    //this map tells whether to display the role in detail mode.   All roles
    //start in non-detailed mode
    $scope.roleDetailToggle = {};
    $scope.canUpdate = <%=canUpdate%>;
    
    AllPeople.clearCache($scope.siteInfo.key);

    $scope.inviteMsg = "Hello,\n\nYou have been asked by '<%ar.writeHtml(uProf.getName());%>' to"
                    +" participate in a role of the project '<%ar.writeHtml(ngw.getFullName());%>'."
                    +"\n\nWeaver is a collaboration site that helps teams work together better.  You can share documents, hold a discussion, and prepare for  meetings, all securely shared within a workspace accessible only to members.  Weaver is supported by volunteers, and if you like the way it works you can join us.";


    $scope.showInput = false;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };


    $scope.cleanDuplicates = function(role) {
        var cleanList = [];
        role.players.forEach( function(item) {
            var newOne = true;
            var uidlc = item.uid.toLowerCase();
            cleanList.forEach( function(inner) {
                if (uidlc == inner.uid.toLowerCase()) {
                    newOne = false;
                }
            });
            if (newOne) {
                cleanList.push(item);
            }
        });
        role.players = cleanList;
    }
    $scope.allRoles.forEach( function(item) {
        $scope.cleanDuplicates(item);
    });
    
    $scope.updateRoleList = function(role) {
        var key = role.name;
        var newRoles = [];
        $scope.allRoles.forEach( function (item) {
            if (item.name==key) {
                newRoles.push(role);
            }
            else {
                newRoles.push(item);
            }
        });
        $scope.allRoles = newRoles;
    }


    $scope.refreshAllRoles = function() {
        window.location.reload();
    };
    
    $scope.updateRole = function(role) {
        if (!$scope.canUpdate) {
            alert("You are not able to update this role because you are an unpaid user");
            return;
        }
        var key = role.name;
        var postURL = "roleUpdate.json?op=Update";
        role.players.forEach( function(item) {
            if (!item.uid) {
                item.uid = item.name;
            }
        });
        var postdata = angular.toJson(role);
        $scope.updateRoleList(role);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.cleanDuplicates(data);
            $scope.updateRoleList(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.removePlayer = function(role, player) {
        if (!$scope.canUpdate) {
            alert("You are not able to remove player from this role because you are an unpaid user");
            return;
        }
        var newPlayers = [];
        var found = false;
        role.players.forEach( function(item) {
            if (item.uid == player.uid) {
                found = true;
            }
            else {
                newPlayers.push(item);
            }
        });
        
        if (found) {
            role.players = newPlayers;
            $scope.updateRole(role);
        }
    }

    $scope.visitPlayer = function(player) {
        window.location = "<%=ar.retPath%>v/"+encodeURIComponent(player.key)+"/PersonShow.htm";
    }
    $scope.deleteRole = function(role) {
        if (!$scope.canUpdate) {
            alert("You are not able to delete this role because you are an unpaid user");
            return;
        }
        var key = role.name;
        if (role.name == "Members" || role.name == "Stewards" ) {
            alert("The role "+role.name+" is required and can not be deleted.");
            return;
        }
        var ok = confirm("Are you sure you want to delete: "+key);
        var postURL = "roleUpdate.json?op=Delete";
        var postdata = angular.toJson(role);
        $scope.showError=false;
        if (ok) {
            $http.post(postURL ,postdata)
            .success( function(data) {
                var newSet = [];
                $scope.allRoles.map( function(item) {
                    if (item.name!=key) {
                        newSet.push(item);
                    }
                });
                $scope.allRoles = newSet;
            })
            .error( function(data, status, headers, config) {
                $scope.reportError(data);
            });
        }
    }

    $scope.sendEmailLoginRequest = function(message) {
        console.log("Unnecessary method $scope.sendEmailLoginRequest");
    }

    $scope.navigateToUser = function(player) {
        window.location="<%=ar.retPath%>v/"+encodeURIComponent(player.key)+"/PersonShow.htm";
    }
    
    $scope.openInviteSender = function (player) {
        if ($scope.isFrozen) {
            alert("You are not able to invite because this workspace is frozen");
            return;
        }
        if (!$scope.canUpdate) {
            alert("You are not able to update this role because you are an unpaid user");
            return;
        }

        var proposedMessage = {}
        proposedMessage.msg = $scope.inviteMsg;
        proposedMessage.userId = player.uid;
        proposedMessage.name   = player.name;
        proposedMessage.return = "<%=ar.baseURL%><%=ar.getResourceURL(ngw, "FrontPage.htm")%>";

        var modalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>new_assets/templates/InviteModal.html<%=templateCacheDefeater%>',
            controller: 'InviteModalCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                email: function () {
                    return player.uid;
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

    
    $scope.openRoleModal = function (role) {
        if (!$scope.canUpdate) {
            alert("You are not able to edit this role because you are an unpaid user");
            return;
        }
        var isNew = false;
        if (!role) {   
            role = {players:[]};
            isNew = true;
        }
        var modalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>new_assets/templates/RoleModal.html<%=templateCacheDefeater%>',
            controller: 'RoleModalCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                roleInfo: function () {
                    return JSON.parse(JSON.stringify(role));
                },
                isNew: function() {return isNew;},
                parentScope: function() { return $scope; },
                siteId: function() {return $scope.siteInfo.key}
            }
        });

        modalInstance.result.then(function (message) {
            $scope.refreshAllRoles();
        }, function () {
            $scope.refreshAllRoles();
        });
    };
    
    $scope.goNomination = function(role) {
        if ($scope.isFrozen) {
            alert("You are not able to update this role because this workspace is frozen");
            return;
        }
        if (!$scope.canUpdate) {
            alert("You are not able to update this role because you are an unpaid user");
            return;
        }
        if (!role.terms) {
            role.terms = [];
        }
        if (role.terms.length > 0) {
            var selTerm = role.terms[role.terms.length-1];
            window.location = "RoleNomination.htm?role="+role.name+"&term="+selTerm.key;
            return;
        }
        
        //need to create a term so you can vote on it
        
        var newTerm = {state: "Initial Check"};
        var proposeBegin = (new Date()).getTime();
        newTerm.termStart = proposeBegin;
        newTerm.termEnd = proposeBegin + 365*24*60*60*1000;
        role.terms.push(newTerm);
        
        var postURL = "roleUpdate.json?op=Update";
        role.players.forEach( function(item) {
            if (!item.uid) {
                item.uid = item.name;
            }
        });
        var postdata = angular.toJson(role);
        $scope.updateRoleList(role);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.cleanDuplicates(data);
            $scope.updateRoleList(data);
            var createdTerm = false;
            data.terms.forEach( function(aTerm) {
                if (aTerm.termStart == proposeBegin) {
                    createdTerm = true;
                    window.location = "RoleNomination.htm?role="+role.name+"&term="+aTerm.key;
                }
            });
            if (!createdTerm) {
                console.log("DID NOT FIND the term that was supposed to be created!", newTerm, data);
            }
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    
});

</script>
<script src="../../../jscript/AllPeople.js"></script>

<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>


<% if (canUpdate) { %>
    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1" href="RoleManagement.htm">
              <span class="fa fa-group"></span> Manage Roles</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1" href="RoleInvite.htm">
              <span class="fa fa-phone"></span> Invite Users</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1" href="MultiInvite.htm">
              <span class="fa fa-phone"></span> Multi-Person Invite</a></li>
          <li role="presentation" class="divider"></li>
          <li role="presentation"><a role="menuitem" tabindex="-1" ng-click="openRoleModal(null)">
              <span class="fa fa-plus-square"></span> Create New Role</a></li>
        </ul>
      </span>
    </div>
<% } %>

    <style>
    .spacey tr td{
        padding: 8px;
    }
    .spacey tr:hover {
        background-color:lightgrey;
    }
    .spacey {
        width: 100%;
    }
    .updateStyle {
        padding:5px;
        color:grey;
        border-radius:15px;
        font-size:10px;
    }
    .userColumn {
        text-align: center;
    }
    </style>
    

    <table class="spacey table">
        <tr>
            <td></td>
            <td></td>
            
            <td ng-repeat="user in allUsers" class="userColumn">
                <img class="rounded-5" 
                         ng-src="<%=ar.retPath%>icon/{{user.key}}.jpg" 
                         style="width:32px;height:32px" 
                         title="{{user.name}} - {{user.uid}}">
            </td>
        </tr>
        <tr ng-repeat="role in allRoles">
            <td>
<% if (canUpdate) { %>
              <div class="dropdown">
                <button class="dropdown-toggle specCaretBtn"
                        type="button" id="menu4" data-toggle="dropdown">
                    <span class="caret"></span></button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu4">
                  <li role="presentation"><a role="menuitem" 
                      ng-click="openRoleModal(role)">
                      <span class="fa fa-edit"></span> Edit All Players </a></li>
                  <li role="presentation"><a role="menuitem" 
                      href="RoleDefine.htm?role={{role.name}}">
                      <span class="fa fa-street-view"></span> Define Role </a></li>
                  <li role="presentation"><a role="menuitem" 
                      ng-click="goNomination(role)">
                      <span class="fa fa-flag-o"></span> Role Elections </a></li>
                  <li role="presentation"><a role="menuitem" tabindex="-1"
                      href="MultiInvite.htm?role={{role.name}}">
                      <span class="fa fa-phone"></span>Multi-Person Invite</a></li>
                  <li role="presentation" class="divider"></li>
                  <li role="presentation"><a role="menuitem" 
                      ng-click="deleteRole(role)">
                      <span class="fa fa-times"></span> Delete Role</a></li>
                </ul>
              </div>
<% } %>
            </td>
            <td ng-click="roleDetailToggle[role.name]=!roleDetailToggle[role.name]" ng-dblclick="openRoleModal(role)">
                <div style="color:black;background-color:{{role.color}};padding:5px">
                    {{role.name}}</div>
                <div ng-show="role.canUpdateWorkspace" class="updateStyle">CAN EDIT</div>
                <div ng-hide="role.canUpdateWorkspace" class="updateStyle">READ-ONLY</div>
            </td>
            <td ng-repeat="user in allUsers" class="userColumn" ng-dblclick="openRoleModal(role)">

                <div ng-show="allMap[role.name][user.key]"><i class="fa fa-check"></i></div>
                <div ng-hide="allMap[role.name][user.key]">.</div>
            </td>
        </tr>
    </table>

<% if (canUpdate) { %>
    <button class="btn btn-primary btn-raised" ng-click="openRoleModal(null)">
        <span class="fa fa-plus"></span> Create Role</button>
<% } %>
        
    <div style="height:150px"></div>

</div>
<script src="<%=ar.retPath%>new_assets/templates/RoleModalCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/InviteModal.js"></script>

