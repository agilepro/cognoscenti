<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.RoleRequestRecord"
%><%@page import="com.purplehillsbooks.weaver.SuperAdminLogFile"
%><%@page import="com.purplehillsbooks.weaver.mail.EmailListener"
%><%@page import="java.util.Date"
%>
<%
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    ar.assertLoggedIn("Must be logged in to set your personal settings");
    NGBook site = ngw.getSite();

    UserProfile uProf = ar.getUserProfile();
    Date date = new Date(ar.getSuperAdminLogFile().getLastNotificationSentTime());
    
    List<WorkspaceRole> roles = ngw.getWorkspaceRoles();
    
    SiteUsers siteUsers = site.getUserMap();

    JSONArray roleList = new JSONArray();
    for (WorkspaceRole crole : roles) {
        JSONObject jObj = crole.getJSON();
        jObj.put("player", crole.isPlayer(uProf));
        RoleRequestRecord rrr = ngw.getRoleRequestRecord(crole.getName(),uProf.getUniversalId());
        jObj.put("reqPending", (rrr!=null && !rrr.isCompleted()));
        roleList.put(jObj);
    }
    
    JSONObject personalSettings = ngw.getPersonalWorkspaceSettings(uProf);
    /*new JSONObject();
    personalSettings.put("isWatching", uProf.isWatch(siteId+"|"+pageId));
    personalSettings.put("reviewTime", uProf.watchTime(siteId+"|"+pageId));
    personalSettings.put("isNotify", uProf.isNotifiedForProject(siteId+"|"+pageId));
    personalSettings.put("isMute", ngw.getMuteRole().isPlayer(uProf));*/

%>
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
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
        "isWatching": {
            "title": "Watch workspace",
            "type": "boolean",
            "help": "When you watch a workspace it means simply that that workspace name will appear in the list of \"Watched Workspaces\" on your personal home page.\n\nYou can add and remove workspaces from the list at any time with immediate effect. Performing some operations in the workspace (such as creating a discussion) will automatically add the workspace to your watched list."
        },  
        "isNotify": {
            "title": "Digest",
            "type": "boolean",
            "help": "If you request to receive the digest of changes, then a summary of the changes to this workspace will be included in the period email (daily, weekly, or monthly) that you receive. Set the notification period in your personal settings. "
        },
        "isMute": {
            "title": "Mute Emails",
            "type": "boolean",
            "help": "Normally all members will receive an email when a new discussion is created. This option allows you to disable that so that you will not receive any email when a new discussion is created."
        }
    };
    $scope.propertyOrder = [
        "isWatching",
        "isNotify",
        "isMute"
    ]
});

</script>



<div>

<%@include file="ErrorPanel.jsp"%>
    <div class="container-fluid override mx-4">
        <p>These settings are for user "<%=uProf.getName()%>":</p>
        <div class="d-flex col-12 m-2">
            <div class="col-7 ms-3">
                    <div class="row my-3" ng-repeat="key in propertyOrder">
                        <span class="col-lg-3" >
                        <b>{{metadata[key].title}}:</b></span>
                        <span class="col-1">
                            <button class="btn-sm" ng-show="pSettings[key]" ng-click="toggle(key)"><i class="fa fa-check-square-o"></i></button>
                            <button class="btn-sm" ng-hide="pSettings[key]"  ng-click="toggle(key)"><i class="fa fa-square-o"></i></button>
                        </span>
                        <span class="col-3" ng-hide="exposed[key]">
                        <button class="btn-sm" ng-click="exposed[key]=!exposed[key]">?</button>
                        </span>
                        <span class="col-7-auto pe-3" ng-show="exposed[key]" ng-click="exposed[key]=!exposed[key]">
                        <div class="guideVocal">
                        {{metadata[key].help}}
                        </div>
                        </span>
                    </div>
                </div>
            <div class="col-4">
                <div class="well col-10">
    
    <div>User = <%=uProf.getName()%></div>
    <div>Key = <%=uProf.getKey()%></div>
    <div>Roles<br/>
    <%
        for (NGRole role : ngw.findRolesOfPlayer(uProf)) {
            
            %>* <%=role.getName()%>  update: <%=role.allowUpdateWorkspace()%><br/><%
        }
    %>
    </div>
    <div>AR Update = <%=ar.canUpdateWorkspace()%></div>
    <div>Workspace Update = <%=ngw.canUpdateWorkspace(uProf)%></div>
    <div>Site Read Only = <%=site.isUnpaidUser(uProf.getUniversalId())%></div>
    <div>Site Read Only = <%=siteUsers.isReadOnly(uProf)%></div>
    
                </div>
            </div>
        </div>
    </div>

    <div style="height:100px"></div>

</div>