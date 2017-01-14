<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.UserCache"
%><%@page import="org.socialbiz.cog.UserCacheMgr"
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

var app = angular.module('myApp', ['ui.bootstrap']);
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
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Items that <% ar.writeHtml(uProf.getName()); %> needs to respond to.
        </div>
        <!--div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="">Do Nothing</a></li>
            </ul>
          </span>

        </div-->
    </div>



        <div class="generalSettings">

            <table class="gridTable2" width="100%">
            <tr class="gridTableHeader">
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
                    <span style="{{dueStyle(rec)}}">{{rec.dueDate|date}}</span>
                </td>
            </tr>
            </table>
        </div>



        <div><i>Note: this list is updated when the email is sent.  Email is usually delayed 5 minutes.</i></div>

    </div>
</div>
