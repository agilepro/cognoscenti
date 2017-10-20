<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.CustomRole"
%><%


    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    String tenant = ar.reqParam("t");
    String appId = ar.reqParam("a");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    NGBook ngb = ngw.getSite();
    
    JSONObject siteInfo = ngb.getConfigJSON();
    
    String processUrl = ar.getSystemProperty("processUrl");
    

%>


<script>

var app = angular.module('myApp', ['ui.bootstrap', 'ui.tinymce', 'ngSanitize']);
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Current Process Work Items");
    $scope.siteInfo   = <%siteInfo.write(out,2,4);%>;
    $scope.processUrl = "<% ar.writeJS(processUrl); %>";
    $scope.tenant     = "<% ar.writeJS(tenant); %>";
    $scope.appId      = "<% ar.writeJS(appId); %>";
    $scope.processes = [];
    $scope.initialFetchDone = false;

    $scope.reportError = function(data) {
        console.log("ERROR", data);
    }
    $scope.getAppList = function() {
        if (!$scope.processUrl || $scope.processUrl.length==0) {
            alert("processUrl is not configured in the config.txt file");
            return;
        }
        var myCaseId = "";
        var outData = {filterBy: [ {udaName:"", udaType:"STRING", sqlOperator:"=", value: myCaseId}]};

        
        var postURL = $scope.processUrl + "api/t="+$scope.tenant+"/a="+$scope.appId+"/AllWorkItems";
        console.log("calling: "+postURL);
        SLAP.postJSON(postURL, {},
            function(data) {
                data.wiList.forEach( function(item) {
                    item.uiurl = $scope.processUrl + "#/workItemDetail/"+$scope.tenant+"/a/"+$scope.appId+"/wi/"+item.id;
                });
                $scope.processes = data.wiList;
                console.log("Got tasks:", data);
                $scope.initialFetchDone = true;
                $scope.$apply();
            },
            function(error) {
                console.log("failed", data);
                $scope.reportError(error);
            });
    };
    
    $scope.getAppList();
});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" href="ProcessApps.htm">
              <i class="fa fa-backward"></i> Process Applications</a>
          </li>
        </ul>
      </span>
     </div>

    <table class="table">
      <tr>
        <td></td>
        <td>Assignee</td>
        <td>Name</td>
        <td>Created</td>
        <td>Values</td>
      </tr>
      <tr ng-repeat="proc in processes">
        <td>
          <div class="dropdown">
            <button class="dropdown-toggle specCaretBtn" type="button"  d="menu" 
                data-toggle="dropdown"> <span class="caret"></span> </button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem"
                href="ProcessApps.htm">Nothing</a></li>
            </ul>
          </div>
        </td>
        <td>{{proc.assignee}}</td>
        <td><a href="{{proc.uiurl}}">{{proc.name}} <i class="fa fa-external-link"></i></a></td>
        <td>{{proc.creationTime | date}}</td>
        <td><div ng-repeat="(name,val) in proc.uda">{{name}}: {{val}}</div></td>
      </tr>
    </table>

        
    <div class="instruction" ng-show="processes.length==0 && !initialFetchDone" style="margin-top:80px">
    Fetching processes . . .
    </div>
    <div class="guideVocal" ng-show="processes.length==0 && initialFetchDone" style="margin-top:80px">
    You have no running processes from this application at this time.
    </div>
       
</div>

<script src="<%=ar.retPath%>templates/CreateTopicModal.js"></script>
