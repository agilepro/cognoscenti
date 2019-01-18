<%@page errorPage="/spring/jsp/error.jsp"
%><%@include file="/spring/jsp/include.jsp"
%><%
    UserProfile uProf =(UserProfile)request.getAttribute("userProfile");
    List<NGPageIndex> ownedProjs = ar.getCogInstance().getAllPagesForAdmin(uProf);
    boolean noneFound = ownedProjs.size()==0;

    JSONArray projList = new JSONArray();
    for (NGPageIndex ngpi : ownedProjs) {
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

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Workspaces You Administer");
    $scope.projList = <%projList.write(out,2,4);%>;
    $scope.noneFound = <%=noneFound%>;
    $scope.filter = "";

    $scope.showInput = false;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.sortItems = function() {
        $scope.projList.sort( function(a, b){
            return b.changed - a.changed;
        });
        return $scope.projList;
    };
    $scope.getRows = function() {
        var lcfilter = parseLCList($scope.filter);
        var res = [];
        var last = $scope.projList.length;
        for (var i=0; i<last; i++) {
            var rec = $scope.projList[i];
            if (containsOne(rec.name, lcfilter)) {
                res.push(rec);
            }
        }
        return res;
    }
    $scope.sortItems();
});

</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div>Filter <input ng-model="filter"></div>
    <div style="height:30px;"></div>

    <table class="gridTable2" width="100%">
        <tr class="gridTableHeader">
            <td width="50px"></td>
            <td width="200px">Workspace</td>
            <td width="100px">Changed</td>
        </tr>
        <tr ng-repeat="rec in getRows()">
            <td>
              <div class="dropdown">
                <button class="dropdown-toggle specCaretBtn" type="button"  d="menu" 
                    data-toggle="dropdown"> <span class="caret"></span> </button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.pageKey}}/frontPage.htm">Access Workspace</a></li>
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.pageKey}}/roleManagement.htm">Abandon Workspace</a></li>
                </ul>
              </div>
            </td>
            <td class="repositoryName">
                <a href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.pageKey}}/frontPage.htm">
                   {{rec.name}}
                       <span ng-show="rec.isDeleted" style="color:grey"> (DELETED)</span>
                       <span ng-show="rec.frozen" style="color:grey"> (FROZEN)</span>
                       <span ng-show="rec.isMoved" style="color:grey"> (MOVED)</span>
                </a>
            </td>
            <td>{{rec.changed|date}}</td>
        </tr>
    </table>

    <div class="guideVocal" ng-show="noneFound">
        User <% uProf.writeLink(ar); %> has not created any projects, and does not have any access to sites to create one in.
       <br/>
       When a user create projects, they will be listed here.<br/>
       <br/>
       In order to create a workspace, you need to be an "Owner" or an "Executive" of an "Site".<br/>
       <br/>
       Use <button class="btn btn-sm" onClick="location.href='userAccounts.htm'">Settings &gt; Sites</button>
       to view your sites, or request a new site from the system administrator.
       If approved you will be the owner of that new site,
       and can create new projects within it.
    </div>

</div>
