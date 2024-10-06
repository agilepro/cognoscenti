<!DOCTYPE html>
<%@ include file="/include.jsp"
%><%
    if (!Cognoscenti.getInstance(request).isInitialized()) {
        String go = ar.getCompleteURL();
        String configDest = ar.retPath + "init/config.htm?go="+URLEncoder.encode(go);
        response.sendRedirect(configDest);
    }
    String property_msg_key = ar.defParam("property_msg_key", "Warning message is unspecified.");
    String[] warningMessage = property_msg_key.split("\n");
    UserProfile loggedUser = ar.getUserProfile();
    boolean isLoggedIn = ar.isLoggedIn();
    NGBook site = null;
    NGWorkspace ws = null;
    if (ar.ngp != null) {
        if (ar.ngp instanceof NGBook) {
            site = (NGBook) ar.ngp;
        }
        else {
            ws = (NGWorkspace) ar.ngp;
            site = ws.getSite();
        }
    }
    String niceDate = SectionUtil.getDateAndTime(System.currentTimeMillis());
    
    JSONObject loginConfigSetup = new JSONObject();
    loginConfigSetup.put("providerUrl", ar.getSystemProperty("identityProvider"));
    loginConfigSetup.put("serverUrl",   ar.baseURL);
    
    JSONObject loginInfoPrefetch = new JSONObject();
    if (ar.isLoggedIn()) {
        loginInfoPrefetch.put("userId", ar.getBestUserId());
        loginInfoPrefetch.put("userName", loggedUser.getName());
        loginInfoPrefetch.put("verified", true);
        loginInfoPrefetch.put("msg", "Previously logged into server");
    }
    else {
        //use this to indicate the very first display, before the page knows anything
        loginInfoPrefetch.put("haveNotCheckedYet", true);
    }
    

%>
<html>
<head>
    <link rel="shortcut icon" href="http://localhost:8080/weaver/bits/favicon.ico" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="Content-Language" content="en-us" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta http-equiv="imagetoolbar" content="no" />
    <meta name="viewport" content="user-scalable=no, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0" />
    <!-- INCLUDE web fonts for icons-->
    <link href="http://localhost:8080/weaver/new_assets/assets/font-awesome/css/font-awesome.min.css" rel="stylesheet"
          data-semver="4.3.0" data-require="font-awesome@*" />
    <link href="http://localhost:8080/weaver/new_assets/assets/google/css/PT_Sans-Web.css" rel="stylesheet"/>


    <!-- Bootstrap 5.0-->
    <link rel="stylesheet" href="http://localhost:8080/weaver/new_assets/css/bootstrap.min.css" />
    <link rel="stylesheet" href="http://localhost:8080/weaver/new_assets/css/weaver.min.css" />


    <script src="http://localhost:8080/weaver/new_assets/jscript/ui-bootstrap-tpls.min.js"></script>
    <script src="http://localhost:8080/weaver/new_assets/jscript/jquery-3.6.0.min.js"></script>
    <script src="http://localhost:8080/weaver/new_assets/jscript/bootstrap.min.js"></script>
    <script src="http://localhost:8080/weaver/new_assets/jscript/slap.js"></script>
    <link
    rel="stylesheet"
    href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"/>

    <link href="http://localhost:8080/weaver/new_assets/jscript/ng-tags-input.css" rel="stylesheet">


 
    <title>Display Warning</title>


<!-- DisplayWarning.jsp -->
<script>

function logoutButton() {
    console.log("SLAP LOGOUT:", SLAP);
    SLAP.displayLoginStatus = function(data) {
        SLAP.displayLoginStatus = function () {};
        window.location.reload();
    }
    SLAP.logoutUser();
}

function loginButton() {
    console.log("SLAP LOGIN:", SLAP);
    SLAP.loginUserRedirect();
}

function displayWelcomeMessage() {
    console.log("SLAP:", SLAP);
    <% if (!isLoggedIn) { %>
    if (SLAP.loginInfo.verified) {
        console.log("WAS not logged in, but now logged in", SLAP.loginInfo);
        window.location.reload();
    }
    <% } %>
};

