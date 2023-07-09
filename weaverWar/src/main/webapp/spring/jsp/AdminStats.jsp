<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="include.jsp"
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
            accessStatus.put(aUser, "Read Only");
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
    window.setMainPageTitle("Workspace Administration");
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


<style>
.spaceyTable {
    min-width:800px;
    max-width:1000px;
}
.spaceyTable tr td {
    padding:8px;
    border-bottom: 1px solid #ddd;
}
.spaceyTable tr:hover {
    background-color: #f5f5f5;
}
editBoxStyle {
    background-color: red;
    width:400px;
    height:150px;
}
.clicker {
    background-color: #DDD;
    color:white;
    padding:8px;
}
.clicker:after {
    content: "Double-click to Set Value"
}
.centeredCell {
    text-align:center;
}
</style>

<!-- MAIN CONTENT SECTION START -->
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

<h1>Statistics</h1>

        <table class="spaceyTable">
        <tr>
           <td class="centeredCell"></td>
           <td class="centeredCell">This Workspace</td>
           <td class="centeredCell">Entire Site</td>
           <td class="centeredCell">Site Limit</td>
        </tr>
        <tr>
           <td>Last Change:</td>
           <td class="centeredCell">{{workspaceInfo.changed|cdate}}</td>
           <td class="centeredCell">{{siteInfo.changed|cdate}}</td>
           <td class="centeredCell"></td>
        </tr>
        <tr>
           <td>Full Users:</td>
           <td class="centeredCell">{{stats.editUserCount}}</td>
           <td class="centeredCell">{{siteStats.editUserCount}}</td>
           <td class="centeredCell">{{siteInfo.editUserLimit}}</td>
        </tr>
        <tr>
           <td>Read-only Users:</td>
           <td class="centeredCell">{{stats.readUserCount}}</td>
           <td class="centeredCell">{{siteStats.readUserCount}}</td>
           <td class="centeredCell">{{siteInfo.viewUserLimit}}</td>
        </tr>
        <tr>
           <td>Emails / Month:</td>
           <td class="centeredCell"></td>
           <td class="centeredCell"></td>
           <td class="centeredCell">{{siteInfo.emailLimit}}</td>
        </tr>
        <tr>
           <td>Size of Documents:</td>
           <td class="centeredCell">{{stats.sizeDocuments|number}}</td>
           <td class="centeredCell">{{siteStats.sizeDocuments|number}}</td>
           <td class="centeredCell">{{siteInfo.fileSpaceLimit*1000000|number}}</td>
        </tr>
        <tr>
           <td>Number of Topics:</td>
           <td class="centeredCell">{{stats.numTopics}}</td>
           <td class="centeredCell">{{siteStats.numTopics}}</td>
           <td class="centeredCell"></td>
        </tr>
        <tr>
           <td>Number of Meetings:</td>
           <td class="centeredCell">{{stats.numMeetings}}</td>
           <td class="centeredCell">{{siteStats.numMeetings}}</td>
           <td class="centeredCell"></td>
        </tr>
        <tr>
           <td>Number of Decisions:</td>
           <td class="centeredCell">{{stats.numDecisions}}</td>
           <td class="centeredCell">{{siteStats.numDecisions}}</td>
           <td class="centeredCell"></td>
        </tr>
        <tr>
           <td>Number of Comments:</td>
           <td class="centeredCell">{{stats.numComments}}</td>
           <td class="centeredCell">{{siteStats.numComments}}</td>
           <td class="centeredCell"></td>
        </tr>
        <tr>
           <td>Number of Proposals:</td>
           <td class="centeredCell">{{stats.numProposals}}</td>
           <td class="centeredCell">{{siteStats.numProposals}}</td>
           <td class="centeredCell"></td>
        </tr>
        <tr>
           <td>Number of Documents:</td>
           <td class="centeredCell">{{stats.numDocs}}</td>
           <td class="centeredCell">{{siteStats.numDocs}}</td>
           <td class="centeredCell"></td>
        </tr>
        <tr>
           <td>Number of Old Versions:</td>
           <td class="centeredCell">{{stats.sizeArchives|number}}</td>
           <td class="centeredCell">{{siteStats.sizeArchives|number}}</td>
           <td class="centeredCell"></td>
        </tr>
        <tr>
           <td>Active Workspaces:</td>
           <td class="centeredCell">{{stats.numActive}}</td>
           <td class="centeredCell">{{siteStats.numActive}}</td>
           <td class="centeredCell">{{siteInfo.workspaceLimit}}</td>
        </tr>
        <tr>
           <td>Frozen Workspaces:</td>
           <td class="centeredCell">{{stats.numFrozen}}</td>
           <td class="centeredCell">{{siteStats.numFrozen}}</td>
           <td class="centeredCell">{{siteInfo.frozenLimit}}</td>
        </tr>
    </table>

<h1>User Counts</h1>
<table class="table">

<tr style="background-color:#EEF">
<td>Filter: <input ng-model="userFilter"></td>
<td class="centeredCell">Comments</td>
<td class="centeredCell">Docs</td>
<td class="centeredCell">Meetings</td>
<td class="centeredCell">Proposals</td>
<td class="centeredCell">Responses</td>
<td class="centeredCell">Unresponded</td>
<td class="centeredCell">Access</td>
</tr>

<tr ng-repeat="(user,val) in getUserStats()">
<td>{{user}}</td>
<td class="centeredCell">{{stats.commentsPerUser[user]}}</td>
<td style="text-align:center;background-color:#fefefe;">{{stats.docsPerUser[user]}}</td>
<td class="centeredCell">{{stats.meetingsPerUser[user]}}</td>
<td style="text-align:center;background-color:#fefefe;">{{stats.proposalsPerUser[user]}}</td>
<td class="centeredCell">{{stats.responsesPerUser[user]}}</td>
<td style="text-align:center;background-color:#fefefe;">{{stats.unrespondedPerUser[user]}}</td>
<td class="centeredCell">{{stats.access[user]}}</td>
</tr>

</table>


</div>

