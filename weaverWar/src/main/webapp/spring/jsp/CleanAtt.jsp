<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
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
app.controller('myCtrl', function($scope, $http) {
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


<div>

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
