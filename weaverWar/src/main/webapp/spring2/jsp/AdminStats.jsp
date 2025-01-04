<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.mail.EmailGenerator"
%><%@page import="com.purplehillsbooks.weaver.CommentRecord"
%><%@page import="com.purplehillsbooks.weaver.mail.ScheduledNotification"
%><%@page import="com.purplehillsbooks.weaver.WorkspaceStats"
%><%@page import="com.purplehillsbooks.weaver.util.NameCounter"
%><%@page import="java.util.ArrayList"
%>
<%
    ar.assertLoggedIn("Must be logged in to see admin options");
    ar.assertAccessWorkspace("This VIEW only for members in use cases");

    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    NGPageIndex ngpi = ar.getCogInstance().getWSBySiteAndKey(siteId,pageId);
    NGWorkspace ngw  = ngpi.getWorkspace();
    ar.setPageAccessLevels(ngw);
    NGBook site = ngw.getSite();
    boolean showExperimental = site.getShowExperimental();
    Cognoscenti cog = ar.getCogInstance();

    UserProfile up = ar.getUserProfile();
    String userKey = up.getKey();
    SiteUsers userMap = site.getUserMap();

    List<String> names = ngw.getContainerNames();

    String parentKey = ngw.getParentKey();
    NGPageIndex parentIndex = cog.getWSByCombinedKey(parentKey);
    JSONObject parentWorkspace = new JSONObject();
    if (parentIndex!=null) {
        parentWorkspace = parentIndex.getJSON4List();
    }

    JSONObject workspaceConfig = ngw.getConfigJSON();

    JSONArray allWorkspaces = new JSONArray();
    for (NGPageIndex ngpis : cog.getNonDelWorkspacesInSite(site.getKey())) {
        if (ngpis.isDeleted) {
            continue;
        }
        allWorkspaces.put(ngpis.getJSON4List());
    }
    UserManager userManager = UserManager.getStaticUserManager();
    WorkspaceStats wStats = new WorkspaceStats();
    wStats.gatherFromWorkspace(ngw);
    wStats.countUsers(ngw.getSite().getUserMap());
    JSONObject statsObj = wStats.getJSON();
    
    JSONObject allUsers = statsObj.getJSONObject("anythingPerUser");
    JSONObject accessStatus = new JSONObject();
    for (String aUser : allUsers.keySet()) {
        UserProfile aUserProf = userManager.lookupUserByAnyId(aUser);
        if (aUserProf == null) {
            accessStatus.put(aUser, "No Profile");
            continue;
        }
        
        if (ar.isSuperAdmin(aUserProf.getKey())) {
            accessStatus.put(aUser, "Super");
        }
        else if (site.userReadOnly(aUser)) {
            accessStatus.put(aUser, "Site R/O");
        }
        else if (ngw.canUpdateWorkspace(aUserProf)) {
            accessStatus.put(aUser, "Can Edit");
        }
        else if (ngw.canAccessWorkspace(aUserProf)) {
            accessStatus.put(aUser, "Observer");
        }
        else {
            accessStatus.put(aUser, "No Access");
        }
    }
    statsObj.put("access", accessStatus);
    

    boolean foundInRecents = false;

    int barPos = parentKey.indexOf("|");
    if (barPos>=0) {
        parentKey = parentKey.substring(barPos+1);
    }
    List<NGPageIndex> allWS = cog.getNonDelWorkspacesInSite(siteId);
    JSONArray recentWorkspaces = new JSONArray();
    for (NGPageIndex sibling : allWS) {
        if (sibling.containerKey.equals(pageId)) {
            continue;  //skip adding this page into possible parents list
        }
        recentWorkspaces.put(sibling.getJSON4List());
    }
    
    JSONObject nextActionDate = new JSONObject();
    for (NGPageIndex p : ar.getCogInstance().getAllContainers()) {
        if (p.nextScheduledAction>0 && p.nextScheduledAction<ar.nowTime) {
            nextActionDate.put(p.containerName, p.nextScheduledAction);
        }
    }


    /*
    Data from the server is the workspace config structure
    {
      "accessState": "Live",
      "allNames": ["Darwin2"],
      "deleted": false,
      "frozen": false,
      "goal": "",
      "pageKey": "darwin2",
      "parentKey": "",
      "projectMail": "",
      "purpose": "",
      "showExperimental": false,
      "site": "goofoof"
    }
    */

