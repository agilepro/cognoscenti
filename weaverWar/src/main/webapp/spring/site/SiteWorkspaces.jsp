<%@page errorPage="/spring/jsp/error.jsp"
%><%@include file="/spring/jsp/include.jsp"
%><%
    UserProfile uProf = ar.getUserProfile();
    Cognoscenti cog = ar.getCogInstance();
    
    List<NGPageIndex> ownedProjs = ar.getCogInstance().getAllContainers();
    String accountKey = ar.reqParam("siteId");
    NGBook site = cog.getSiteByIdOrFail(accountKey);
    boolean showExperimental = site.getShowExperimental();

    JSONArray projList = new JSONArray();
    for (NGPageIndex ngpi : cog.getAllProjectsInSite(accountKey)) {
        if (!ngpi.isWorkspace()) {
            continue;
        }
        projList.put(ngpi.getJSON4List());
    }
    for (NGPageIndex ngpi : cog.getDeletedContainers()) {
        if (!ngpi.isWorkspace()) {
            continue;
        }
        if (!accountKey.equals(ngpi.wsSiteKey)) {
            // only consider if the project is in the site we look for
            continue;
        }
        projList.put(ngpi.getJSON4List());
    }
    boolean noneFound = projList.length()==0;
    

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
    window.setMainPageTitle("Workspaces in Site");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.projList = <%projList.write(out,2,4);%>;
    $scope.noneFound = <%=noneFound%>;
    $scope.numberFound = <%=ownedProjs.size()%>
    $scope.filter = "";
    $scope.showExperimental = <%=showExperimental%>;

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
    $scope.getWorkspaceName = function(wsKey) {
        var res = null;
        $scope.projList.forEach( function(item) {
           if (item.pageKey == wsKey) {
               res = item;
           } 
        });
        if (res) {
            return res.name;
        }
        else {
            return wsKey;
        }
    }
    
    $scope.sortItems();
    
    $scope.garbageCollect = function() {
        if (!confirm("Do you really want to delete the workspaces marked for deletion?")) {
            return;
        }
        var postURL = "GarbageCollect.json";
        $http.get(postURL)
        .success( function(data) {
            console.log("Garbage Results", data);
            alert("Success.  REFRESHING the page");
            window.location.reload();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }

});

</script>

<div>

<%@include file="../jsp/ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem"
              href="SiteCreateWorkspace.htm" >Create New Workspace</a></li>
          <li role="presentation" class="divider"></li>
          <li role="presentation"><a role="menuitem" 
              ng-click="garbageCollect()">Garbage Collect</a></li>
        </ul>
      </span>
    </div>


    <div class="well">Filter <input ng-model="filter"></div>
    <div style="height:10px;"></div>

    <table class="table" width="100%">
        <tr >
            <td width="50px"></td>
            <td width="200px">Workspace</td>
            <td width="100px">Changed</td>
            <td width="100px">Parent</td>
        </tr>
        <tr ng-repeat="rec in getRows()">
            <td>
              <div class="dropdown">
                <button class="dropdown-toggle specCaretBtn" type="button"  d="menu" 
                    data-toggle="dropdown"> <span class="caret"></span> </button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.pageKey}}/frontPage.htm">Access Workspace</a></li>
                  <li role="presentation"><a role="menuitem"
                      href="SiteCreateWorkspace.htm?parent={{rec.pageKey}}" >Create Child Workspace</a></li>
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
            <td>{{rec.changed|cdate}}</td>
            <td><a href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.parentKey}}/frontPage.htm">{{getWorkspaceName(rec.parentKey)}}</a></td>
        </tr>
    </table>
    
    <a href="SiteCreateWorkspace.htm" >
        <button class="btn btn-primary btn-raised"><i class="fa fa-plus"></i> Create Workspace</button>
    </a>

    <div class="guideVocal" ng-show="noneFound">
       <p>
        This site &quot;{{siteInfo.names[0]}}&quot; does not have any workspaces.
       </p>
       <p>
       The "Owner" or "Executive" of a "Site" has permission to create a workspace.
       </p>
       <p>
       Use the button
       <a href="SiteCreateWorkspace.htm">
           <button class="btn btn-sm btn-primary btn-raised"><i class="fa fa-plus"></i> Create Workspace</button></a>
       to create a new workspace.
       </p>
       <p>
       If you would like some guidance in how to do this, and how sites and workspaces work,
       please check the tutorial on the topic of <a href="https://s06.circleweaver.com/Tutorial02.html">Sites &amp; Workspaces</a>
       for a complete walk through on how to do this.
       </p>
       <p>
       <a href="https://s06.circleweaver.com/Tutorial02.html"  target="Tutorials">
           <img src="https://s06.circleweaver.com/tutorial-files/Tutorial02-thumb.png"
                class="tutorialThumbnail"/>
       </a>
       </p>
    </div>
</div>
