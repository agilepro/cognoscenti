<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    if (!Cognoscenti.getInstance(request).isInitialized()) {
        String go = ar.getCompleteURL();
        String configDest = ar.retPath + "init/config.htm?go="+URLEncoder.encode(go);
        response.sendRedirect(configDest);
    }

%>


<!DOCTYPE html>
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

<!-- index.jsp -->
<script>
var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {

    $scope.login = function() {
        SLAP.loginUserRedirect();
    }
    $scope.createNewSite = function() {
        window.location = "NewSiteApplication.htm";
    }
});


function reloadIfLoggedIn() {
    if (SLAP.loginInfo.verified) {
        window.location = "..";
    }
}
</script>

<style>
.mainQuote {
    margin: auto;
    max-width:440px;
    padding:0px;
    font-size:28px;
    font-style: italic;
    font-family:"PT_Sans"
}
</style>

</head>

<body>
  <div class="bodyWrapper"  style="margin:50px">

<%@ include file="AnonNavBar.jsp" %>

<div ng-app="myApp" ng-controller="myCtrl">

    <div>
        If you already have an account, please
        <button class="btn btn-primary btn-raised" ng-click="login()">
            Login
        </button>
    </div>

    <hr/>
    <div class="mainQuote">
        <p>
            Let us bring you to agreement!&#8482;
        </p>
    </div>
    <hr/>

    <h1>What is Weaver?</h1>
    <p>
        Weaver is a platform to help organizations large and small to reach their goals.
        It helps you organize people to produce results.
        It helps you prepare for meetings, distribute information, collect input, run meetings,
        write minutes, and to clearly share decisions that are made.
    </p>
    <p>
        Weaver is based on a proven methodology for helping people come together and reach agreement
        known as Dynamic Governance or Sociocracy.  This approach is an <i>inclusive</i> approach that
        helps to assure that everyone's voice is heard, and everyone is involved in making the decisions.
        By keeping people involved in the decisions, you keep them involved in the follow through as well.
        Whether you are running a community organization, a non-profit, a school group, a government agency,
        a small business or a large busines, Weaver you will give a greater ability to produce high
        quality results with a team.
    </p>
    <h1>How can you get Weaver?</h1>
    <p>
        Weaver is free at the basic level, which includes meeting planning, document sharing,
        discussion lists, action / task lists, role based access, decision list, email notifications
        and much more.
    </p>
    <p>
        With a few keystrokes you make a workspace which can be accessed from anywhere,
        but only the people you designate.
        Action items can be assigned to anyone with an email address,
        and automatic email notification keeps everyone informed.
        It is quick and easy to sign up for a free site.
    </p>
    <p>
        <button class="btn btn-primary btn-raised" ng-click="createNewSite()">Request A Site</button>
    </p>

</div>


</div>

</body>
</html>