%>

<fmt:setBundle basename="messages"/>
<script type="text/javascript" language="JavaScript">

tagsInputWorkspacePicker  ={
    "placeholder":"Enter workspace name",
    "display-property":"name",
    "key-property":"pageKey",
    "replace-spaces-with-dashes":"false",
    "add-on-space":true,
    "on-tag-added":"updatePlayers()",
    "on-tag-removed":"updatePlayers()",
    "maxTags":1,
    "freeInput":false
}

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Workspace Statistics");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.siteStats = <%site.getStatsJSON(cog).write(out,2,4);%>;
    $scope.workspaceInfo = <%ngpi.getJSON4List().write(out,2,4);%>;
    $scope.workspaceConfig = <%workspaceConfig.write(out,2,4);%>;
    $scope.newName = $scope.workspaceConfig.allNames[0];
    $scope.editName = false;
    $scope.editInfo = false;
    $scope.stats = <%statsObj.write(out,2,4);%>;
    $scope.nextActionDate = <%nextActionDate.write(out,2,4);%>;
    $scope.userFilter = "";

    $scope.allWorkspaces = <%allWorkspaces.write(out,2,4);%>;
    $scope.recentWorkspaces = <%recentWorkspaces.write(out,2,4);%>;
    $scope.parentFilter = "";

    //the object form of the parent workspace
    $scope.parentWorkspace = <%parentWorkspace.write(out,2,4);%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        console.log("Error: ",serverErr);
        errorPanelHandler($scope, serverErr);
    };

    $scope.lookUpName = function(prjKey) {
        for (var i=0; i<$scope.allWorkspaces.length; i++) {
            if ($scope.allWorkspaces[i].pageKey==prjKey) {
                return $scope.allWorkspaces[i].name;
            }
        }
        return "(unknown)";
    }
    $scope.projectMode = function() {
        if ($scope.workspaceConfig.deleted) {
            return "deletedMode";
        }
        if ($scope.workspaceConfig.frozen) {
            return "freezedMode";
        }
        return "normalMode";
    }
    $scope.setEdit = function(fieldName) {
        if (<%=ar.isAdmin()%>) {
            $scope.isEditing = fieldName;
        }
        else {
            $scope.isEditing = null;
            console.log("Non-admin not allowed to edit.")
        }
    }
    $scope.generateTheHtmlValues = function() {
        $scope.purposeHtml = convertMarkdownToHtml($scope.workspaceConfig.purpose);
        $scope.visionHtml  = convertMarkdownToHtml($scope.workspaceConfig.vision);
        $scope.missionHtml = convertMarkdownToHtml($scope.workspaceConfig.mission);
        $scope.domainHtml  = convertMarkdownToHtml($scope.workspaceConfig.domain);
    }
    $scope.generateTheHtmlValues();
    $scope.saveOneField = function(fieldName) {
        var newData = {};
        newData[fieldName] = $scope.workspaceConfig[fieldName];
        $scope.saveRecord(newData);
        $scope.isEditing = null;
    }
    $scope.deleteParentKey = function() {
        $scope.saveParentKey({pageKey:"$delete$"})
    }
    $scope.saveParentKey = function(workspace) {
        $scope.workspaceConfig.parentKey = workspace.pageKey;
        $scope.parentWorkspace = workspace;
        $scope.parentFilter = "";
        $scope.saveOneField(['parentKey']);
    }
    $scope.clearField = function(fieldName) {
        var newData = {};
        newData[fieldName] = "";
        $scope.saveRecord(newData);
        $scope.isEditing = null;
    }
    $scope.saveProjectConfig = function() {
        $scope.saveRecord($scope.workspaceConfig);
    }
    $scope.saveRecord = function(rec) {
        $scope.generateTheHtmlValues();
        var postURL = "updateProjectInfo.json";
        var postdata = angular.toJson(rec);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.workspaceConfig = data;
            $scope.generateTheHtmlValues();
            $scope.editInfo=false;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.cancelProjectConfig = function() {
        $scope.generateTheHtmlValues();
        var postURL = "updateProjectInfo.json";
        var postdata = "{}";
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.workspaceConfig = data;
            $scope.generateTheHtmlValues();
            $scope.editInfo=false;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.addWorkspaceName = function(name) {
        var obj = {};
        obj.newName = name;
        var postURL = "updateWorkspaceName.json";
        var postdata = angular.toJson(obj);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.workspaceConfig = data;
            $scope.editName = false;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.deleteWorkspaceName = function(name) {
        if ($scope.workspaceConfig.allNames.length<2) {
            alert("Can not delete the only name from a workspace.");
            return;
        }
        if (!confirm("Are you sure you want to permanently delete the name "+name+"?")) {
            return;
        }
        var obj = {};
        obj.oldName = name;
        var postURL = "deleteWorkspaceName.json";
        var postdata = angular.toJson(obj);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.workspaceConfig = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.cleanUpParent = function() {
        var realParent = $scope.parentWorkspace;
        if (realParent && realParent.pageKey) {
            $scope.workspaceConfig.parentKey = realParent.pageKey;
        }
        else {
            $scope.workspaceConfig.parentKey = "";
        }
    }
    
    $scope.filterParents = function() {
        var res = [];
        if (!$scope.parentFilter) {
            return $scope.recentWorkspaces;
        }
        var lcFilter = $scope.parentFilter.toLowerCase();
        $scope.recentWorkspaces.forEach( function(item) {
            if (item.name.toLowerCase().indexOf(lcFilter)>=0) {
                res.push(item);
            }
            else if (item.pageKey.toLowerCase().indexOf(lcFilter)>=0) {
                res.push(item);
            }
        });
        return res;
    }
    
    $scope.getUserStats = function() {
        if ($scope.userFilter.length==0 && false) {
            return $scope.stats.anythingPerUser;
        }
        var filterLC = $scope.userFilter.toLowerCase();
        var coll = {};
        Object.keys($scope.stats.anythingPerUser).forEach(function(item) {
            if (item.toLowerCase().indexOf(filterLC)>=0) {
                coll[item] = $scope.stats.anythingPerUser[item];
            }
        });
        return coll;
    }

});
app.filter('escape', function() {
  return window.encodeURIComponent;
});
</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>
<div class="container-fluid override">
    <div class="row">
        <div class="col-md-auto fixed-width border-end border-1 border-secondary">
            <span class="btn btn-raised btn-comment btn-secondary m-3 pb-2 pt-0" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewTopic"><a class="nav-link" role="menuitem" href="LabelList.htm">
                Labels &amp; Folders</a>
                  </span>
            <span class="btn btn-raised btn-comment btn-secondary m-3 pb-2 pt-0" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewTopic"><a class="nav-link" role="menuitem" href="RoleRequest.htm">
          Role Requests</a>
            </span>
            <span class="btn btn-raised btn-comment btn-secondary m-3 pb-2 pt-0" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewTopic"><a class="nav-link" role="menuitem" href="EmailCreated.htm">
          Email Prepared</a>
            </span>
            <span class="btn btn-raised btn-comment btn-secondary m-3 pb-2 pt-0" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewTopic"><a class="nav-link" role="menuitem" href="EmailSent.htm">
          Email Sent</a>
            </span>
            <span class="btn btn-raised btn-comment btn-secondary m-3 pb-2 pt-0" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewTopic"><a class="nav-link" role="menuitem" href="AdminStats.htm">
                Workspace Statistics</a>
                  </span>
            <span class="btn btn-raised btn-comment btn-secondary m-3 pb-2 pt-0" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewTopic"><a class="nav-link" role="menuitem" 
          href="../$/SiteCreateWorkspace.htm?parent={{workspaceConfig.key}}">
          Create Child Workspace</a>
            </span>
            <span class="btn btn-raised btn-comment btn-secondary m-3 pb-2 pt-0" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewTopic"><a class="nav-link" role="menuitem" 
          href="../$/SiteCreateWorkspace.htm?parent={{workspaceConfig.parentKey}}">
          Create Sibling Workspace</a>
            </span>

</div>
<div class="d-flex col-9">
    <div class="contentColumn">
        <div class="container-fluid">
            <div class="generalContent">
<div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4"></span>
           <span class="col-2 h6">This Workspace</span>
           <span class="col-2 h6">Entire Site</span>
           <span class="col-2 h6">Site Limit</span>
</div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Last Change:</span>
           <span class="col-2">{{workspaceInfo.changed|cdate}}</span>
           <span class="col-2">{{siteInfo.changed|cdate}}</span>
           <span class="col-2"></span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Users:</span>
           <span class="col-2">{{stats.editUserCount}}</span>
           <span class="col-2">{{siteStats.editUserCount}}</span>
           <span class="col-2">{{siteInfo.editUserLimit}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Observers:</span>
           <span class="col-2">{{stats.readUserCount}}</span>
           <span class="col-2">{{siteStats.readUserCount}}</span>
           <span class="col-2">{{siteInfo.viewUserLimit}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Emails / Month:</span>
           <span class="col-2"></span>
           <span class="col-2"></span>
           <span class="col-2">{{siteInfo.emailLimit}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Size of Documents:</span>
           <span class="col-2">{{stats.sizeDocuments|number}}</span>
           <span class="col-2">{{siteStats.sizeDocuments|number}}</span>
           <span class="col-2">{{siteInfo.fileSpaceLimit*1000000|number}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Number of Topics:</span>
           <span class="col-2">{{stats.numTopics}}</span>
           <span class="col-2">{{siteStats.numTopics}}</span>
           <span class="col-2"></span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Number of Meetings:</span>
           <span class="col-2">{{stats.numMeetings}}</span>
           <span class="col-2">{{siteStats.numMeetings}}</span>
           <span class="col-2"></span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Number of Decisions:</span>
           <span class="col-2">{{stats.numDecisions}}</span>
           <span class="col-2">{{siteStats.numDecisions}}</span>
           <span class="col-2"></span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Number of Comments:</span>
           <span class="col-2">{{stats.numComments}}</span>
           <span class="col-2">{{siteStats.numComments}}</span>
           <span class="col-2"></span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Number of Proposals:</span>
           <span class="col-2">{{stats.numProposals}}</span>
           <span class="col-2">{{siteStats.numProposals}}</span>
           <span class="col-2"></span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Number of Documents:</span>
           <span class="col-2">{{stats.numDocs}}</span>
           <span class="col-2">{{siteStats.numDocs}}</span>
           <span class="col-2"></span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Number of Old Versions:</span>
           <span class="col-2">{{stats.sizeArchives|number}}</span>
           <span class="col-2">{{siteStats.sizeArchives|number}}</span>
           <span class="col-2"></span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Active Workspaces:</span>
           <span class="col-2 ">{{stats.numActive}}</span>
           <span class="col-2 ">{{siteStats.numActive}}</span>
           <span class="col-2 ">{{siteInfo.workspaceLimit}}</span>
        </div>
        <div class="row-cols-3 d-flex my-2 border-bottom border-1">
           <span class="col-4 h6">Frozen Workspaces:</span>
           <span class="col-2 ">{{stats.numFrozen}}</span>
           <span class="col-2 ">{{siteStats.numFrozen}}</span>
           <span class="col-2 ">{{siteInfo.frozenLimit}}</span>
        </div>
    </div>
<hr>
<div class="my-2 h5">User Counts</div>
<div class="row-cols-3 d-flex my-2 border-bottom border-1">

<span class="col-3 h6">Filter: <input ng-model="userFilter"></span>
<span class="col-1 text-center h6">Comments</span>
<span class="col-1 text-center h6" >Docs</span>
<span class="col-1 text-center h6">Meetings</span>
<span class="col-1 text-center h6">Proposals</span>
<span class="col-1 text-center h6">Responses</span>
<span class="col-1 text-center h6">Unresponded</span>
<span class="col-1 h6 text-left ms-4 ps-3">Access</span>
</div>

<div class="row-cols-3 d-flex border-bottom border-1" ng-repeat="(user,val) in getUserStats()">
<span class="col-3 h6 py-2" >{{user}}</span>
<span class="col-1 text-center py-2"  style="background-color:#f0e9f1;">{{stats.commentsPerUser[user]}}</span>
<span class="col-1 text-center py-2">{{stats.docsPerUser[user]}}</span>
<span class="col-1 text-center py-2" style="background-color:#f0e9f1;">{{stats.meetingsPerUser[user]}}</span>
<span class="col-1 text-center py-2">{{stats.proposalsPerUser[user]}}</span>
<span class="col-1 text-center py-2" style="background-color:#f0e9f1;">{{stats.responsesPerUser[user]}}</span>
<span class="col-1 text-center py-2">{{stats.unrespondedPerUser[user]}}</span>
<span class="col-1 text-left ms-4 ps-3" style="background-color:#f0e9f1;">{{stats.access[user]}}</span>
</div>

</div>
<br><br><br><br>

</div>

