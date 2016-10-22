<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    String go = ar.getCompleteURL();

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
    String loggingUserName=uProf.getName();

    UserPage uPage = uProf.getUserPage();
    JSONArray workList = new JSONArray();
    List<RemoteGoal> allRG = uPage.getRemoteGoals();
    boolean noneFound = allRG.size()==0;
    for (RemoteGoal tr : allRG) {
        workList.put(tr.getJSONObject());
    }

%>

<style>
    .tightertable tr td {line-height: 1.3;}
</style>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.workList = <%workList.write(out,2,4);%>;
    $scope.noneFound = <%=noneFound%>;
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
        var lcfilter = $scope.filterVal.toLowerCase();
        var res = [];
        var last = $scope.workList.length;
        for (var i=0; i<last; i++) {
            var rec = $scope.workList[i];
            var state = rec.state;
            switch (state) {
                case 0:
                    break;
                case 1:
                    if (!$scope.filterFuture) {
                        continue;
                    }
                    break;
                case 2:
                case 3:
                case 4:
                    if (!$scope.filterCurrent) {
                        continue;
                    }
                    break;
                default:
                    if (!$scope.filterPast) {
                        continue;
                    }
                    break;
            }

            if (rec.synopsis.toLowerCase().indexOf(lcfilter)>=0) {
                res.push(rec);
            }
            else if (rec.description.toLowerCase().indexOf(lcfilter)>=0) {
                res.push(rec);
            }
            else if (rec.projectname.toLowerCase().indexOf(lcfilter)>=0) {
                res.push(rec);
            }

        }
        return res;
    }

});

</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Remote Action Items for <% ar.writeHtml(uProf.getName()); %>
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


    <div >
        Filter: <input ng-model="filterVal"> {{filterVal}}
            <input type="checkbox" ng-model="filterPast"> Past
            <input type="checkbox" ng-model="filterCurrent"> Current
            <input type="checkbox" ng-model="filterFuture"> Future
    </div>

    <div class="generalSettings">

        <table class="gridTable2 tightertable" width="100%">
        <tr class="gridTableHeader">
            <td width="16px"></td>
            <td width="200px">Action Item</td>
            <td width="200px">Description</td>
            <td width="100px">Workspace</td>
            <td width="100px">Site</td>
        </tr>
        <tr ng-repeat="rec in getRows()">
            <td width="16px"><img src="<%= ar.retPath %>/assets/goalstate/small{{rec.state}}.gif"></td>
            <td >
                 <a href="ViewRemoteTask.htm?url={{rec.universalid}}">{{rec.synopsis}}</a>
            </td>
            <td>{{rec.description | limitTo: 150}}</td>
            <td>{{rec.projectname}}</td>
            <td>{{rec.sitename}}</td>
        </tr>
        </table>
    </div>
    
    
    <div class="guideVocal" ng-show="noneFound">
        User <% uProf.writeLink(ar); %> has not retrieved any remote action items.<br/>
            <br/>
            If you are using more than one Weaver server, 
            and if you have remote profiles, you can retrieve action items from
            those remote servers.
            This is fairly advanced functionality, and the casual userneed not worry about it.
    </div>
    
</div>
