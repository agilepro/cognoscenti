<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to edit roles");

    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }
    
    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    String roleName    = ar.reqParam("role");
    
    //page must work for both workspaces and for sites
    NGContainer ngc = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngc);
    UserProfile uProf = ar.getUserProfile();

    CustomRole theRole = ngc.getRole(roleName);
    JSONObject role = theRole.getJSONDetail();

    boolean canUpdate = ar.canUpdateWorkspace();

%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    $scope.role = <%role.write(out,2,4);%>;
    $scope.showInput = false;
    $scope.canUpdate = <%=canUpdate%>;

    window.setMainPageTitle("Define Role: "+$scope.role.name);
    $scope.showInput = false;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    
    $scope.goNominate = function(aterm) {
        window.location = "RoleNomination.htm?role="+$scope.role.name+"&term="+aterm.key;
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
        roleObj.currentTerm = $scope.role.currentTerm;
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
    $scope.selectCurrentTerm = function(term) {
        $scope.role.currentTerm = term.key;
    }
    
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
    
    $scope.termColor = function(aterm) {
        if ($scope.role.currentTerm == aterm.key) {
            return {"background-color": "lightyellow"};
        }
        else {
            return {"background-color": "white"};
        }
    }

    $scope.openResponsibilityModal = function (resp) {
        var isNew = false;
        if (!resp) {   
            resp = {};
            isNew = true;
        }
        var modalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>new_assets/templates/Responsibility.html<%=templateCacheDefeater%>',
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
    
    $scope.createTerm = function (term) {
        var term = {};
        term.termStart = (new Date()).getTime();
        var estimatedDuration = 365*24*60*60*1000;
        //look for the last term end date
        if ($scope.role.terms) {
            $scope.role.terms.forEach( function(aTerm) {
                var newStart = aTerm.termEnd;
                if (newStart>term.termStart) {
                    term.termStart = newStart;
                    estimatedDuration = (aTerm.termEnd - aTerm.termStart);
                }
            });
        }
        term.termEnd = term.termStart + estimatedDuration;
        if (!$scope.role.terms) {
            $scope.role.terms = [];
        }
        $scope.role.terms.push(term);
        $scope.updateRole($scope.role);
    }

});

</script>

<div>

<%@include file="ErrorPanel.jsp"%>

<div class="container-fluid">    
    <div class="row">
        <div class="col-md-6 col-sm-12">
            <div class="form-group d-flex col-11 m-2">
                <label for="synopsis" class="col-md-3 control-label h5">Description: <span class="fa fa-question-circle helpIcon" ng-click="descHelp=!descHelp"></span></label>
                
                <textarea ng-model="role.description" class=" form-control markDownEditor" placeholder="Enter description"></textarea>
            </div>
            <div class="guideVocal m-4" ng-show="descHelp" ng-click="descHelp=false">
                The description is something for everyone to see to give a basic understanding of 
                what the role are expected to do.  The first place that people will go
                when they want to know more about a role is the description.  You should try to be
                succinct and explain in 3 sentences or less.
            </div>
            <div class="form-group d-flex col-11 m-2 g-2">
                <label for="synopsis" class="col-md-3 control-label h5">Eligibility: <span class="fa fa-question-circle helpIcon" ng-click="eligHelp=!eligHelp"></span></label>
                
                <textarea ng-model="role.requirements" class="form-control markDownEditor" placeholder="Enter requirements"></textarea>
            </div>
            <div class="guideVocal m-4" ng-show="eligHelp" ng-click="eligHelp=false">
                The eligibility is a little more detail about what qualities one would expected
                of a role player.  Perhaps there are some skills required.  In some cases there
                are eligibility requirements, like having participated in the group for a period
                of time before they can be considered for the roles.
            </div>
            <div class="form-group d-flex col-11 m-2 g-2">
                <label for="updateCheck" class="col-md-3 control-label h5">Can Update: <span class="fa fa-question-circle helpIcon" ng-click="updateHelp=!updateHelp"></span></label>
                
                <input type="checkbox" id="updateCheck" ng-model="role.canUpdateWorkspace" class="checkbox-lg "/>
            </div>
            <div class="guideVocal m-4" ng-show="updateHelp" ng-click="updateHelp=false">
                This checkbox confers the ability for the players of this role to be able to 
                update the workspace.  
                A person in any role will be able to see the workspace. 
                Any person in a role checked like this will be able 
                to modify resources in the workspace.   
                People who are not in any update role, but in another role, will have observer access.   
                Please note:
                the administrator at the site level can set which users are allowed to have
                update and which users are observers, and that takes precidence.
            </div>
            <div class="form-group d-flex col-11 m-2 g-2 justify-content-end">
<% if (canUpdate) { %>
                <button ng-click="updateRole(role)" class="btn btn-default btn-primary btn-raised">Save</button>
<% } %>

            </div>