SLAP.initLogin(<% loginConfigSetup.write(out, 2, 2); %>, <% loginInfoPrefetch.write(out, 2, 2); %>, displayWelcomeMessage);
console.log("SLAP CONFIGURATION:", SLAP);

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
    font-size:24px;
    font-weight:300;
    padding: 30px;
    margin-top: 30px;
    margin-bottom: 30px;
    border: 2px solid green;
    border-radius: 20px;
    background-color: #F6FFED;
}
.innerVoice {
    padding: 20px;
}
.main-content {
    max-width: 800px;
    padding: 20px;
    margin: 20px;
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
  <a class="navbar-brand pb-2" href="http://localhost:8080/weaver/v/OBIEZWJFH/UserHome.htm" title="Access your overall personal Weaver Home Page">
    <span class="fw-semibold fs-1 vertical-align-middle">
      <img class="d-inline-block mx-2" alt="Weaver Logo" src="http://localhost:8080/weaver/new_assets/bits/header-icon.png">
    Weaver</span>
  </a>



  <!-- Drop Down Workspaces -->
  <div class="collapse navbar-collapse" id="topbar-nav">

      
      
      
      
<% if (isLoggedIn) { %>
  <ul class="navbar-nav ms-auto">
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
            <li><a class="dropdown-item" onClick='logoutButton();'>Log Out</a></li>
 
          </ul>
        </li>
      </ul>
<% } %>
      <!-- END App Bar -->
      
      
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
    
    <li class="my-5 text-weaverbody" style="width: 55px;">  
        
    </li>
    
    </ul>
  </div>
  
</nav>

<div class="main-content">
    
    <h4>Weaver has a message for you . . . please read</h4>
    
    <div class="warningBox">
        <div class="guideVocal">
        <% for (String line: warningMessage) { %>
           <div class="innerVoice"><% ar.writeHtml(line); %></div>
        <% } %>
        </div>
        <table class="table">
          <% if (ws != null) { %>
          <tr>
            <td class="header-column">
              Workspace:
            </td>
            <td>
                <% ar.writeHtml(ws.getFullName()); %>
            </td>
          </tr>
          <% } %>
          <% if (site != null) { %>
          <tr>
            <td class="header-column">
              Site:
            </td>
            <td>
                <% ar.writeHtml(site.getFullName()); %>
            </td>
          </tr>
          <% } %>
          <% if (isLoggedIn) { %>
          <tr>
            <td class="header-column">
              Login as:
            </td>
            <td>
                <% ar.writeHtml(loggedUser.getName()); %>, <% ar.writeHtml(loggedUser.getKey()); %>, <% ar.writeHtml(loggedUser.getLastLoginId()); %>
            </td>
          </tr>
          <% } %>
          <tr>
            <td class="header-column">
                Admins: 
            </td>
            <td>
                <% if (ws != null) {
                   NGRole admins = ar.ngp.getSecondaryRole(); 
                   boolean needsComma = false;
                   for (AddressListEntry player : admins.getExpandedPlayers(ws)) {
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
          <tr>
            <td class="header-column">
              When:
            </td>
            <td>
                <% ar.writeHtml(niceDate); %>
            </td>
          </tr>
          <tr>
            <td class="header-column">
              URL:
            </td>
            <td>
                <% ar.writeHtml(ar.getCompleteURL()); %>
            </td>
          </tr>
         </table> 
    </div>


<% if (ar.isLoggedIn()) {  %>
    <div>
        <p>You are currently logged in as <%=loggedUser.getName()%> (<%=loggedUser.getUniversalId()%>).</p>
        <p>If that is the wrong user account, you can logout and login with the correct one.</p>
        <button class="btn btn-primary btn-raised" onClick="logoutButton()">
            Logout
        </button>
        
    </div>
    
<% } else { %>
    <div>
        <p>If you already have an account, please Login to find out more.</p>
        <button class="btn btn-primary btn-raised" onClick="loginButton()">
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

  <div>
    

  </div>
  </div>
</div>
</div>
</body>
</html>




