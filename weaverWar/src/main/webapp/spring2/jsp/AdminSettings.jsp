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
    wStats.countUsers(ngw.getSite().getUserMap());

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
    int unfrozenCount = site.countUnfrozenWorkspaces();
    int workspaceLimit = site.getWorkspaceLimit();
    boolean mustBeFrozen = (unfrozenCount >= workspaceLimit && ngw.isFrozen());

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
app.controller('myCtrl', function($scope, $http, $modal, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Workspace Administration");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.workspaceConfig = <%workspaceConfig.write(out,2,4);%>;
    $scope.newName = $scope.workspaceConfig.allNames[0];
    $scope.editName = false;
    $scope.editInfo = false;
    $scope.isAdmin = <%= ar.isAdmin() %>;
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
            alert("Sorry, only administrators can edit the values on this page");
            $scope.isEditing = null;
            console.log("Sorry, only administrators can edit the values on this page")
        }
    }
    $scope.generateTheHtmlValues = function() {
        $scope.purposeHtml = convertMarkdownToHtml($scope.workspaceConfig.purpose);
        $scope.visionHtml  = convertMarkdownToHtml($scope.workspaceConfig.vision);
        $scope.missionHtml = convertMarkdownToHtml($scope.workspaceConfig.mission);
        $scope.domainHtml  = convertMarkdownToHtml($scope.workspaceConfig.domain);
    }
    $scope.generateTheHtmlValues();
    $scope.saveOneField = function(fieldName, refreshPage) {
        var newData = {};
        newData[fieldName] = $scope.workspaceConfig[fieldName];
        saveRecord(newData, refreshPage);
        $scope.isEditing = null;
    }
    $scope.deleteParentKey = function() {
        $scope.saveParentKey({pageKey:"$delete$"})
    }
    $scope.saveParentKey = function(workspace) {
        $scope.workspaceConfig.parentKey = workspace.pageKey;
        $scope.parentWorkspace = workspace;
        $scope.parentFilter = "";
        $scope.saveOneField("parentKey");
    }
    $scope.undeleteWorkspace = function() {
        var newData = {};
        newData.deleted = false;
        newData.frozen = true;
        saveRecord(newData, true);
        $scope.isEditing = null;
    }
    $scope.clearField = function(fieldName) {
        var newData = {};
        newData[fieldName] = "";
        saveRecord(newData);
        $scope.isEditing = null;
    }
    $scope.saveProjectConfig = function() {
        saveRecord($scope.workspaceConfig);
    }
    
    
    console.log("FROZEN", $scope.workspaceConfig.frozen, $scope.workspaceConfig );
    function saveRecord(rec, refreshPage) {
        console.log("FROZEN", $scope.workspaceConfig.frozen, $scope.workspaceConfig);
        if (!<%=ar.isAdmin()%>) {
            alert("Sorry, you are not allowed to make changes on this page.  You must be an administrator of this workspace.");
            return;
        }
        if ((!$scope.workspaceConfig.frozen) && <%=mustBeFrozen%>) {
            $scope.workspaceConfig.frozen = true;
            alert("Sorry, the administrator has set a limit on the number of workspaces, and you already have too many unfrozen workspaces.  You options are to freeze another workspace before unfreezing this one, or raising the limit on the number of workspaces.");
            return;
        }
            
        $scope.generateTheHtmlValues();
        var postURL = "updateProjectInfo.json";
        var postdata = angular.toJson(rec);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.workspaceConfig = data;
            $scope.generateTheHtmlValues();
            $scope.editInfo=false;
            if (refreshPage) {
                window.location.reload();
            }
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
            $scope.setEdit('');
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
    
    $scope.toggleFrontPage = function(flag) {
        if (!$scope.isAdmin) {
            return;
        }
        $scope.workspaceConfig.wsSettings[flag] = !$scope.workspaceConfig.wsSettings[flag];
        var newData = {wsSettings: {}};
        newData.wsSettings[flag] = $scope.workspaceConfig.wsSettings[flag];
        saveRecord(newData);
    }
    $scope.toggleBool = function(flag) {
        if (!$scope.isAdmin) {
            return;
        }
        $scope.workspaceConfig[flag] = !$scope.workspaceConfig[flag];
        var newData = {};
        newData[flag] = $scope.workspaceConfig[flag];
        saveRecord(newData);
    }

});
app.filter('escape', function() {
  return window.encodeURIComponent;
});
</script>



