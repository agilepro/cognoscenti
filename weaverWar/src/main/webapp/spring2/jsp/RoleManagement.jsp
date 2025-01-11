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

    JSONArray allRoles = new JSONArray();

    for (CustomRole aRole : ngw.getAllRoles()) {
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
        var postURL = "roleUpdate.json?op=GetAll";
        $scope.showError=false;
        $http.post(postURL ,"{}")
        .success( function(data) {
            console.log("GETALL: ", data);
            $scope.allRoles = data.roles;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    
    $scope.updateRole = function(role) {
        if (!$scope.canUpdate) {
            alert("You are not able to update this role because you are an observer");
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
            console.log("CLEARING USERS FROM SITE: "+$scope.siteInfo.id);
            AllPeople.clearCache($scope.siteInfo.id);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.removePlayer = function(role, player) {
        if (!$scope.canUpdate) {
            alert("You are not able to remove player from this role because you are an observer");
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
            alert("You are not able to delete this role because you are an observer");
            return;
        }
        var key = role.name;
        if (role.name == "Members" || role.name == "Administrators" ) {
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
            alert("You are not able to update this role because you are an observer");
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
            alert("You are not able to edit this role because you are an observer");
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
            alert("You are not able to update this role because you are an observer");
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
    <div class="container-fluid override">
        <div class="col-md-auto second-menu"><span class="h5"> Additional Actions</span>
            <div class="col-md-auto second-menu">
                <button class="specCaretBtn m-2" type="button" data-bs-toggle="collapse" data-bs-target="#collapseSecondaryMenu" aria-expanded="false" aria-controls="collapseSecondaryMenu">
                    <i class="fa fa-arrow-down"></i>
                </button>
                <div class="collapse" id="collapseSecondaryMenu">
                    <div class="col-md-auto">
    
                        <span class="btn second-menu-btn btn-wide" type="button" ng-click="openTopicCreator()" aria-labelledby="manageRoles"><a class="nav-link" role="menuitem" tabindex="-1" href="RoleManagement.htm">
              <span class="fa fa-group"></span> &nbsp;Manage Roles</a></span>

          <span class="btn second-menu-btn btn-wide" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewSingleInvite"><a class="nav-link" role="menuitem" tabindex="-1" href="RoleInvite.htm">
              <span class="fa fa-envelope"></span> &nbsp;Invite Users</a></span>

          <span class="btn second-menu-btn btn-wide" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewInvite"><a class="nav-link" role="menuitem" tabindex="-1" href="MultiInvite.htm">
              <span class="fa fa-envelope"></span> &nbsp;Multi-Person Invite</a></span>
          <span class="btn second-menu-btn btn-wide" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewRole"><a class="nav-link" role="menuitem" tabindex="-1" ng-click="openRoleModal(null)">
              <span class="fa fa-plus-square"></span> &nbsp;Create New Role</a></span>
    </div>
                </div>
            </div>
        </div><hr>
<% } %>

<div class="d-flex col-12"><div class="contentColumn mx-5">
    
<% if (canUpdate) { %>    <p><i>Add people to the project by double clicking on any row below and entering their email address at in the pop up prompt.</i></p>
<% } %>
    <table class="spacey table">
        <tr ng-repeat="role in allRoles">
            <td>
<% if (canUpdate) { %>
              <div class="nav-item dropdown">
                <button class="btn btn-comment btn-sm btn-raised dropdown-toggle specCaretBtn"
                        type="button" id="roleMembers" data-toggle="dropdown">
                    </button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="roleMembers">
                  <li role="presentation"><a class="dropdown-item" role="menuitem" 
                      ng-click="openRoleModal(role)">
                      <span class="fa fa-edit"></span> Edit All Players </a></li>
                  <li role="presentation"><a class="dropdown-item" role="menuitem" 
                      href="RoleDefine.htm?role={{role.name}}">
                      <span class="fa fa-street-view"></span> Define Role </a></li>
                  <li role="presentation"><a class="dropdown-item" role="menuitem" 
                      ng-click="goNomination(role)">
                      <span class="fa fa-flag-o"></span> Role Elections </a></li>
                  <li role="presentation"><a class="dropdown-item" role="menuitem" tabindex="-1"
                      href="MultiInvite.htm?role={{role.name}}">
                      <span class="fa fa-envelope-o"></span> Multi-Person Invite</a></li>
                  <li role="presentation" class="divider"></li>
                  <li role="presentation"><a class="dropdown-item" role="menuitem" 
                      ng-click="deleteRole(role)">
                      <span class="fa fa-times"></span> Delete Role</a></li>
                </ul>
              </div>
<% } %>
            </td>
            <td style="width:200px" ng-click="roleDetailToggle[role.name]=!roleDetailToggle[role.name]" ng-dblclick="openRoleModal(role)">
                <div style="color:black;background-color:{{role.color}};padding:5px">
                    {{role.name}}</div>
                <!--<div ng-show="role.canUpdateWorkspace" class="updateStyle">CAN EDIT</div>
                <div ng-hide="role.canUpdateWorkspace" class="updateStyle">OBSERVER</div>-->
            </td>
            <td style="width:100px">
              <div ng-hide="roleDetailToggle[role.name]">
                <span ng-repeat="player in role.players">
                  <span class="dropdown" >
                    <span id="menu1" data-toggle="dropdown">
                    <img class="rounded-5" 
                         ng-src="<%=ar.retPath%>icon/{{player.key}}.jpg" 
                         style="width:32px;height:32px" 
                         title="{{player.name}} - {{player.uid}}">
                    </span>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                          tabindex="-1" style="text-decoration: none;text-align:center">
                          {{player.name}}<br/>{{player.uid}}</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="navigateToUser(player)">
                          <span class="fa fa-user"></span> Visit Profile</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="openInviteSender(player)">
                          <span class="fa fa-envelope-o"></span> Compose &amp; Send Invitation</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="openRoleModal(role)">
                          <span class="fa fa-edit"></span> Edit All Players </a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="removePlayer(role, player)">
                          <span class="fa fa-times"></span> Remove from Role </a></li>
                    </ul>
                  </span>
                </span>
              </div>
              <div ng-show="roleDetailToggle[role.name]"> 
                <div ng-repeat="player in role.players"  style="height:40px">
                  <span class="dropdown" >
                    <span id="playerRole" data-toggle="dropdown">
                    <img class="rounded-5" 
                         ng-src="<%=ar.retPath%>icon/{{player.key}}.jpg" 
                         style="width:32px;height:32px" 
                         title="{{player.name}} - {{player.uid}}">
                    </span>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="playerRole">
                      <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                          tabindex="-1" style="text-decoration: none;text-align:center">
                          {{player.name}}<br/>{{player.uid}}</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="navigateToUser(player)">
                          <span class="fa fa-user"></span> Visit Profile</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="openInviteSender(player)">
                          <span class="fa fa-envelope-o"></span> Compose &amp; Send Invitation</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="openRoleModal(role)">
                          <span class="fa fa-edit"></span> Edit All Players </a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="removePlayer(role, player)">
                          <span class="fa fa-times"></span> Remove from Role </a></li>
                    </ul>
                  </span>
                  <span>{{player.name}}</span>
                </div>
              </div>              
            </td>
            <td  ng-dblclick="openRoleModal(role)">
              <div ng-hide="roleDetailToggle[role.name]"> 
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
              <div ng-show="roleDetailToggle[role.name]"> 
                <div ng-repeat="player in role.players" style="height:40px;vertical-align: middle">
                  {{player.uid}}
                </div>
              </div>
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

