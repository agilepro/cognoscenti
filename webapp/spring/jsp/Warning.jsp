<%@page import="org.socialbiz.cog.NGRole"
%><%@ include file="/spring/jsp/include.jsp"
%><%
    String property_msg_key = ar.reqParam("property_msg_key");
    String warningMessage = property_msg_key;
    if (property_msg_key.startsWith("nugen")) {
        warningMessage = ar.getMessageFromPropertyFile(property_msg_key, new Object[0]);
    }

%>
<!-- Warning.jsp -->
<script>
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Weaver Access Control");
    $scope.warningMessage = "<% ar.writeJS(warningMessage); %>"
});
</script>

<div ng-app="myApp" ng-controller="myCtrl">

    <div class="guideVocal">
        {{warningMessage}}
    </div>

</div>
