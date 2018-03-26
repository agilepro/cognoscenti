<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.SharePortRecord"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%@ include file="/spring/jsp/include.jsp"
%><%

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
    <script src="<%=ar.baseURL%>jscript/ng-tags-input.js"></script>
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

var app = angular.module('myApp', ['ui.bootstrap', 'ui.tinymce', 'ngSanitize', 'ngTagsInput']);
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {

    $scope.newWorkspace = {newName:"",template:"",purpose:"",members:[]};
    
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        console.log("Error: "+serverErr);
        errorPanelHandler($scope, serverErr);
    };

    $scope.getURLAddress = function() {
        var res = "";
        var str = $scope.newWorkspace.newName;
        var isInGap = false;
        for (i=0; i<str.length && res.length<8; i++) {
            var ch = str[i].toLowerCase();
            var isAddable = ( (ch>='a' && ch<='z') || (ch>='0' && ch<='9') );
            if (isAddable) {
                if (isInGap) {
                    res = res + "-";
                    isInGap = false;
                }
                res = res + ch;
            }
            else {
                isInGap = res.length > 0;
            }
        }
        return res;
    }
    $scope.loadPersonList = function(query) {
        console.log("loadPersonList called")
        return AllPeople.findMatchingPeople(query);
    }
    
});

function reloadIfLoggedIn() {
    //stay on this page whether logged in or not.
}
</script>
<script src="<%=ar.baseURL%>jscript/AllPeople.js"></script>

</head>

<body>
  <div class="bodyWrapper"  style="margin:50px">


<style>
.spacey tr td {
    padding: 5px 10px;
}
</style>


<%@ include file="AnonNavBar.jsp" %>

<div style="max-width:500px" ng-app="myApp" ng-controller="myCtrl">

    <div class="form-group">
        <label ng-click="showNameHelp=!showNameHelp">
            New Site Name &nbsp; <i class="fa fa-question-circle-o"></i>
        </label>
        <input type="text" class="form-control" ng-model="newWorkspace.newName"/>
    </div>
    <div class="form-group">
        <label>
            URL Address:  
        </label>
        {{getURLAddress()}}
    </div>
    <div class="guideVocal" ng-show="showNameHelp" ng-click="showNameHelp=!showNameHelp">
        Pick a short clear name that would be useful to people that don't already know
        about the group using the site.  You can change the name at any time, 
        however the first name you pick will set the URL address and that can not be 
        changed later.
    </div>
    <div class="form-group">
        <label ng-click="showPurposeHelp=!showPurposeHelp">
            Site Purpose &nbsp; <i class="fa fa-question-circle-o"></i>
        </label>
        <textarea class="form-control" ng-model="newWorkspace.purpose"></textarea>
    </div>
    <div class="guideVocal" ng-show="showPurposeHelp" ng-click="showPurposeHelp=!showPurposeHelp">
        Describe in a sentence or two the <b>purpose</b> of the workspace in a way that 
        people who are not (yet) part of the workspace will understand,
        and to help them know whether they should or should not be 
        part of that workspace. <br/>
        This description will be available to the public if the workspace
        ever appears in a public list of workspaces.
    </div>
    <div class="form-group">
        <label ng-click="showMembersHelp=!showMembersHelp">
            Initial Members &nbsp; <i class="fa fa-question-circle-o"></i>
        </label>
        <tags-input ng-model="newWorkspace.members" 
                    placeholder="Enter email/name of members for this workspace"
                    display-property="name" key-property="uid">
            <auto-complete source="loadPersonList($query)"></auto-complete>
        </tags-input>
    </div>
    <div class="guideVocal" ng-show="showMembersHelp" ng-click="showMembersHelp=!showMembersHelp">
        Members are allowed to access the workspace.  
        You can enter their email address if they have not accessed the system before. 
        If not novices, type three letters to get a list of known users that match.  
        Later, you can add and remove members whenever needed.<br/>
        <br/>
        After the workspace is created go to each <b>novice</b> user and send them an 
        invitation to join.
    </div>
    
    
    <div class="form-group">
        <button class="btn btn-primary btn-raised" ng-click="createNewWorkspace()">
            Request Site</button>
    </div>

       
</div>


  </div>
</body>
</html>





