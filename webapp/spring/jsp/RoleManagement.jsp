<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to edit roles");

    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    
    //page must work for both workspaces and for sites
    NGContainer ngc = ar.getCogInstance().getWorkspaceOrSiteOrFail(siteId, pageId);
    ar.setPageAccessLevels(ngc);
    UserProfile uProf = ar.getUserProfile();

    JSONArray allRoles = new JSONArray();

    for (CustomRole aRole : ngc.getAllRoles()) {
        for (AddressListEntry ale: aRole.getDirectPlayers()) {
            UserProfile uP2 = ale.getUserProfile();
            if (uP2!=null) {
                uP2.assureImage(ar.getCogInstance());
            }
        }
        allRoles.put(aRole.getJSONDetail());
    }

    //String cacheDefeater = "?t="+System.currentTimeMillis();
    String cacheDefeater = "";

%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap','ngTagsInput']);
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {
    window.setMainPageTitle("Roles");
    $scope.allRoles = <%allRoles.write(out,2,4);%>;
    $scope.showInput = false;

    $scope.inviteMsg = "Hello,\n\nYou have been asked by '<%ar.writeHtml(uProf.getName());%>' to"
                    +" participate in a role of the project '<%ar.writeHtml(ngc.getFullName());%>'."
                    +"\n\nThe links below will make registration quick and easy, and after that you will be able to"
                    +" participate directly with the others through the site.";
    
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
    
    function updateRoleList(role) {
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


    $scope.updateRole = function(role) {
        var key = role.name;
        var postURL = "roleUpdate.json?op=Update";
        role.players.forEach( function(item) {
            if (!item.uid) {
                item.uid = item.name;
            }
        });
        var postdata = angular.toJson(role);
        updateRoleList(role);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.cleanDuplicates(data);
            updateRoleList(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.saveCreatedRole = function(newOne) {
        var key = newOne.name;
        $scope.allRoles.push(newOne);
        var postdata = angular.toJson({name: key});
        postURL = "roleUpdate.json?op=Create";
        $http.post(postURL,postdata)
        .success( function(data) {
            $scope.cleanDuplicates(data);
            updateRoleList(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });        
    }

    $scope.visitPlayer = function(player) {
        window.location = "<%=ar.retPath%>v/FindPerson.htm?uid="+player.uid;
    }
    $scope.deleteRole = function(role) {
        var key = role.name;
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
    $scope.imageName = function(player) {
        if (player.key) {
            return player.key+".jpg";
        }
        else {
            var lc = player.uid.toLowerCase();
            var ch = lc.charAt(0);
            var i =1;
            while(i<lc.length && (ch<'a'||ch>'z')) {
                ch = lc.charAt(i); i++;
            }
            return "fake-"+ch+".jpg";
        }
    }

    $scope.sendEmailLoginRequest = function(message) {
        var postURL = "<%=ar.getSystemProperty("identityProvider")%>?openid.mode=apiSendInvite";
        var postdata = JSON.stringify(message);
        $http.post(postURL ,postdata)
        .success( function(data) {
            alert("message has been sent to "+message.userId);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }

    $scope.navigateToUser = function(player) {
        window.location="<%=ar.retPath%>v/FindPerson.htm?uid="+encodeURIComponent(player.uid);
    }
    
    $scope.openInviteSender = function (player) {

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/InviteModal.html<%=cacheDefeater%>',
            controller: 'InviteModalCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                email: function () {
                    return player.uid;
                },
                msg: function() {
                    return $scope.inviteMsg;
                }
            }
        });

        modalInstance.result.then(function (message) {
            $scope.inviteMsg = message.msg;
            message.userId = player.uid;
            message.name = player.name;
            message.return = "<%=ar.baseURL%><%=ar.getResourceURL(ngc, "frontPage.htm")%>";
            $scope.sendEmailLoginRequest(message);
        }, function () {
            //cancel action - nothing really to do
        });
    };

    
    $scope.openRoleModal = function (role) {
        var isNew = false;
        if (!role) {   
            role = {players:[]};
            isNew = true;
        }
        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/RoleModal.html<%=cacheDefeater%>',
            controller: 'RoleModalCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                roleInfo: function () {
                    return JSON.parse(JSON.stringify(role));
                },
                isNew: function() {return isNew;},
                parentScope: function() { return $scope; }
            }
        });

        modalInstance.result.then(function (message) {
            //what to do when closing the role modal?
        }, function () {
            //cancel action - nothing really to do
        });
    };
    
});

</script>
<script src="../../../jscript/AllPeople.js"></script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              ng-click="openRoleModal(null)">Create New Role</a></li>
        </ul>
      </span>
    </div>

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
    </style>
    
    <p><i>Add people to the project by clicking on any row below and entering their email address at in the pop up prompt.</i></p>
    <table class="spacey table">
        <tr ng-repeat="role in allRoles" 
            class="generalContent">
            <td  ng-click="openRoleModal(role)">
                <button class="btn btn-sm" style="color:black;background-color:{{role.color}}">
                    {{role.name}}</button>
            </td>
            <td style="width:200px">
                <span ng-repeat="player in role.players">
                  <span class="dropdown">
                    <span id="menu1" data-toggle="dropdown">
                    <img class="img-circle" src="<%=ar.retPath%>users/{{imageName(player)}}" 
                         style="width:32px;height:32px" title="{{player.name}} - {{player.uid}}">
                    </span>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                          tabindex="-1" ng-click="">
                          <span class="fa fa-user"></span> {{player.name}} - {{player.uid}}</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="navigateToUser(player)">
                          <span class="fa fa-user"></span> Visit Profile</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="openInviteSender(player)">
                          <span class="fa fa-envelope-o"></span> Compose &amp; Send Invitation</a></li>
                    </ul>
                  </span>
                </span>
            </td>
            <td  ng-click="openRoleModal(role)">
                <div ng-show="role.description">
                    <b>Description:</b><br/>
                    {{role.description}}
                </div>
                <div ng-show="role.requirements">
                    <b>Eligibility:</b><br/>
                    {{role.requirements}}
                </div>
            </td>
        </tr>
    </table>

    <button class="btn btn-primary btn-raised" ng-click="openRoleModal(null)" style="float:right;">
        <span class="fa fa-plus"></span> Create Role</button>

</div>
<script src="<%=ar.retPath%>templates/RoleModalCtrl.js"></script>
<script src="<%=ar.retPath%>templates/InviteModal.js"></script>

