<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    String go = ar.getCompleteURL();
    ar.assertLoggedIn("Must be logged in to see anything about a user");

    UserProfile uProf = (UserProfile)request.getAttribute("userProfile");
    if (uProf == null) {
        throw new NGException("nugen.exception.cant.find.user",null);
    }

    UserProfile  operatingUser =ar.getUserProfile();
    if (operatingUser==null) {
        //this should never happen, and if it does it is not the users fault
        throw new ProgramLogicError("user profile setting is null.  No one appears to be logged in.");
    }

    boolean viewingSelf = uProf.getKey().equals(operatingUser.getKey());
    UserPage uPage = uProf.getUserPage();
    List<ProfileRef> remoteRefs = uPage.getProfileRefs();
    JSONArray profs = new JSONArray();
    for (ProfileRef oneRef : remoteRefs) {
        JSONObject oneObj = new JSONObject();
        oneObj.put("url",        oneRef.getAddress());
        oneObj.put("lastAccess", oneRef.getLastAccess());
        profs.put(oneObj);
    }

%>

<script type="text/javascript">

var app = angular.module('myApp', []);
app.controller('myCtrl', function($scope, $http) {
    $scope.profiles = <%profs.write(out,2,4);%>;
    $scope.go = "<%ar.writeJS(ar.getCompleteURL());%>";
    $scope.newURL = "";
    $scope.showInput = false;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        var exception = serverErr.exception;
        $scope.errorMsg = exception.join();
        $scope.errorTrace = exception.stack;
        $scope.showError=true;
        $scope.showTrace = false;
    };

    $scope.deleteRow = function(row) {
        var selAddress = row.url;
        var postURL = "RemoteProfileUpdate.json?act=Delete&address=" + encodeURIComponent(selAddress);
        var postdata = "Bogus";
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            var newSet = [];
            for( var i =0; i<$scope.profiles.length; i++) {
                var irow = $scope.profiles[i];
                if (selAddress != irow.url) {
                    newSet.push(irow);
                }
            }
            $scope.profiles = newSet;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.createRow = function() {
        var postURL = "RemoteProfileUpdate.json?act=Create&address=" + encodeURIComponent($scope.newURL);
        var postdata = "Bogus";
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            var rec = {
                lastAccess: 0
            };
            rec.url=$scope.newURL;
            $scope.profiles.push(rec);
            $scope.showInput=false;
            $scope.newURL="";
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

});

</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Remote Profiles (for accessing Goals)
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="showInput=!showInput">Add New Remote Profile</a></li>
            </ul>
          </span>

        </div>
    </div>

    <div id="NewConnection" class="well" ng-show="showInput" ng-cloak>
        <table>
            <tr id="trspath">
                <td class="gridTableColummHeader">URL:</td>
                <td style="width:20px;"></td>
                <td colspan="2"><input type="text" ng-model="newURL" class="form-control" size="69" /></td>
            </tr>
            <tr><td style="height:30px"></td></tr>
            <tr>
                <td ></td>
                <td style="width:20px;"></td>
                <td colspan="2">
                    <input type="submit" class="btn btn-primary"
                        value="Add Remote Profile"
                        ng-click="createRow()">
                    <input type="button" class="btn btn-primary"
                        value="Cancel"
                        ng-click="showInput=false">
                </td>
            </tr>
        </table>
    </div>
    <div style="height:30px;"></div>

    <table class="gridTable2" width="100%">
        <tr class="gridTableHeader">
            <td width="300px">Address</td>
            <td width="80px">Last Used</td>
            <td width="50px">Delete</td>
        </tr>
        <tr ng-repeat="rec in profiles">
            <td class="repositoryName"><a href="{{rec.url}}">{{rec.url}}</a></td>
            <td>{{rec.lastAccess|date}}</td>
            <td>
            <button ng-click="deleteRow(rec)"><img src="<%=ar.retPath%>assets/iconDelete.gif"/></button>
            </td>
        </tr>
    </table>

</div>
