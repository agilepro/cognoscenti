<%@page errorPage="/spring/jsp/error.jsp"
%><%@include file="/spring/jsp/include.jsp"
%><%
    UserProfile uProf =(UserProfile)request.getAttribute("userProfile");
    List<String> notifications = uProf.getNotificationList();
    boolean noneFound = notifications.size()==0;

    JSONArray projList = new JSONArray();
    for (String pageKey : notifications) {
        NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(pageKey);
        if (ngpi==null) {
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
    window.setMainPageTitle("Notified Workspaces");
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

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Notified Workspaces
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
                      <a role="menuitem" tabindex="-1" href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.pageKey}}/frontPage.htm">
                      Access Workspace</a></li>
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.pageKey}}/personal.htm">
                      Stop Notifications</a></li>
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
        User <% uProf.writeLink(ar); %> has not signed up to receive notifications from any workspace.<br/>
        <br/>
        As you visit workspaces, go to the "Workspace Settings &gt; Personal" page, and sign up
        to receive notifications.   Then, when things in the workspace change,
        such as documents added, or topics edited, you will see those changes here,
        and will be automatically notified of the changes by email.<br/>
        <br/>
        Later, you can turn off notifications at any time.
    </div>

</div>
