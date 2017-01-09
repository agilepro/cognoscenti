<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to edit roles");

    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    String roleName    = ar.reqParam("role");
    
    //page must work for both workspaces and for sites
    NGContainer ngc = ar.getCogInstance().getWorkspaceOrSiteOrFail(siteId, pageId);
    ar.setPageAccessLevels(ngc);
    UserProfile uProf = ar.getUserProfile();

    CustomRole theRole = ngc.getRole(roleName);
    JSONObject role = theRole.getJSONDetail();



%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap','ngTagsInput','ui.bootstrap.datetimepicker']);
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {
    $scope.role = <%role.write(out,2,4);%>;
    $scope.showInput = false;

    $scope.showInput = false;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.goNominate = function(aterm) {
        window.location = "roleNomination.htm?role="+$scope.role.name+"&term="+aterm.key;
    }
    $scope.deleteResponsibility = function(resp) {
        if (confirm("Are you sure you want to delete this responsibility?")) {
            resp["_DELETE_ME_"] = true;
            $scope.updateResponsibility(resp);
        }
    }
    $scope.deleteTerm = function(term) {
        if (confirm("Are you sure you want to delete term?")) {
            term["_DELETE_ME_"] = true;
            $scope.updateTerm(term);
        }
    }
    $scope.updateResponsibility = function(resp) {
        var roleObj = {};
        roleObj.name = $scope.role.name;
        roleObj.responsibilities = [];
        roleObj.responsibilities.push(resp);
        $scope.updateRole(roleObj);
    }
    $scope.updateTerm = function(term) {
        var roleObj = {};
        roleObj.name = $scope.role.name;
        roleObj.terms = [];
        roleObj.terms.push(term);
        $scope.updateRole(roleObj);
    }
    $scope.updateRole = function(role) {
        var key = role.name;
        var postURL = "roleUpdate.json?op=Update";
        var postdata = angular.toJson(role);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.role = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.getDays = function(term) {
        if (term.termStart<100000) {
            return 0;
        }
        if (term.termEnd<100000) {
            return 0;
        }
        var diff = Math.floor((term.termEnd - term.termStart)/(1000*60*60*24));
        return diff;
    }

    $scope.openResponsibilityModal = function (resp) {
        var isNew = false;
        if (!resp) {   
            resp = {};
            isNew = true;
        }
        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/Responsibility.html?t=<%=System.currentTimeMillis()%>',
            controller: 'Responsibility',
            size: 'lg',
            backdrop: "static",
            resolve: {
                responsibility: function () {
                    return JSON.parse(JSON.stringify(resp));
                },
                isNew: function() {return isNew;},
                parentScope: function() { return $scope; }
            }
        });

        modalInstance.result.then(function (message) {
            //what to do when closing the role modal?
        }, function () {
            //cancel action - nothing really to do
        });
    };
    
    $scope.openTermModal = function (term) {
        var isNew = false;
        if (!term) {   
            term = {};
            isNew = true;
        }
        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/TermModal.html?t=<%=System.currentTimeMillis()%>',
            controller: 'TermModal',
            size: 'lg',
            backdrop: "static",
            resolve: {
                term: function () {
                    return JSON.parse(JSON.stringify(term));
                },
                isNew: function() {return isNew;},
                parentScope: function() { return $scope; }
            }
        });

        modalInstance.result.then(function (message) {
            //what to do when closing the role modal?
        }, function () {
            //cancel action - nothing really to do
        });
    };
});

