<%@page errorPage="/spring2/jsp/error.jsp"
%><%@include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.WatchRecord"
%><%

    UserProfile uProf =(UserProfile)request.getAttribute("userProfile");
    List<WatchRecord> watchList = uProf.getWatchList();
    boolean noneFound = watchList.size()==0;

    JSONArray wList = new JSONArray();
    for (WatchRecord wr : watchList) {
        String pageKey = wr.pageKey;
        NGPageIndex ngpi = ar.getCogInstance().getWSByCombinedKey(pageKey);
        if (ngpi==null) {
            ngpi = ar.getCogInstance().lookForWSBySimpleKeyOnly(pageKey);
        }
        if (ngpi==null) {
            continue;
        }
        JSONObject wObj = ngpi.getJSON4List();
        wObj.put("visited", wr.lastSeen);
        wList.put(wObj);
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
    window.setMainPageTitle("Watched Workspaces");
    $scope.wList = <%wList.write(out,2,4);%>;
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
        $scope.wList.sort( function(a, b){
            return b.changed - a.changed;
        });
        return $scope.wList;
    };
    $scope.getRows = function() {
        var lcfilter = parseLCList($scope.filter);
        var res = [];
        var last = $scope.wList.length;
        for (var i=0; i<last; i++) {
            var rec = $scope.wList[i];
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
<div class="userPageContents">

<%@include file="../jsp/ErrorPanel.jsp"%>

<div class="col-10 well ms-5">Filter <input ng-model="filter"></div>

    <div class="container-fluid col-10 ms-5">
        <div class="row d-flex border-bottom border-1">
            <span class="col-1 m-3"></span>
            <span class="col-4 h6">Workspace</span>
            <span class="col-2 h6">Changed</span>
            <span class="col-2 h6">Last Review</span>
            <span class="col-1 h6">Site</span>
        </div>
        <div class="row d-flex border-bottom border-1" ng-repeat="rec in getRows()">
            <span class="col-1 m-3">
                <div class="nav-item dropdown">
                    <button class="specCaretBtn dropdown-toggle " type="button"  id="PartProjects" 
                data-toggle="dropdown"> 
                    <span class="caret"></span>         
                    </button>
                        <ul class="dropdown-menu" role="menu" aria-labelledby="docsList">
                            <li><a class="dropdown-item" role="menuitem" tabindex="0" href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.pageKey}}/FrontPage.htm">Access Workspace</a></li>
                            <li><a class="dropdown-item" role="menuitem" tabindex="-1" href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.pageKey}}/Personal.htm">Stop Watching</a></li>
                        </ul>
                    </div>
                </span>
          
                <span class="col-4 my-3 repositoryName">
                <a href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.pageKey}}/FrontPage.htm">
                   {{rec.name}}
                       <span ng-show="rec.isDeleted" style="color:grey"> (DELETED)</span>
                       <span ng-show="rec.frozen" style="color:grey"> (FROZEN)</span>
                       <span ng-show="rec.isMoved" style="color:grey"> (MOVED)</span>
                </a>
            </span>
            <span class="col-2">{{rec.changed|cdate}}</span>
            <span class="col-2">{{rec.visited|cdate}}</span>
            <span class="col-1">{{rec.siteKey}}</span>
        </div>
    </div>
    <div class="container-fluid well col-10 ms-5 mt-4">
    <div class="guideVocal" ng-show="noneFound">
        User <% uProf.writeLink(ar); %> is not watching any projects.<br/>
        <br/>
        As you visit projects, go to the "Workspace Settings &gt; Personal" page, and choose
        to watch the workspace.  Then that workspace will appear here.  It is a convenient
        way to keep track of the projects that you are currently working on.<br/>
        <br/>
        Later, when you are no longer interested, it is easy to stop watching a workspace.
    </div>

</div>
