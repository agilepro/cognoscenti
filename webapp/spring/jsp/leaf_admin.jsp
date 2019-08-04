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

    String thisPage = ar.getResourceURL(ngw,"admin.htm");
    String allTasksPage = ar.getResourceURL(ngw,"projectAllTasks.htm");

    String upstreamLink = ngw.getUpstreamLink();

    List<String> names = ngw.getContainerNames();

    String parentKey = ngw.getParentKey();
    NGPageIndex parentIndex = cog.getWSByCombinedKey(parentKey);
    String parentName = "";
    if (parentIndex!=null) {
        parentName = parentIndex.containerName;
    }

    JSONObject workspaceConfig = ngw.getConfigJSON();
    workspaceConfig.put("parentName", parentName);

    JSONArray allProjects = new JSONArray();
    for (NGPageIndex ngpis : cog.getAllProjectsInSite(site.getKey())) {
        if (ngpis.isDeleted) {
            continue;
        }
        JSONObject pInfo = new JSONObject();
        pInfo.put("name", ngpis.containerName);
        pInfo.put("key", ngpis.containerKey);
        allProjects.put(pInfo);
    }

    WorkspaceStats wStats = new WorkspaceStats();
    wStats.gatherFromWorkspace(ngw);
    
    boolean foundInRecents = false;
    JSONArray recentWorkspaces = new JSONArray();
    List<RUElement> recent = ar.getSession().recentlyVisited;    
    for (RUElement rue : recent) {
        if (rue.key.equals(pageId)) {
            continue;  //skip adding this page into possible parents list
        }
        JSONObject rujo = new JSONObject();
        if (parentKey.equals(rue.key)) {
            foundInRecents = true;
        }
        rujo.put("siteKey", rue.siteKey);
        rujo.put("key", rue.key);
        rujo.put("displayName", rue.displayName);
        recentWorkspaces.put(rujo);      
    }  
    if (!foundInRecents && parentIndex!=null) {
        JSONObject includeParent = new JSONObject();
        includeParent.put("siteKey", parentIndex.wsSiteKey);
        includeParent.put("name", parentIndex.containerName);
        includeParent.put("key", parentIndex.containerKey);
        recentWorkspaces.put(includeParent);
    }

    /*
    Data from the server is the workspace config structure
    {
      "accessState": "Live",
      "allNames": ["Darwin2"],
      "deleted": false,
      "frozen": false,
      "goal": "",
      "key": "darwin2",
      "parentKey": "",
      "parentName": "",
      "projectMail": "",
      "purpose": "",
      "showExperimental": false,
      "site": "goofoof",
      "upstream": ""
    }
    */
    
%>

