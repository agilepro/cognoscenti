<%@page errorPage="/spring/jsp/error.jsp"
%><%@include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.NotificationRecord"
%><%
    UserProfile uProf = ar.getUserProfile();
    Vector<NGPageIndex> ownedProjs = ar.getCogInstance().getAllContainers();
    boolean noneFound = ownedProjs.size()==0;
    String accountKey = ar.reqParam("accountId");

    JSONArray projList = new JSONArray();
    for (NGPageIndex ngpi : ar.getCogInstance().getAllProjectsInSite(accountKey)) {
        if (!ngpi.isProject()) {
            continue;
        }
        projList.put(ngpi.getJSON4List());
    }

/** RECORD PROTOTYPE
      {
        "changed": 1433079860881,
        "name": "Secular Coalition for America",
        "pageKey": "secular-coalition-for-america",
        "siteKey": "serious",
        "visited": 1408859504142
      },
*/

%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.projList = <%projList.write(out,2,4);%>;
    $scope.noneFound = <%=noneFound%>;
    $scope.filter = "";

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        var exception = serverErr.exception;
        $scope.errorMsg = exception.msgs.join();
        $scope.errorTrace = exception.stack;
        $scope.showError=true;
        $scope.showTrace = false;
    };

    $scope.sortItems = function() {
        $scope.projList.sort( function(a, b){
            return b.changed - a.changed;
        });
        return $scope.projList;
    };
    $scope.getRows = function() {
        var lcfilter = $scope.filter.toLowerCase();
        var res = [];
        var last = $scope.projList.length;
        for (var i=0; i<last; i++) {
            var rec = $scope.projList[i];
            if (rec.name.toLowerCase().indexOf(lcfilter)>=0) {
                res.push(rec);
            }
        }
        return res;
    }
    $scope.sortItems();
});

</script>

<div class="content tab03" style="display:block;" ng-app="myApp" ng-controller="myCtrl">
    <div class="section_body">
        <div style="height:10px;"></div>

        <div id="ErrorPanel" style="border:2px solid red;display=none;background:LightYellow;margin:10px;" ng-show="showError" ng-cloak>
            <div class="generalSettings">
                <table>
                    <tr>
                        <td class="gridTableColummHeader">Error:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">{{errorMsg}}</td>
                    </tr>
                    <tr ng-show="showTrace">
                        <td class="gridTableColummHeader">Trace:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">{{errorTrace}}</td>
                    </tr>
                    <tr ng-hide="showTrace">
                        <td class="gridTableColummHeader">Trace:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2"><button ng-click="showTrace=true">Show The Trace</button></td>
                    </tr>
                </table>
            </div>
        </div>

        <div class="generalHeading">Projects that belong to this site</div>
        <div>Filter <input ng-model="filter"></div>
        <div style="height:10px;"></div>

        <table class="gridTable2" width="100%">
            <tr class="gridTableHeader">
                <td width="50px"></td>
                <td width="200px">Project</td>
                <td width="100px">Changed</td>
            </tr>
            <tr ng-repeat="rec in getRows()">
                <td>
                  <div class="dropdown">
                    <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                    <span class="caret"></span></button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation">
                          <a role="menuitem" tabindex="-1" href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.pageKey}}/frontPage.htm">Access Project</a></li>
                    </ul>
                  </div>
                </td>
                <td class="repositoryName">
                    <a href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.pageKey}}/frontPage.htm">
                       {{rec.name}}
                    </a>
                </td>
                <td>{{rec.changed|date}}</span></td>
            </tr>
        </table>

        <div class="guideVocal" ng-show="noneFound">
            User <% uProf.writeLink(ar); %> has not created any projects, and does not have any access to sites to create one in.
           <br/>
           When a user create projects, they will be listed here.<br/>
           <br/>
           In order to create a project, you need to be an "Owner" or an "Executive" of an "Site".<br/>
           <br/>
           Use <button class="btn btn-sm" onClick="location.href='userAccounts.htm'">Settings &gt; Sites</button>
           to view your sites, or request a new site from the system administrator.
           If approved you will be the owner of that new site,
           and can create new projects within it.
        </div>

    </div>
</div>
