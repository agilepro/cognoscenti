<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.SharePortRecord"
%><%@ include file="/spring/jsp/include.jsp"
%><%

//    String pageId  = ar.reqParam("pageId");
//    String siteId  = ar.reqParam("siteId");
//    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
//    ar.setPageAccessLevels(ngw);   
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
    <script src="<%=ar.baseURL%>jscript/jquery-3.6.0.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/bootstrap.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/slap.js"></script>

    <link href="<%=ar.baseURL%>jscript/ng-tags-input.css" rel="stylesheet">
    <script src="<%=ar.baseURL%>jscript/textAngular-sanitize.min.js"></script>
    <!--
    <script src="<%=ar.baseURL%>jscript/bootstrap-material-design/ripples.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/bootstrap-material-design/material.min.js"></script>
    <link rel="stylesheet" href="<%=ar.baseURL%>css/bootstrap-material-design/bootstrap-material-design.min.css" media="screen">
    <link rel="stylesheet" href="<%=ar.baseURL%>css/bootstrap-material-design/ripples.min.css" media="screen">
-->
    <!-- INCLUDE web fonts -->
    <link href="<%=ar.retPath%>assets/font-awesome/css/font-awesome.min.css" rel="stylesheet"
          data-semver="4.3.0" data-require="font-awesome@*" />
      <link href="<%=ar.retPath%>assets/google/css/PT_Sans-Web.css" rel="stylesheet"/>

    <link href="<%=ar.retPath%>bits/fixed-sidebar.min.css" rel="styleSheet" type="text/css" media="screen" />
    <!-- Weaver specific tweaks -->    
    <!-- Bootstrap 5.0-->
    <link rel="stylesheet" href="<%=ar.retPath%>css/bootstrap.min.css" />
    <link rel="stylesheet" href="<%=ar.retPath%>css/weaver.min.css" />

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap', 'ngSanitize']);
app.controller('myCtrl', function($scope, $http, $modal) {
    
    
});

function reloadIfLoggedIn() {
    if (SLAP.loginInfo.verified) {
        window.location = "<%= ar.getCompleteURL() %>";
    }
}
</script>

</head>

<body>
  <div class="bodyWrapper"  style="margin:50px">

<style>
.fieldName {
    max-width:150px;
}
</style>  

<%@ include file="AnonNavBar.jsp" %>
  
    <div ng-app="myApp" ng-controller="myCtrl">

        <div class="page-name">
            <h1 id="mainPageTitle">Administrators Page</h1>
        </div>

        <div class="guideVocal">
        You have attempted to access a site administration function, but you are 
        not logged in.   Please login to continue.
        </div>

    </div>
  </div>

<%@ include file="WhatIsWeaver.jsp" %>  
  
  </body>
</html>





