<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@page import="com.purplehillsbooks.weaver.License"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    ar.assertExecutive("Must be logged in as site executive to use site admin functions");
    String siteId = ar.reqParam("siteId");
    Cognoscenti cog = ar.getCogInstance();
    NGBook site = cog.getSiteByIdOrFail(siteId);


%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Template Editor");
    
    $scope.templateName = "DiscussionTopicManual.chtml";
    $scope.templateBody = "";

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.getTemplate = function() {
        var getURL = "getChunkTemplate.chtml?t=" + $scope.templateName;
        console.log("REQUEST URL", getURL)
        $http.get(getURL)
        .success( function(data) {
            $scope.templateBody = data;
            console.log("result", data);
        })
        .error( function(data, status, headers, config) {
            console.log("ERROR", data, status)
        });
    }
    $scope.saveTemplate = function() {
        var postData = $scope.templateBody;
        var postURL = "putChunkTemplate.chtml?t=" + $scope.templateName;
        console.log("REQUEST URL", postURL, postData);
        $http.put(postURL, postData)
        .success( function(data) {
            console.log("result", data);
        })
        .error( function(data, status, headers, config) {
            console.log("ERROR", data, status)
        });
    }
    $scope.eraseTemplate = function() {
        if (confirm("Are you sure you want to remove this template, and go back to the default template?")) {
            $scope.templateBody = "";
            $scope.saveTemplate();
        }
    }
});
</script>

<div>

<%@include file="../jsp/ErrorPanel.jsp"%>



<style>

</style>

<h2>Caution: Experimental Feature, Use carefully</h2>

<div>
<textarea style="width:800px;height:400px" ng-model="templateBody"></textarea>
</div>
<div>
<button ng-click="saveTemplate()" class="btn btn-primary btn-raised">Update Server</button>
<button ng-click="getTemplate()" class="btn btn-primary btn-raised">Get from Server</button>
<button ng-click="eraseTemplate()" class="btn btn-primary btn-raised">Erase Template</button>
</div>

</div>

