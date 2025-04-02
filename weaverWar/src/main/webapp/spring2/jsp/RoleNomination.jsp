<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to edit roles");

    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    String roleName    = ar.reqParam("role");
    String termKey    = ar.reqParam("term");
    
    //page must work for both workspaces and for sites
    NGWorkspace ngc = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngc);
    UserProfile uProf = ar.getUserProfile();

    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }    
    
    WorkspaceRole theRole = ngc.getWorkspaceRole(roleName);
    JSONObject role = theRole.getJSONDetail();


%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {
    setUpLearningMethods($scope, $modal, $http);
    $scope.role = <%role.write(out,2,4);%>;
    $scope.origRole = <%role.write(out,2,4);%>;
    window.setMainPageTitle("Nominate Role: "+$scope.role.name);
    $scope.termKey = "<%ar.writeJS(termKey);%>";
    $scope.thisUser = "<%ar.writeJS(ar.getBestUserId());%>";
    $scope.siteId = "<%ar.writeJS(siteId);%>";
    $scope.comment = "";
    $scope.setComment = function(newComm) {
        $scope.comment = newComm;
    }
    
    $scope.showInput = false;

    $scope.showInput = false;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    function findTerm(role) {
        var res = {};
        role.terms.forEach( function(term) {
            if (term.key == $scope.termKey) {
                if (!term.nominations) {
                    term.nominations = [];
                }
                res = term;
            }
        });
        return res;
    }
    $scope.term = findTerm($scope.role);
    $scope.origTerm = findTerm($scope.origRole);
    
    if (!$scope.term.state) {
        $scope.term.state = "Initial Check";
    }

    $scope.findNom = function() {
        var res = {owner: $scope.thisUser};
        $scope.term.nominations.forEach( function(anom) {
            if (anom.owner == $scope.thisUser) {
                res = anom;
            }
        });
        return res;
    }
    $scope.nom = $scope.findNom();
    
    
    $scope.stateStyle = function() {
        if ($scope.term.state=="Initial Check") {
            return {"background-color": "pink"};
        }
        if ($scope.term.state=="Nominating") {
            return {"background-color": "lightgreen"};
        }
        if ($scope.term.state=="Changing") {
            return {"background-color": "skyblue"};
        }
        if ($scope.term.state=="Proposing") {
            return {"background-color": "yellow"};
        }
        if ($scope.term.state=="Completed") {
            return {"background-color": "darkgray"};
        }
    }
    $scope.isNominating = function() {
        return ($scope.term.state=="Nominating");
    }
    $scope.showNominations = function() {
        return ($scope.term.state!="Completed");
    }
    $scope.isProposingCompleting = function() {
        return ($scope.term.state=="Proposing" || $scope.term.state=="Completed");
    }
    $scope.isProposing = function() {
        return ($scope.term.state=="Proposing");
    }
    $scope.isCompleted = function() {
        return ($scope.term.state=="Completed");
    }
    
    $scope.loadPersonList = function(query) {
        return AllPeople.findMatchingPeople(query, $scope.siteId);
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
    $scope.getNominations = function() {
        return $scope.term.nominations;
    }
    $scope.missingNomination = function() {
        var ret = true;
        $scope.term.nominations.forEach( function(item) {
            if (item.owner == $scope.thisUser) {
                ret = false;
            }
        });
        return ret;
    }
   
    $scope.consent = function() {
        $scope.updateResponse("Consent");
    }
    $scope.object = function() {
        $scope.updateResponse("Object");
    }
    $scope.updateResponse = function(choice) {
        var respObj = {};
        respObj.owner = $scope.thisUser;
        respObj.comment = $scope.comment;
        respObj.choice = choice;
        var termObj = {};
        termObj.key = $scope.termKey;
        termObj.responses = [];
        termObj.responses.push(respObj);
        $scope.updateTerm(termObj);
    }
    $scope.save = function() {
        $scope.updateTerm($scope.term);
    }
    $scope.updateState = function(newState) {
        var termObj = {};
        termObj.key = $scope.termKey;
        termObj.state = newState;
        $scope.updateTerm(termObj);
    }
    $scope.updateNomination = function(nom) {
        var termObj = {};
        termObj.key = $scope.termKey;
        termObj.nominations = [];
        termObj.nominations.push(nom);
        $scope.updateTerm(termObj);
    }
    $scope.updatePlayers = function() {
        var termObj = {};
        termObj.key = $scope.termKey;
        termObj.players = [];
        termObj.players = cleanUserList($scope.term.players);
        $scope.updateTerm(termObj);
    }
    $scope.updateTerm = function(termObj) {
        var roleObj = {};
        roleObj.symbol = $scope.role.symbol;
        roleObj.terms = [];
        roleObj.terms.push(termObj);
        $scope.updateRole(roleObj);
    }
    $scope.updateRole = function(role) {
        console.log("UPDATING role: ", role);
        role.terms.forEach( function(term) {
            if (term.players) {
                term.players.forEach( function(item) {
                    if (!item.uid) {
                        item.uid = item.name;
                    }
                });
            }
        });
        var key = role.symbol;
        var postURL = "roleUpdate.json?op=Update";
        var postdata = angular.toJson(role);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.role = data;
            $scope.origRole = JSON.parse(JSON.stringify(data));
            $scope.term = findTerm($scope.role);
            $scope.origTerm = findTerm($scope.origRole);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    
    
    
    $scope.openNominationModal = function (nom) {
        if (!$scope.showNominations()) {
            return;  //avoid nominations when completed
        }
        var isNew = false;
        if (!nom) {   
            nom = {"owner":$scope.thisUser};
            isNew = true;
        }
        var modalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>new_assets/templates/NominationModal.html?<%=templateCacheDefeater%>',
            controller: 'NominationModal',
            size: 'lg',
            backdrop: "static",
            resolve: {
                nomination: function () {
                    return JSON.parse(JSON.stringify(nom));
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
    
    $scope.deleteNomination = function(nom) {
        if (!confirm("Are you sure you want to delete the nomination made by "+nom.owner+"?")) {
            return;
        }
        let newList = [];
        $scope.term.nominations.forEach( function(item) {
            if (item.owner != nom.owner) {
                newList.push(item);
            }
            else {
                newList.push({owner: nom.owner, "_DELETE_ME_": "_DELETE_ME_"})
            }
        });
        $scope.term.nominations = newList;
        $scope.updateRole($scope.role);
    } 

});

</script>
<script src="../../../jscript/AllPeople.js"></script>

<div class="container-fluid override mb-4 mx-3 d-inline-flex">
    <span class="dropdown mt-1">
        <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
            data-bs-toggle="dropdown" aria-expanded="false">
        </button>
        <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
            <li>
                <button class="dropdown-item" onclick="window.location.reload(true)">Refresh</button>
            </li>
        </ul>
    </span>
    <span>
        <h1 class="d-inline page-name" id="mainPageTitle"></h1>
    </span>
</div>

<%@include file="ErrorPanel.jsp"%>

<div class="container-fluid">
    <div class="row col-md-12 d-flex m-3">
      <span class="nav-item dropdown col-3">
        <button class="btn btn-default btn-raised dropdown-toggle" 
                type="button" id="nominatePhase" data-toggle="dropdown" ng-style="stateStyle()">
            {{term.state}}: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="nominationPhase">
          <li role="presentation"><a class="dropdown-item h6" role="menuitem" tabindex="-1"
              ng-click="updateState('Initial Check')">State &#10132; Initial Check</a></li>
          <li role="presentation"><a class="dropdown-item h6" role="menuitem" tabindex="-1"
              ng-click="updateState('Nominating')">State &#10132; Nominating</a></li>
          <li role="presentation"><a class="dropdown-item h6" role="menuitem" tabindex="-1"
              ng-click="updateState('Changing')">State &#10132; Changing</a></li>
          <li role="presentation"><a class="dropdown-item h6" role="menuitem" tabindex="-1"
              ng-click="updateState('Proposing')">State &#10132; Proposing</a></li>
          <li role="presentation"><a class="dropdown-item h6" role="menuitem" tabindex="-1"
              ng-click="updateState('Completed')">State &#10132; Completed</a></li>
        </ul>
      </span>
        <div class="col-9">
            <div class="form-group h5">
                <label for="status">Term:</label>
                <span>
                    {{term.termStart|date:"dd-MMM-yyyy"}}  . . .   {{term.termEnd|date:"dd-MMM-yyyy"}}
                </span> 
            </div>
        </div>
    </div>
    <div class="row col-md-12 d-flex m-3">
        <div ng-show="term.state=='Initial Check'">
            <div class="guideVocal h6">
            <b>Step 1:</b> Check that the dates for this term is correct.   
            If you modify the dates, press save before continuing.</div>
            <div class="d-flex">
            <button class="btn btn-primary btn-raised my-3 " ng-click="updateState('Nominating')">
                Next &nbsp;<i class="fa fa-forward"></i></button>
            </div>
        </div>
        <div class="row col-md-12 d-flex my-3 gx-5">
            <span class="form-group col-1">
                <label for="status" class="h6 justify-content-end">Term Start:</label>
            </span>
            <span datetime-picker ng-model="term.termStart"  
                    class="form-control col-3" style="max-width:300px">
                    {{term.termStart|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm  '&nbsp;  GMT'Z"}}
            </span> 

            <span class="form-group col-1">
                <label for="status" class="h6">Term End:</label>
            </span>

            <span datetime-picker ng-model="term.termEnd"  
                    class="form-control col-3" style="max-width:300px">
                    {{term.termEnd|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm  '&nbsp;  GMT'Z"}}
            </span> 
        </div>

        <div class="form-group" title="The duration is the number of days between the start and end dates.">
            <label for="status" class="h5">Duration:</label>
            <span class="h5"><em>
                {{ getDays(term) }} Days</em>
            </span>
        </div>
        <div class="col-10 m-2">
            <div class="my-3 form-group d-flex">
                <button class="btn btn-primary btn-raised my-3 ms-auto" ng-click="save()"
                ng-hide="term.termEnd==origTerm.termEnd && term.termStart==origTerm.termStart">Save</button>
            </div>
            <div ng-show="term.state=='Nominating'">
            <div class="guideVocal h6">
                <b>Step 2:</b> Enter the email address of the person you want to nominate and give a good reason for why they are good for this role. Other people can access this page and make nominations as well. You will only see your own nomination at this stage.<br/>
                    <div class="my-3 form-group d-flex"><button class="btn btn-primary ms-auto me-3" ng-click="updateState('Initial Check')">
                <i class="fa fa-backward"></i> &nbsp;Back </button>
                <button class="btn btn-primary" ng-click="updateState('Changing')">
                Next &nbsp;<i class="fa fa-forward"></i></button></div>
            </div>
            <div class=" col-10 m-2">
        
            <div class="row form-group" ng-show="showNominations()">
                <label for="synopsis" class="h5">Nominations:</label>
            </div>
            <div class="row form-group col-12 d-flex m-2">
                <span class="col-1"></span>
                <span class="col-4">Nominator</span>
                <span class="col-2">Nominee</span>
                <span class="col-4">Reason</span>
                <span class="col-1"></span>
            </div>
                <div class="row form-group col-12 d-flex m-2" ng-show="missingNomination()">
                    <span class="actions col-1">
                        <button type="button" name="edit" class="btn btn-tiny btn-comment" 
                                ng-click="openNominationModal()">
                            <span class="fa fa-edit fa-md"></span>
                        </button>
                    </span>
                    <span class="col-4" ng-click="openNominationModal()">{{thisUser}}</span>
                    <span class="col-2" ng-click="openNominationModal()" colspan="2"> 
                        <i>Click here to make a nomination</i></span>
                    <span class="col-3" ><button type="button" name="edit" class="btn btn-primary" 
                                ng-click="deleteNomination(nom)">
                            <span class="fa fa-trash"></span>
                        </button></span>
                </div>
                <div class="row form-group col-12 d-flex m-2" ng-repeat="nom in getNominations()" ng-show="nom.owner==thisUser">
                    <span class="actions col-1">
                        <button type="button" name="edit" class="btn btn-tiny btn-comment" 
                                ng-click="openNominationModal(nom)">
                            <span class="fa fa-edit"></span>
                        </button>
                    </span>
                    <span class="col-4" ng-click="openNominationModal(nom)">{{nom.owner}}</span>
                    <span class="col-2" ng-click="openNominationModal(nom)">{{nom.nominee}}</span>
                    <span class="col-4"  ng-click="openNominationModal(nom)" style="max-width:400px">{{nom.comment}}</span>
                    <span class="actions col-1">
                        <button type="button" name="delete" class=" btn btn-danger btn-tiny btn-comment ms-auto" 
                                ng-click="deleteNomination(nom)">
                            <span class="fa fa-trash"></span>
                        </button></span>
                </div>
                <div class="row form-group col-12 d-flex m-2" ng-repeat="nom in getNominations()" ng-hide="nom.owner==thisUser">
                    <span class="actions col-1">
                        <button type="button" name="edit" class="btn btn-tiny btn-comment" 
                                ng-click="openNominationModal(nom)">
                            <span class="fa fa-edit"></span>
                        </button>
                    </span>
                    <span class="col-4" ng-click="openNominationModal(nom)">{{nom.owner}}</span>
                    <span class="col-2" ng-click="openNominationModal(nom)"><i style="color:lightgray">hidden</i></span>
                    <span class="col-4" ng-click="openNominationModal(nom)" style="max-width:400px;color:lightgray">
                       <i>hidden</i></span>
                       <span class="actions col-1">
                        <button type="button" name="delete" class=" btn btn-danger btn-tiny btn-comment ms-auto" 
                                ng-click="deleteNomination(nom)">
                            <span class="fa fa-trash"></span>
                        </button></span>
                    </div >
                    <div class="row form-group col-12 d-flex m-2">
                        <span class="actions col-3"></span>
                    <span ng-click="openNominationModal()"><button class="btn btn-primary btn-raised">Add Nomination</button></span>
                    <span ng-click="openNominationModal()" class="col-2"> </span>
                    </div>
                </div>
                <div ng-show="term.nominations.length==0" class="guideVocal">
                There are no nominations for this term at this time.
                </div>
            </div>
            <hr/>
        </div>        
    </div>
    <div class="col-10 m-2">
        <div class="my-3 form-group d-flex">
            <div ng-show="term.state=='Changing'">
                <div class="guideVocal h6">
                    <b>Step 3:</b> Review all of the nominations made so far. People can change their nominations if they want to.<br/>
                </div>

                <div class="my-3 form-group d-flex"><button class="btn btn-primary ms-auto me-3" ng-click="updateState('Nominating')">
                    <i class="fa fa-backward"></i> &nbsp;Back </button>
                    <button class="btn btn-primary" ng-click="updateState('Proposing')">Next &nbsp;<i class="fa fa-forward"></i></button>
                </div>
            </div>
        </div>
    </div>
    <div class="col-10 m-2">
        <div class="row form-group col-12 d-flex m-2"  ng-show="showNominations()">
            <span class="actions col-1">
                <label for="synopsis" class="h5">Nominations:</label></span>

                <div class="row form-group col-12 d-flex m-2">
                    <span class="col-1"></span>
                    <span class="col-4"></span>
                    <span class="col-2">Nominee</span>
                    <span class="col-4">Reason</span>
                    <span class="col-1"></span>
                </div>

                <div class="row form-group col-12 d-flex m-2" ng-repeat="nom in getNominations()" >
                    <span class="actions col-1">
                        <button type="button" name="edit" class="btn btn-tiny btn-comment" 
                                ng-click="openNominationModal(nom)">
                            <span class="fa fa-edit"></span>
                        </button></span>
                        <span class="col-4"  ng-click="openNominationModal(nom)">{{nom.owner}}</span>
                        <span class="col-2"  ng-click="openNominationModal(nom)">{{nom.nominee}}</span>
                        <span class="col-4"  ng-click="openNominationModal(nom)" style="max-width:400px">{{nom.comment}}</span>
                    </div>
                <div class="row form-group col-12 d-flex m-2" ng-show="missingNomination()">
                    <span class="actions col-1">
                        <button type="button" name="edit" class="btn btn-tiny btn-comment" 
                                ng-click="openNominationModal()">
                            <span class="fa fa-edit"></span>
                        </button>
                    </span>
                    <span class="col-4" ng-click="openNominationModal()">{{thisUser}}</span>
                    <span class="col-2" ng-click="openNominationModal()"> 
                        <i>Click here to make a nomination</i></span>
                </div>
            </div>
                <div ng-show="term.nominations.length==0" class="guideVocal">
                There are no nominations for this term at this time.
                </div>
            </div>
            <hr/>
        </div>
    </div>
    <div class="col-10 m-2">
        <div class="my-3 form-group d-flex">
            <div ng-show="term.state=='Proposing'">
                <div class="guideVocal h6">
                    <b>Step 4:</b> Given the nominations, the leader makes a proposal for role player, and each participant can express consent or object to that.<br/>
                </div>
                <div class="my-3 form-group d-flex"><button class="btn btn-primary ms-auto me-3" ng-click="updateState('Changing')">
                    <i class="fa fa-backward"></i> &nbsp;Back </button>
                    <button class="btn btn-primary" ng-click="updateState('Completed')">Next &nbsp;<i class="fa fa-forward"></i></button>
                </div>
                <div class="row form-group col-12 d-flex m-2">
                    <span class="actions col-2">
                <label for="status" class="h6">Players (Proposed):</label></span>
                <span class="col-10">
                <tags-input ng-model="term.players" placeholder="Enter user name or id" 
                        display-property="name" key-property="uid" 
                        replace-spaces-with-dashes="false" add-on-space="true" add-on-comma="true"
                        on-tag-added="updatePlayers()" 
                        on-tag-removed="updatePlayers()">
                    <auto-complete source="loadPersonList($query)" min-length="1"></auto-complete>
                </tags-input></span>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
                   <li role="presentation"><a class="dropdown-item" role="menuitem" title="{{add}}"
                      ng-click="">Remove Label:<br/>{{role.name}}</a></li>
                </ul>
            </div>
            <div class="row form-group col-12 d-flex m-2" ng-show="isProposing()"><span class="col-2">
                <label for="status" class="h6"><br/>Your Response:</label></span>
                <span class="col-10">
                <textarea ng-model="comment" class="form-control"></textarea></span>
            </div>
            <div class="col-12 m-2">
                <div class="my-3 form-group d-flex" ng-show="isProposing()">
                <button ng-click="consent()" class="btn btn-primary ms-auto me-3">Consent</button>
                <button ng-click="object()" class="btn btn-primary ">Object</button>
            </div>
            <div class="row form-group col-12 d-flex m-2">
                <label for="status" class="h5"><br/>All Responses So Far:</label>
                <div class="col-10 m-2">
                    <div class="row form-group col-12 d-flex m-2">
                        <span class="col-1"></span>
                        <span class="col-4">Member</span>
                        <span class="col-2">Choice</span>
                        <span class="col-4">Comment</span>
                        <span class="col-1"></span>
                    </div>

                    <div class="row form-group col-12 d-flex m-2" ng-repeat="resp in term.responses" ng-click="setComment(resp.comment)">
                        <span class="col-1"></span>
                        <span class="col-4">{{resp.owner}}</span>
                        <span class="col-2">{{resp.choice}}</span>
                        <span class="col-4">{{resp.comment}}</span>
                        <span class="col-1"></span>
                    </div>
                </div>
            </div>
        </div>
    </><!-- What is below this line???-->
    <div class="col-10 m-2">
        <div class="my-3 form-group d-flex">
            <div ng-show="term.state=='Completed'">
                <div class="guideVocal h6">
                    <b>Step 5:</b> Celebrate!  You are done.   The selected person(s) will be automatically placed in the role during the dates specified by the term.<br/></div>
                    <div class="my-3 form-group d-flex">
                        <button class="btn btn-primary ms-auto me-3"  ng-click="updateState('Proposing')">
                            <i class="fa fa-backward"></i>Back </button>
                    </div>
                    <div class="row form-group col-12 d-flex m-2">
                        <span class="actions col-2">
                        <label for="status" class="h5">Players </label></span>
                        <span class="col-10">
                <tags-input ng-model="term.players" placeholder="Enter user name or id" 
                        display-property="name" key-property="uid" 
                        replace-spaces-with-dashes="false" add-on-space="true" add-on-comma="true"
                        on-tag-added="updatePlayers()" 
                        on-tag-removed="updatePlayers()">
                    <auto-complete source="loadPersonList($query)" min-length="1"></auto-complete>
                </tags-input>   </span>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
                   <li role="presentation"><a role="menuitem" title="{{add}}"
                      ng-click="">Remove Label:<br/>{{role.name}}</a></li>
                </ul>
            </div>
            <div class="form-group">
                <label for="status"><br/>All Confirmations:</label>
                <table class="table">
                    <tr>
                        <td><label>Member</label></td>
                        <td><label>Choice</label></td>
                        <td><label>Comment</label></td>
                    </tr>
                    <tr ng-repeat="resp in term.responses" ng-click="setComment(resp.comment)">
                        <td>{{resp.owner}}</td>
                        <td>{{resp.choice}}</td>
                        <td>{{resp.comment}}</td>
                    </tr>
                </table>
            </div>
        </div>
        <div class="col-md-6 col-sm-12">
            <div class="form-group" ng-show="isProposing()">
                <label for="status">Your Response:</label>
                <textarea ng-model="comment" class="form-control"></textarea>
            </div>
            <div class="form-group" ng-show="isProposing()">
                <button ng-click="consent()" class="btn btn-primary btn-raised">Consent</button>
                <button ng-click="object()" class="btn btn-primary btn-raised">Object</button>
            </div>
        </div>
    </div>
</div>

<script src="<%=ar.retPath%>new_assets/templates/NominationModal.js"></script>
