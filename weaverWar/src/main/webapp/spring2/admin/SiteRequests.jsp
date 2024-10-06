<%@page errorPage="/spring2/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.SiteRequest"
%><%@page import="com.purplehillsbooks.weaver.SiteReqFile"
%><%@ include file="/include.jsp"
%><%

    ar.assertLoggedIn("New Site page should never be accessed when not logged in");
    ar.assertSuperAdmin("Must be a super admin to see new site page");
    UserProfile uProf=ar.getUserProfile();
    SiteReqFile siteReqFile = new SiteReqFile(ar.getCogInstance());
    List<SiteRequest> superRequests = siteReqFile.getAllSiteReqs();

    JSONArray allRequests = new JSONArray();
    for (SiteRequest requestRecord : superRequests) {
        allRequests.put(requestRecord.getJSON());
    }

%>
<script type="text/javascript">

var app = angular.module('myApp');
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
        var postURL = "acceptOrDenySite.json";
        var postObject = {};
        postObject.requestId = rec.requestId;
        postObject.siteId = rec.siteId;
        if (isGranted) {
            postObject.newStatus = "Granted";
        }
        else {
            postObject.newStatus = "Denied";
        }
        postObject.description = "";
        var postdata = angular.toJson(postObject);
        $scope.showError=false;
        console.log("REQUEST UPDATE:", postObject);
        $http.post(postURL, postdata)
        .success( function(data) {
            console.log("REQUEST RETURN:", data);
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
                        <th >Request Id<br/>Status</th>
                        <th >Site Name<br/>Site Id</th>
                        <th >Description</th>
                        <th >Requested by<br/>Date</th>
                    </tr>
                </thead>
                <tbody>
                    <tr ng-repeat="rec in allRequests">
                        <td>
                          <button ng-click="changeStatus(rec,true)" ng-show="notDone(rec)">Grant Site</button><br/>
                          <button ng-click="changeStatus(rec,false)" ng-show="notDone(rec)">Deny Site</button>
                        </td>
                        <td>{{rec.status}}</td>
                        <td>{{rec.siteName}}<br/>
                            <input ng-model="rec.siteId" type="text"/>
                            <a href="ListSites.htm?filter={{rec.siteId}}"><i class="fa fa-search"></i></a>
                            </td>
                        <td>{{rec.purpose}}</td>
                        <td>{{rec.requester}}<br/>{{rec.modTime|date}}</td>
                    </tr>
                    <tr><td></td><td></td><td></td><td></td><td></td></tr>
                </tbody>
            </table>
        </div>
    </div>
</div>

