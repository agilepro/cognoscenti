<%@page errorPage="/spring/jsp/error.jsp"
%><%@include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.TemplateRecord"
%><%
    UserProfile uProf =(UserProfile)request.getAttribute("userProfile");
    List<TemplateRecord> tmpList = uProf.getTemplateList();
    boolean noneFound = tmpList.size()==0;

    JSONArray projList = new JSONArray();
    for (TemplateRecord tr : tmpList) {
        String pageKey = tr.getPageKey();
        NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(pageKey);
        if (ngpi==null) {
            continue;
        }
        JSONObject wObj = ngpi.getJSON4List();
        wObj.put("visited", tr.getLastSeen());
        projList.put(wObj);
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
            Templates
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="">Do Nothing</a></li>
            </ul>
          </span>

        </div>
    </div>

    <div>Filter <input ng-model="filter"></div>
    <div style="height:30px;"></div>

    <table class="gridTable2" width="100%">
        <tr class="gridTableHeader">
            <td width="50px"></td>
            <td width="200px">Project</td>
            <td width="100px">Changed</td>
            <td width="100px">Seen</td>
        </tr>
        <tr ng-repeat="rec in getRows()">
            <td>
              <div class="dropdown">
                <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                <span class="caret"></span></button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.pageKey}}/notesList.htm">
                          Access Project</a></li>
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.pageKey}}/personal.htm">
                          Remove Template</a></li>
                </ul>
              </div>
            </td>
            <td class="repositoryName">
                <a href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.pageKey}}/notesList.htm">
                   {{rec.name}}
                </a>
            </td>
            <td>{{rec.changed|date}}</span></td>
            <td>{{rec.visited|date}}</span></td>
        </tr>
    </table>

    <div class="guideVocal" ng-show="noneFound">
        User <% uProf.writeLink(ar); %> has not specified any templates.<br/>
            <br/>
            Templates are references to normal projects.  When you
            create a new project, you can specify a template, and all the action items
            and roles are copied (empty & unstarted) into the new project.
            This is a convenient way to 'prime' a project with the normal tasks
            and roles that you need. <br/>
            <br/>
            If you visit a project which has a good form, and you might want to use it
            in the future as a template, on that project go the "Project Settings>Personal" page,
            and choose to remember the project as a template.  Then that project will appear here
            and in other places where you can use a template, such as at the time that you
            create a new project.
    </div>

</div>
