<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@page import="com.purplehillsbooks.weaver.CustomRole"
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

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Running Process");
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

        
        var postURL = $scope.processUrl + "api/t="+$scope.tenant+"/a="+$scope.appId+"/AllActiveProcesses";
        console.log("calling: "+postURL);
        SLAP.postJSON(postURL, {},
            function(data) {
                data.piList.forEach( function(item) {
                    if (item.forms && item.forms.length>0) {
                        item.uiurl = $scope.processUrl + "api/t="+$scope.tenant+"/a="
                             +$scope.appId+"/ui/"+item.forms[0]+"?pdId="+item.pdId+"&piId="+item.piId;
                    }
                    else {
                        item.uiurl = $scope.processUrl + "HomePage.html?t="+$scope.tenant
                             +"&a="+$scope.appId+"/pi="+item.piId;
                    }
                    item.uiurl = $scope.processUrl + "#/instanceDetail/"+$scope.tenant+"/a/"+$scope.appId+"/pi/"+item.idInst;
                });
                $scope.processes = data.piList;
                console.log("Got processes:", data);
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

<div>

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
        <td>ID</td>
        <td>Name</td>
        <td>Due</td>
        <td>State</td>
      </tr>
      <tr ng-repeat="proc in processes">
        <td>
          <div class="dropdown">
            <button class="dropdown-toggle specCaretBtn" type="button"  d="menu" 
                data-toggle="dropdown"> <span class="caret"></span> </button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem"
                href="{{proc.uiurl}}">View Process</a></li>
            </ul>
          </div>
        </td>
        <td>{{proc.idInst}}</td>
        <td><a href="{{proc.uiurl}}">{{proc.name}} <i class="fa fa-external-link"></i></a></td>
        <td>{{proc.due |cdate}}</td>
        <td>{{proc.state}}</td>
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
