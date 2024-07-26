<%@page errorPage="/spring2/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.SharePortRecord"
%><%@ include file="/spring2/jsp/include.jsp"
%><%

    String topicId      = ar.reqParam("topicId");
    String pageId  = ar.reqParam("pageId");
    String siteId  = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);

    JSONArray allLabels = ngw.getJSONLabels();
    TopicRecord topic = ngw.getDiscussionTopic(topicId);
    JSONObject topicObject = topic.getJSONWithMarkdown(ar, ngw);
        
%>

<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="Content-Language" content="en-us" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta http-equiv="imagetoolbar" content="no" />
    <meta name="viewport" content="user-scalable=no, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0" />

    <!-- INCLUDE the ANGULAR JS library -->
    <script src="<%=ar.baseURL%>new_assets/jscript/angular.min.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/ui-bootstrap-tpls.min.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/jquery.min.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/bootstrap.min.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/slap.js"></script>
    
    <link href="<%=ar.baseURL%>new_assets/jscript/ng-tags-input.css" rel="stylesheet">
    <script src="<%=ar.baseURL%>new_assets/jscript/textAngular-sanitize.min.js"></script>
    <!--
    <script src="<%=ar.baseURL%>jscript/bootstrap-material-design/ripples.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/bootstrap-material-design/material.min.js"></script>
    <link rel="stylesheet" href="<%=ar.baseURL%>css/bootstrap-material-design/bootstrap-material-design.min.css" media="screen">
    <link rel="stylesheet" href="<%=ar.baseURL%>css/bootstrap-material-design/ripples.min.css" media="screen">
-->
    <!-- INCLUDE web fonts -->
    <link href="<%=ar.retPath%>new_assets/assets/font-awesome/css/font-awesome.min.css" rel="stylesheet"
          data-semver="4.3.0" data-require="font-awesome@*" />
      <link href="<%=ar.retPath%>new_assets/assets/google/css/PT_Sans-Web.css" rel="stylesheet"/>

    <link href="<%=ar.retPath%>new_assets/bits/fixed-sidebar.min.css" rel="styleSheet" type="text/css" media="screen" />
    <!-- Weaver specific tweaks -->
        <!-- Bootstrap 5.0-->
        <link rel="stylesheet" href="<%=ar.retPath%>new_assets/css/bootstrap.min.css" />
        <link rel="stylesheet" href="<%=ar.retPath%>new_assets/css/weaver.min.css" />


<script src="<%=ar.retPath%>new_assets/jscript/HtmlToMarkdown.js"></script>
<script src="<%=ar.retPath%>new_assets/jscript/HtmlParser.js"></script>
<script src="<%=ar.baseURL%>new_assets/jscript/TextMerger.js"></script>
<script src="<%=ar.baseURL%>new_assets/jscript/MarkdownToHtml.js"></script>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap', 'ngSanitize']);
app.controller('myCtrl', function($scope, $http, $modal) {
    $scope.topic = <%topicObject.write(out,2,4);%>;
    $scope.topic.html2 = convertMarkdownToHtml($scope.topic.wiki);
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
            <h1 id="mainPageTitle">{{topic.subject}}</h1>
        </div>

        <div class="comment-outer">
          <div class="comment-inner">
            <div ng-bind-html="topic.html2"></div>
          </div>
        </div>

    </div>
  </div>
  
  <!--pre>
  <%
  //topicObject.write(out,2,4);
  %>
  </pre-->
</body>
</html>



