<%@page errorPage="/spring2/jsp/error.jsp"
%><%@include file="/include.jsp"
%><%
    UserProfile uProf =(UserProfile)request.getAttribute("userProfile");
    List<NGPageIndex> ownedProjs = ar.getCogInstance().getWorkspacesUserIsIn(uProf);
    
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
    window.setMainPageTitle("Workspaces <% ar.writeJS(uProf.getName()); %> Participate In");
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
<div class="userPageContents">

<%@include file="../jsp/ErrorPanel.jsp"%>


<div class="col-8 well ms-5">Filter <input ng-model="filter"></div>

    <div class="container-fluid col-8 ms-5">
        <div class="row d-flex border-bottom border-1">
            <span class="col-1 m-3"></span>
            <span class="col-4 h6">Workspace</span>
            <span class="col-3 h6">Changed</span>
            </div>

            <div class="row d-flex border-bottom border-1" ng-repeat="rec in getRows()">
                <span class="col-1 m-3">
                    <div class="nav-item dropdown">
                        <button class="specCaretBtn dropdown-toggle " type="button"  id="PartProjects" 
                    data-toggle="dropdown"> 
                        <span class="caret"></span>         
                        </button>
                        <ul class="dropdown-menu" role="menu" aria-labelledby="PartProjects">
                            <li role="presentation"><a class="dropdown-item" role="menuitem" tabindex="0" href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.pageKey}}/FrontPage.htm">Access Workspace</a></li>
                            <li role="presentation"><a class="dropdown-item" role="menuitem" tabindex="-1" href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.pageKey}}/RoleManagement.htm">Abandon Workspace</a></li>
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
            <span class="col-3 my-3">{{rec.changed|cdate}}</span>
        </div>
        </div>
        <div class="container-fluid well col-8 ms-5 mt-4">
    <div class="guideVocal" ng-show="noneFound">
        User <% uProf.writeLink(ar); %> has not created any projects, and does not have any access to sites to create one.
       <br/><br/>
       When a user creates projects, they will be listed here.<br/>
       <br/>
       In order to create a workspace, you need to be an "Owner" or an "Executive" of an "Site".<br/>
       <br/>
       Use <button class="btn btn-sm" onClick="location.href='userSites.htm'"><img src="<%=ar.retPath%>new_assets/assets/navicon/UserSiteAdmin.png" style="max-height:25px;max-width:25px"></button>
       to view your sites. Or request a new site from the system administrator here: <form name="createAccountForm" method="GET" action="NewSiteRequest.htm">
        <input type="submit" class="btn btn-sm btn-comment btn-wide btn-primary my-3"  Value="Request New Site">
    </form>
       If approved you will be the owner of that new site,
       and can create new projects within it.
    </div>

</div>
