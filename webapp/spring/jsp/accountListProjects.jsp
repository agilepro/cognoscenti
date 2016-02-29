<%@page errorPage="/spring/jsp/error.jsp"
%><%@include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.NotificationRecord"
%><%
    UserProfile uProf = ar.getUserProfile();
    List<NGPageIndex> ownedProjs = ar.getCogInstance().getAllContainers();
    boolean noneFound = ownedProjs.size()==0;
    String accountKey = ar.reqParam("accountId");

    JSONArray projList = new JSONArray();
    for (NGPageIndex ngpi : ar.getCogInstance().getAllProjectsInSite(accountKey)) {
        if (!ngpi.isProject()) {
            continue;
        }
        JSONObject jo = ngpi.getJSON4List();
        jo.put("parentKey", ngpi.parentKey);
        projList.put(jo);
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
});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Workspaces that belong to this site
        </div>
        <!--div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="" >Do Nothing</a></li>
            </ul>
          </span>

        </div-->
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
                    </ul>
                  </div>
                </td>
                <td class="repositoryName">
                    <a href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.pageKey}}/frontPage.htm">
                       {{rec.name}}
                    </a>
                </td>
                <td>{{rec.changed|date}}</span></td>
                <td><a href="<%=ar.retPath%>t/{{rec.siteKey}}/{{rec.parentKey}}/frontPage.htm">{{getWorkspaceName(rec.parentKey)}}</a></td>
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
</div>