</script>
<script src="../../../jscript/AllPeople.js"></script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="col-12">
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default btn-raised dropdown-toggle" 
                    type="button" id="menu1" data-toggle="dropdown">
                Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  ng-click="">Do Nothing</a></li>
            </ul>
          </span>

        </div>
    </div>


    
    <div class="row">
        <div class="col-md-6 col-sm-12">
            <div class="h1">
                Role: {{role.name}}
            </div>
        </div>
    </div>
    <div class="row">
        <div class="col-md-6 col-sm-12">
            <div class="form-group">
                <label for="synopsis">Description:</label>
                <textarea ng-model="role.description" class="form-control" placeholder="Enter description"></textarea>
            </div>
            <div class="form-group">
                <label for="synopsis">Eligibility:</label>
                <textarea ng-model="role.requirements" class="form-control" placeholder="Enter requirements"></textarea>
            </div>
            <div style="margin-bottom:40px">
                <button ng-click="updateRole(role)" class="btn btn-default btn-raised">Save</button>
            </div>
            <div class="form-group">
                <label for="synopsis">Responsibilities:</label>
                <table class="table">
                <tr ng-repeat="aresp in role.responsibilities" >
                    <td class="actions">
                        <button type="button" name="edit" class="btn btn-primary" 
                                ng-click="openResponsibilityModal(aresp)">
                            <span class="fa fa-edit"></span>
                        </button>
                    </td>
                    <td ng-click="openResponsibilityModal(aresp)">{{aresp.text}}</td>
                    <td class="actions">
                        <button type="button" name="delete" class='btn btn-warning' 
                                ng-click="deleteResponsibility(aresp)">
                            <span class="fa fa-trash"></span>
                        </button>
                    </td>
                </tr>
                </table>
                <div ng-show="role.responsibilities.length==0" class="guideVocal">
                There are no responsibilities listed for this role.
                </div>
            </div>
            <div>
                <button ng-click="openResponsibilityModal()" class="btn btn-default btn-raised">
                    Create Responsibility
                </button>
            </div>
        </div>
        
        <div class="col-md-6 col-sm-12">
            <div class="form-group">
                <label for="synopsis">Perpetual:</label>
                <input type="checkbox" ng-model="role.termLength" class="form-control" 
                       placeholder="Enter requirements"/>
            </div>
            <div class="form-group">
                <label for="synopsis">Nominal Term Length (in months):</label>
                <input ng-model="role.termLength" class="form-control"/>
            </div>
            <div class="form-group">
                <label for="synopsis">Current Term Start:</label>
                <input ng-model="role.startDate" class="form-control" placeholder="Date term started"/>
            </div>
            <div class="form-group">
                <label for="synopsis">Current Term End:</label>
                <input ng-model="role.endDate" class="form-control" placeholder="Date term started"/>
            </div>
            <div class="form-group">
                <label for="synopsis">Terms on Record:</label>
                <table class="table">
                <tr>
                    <td></td>
                    <td></td>
                    <td>Start</td>
                    <td>Days</td>
                </tr>
                <tr ng-repeat="aterm in role.terms" >
                    <td class="actions">
                        <button type="button" name="edit" class="btn btn-primary" 
                                ng-click="openTermModal(aterm)">
                            <span class="fa fa-edit"></span>
                        </button>
                    </td>
                    <td class="actions">
                        <button type="button" name="edit" class="btn btn-primary" 
                                ng-click="goNominate(aterm)">
                            <span class="fa fa-flag"></span>
                        </button>
                    </td>
                    <td ng-click="openTermModal(aterm)">{{aterm.termStart |  date}}</td>
                    <td ng-click="openTermModal(aterm)">{{getDays(aterm)}}</td>
                    <td class="actions">
                        <button type="button" name="delete" class='btn btn-warning' 
                                ng-click="deleteTerm(aterm)">
                            <span class="fa fa-trash"></span>
                        </button>
                    </td>
                </tr>
                </table>
                <div ng-show="role.terms.length==0" class="guideVocal">
                There are no designated terms for this role.
                </div>
            </div>
            <div>
                <button ng-click="openTermModal()" class="btn btn-default btn-raised">Create Term</button>
            </div>
        </div>

    </div>

</div>

<script src="<%=ar.retPath%>templates/Responsibility.js"></script>
<script src="<%=ar.retPath%>templates/TermModal.js"></script>
