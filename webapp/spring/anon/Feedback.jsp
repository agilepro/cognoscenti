<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page isErrorPage="true"
%><%@include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.ErrorLog"
%><%@page import="org.socialbiz.cog.ErrorLogDetails"
%><%

    String url = ar.defParam("url", "");

%>

<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="Content-Language" content="en-us" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta http-equiv="imagetoolbar" content="no" />
    <meta name="viewport" content="user-scalable=no, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0" />

    <!-- INCLUDE the ANGULAR JS library -->
    <script src="<%=ar.baseURL%>jscript/angular.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/ui-bootstrap-tpls.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/jquery.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/bootstrap.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/slap.js"></script>
    <link href="<%=ar.baseURL%>jscript/bootstrap.min.css" rel="stylesheet">
    <script src='<%=ar.baseURL%>jscript/tinymce/tinymce.min.js'></script>
    <script src='<%=ar.baseURL%>jscript/tinymce/tinymce-ng.js'></script>
    <script src="<%=ar.baseURL%>jscript/textAngular-sanitize.min.js"></script>
    <link href="<%=ar.baseURL%>jscript/ng-tags-input.css" rel="stylesheet">
    <script src="<%=ar.baseURL%>jscript/bootstrap-material-design/ripples.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/bootstrap-material-design/material.min.js"></script>
    <link rel="stylesheet" href="<%=ar.baseURL%>css/bootstrap-material-design/bootstrap-material-design.min.css" media="screen">
    <link rel="stylesheet" href="<%=ar.baseURL%>css/bootstrap-material-design/ripples.min.css" media="screen">
    <script src="<%=ar.baseURL%>jscript/common.js"></script>

	<!-- INCLUDE web fonts -->
    <link href="<%=ar.retPath%>assets/font-awesome/css/font-awesome.min.css" rel="stylesheet"
          data-semver="4.3.0" data-require="font-awesome@*" />
	  <link href="<%=ar.retPath%>assets/google/css/PT_Sans-Web.css" rel="stylesheet"/>

    <link href="<%=ar.retPath%>bits/fixed-sidebar.min.css" rel="styleSheet" type="text/css" media="screen" />
    <!-- Weaver specific tweaks -->
    <link href="<%=ar.retPath%>bits/main.min.css" rel="styleSheet" type="text/css" media="screen" />

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
console.log("RUN RUN");

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
        })
        .error( function(data) {
           console.log("got error: ", data);
        });        
    }
});
</script>

</head>


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
<body>
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
        </tr></table>

    </div>
    
    
    <div class="guideVocal" ng-show="showThanks">
        Thanks for sending additional information, this has been recorded in a file
        accessible to the administrators.  
    </div>
    
</body>
</html>






