<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%/*
Required parameters:

    1. pageId : This is the id of a  workspace and here it is used to retrieve NGPage (Workspace's Details).
    2. roleName : This request parameter is required to get NGRole detail of given role.

    3. roles    : This parameter is used to get List of all existing roles , this list is required to check
                  if provided 'role name' is already exists in the system or not.
*/

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Must be a member to see meetings");
    UserProfile uProf = ar.getUserProfile();

    String roleName = ar.reqParam("roleName");
    boolean isNew = "~new~".equals(roleName);
    JSONObject roleInfo = null;

    if (isNew) {
        roleInfo = new JSONObject();
        roleInfo.put("color", "lightgray");
        roleInfo.put("players", new JSONArray());
        roleInfo.put("expandedPlayers", new JSONArray());
    }
    else {
        CustomRole role = (CustomRole) ngp.getRoleOrFail(roleName);
        //migration code does not get saved here, but initialized here.
        String color = role.getColor();
        if (color==null || color.length()==0) {
            role.setColor("lightgray");
        }
        roleInfo = role.getJSON();
    }

    JSONArray allPeople = UserManager.getUniqueUsersJSON();


/*   PROTOTYPE

    $scope.roleInfo = {
      "color": "yellow",
      "description": "Members of a project can see and edit any of ",
      "expandedPlayers": [
        {
          "name": "Keith Swenson",
          "uid": "kswenson@us.fujitsu.com"
        },
        {
          "name": "Alex Demo",
          "uid": "alex@kswenson.oib.com"
        }
      ],
      "name": "Members",
      "players": [
        {
          "name": "Keith Swenson",
          "uid": "kswenson@us.fujitsu.com"
        },
        {
          "name": "Alex Demo",
          "uid": "alex@kswenson.oib.com"
        }
      ],
      "requirements": "you must 18 or older"
    };

*/
%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.roleInfo = <%roleInfo.write(out,2,4);%>;
    $scope.isNew = <%=isNew%>;
    $scope.allPeople = <%allPeople.write(out,2,4);%>;
    $scope.colors = ["pink","yellow","white","lightgreen","magenta","bisque","red","cyan"];
    $scope.newPlayer = "";

    $scope.showInput = false;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        var exception = serverErr.exception;
        $scope.errorMsg = exception.msgs.join();
        $scope.errorTrace = exception.stack;
        $scope.showError=true;
        $scope.showTrace = false;
    };

    $scope.updateRole = function() {
        var key = $scope.roleInfo.name;
        var postURL = "roleUpdate.json?op=Update";
        if ($scope.isNew) {
            postURL = "roleUpdate.json?op=Create";
        };
        var postdata = angular.toJson($scope.roleInfo);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            if ($scope.isNew) {
                window.location="EditRole.htm?roleName="+data.name;
            }
            $scope.roleInfo = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.getPeople = function(filter) {
        var lcfilter = filter.toLowerCase();
        var res = [];
        var last = $scope.allPeople.length;
        for (var i=0; i<last; i++) {
            var rec = $scope.allPeople[i];
            if (rec.name.toLowerCase().indexOf(lcfilter)>=0) {
                res.push(rec);
            }
        }
        return res;
    }
    $scope.addPlayer = function() {
        var found = false;
        var player = $scope.newPlayer;
        if (typeof player == "string") {
            var pos = player.lastIndexOf(" ");
            var name = player.substring(0,pos).trim();
            var uid = player.substring(pos).trim();
            player = {name: name, uid: uid};
        }
        $scope.roleInfo.players.map( function(one) {
            if (player.uid == one.uid) {
                found = true;
            }
        });
        if (!found) {
            $scope.roleInfo.players.push(player);
        }
        $scope.newPlayer = "";
    }
    $scope.removePlayer = function(player) {
        var res = [];
        $scope.roleInfo.players.map( function(one) {
            if (player.uid != one.uid) {
                res.push(one);
            }
        });
        $scope.roleInfo.players = res;
    }
    $scope.bestPart = function(rec) {
        var name = rec.name;
        if (name) {
            return name;
        }
        return rec.uid;
    }
});

</script>

