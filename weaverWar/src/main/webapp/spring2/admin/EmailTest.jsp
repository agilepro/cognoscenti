<%@page errorPage="/spring2/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.ErrorLog"
%><%@page import="com.purplehillsbooks.weaver.ErrorLogDetails"
%><%@page import="java.text.ParsePosition"
%><%@ include file="/include.jsp"
%><%

    Cognoscenti cog = Cognoscenti.getInstance(request);

%>
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    $scope.toAddress = "test@example.com";
    $scope.subject = "Test Email "+new Date();
    $scope.from = "admin@weaver.com";
    $scope.body = "This is an email used to test the configuration of a server.   If you receive it, you can safely ignore it.";
    $scope.status = "unsent";
    
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    
    $scope.sendIt = function() {
        var postObj = {};
        postObj.to = $scope.toAddress;
        postObj.from = $scope.from;
        postObj.subject = $scope.subject;
        postObj.body = $scope.body;
        var postdata = angular.toJson(postObj);
        $http.post("../su/testEmailSend.json", postdata)
        .success( function(data) {
            console.log("AFTER SENDING EMAIL: ", data);
            $scope.status = data.status;
        })
        .error( function(data) {
           console.log("got error: ", data);
           $scope.reportError(data);
        });
    }
    console
});

</script>


<div ng-app="myApp" ng-controller="myCtrl">


    <div class="h1">Send Test Email  
    </div>
        
    <div style="max-width:600px">
      <div class="form-group">
        <label>To:</label>
        <input ng-model="toAddress" type="text" class="form-control"/>
      </div>
      <div class="form-group">
        <label>From:</label>
        <input ng-model="from" type="text" class="form-control"/>
      </div>
      <div class="form-group">
        <label>Subject:</label>
        <input ng-model="subject" type="text" class="form-control"/>
      </div>
      <div class="form-group">
        <label>Body:</label>
        <textarea ng-model="body" class="form-control"/></textarea>
      </div>
    
      <div class="form-group">
        <button class="btn btn-primary btn-raised" ng-click="sendIt()">Send It</button>  
      </div>
      
      <div class="form-group">
        <label>Status:</label>
        {{status}}
      </div>
    
    </div>

</div>

<%@include file="ErrorPanel.jsp"%>