<fmt:setBundle basename="messages"/>
<script type="text/javascript" language="JavaScript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Workspace Administration");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.workspaceConfig = <%workspaceConfig.write(out,2,4);%>;
    $scope.newName = $scope.workspaceConfig.allNames[0];
    $scope.editName = false;
    $scope.editInfo = false;
    $scope.foo = "<p>This <b>bold</b> statement.</p>"
    
    $scope.allProjects = <%allProjects.write(out,2,4);%>;
    $scope.recentWorkspaces = <%recentWorkspaces.write(out,2,4);%>;
       

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        console.log("Error: ",serverErr);
        errorPanelHandler($scope, serverErr);
    };

    $scope.lookUpName = function(prjKey) {
        for (var i=0; i<$scope.allProjects.length; i++) {
            if ($scope.allProjects[i].key==prjKey) {
                return $scope.allProjects[i].name;
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
    content: "Click to Set Value"
}
</style>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

<% if (ar.isAdmin()) { %>
    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" href="listEmail.htm">
              Email Prepared</a>
          </li>
          <li role="presentation"><a role="menuitem" href="emailSent.htm">
              Email Sent</a>
          </li>
          <li role="presentation"><a role="menuitem" href="roleRequest.htm">
              Role Requests</a>
          </li>
        </ul>
      </span>
    </div>
<% } %>

    <div>

        <div>
            <table class="spaceyTable">
                <tr >
                    <td ng-click="setEdit('name')"><label>Workspace Names:</label></td>
                    <td ng-hide="isEditing=='name'" ng-click="setEdit('name')">
                        <h1>{{workspaceConfig.allNames[0]}}</h1>
                    </td>
                    <td class="form-inline form-group" ng-show="isEditing=='name'">
                        <div ng-repeat="name in workspaceConfig.allNames">
                            <a ng-click="deleteWorkspaceName(name)"
                               title="delete this name from workspace">
                               {{name}}
                               <img src="<%=ar.retPath%>/assets/iconDelete.gif">
                            </a>
                        </div>
                        <input type="text" class="form-control" style="width:300px;background-color:white" ng-model="newName"/>
                        <button class="btn btn-primary btn-raised" ng-click="addWorkspaceName(newName)">Add Name</button>
                        <button class="btn btn-warning btn-raised" ng-click="editName=false">Cancel</button>
                    </td>
                </tr>
                <tr>
                    <td ng-click="setEdit('vision')"><label>Vision:</label></td>
                    <td ng-show="isEditing=='vision'">
                        <textarea class="form-control editBoxStyle" 
                              placeholder="Enter a vision statement for the circle working in this  workspace, if any" 
                              ng-model="workspaceConfig.vision" rows="14" cols="80"></textarea>
                              <button ng-click="saveOneField('vision')" class="btn btn-primary btn-raised">
                                  Save</button>
                              <button ng-click="saveOneField('frozen')" class="btn btn-raised">
                                  Cancel</button>
                              </td>
                    <td ng-hide="isEditing=='vision'" ng-click="setEdit('vision')">
                        <div ng-bind-html="visionHtml"></div>
                        <div ng-hide="visionHtml" class="clicker"></div>
                    </td>
                </tr>
                <tr>
                    <td ng-click="setEdit('mission')"><label>Mission:</label></td>
                    <td ng-show="isEditing=='mission'">
                        <textarea class="form-control editBoxStyle" 
                              placeholder="Enter a mission statement for the circle working in this  workspace, if any" 
                              ng-model="workspaceConfig.mission" rows="14" cols="80"></textarea>
                              <button ng-click="saveOneField('mission')" class="btn btn-primary btn-raised">
                                  Save</button>
                              <button ng-click="saveOneField('frozen')" class="btn btn-raised">
                                  Cancel</button>
                              </td>
                    <td ng-hide="isEditing=='mission'" ng-click="setEdit('mission')">
                        <div ng-bind-html="missionHtml"></div>
                        <div ng-hide="missionHtml" class="clicker"></div>
                    </td>
                </tr>
                <tr >
                    <td  ng-click="setEdit('purpose')"><label>Aim:</label></td>
                    <td ng-show="isEditing=='purpose'">
                        <textarea class="form-control editBoxStyle" 
                              placeholder="Enter a public description of the work that will be done in this workspace, the aim of this workspace." 
                              ng-model="workspaceConfig.purpose" rows="14" cols="80"></textarea>
                              <button ng-click="saveOneField('purpose')" class="btn btn-primary btn-raised">
                                  Save</button>
                              <button ng-click="saveOneField('frozen')" class="btn btn-raised">
                                  Cancel</button>
                              </td>
                    <td ng-hide="isEditing=='purpose'" ng-click="setEdit('purpose')">
                        <div ng-bind-html="purposeHtml"></div>
                        <div ng-hide="purposeHtml" class="clicker"></div>
                    </td>
                </tr>
                <tr>
                    <td ng-click="setEdit('domain')"><label>Domain:</label></td>
                    <td ng-show="isEditing=='domain'">
                        <textarea class="form-control editBoxStyle" 
                              placeholder="Enter a domain statement for the circle working in this  workspace, if any" 
                              ng-model="workspaceConfig.domain" rows="14" cols="80"></textarea>
                              <button ng-click="saveOneField('domain')" class="btn btn-primary btn-raised">
                                  Save</button>
                              <button ng-click="saveOneField('frozen')" class="btn btn-raised">
                                  Cancel</button>
                              </td>
                    <td ng-hide="isEditing=='domain'" ng-click="setEdit('domain')">
                        <div ng-bind-html="domainHtml"></div>
                        <div ng-hide="domainHtml" class="clicker"></div>
                    </td>
                </tr>
                <tr>
                    <td valign="top" ng-click="setEdit('frozen')"><label>Workspace Mode:</label></td>
                    <td  valign="top" ng-show="isEditing=='frozen'">

                        <button ng-click="workspaceConfig.frozen=true;saveOneField('frozen')" 
                            class="btn btn-primary btn-raised" ng-hide="workspaceConfig.frozen">
                            Freeze Workspace</button>
                        <button ng-click="workspaceConfig.frozen=false;saveOneField('frozen')" 
                            class="btn btn-primary btn-raised" 
                            ng-show="workspaceConfig.frozen && !workspaceConfig.deleted">
                            Unfreeze Workspace</button>
                        <button ng-click="workspaceConfig.deleted=true;saveOneField('deleted')" 
                            class="btn btn-primary btn-raised" ng-hide="workspaceConfig.deleted">
                            Delete Workspace</button>
                        <button ng-click="workspaceConfig.deleted=false;saveOneField('deleted')" 
                            class="btn btn-primary btn-raised" ng-show="workspaceConfig.deleted">
                            Undelete Workspace</button>
                        <button ng-click="isEditing=null" class="btn btn-raised">
                            Cancel</button>
                    </td>
                    <td  valign="top" ng-hide="isEditing=='frozen'" ng-click="setEdit('frozen')">
                        <span ng-show="workspaceConfig.deleted">This workspace is DELETED</span>
                        <span ng-show="workspaceConfig.frozen && !workspaceConfig.deleted">This workspace is FROZEN</span>
                        <span ng-show="!workspaceConfig.frozen && !workspaceConfig.deleted">Active and available.</span>
                    </td>
                </tr>
                <tr>
                    <td ng-click="setEdit('parentKey')"><label>Parent Circle:</label></td>
                    <td ng-show="isEditing=='parentKey'">
                        <select ng-model="workspaceConfig.parentKey" class="form-control" style="width:400px">
                            <option ng-repeat="ws in recentWorkspaces" value="{{ws.key}}">{{ws.displayName}} ({{ws.key}})</option>
                            </select>
                        <button ng-click="saveOneField('parentKey')" class="btn btn-primary btn-raised">
                            Save</button>
                        <button ng-click="clearField('parentKey')" class="btn btn-primary btn-raised">
                            Clear It</button>
                        <button ng-click="saveOneField('frozen')" class="btn btn-raised">
                            Cancel</button>
                    </td>
                    <td ng-hide="isEditing=='parentKey'" ng-click="setEdit('parentKey')">
                        <div>{{workspaceConfig.parentKey}}</div>
                        <div ng-hide="workspaceConfig.parentKey" class="clicker"></div>
                    </td>
                </tr>
<% if (showExperimental) { %>
                <tr>
                    <td ><label>Workspace Email id:</label></td>
                    <td>
                        <input type="text" class="form-control"
                               name="projectMailId" ng-model="workspaceConfig.projectMail" />
                    </td>
                </tr>
                <tr>
                    <td><label>Upstream Clone:</label></td>
                    <td>
                        <input type="text" class="form-control" style="width:450px" id="upstream"
                               name="upstream" ng-model="workspaceConfig.upstream" />
                    </td>
                </tr>
<% } %>
            </table>
        </div>


    <% if (showExperimental) { %>

            <div class="generalContent">
                <div class="generalSubHeading paddingTop">Copy From Template</div>
                <table width="720px" class="spaceyTable">
                  <form action="<%=ar.retPath%>CopyFromTemplate.jsp" method="post">
                  <input type="hidden" name="go" value="<%ar.writeHtml(allTasksPage);%>"/>
                  <input type="hidden" name="p" value="<%ar.writeHtml(pageId);%>"/>
                    <tr>
                        <td>Template:</td>
                        <td style="width:20px;"></td>
                        <td><select name="template" class="form-control" style="width:400px">
                        <%
                            for (NGPageIndex temp : templates) {
                            %>
                            <option name="template" value="<%ar.writeHtml(temp.containerKey);%>"><%
                            ar.writeHtml(temp.containerName);
                            %></option>
                            <%
                            }
                        %>
                        </select></td>
                    </tr>
                    <tr>
                        <td></td>
                        <td style="width:20px;"></td>
                        <td> <input type="submit" value="Copy From Template" class="btn btn-primary btn-raised"/> </td>
                    </tr>
                  </form>
                </table>
            </div>
    <% } %>


<hr/>
<h1>Statistics</h1>
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

            <div class="generalContent">
                <div class="generalSubHeading paddingTop">Statistics</div>
                <table class="spaceyTable">
                <tr>
                   <td>Number of Topics:</td>
                   <td><%=wStats.numTopics%></td>
                </tr>
                <tr>
                   <td>Number of Meetings:</td>
                   <td><%=wStats.numMeetings%></td>
                </tr>
                <tr>
                   <td>Number of Decisions:</td>
                   <td><%=wStats.numDecisions%></td>
                </tr>
                <tr>
                   <td>Number of Comments:</td>
                   <td><%=wStats.numComments%></td>
                </tr>
                <tr>
                   <td>Number of Proposals:</td>
                   <td><%=wStats.numProposals%></td>
                </tr>
                <tr>
                   <td>Number of Documents:</td>
                   <td><%=wStats.numDocs%></td>
                </tr>
                <tr>
                   <td>Size of Documents:</td>
                   <td>{{<%=wStats.sizeDocuments%>|number}}</td>
                </tr>
                <tr>
                   <td>Number of Old Versions:</td>
                   <td>{{<%=wStats.sizeArchives%>|number}}</td>
                </tr>
                <tr>
                   <td>Topics:</td>
                   <td><% outputStatTable(ar, wStats.topicsPerUser, "Topics"); %></td>
                </tr>
                <tr>
                   <td>Documents:</td>
                   <td><% outputStatTable(ar, wStats.docsPerUser, "Documents"); %></td>
                </tr>
                <tr>
                   <td>Comments:</td>
                   <td><% outputStatTable(ar, wStats.commentsPerUser, "Comments"); %></td>
                </tr>
                <tr>
                   <td>Meetings:</td>
                   <td><% outputStatTable(ar, wStats.meetingsPerUser, "Meetings"); %></td>
                </tr>
                <tr>
                   <td>Proposals:</td>
                   <td><% outputStatTable(ar, wStats.proposalsPerUser, "Proposals"); %></td>
                </tr>
                <tr>
                   <td>Responses:</td>
                   <td><% outputStatTable(ar, wStats.responsesPerUser, "Responses"); %></td>
                </tr>
                <tr>
                   <td>Unresponded:</td>
                   <td><% outputStatTable(ar, wStats.unrespondedPerUser, "Unresponded"); %></td>
                </tr>
                <tr>
                   <td>All Users:</td>
                   <td><% outputStatTable(ar, wStats.anythingPerUser, "All Users"); %></td>
                </tr>
                </table>
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

    private void outputStatTable(AuthRequest ar, NameCounter counter, String group) throws Exception  {
        ar.write("\n<table>");
        List<String> keys = counter.getSortedKeys();
        for (String key : keys) {
            ar.write("\n  <tr><td style=\"text-align:right;\">");
            ar.writeHtml(key);
            ar.write(" </td><td>: ");
            ar.write(counter.get(key).toString());
            ar.write("</td></tr>");
        }
        ar.write("\n</table>");
    }


%>
