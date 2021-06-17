<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="include.jsp"
%><%@page import="org.socialbiz.cog.EmailGenerator"
%><%@page import="org.socialbiz.cog.CommentRecord"
%><%@page import="org.socialbiz.cog.mail.ScheduledNotification"
%><%@page import="org.socialbiz.cog.WorkspaceStats"
%><%@page import="org.socialbiz.cog.util.NameCounter"
%><%@page import="java.util.ArrayList"
%>
<%
    ar.assertLoggedIn("Must be logged in to see admin options");
    ar.assertMember("This VIEW only for members in use cases");

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

    List<NGPageIndex> templates = up.getValidTemplates(ar.getCogInstance());

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
    for (NGPageIndex ngpis : cog.getAllProjectsInSite(site.getKey())) {
        if (ngpis.isDeleted) {
            continue;
        }
        allWorkspaces.put(ngpis.getJSON4List());
    }

    WorkspaceStats wStats = new WorkspaceStats();
    wStats.gatherFromWorkspace(ngw);
    JSONObject statsObj = wStats.getJSON();
    

    boolean foundInRecents = false;

    int barPos = parentKey.indexOf("|");
    if (barPos>=0) {
        parentKey = parentKey.substring(barPos+1);
    }
    List<NGPageIndex> allWS = cog.getAllProjectsInSite(siteId);
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
    $scope.stats = <%statsObj.write(out,2,4);%>;

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
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

<h1>Statistics</h1>

        <table class="spaceyTable">
        <tr>
           <td>Number of Topics:</td>
           <td style="text-align:center;">{{stats.numTopics}}</td>
        </tr>
        <tr>
           <td>Number of Meetings:</td>
           <td style="text-align:center;">{{stats.numMeetings}}</td>
        </tr>
        <tr>
           <td>Number of Decisions:</td>
           <td style="text-align:center;">{{stats.numDecisions}}</td>
        </tr>
        <tr>
           <td>Number of Comments:</td>
           <td style="text-align:center;">{{stats.numComments}}</td>
        </tr>
        <tr>
           <td>Number of Proposals:</td>
           <td style="text-align:center;">{{stats.numProposals}}</td>
        </tr>
        <tr>
           <td>Number of Documents:</td>
           <td style="text-align:center;">{{stats.numDocs}}</td>
        </tr>
        <tr>
           <td>Size of Documents:</td>
           <td style="text-align:center;">{{stats.sizeDocuments|number}}</td>
        </tr>
        <tr>
           <td>Number of Old Versions:</td>
           <td style="text-align:center;">{{stats.sizeArchives|number}}</td>
        </tr>
    </table>

<table class="spaceyTable">

<tr>
<td></td>
<td style="text-align:center;">Comments</td>
<td style="text-align:center;background-color:#fefefe;">Docs</td>
<td style="text-align:center;">Meetings</td>
<td style="text-align:center;background-color:#fefefe;">Proposals</td>
<td style="text-align:center;">Responses</td>
<td style="text-align:center;background-color:#fefefe;">Unresponded</td>
</tr>

<tr ng-repeat="(user,val) in stats.anythingPerUser">
<td>{{user}}</td>
<td style="text-align:center;">{{stats['commentsPerUser'][user]}}</td>
<td style="text-align:center;background-color:#fefefe;">{{stats['docsPerUser'][user]}}</td>
<td style="text-align:center;">{{stats['meetingsPerUser'][user]}}</td>
<td style="text-align:center;background-color:#fefefe;">{{stats['proposalsPerUser'][user]}}</td>
<td style="text-align:center;">{{stats['responsesPerUser'][user]}}</td>
<td style="text-align:center;background-color:#fefefe;">{{stats['unrespondedPerUser'][user]}}</td>
</tr>

</table>


    <div class="generalContent">
        <div class="generalSubHeading paddingTop">Future Scheduled Actions</div>
        <div>
           Next Action due: {{<%=ngw.nextActionDue()%>|date:'M/d/yy H:mm'}}
        </div>
        <div>
           Index says: {{<%=ngpi.nextScheduledAction%>|date:'M/d/yy H:mm'}}
        </div>
        <div>
            OVERDUE:
            <ul>
            <%findOverdueContainer(ar);%>
            </ul>
            ALL UNSENT NOTIFICATIONS:
            <ol>
            <%

            ArrayList<ScheduledNotification> allUnsent = new ArrayList<ScheduledNotification>();

            //Now scan all the comments on all the topics
            int ii = 0;
            ngw.gatherUnsentScheduledNotification(allUnsent, ar.nowTime);
            for (ScheduledNotification sn : allUnsent) {
                if (sn!=null) {
                    long timeToAct = sn.futureTimeToSend();
                    ar.write("<li>"+ (++ii)+": ");
                    ar.writeHtml( (new Date(timeToAct)).toString() );
                    ar.write(", ");
                    ar.writeHtml( sn.selfDescription() );
                    if (timeToAct < ar.nowTime) {
                        ar.write("  <b>OVERDUE!</b>");
                    }
                    ar.write("</li>");
                }
            }



            %>
            </ol>
        </div>
    </div>


</div>


<%!

    private NGPageIndex findOverdueContainer(AuthRequest ar) throws Exception  {
        for (NGPageIndex ngpi : ar.getCogInstance().getAllContainers()) {
            if (ngpi.nextScheduledAction>0 && ngpi.nextScheduledAction<ar.nowTime) {
                ar.write("<li>");
                ar.writeHtml(ngpi.containerName);
                ar.write(": ");
                ar.write( (new Date(ngpi.nextScheduledAction)).toString() );
                ar.write("</li>");
            }
        }
        return null;
    }


%>


