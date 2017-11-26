<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.SharePortRecord"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of a workspace and here it is used to retrieve NGPage.

*/

    String id      = ar.reqParam("id");
    String pageId  = ar.reqParam("pageId");
    String siteId  = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);

    JSONArray allLabels = ngw.getJSONLabels();
    SharePortRecord spr = ngw.findSharePortOrFail(id);
    JSONObject sharePort = spr.getFullJSON(ngw);
    
    long startTime = sharePort.getLong("startTime");
    long days = sharePort.getInt("days");
    long endTime = startTime + (days * 24L * 60L * 60L * 1000L);
    boolean isActive = true;
    if (sharePort.has("isActive")) {
        isActive = sharePort.getBoolean("isActive");
    }
    
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
    <link href="<%=ar.baseURL%>jscript/ng-tags-input.css" rel="stylesheet">
    <script src="<%=ar.baseURL%>jscript/bootstrap-material-design/ripples.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/bootstrap-material-design/material.min.js"></script>
    <link rel="stylesheet" href="<%=ar.baseURL%>css/bootstrap-material-design/bootstrap-material-design.min.css" media="screen">
    <link rel="stylesheet" href="<%=ar.baseURL%>css/bootstrap-material-design/ripples.min.css" media="screen">

	<!-- INCLUDE web fonts -->
    <link href="<%=ar.retPath%>assets/font-awesome/css/font-awesome.min.css" rel="stylesheet"
          data-semver="4.3.0" data-require="font-awesome@*" />
	  <link href="<%=ar.retPath%>assets/google/css/PT_Sans-Web.css" rel="stylesheet"/>

    <link href="<%=ar.retPath%>bits/fixed-sidebar.min.css" rel="styleSheet" type="text/css" media="screen" />
    <!-- Weaver specific tweaks -->
    <link href="<%=ar.retPath%>bits/main.min.css" rel="styleSheet" type="text/css" media="screen" />

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http, $modal) {
    $scope.sharePort = <%sharePort.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.nowTime = new Date().getTime();
    
    $scope.acessDocument = function (doc) {
        if (doc.attType=="URL") {
            window.open(doc.url,'_blank');
        }
        else {
            window.location = "../a/"+encodeURI(doc.name)+"?"+doc.access;
        }
    }
    
});
</script>

</head>

<body>
  <div class="bodyWrapper"  style="margin:50px">

  
  
    <nav class="navbar navbar-default appbar">
      <div class="container-fluid">

      
<style>
.tighten li a {
    padding: 0px 5px !important;
    background-color: white;
}
.tighten li {
    background-color: white;
}
.tighten {
    padding: 5px !important;
    border: 5px #F0D7F7 solid !important;
    max-width:300px;
    background-color: white !important;
}
</style>


        <!-- Logo Brand -->
        <a class="navbar-brand" href="<%=ar.retPath%>" title="Weaver Home Page">
          <img class="hidden-xs" alt="Weaver Icon" src="<%=ar.retPath%>bits/header-icon.png">
          <h1>Weaver</h1>
        </a>


      </div>
    </nav>
  
    <div ng-app="myApp" ng-controller="myCtrl">

        <div class="page-name">
            <h1 id="mainPageTitle">{{sharePort.name}}</h1>
        </div>

        <div ng-show="sharePort.isActive && sharePort.endTime>nowTime">
            <p>{{sharePort.message}}</p>
            
            <div style="margin:40px"> </div>
            
            <table class="table">
            <col width="50">
            <tr>
               <th></th>
               <th>Name</th>
               <th>Updated</th>
               <th style="text-align:right">Size</th>
            </tr>
            <tr ng-repeat="rec in sharePort.docs" ng-click="acessDocument(rec)" style="cursor:pointer">
               <td ng-hide="rec.url" >
                 <span class="fa fa-download"></scan></td>
               <td ng-show="rec.url" >
                 <span class="fa fa-external-link"></scan></td>
               <td><b>{{rec.name}}</b> ~ {{rec.description}}</td>
               <td>{{rec.modifiedtime|date}}</td>
               <td ng-show="rec.size>=0" style="text-align:right">{{rec.size|number}}</td>
               <td ng-hide="rec.size>=0" style="text-align:right;color:lightgray">Web Link</td>
            </tr>
            <tr><td></td><td></td><td></td></tr>
            </table>

            <div ng-show="sharePort.docs.length==0" class="guideVocal">
               There are no documents that match the filter criteria at this time.
            </div>
            
            <p ng-show="sharePort.days>0">
               This sharing page will be available until {{sharePort.endTime|date}}.
            </p>
        </div>
        
       <div ng-show="sharePort.isActive && sharePort.endTime<=nowTime">
       
            <div ng-show="sharePort.docs.length==0" class="guideVocal">
               This is no longer available since {{sharePort.endTime|date}}.
            </div>
       
       </div>
        
       <div ng-show="!sharePort.isActive">
       
            <div ng-show="sharePort.docs.length==0" class="guideVocal">
               This sharing page has been disabled by the user and is no longer available.
            </div>
       
       </div>
        
    </div>
  </div>
</body>
</html>





