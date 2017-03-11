<%@page errorPage="/spring/jsp/error.jsp"
%><%@include file="/spring/jsp/include.jsp"
%><%
    UserProfile uProf =(UserProfile)request.getAttribute("userProfile");
    List<String> tmpList = uProf.getTemplateList();
    boolean noneFound = tmpList.size()==0;

    JSONArray projList = new JSONArray();
    for (String pageKey : tmpList) {
        NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(pageKey);
        if (ngpi==null) {
            continue;
        }
        JSONObject wObj = ngpi.getJSON4List();
        projList.put(wObj);
    }

/** RECORD PROTOTYPE
      {
        "changed": 1433079860881,
        "name": "Secular Coalition for America",
        "pageKey": "secular-coalition-for-america",
        "siteKey": "serious"
      },
*/

%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Your Template Workspaces");
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
                          Remove Template</a></li>
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
        User <% uProf.writeLink(ar); %> has not specified any templates.<br/>
            <br/>
            Templates are references to normal projects.  When you
            create a new workspace, you can specify a template, and all the action items
            and roles are copied (empty & unstarted) into the new workspace.
            This is a convenient way to 'prime' a workspace with the normal tasks
            and roles that you need. <br/>
            <br/>
            If you visit a workspace which has a good form, and you might want to use it
            in the future as a template, on that workspace go the "Workspace Settings>Personal" page,
            and choose to remember the workspace as a template.  Then that workspace will appear here
            and in other places where you can use a template, such as at the time that you
            create a new workspace.
    </div>

</div>
