<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.UserCache"
%><%@page import="com.purplehillsbooks.weaver.UserCacheMgr"
%><%

    UserProfile uProf = (UserProfile)request.getAttribute("userProfile");
    if (uProf == null) {
        throw new NGException("nugen.exception.cant.find.user",null);
    }

    NGPageIndex.clearLocksHeldByThisThread();
    UserCache userCache = ar.getCogInstance().getUserCacheMgr().getCache(uProf.getKey());
    JSONArray workList = userCache.getActionItems();

    UserProfile  operatingUser =ar.getUserProfile();
    if (operatingUser==null) {
        //this should never happen, and if it does it is not the users fault
        throw new ProgramLogicError("user profile setting is null.  No one appears to be logged in.");
    }

    boolean viewingSelf = uProf.getKey().equals(operatingUser.getKey());
    String loggingUserName=uProf.getName();


%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Action Items for <%ar.writeJS(uProf.getName());%>");
    $scope.workList = <%workList.write(out,2,4);%>;
    $scope.filterVal = "";
    $scope.filterPast = false;
    $scope.filterCurrent = true;
    $scope.filterFuture = false;

    $scope.showInput = false;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.getRows = function() {
        var filterList = parseLCList($scope.filterVal);
        var res = $scope.workList.filter( function(item) {

            switch (item.state) {
                case 0:
                    break;
                case 1:
                    if (!$scope.filterFuture) {
                        return false;
                    }
                    break;
                case 2:
                case 3:
                case 4:
                    if (!$scope.filterCurrent) {
                        return false;
                    }
                    break;
                default:
                    if (!$scope.filterPast) {
                        return false;
                    }
            }
            return (containsOne(item.synopsis,filterList) ||
                  containsOne(item.description,filterList) ||
                  containsOne(item.projectname,filterList));
        });
        return res;
    }
    $scope.bestDate = function(rec) {
        if (rec.duedate> 0) {
            return rec.duedate;
        }
        if (rec.modifiedtime > 0) {
            return rec.modifiedtime;
        }
        if (rec.startdate > 0) {
            return rec.startdate;
        }
        return rec.enddate;
    }
    
    $scope.workList.sort( function(a,b) {
        return ($scope.bestDate(a)-$scope.bestDate(b)); 
    });
    
    $scope.navigateRec = function(rec) {
        window.location = "../../t/"+rec.siteKey+"/"+rec.projectKey+"/task"+rec.id+".htm";
    }
});

</script>

<!-- MAIN CONTENT SECTION START -->
<div>

<%@include file="ErrorPanel.jsp"%>

        <div >
            Filter: <input ng-model="filterVal"> 
                <input type="checkbox" ng-model="filterPast"> Past
                <input type="checkbox" ng-model="filterCurrent"> Current
                <input type="checkbox" ng-model="filterFuture"> Future
        </div>

<style>
.selectableRow:hover {background:lightblue;cursor:pointer;}
</style>
        
        
        <div class="generalSettings">

            <table class="gridTable2" width="100%">
            <tr class="gridTableHeader">
                <td width="16px"></td>
                <td width="300px">Action Item - Description</td>
                <td width="100px">Due Date</td>
                <td width="100px">Workspace</td>
            </tr>
            <tr ng-repeat="rec in getRows()" ng-click="navigateRec(rec)" class="selectableRow">
                <td width="16px">
                  <img ng-src="<%= ar.retPath %>/assets/goalstate/small{{rec.state}}.gif">
                </td>
                <td >
                    <a href="../../t/{{rec.siteKey}}/{{rec.projectKey}}/task{{rec.id}}.htm">
                        {{rec.synopsis}}
                    </a> - {{rec.description | limitTo: 250}}
                </td>
                <td>{{bestDate(rec)|cdate}}</td>
                <td>
                    <a href="../../t/{{rec.siteKey}}/{{rec.projectKey}}/frontPage.htm">{{rec.projectname}}</a>
                </td>
            </tr>
            </table>
        </div>

        <hr/>
        <div><i>Note: this list is updated daily so it might not show changes that have occurred in the last 24 hours.
        If you want to see this page updated use 
        <a href="UserHome.htm?ref=<%=ar.nowTime%>">
          <button class="btn btn-default btn-raised">Refresh</button></a></i></div>

</div>
