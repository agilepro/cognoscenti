<%@page errorPage="/spring2/jsp/error.jsp"
%><%@include file="/include.jsp"
%><%
    UserProfile uProf = ar.getUserProfile();
    Cognoscenti cog = ar.getCogInstance();
    
    List<NGPageIndex> ownedProjs = ar.getCogInstance().getAllContainers();
    String siteId = ar.reqParam("siteId");
    NGBook site = cog.getSiteByIdOrFail(siteId);
    boolean showExperimental = site.getShowExperimental();

    JSONArray projList = new JSONArray();
    for (NGPageIndex ngpi : cog.getNonDelWorkspacesInSite(siteId)) {
        if (!ngpi.isWorkspace()) {
            continue;
        }
        projList.put(ngpi.getJSON4List());
    }
    for (NGPageIndex ngpi : cog.getDeletedContainers()) {
        if (!ngpi.isWorkspace()) {
            continue;
        }
        if (!siteId.equals(ngpi.wsSiteKey)) {
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

<div ng-cloak>

<%@include file="../jsp/ErrorPanel.jsp"%>

<div class="container-fluid override mx-2">
    <div class="col-md-auto second-menu d-flex">
        <button type="button" data-bs-toggle="collapse" data-bs-target="#collapseSecondaryMenu" aria-expanded="false"
            aria-controls="collapseSecondaryMenu">
            <i class="fa fa-bars"></i></button>
            <div class="collapse" id="collapseSecondaryMenu">
                <div class="col-md-auto">
                    <span class="btn second-menu-btn btn-wide" type="button" aria-labelledby="createNewWorkspace"><a class="nav-link"
                        href="SiteCreateWorkspace.htm" >Create New Workspace</a></span>
                    <span class="btn second-menu-btn btn-wide" type="button" ng-click="garbageCollect()" aria-labelledby="collectGarbage"><a class="nav-link"
                        >Garbage <i class="fa fa-trash"></i> Collect</a></span>
                </div>
            </div>
        </div>

    <div class="d-flex col-9">
        <div class="contentColumn">
                <div class="col-12 well ms-3">Filter <input ng-model="filter"></div>
        <div class="row d-flex border-bottom border-1 ms-3">
            <span class="col-1 m-3"></span>
            <span class="col-4 h6">Workspace</span>
            <span class="col-2 h6">Changed</span>
            <span class="col-4 h6">Parent</span>
        </div>
        <div class="row d-flex border-bottom border-1 ms-3" ng-repeat="rec in getRows()">
            <span class="col-1 m-3">
                <div class="nav-item dropdown">
                    <button class="specCaretBtn dropdown-toggle " type="button"  id="SiteWorkspaces" data-bs-toggle="dropdown" aria-expanded="false"><span class="caret "></span></button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="siteWorkspaces">
                    <li><a class="dropdown-item" role="menuitem" tabindex="-1" href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.pageKey}}/FrontPage.htm">Access Workspace</a></li>
                    <li><a class="dropdown-item" role="menuitem"
                      href="SiteCreateWorkspace.htm?parent={{rec.pageKey}}" >Create Child Workspace</a></li>
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
            <span class="col-4"><a href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.parentKey}}/FrontPage.htm">{{getWorkspaceName(rec.parentKey)}}</a>
            </span>
        </div>
    </div>
</div>
    
<div class="container-fluid col-10 ms-3 my-4">
    <div class="guideVocal">
        Site can have {{siteInfo.workspaceLimit}} active workspaces.
    </div>

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
           <button class="btn btn-wide btn-primary btn-raised"><i class="fa fa-plus"></i> Create Workspace</button></a>
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
