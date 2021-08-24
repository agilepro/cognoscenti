<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@page import="com.purplehillsbooks.weaver.CustomRole"
%><%


    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    NGBook ngb = ngw.getSite();
    
    JSONObject siteInfo = ngb.getConfigJSON();
    
    String processUrl = ar.getSystemProperty("processUrl");
    

%>


<script>

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Available Process Applications");
    $scope.siteInfo = <%siteInfo.write(out,2,4);%>;
    $scope.caseId = "<% ar.writeJS(siteId+"|"+pageId); %>";
    $scope.processUrl = "<% ar.writeJS(processUrl); %>";
    $scope.initialFetchDone = false;
    $scope.processes = [];
    
    $scope.getAllTenants = function() {
        if (!$scope.processUrl || $scope.processUrl.length==0) {
            alert("processUrl is no configured in the config.txt file");
            return;
        }
        var postURL = $scope.processUrl + "api/Tenants";
        $http.get(postURL)
        .success( function(data) {
            data.tenants.forEach( function(item) {
                $scope.getAppList(item.name);
            });
            console.log("Got applications:", data);
            $scope.initialFetchDone = true;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.getAppList = function(tenant) {
        if (!$scope.processUrl || $scope.processUrl.length==0) {
            alert("processUrl is no configured in the config.txt file");
            return;
        }
        var postURL = $scope.processUrl + "api/t="+tenant+"/Applications";
        $http.get(postURL)
        .success( function(data) {
            data.applications.forEach( function(item) {
                if (item.homePage.indexOf("http")<0) {
                    item.homePage = $scope.processUrl + item.homePage;
                }
                $scope.processes.push(item);
            });
            console.log("Got applications:", data);
            $scope.initialFetchDone = true;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    
    $scope.getAllTenants();
});

</script>

<div>

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" href="ProcessApps.htm">
              Process Applications</a>
          </li>
        </ul>
      </span>
     </div>

    <table class="table">
      <tr>
        <td></td>
        <td>Application Name</td>
        <td>Description</td>
        <td>Owner</td>
      </tr>
      <tr ng-repeat="app in processes">
        <td>
          <div class="dropdown">
            <button class="dropdown-toggle specCaretBtn" type="button"  d="menu" 
                data-toggle="dropdown"> <span class="caret"></span> </button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem"
                href="ProcessRun.htm?t={{app.tenant}}&a={{app.id}}">View Processes</a></li>
              <li role="presentation"><a role="menuitem"
                href="ProcessTasks.htm?t={{app.tenant}}&a={{app.id}}">View Tasks</a></li>
            </ul>
          </div>
        </td>
        <td><a href="{{app.homePage}}?CaseID={{caseId}}">{{app.name}} <i class="fa fa-external-link"></i></a></td>
        <td style="max-width:500px">{{app.description}} -  {{app.tenant}} / {{app.id}}</td>
        <td>{{app.owner}}</td>
      </tr>
    </table>

        
    <div class="instruction" ng-show="processes.length==0 && !initialFetchDone" style="margin-top:80px">
    Fetching process applications . . .
    </div>
    <div class="guideVocal" ng-show="processes.length==0 && initialFetchDone" style="margin-top:80px">
    You have no process applications at this time.
    </div>
       
</div>

<script src="<%=ar.retPath%>templates/CreateTopicModal.js"></script>
