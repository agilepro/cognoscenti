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
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    ar.assertLoggedIn("Must be logged in to set your personal settings");
    NGBook site = ngp.getSite();

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

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Workspace Personal Settings");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.pSettings = {};
    $scope.pSettings.isWatching = <%=uProf.isWatch(siteId+"|"+pageId)%>;
    $scope.pSettings.reviewTime = <%=uProf.watchTime(siteId+"|"+pageId)%>;
    $scope.pSettings.isTemplate = <%=uProf.isTemplate(siteId+"|"+pageId)%>;
    $scope.pSettings.isNotify   = <%=uProf.isNotifiedForProject(siteId+"|"+pageId)%>;
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
        console.log("POST", postURL, data);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            console.log("RESPONSE", data);
            $scope.pSettings = data;
            if ("SetEmailMute" == op) {
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
                    <button ng-show="pSettings.isWatching" class="btn " ng-click="userOp('ClearWatch')"><i class="fa  fa-check-square-o"></i> Watch List</button>
                    <button ng-hide="pSettings.isWatching" class="btn " ng-click="userOp('SetWatch')"><i class="fa  fa-square-o"></i> Watch List</button>
                </td>
                <td ng-hide="openWatch">
                    <button class="btn" ng-click="openWatch=!openWatch">?</button>
                </td>
                <td ng-show="openWatch" ng-click="openWatch=!openWatch" >
                  <div class="guideVocal">
                    <span ng-hide="pSettings.isWatching"><b>You are not watching this workspace</b></span>
                    <span ng-show="pSettings.isWatching"><b>You are watching this workspace</b></span>
                    <br/>
                    <br/>
                    Watching a workspace means simply that that workspace name
                    will appear in the list of "<b>Watched Workspaces</b>" on your personal home page.<br/>
                    <br/>
                    You can add and remove workspaces from the list at any time with immediate effect.  
                    Performing some operations in the workspace (such as creating a discussion topic) 
                    will automatically add the workspace to your watched list.
                    <br/>
                    Every time you review the workspace, you can mark it as having been 
                    reviewed at the current date and time.
                  </div>
                </td>
            </tr>
            <tr ng-show="pSettings.isWatching">
                <td><b>Last Reviewed:</b></td>
                <td>
                    <span class="btn">{{pSettings.reviewTime | date}}</span>
                    <button class="btn " ng-click="userOp('SetReviewTime')">Reset Review Time</button>
                </td>
                <td ng-hide="openReview">
                    <button class="btn" ng-click="openReview=true">?</button>
                </td>
                <td ng-show="openReview" ng-click="openReview=false" >
                  <div class="guideVocal">
                    If you are watching this workspace, you can also keep track of 
                    the last time you reviewed the workspace.
                    Every time you review the workspace, you can mark it as having been 
                    reviewed at the current date and time.
                  </div>
                </td>
            </tr>            <tr>
                <td><b>Template:</b></td>
                <td>
                    <button ng-show="pSettings.isTemplate" class="btn" ng-click="userOp('ClearTemplate')"><i class="fa  fa-check-square-o"></i> Template</button>
                    <button ng-hide="pSettings.isTemplate" class="btn" ng-click="userOp('SetTemplate')"><i class="fa  fa-square-o"></i> Template</button>
                </td>
                <td ng-hide="openTemplate">
                    <button class="btn" ng-click="openTemplate=!openTemplate">?</button>
                </td>
                <td ng-show="openTemplate" ng-click="openTemplate=!openTemplate">
                  <div class="guideVocal">
                    <span ng-hide="pSettings.isTemplate"><b>This workspace is not one of your templates</b></span>
                    <span ng-show="pSettings.isTemplate"><b>This workspace is one of your templates</b></span>
                    <br/>
                    <br/>
                    A template workspace is used at the time that you create a new workspace, 
                    and all of the roles and action items will be copied from the template to the 
                    newly created workspace (but without any users assigned to them).  
                    List your templates by choosing "Workspaces &gt; Templates" from the 
                    navigation bar at the top of the screen. 
                  </div>
                </td>
            </tr>
            <tr>
                <td><b>Digest:</b></td>
                <td>
                    <button ng-show="pSettings.isNotify" class="btn" ng-click="userOp('ClearNotify')"><i class="fa  fa-check-square-o"></i>
                    Receive Digest</button>
                    <button ng-hide="pSettings.isNotify" class="btn" ng-click="userOp('SetNotify')"><i class="fa  fa-square-o"></i> 
                    Receive Digest</button>
                </td>
                <td ng-hide="openNotify">
                    <button class="btn" ng-click="openNotify=!openNotify">?</button>
                </td>
                <td ng-show="openNotify" ng-click="openNotify=!openNotify">
                  <div class="guideVocal">
                    <span ng-hide="pSettings.isNotify"><b>You are not receiving the digest for this workspace</b></span>
                    <span ng-show="pSettings.isNotify"><b>You are receiving the digest for this workspace</b></span>
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