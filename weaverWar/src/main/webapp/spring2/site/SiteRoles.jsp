<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to edit roles");

    String siteId      = ar.reqParam("siteId");
    
    //page must work for both workspaces and for sites
    boolean isSite = true;
    NGBook site = ar.getCogInstance().getSiteByKeyOrFail(siteId).getSite();

    ar.setPageAccessLevels(site);
    
    UserProfile uProf = ar.getUserProfile();
    
    String frontPageResource = "SiteWorkspaces.htm";

    JSONArray allRoles = new JSONArray();

    for (CustomRole aRole : site.getAllRoles()) {
        allRoles.put(aRole.getJSONDetail());
    }

    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }

%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {
    window.setMainPageTitle("Roles for Site");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.allRoles = <%allRoles.write(out,2,4);%>;
    $scope.showInput = false;
    AllPeople.clearCache($scope.siteInfo.key);

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
    $scope.saveCreatedRole = function(newOne) {
        var key = newOne.name;
        $scope.allRoles.push(newOne);
        var postdata = angular.toJson(newOne);
        postURL = "roleUpdate.json?op=Create";
        $http.post(postURL,postdata)
        .success( function(data) {
            $scope.cleanDuplicates(data);
            $scope.updateRoleList(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });        
    }
    $scope.removePlayer = function(role, player) {
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
    


    
    $scope.openRoleModal = function (role) {
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

<div>

<%@include file="../jsp/ErrorPanel.jsp"%>

<div class="container-fluid">
    <div class="row d-flex">
        <div class="col-md-3 fixed-width border-end border-1 border-secondary">
            <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button">
                <a class="nav-link" role="menuitem" tabindex="-1" href="SiteRoles.htm">
                    <span class="fa fa-group"></span> Manage Roles
                </a>
            </span>
            <span role="presentation" class="divider"></span>
            <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button">
                <a class="nav-link" role="menuitem" tabindex="-1" ng-click="openRoleModal(null)">
                    <span class="fa fa-plus-square"></span> Create New Role
                </a>
            </span>
        </div>


        <div class="d-flex col-9">
            <div class="contentColumn">
                <div class="container-fluid">
                    <div class="generalContent">
                        <p><i>Add people to the project by clicking on any row below and entering their email address at in the pop up prompt.</i></p>
        <div class="row d-flex" ng-repeat="role in allRoles">
            <span class="col-1 nav-item dropdown">
                <button class="dropdown-toggle specCaretBtn" type="button" id="roleMembers" data-toggle="dropdown">
                </button>
                <ul class="dropdown-menu">
                    <li><a class="dropdown-item"  ng-click="openRoleModal(role)">
                        <span class="fa fa-edit"></span> Edit All Players </a>
                    </li>
                    <li><a class="dropdown-item" role="menuitem" ng-click="deleteRole(role)">
                        <span class="fa fa-times"></span> Delete Role</a>
                    </li>
                </ul>
            </span>
            <span class="col-2" ng-dblclick="openRoleModal(role)">
                <div class="h6" style="color:black;background-color:{{role.color}};padding:5px">{{role.name}}</div>
            </span>
            <span class="col-3 p-0">
                <span ng-repeat="player in role.players">
                    <span class="dropdown" >
                        <ul id="navbar-btn list-inline">
                            <li class="nav-item dropdown d-inline" id="user" data-toggle="dropdown">
                                <img class="rounded-5" ng-src="<%=ar.retPath%>icon/{{player.key}}.jpg" style="width:32px;height:32px" title="{{player.name}} - {{player.uid}}">
                                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                                    <li role="presentation" style="background-color:lightgrey; float:left;"><a class="dropdown-item" role="menuitem" tabindex="0" style="text-decoration: none;text-align:left">{{player.name}}<br/>{{player.uid}}</a></li>
                                    <li role="presentation" style="cursor:pointer"><a class="dropdown-item" role="menuitem" tabindex="0" ng-click="navigateToUser(player)"><span class="fa fa-user"></span> Visit Profile</a></li>
                                    <li role="presentation" style="cursor:pointer"><a class="dropdown-item" role="menuitem" tabindex="0" ng-click="openInviteSender(player)"><span class="fa fa-envelope-o"></span> Compose &amp; Send Invitation</a></li>
                                    <li role="presentation" style="cursor:pointer"><a class="dropdown-item" role="menuitem" tabindex="0" ng-click="openRoleModal(role)">
                                        <span class="fa fa-edit"></span> Edit All Players </a></li>
                                    <li role="presentation" style="cursor:pointer"><a class="dropdown-item" role="menuitem" tabindex="0" ng-click="removePlayer(role, player)"><span class="fa fa-times"></span> Remove from Role </a></li>
                                </ul>
                            </li>
                        </ul>
                    </span>
                </span>
            </span>

            <span class="col-5" ng-dblclick="openRoleModal(role)">
                <div ng-show="role.description">
                    <b>Description:</b><br/>
                    {{role.description}}
                </div>
                <div ng-show="role.linkedRole">
                    <b>Linked: </b> {{role.linkedRole}}
                </div>
                <div ng-show="role.requirements">
                    <b>Eligibility:</b><br/>
                    {{role.requirements}}
                </div>
            </span>
        </div>
    </div>
</div>


</div>
<script src="<%=ar.retPath%>new_assets/templates/RoleModalCtrl.js"></script>

