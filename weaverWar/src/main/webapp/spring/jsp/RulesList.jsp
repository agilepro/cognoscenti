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
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Business Rules / Decisions");
    $scope.siteInfo = <%siteInfo.write(out,2,4);%>;
    $scope.caseId = "<% ar.writeJS(siteId+"|"+pageId); %>";
    $scope.processUrl = "<% ar.writeJS(processUrl); %>";
    $scope.initialFetchDone = false;
    $scope.rules = [];
    
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
            console.log("Got tenants:", data);
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
                $scope.getRulesList(tenant, item.id);
            });
            console.log("Got applications ("+tenant+"):", data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.getRulesList = function(tenant, appId) {
        if (!$scope.processUrl || $scope.processUrl.length==0) {
            alert("processUrl is no configured in the config.txt file");
            return;
        }
        console.log("REQUEST: ("+tenant+","+appId+")");
        var postURL = $scope.processUrl + "api/t="+tenant+"/a="+appId+"/ObtainRules";
        SLAP.postJSON(postURL, {},
            function(data) {
                data.rules.forEach( function(item) {
                    item.uiurl = $scope.processUrl + "#/rules/"+tenant+"/a/"+appId;
                    item.tenant = tenant;
                    item.appId = appId;
                    $scope.rules.push(item);
                });
                console.log("Got rules ("+tenant+","+appId+"):", data);
                $scope.initialFetchDone = true;
                $scope.rules.sort( function(a,b) {
                    if (a>=b) {
                        return -1;
                    }
                    else {
                        return 1;
                    }
                });
                $scope.$apply();
            },
            function(data, status, headers, config) {
                $scope.reportError(data);
                $scope.$apply();
            });
    };
    $scope.reportError = function(error) {
        console.log("HIT AN ERROR:", error);
    }
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
          <li role="presentation"><a role="menuitem" href="ProcessRun.htm">
              Running Process</a>
          </li>
          <li role="presentation"><a role="menuitem" href="ProcessTasks.htm">
              Process Tasks</a>
          </li>
        </ul>
      </span>
     </div>

    <table class="table">
      <tr>
        <td></td>
        <td>Tenant / ID</td>
        <td>Name</td>
        <td>Description</td>
      </tr>
      <tr ng-repeat="rule in rules">
        <td>
          <div class="dropdown">
            <button class="dropdown-toggle specCaretBtn" type="button"  d="menu" 
                data-toggle="dropdown"> <span class="caret"></span> </button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem"
                href="ProcessRun.htm?t={{rule.tenant}}&a={{rule.appId}}">View Rule</a></li>
              <li role="presentation"><a role="menuitem"
                href="{{rule.uiurl}}">Test Rule</a></li>
            </ul>
          </div>
        </td>
        <td>{{rule.tenant}} / {{rule.appId}}</td>
        <td><a href="{{rule.uiurl}}">{{rule.name}} <i class="fa fa-external-link"></i></a></td>
        <td>{{rule.description}}</td>
      </tr>
    </table>

        
    <div class="instruction" ng-show="processes.length==0 && !initialFetchDone" style="margin-top:80px">
    Fetching business rules / decisions . . .
    </div>
    <div class="guideVocal" ng-show="processes.length==0 && initialFetchDone" style="margin-top:80px">
    You have no business rules at this time.
    </div>
       
</div>

<script src="<%=ar.retPath%>templates/CreateTopicModal.js"></script>
