<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="include.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.CustomRole"
%><%@page import="org.socialbiz.cog.RoleRequestRecord"
%><%@page import="org.socialbiz.cog.SuperAdminLogFile"
%><%@page import="org.socialbiz.cog.EmailListener"
%><%@page import="java.util.Date"
%>
<%
    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    ar.assertLoggedIn("Must be logged in to set your personal settings");

    UserProfile uProf = ar.getUserProfile();
    Date date = new Date(ar.getSuperAdminLogFile().getLastNotificationSentTime());
    List<CustomRole> roles = ngp.getAllRoles();

    JSONArray roleList = new JSONArray();
    for (CustomRole crole : roles) {
        JSONObject jObj = crole.getJSON();
        jObj.put("player", crole.isPlayer(uProf));
        RoleRequestRecord rrr = ngp.getRoleRequestRecord(crole.getName(),uProf.getUniversalId());
        jObj.put("reqPending", (rrr!=null && !rrr.isCompleted()));
        roleList.put(jObj);
    }

%>
<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Workspace Personal Settings");
    $scope.isWatching = <%=uProf.isWatch(pageId)%>;
    $scope.watchTime  = <%=uProf.watchTime(pageId)%>;
    $scope.isTemplate = <%=uProf.isTemplate(pageId)%>;
    $scope.isNotify   = <%=uProf.isNotifiedForProject(pageId)%>;
    $scope.isMute     = <%=ngp.getMuteRole().isPlayer(uProf)%>;
    $scope.roleList   = <%roleList.write(out,2,4);%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.userOp = function(op) {
        var data = {};
        data.op = op;
        var postURL = "personalUpdate.json";
        var postdata = angular.toJson(data);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            if ("SetWatch" == op) {
                $scope.isWatching = true;
            }
            else if ("ClearWatch" == op) {
                $scope.isWatching = false;
            }
            else if ("SetTemplate" == op) {
                $scope.isTemplate = true;
            }
            else if ("ClearTemplate" == op) {
                $scope.isTemplate = false;
            }
            else if ("SetNotify" == op) {
                $scope.isNotify = true;
            }
            else if ("ClearNotify" == op) {
                $scope.isNotify = false;
            }
            else if ("SetEmailMute" == op) {
                $scope.isMute = true;
            }
            else if ("ClearEmailMute" == op) {
                $scope.isMute = false;
            }
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.rolePlayer = function() {
        var res = [];
        for (var i=0; i<$scope.roleList.length; i++) {
            var role = $scope.roleList[i];
            if (role.player) {
                res.push(role);
            }
        }
        return res;
    };
    $scope.rolePending = function() {
        var res = [];
        for (var i=0; i<$scope.roleList.length; i++) {
            var role = $scope.roleList[i];
            if (!role.player && role.reqPending) {
                res.push(role);
            }
        }
        return res;
    };
    $scope.roleNonPlayer = function() {
        var res = [];
        for (var i=0; i<$scope.roleList.length; i++) {
            var role = $scope.roleList[i];
            if (!role.player && !role.reqPending) {
                res.push(role);
            }
        }
        return res;
    };

    $scope.roleChange = function(role, op) {
        var data = {};
        data.op = op;
        data.roleId = role.name;
        var postURL = "rolePlayerUpdate.json";
        var postdata = angular.toJson(data);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            role.reqPending = data.reqPending;
            role.player = data.player;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
});

</script>

<style>
.spacey {
}
.spacey tr td {
    padding:10px;
}
.btn {
    margin:0px;
}
.guideVocal {
    margin:0px;
}
</style>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalSubHeading" style="height:40px">
        Personal Settings
    </div>
<div class="btn-toolbar primary-toolbar">
  <a class="btn btn-default btn-raised" href="emailSent.htm?f=<%ar.writeURLData(uProf.getPreferredEmail());%>">
    <i class="fa fa-list-alt material-icons"></i> View Emails</a>
