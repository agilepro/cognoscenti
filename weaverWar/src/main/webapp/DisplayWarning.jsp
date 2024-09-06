<!DOCTYPE html>
<%@ include file="/spring/jsp/include.jsp"
%><%

    if (!Cognoscenti.getInstance(request).isInitialized()) {
        String go = ar.getCompleteURL();
        String configDest = ar.retPath + "init/config.htm?go="+URLEncoder.encode(go);
        response.sendRedirect(configDest);
    }
    String property_msg_key = ar.defParam("property_msg_key", "Warning message is unspecified.");
    String warningMessage = property_msg_key;
    if (property_msg_key.startsWith("nugen")) {
        warningMessage = ar.getMessageFromPropertyFile(property_msg_key, new Object[0]);
    }
    UserProfile user = ar.getUserProfile();
    

%>
<html>
<head>
    <link rel="shortcut icon" href="http://localhost:8080/weaver/bits/favicon.ico" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="Content-Language" content="en-us" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta http-equiv="imagetoolbar" content="no" />
    <meta name="viewport" content="user-scalable=no, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0" />
    <!-- INCLUDE the ANGULAR JS library -->
    <script src="http://localhost:8080/weaver/new_assets/jscript/angular.js"></script>
    <script src="http://localhost:8080/weaver/new_assets/jscript/angular-translate.js"></script>
    <script src="http://localhost:8080/weaver/new_assets/jscript/ui-bootstrap-tpls.min.js"></script>
    <script src="http://localhost:8080/weaver/new_assets/jscript/jquery-3.6.0.min.js"></script>
    <script src="http://localhost:8080/weaver/new_assets/jscript/bootstrap.min.js"></script>
    <script src="http://localhost:8080/weaver/new_assets/jscript/slap.js"></script>
    <link
    rel="stylesheet"
    href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"/>
    <script src="http://localhost:8080/weaver/new_assets/jscript/MarkdownToHtml.js"></script>
    <script src="http://localhost:8080/weaver/new_assets/jscript/HtmlParser.js"></script>
    <script src="http://localhost:8080/weaver/new_assets/jscript/TextMerger.js"></script>
    <script src="http://localhost:8080/weaver/new_assets/jscript/HtmlToMarkdown.js"></script>

    <link href="http://localhost:8080/weaver/new_assets/jscript/ng-tags-input.css" rel="stylesheet">

    <!-- INCLUDE web fonts for icons-->
    <link href="http://localhost:8080/weaver/new_assets/assets/font-awesome/css/font-awesome.min.css" rel="stylesheet"
          data-semver="4.3.0" data-require="font-awesome@*" />
      <link href="http://localhost:8080/weaver/new_assets/assets/google/css/PT_Sans-Web.css" rel="stylesheet"/>


    <!-- Bootstrap 5.0-->
    <link rel="stylesheet" href="http://localhost:8080/weaver/new_assets/css/bootstrap.min.css" />
    <link rel="stylesheet" href="http://localhost:8080/weaver/new_assets/css/weaver.min.css" />

 
    <title>Display Error</title>


