<%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@ include file="/spring/jsp/include.jsp"
%><%
    String property_msg_key = ar.reqParam("property_msg_key");
    String warningMessage = property_msg_key;
    if (property_msg_key.startsWith("nugen")) {
        warningMessage = ar.getMessageFromPropertyFile(property_msg_key, new Object[0]);
    }
    NGWorkspace ngw =null;
    NGBook ngb = null;
    Cognoscenti cog = ar.getCogInstance();
    String pageId = (String)request.getAttribute("pageId");
    String siteId = (String)request.getAttribute("siteId");
    if (pageId!=null) {
        ngw = ar.getCogInstance().getWSBySiteAndKey(siteId, pageId).getWorkspace();
        if (ngw!=null) {
            ngb = ngw.getSite();
        }
    }
    else if (siteId!=null) {
        ngb = cog.getSiteById(siteId);
    }

%>
<!-- NoAccess.jsp -->
<script>
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Welcome to Weaver");
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
    $scope.login = function() {
        SLAP.loginUserRedirect();
    }
    
});
</script>

<div>
<%@include file="ErrorPanel.jsp"%> 

<div class="col col-lg-6 col-md-6 col-sm-12">

    <p>Welcome!  You have accessed a link and you are not logged in.</p>
    
    <div ng-bind-html="warningMessage"></div>
    
    <p>If you have registered a user, then please
    <button class="btn btn-primary btn-raised" ng-Click="login()">Login</button></p>
    
    <hr/>
    
    <p>Weaver is an online collaboration tool based on Dynamic Governance 
    to help teams of people work together better.  
    Weaver makes it easy to share information, to track tasks, and to run meetings to get things done.</p>
    
    <%if (ngw!=null) { %>
    <p>You are attempting to access a workspace named "<b><%ar.writeHtml(ngw.getFullName());%></b>" 
    in the site named "<b><%ar.writeHtml(ngb.getFullName());%></b>.  </p>
    <% } else if (ngb!=null) { %>
    <p>You are attempting to access a site named "<b><%ar.writeHtml(ngb.getFullName());%></b>.</p>
    <% } %>
    
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

<div class="col col-lg-6 col-md-6  col-sm-12">

    <p>Weaver makes it easy to share documents and to track work.</p>
    
    <div class="centerIcon"><img src="../../../bits/workspace.png"/></div>
    <p><b>Workspaces</b> - The workspace is a place where a specified set of people -- also known as a circle in Dynamic Governance terminology -- can place documents, tasks, discussions, meetings, and decisions.  Think of it as a storage cabinet that only members of that circle can get into.  But workspaces also allow you to share in a safe way information with people outside the circle.</p>
    
    <div class="centerIcon"><img src="../../../bits/safety-icon.png"/></div>
    <p><b>Security</b> - Weaver uses secure protocols so that your information remains safe and protected.
    You can make it available to anyone you designate, and tracks who accesses it.  
    All the documents for a circle of people are here in one place, together.</p>
    
    <div class="centerIcon"><img src="../../../bits/meeting-icon.png"/></div>
    <p><b>Meetings</b> - Prepare for, run, and record the results of meetings.  Automatically collect and track
    presentations, handouts, notes, minutes, and timings.  Send announcements, help decide the time for a meeting, and record attendance.  All of this collected on one place available to all circle members.</p>
    
    


</div>

</div>