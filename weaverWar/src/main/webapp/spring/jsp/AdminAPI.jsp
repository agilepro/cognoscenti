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

    String allTasksPage = ar.getResourceURL(ngw,"projectAllTasks.htm");

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

    WorkspaceStats wStats = new WorkspaceStats();
    wStats.gatherFromWorkspace(ngw);

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
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Workspace Administration");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.workspaceConfig = <%workspaceConfig.write(out,2,4);%>;
    $scope.newName = $scope.workspaceConfig.allNames[0];
    $scope.editName = false;
    $scope.editInfo = false;
    $scope.foo = "<p>This <b>bold</b> statement.</p>"

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

});
app.filter('escape', function() {
  return window.encodeURIComponent;
});
</script>


<style>
.spaceyTable {
    min-width:400px;
    max-width:800px;
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
</style>

<!-- MAIN CONTENT SECTION START -->
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>






    <div>

       <h3>Data API</h3>


       <ul>

       <li><a target="dataWindow" href="taskAreas.json">taskAreas.json</a></li>
       <li><a target="dataWindow" href="allActionsList.json">allActionsList.json</a></li>
       <li><a target="dataWindow" href="docsList.json">docsList.json</a></li>
       <li><a target="dataWindow" href="topicList.json">topicList.json</a></li>
       <li><a target="dataWindow" href="meetingList.json">meetingList.json</a></li>

       <li><a target="dataWindow" href="invitations.json">invitations.json</a></li>
       <li><a target="dataWindow" href="getNoteHistory.json?nid={{sampleTopic}}">getNoteHistory.json?nid={{sampleTopic}}"</a></li>
       <li><a target="dataWindow" href="sharePorts.json">sharePorts.json</a></li>
       <li><a target="dataWindow" href="../$/SiteStatistics.json">../$/SiteStatistics.json</a></li>
       <li>Sample Goal: <input ng-model="sampleGoal"/></li>
       <li><a target="dataWindow" href="getGoalHistory.json?gid={{sampleGoal}}">getGoalHistory.json?gid={{sampleGoal}}</a></li>
       <li><a target="dataWindow" href="fetchGoal.json?gid={{sampleGoal}}">fetchGoal.json?gid={{sampleGoal}}</a></li>
       <li><a target="dataWindow" href="ActionItem{{sampleGoal}}Due.ics">ActionItem{{sampleGoal}}Due.ics</a></li>
       <li>Sample Meeting: <input ng-model="sampleMeet"/> Agenda Item <input ng-model="sampleAgenda"/></li>
       <li><a target="dataWindow" href="getMeetingNotes.json?id={{sampleMeet}}">getMeetingNotes.json?id={{sampleMeet}}</a></li>
       <li><a target="dataWindow" href="meetingRead.json?id={{sampleMeet}}">meetingRead.json?id={{sampleMeet}}</a></li>
       <li><a target="dataWindow" href="attachedActions.json?meet={{sampleMeet}}&ai={{sampleAgenda}}">attachedActions.json?meet={{sampleMeet}}&ai={{sampleAgenda}}</a></li>
       <li><a target="dataWindow" href="attachedDocs.json?meet={{sampleMeet}}&ai={{sampleAgenda}}">attachedDocs.json?meet={{sampleMeet}}&ai={{sampleAgenda}}</a></li>
       <li>Sample Role: <input ng-model="sampleRole"/></li>
       <li><a target="dataWindow" href="isRolePlayer.json?role={{sampleRole}}">isRolePlayer.json?role={{sampleRole}}</a></li>
       <li>Sample Topic: <input ng-model="sampleTopic"/></li>
       <li><a target="dataWindow" href="getTopic.json?nid={{sampleTopic}}">getTopic.json?nid={{sampleTopic}}</a></li>
       <li><a target="dataWindow" href="attachedActions.json?note={{sampleTopic}}">attachedActions.json?note={{sampleTopic}}</a></li>
       <li><a target="dataWindow" href="attachedDocs.json?note={{sampleTopic}}">attachedDocs.json?note={{sampleTopic}}</a></li>
       <li>Sample Comment: <input ng-model="sampleComment"/></li>
       <li><a target="dataWindow" href="info/comment?cid={{sampleComment}}">info/comment?cid={{sampleComment}}</a></li>
       <li>Sample SharePort: <input ng-model="sampleSharePort"/></li>
       <li><a target="dataWindow" href="share/{{sampleSharePort}}.json">share/{{sampleSharePort}}.json</a></li>
       </ul>

    </div>
</div>




