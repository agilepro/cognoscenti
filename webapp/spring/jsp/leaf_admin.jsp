<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="include.jsp"
%><%@page import="org.socialbiz.cog.TemplateRecord"
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
    NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(pageId);
    NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngw);
    NGBook ngb = ngw.getSite();
    boolean showExperimental = ngb.getShowExperimental();
    Cognoscenti cog = ar.getCogInstance();

    UserProfile up = ar.getUserProfile();
    String userKey = up.getKey();

    List<NGPageIndex> templates = new ArrayList<NGPageIndex>();
    for(TemplateRecord tr : up.getTemplateList()){
        NGPageIndex ngpirr = ar.getCogInstance().getContainerIndexByKey(tr.getPageKey());
        if (ngpirr!=null) {
            //silently ignore templates that no longer exist
            templates.add(ngpirr);
        }
    }
    NGPageIndex.sortInverseChronological(templates);

    String thisPage = ar.getResourceURL(ngw,"admin.htm");
    String allTasksPage = ar.getResourceURL(ngw,"projectAllTasks.htm");

    String upstreamLink = ngw.getUpstreamLink();

    List<String> names = ngw.getContainerNames();

    String parentKey = ngw.getParentKey();
    NGPageIndex parentIndex = cog.getContainerIndexByKey(parentKey);
    String parentName = "";
    if (parentIndex!=null) {
        parentName = parentIndex.containerName;
    }

    JSONObject projectInfo = ngw.getConfigJSON();
    projectInfo.put("parentName", parentName);

    JSONArray allProjects = new JSONArray();
    for (NGPageIndex ngpis : cog.getAllProjectsInSite(ngb.getKey())) {
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
    
    JSONArray recentWorkspaces = new JSONArray();
    List<RUElement> recent = ar.getSession().recentlyVisited;    
    for (RUElement rue : recent) {
        JSONObject rujo = new JSONObject();
        rujo.put("siteKey", rue.siteKey);
        rujo.put("key", rue.key);
        rujo.put("displayName", rue.displayName);
        recentWorkspaces.put(rujo);      
    }  

%>

<fmt:setBundle basename="messages"/>
<script type="text/javascript" language="JavaScript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.projectInfo = <%projectInfo.write(out,2,4);%>;
    $scope.newName = $scope.projectInfo.allNames[0];
    
    $scope.allProjects = <%allProjects.write(out,2,4);%>;
    $scope.recentWorkspaces = <%recentWorkspaces.write(out,2,4);%>;
    
    if (!$scope.projectInfo.parentName) {
        $scope.projectInfo.parentName = "(unknown parent workspace)";
    }
    $scope.originalParentKey = $scope.projectInfo.parentKey;
    $scope.originalParentName = $scope.projectInfo.parentName;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
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
        if ($scope.projectInfo.deleted) {
            return "deletedMode";
        }
        if ($scope.projectInfo.frozen) {
            return "freezedMode";
        }
        return "normalMode";
    }
    $scope.saveProjectConfig = function() {
        var postURL = "updateProjectInfo.json";
        var postdata = angular.toJson($scope.projectInfo);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.projectInfo = data;
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
            $scope.projectInfo = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.deleteWorkspaceName = function(name) {
        if ($scope.projectInfo.allNames.length<2) {
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
            $scope.projectInfo = data;
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
.spaceyTable tr td {
    padding:8px;
}
</style>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Admin Settings
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
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
    </div>

    <div>

<% if (!ar.isAdmin()) { %>

            <div class="generalContent">
                <fmt:message key="nugen.generatInfo.Admin.administration">
                    <fmt:param value='<%=ar.getBestUserId()%>'/>
                </fmt:message><br/>
            </div>
            <div class="generalSubHeading"><fmt:message key="nugen.generatInfo.PageNameCaption"/> </div>
            <div class="generalContent">
                <ul class="bulletLinks">
                <li ng-repeat="name in projectInfo.allNames">{{name}}</li>
                </ul>
            </div>

<% }else { %>

            <div>
                <table class="spaceyTable">
                    <tr>
                        <td class="gridTableColummHeader_2">New Name for Workspace:</td>
                        <td><input type="text" class="form-control" style="width:300px" ng-model="newName"/>
                        </td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader_2"></td>
                        <td>
                            <button class="btn btn-primary btn-raised" ng-click="addWorkspaceName(newName)"/>Add Name</button>
                        </td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader_2">All Names</td>
                        <td></td>
                    </tr>

                <tr ng-repeat="name in projectInfo.allNames">
                    <td></td>
                    <td>
                        <a ng-click="deleteWorkspaceName(name)"
                           title="delete this name from workspace">
                           {{name}}
                           <img src="<%=ar.retPath%>/assets/iconDelete.gif">
                        </a>
                    </td>
                </tr>
                </table>
            </div>
            <div class="generalContent">
                <div class="generalSubHeading paddingTop">Workspace Settings</div>
                <table width="720px"  class="spaceyTable">
                    <tr>
                        <td class="gridTableColummHeader_2">Public Purpose:</td>
                        <td><textarea name="purpose" class="form-control" ng-model="projectInfo.purpose"
                              rows="4" placeholder="Enter a public description of the work that will be done in this workspace"></textarea></td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader_2" valign="top">Workspace Mode:</td>
                        <td  valign="top">

                            <input type="checkbox" name="allowPublic" value="yes"
                                ng-model="projectInfo.frozen"/> Frozen  &nbsp;&nbsp;
                            <input type="checkbox" name="allowPublic" value="yes"
                                ng-model="projectInfo.deleted"/> Deleted

                            <input type="hidden" name="projectMode" value="{{projectMode()}}"/>
                        </td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader_2">Parent Circle:</td>
                        <td>
                            <select ng-model="projectInfo.parentKey" class="form-control" style="width:400px">
                                <option value="{{originalParentKey}}">{{originalParentName}}</option>
                                <option ng-repeat="ws in recentWorkspaces" value="{{ws.key}}">{{ws.displayName}}</option>
                                </select>
                        </td>
                    </tr>
<% if (showExperimental) { %>
                    <tr>
                        <td class="gridTableColummHeader_2">Allow Public:</td>
                        <td>
                            <input type="checkbox" name="allowPublic" value="yes"
                                ng-model="projectInfo.allowPublic"/> {{projectInfo.allowPublic}}
                        </td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader_2">Workspace Email id:</td>
                        <td>
                            <input type="text" class="form-control"
                                   name="projectMailId" ng-model="projectInfo.projectMail" />
                        </td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader_2">Upstream Clone:</td>
                        <td>
                            <input type="text" class="form-control" style="width:450px" id="upstream"
                                   name="upstream" ng-model="projectInfo.upstream" />
                        </td>
                    </tr>
<% } %>
                    <tr>
                        <td class="gridTableColummHeader_2"></td>
                        <td>
                            <button ng-click="saveProjectConfig();" class="btn btn-primary btn-raised" >Update</button>
                        </td>
                    </tr>
                </table>
            </div>


    <% if (showExperimental) { %>

            <div class="generalContent">
                <div class="generalSubHeading paddingTop">Copy From Template</div>
                <table width="720px" class="spaceyTable">
                  <form action="<%=ar.retPath%>CopyFromTemplate.jsp" method="post">
                  <input type="hidden" name="go" value="<%ar.writeHtml(allTasksPage);%>">
                  <input type="hidden" name="p" value="<%ar.writeHtml(pageId);%>">
                    <tr>
                        <td class="gridTableColummHeader_2">Template:</td>
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
                        <td class="gridTableColummHeader_2"></td>
                        <td style="width:20px;"></td>
                        <td> <input type="submit" value="Copy From Template" class="btn btn-primary btn-raised"> </td>
                    </tr>
                  </form>
                </table>
            </div>
    <% } %>
<% } %>

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
                    ngw.gatherUnsentScheduledNotification(allUnsent);
                    for (ScheduledNotification sn : allUnsent) {
                        if (sn!=null) {
                            long timeToAct = sn.timeToSend();
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
                <table class="table">
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
