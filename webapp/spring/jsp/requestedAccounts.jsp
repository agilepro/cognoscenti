<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.SiteRequest"
%><%@page import="org.socialbiz.cog.SiteReqFile"
%><%@ include file="/spring/jsp/include.jsp"
%><%ar.assertLoggedIn("New Site page should never be accessed when not logged in");
    if (!ar.isSuperAdmin()) {
        throw new Exception("New Site page should only be accessed by Super Admin");
    }
    UserProfile uProf=ar.getUserProfile();
    Vector<SiteRequest> superRequests = new Vector<SiteRequest>();
    for (SiteRequest accountDetails: SiteReqFile.getAllSiteReqs())
    {   if (accountDetails.getStatus().equalsIgnoreCase("requested"))
        {
            superRequests.add(accountDetails);
        }
    }

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


    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            System Administrator: Site Requests
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="">Do Nothing</a></li>
            </ul>
          </span>

        </div>
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
                        <th >timePeriod</th>
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
                                  <a role="menuitem" tabindex="-1" ng-click="changeStatus(rec,true)">Grant Site</a></li>
                              <li role="presentation">
                                  <a role="menuitem" tabindex="-1" ng-click="changeStatus(rec,false)">Deny Site</a></li>
                            </ul>
                          </div>
                        </td>
                        <td>{{rec.requestId}}</td>
                        <td>{{rec.name}}</td>
                        <td>{{rec.status}}</td>
                        <td>{{rec.desc}}</td>
                        <td>{{rec.modTime}}</td>
                        <td>{{rec.modUser}}</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</div>

