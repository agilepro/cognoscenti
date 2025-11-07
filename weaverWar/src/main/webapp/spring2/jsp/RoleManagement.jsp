<%@page errorPage="/spring2/jsp/error.jsp"
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
    SiteUsers siteUsers = site.getUserMap();
    
    JSONArray allRoles = new JSONArray();

    for (WorkspaceRole aRole : ngw.getWorkspaceRoles()) {
        allRoles.put(aRole.getJSONDetail());
    }

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
    window.setMainPageTitle("Roles");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.allRoles = <%allRoles.write(out,2,4);%>;
    $scope.siteUsers = <%siteUsers.getJson().write(out,2,4);%>;
        console.log("siteUsers", $scope.siteUsers);
    $scope.isFrozen = <%= ngw.isFrozen() %>;
    $scope.showInput = false;
    //this map tells whether to display the role in detail mode.   All roles
    //start in non-detailed mode
    $scope.roleDetail = {toggle: false};
    
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

    $scope.findLastLogin = function(user) {
        return $scope.siteUsers[user.key].lastAccess;
    }
    function preferredRoleOrder() {
        $scope.allRoles.sort( (a,b) => {
           if (a.symbol === "MembersRole") {
               return -1;
           }
           if (b.symbol === "MembersRole") {
               return 1;
           }
           if (a.symbol === "StewardsRole") {
               return -1;
           }
           if (b.symbol === "StewardsRole") {
               return 1;
           }
           if (a.name < b.name) {
              return -1;
           }
           if (a.name > b.name) {
              return 1;
           }
           return 0;
        });
    }
    preferredRoleOrder();

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
        var key = role.symbol;
        var newRoles = [];
        $scope.allRoles.forEach( function (item) {
            if (item.symbol==key) {
                newRoles.push(role);
            }
            else {
                newRoles.push(item);
            }
        });
        $scope.allRoles = newRoles;
        preferredRoleOrder();
    }


    $scope.refreshAllRoles = function() {
        var postURL = "roleUpdate.json?op=GetAll";
        $scope.showError=false;
        $http.post(postURL ,"{}")
        .success( function(data) {
            console.log("GETALL: ", data);
            $scope.allRoles = data.roles;
            preferredRoleOrder();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    
    $scope.updateRole = function(role) {
        if (!$scope.canUpdate) {
            alert("You are not able to update this role because you are not playing an update role in the workspace");
            return;
        }
        var key = role.symbol;
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
            console.log("CLEARING USERS FROM SITE: "+$scope.siteInfo.id);
            AllPeople.clearCache($scope.siteInfo.id);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.removePlayer = function(role, player) {
        if (!$scope.canUpdate) {
            alert("You are not able to remove player from this role because you are not playing an update role in the workspace");
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
            alert("You are not able to delete this role because you are not playing an update role in the workspace");
            return;
        }
        var key = role.symbol;
        if (role.symbol == "MembersRole" || role.symbol == "StewardsRole" ) {
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
                    if (item.symbol!=key) {
                        newSet.push(item);
                    }
                });
                $scope.allRoles = newSet;
                preferredRoleOrder();
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
            alert("You are not able to update this role because you are not playing an update role in the workspace");
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
            alert("You are not able to edit this role because you are not playing an update role in the workspace");
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
            alert("You are not able to update this role because you are not playing an update role in the workspace");
            return;
        }
        if (!role.terms) {
            role.terms = [];
        }
        if (role.terms.length > 0) {
            var selTerm = role.terms[role.terms.length-1];
            window.location = "RoleNomination.htm?role="+role.symbol+"&term="+selTerm.key;
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
                    window.location = "RoleNomination.htm?role="+role.symbol+"&term="+aTerm.key;
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

    $scope.recountUsers = function () {
        var activeCount = 0;
        var inactiveCount = 0;
        var keys = Object.keys($scope.siteUsers);
        keys.forEach(function (key) {
            if (!$scope.siteUsers[key].readOnly && $scope.siteUsers[key].lastAccess > 100000) {
                activeCount++;
            }
            else {
                inactiveCount++;
            }
        });
        $scope.activeUserCount = activeCount;
        $scope.readOnlyCount = inactiveCount;
    }
    
});

</script>
<script src="../../../jscript/AllPeople.js"></script>
<div class="container-fluid override mb-4 mx-3 d-inline-flex">
    <span class="dropdown mt-1">
        <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
            data-bs-toggle="dropdown" aria-expanded="false">
        </button>
        <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
            <li>
                <button class="dropdown-item" onclick="window.location.reload(true)">Refresh</button>
                <span class="dropdown-item" type="button" aria-labelledby="createNewSingleInvite">
                    <a class="nav-link" role="menuitem" tabindex="-1" href="UserAdd.htm">
                        <span class="fa fa-plus-square"></span> &nbsp;Add User
                    </a>
                </span>
                <span class="dropdown-item" type="button" aria-labelledby="createNewSingleInvite">
                    <a class="nav-link" role="menuitem" tabindex="-1" href="RoleInvite.htm">
                        <span class="fa fa-envelope"></span> &nbsp;Invite Users
                    </a>
                </span>
                <span class="dropdown-item" type="button" aria-labelledby="createNewInvite">
                    <a class="nav-link" role="menuitem" tabindex="-1" href="MultiInvite.htm">
                        <span class="fa fa-envelope"></span> &nbsp;Multi-Person Invite
                    </a>
                </span>
                <span class="dropdown-item" type="button" aria-labelledby="createNewRole">
                    <a class="nav-link" role="menuitem" tabindex="-1" ng-click="openRoleModal(null)">
                        <span class="fa fa-plus-square"></span> &nbsp;Create New Role
                    </a>
                </span>
            </li>
        </ul>
    </span>
    <span>
        <h1 class="d-inline page-name" id="mainPageTitle">Roles</h1>
    </span>
        
</div>
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

<div class="container-fluid override mx-3">
  <div class="d-flex col-12">
    <div class="contentColumn mx-3">
      <div class="container-fluid">
        <div class="row" ng-repeat="role in allRoles">
            <hr/>
            <div class="row">
                <span ng-dblclick="openRoleModal(role)">
                    <span style="color:black;background-color:{{role.color}};padding:5px;border-radius:5px"
                        ng-click="roleDetail.toggle=!roleDetail.toggle">
                        {{role.name}}</span>
                
                &nbsp;
<% if (canUpdate) { %>
                <span class="col-1 nav-item dropdown">
                    <button class="btn btn-comment btn-sm btn-raised dropdown-toggle specCaretBtn"
                        type="button" id="roleMembers" ng-click="dropdownStates['menu'] = !dropdownStates['menu']" aria-expanded="{{dropdownStates['menu']}}">
                    </button>
                        <ul class="dropdown-menu" ng-class="{'show': dropdownStates['menu']}" role="menu" aria-labelledby="roleMembers">
                            <li class="dropdown-item" role="menuitem" 
                            ng-click="roleDetail.toggle=!roleDetail.toggle; dropdownStates['menu'] = false">
                            <span class="fa fa-list-ul"></span><span ng-show="roleDetail.toggle"> List Mode</span><span ng-hide="roleDetail.toggle"> Details Mode</span></li></li>
                        <li role="presentation">
                            <a class="dropdown-item" role="menuitem" 
                            ng-click="openRoleModal(role); dropdownStates['menu'] = false;">
                            <span class="fa fa-edit"></span> Edit All Players </a></li>
                        <li role="presentation"><a class="dropdown-item" role="menuitem" 
                            href="RoleDefine.htm?role={{role.symbol}}">
                            <span class="fa fa-street-view"></span> Define Role </a></li>
                        <li role="presentation"><a class="dropdown-item" role="menuitem" 
                            ng-click="goNomination(role); dropdownStates['menu'] = false;">
                            <span class="fa fa-flag-o"></span> Role Elections </a></li>
                        <li role="presentation"><a class="dropdown-item" role="menuitem" tabindex="-1"
                            href="MultiInvite.htm?role={{role.symbol}}">
                            <span class="fa fa-envelope-o"></span> Multi-Person Invite</a></li>
                        <li role="presentation" class="divider"></li>
                        <li role="presentation"><a class="dropdown-item" role="menuitem" 
                            ng-click="deleteRole(role); dropdownStates['menu'] = false;">
                            <span class="fa fa-times"></span> Delete Role</a></li>
                        </ul>
                    </span> &nbsp; &nbsp;
<% } %>
                    <span ng-show="role.canUpdateWorkspace && role.canAccessWorkspace">(Can Update)</span>
                    <span ng-show="!role.canUpdateWorkspace && role.canAccessWorkspace">(Read only)</span>
                    <span ng-show="!role.canAccessWorkspace">(No Access)</span>
                </span> 
            </div>
            <div class="row py-3">
              <span class="col-4" ng-show="roleDetail.toggle">
                <span ng-repeat="player in role.players" ng-mouseleave="dropdownStates[player.uid] = false">
                <button class="no-btn" ng-click="dropdownStates[player.uid] = !dropdownStates[player.uid]"
                    aria-expanded="{{dropdownStates[player.uid]}}">
                    
                    <img class="rounded-5" 
                         ng-src="<%=ar.retPath%>icon/{{player.key}}.jpg" 
                         style="width:32px;height:32px" 
                         title="{{player.name}} - {{player.uid}}">
                </button>
                    <ul class="dropdown-menu" ng-class="{'show': dropdownStates[player.uid]}" role="menu" aria-labelledby="user" ng-mouseenter="keepDropdownOpen(playerRole)"
      ng-mouseleave="dropdownStates[playerRole] = false">
                      <li role="presentation" style="font-weight: bold; font-style: italic;"><a role="menuitem" class="dropdown-item"
                          tabindex="-1" style="text-decoration: none">
                          {{player.name}}<br/>{{player.uid}}</a></li>
                          
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" class="dropdown-item border-top border-1 " tabindex="-1"
                          ng-click="navigateToUser(player)">
                          <span class="fa fa-user"></span> Visit Profile</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" class="dropdown-item" tabindex="-1"
                          ng-click="openInviteSender(player)">
                          <span class="fa fa-envelope-o"></span> Compose &amp; Send Invitation</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" class="dropdown-item" tabindex="-1"
                          ng-click="openRoleModal(role)">
                          <span class="fa fa-edit"></span> Edit All Players </a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" class="dropdown-item" tabindex="-1"
                          ng-click="removePlayer(role, player)">
                          <span class="fa fa-times"></span> Remove from Role </a></li>
                    </ul>
                  </span>
              </span>
              <!--list view-->
              <div class="col-12" ng-hide="roleDetail.toggle"> 
                <div class="row d-flex" ng-repeat="player in role.players" ng-mouseleave="dropdownStates[player.uid] = false" style="height:40px">
                    <span class="col-auto text-center">
                    <button class="no-btn" ng-click="dropdownStates[player.uid] = !dropdownStates[player.uid]"
                    aria-expanded="{{dropdownStates[player.uid]}}">
                    <img class="rounded-5" 
                         ng-src="<%=ar.retPath%>icon/{{player.key}}.jpg" 
                         style="width:32px;height:32px" 
                         title="{{player.name}} - {{player.uid}}">
                    </button>
                    <ul class="dropdown-menu mt-1" ng-class="{'show': dropdownStates[player.uid]}" role="menu" aria-labelledby="playerRole" ng-mouseenter="keepDropdownOpen(playerRole)"
      ng-mouseleave="dropdownStates[playerRole] = false">
                      <li role="presentation" style="font-weight: bold; font-style: italic;"><a role="menuitem" 
                          tabindex="-1" class="dropdown-item" style="text-decoration: none;">
                          {{player.name}}<br/>{{player.uid}}</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" class="dropdown-item border-top border-1" tabindex="-1"
                          ng-click="navigateToUser(player)">
                          <span class="fa fa-user"></span> Visit Profile</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" class="dropdown-item" tabindex="-1"
                          ng-click="openInviteSender(player)">
                          <span class="fa fa-envelope-o"></span> Compose &amp; Send Invitation</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" class="dropdown-item" tabindex="-1"
                          ng-click="openRoleModal(role)">
                          <span class="fa fa-edit"></span> Edit All Players </a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" class="dropdown-item" tabindex="-1"
                          ng-click="removePlayer(role, player)">
                          <span class="fa fa-times"></span> Remove from Role </a></li>
                    </ul>
                    </span>
                
                    <span class="col-4 text-wrap">{{player.name}}</span>
                    <span class="col-4 text-wrap">{{player.uid}}</span>
                    <div class="col-2">{{findLastLogin(player)|cdate}} </div>
                </div>

              </div>
                            

            <span class="col-8"  ng-dblclick="openRoleModal(role)">
              <div ng-show="roleDetail.toggle"> 
                <div ng-show="role.description">
                    <b>Description:</b><br/>
                    <div ng-bind-html="role.description|wiki"></div>
                </div>
                <div ng-show="role.linkedRole">
                    <b>Linked: </b> {{role.linkedRole}}
                </div>
                <div ng-show="role.requirements">
                    <b>Eligibility:</b><br/>
                    <div ng-bind-html="role.requirements|wiki"></div>
                </div>
              </div>
              
            </span>
        </div>
    </div>

<% if (canUpdate) { %>
    <button class="btn btn-primary btn-raised btn-default" ng-click="openRoleModal(null)">
        <span class="fa fa-plus"></span> Create Role</button>
<% } %>
        
    <div style="height:150px"></div>

</div>
<script src="<%=ar.retPath%>new_assets/templates/RoleModalCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/InviteModal.js"></script>

