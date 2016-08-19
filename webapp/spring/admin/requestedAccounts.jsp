<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.SiteRequest"
%><%@page import="org.socialbiz.cog.SiteReqFile"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    ar.assertLoggedIn("New Site page should never be accessed when not logged in");
    ar.assertSuperAdmin("Must be a super admin to see new site page");
    UserProfile uProf=ar.getUserProfile();
    List<SiteRequest> superRequests = SiteReqFile.getAllSiteReqs();

    JSONArray allRequests = new JSONArray();
    for (SiteRequest requestRecord : superRequests) {
        allRequests.put(requestRecord.getJSON());
    }

%>
<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.allRequests = <%allRequests.write(out,2,4);%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.notDone = function(rec) {
        return (rec.status == "requested");
    }

    $scope.changeStatus = function(rec, isGranted) {
        rec.public = !rec.public;
        var postURL = "acceptOrDenySite.json";
        var postObject = {};
        postObject.requestId = rec.requestId;
        if (isGranted) {
            postObject.newStatus = "Granted";
        }
        else {
            postObject.newStatus = "Denied";
        }
        postObject.description = "";
        var postdata = angular.toJson(postObject);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            rec.status = data.status;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="h1">
        Requested Sites
    </div>

        <div id="accountRequestDiv">
            <table class="table">
                <thead>
                    <tr>
                        <th></th>
                        <th >Request Id</th>
                        <th >Site Name</th>
                        <th >State</th>
                        <th >Description</th>
                        <th >Date</th>
                        <th >Requested by</th>
                    </tr>
                </thead>
                <tbody>
                    <tr ng-repeat="rec in allRequests">
                        <td>
                          <div class="dropdown">
                            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                            <span class="caret"></span></button>
                            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                              <li role="presentation">
                                  <a role="menuitem" ng-click="changeStatus(rec,true)" ng-show="notDone(rec)">Grant Site</a></li>
                              <li role="presentation">
                                  <a role="menuitem" ng-click="changeStatus(rec,false)" ng-show="notDone(rec)">Deny Site</a></li>
                              <li role="presentation">
                                  <a role="menuitem" ng-hide="notDone(rec)">No Action Available</a></li>
                            </ul>
                          </div>
                        </td>
                        <td>{{rec.requestId}}</td>
                        <td>{{rec.name}}</td>
                        <td>{{rec.status}}</td>
                        <td>{{rec.desc}}</td>
                        <td>{{rec.modTime|date}}</td>
                        <td>{{rec.requester.name}}</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</div>

