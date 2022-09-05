<%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@ include file="/spring/jsp/include.jsp"
%><%
    String property_msg_key = ar.reqParam("property_msg_key");
    String warningMessage = property_msg_key;
    if (property_msg_key.startsWith("nugen")) {
        warningMessage = ar.getMessageFromPropertyFile(property_msg_key, new Object[0]);
    }

%>
<!-- jsp/Warning.jsp -->
<script>
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Weaver Access Control");
    $scope.notLoggedIn = <%=ar.isLoggedIn()==false%>;
    $scope.newEmail = "";
    $scope.sentEmail = "";
    $scope.warningMessage = "<% ar.writeJS(warningMessage); %>"
    
    $scope.sendConfirmEmail = function() {
        console.log("attempting to send email to: "+$scope.newEmail);
        var message = {};
        message.userId = $scope.newEmail;
        message.msg = "This is the email confirmation message that you requested from Weaver.  Use the link below to set (or reset) your password in order to access Weaver";
        message.return = "<%=ar.getCompleteURL()%>"
        message.subject = "Your Weaver Email Confirmation Message";
        
        SLAP.sendInvitationEmail(message, function(data) {
            console.log("Confirm email sent");
            $scope.sentEmail = message.userId;
            $scope.$apply();
        }, function(data) {
            console.log("Confirm email was not sent", data);
        });
    }
});
</script>

<style>
.guideVocal {
    font-size:20px;
    font-weight:300;
}
</style>

<div>

    <div class="guideVocal">
        <div ng-bind-html="warningMessage"></div>
    </div>
    
    <div ng-show="notLoggedIn" style="margin:50px;max-width:600px">
      <div class="panel panel-default">
        <div class="panel-heading" ng-click="showEmail=true">
          Don't have a login?  
          <span ng-hide="showEmail" > (Click here) </span></div>
        <div class="panel-body" ng-show="showEmail">
          <p>Would you like to register for access to Weaver?  It is quick, easy, and free.</p>
          <p><input type="email" ng-model="newEmail" class="form-control" placeholder="Enter your email address"/></p>
          <p><button class="btn btn-primary btn-raised"/ ng_click="sendConfirmEmail()">
             Send Confirmation Email</button></p>
          <p>Just enter your email address, request a confirmation email.  That email will contain a link to set (or reset) your password and your name.</p>
          <p ng-show="sentEmail">OK, email has been sent to <b>{{sentEmail}}</b>.  Look for it in your inbox and set your password.<p>
        </div>
      </div>
    </div>

</div>