<hr>            <div class="form-group d-flex col-11 m-2">
                <label for="synopsis" class="col-md-4 control-label h5">Responsibilities: <span class="fa fa-question-circle helpIcon" ng-click="respHelp=!respHelp"></span></label>
                <div class="form-group col-10 m-2">
                <div class="row  align-middle" ng-repeat="aresp in role.responsibilities" >
                    <span class="actions col-1 m-0">
                        <button type="button" name="edit" class="col-1 btn btn-tiny btn-comment" 
                                ng-click="openResponsibilityModal(aresp)">
                            <span class="fa fa-edit fa-md"></span>
                        </button>
                    </span>
                    <span class="col-7 h6" ng-click="openResponsibilityModal(aresp)">
                        <div ng-bind-html="aresp.text|wiki"></div>
                    </span>
                    <span class="actions col-1">
                        <button type="button" name="delete" class=" btn btn-danger btn-tiny btn-comment ms-auto" 
                                ng-click="deleteResponsibility(aresp)">
                            <span class="fa fa-trash fa-md"></span>
                        </button>
                    </span>
                </div><div ng-show="role.responsibilities.length==0" class="col-8 guideVocal h6"><i>
                There are no responsibilities listed for this role.</i>
                </div>
                </div>
                
                
            </div>
            
            <% if (canUpdate) { %>
                <div class="form-group ">
                <button ng-click="openResponsibilityModal()" class="btn btn-secondary btn-wide btn-raised">
                    Create Responsibility
                </button></div>
<% } %>
            <div>

                
            </div>
            <div class="guideVocal m-4" ng-show="respHelp" ng-click="respHelp=false">
                You can list a set of responsibilities that the player of this role
                normally takes care of.  These should be descriptive of the role.
                List as many as possible as long as the list is helpful in guiding
                people while they play the role, or in helping people to decide who
                might be the best person for the role.
            </div>
        </div>
        
        <div class="col-md-6 col-sm-12">
            <div class="form-group col-12 m-2">
                <label for="synopsis" class="col-10 control-label h5">Terms of Office: <span class="fa fa-question-circle helpIcon" ng-click="termHelp=!termHelp"></span></label>
            </div>
            <div class="row form-group col-12 d-flex m-2">
                <span class="col-1"></span>
                <span class="col-2 h6">Start</span>
                <span class="col-2 h6">End</span>
                <span class="col-4 h6">State</span>
                <span class="col-1"></span>
            </div>
            <div class="row form-group col-12 d-flex m-2" ng-repeat="aterm in role.terms" >
                    <span class="actions col-1" title="Edit this term to sent time span and to make it the current term. Nominations and elections of members to the term of the role">
                        <button type="button" name="edit" class="btn btn-tiny btn-comment" 
                                ng-click="goNominate(aterm)">
                            <span class="fa fa-edit fa-md"></span>
                        </button>
                    </span>
                    <span class="col-2" ng-click="goNominate(aterm)" ng-style="termColor(aterm)" 
                        title="Date that the term is proposed to start - click to edit">
                        {{aterm.termStart |  date}}</span>
                    <span class="col-2" ng-click="goNominate(aterm)"
                        title="click to edit">
                        {{aterm.termEnd |  date}}</span>
                    <span class="col-4" ng-click="goNominate(aterm)"
                        title="click to edit">
                        {{aterm.state}}</span>
                    <span class="actions col-1">
                        <button type="button" name="delete" class=" btn btn-danger btn-tiny btn-comment ms-auto" 
                                ng-click="deleteTerm(aterm)"
                                title="Click here to delete this term">
                            <span class="fa fa-trash"></span>
                        </button>
                    </span>
            </div>
            <div ng-show="role.terms.length==0" class="guideVocal h6"><em>
                    There are no designated terms for this role.  Create one!</em><br/>
            </div>              
    <div class="form-group ">
<% if (canUpdate) { %>
    <div class="form-group">
                <button ng-click="createTerm()" class="btn btn-secondary btn-wide btn-raised">
                    <span class="fa fa-plus"></span> Create New Term</button>
                </div>
<% } %>
            </div>
            <div class="guideVocal m-4" ng-show="termHelp || role.terms.length==0" ng-click="termHelp=false">
                You can create a 'term of office' for this role, those are particular time periods for which 
                people will hold the role.  <br/>
                <br/>
                <b>Role Elections:</b><br/>
                People are elected to a term, that is, a period of time that they hold the role.  
                In order to hold an election, first
                define a term and then there are options for 
                electing the role player.<br/>
                <br/>
                <b>Non Elected Roles:</b><br/>
                Alternatively, you can just assign people to a role indefinitely, and
                they will remain in that role until it is changed.
            </div>
        </div>

    </div>

</div>

<script src="<%=ar.retPath%>new_assets/templates/Responsibility.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/TermModal.js"></script>
