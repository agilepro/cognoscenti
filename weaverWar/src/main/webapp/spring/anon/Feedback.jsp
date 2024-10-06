<%@page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8"
%><%@page isErrorPage="true"
%><%@include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.ErrorLog"
%><%@page import="com.purplehillsbooks.weaver.ErrorLogDetails"
%><%

    String url = ar.defParam("url", "");

%>

<script type="text/javascript">

var app = angular.module('myApp');

app.controller('myCtrl', function($scope, $http) {
    $scope.log_number = -1;
    $scope.logDate = <%=ar.nowTime%>;
    $scope.comment = "";
    $scope.showThanks = false;
    $scope.url = "<% ar.writeJS(url); %>";
    
    $scope.submitComment = function() {
        var errUp = {};
        errUp.errNo = $scope.log_number;
        errUp.logDate = $scope.logDate;
        errUp.comment = $scope.comment;
        errUp.message = "Feedback submitted by <% ar.writeHtml(ar.getBestUserId()); %>";
        var postdata = angular.toJson(errUp);
        console.log("sending this: ", errUp);
        $http.post("<%=ar.baseURL%>t/su/submitComment", postdata)
        .success( function(data) {
            console.log("got a response: ", data);
            $scope.log_number = data.errNo;
            console.log("Set id to: ", $scope.log_number)
            $scope.showThanks = true;
            $scope.returnToPage();
        })
        .error( function(data) {
           console.log("got error: ", data);
        });        
    }
    
    $scope.returnToPage = function() {
        window.location.assign($scope.url);
    }
});
</script>

<style type="text/css">
td {
    padding:100;
    border:10;
    margin:10;
    vertical-align:top;
}
.spacey tr td {
    padding: 5px 10px;
}
</style>

  <div ng-app="myApp" ng-controller="myCtrl" style="margin:50px;max-width:800px">

    <nav class="navbar navbar-default appbar">
      <div class="container-fluid">
        <!-- Logo Brand -->
        <a class="navbar-brand" href="<%=ar.retPath%>" title="Weaver Home Page">
          <img class="hidden-xs" alt="Weaver Icon" src="<%=ar.retPath%>bits/header-icon.png">
          <h1>Weaver</h1>
        </a>
      </div>
    </nav>
    
    <div>
        <div class="page-name">
            <h1 id="mainPageTitle" ng-click="infoOpen=!infoOpen"
                title="This is the title of the discussion topic that all these topics are attached to">
                Feedback Form
            </h1>
        </div>
        
        <div class="guideVocal">
            Thanks for giving us feedback on the product.  
            This is  very much appreciated. 
            Try to include as many details as you  can about what you were doing
            that caused the behavior to be addressed.
        </div>
    
        <table class="table">
        <col style="width:120px">
        <col style="max-width:500px">
        <tr>
          <td>Date & Time:</td>
          <td><% SectionUtil.nicePrintDateAndTime(ar.w, ar.nowTime); %> </td>
        </tr><tr>
          <td>Feedback:</td>
          <td>
             <textarea class="form-control" ng-model="comment" style="height:300px"></textarea>
          </td>
        </tr><tr>
          <td>Incident ID:</td>
          <td>{{log_number}}</td>
        </tr><tr>
          <td>Logged in as:</td>
          <td><% ar.writeHtml(ar.getBestUserId()); %> </td>
        </tr><tr>
          <td>URL:</td>
          <td>{{url}}</td>
        </tr><tr>
          <td></td>
          <td><button ng-click="submitComment()" class="btn btn-primary btn-raised">Send Feedback</button></td>
        </tr><tr>
          <td></td>
          <td><button ng-click="returnToPage()" class="btn btn-warning btn-raised">Return</button></td>
        </tr></table>

    </div>
    
    
    <div class="guideVocal" ng-show="showThanks">
        Thanks for sending additional information, this has been recorded in a file
        accessible to the administrators.  
    </div>
  </div>





