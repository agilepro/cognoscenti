<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to edit roles");

    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    String roleName    = ar.reqParam("role");
    String termKey    = ar.reqParam("term");
    
    //page must work for both workspaces and for sites
    NGContainer ngc = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngc);
    UserProfile uProf = ar.getUserProfile();

    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }    
    
    CustomRole theRole = ngc.getRole(roleName);
    JSONObject role = theRole.getJSONDetail();


%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {
    $scope.role = <%role.write(out,2,4);%>;
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

    $scope.findTerm = function() {
        var res = {};
        $scope.role.terms.forEach( function(term) {
            if (term.key == $scope.termKey) {
                if (!term.nominations) {
                    term.nominations = [];
                }
                res = term;
            }
        });
        return res;
    }
    $scope.term = $scope.findTerm();
    if (!$scope.term.state) {
        $scope.term.state = "Initial Check";
    }

    $scope.findNom = function() {
        var res = {};
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
        if (!$scope.isNominating()) {
            return $scope.term.nominations;
        }
        var ret = [];
        $scope.term.nominations.forEach( function(item) {
            if (item.owner == $scope.thisUser) {
                ret.push(item);
            }
        });
        return ret;
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
        roleObj.name = $scope.role.name;
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
        var key = role.name;
        var postURL = "roleUpdate.json?op=Update";
        var postdata = angular.toJson(role);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.role = data;
            $scope.term = $scope.findTerm();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    
    
    
    $scope.openNominationModal = function (nom) {
        if (!$scope.showNominations()) {
            return;  //avoid nominiations when completed
        }
        var isNew = false;
        if (!nom) {   
            nom = {"owner":$scope.thisUser};
            isNew = true;
        }
        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/NominationModal.html?<%=templateCacheDefeater%>',
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

});

</script>
<script src="../../../jscript/AllPeople.js"></script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" 
                type="button" id="menu1" data-toggle="dropdown" ng-style="stateStyle()">
            {{term.state}}: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              ng-click="updateState('Initial Check')">State &#10132; Initial Check</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              ng-click="updateState('Nominating')">State &#10132; Nominating</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              ng-click="updateState('Changing')">State &#10132; Changing</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              ng-click="updateState('Proposing')">State &#10132; Proposing</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              ng-click="updateState('Completed')">State &#10132; Completed</a></li>
        </ul>
      </span>
    </div>


    <div class="row">
        <div class="col-md-6 col-sm-12">
            <div class="form-group">
                <label for="status">Term Start:</label>
                <span>
                    {{term.termStart|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm  '&nbsp;  GMT'Z"}}
                </span> 
            </div>
        </div>
        
        <div class="col-md-6 col-sm-12">
            <div class="form-group">
                <label for="status">Term End:</label>
                <span >
                    {{term.termEnd|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm  '&nbsp;  GMT'Z"}}
                </span> 
            </div>
        </div>
    </div>
    <div ng-show="term.state=='Initial Check'">
        <div class="guideVocal">
            <b>Step 1:</b> Check that the dates for this term is correct.   
            If you modify the dates, press save before continuing.<br/>
            <button class="btn btn-primary" ng-click="updateState('Nominating')">
                Next <i class="fa fa-forward"></i></button>
        </div>
        <div >
            <div class="form-group">
                <label for="status">Term Start:</label>
                <span datetime-picker ng-model="term.termStart"  
                    class="form-control" style="max-width:300px">
                    {{term.termStart|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm  '&nbsp;  GMT'Z"}}
                </span> 
            </div>
        </div>
        
        <div >
            <div class="form-group">
                <label for="status">Term End:</label>
                <span datetime-picker ng-model="term.termEnd"  
                    class="form-control" style="max-width:300px">
                    {{term.termEnd|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm  '&nbsp;  GMT'Z"}}
                </span> 
            </div>
        </div>
        <div class="form-group" title="The duration is the number of days between the start and end dates.">
            <label for="status">Duration:</label>
            <span >
                {{ getDays(term) }} Days
            </span>
        </div>
        <button class="btn btn-primary btn-raised" ng-click="save()">Save</button>
    </div>
    <div ng-show="term.state=='Nominating'">
        <div class="guideVocal">
            <b>Step 2:</b> Enter the email address of the person you want to nominate and give a good reason for why they are good for this role.
            Other people can access this page and make nominations as well.
            You will only see your own nomination at this stage.<br/>
            <button class="btn btn-primary" ng-click="updateState('Initial Check')">
                <i class="fa fa-backward"></i>Back </button>
            <button class="btn btn-primary" ng-click="updateState('Changing')">
                Next <i class="fa fa-forward"></i></button>
        </div>
        <div class="col-12">
            <div class="form-group" style="max-width:600px">
                <label for="status">Nominator: (you)</label>
                <input class="form-control" ng-model="nom.owner"/>
            </div>
            <div class="form-group" style="max-width:600px">
                <label for="status">Nominee:</label>
                <input class="form-control" ng-model="nom.nominee"/>
            </div>
            <div class="form-group" style="max-width:600px">
                <label for="status">Reason:</label>
                <textarea class="form-control" ng-model="nom.comment"></textarea>
            </div>
            <button class="btn btn-primary btn-raised" ng-click="updateNomination(nom)">Save</button>
        </div>
    </div>
    <div ng-show="term.state=='Changing'">
        <div class="guideVocal">
            <b>Step 3:</b> Review all of the nominations made so far.  
            People can change their nominations if they want to.<br/>
            <button class="btn btn-primary" ng-click="updateState('Nominating')">
                <i class="fa fa-backward"></i>Back </button>
            <button class="btn btn-primary" ng-click="updateState('Proposing')">
                Next <i class="fa fa-forward"></i></button>
        </div>
        <div class="col-12">
        
            <div class="form-group" ng-show="showNominations()">
                <label for="synopsis">Nominations:</label>
                <table class="table">
                <tr>
                    <td></td>
                    <td></td>
                    <td><label>Nominee</label></td>
                    <td><label>Reason</label></td>
                </tr>
                <tr ng-repeat="nom in getNominations()" >
                    <td class="actions">
                        <button type="button" name="edit" class="btn btn-primary" 
                                ng-click="openNominationModal(nom)">
                            <span class="fa fa-edit"></span>
                        </button>
                    </td>
                    <td ng-click="openNominationModal(nom)">{{nom.owner}}</td>
                    <td ng-click="openNominationModal(nom)">{{nom.nominee}}</td>
                    <td ng-click="openNominationModal(nom)">{{nom.comment}}</td>
                </tr>
                <tr ng-show="missingNomination()">
                    <td class="actions">
                        <button type="button" name="edit" class="btn btn-primary" 
                                ng-click="openNominationModal()">
                            <span class="fa fa-edit"></span>
                        </button>
                    </td>
                    <td ng-click="openNominationModal()">{{thisUser}}</td>
                    <td ng-click="openNominationModal()" colspan="2"> 
                        <i>Click here to make a nomination</i></td>
                </tr>
                </table>
                <div ng-show="term.nominations.length==0" class="guideVocal">
                There are no nominations for this term at this time.
                </div>
            </div>
            <hr/>
        </div>
    </div>
    <div ng-show="term.state=='Proposing'">
        <div class="guideVocal">
            <b>Step 4:</b> Given the nominations, the leader makes a proposal for role player,
                 and each participant can express consent or object to that.<br/>
            <button class="btn btn-primary" ng-click="updateState('Changing')">
                <i class="fa fa-backward"></i>Back </button>
            <button class="btn btn-primary" ng-click="updateState('Completed')">
                Next <i class="fa fa-forward"></i></button>
        </div>
        <div style="max-width:600px">
            <div class="form-group">
                <label for="status">Players (Proposed)</label>
                <tags-input ng-model="term.players" placeholder="Enter user name or id" 
                        display-property="name" key-property="uid" 
                        replace-spaces-with-dashes="false" add-on-space="true" add-on-comma="true"
                        on-tag-added="updatePlayers()" 
                        on-tag-removed="updatePlayers()">
                    <auto-complete source="loadPersonList($query)" min-length="1"></auto-complete>
                </tags-input>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
                   <li role="presentation"><a role="menuitem" title="{{add}}"
                      ng-click="">Remove Label:<br/>{{role.name}}</a></li>
                </ul>
            </div>
            <div class="form-group" ng-show="isProposing()">
                <label for="status"><br/>Your Response:</label>
                <textarea ng-model="comment" class="form-control"></textarea>
            </div>
            <div class="form-group" ng-show="isProposing()">
                <button ng-click="consent()" class="btn btn-primary btn-raised">Consent</button>
                <button ng-click="object()" class="btn btn-primary btn-raised">Object</button>
            </div>
            <div class="form-group">
                <label for="status"><br/>All Responses So Far:</label>
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
    </div>
    <div ng-show="term.state=='Completed'">
        <div class="guideVocal">
            <b>Step 5:</b> Celebrate!  You are done.   The selected person(s) will be automatically
                placed in the role during the dates specified by the term.<br/>
            <button class="btn btn-primary" ng-click="updateState('Proposing')">
                <i class="fa fa-backward"></i>Back </button>
        </div>
        <div class="col-md-6 col-sm-12">
            <div class="form-group">
                <label for="status">Players </label>
                <tags-input ng-model="term.players" placeholder="Enter user name or id" 
                        display-property="name" key-property="uid" 
                        replace-spaces-with-dashes="false" add-on-space="true" add-on-comma="true"
                        on-tag-added="updatePlayers()" 
                        on-tag-removed="updatePlayers()">
                    <auto-complete source="loadPersonList($query)" min-length="1"></auto-complete>
                </tags-input>
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

<script src="<%=ar.retPath%>templates/NominationModal.js"></script>
