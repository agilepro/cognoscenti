<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.SiteRequest"
%><%@page import="org.socialbiz.cog.SiteReqFile"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    ar.assertLoggedIn("New Site page should never be accessed when not logged in");
    ar.assertSuperAdmin("Must be a super admin to see new site page");
    UserProfile uProf=ar.getUserProfile();
    
    List<SiteRequest> superRequests = SiteReqFile.getAllSiteReqs();

    Cognoscenti cog = Cognoscenti.getInstance(request);
    
    JSONArray allRequests = new JSONArray();
    for (NGPageIndex ngpi : cog.getAllSites()){
        NGBook site = (NGBook) ngpi.getContainer();
        JSONObject jo = site.getConfigJSON();
        allRequests.put(jo);
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

    $scope.addAdmin = function(rec) {
        if (confirm("Are you sure you want to add youself as an owner of the site: "
                    +rec.names[0]+" ("+rec.key+")")) {
            var siteKey = rec.key;
            var postURL = "takeOwnershipSite.json";
            var postObj = {};
            postObj.key = rec.key;
            var postdata = angular.toJson(postObj);
            $scope.showError=false;
            $http.post(postURL, postdata)
            .success( function(data) {
                var newList = [];
                $scope.allRequests.forEach( function(item) {
                    if (item.key==siteKey) {
                        newList.push(data);
                    }
                    else {
                        newList.push(item);
                    }
                });
                $scope.allRequests = newList;
            })
            .error( function(data, status, headers, config) {
                $scope.reportError(data);
            });
        }
    };
});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="h1">
        All Sites
    </div>

        <div id="accountRequestDiv">
            <table class="table">
                <thead>
                    <tr>
                        <th></th>
                        <th >Site Name</th>
                        <th >Last Change</th>
                        <th >Deleted</th>
                        <th >Owners</th>
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
                                  <a role="menuitem" ng-click="addAdmin(rec)">Add Yourself to Owners</a></li>
                            </ul>
                          </div>
                        </td>
                        <td><a href="../../t/{{rec.key}}/$/SiteStats.htm"><b>{{rec.names[0]}}</b></a> ({{rec.key}})</td>
                        <td>{{rec.changed|date}}</td>
                        <td>{{rec.isDeleted}}</td>
                        <td><div ng-repeat="owner in rec.owners">{{owner.name}}</div></td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</div>

