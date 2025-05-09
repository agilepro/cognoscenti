<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.NGLabel"
%><%@page import="com.purplehillsbooks.weaver.LabelRecord"
%><%


    ar.assertLoggedIn("You need to Login to manipulate labels.");
    Cognoscenti cog = ar.getCogInstance();
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    ar.assertAccessWorkspace("Must be a member to see meetings");
    NGBook site = ngw.getSite();

    JSONArray labelList = new JSONArray();
    for (NGLabel label : ngw.getAllLabels()) {
        if (label instanceof LabelRecord) {
            labelList.put(label.getJSON());
        }
    }
    
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }
    
    JSONArray allWorkspaces = new JSONArray();
    JSONObject thisWorkspace = null;
    for (NGPageIndex ngpis : cog.getNonDelWorkspacesInSite(siteId)) {
        if (ngpis.isDeleted) {
            continue;
        }
        if (ngpis.containerKey.equals(pageId)) {
            thisWorkspace = ngpis.getJSON4List();
            continue;
        }
        allWorkspaces.put(ngpis.getJSON4List());
    }
    

%>


<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Labels");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.allWorkspaces = <%allWorkspaces.write(out,2,4);%>;
    $scope.thisWorkspace = <%thisWorkspace.write(out,2,4);%>;
    $scope.selectedWS = {};
    $scope.newLabelsCreated = [];
    
    $scope.allLabels = <%= labelList.toString() %>;
    
    
    $scope.openEditLabelsModal = function (label) {
        
        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>new_assets/templates/EditLabels.html<%=templateCacheDefeater%>',
            controller: 'EditLabelsCtrl',
            size: 'lg',
            resolve: {
                siteInfo: function () {
                  return label;
                },
                siteInfo: function () {
                    return $scope.siteInfo;
                },
            }
        });

        attachModalInstance.result
        .then(function (updatedLabel) {
            // Handle saving the updated label
            const index = $scope.allLabels.findIndex(l => l.id === updatedLabel.id);
            if (index !== -1) {
                $scope.allLabels[index] = updatedLabel; // Update the label in the list
            }
        }, function () {
            // Cancel action
        });
    };

    $scope.selectWorkspace = function(ws) {
        $scope.selectedWS = ws;
        $scope.newLabelsCreated = [];
        console.log("SELECTED", ws);
    }
    $scope.cancelCopy = function() {
        $scope.selectedWS = {};
        console.log("SELECTED", "none");
    }
    $scope.copyLabels = function() {
        let postURL = "copyLabels.json";
        var postObj = {
            "from": $scope.selectedWS.comboKey,
        }
        var postdata = angular.toJson(postObj);
        $http.post(postURL, postdata)
        .then(function (response) {
            $scope.newLabelsCreated = response.data.list;
            console.log("SUCCESS");
        })
        .catch(function (error) {
            console.log("FAILURE", error.data);
            $scope.reportError(error.data);
        });
        $scope.selectedWS = {};        
    }

    $scope.getAllLabels = function () {
        var postURL = "getLabels.json";
        $scope.showError = false;
        $http.post(postURL, "{}")
            .success(function (data) {
                console.log("All labels are gotten: ", data);
                $scope.allLabels = data.list;
                $scope.sortAllLabels();
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    };

    $scope.updateLabel = function (label) {
        var key = label.name;
        var postURL = "labelUpdate.json?op=Create";
        var postdata = angular.toJson(label);
        $scope.showError = false;
        $http.post(postURL, postdata)
            .success(function (data) {
                console.log("Updated Label: ", data);
                $scope.getAllLabels();
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    };

    $scope.deleteLabel = function (label) {
        var specialName = label.name;
        var postURL = "labelUpdate.json?op=Delete";
        var postdata = angular.toJson(label);
        $scope.showError = false;
        $http.post(postURL, postdata)
            .success(function (data) {
                console.log("Deleted Label: ", data);
                $scope.getAllLabels();
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    };
    $scope.createRandomLabel = function() {
        var newLabel = {name: "~new~", editedName: "", color: $scope.colors[0], isEdit:true};
        $scope.allLabels.push(newLabel);
    }
    $scope.sortAllLabels = function() {
        $scope.allLabels.sort( function(a, b){
              if (a.name.toLowerCase() < b.name.toLowerCase())
                return -1;
              if (a.name.toLowerCase() > b.name.toLowerCase())
                return 1;
              return 0;
        });
    };

    $scope.getContrastColor = function (color) {

        const tempEl = document.createElement("div");
        tempEl.style.color = color;
        document.body.appendChild(tempEl);
        const computedColor = window.getComputedStyle(tempEl).color;
        document.body.removeChild(tempEl);

        const match = computedColor.match(/\d+/g);

        if (!match) {
            console.error("Failed to parse color: ", computedColor);
            return "#39134C";
        }
        const [r, g, b] = match.map(Number);

        var yiq = ((r * 299) + (g * 587) + (b * 114)) / 1000;

        return (yiq >= 128) ? '#39134C' : '#ebe7ed';
    };
});




</script>

<!-- MAIN CONTENT SECTION START -->
<div class="container-fluid override mb-4 mx-3 d-inline-flex">
    <span class="dropdown mt-1">
        <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
            data-bs-toggle="dropdown" aria-expanded="false">
        </button>
        <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
            <li>
                <button class="dropdown-item" onclick="window.location.reload(true)">
                    Refresh</button>
                <span class="dropdown-item" type="button">
                    <a role="menuitem" class="nav-link" tabindex="-1" href="LabelList.htm">
                        Admin Settings</a></span>
                <span class="dropdown-item" type="button">
                    <a role="menuitem" class="nav-link" tabindex="-1" href="LabelList.htm">
                        Labels &amp; Folders</a></span>
                <span class="dropdown-item" type="button" aria-labelledby="roleRequest">
                    <a role="menuitem" class="nav-link" tabindex="-1" href="RoleRequest.htm">
                        Role Requests</a></span>
                <span class="dropdown-item" type="button" aria-labelledby="emailPrepared">
                    <a role="menuitem" class="nav-link" href="EmailCreated.htm">
                        Email Prepared</a></span>
                <span class="dropdown-item" type="button" aria-labelledby="EmailSent">
                    <a role="menuitem" class="nav-link" href="EmailSent.htm">
                        Email Sent</a></span>
                <span class="dropdown-item" type="button" aria-labelledby="WorkspaceStats">
                    <a role="menuitem" class="nav-link" href="AdminStats.htm">
                        Workspace Statistics</a></span>
                <span class="dropdown-item" type="button" aria-labelledby="createChildWorkspace">
                    <a class="nav-link" role="menuitem" 
                        href="../$/SiteCreateWorkspace.htm?parent={{workspaceConfig.key}}">
                        Create Child Workspace</a></span>
                <span class="dropdown-item" type="button" aria-labelledby="createSiblingWorkspace">
                    <a class="nav-link" role="menuitem" 
                        href="../$/SiteCreateWorkspace.htm?parent={{workspaceConfig.parentKey}}">
                        Create Sibling Workspace</a></span>
            </li>
        </ul>
    </span>
    <span>
        <h1 class="d-inline page-name" id="mainPageTitle">Labels &amp; Folders</h1>
    </span>
</div>
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

    <div class="container-fluid override mx-2">
        <div class="row col-12 m-2">
            <div class="contentColumn">
                <h2 class="text-secondary fs-3">Edit Labels</h2>
                <div class="well">
                    <span class="mx-2 my-5 h5">Copy Labels from another Workspace:</span>
<br/><br/>
                    <row style="height:50px;padding:15px" ng-hide="selectedWS.name">
                        <span class="h5">
                            Select:
                        </span>
                        <span class="row">
                            <div class="col-md-auto">
                                <button ng-repeat="ws in allWorkspaces" ng-click="selectWorkspace(ws)" class="btn btn-small btn-outline-primary btn-raised" type="button" role="menuitem">{{ws.name}}</button>
                            </div>
                        </span>
                    </row>            
                    <row style="height:50px;padding:15px" ng-show="selectedWS.name">
                        <span class="h5">
                            Confirm:
                        </span>
                    </row>
                    <row style="height:50px;padding:15px" ng-show="selectedWS.name">
                        <span class="p-2">
                            <button ng-click="copyLabels()" class="btn btn-small btn-outline-primary btn-raised">Add all labels from --{{selectedWS.name}}-- to this workspace.</button>
                            <button ng-click="cancelCopy()" class="btn btn-small btn-danger btn-raised">Cancel</button>
                        </span>
                    </row>
                    <row style="height:50px;padding:15px" ng-show="newLabelsCreated.length>0"><br/>
                        <span class="h5 mx-2">
                            Created:
                        </span>
                    </row>
                    <row>
                        <span style="padding:15px">
                            <div ng-repeat="lab in newLabelsCreated">
                            <button style="background-color:{{lab.color}};" ng-style="color:{{getContrastColor(lab.color)}};" class="btn btn-wide labelButton">{{lab.name}}</button>
                            </div>
                        </span>
                    </row>
                </div>
                
                <div class="container-fluid override well">
                    <div class="col-md-auto second-menu">
                        <span class="h5" data-bs-toggle="collapse" data-bs-target="#collapseCurrentLabels" aria-expanded="false" aria-controls="collapseCurrentLabels">
                        Current Labels <i class="fa fa-arrow-down"></i>
                        </span>
                        <div class="collapse" id="collapseCurrentLabels">
                            <div class="card col-md-12 align-top">
                        <div class="card-body override" style="overflow-y: auto; max-height: fit-content; overflow-x: auto;">
            
                        <div class="container-fluid" >
                        <div class="row">
                            <span class="col-4 fs-5 fw-bold">Label</span>
                            <span class="col-4 fs-5 fw-bold">Color</span>
                            <span class="col-4 fs-5 fw-bold"></span>
                        </div>
                        <div class="row" ng-repeat="label in allLabels" ng-click="label.isEdit=true;label.editedName=label.name">
                            <div class="col-4 my-1">
                                <span ng-show="label.isEdit || label.isNew">
                                    <input class="form-control fs-6" style="width:200px; overflow: auto;" type="text" ng-model="label.editedName"
                                    placeholder="Enter Label Name">
                                </span>
                                <span ng-hide="label.isEdit || label.isNew">
                                    <button class="h6 btn btn-wide labelButton" style="background-color:{{label.color}}; color:{{getContrastColor(label.color)}};"  placeholder="Enter Label Name">{{label.name}}</button>
                                </span>
                            </div>
            
                            <div class="col-4">
                                <ul class="btn btn-default" ng-show="label.isEdit || label.isNew">
                                    <li class="btn nav-item py-2 mb-0" id="EditLabels" data-toggle="dropdown" style="background-color:{{label.color}}; color:{{getContrastColor(label.color)}}; cursor:default">
                                        
                                        <span class=" p-2" id="LabelcolorList" data-bs-toggle="dropdown" aria-expanded="false">
                                    {{label.color}} </span>
                                </li>
                            </ul>
                                <div class="h6 py-2 m-2" ng-hide="label.isEdit || label.isNew">
                                    {{label.color}}
                                </div>
                            </div>
                            
                            <div class="col-4 pt-1">
                                <span ng-hide="label.isEdit || label.isNew">
                                    <button class="btn btn-default btn-comment" 
                                    ng-click="label.isEdit=true;label.editedName=label.name">Edit Name</button>
                                </span>
                                <span ng-show="label.isEdit">
                                    <button class="btn btn-small btn-primary" ng-click="updateLabel(label)">Save</button>
                                </span>
                                <span ng-show="label.isEdit">
                                    <button class="btn btn-small btn-danger" ng-click="deleteLabel(label)">Delete</button>
                                </span>
                                <span ng-hide="label.isEdit"></span>
                                <span ng-show="label.isNew">
                                    <button class="btn btn-secondary btn-small" ng-click="updateLabel(label)">Create</button>
                                </span>
                            </div>
                        </div>
                    </div>
                        </div>
                            </div>
                        </div>
                    </div>
                </div>
                    <div class="container-fluid m-2">
                    <button class="btn btn-raised btn-primary btn-wide float-end" type="button" ng-click="openEditLabelsModal()"  aria-labelledby="createNewLabels">
                        Create or Delete Labels
                        </button>
                </div>  

            </div>    
        </div>
    </div>
</div>


<script src="<%=ar.baseURL%>new_assets/templates/EditLabelsCtrl.js"></script>