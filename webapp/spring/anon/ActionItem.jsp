<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.SharePortRecord"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    String taskId      = ar.reqParam("taskId");
    String pageId  = ar.reqParam("pageId");
    String siteId  = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);

    JSONArray allLabels = ngw.getJSONLabels();
    GoalRecord actionItem = ngw.getGoalOrFail(taskId);
    JSONObject actionItemObj = actionItem.getJSON4Goal(ngw);

    JSONObject stateName = new JSONObject();
    stateName.put("0", BaseRecord.stateName(0));
    stateName.put("1", BaseRecord.stateName(1));
    stateName.put("2", BaseRecord.stateName(2));
    stateName.put("3", BaseRecord.stateName(3));
    stateName.put("4", BaseRecord.stateName(4));
    stateName.put("5", BaseRecord.stateName(5));
    stateName.put("6", BaseRecord.stateName(6));
    stateName.put("7", BaseRecord.stateName(7));
    stateName.put("8", BaseRecord.stateName(8));
    stateName.put("9", BaseRecord.stateName(9));
    
    JSONObject cUser = new JSONObject();
    if (ar.isLoggedIn()) {
        cUser = ar.getUserProfile().getJSON();
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
    <script src="<%=ar.baseURL%>jscript/textAngular-sanitize.min.js"></script>
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

var app = angular.module('myApp', ['ui.bootstrap', 'ngSanitize']);
app.controller('myCtrl', function($scope, $http, $modal) {
    $scope.actionItem = <%actionItemObj.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.nowTime = new Date().getTime();
    $scope.stateName = <%stateName.write(out,2,4);%>;
    $scope.cUser = <%cUser.write(out,2,4);%>;
    
    $scope.acessDocument = function (doc) {
        if (doc.attType=="URL") {
            window.open(doc.url,'_blank');
        }
        else {
            window.location = "../a/"+encodeURI(doc.name)+"?"+doc.access;
        }
    }
    
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
            <h1 id="mainPageTitle">Action Item</h1>
        </div>

        <table class="table">
        <tr><td class="fieldName">Synopsis</td><td>{{actionItem.synopsis}}</td></tr>
        <tr><td class="fieldName">Description</td><td>{{actionItem.description}}</td></tr>
        <tr><td class="fieldName">State</td><td><img src="<%=ar.retPath%>assets/goalstate/small{{actionItem.state}}.gif">
            {{stateName[actionItem.state]}}</td></tr>
        <tr><td class="fieldName">Assigned</td><td>
            <div ng-repeat="person in actionItem.assignTo">{{person.name}}</div></td></tr>
        <tr ng-show="actionItem.duedate>100000">
            <td class="fieldName">Due Date</td><td>{{actionItem.duedate|date}}</td></tr>
        <tr ng-show="actionItem.startdate>100000">
            <td class="fieldName">Start Date</td><td>{{actionItem.startdate|date}}</td></tr>
        <tr ng-show="actionItem.enddate>100000">
            <td class="fieldName">End Date</td><td>{{actionItem.enddate|date}}</td></tr>
        <tr><td class="fieldName">Workspace</td><td>{{actionItem.sitename}} / {{actionItem.projectname}}</td></tr>
        <tr ng-show="actionItem.duedate>100000">
            <td class="fieldName">Last Updated</td><td>{{actionItem.modifiedtime|date}}</td></tr>
        <tr><td class="fieldName">You</td><td>{{cUser.name}}</td></tr>
        </table>

    </div>
  </div>
</body>
</html>