</div>

        <table class="table">
            <col width="150px">
            <col width="250px">
            <col width="400px">
            <tr>
                <td><b>Watch workspace:</b></td>
                <td>
                    <button ng-show="isWatching" class="btn " ng-click="userOp('ClearWatch')"><i class="fa  fa-check-square-o"></i> Watch List</button>
                    <button ng-show="isWatching" class="btn " ng-click="userOp('SetWatch')">Reset Watch Time</button>
                    <button ng-hide="isWatching" class="btn " ng-click="userOp('SetWatch')"><i class="fa  fa-square-o"></i> Watch List</button>
                </td>
                <td ng-hide="openWatch">
                    <button class="btn" ng-click="openWatch=!openWatch">?</button>
                </td>
                <td ng-show="openWatch" ng-click="openWatch=!openWatch" >
                  <div class="guideVocal">
                    <span ng-hide="isWatching"><b>You are not watching this workspace</b></span>
                    <span ng-show="isWatching"><b>You are watching this workspace</b></span>
                    <br/>
                    <br/>
                    In order to view your recent &amp; selected modified projects list at a glance from your
                    profile's homepage, you can simply click the "<b>Start Watching</b>" button and the workspace name
                    will appear in the list of "<b>Watched Workspaces</b>" under homepage.<br/>
                    <br/>
                    And in future if you do not want that workspace to appear in watched workspace list you can stop
                    watching that workspace immediately.
                  </div>
                </td>
            </tr>
            <tr>
                <td><b>Template:</b></td>
                <td>
                    <button ng-show="isTemplate" class="btn" ng-click="userOp('ClearTemplate')"><i class="fa  fa-check-square-o"></i> Template</button>
                    <button ng-hide="isTemplate" class="btn" ng-click="userOp('SetTemplate')"><i class="fa  fa-square-o"></i> Template</button>
                </td>
                <td ng-hide="openTemplate">
                    <button class="btn" ng-click="openTemplate=!openTemplate">?</button>
                </td>
                <td ng-show="openTemplate" ng-click="openTemplate=!openTemplate">
                  <div class="guideVocal">
                    <span ng-hide="isTemplate"><b>This workspace is not one of your template</b></span>
                    <span ng-show="isTemplate"><b>This workspace is one of your template</b></span>
                    <br/>
                    <br/>
                    You can use this workspace as template for your future reference. If you mark this
                    workspace as template then it will appear in the "List of Templates" in your profile's
                    workspace page. At any time you can even stop using this workspace as template.
                  </div>
                </td>
            </tr>
            <tr>
                <td><b>Digest:</b></td>
                <td>
                    <button ng-show="isNotify" class="btn" ng-click="userOp('ClearNotify')"><i class="fa  fa-check-square-o"></i>
                    Receive Digest</button>
                    <button ng-hide="isNotify" class="btn" ng-click="userOp('SetNotify')"><i class="fa  fa-square-o"></i> 
                    Receive Digest</button>
                </td>
                <td ng-hide="openNotify">
                    <button class="btn" ng-click="openNotify=!openNotify">?</button>
                </td>
                <td ng-show="openNotify" ng-click="openNotify=!openNotify">
                  <div class="guideVocal">
                    <span ng-hide="isNotify"><b>You are not receiving the digest for this workspace</b></span>
                    <span ng-show="isNotify"><b>You are receiving the digest for this workspace</b></span>
                    <br/>
                    <br/>
                    If you request to receive the digest of changes, then a summary of the changes to this workspace will
                    be included in the period email (daily, weekly, or monthly) that you receive.  Set the notification period in your personal settings.
                   </div>
                </td>
            </tr>
            <tr>
                <td><b>Mute Emails:</b></td>
                <td>
                    <button ng-show="isMute" class="btn" ng-click="userOp('ClearEmailMute')"><i class="fa  fa-check-square-o"></i>
                    Mute Email Notifications</button>
                    <button ng-hide="isMute" class="btn" ng-click="userOp('SetEmailMute')"><i class="fa  fa-square-o"></i> 
                    Mute Email Notifications</button>
                </td>
                <td ng-hide="openMute">
                    <button class="btn" ng-click="openMute=!openMute">?</button>
                </td>
                <td ng-show="openMute" ng-click="openMute=!openMute">
                  <div class="guideVocal">
                    <span ng-hide="isMute"><b>You will receive email notification when new Topics are created</b></span>
                    <span ng-show="isMute"><b>You will not receive email notification when new Topics are created</b></span>
                    <br/>
                    <br/>
                    Normally all members will receive an email when a new topic is created.  
                    This option allows you to disable that so that you will not receive any email
                    when a new discussion topic is created.
                  </div>
                </td>
            </tr>
        </table>


        <table class="table" style="margin-top:50px;">
            <col width="150px"/>
            <col width="60px"/>
            <col width="60px"/>
            <col width="60px"/>
            <col width="60px"/>
            <col width="400px"/>
            <tr>
                <th>
                    Roles in Workspace
                </th>
                <th style="width:60px;text-align:center">
                    Playing
                </th>
                <th style="width:60px;text-align:center">
                    Pending
                </th>
                <th style="width:60px;text-align:center">
                    Not Playing
                </th>
                <th style="width:60px;text-align:center">
                </th>
                <th>
                    Role Description
                </th>
            </tr>
            <tr ng-repeat="role in roleList">
                <td>
                    <button class="labelButton" style="background-color:{{role.color}};">{{role.name}}</button>
                </td>
                <td style="width:60px;text-align:center">
                    <span ng-show="role.player"><i class="fa  fa-check-square-o"></i></span>
                    <span ng-hide="role.player"><i class="fa  fa-square-o"></i></span>
                </td>
                <td style="width:60px;text-align:center">
                    <span ng-show="!role.player && role.reqPending"><i class="fa  fa-check-square-o"></i></span>
                    <span ng-hide="!role.player && role.reqPending"><i class="fa  fa-square-o"></i></span>
                </td>
                <td style="width:60px;text-align:center">
                    <span ng-show="!role.player && !role.reqPending"><i class="fa  fa-check-square-o"></i></span>
                    <span ng-hide="!role.player && !role.reqPending"><i class="fa  fa-square-o"></i></span>
                </td>
                <td style="width:60px;text-align:center">
                    <button class="btn btn-primary btn-raised" ng-hide="role.player || role.reqPending" ng-click="roleChange(role, 'Join')">Join</button>
                    <button class="btn btn-primary btn-raised" ng-show="role.player || role.reqPending" ng-click="roleChange(role, 'Leave')">Leave</button>
                </td>
                <td>
                    <div ng-hide="role.show">
                        <button class="btn" ng-click="role.show=!role.show">?</button>
                    </div>
                    <div ng-show="role.show"  ng-click="role.show=!role.show">
                      <div class="guideVocal">
                        <b>Description</b><br/>
                        {{role.description}}
                        <br/>
                        <br/>
                        <b>Requirements</b><br/>
                        {{role.requirements}}
                      </div>
                    </div>
                </td>
           </tr>
        </table>
    <div style="height:100px"></div>

</div>