<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

<% if (ar.isAdmin()) { %>
    <div class="container-fluid">
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
    <div class="d-flex col-9"><div class="contentColumn">
<% } %>


            <div class="container m-2">
                <div class="row my-2 border-bottom border-1" >
                    <span ng-click="setEdit('name')" class="col-2 fixed-width-sm bold labelColumn">Workspace Name:</span>
                    <span class="col-8 mt-2" ng-hide="isEditing=='name'" ng-click="setEdit('name')">
                        <h2 class="h5 bold text-weaverlight">{{workspaceConfig.allNames[0]}}</h2>
                    </span>
                    <span class="col-8 mt-2 form-inline form-group" ng-show="isEditing=='name'">
                        <input type="text" class="form-control" style="width:350px" ng-model="newName"/>
                        <button class="m-2 btn btn-primary btn-raised" ng-click="addWorkspaceName(newName)">Change Name</button>
                        <button class="m-2 btn btn-danger btn-raised" ng-click="setEdit('')">Cancel</button>
                    </span>
                </div>
                <div class="row my-2 border-bottom border-1">
                    <span ng-click="setEdit('vision')" class="col-1 fixed-width-sm bold labelColumn mt-2">Vision:</span>
                    <span class="col-8 mt-2" ng-hide="isEditing=='vision'" ng-dblclick="setEdit('vision')">
                        <div ng-bind-html="visionHtml"></div>
                        <div ng-hide="visionHtml" class="clicker"></div>
                        <span ng-click="toggleFrontPage('showVisionOnFrontPage')" class="labelCheck">
                        <span class="text-secondary" ng-show="workspaceConfig.wsSettings.showVisionOnFrontPage">
                            <i class="fa fa-check-circle"></i> Show vision on Front Page</span>
                        <span class="text-secondary" ng-hide="workspaceConfig.wsSettings.showVisionOnFrontPage">
                            <i class="fa fa-circle-o"></i> Don't show vision on Front Page
                        </span>
                        </span>
                        </span>
                        <span class="col-8 mt-2 form-inline form-group" ng-show="isEditing=='vision'">
                            <textarea class="form-control  markDownEditor"  placeholder="Enter a vision statement for the circle working in this  workspace, if any" ng-model="workspaceConfig.vision" rows="14" cols="80">
                            </textarea>
                            <button ng-click="saveOneField('vision')" class="btn btn-primary btn-raised">Save</button>
                            <button ng-click="saveOneField('frozen')" class="btn btn-warning btn-raised">Cancel</button>
                        </span>
                        
                </div>
                <div class="row my-2 border-bottom border-1">
                    <span class="col-1 bold fixed-width-sm labelColumn mt-2" ng-click="setEdit('mission')">Mission:</span>
                    <span class="col-8 mt-2" ng-hide="isEditing=='mission'" ng-dblclick="setEdit('mission')">
                        <div ng-bind-html="missionHtml"></div>
                        <div ng-hide="missionHtml" class="clicker"></div>
                        <span ng-click="toggleFrontPage('showMissionOnFrontPage')" class="labelCheck">
                            <span class="text-secondary" ng-show="workspaceConfig.wsSettings.showMissionOnFrontPage">
                                <i class="fa fa-check-circle"></i> Show mission on Front Page</span>
                            <span class="text-secondary" ng-hide="workspaceConfig.wsSettings.showMissionOnFrontPage">
                                <i class="fa fa-circle-o"></i> Don't show mission on Front Page</span>
                        </span>
                    </span>
                    <span class="col-8 mt-2 form-inline form-group" ng-show="isEditing=='mission'">
                        <textarea class="form-control editBoxStyle markDownEditor" placeholder="Enter a mission statement for the circle working in this  workspace, if any" ng-model="workspaceConfig.mission" rows="14" cols="80"></textarea> 
                        <button ng-click="saveOneField('mission')" class="btn btn-primary btn-raised">Save</button> 
                        <button ng-click="saveOneField('frozen')" class="btn btn-warning btn-raised">Cancel</button>
                    </span>
                </div>
                <div class="row my-2 border-bottom border-1" >
                    <span class="col-1 bold fixed-width-sm labelColumn mt-2" ng-click="setEdit('purpose')" >Aim:</span>
                    <span class="col-8 mt-2" ng-hide="isEditing=='purpose'" ng-dblclick="setEdit('purpose')">
                        <div ng-bind-html="purposeHtml"></div>
                        <div ng-hide="purposeHtml" class="clicker"></div>
                        <span ng-click="toggleFrontPage('showAimOnFrontPage')" class="labelCheck">
                            <span class="text-secondary" ng-show="workspaceConfig.wsSettings.showAimOnFrontPage">
                            <i class="fa fa-check-circle"></i> Show aim on Front Page</span>
                            <span class="text-secondary" ng-hide="workspaceConfig.wsSettings.showAimOnFrontPage">
                            <i class="fa fa-circle-o"></i> Don't show aim on Front Page</span>
                        </span>
                    </span>
                    <span class="col-8 mt-2 form-inline form-group" ng-show="isEditing=='purpose'">
                        <textarea class="form-control editBoxStyle markDownEditor" placeholder="Enter a public description of the work that will be done in this workspace, the aim of this workspace." ng-model="workspaceConfig.purpose" rows="14" cols="80"></textarea>
                        <button ng-click="saveOneField('purpose')" class="btn btn-primary btn-raised">Save</button>
                        <button ng-click="saveOneField('frozen')" class="btn btn-warning btn-raised">Cancel</button>
                    </span>
                </div>
                <div class="row my-2 border-bottom border-1">
                    <span class="col-1 bold fixed-width-sm labelColumn mt-2" ng-click="setEdit('domain')" >Domain:</span>
                    <span class="col-8 mt-2" ng-hide="isEditing=='domain'" ng-click="setEdit('domain')">
                        <div ng-bind-html="domainHtml"></div>
                        <div ng-hide="domainHtml" class="clicker"></div>
                        <span ng-click="toggleFrontPage('showDomainOnFrontPage')" class="labelCheck">
                            <span class="text-secondary" ng-show="workspaceConfig.wsSettings.showDomainOnFrontPage">
                            <i class="fa fa-check-circle"></i> Show domain on Front Page</span>
                            <span class="text-secondary" ng-hide="workspaceConfig.wsSettings.showDomainOnFrontPage">
                            <i class="fa fa-circle-o"></i> Don't show domain on Front Page</span>
                        </span>
                    </span>
                    <span class="col-8 mt-2 form-inline form-group" ng-show="isEditing=='domain'">
                        <textarea class="form-control editBoxStyle markDownEditor" placeholder="Enter a domain statement for the circle working in this  workspace, if any" ng-model="workspaceConfig.domain" rows="14" cols="80"></textarea>
                        <button ng-click="saveOneField('domain')" class="btn btn-primary btn-raised">Save</button>
                        <button ng-click="saveOneField('frozen')" class="btn btn-warning btn-raised">
                        Cancel</button>
                    </span>
                </div>
                <div class="row my-2 border-bottom border-1">
                    <span ng-click="setEdit('frozen')" class="col-1 bold fixed-width-sm labelColumn mt-2">Workspace State:</span>
                    <span class="col-8 mt-3 bold" ng-hide="isEditing=='frozen'" ng-dblclick="setEdit('frozen')">
                        <span ng-show="workspaceConfig.deleted">Workspace is marked to be DELETED the next time the Site Administrator performs a 'Garbage Collect'</span>
                        <span ng-show="workspaceConfig.frozen && !workspaceConfig.deleted">This workspace is FROZEN, it is viewable but can not be changed.</span>
                        <span ng-show="!workspaceConfig.frozen && !workspaceConfig.deleted">Active and available for use including updating contents.</span>
                    </span>
                    <span class="col-8" ng-show="isEditing=='frozen'">
                        <div ng-hide="workspaceConfig.frozen">
                        <button ng-click="workspaceConfig.frozen=true;saveOneField('frozen', true)"
                            class="btn btn-primary btn-raised">
                            Freeze Workspace</button><br/>
                            Use this <b>Freeze</b> to change an active workspace into a frozen workspace where nothing can be changed.  Frozen workspaces do not count toward your quota of workspace in the site.
                        </div>
                        <div ng-show="workspaceConfig.frozen && !workspaceConfig.deleted">
                        <button ng-click="workspaceConfig.frozen=false;saveOneField('frozen', true)"
                            class="btn btn-primary btn-raised">
                            Unfreeze Workspace</button><br/>
                            Use <b>Unfreeze</b> to change workspace to be active so that things in the workspace can be changed.
                            You are only allowed a certain number of active workspaces in a site depending upon 
                            your playment plan.  
                            <br/>
                            If you already have the maximum number of active workspaces, you will not be able to 
                            unfreeze this workspace, until you freeze or delete another active one.
                        </div>
                        <div ng-hide="workspaceConfig.deleted">
                        <button ng-click="workspaceConfig.deleted=true;saveOneField('deleted', true)"
                            class="btn btn-primary btn-raised" >
                            Delete Workspace</button><br/>
                            Use <b>Delete</b> option to delete a workspace.  
                            The workspace will actually remain around until the 
                            <b>Garbage Collect</b> operation is run at the site level.
                            After garbage collection the workspace will be permanently gone,
                            and no information can be retrieved.
                        </div>
                        <div ng-show="workspaceConfig.deleted">
                        <button ng-click="undeleteWorkspace()"
                            class="btn btn-primary btn-raised" >
                            Undelete Workspace</button><br/>
                            If you didn't really want to delete the workspace, 
                            use this <b>Undelete</b> to cancel the delete, 
                            and return the workspace to a frozen state.
                        </div>
                        <div>
                            <button ng-click="isEditing=null" class="btn btn-warning btn-raised">
                            Cancel</button><br/>
                            Use <b>Cancel</b> to close this option without changing the workspace state.
                        </div>
                    </span>
                    
                </div>
                <div class="row my-2 border-bottom border-1">
                    <span ng-click="setEdit('parentKey');backupParent=parentWorkspace" class="col-1 bold fixed-width-sm labelColumn mt-2">Parent Circle:</span>
                    <span class="col-8 mt-2" ng-hide="isEditing=='parentKey'" ng-dblclick="setEdit('parentKey');backupParent=parentWorkspace">
                        <div>{{parentWorkspace.name}}</div>
                        <div ng-hide="workspaceConfig.parentKey" class="clicker"></div>
                    </span>
                    <span class="col-10 mt-2" ng-show="isEditing=='parentKey'">
                            <div class="row my-2">
                                <span>Filter: </span>
                                <span class="my-2"><input ng-model="parentFilter" class="form-control">{{parentFilter}}</span>
                            </div>
                            <div class="row " >
                                <span class="col-12 d-block">
                                    <button ng-repeat="ws in filterParents()" ng-click="saveParentKey(ws)" class="m-2 py-0 btn-comment btn-wide">
                            {{ws.name}}</button></span>
                        </div>
                        <div class="row " >
                            <span class="col-12 d-flex">
                            <button ng-click="parentWorkspace=backupParent;cleanUpParent();isEditing=''" 
                                class="btn btn-danger btn-raised btn-wide">
                            Cancel</button>
                            <button ng-click="deleteParentKey()" 
                                class="btn btn-primary btn-wide btn-raised ms-auto">
                            Remove Parent</button></span>
                        </div>
                    </span>
                    
                </div>
                <div class="row my-2 border-bottom border-1">
                    <span class="col-1 bold fixed-width-sm labelColumn" span ng-click="toggleBool('suppressEmail')">Email</span>
                    <span class="col-8 mt-2">
                        <span class="text-secondary" ng-show="workspaceConfig.suppressEmail">
                            <i class="fa fa-check-circle"></i> Suppress: email generated in this workspace will be saved to the database, but will not actually be sent as email.</span>
                        <span class="text-secondary" ng-hide="workspaceConfig.suppressEmail">
                            <i class="fa fa-circle-o"></i> Normal: email in this workspace functions normally</span>
                    </span>
                </div>
            </div>
        </div>
        <div style="margin:75px"></div>

