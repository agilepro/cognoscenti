<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.capture.CapturePage"
%><%@page import="com.purplehillsbooks.streams.NullWriter"
%><%
    ar.assertLoggedIn("You need to Login to Upload a file.");
    String path = ar.reqParam("path");
    
    Writer wr = new NullWriter();
    CapturePage cp = CapturePage.consumeWebPage(wr, path, ar.getRequestURL());
        
%>

<script>
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Web Page - Text Only");
    $scope.originalUrl = "<% ar.writeJS(path); %>";

    $scope.openOriginal = function() {
        window.location = $scope.originalUrl;
    }
    $scope.attachPage = function() {
        alert("Attach page to workspace not implemented yet.");
    }    
});
</script>
<style>
.cleanedWebStyle {
    max-width: 600px;
}
.cleanTitleBox{
    border:2px gray solid;
    border-radius:5px;
    margin:0px;
    padding:8px
}

</style>


<div class="container-fluid override mb-4 mx-3 d-inline-flex">
    <span class="dropdown mt-1">
        <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
            data-bs-toggle="dropdown" aria-expanded="false">
        </button>
        <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
            <li>
                <button class="dropdown-item" onclick="window.location.reload(true)">
                    Refresh</button>
            </li>
        </ul>
    </span>
    <span>
        <h1 class="d-inline page-name" id="mainPageTitle">Web Page - Text Only</h1>
    </span>
</div>
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

    <div class="cleanedWebStyle">
    
        <div class="cleanTitleBox">
          <span class="dropdown">
            <button class="dropdown-toggle specCaretBtn" type="button"  d="menu"
                data-toggle="dropdown"> <span class="caret"></span> </button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
              <li role="presentation"><a role="menuitem"
                  ng-click="openOriginal()">Open Original Web Page</a></li>
              <li role="presentation"><a role="menuitem"
                  ng-click="attachPage()">Attach This Page</a></li>
              <li role="presentation"><a role="menuitem"
                  href="CleanDebug.htm?path={{originalUrl}}">Debug View</a></li>
            </ul>
          </span>
          {{originalUrl}}
        </div>

        <% cp.produceHtml(ar.w); %>
        
    </div>

</div>
<!-- end addDocument.jsp -->