<!-- anon/Warning.jsp -->
<script>
var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http, $modal) {
    $scope.warningMessage = "<% ar.writeJS(warningMessage); %>"
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
.guideVocal {
    font-size:20px;
    font-weight:300;
}
.main-content {
    max-width: 800px;
    padding: 50px;
    margin: 50px;
}
.header-column {
    width: 100px;
}

</style>
</head>
<body ng-app="myApp" ng-controller="myCtrl">
  <div class="bodyWrapper">

<nav class="navbar navbar-expand-lg navbar-dark bg-primary py-0">
<div class="container-fluid">

          <!-- toggle button for mobile nav -->
          <button
            class="navbar-toggler"
            type="button"
            data-bs-toggle="collapse"
            data-bs-target="#navbarNavDropdown"
            aria-controls="navbarNavDropdown"
            aria-expanded="false"
            aria-label="Toggle navigation"
          >
            <span class="navbar-toggler-icon"></span>
          </button>

          <!-- end toggle button for mobile nav -->


  <!-- Logo Brand -->
  <a class="navbar-brand py-2" href="http://localhost:8080/weaver/v/OBIEZWJFH/UserHome.htm" title="Access your overall personal Weaver Home Page">
    <span class="fw-semibold fs-1 vertical-align-middle">
      <img class="d-inline-flex m-2" alt="Weaver Logo" src="http://localhost:8080/weaver/new_assets/bits/header-icon.png">
    Weaver</span>
  </a>

                <!-- Search Bar -->
                <div class="row search">
                  <form class="d-flex" role="search" action="searchAllNotes.htm">
                    <div class="form-group specialweaver is-empty">
                      <input type="text" class="form-control me-2 " name="s" placeholder=" &#xF002; Search" style="font-family:Arial, FontAwesome">
                    </div>
                    </form>
                  </div>
        
                  
                  <!-- end Search Bar -->


  <!-- Drop Down Workspaces -->
  <div class="collapse navbar-collapse" id="topbar-nav">

      
      
      
      
  <ul class="navbar-nav">
      <li class="nav-item dropdown">
            <a href="#" 
            class="nav-link dropdown-toggle text-weaverbody"
            id="navbarWorkspaceDropdown" 
            role="button" 
            data-bs-toggle="dropdown-toggle-label ng-scope" aria-expanded="false">
              <i class="fa fa-circle-o" aria-hidden="true"></i>
              <span class="dropdown-toggle-label" translate>Workspaces</span>
            </a>
            <ul class="dropdown-menu" aria-labelledby="navbarWorkspaceDropdown">
              <span class="dropdown-item">

</span>
            <li><hr class="dropdown-divider"></li> 
          
            <li><a class="dropdown-item" href="http://localhost:8080/weaver/v/OBIEZWJFH/WatchedProjects.htm">Watched Workspaces</a></li>
            <li><a class="dropdown-item" href="http://localhost:8080/weaver/v/OBIEZWJFH/templates.htm">Templates</a></li>
            <li><a class="dropdown-item"  href="http://localhost:8080/weaver/v/OBIEZWJFH/OwnerProjects.htm">Administered</a></li>
            <li><a class="dropdown-item"  href="http://localhost:8080/weaver/v/OBIEZWJFH/ParticipantProjects.htm">Participant</a></li>
            <li><a class="dropdown-item" href="http://localhost:8080/weaver/v/OBIEZWJFH/AllProjects.htm">All</a></li>
          </ul>
        </li>

  
        
    
        <!-- Drop Down User -->
        <li class="nav-item dropdown">
          <a class="nav-link dropdown-toggle text-weaverbody"
          role="button"
          data-target="#"
          data-toggle="dropdown"
          aria-expanded="false"
          title="User: Keith ♘ Swenson">
            <i class="fa fa-user" aria-hidden="true"></i>
            <span class="dropdown-toggle-label">
              Keith ♘ Swenson
            </span>
          </a>
          <ul class="dropdown-menu bg-weaverbody text-weaverdark">
            <li><a class="dropdown-item" href="http://localhost:8080/weaver/v/OBIEZWJFH/UserHome.htm">Home</a></li>
            <li><a class="dropdown-item" href="http://localhost:8080/weaver/v/OBIEZWJFH/UserSettings.htm">Profile</a></li>
            <li><a class="dropdown-item" href="http://localhost:8080/weaver/v/OBIEZWJFH/UserAlerts.htm">Updates</a></li>
            <li><a class="dropdown-item" href="http://localhost:8080/weaver/v/OBIEZWJFH/NotificationSettings.htm">Notifications</a></li>
            <li><a class="dropdown-item" href="https://s06.circleweaver.com/TutorialList.html" target="_blank">Training</a></li>

            <li class="divider"></li>
            <li><a class="dropdown-item" onclick='logOutPage();'>Log Out</a></li>
 
          </ul>
        </li>
      </ul>
      <!-- END App Bar -->
      <!-- BEGIN Input Search -->
      <div class="search navbar-left collapse">
        <form class="navbar-form" role="search" action="searchAllNotes.htm">
          <div class="form-group specialweaver is-empty">
            <input type="text" class="form-control specialweaver" name="s" placeholder="Search">
          </div>
        </form>
      </div>
      <!-- END Input Search -->
    </div>
</nav>

<div class="container-fluid px-0">
  <div class="row">

    <!-- Begin SideBar  -->
    <div class="d-flex">
      <!-- BEGIN SideBar.jsp -->



<!-- Side Bar -->
<nav class="sidebar bg-primary">
  <div class="container-fluid min-vh-100 sidebar bg-primary">
    <ul class="sidebar-nav list-unstyled py-2">
    
    <li class="my-5 text-weaverbody">  
        <img src="http://localhost:8080/weaver/new_assets/assets/Site-Writable.png" title="You have full edit access to this workspace" 
    class="accessIndicator"/>
    </li>
    
    </ul>
  </div>
  
</nav>

<div class="main-content">
    
    <h2>Weaver encountered a problem . . . please read</h2>
    
    <div class="warningBox">
        <table class="table">
          <tr>
            <td class="header-column">
              Error:
            </td>
            <td>
            {{warningMessage}}
            </td>
          </tr>
          <tr>
            <td class="header-column">
              Site:
            </td>
            <td>
                <b>Sociocracy</b>
            </td>
          </tr>
          <tr>
            <td class="header-column">
                Run By: 
            </td>
            <td>
                <% if (ar.ngp != null) {
                   NGRole admins = ar.ngp.getSecondaryRole(); 
                   boolean needsComma = false;
                   for (AddressListEntry player : admins.getExpandedPlayers(ar.ngp)) {
                       if (needsComma) {
                           ar.write(", ");
                       }
                       ar.write("<span>");
                       player.writeLink(ar);
                       ar.write("</span>");
                       needsComma = true;
                   }
                }
                %>
            </td>
          </tr>
        </table> 
    </div>


<div class="main-content">
</div>


<% if (ar.isLoggedIn()) {  %>
    <div>
        <p>You are currently logged in as <%=user.getName()%> (<%=user.getUniversalId()%>).</p>
        <p>If that is the wrong user account, you can logout and login with the correct one.</p>
        <button class="btn btn-primary btn-raised" ng-click="logout()">
            Logout
        </button>
        
    </div>
    
<% } else { %>
    <div>
        If you already have an account, please
        <button class="btn btn-primary btn-raised" ng-click="login()">
            Login
        </button>
        to find out more.
    </div>
<% } %>


    <hr/>
    <div class="mainQuote">
        <p>
            Let us bring you to agreement!&#8482;
        </p>
    </div>
    <hr/>

  <div>
    
<% if (!ar.isLoggedIn()) { %>
    <div>
        No account?  Please
        <button class="btn btn-primary btn-raised" ng-click="login()">
            Register
        </button> 
        to get one.
    </div>
<% } %>
  </div>
  </div>
</div>
</div>
</body>
</html>




