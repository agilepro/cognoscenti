<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    if (!Cognoscenti.getInstance(request).isInitialized()) {
        String go = ar.getCompleteURL();
        String configDest = ar.retPath + "init/config.htm?go="+URLEncoder.encode(go);
        response.sendRedirect(configDest);
    }
    String property_msg_key = ar.reqParam("property_msg_key");
    String warningMessage = property_msg_key;
    if (property_msg_key.startsWith("nugen")) {
        warningMessage = ar.getMessageFromPropertyFile(property_msg_key, new Object[0]);
    }
    UserProfile user = ar.getUserProfile();
    

%>


<!-- anon/Warning.jsp -->
<script>
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    $scope.warningMessage = "<% ar.writeJS(warningMessage); %>"
    setMainPageTitle("Weaver Warning");
    $scope.login = function() {
        SLAP.loginUserRedirect();
    }
    $scope.logout = function() {
        SLAP.displayLoginStatus = function(data) {
            window.location.reload();
            SLAP.displayLoginStatus = function () {};
        }
        SLAP.logoutUser();
    }
    $scope.createNewSite = function() {
        window.location = "../../NewSiteApplication.htm";
    }
});


function reloadIfLoggedIn() {
    //don't do anything if logged in, this is a warning message regardless of login status
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


<div ng-app="myApp" ng-controller="myCtrl" style="margin:50px">

    <div ng-bind-html="warningMessage"></div>

<% if (ar.isLoggedIn()) {  %>
    <div>
        You are currently logged in as <%=user.getName()%> (<%=user.getUniversalId()%>).
        If that is the wrong user account, you can 
        <button class="btn btn-primary btn-raised" ng-click="logout()">
            Logout
        </button>
        and login with the correct one.
    </div>
    
<% } else { %>
    <div>
        If you already have an account, please
        <button class="btn btn-primary btn-raised" ng-click="login()">
            Login
        </button>
    </div>
<% } %>


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
    
<% if (!ar.isLoggedIn()) { %>
    <div>
        If you don't yet have an account, please
        <button class="btn btn-primary btn-raised" ng-click="login()">
            Register
        </button> 
        a new account.
    </div>
<% } %>
    
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
    <h1>How can you Help?</h1>
    <p>
        Weaver is 100% supported by volunteers, and is structured as a cooperative.  Want to help?
        There are many ways you could contribute to Weaver beyond using it.
        Donations are appreciated for helping to run the server.  
        We could use additional training videos showing how to effectively get things done.
        If you understand AngularJS Ui framework, you could help enhance the 
        open source Weaver project by improving the user interface to meet more needs.
        Or -- at the very least -- tell all your friends about Weaver!
    </p>

</div>




