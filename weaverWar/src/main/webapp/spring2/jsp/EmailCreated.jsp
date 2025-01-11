<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    ar.assertAccessWorkspace("Must be a member to see meetings");
    NGBook ngb = ngw.getSite();

    JSONArray eGenList = ngw.getJSONEmailGenerators(ar);
    
    //email must have a subject otherwise the UI will no allow selection of it
    for (int i=0; i<eGenList.length(); i++) {
        JSONObject oneEmail = eGenList.getJSONObject(i);
        String subject = oneEmail.getString("subject");
        if (subject.trim().length()==0) {
            oneEmail.put("subject", "No Subject");
        }
    }

%>

<script>

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, AllPeople, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Email Prepared");
    $scope.eGenList = <%eGenList.write(out,2,4);%>;
    $scope.filter = "";
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.bestDate = function(rec) {
        if (rec.state==2) {
            return rec.scheduleTime;
        }
        else if (rec.state==3) {
            return rec.sendDate;
        }
        else return (new Date()).getTime();
    }
    $scope.sortInverseChron = function() {
        var nowTime = (new Date()).getTime();
        $scope.eGenList.sort( function(a, b){
            return $scope.bestDate(b)-$scope.bestDate(a);
        });
    };
    $scope.sortInverseChron();

    $scope.stateName = function(val) {
        if (val<=1) {
            return "Draft";
        }
        if (val==2) {
            return "Scheduled";
        }
        return "Sent";
    }

    $scope.namePart = function(full) {
        var pos = full.indexOf("�");
        if (pos<0) {
            pos = full.indexOf("<");
        }
        if (pos>3) {
            return full.substring(0,pos);
        }
        return full;
    }

    $scope.deleteEmail = function(rec) {
        rec.deleteIt = true;
        var postURL = "emailGeneratorUpdate.json?id="+rec.id;
        var postdata = angular.toJson(rec);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            var newList = [];
            $scope.eGenList.forEach( function(item) {
                if (item.id != rec.id) {
                    newList.push(item);
                }
            });
            $scope.eGenList = newList;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.navigateToUser = function(player) {
        window.location="<%=ar.retPath%>v/"+encodeURIComponent(player.key)+"/PersonShow.htm";
    }
    $scope.filteredRecs = function(){
        var filterList = parseLCList($scope.filter);
        if (filterList.length==0) {
            return $scope.eGenList;
        }
        var res = [];
        $scope.eGenList.forEach( function(item) {
            if (containsOne(item.subject, filterList)) {
                res.push(item);
            }
        });
        return res;
    }

});

</script>
<script src="../../../jscript/AllPeople.js"></script>

<!-- MAIN CONTENT SECTION START -->
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

<div class="container-fluid override">
    <div class="col-md-auto second-menu"><span class="h5"> Additional Actions</span>
        <div class="col-md-auto second-menu">
        <button class="specCaretBtn m-2" type="button" data-bs-toggle="collapse" data-bs-target="#collapseSecondaryMenu" aria-expanded="false" aria-controls="collapseSecondaryMenu">
            <i class="fa fa-arrow-down"></i>
        </button>
        <div class="collapse" id="collapseSecondaryMenu">
            <div class="col-md-auto">
                <span class="btn second-menu-btn btn-wide" type="button"><a class="nav-link" role="menuitem" href="EmailCreated.htm">
              Email Prepared</a>
            </span>
            <span class="btn second-menu-btn btn-wide" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewTopic"><a class="nav-link" role="menuitem" href="EmailSent.htm">
              Email Sent</a>
            </span>
          <span class="btn second-menu-btn btn-wide" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewTopic"><a class="nav-link " role="menuitem" href="SendNote.htm">
              Create Email</a>
          </span>
    </div>
    </div>
    </div>
    </div><hr>
    
    <div class="d-flex col-12 m-2"><div class="contentColumn">
        <div class="well">Filter: <input ng-model="filter">
    </div>
    <div style="height:20px;"></div>

    <table class="table ms-2" width="100%">
        <tr class="gridTableHeader">
            <td width="50px">From</td>
            <td width="250px">Subject</td>
            <td width="50px">State</td>
            <td width="100px">Date</td>
        </tr>
        <tr ng-repeat="rec in filteredRecs()">
            <td>
                  <span class="dropdown">
                    <span id="menu1" data-toggle="dropdown">
                    <img class="rounded-5" src="<%=ar.retPath%>icon/{{rec.fromUser.uid}}.jpg" 
                         style="width:32px;height:32px" title="{{rec.fromUser.name}} - {{rec.fromUser.uid}}">
                    </span>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                          tabindex="-1" ng-click="" style="text-decoration: none;text-align:center">
                          {{rec.fromUser.name}}<br/>{{rec.fromUser.uid}}</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="navigateToUser(rec.fromUser)">
                          <span class="fa fa-user"></span> Visit Profile</a></li>
                    </ul>
                  </span>
            </td>
            <td><a href="SendNote.htm?id={{rec.id}}">{{rec.subject}}</a></td>
            <td>{{stateName(rec.state)}}</td>
            <td ng-show="rec.state<=1">
              <a role="menuitem" tabindex="-1" title="Delete Email" href="#" ng-click="deleteEmail(rec)">
                <button type="button" name="delete" class=" btn-comment bg-danger-subtle text-danger">
                    <span class="fa fa-trash"></span>
                </button>
              </a>
            </td>
            <td ng-hide="rec.state<=1">{{bestDate(rec)|date:'dd-MMM-yyyy H:mm'}}</td>
        </tr>
    </table>

</div>


