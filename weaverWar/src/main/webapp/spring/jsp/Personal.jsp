<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="include.jsp"
%><%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@page import="com.purplehillsbooks.weaver.CustomRole"
%><%@page import="com.purplehillsbooks.weaver.RoleRequestRecord"
%><%@page import="com.purplehillsbooks.weaver.SuperAdminLogFile"
%><%@page import="com.purplehillsbooks.weaver.EmailListener"
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
    
    JSONObject personalSettings = ngp.getPersonalWorkspaceSettings(uProf);
    /*new JSONObject();
    personalSettings.put("isWatching", uProf.isWatch(siteId+"|"+pageId));
    personalSettings.put("reviewTime", uProf.watchTime(siteId+"|"+pageId));
    personalSettings.put("isTemplate", uProf.isTemplate(siteId+"|"+pageId));
    personalSettings.put("isNotify", uProf.isNotifiedForProject(siteId+"|"+pageId));
    personalSettings.put("isMute", ngp.getMuteRole().isPlayer(uProf));*/

%>
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Workspace Personal Settings");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.pSettings = <%personalSettings.write(out,2,4);%>;
    $scope.roleList   = <%roleList.write(out,2,4);%>;
    $scope.preferred  = "<%=uProf.getPreferredEmail()%>"
    
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.setPersonal = function(op) {
        var data = {};
        data[op] = $scope.pSettings[op];
        var postURL = "setPersonal.json";
        var postdata = angular.toJson(data);
        console.log("POST", postURL, data);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            console.log("RESPONSE", data);
            $scope.pSettings = data;
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

    $scope.toggle = function(key) {
        var item = $scope.metadata[key];
        if ("boolean"==item.type) {
            $scope.pSettings[key] = !$scope.pSettings[key];
            $scope.setPersonal(key);
        }
    }
    $scope.metadata = {
        "isMute": {
            "title": "Mute Emails",
            "type": "boolean",
            "help": "Normally all members will receive an email when a new topic is created. This option allows you to disable that so that you will not receive any email when a new discussion topic is created."
        },
        "isTemplate": {
            "title": "Template",
            "type": "boolean",
            "help": "A template workspace is used at the time that you create a new workspace, and all of the roles and action items will be copied from the template to the newly created workspace (but without any users assigned to them). List your templates by choosing \"Workspaces > Templates\" from the navigation bar at the top of the screen. "
        },
        "isNotify": {
            "title": "Digest",
            "type": "boolean",
            "help": "If you request to receive the digest of changes, then a summary of the changes to this workspace will be included in the period email (daily, weekly, or monthly) that you receive. Set the notification period in your personal settings. "
        },
        "isWatching": {
            "title": "Watch workspace",
            "type": "boolean",
            "help": "When you watch a workspace it means simply that that workspace name will appear in the list of \"Watched Workspaces\" on your personal home page.\n\nYou can add and remove workspaces from the list at any time with immediate effect. Performing some operations in the workspace (such as creating a discussion topic) will automatically add the workspace to your watched list."
        }         
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

<div>

<%@include file="ErrorPanel.jsp"%>

    <div class="generalSubHeading" style="height:40px">
        Personal Settings
    </div>
<div class="btn-toolbar primary-toolbar">
  <a class="btn btn-default btn-raised" href="EmailSent.htm?f={{preferred}}">
    <i class="fa fa-list-alt material-icons"></i> View Emails</a>
</div>

        <table class="table">
            <col width="150px">
            <col width="50px">
            <col width="400px">
            <tr ng-repeat="(key,item) in metadata">
                <td><b>{{item.title}}:</b></td>
                <td>
                    <button ng-show="pSettings[key]" class="btn" ng-click="toggle(key)"><i class="fa  fa-check-square-o"></i></button>
                    <button ng-hide="pSettings[key]" class="btn" ng-click="toggle(key)"><i class="fa  fa-square-o"></i></button>
                </td>
                <td ng-hide="exposed[key]">
                    <button class="btn" ng-click="exposed[key]=!exposed[key]">?</button>
                </td>
                <td ng-show="exposed[key]" ng-click="exposed[key]=!exposed[key]">
                  <div class="guideVocal">
                  {{item.help}}
                  </div>
                </td>
            </tr>
            
        </table>


    <div style="height:100px"></div>

</div>