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
    JSONArray proposalList = userCache.getProposals();

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
    window.setMainPageTitle("Missing Responses for <%ar.writeJS(uProf.getName());%>");
    $scope.proposalList = <%proposalList.write(out,2,4);%>;
    $scope.proposalList.sort( function(a,b) {
        return a.dueDate-b.dueDate;
    });
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
    $scope.nowTime = new Date().getTime();

    $scope.getRows = function() {
        var lcfilter = $scope.filterVal.toLowerCase();
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
            return ((item.synopsis.toLowerCase().indexOf(lcfilter)>=0) ||
                  (item.description.toLowerCase().indexOf(lcfilter)>=0) ||
                  (item.projectname.toLowerCase().indexOf(lcfilter)>=0));
        });
        return res;
    }
    $scope.dueStyle = function(rec) {
        if (rec.dueDate < $scope.nowTime) {
            return "color:red;font-weight:bold;"
        }
        else {
            return "";
        }
    }

});

</script>

<!-- MAIN CONTENT SECTION START -->
<div class="userPageContents">

<%@include file="../jsp/ErrorPanel.jsp"%>


        <div class="generalSettings">

            <table class="table" width="100%">
            <tr >
                <td width="16px"></td>
                <td width="300px">Proposal</td>
                <td width="100px">Workspace</td>
                <td width="100px">Proposed By</td>
                <td width="100px">Due</td>
            </tr>
            <tr ng-repeat="rec in proposalList">
                <td></td>
                <td >
                    <a href="../../t/{{rec.siteKey}}/{{rec.workspaceKey}}/{{rec.address}}">{{rec.content}}</a>
                </td>
                <td>
                    <a href="../../t/{{rec.siteKey}}/{{rec.workspaceKey}}/frontPage.htm">{{rec.workspaceName}}</a>
                </td>
                <td>
                    {{rec.userName}}
                </td>
                <td>
                    <span style="{{dueStyle(rec)}}">{{rec.dueDate|cdate}}</span>
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
</div>