<div class="content tab03" style="display:block;" ng-app="myApp" ng-controller="myCtrl">
    <div class="section_body">
        <div style="height:10px;"></div>

        <div id="ErrorPanel" style="border:2px solid red;display=none;background:LightYellow;margin:10px;" ng-show="showError" ng-cloak>
            <div class="generalSettings">
                <table>
                    <tr>
                        <td class="gridTableColummHeader">Error:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">{{errorMsg}}</td>
                    </tr>
                    <tr ng-show="showTrace">
                        <td class="gridTableColummHeader">Trace:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">{{errorTrace}}</td>
                    </tr>
                    <tr ng-hide="showTrace">
                        <td class="gridTableColummHeader">Trace:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2"><button ng-click="showTrace=true">Show The Trace</button></td>
                    </tr>
                </table>
            </div>
        </div>

        <div class="generalHeading"><span ng-show="isNew">Create New Role</span><span ng-hide="isNew">Edit Role: {{roleInfo.name}}</span>
        </div>

            <table width="100%">
                <tr><td style="height:10px" colspan="3"></td></tr>
                <tr>
                    <td class="gridTableColummHeader">Name:</td>
                    <td style="width:20px;"></td>
                    <td>
                       <% if (isNew) { %>
                       <input ng-model="roleInfo.name" class="form-control">
                       <% } else { %>
                       <button class="btn btn-sm" style="background-color:{{roleInfo.color}};"><%ar.writeHtml(roleName);%></button>
                       <% } %>
                    </td>
                    <td align="right">
                       <div class="dropdown" style="float: right;">
                            <b>Color:</b>
                            <button class="btn btn-default dropdown-toggle" type="button" id="menu2"
                                data-toggle="dropdown" style="background-color:{{roleInfo.color}};">
                            {{roleInfo.color}} <span class="caret"></span></button>
                            <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
                                <li role="presentation" ng-repeat="color in colors">
                                    <a role="menuitem" style="background-color:{{color}};"
                                    href="#"  ng-click="roleInfo.color=color">{{color}}</a></li>
                            </ul>
                        </div>
                    </td>
                    <td style="width:30px;"></td>
                </tr>
                <tr><td style="height:10px" colspan="3"></td></tr>
                <tr>
                    <td class="gridTableColummHeader">Players:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2">
                      <span class="dropdown" ng-repeat="player in roleInfo.players">
                        <button class="btn btn-sm dropdown-toggle" type="button" id="menu1"
                           data-toggle="dropdown" style="margin:2px;padding: 2px 5px;font-size: 11px;">
                           {{bestPart(player)}}</button>
                        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                           <li role="presentation"><a role="menuitem" title="{{player}}"
                              ng-click="removePlayer(player)">Remove Player:<br/>{{player.name}}<br/>{{player.uid}}</a></li>
                        </ul>
                      </span>
                      <span >
                        <button class="btn btn-sm btn-primary" ng-click="showAddPlayer=!showAddPlayer"
                            style="margin:2px;padding: 2px 5px;font-size: 11px;">+</button>
                      </span>
                    </td>
                    <td style="width:30px;"></td>
                </tr>
                <tr><td style="height:8px" colspan="3"></td></tr>
                <tr ng-show="showAddPlayer">
                    <td ></td>
                    <td style="width:20px;"></td>
                    <td  colspan="2" class="form-inline form-group">
                        <button ng-click="addPlayer(newPlayer);showAddPlayer=false" class="form-control btn btn-primary">
                            Add </button>
                        <input type="text" ng-model="newPlayer"  class="form-control"
                            placeholder="Enter Email Address" style="width:250px;"
                            typeahead="person as person.name for person in getPeople($viewValue) | limitTo:8">
                    </td>
                    <td style="width:30px;"></td>
                </tr>
                <tr><td style="height:8px" colspan="3"></td></tr>
                <tr>
                     <td class="gridTableColummHeader">Description:</td>
                     <td style="width:20px;"></td>
                     <td colspan="2"><textarea ng-model="roleInfo.description" placeholder="Enter Description of Role"
                         class="form-control" style="height:150px;"></textarea></td>
                    <td style="width:30px;"></td>
                </tr>
                <tr><td style="height:8px" colspan="3"></td></tr>
                <tr>
                     <td class="gridTableColummHeader">Eligibility:</td>
                     <td style="width:20px;"></td>
                     <td colspan="2"><textarea ng-model="roleInfo.requirements" placeholder="Enter Eligibility Requirements"
                         style="height:150px;" class="form-control"></textarea></td>
                    <td style="width:30px;"></td>
                </tr>
                <tr><td style="height:24px" colspan="3"></td></tr>
                <tr>
                     <td class="gridTableColummHeader"></td>
                     <td style="width:20px;"></td>
                     <td colspan="2"><button ng-click="updateRole()" class="btn btn-primary">Save Changes</button>
                         &nbsp; &nbsp; &nbsp;
                         <button ng-click="deleteRole()" class="btn btn-primary">Delete Role</button>
                     </td>
                    <td style="width:30px;"></td>
                </tr>
            </table>

        <div style="height:50px;"></div>
        <div class="generalHeadingBorderLess">Players of Role '<%ar.writeHtml(roleName);%>'</div>
        <div class="generalContent">
            <table class="gridTable2" width="600px;">
            <tr ng-repeat="player in roleInfo.players">
                <td>{{player.name}}</td><td>{{player.uid}}</td>
            </tr>
            </table>
        </div>
        <div class="generalHeadingBorderLess">Expanded List of Players of Role '<%ar.writeHtml(roleName);%>'</div>
        <div class="generalContent">
            <table class="gridTable2" width="600px;">
            <tr ng-repeat="player in roleInfo.expandedPlayers">
                <td>{{player.name}}</td><td>{{player.uid}}</td>
            </tr>
            </table>
        </div>
    </div>
</div>