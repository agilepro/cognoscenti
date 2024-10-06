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
});




</script>


<!-- MAIN CONTENT SECTION START -->
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>



        <div class="container-fluid">
            <div class="row">
                <div class="col-md-auto fixed-width border-end border-1 border-secondary">
                    <span class="btn btn-raised btn-comment btn-secondary m-3 pb-2 pt-0" type="button" ng-click="openEditLabelsModal()"  aria-labelledby="createNewLabels">
                        <a class="nav-link">Create or Delete Labels</a>
                    </span>
                    <span class="btn btn-raised btn-comment btn-secondary m-3 pb-2 pt-0" type="button">Copy Labels from another Workspace
                    </span>
                    <table>
                        <tr ng-hide="selectedWS.name">
                            <td class="h5">
                                From:
                            </td>
                        </tr>
                        <tr>
                            <td class="p-3">
                                <button ng-repeat="ws in allWorkspaces" ng-click="selectWorkspace(ws)" class="my-2 btn-flex btn-comment btn-raised">{{ws.name}}</button>
                            </td>
                        </tr>
                        <tr style="height:50px;padding:15px" ng-show="selectedWS.name">
                            <td class="h5">
                                Confirm:
                            </td>
                        </tr>
                        <tr ng-show="selectedWS.name">
                            <td class="p-2">
                                <button ng-click="copyLabels()" class="btn btn-small btn-outline-secondary btn-raised">Add all labels from --{{selectedWS.name}}-- to this workspace.</button>
                                <button ng-click="cancelCopy()" class="mt-3 btn btn-small btn-danger btn-raised">Cancel</button>
                            </td>
                        </tr>
                        <tr ng-show="newLabelsCreated.length>0">
                            <td class="h5">
                                Created:
                            </td>
                        </tr>
                        <tr>
                            <td style="padding:15px">
                                <div ng-repeat="lab in newLabelsCreated">
                                <button style="background-color:{{lab.color}};" class="labelButton">{{lab.name}}</button>
                                </div>
                            </td>
                        </tr>
                        </table>
                </div>
    
                <div class="d-flex col-9"><div class="contentColumn">
                    <h2 class="text-secondary fs-3">Edit Labels</h2>
                    <div class="container-fluid">
                        <div class="card col-md-12 align-top">
                                <div class="card-body p-2" >
                                    <div class="container">
                                        <div class="row p-1">
                                            <span class="col-3 fs-5 fw-bold">Label</span>
                                            <span class="col-3 fs-5 fw-bold">Color</span>
                                            <span class="col-3 fs-5 fw-bold"></span>
                                        </div>
                                        <div class="row" >
                                            <div class="d-flex my-2" ng-repeat="labels in allLabels" ng-click="label.isEdit=true;label.editedName=lab.name">
                                                <div class="col-md-3">
                                                    <span ng-hide="label.isEdit || label.isNew">
                                                        <button style="background-color:{{lab.color}}" class="btn-flex" placeholder="Enter Label Name">{{lab.name}}What name?</button>
                                                    </span>
                                                    <span ng-show="label.isEdit || label.isNew">
                                                        <input class="form-control fs-6" style="width:200px; overflow: auto;" type="text" ng-model="label.editedName" placeholder="Enter Label Name">
                                                    </span>
                                                    
                                                </div>
    
                                                <span class="col-md-3">
                                                    <ul class="dropdown btn-flex" ng-show="label.isEdit || label.isNew">
                                                        <li class="nav-item dropdown" type="button" id="EditLabels" data-bs-toggle="dropdown" style="background-color:{{rolex.color}}">
                                                            <a class=" mt-0 border border-1 p-2 nav-link dropdown-toggle" id="LabelcolorList" role="button" data-bs-toggle="dropdown" aria-expanded="false">
                                                        {{rolex.color}}color</a>
                        
                                                            <ul class="dropdown-menu" role="menu" aria-labelledby="EditLabels">
                                                                <li role="presentation" ng-repeat="color in colors">
                                                                    <a class="nav-link dropdown-item p-1" style="background-color:{{color}}" href="#"  ng-click="lab.color=color">{{color}}</a></li>
                                                            </ul>
                                                        </li>
                                                    </ul>
                                                    <div class="dropdown" ng-hide="label.isEdit || label.isNew">
                                                    {{lab.color}}
                                                    </div>
                                                </span>
                    
                                            <span class="col-md-3 d-flex">
                                                <span ng-hide="label.isEdit"></span>
                                                <span ng-show="label.isNew">
                                                    <button class="btn  btn-primary btn-flex" ng-click="updateLabel(label)">Create</button>
                                                </span>
                                                <span class="col-1" ng-hide="label.isEdit || label.isNew">
                                                    <button class="btn btn-flex btn-secondary" ng-click="label.isEdit=true;label.editedName=label.name">Edit</button>
                                                </span>
                                                <span ng-show="label.isEdit">
                                                    <button class="btn btn-flex btn-primary me-2" ng-click="updateLabel(label)">Save</button>
                                                </span>
                                                <span class="col-1" ng-show="label.isEdit">
                                                    <button class="mx-2 btn  btn-danger btn-flex" ng-click="deleteLabel(label)">Delete</button>
                                                </span>
                                            </span>
                                        </div>
                                            
                                        </div>
                                    </div>
                                </div>
                        </div>
    
    
                        <div class="mt-5 p-3 bg-primary-subtle text-primary">
                <span class="p-2 h5 my-3" id="attachDocumentLabel">
                    Create Custom Labels
                </span>
                <div class="row d-flex mt-3 ms-2">
                <span class="col-1"><label>Name:</label></span>
                <span class="col-3"><input ng-model="newLabel.editedName" class="form-control"></span>
                <span class="col-3">
                <label>Select Custom Color: </label>{{nameMessage()}}</span>
                <span class="col-md-3 mx-2">
                    <input class="p-0 form-control" type="color" ng-model="newLabel.color">
                    <ul class="dropdown btn btn-flex" ng-show="label.isEdit || label.isNew">
                        <li class="nav-item dropdown" type="button" id="EditLabels" data-bs-toggle="dropdown" style="background-color:{{lab.color}}">
                            <a class=" dropdown-toggle p-4" id="newLabelcolorList" role="button" data-bs-toggle="dropdown" aria-expanded="false">
                    {{lab.color}} </a>
                
                            <ul class="dropdown-menu" role="menu" aria-labelledby="EditNewLabels">
                                <li role="presentation" ng-repeat="color in colors">
                                    <a class="dropdown-item p-1" style="background-color:{{color}}" href="#"  ng-click="newLabel.color=color">{{color}}</a></li>
                            </ul>
                        </li>
                    </ul>
                </span>
                </div>
                <button class="btn btn-primary btn-raised mt-3" ng-click="createLabel()">
                Create</button>
                        </div>
                    </div>  

                </div>    
            </div>
        </div>
    </div>


<script src="<%=ar.baseURL%>new_assets/templates/EditLabelsCtrl.js"></script>