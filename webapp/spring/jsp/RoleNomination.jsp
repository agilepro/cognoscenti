<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to edit roles");

    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    String roleName    = ar.reqParam("role");
    String termKey    = ar.reqParam("term");
    
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
    $scope.termKey = "<%ar.writeJS(termKey);%>";
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
                res = term;
            }
        });
        return res;
    }
    $scope.term = $scope.findTerm();
    
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
    
    $scope.updateNomination = function(nom) {
        if (!nom) {
            nom = {};
        }
        var termObj = {};
        termObj.key = $scope.termKey;
        termObj.nominations = [];
        termObj.nominations.push(nom);
        var roleObj = {};
        roleObj.name = $scope.role.name;
        roleObj.terms = [];
        roleObj.terms.push(termObj);
        $scope.updateRole(roleObj);
    }
    $scope.updateRole = function(role) {
        console.log("UPDATING role: ", role);
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
        var isNew = false;
        if (!nom) {   
            nom = {};
            isNew = true;
        }
        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/NominationModal.html?t=<%=System.currentTimeMillis()%>',
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
                Nominations for: {{role.name}}
            </div>
        </div>
    </div>
    <div class="row">
        <div class="col-md-6 col-sm-12">
            <div class="form-group">
                <label for="status">Term Start:</label>
                <span class="dropdown-toggle form-control" id="dropdown2" role="button" 
                    data-toggle="dropdown" data-target="#">
                    {{ term.termStart | date:'dd-MMM-yyyy \'at\' HH:mm  \' &nbsp;  GMT\'Z' }}
                </span>
                <ul class="dropdown-menu" role="menu" aria-labelledby="dLabel">
                    <datetimepicker
                        data-ng-model="term.termStart"
                        data-datetimepicker-config="{ dropdownSelector: '#dropdown2',minuteStep: 15,minView:'hour'}"
                        data-on-set-time="onTimeSet(newDate, 'termStart')"/>
                </ul>                
            </div>
            <div class="form-group">
                <label for="status">Term End:</label>
                <span class="dropdown-toggle form-control" id="dropdown3" role="button" 
                    data-toggle="dropdown" data-target="#">
                    {{ term.termEnd | date:'dd-MMM-yyyy \'at\' HH:mm  \' &nbsp;  GMT\'Z' }}
                </span>
                <ul class="dropdown-menu" role="menu" aria-labelledby="dLabel">
                    <datetimepicker
                        data-ng-model="term.termEnd"
                        data-datetimepicker-config="{ dropdownSelector: '#dropdown3',minuteStep: 15,minView:'hour'}"
                        data-on-set-time="onTimeSet(newDate, 'termEnd')"/>
                </ul>                
            </div>
            <div class="form-group">
                <label for="status">Duration:</label>
                <span >
                    {{ getDays(term) }} Days
                </span>
            </div>
        </div>
        
        <div class="col-md-6 col-sm-12">
col 2
        </div>
        <div class="col-12">
        
            <div class="form-group">
                <label for="synopsis">Nominations:</label>
                <table class="table">
                <tr ng-repeat="nom in term.nominations" >
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
                </table>
            </div>
            <div>
                <button ng-click="openNominationModal()" class="btn btn-default btn-raised">
                    Create Nomination
                </button>
            </div>
        </div>
    </div>

</div>

<script src="<%=ar.retPath%>templates/NominationModal.js"></script>
