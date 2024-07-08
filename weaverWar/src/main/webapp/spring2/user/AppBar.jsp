<!-- BEGIN AppBar.jsp -->
<script>

    function changePage(dest) {
        window.location = dest;
    }
    function logOutPage() {
        SLAP.logOutProvider();
    }

    var retPath ='<%=ar.retPath%>';
    var userKey = "<%=pageUserKey%>";
    var isSuperAdmin = "<%=ar.isSuperAdmin()%>";
</script>





<nav class="navbar navbar-expand-lg navbar-dark bg-weaverdark py-0">
<div class="container-fluid">

  <!-- Logo Brand -->
  <a class="navbar-brand pb-2" href="<%=userRelPath%>UserHome.htm" title="Access your overall personal Weaver Home Page">
    <span class="fw-semibold fs-1 text-weaverbody">
      <img class="d-inline-block mx-2" alt="Weaver Logo" src="<%=ar.retPath%>bits/header-icon.png">
    Weaver</span>
  </a>

  <!-- Search Bar -->
  <i class="fa fa-search text-weaverbody mx-3" aria-hidden="true"></i>
        <form class="d-flex">
          <input 
              class="form-control me-2 text-weaverbody" 
              type="search" 
              placeholder="Search" 
              aria-label="Search"
              />
        </form>
  <!-- end Search Bar -->
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

        <!-- Start top navigation -->

      <div class="collapse navbar-collapse" id="topbar-nav">
        <ul class="navbar-nav ms-auto">
<%if(ar.isSuperAdmin()){ %>

      <li style="padding:5px" onclick="window.location = '<%=userRelPath%>../su/EmailListnerSettings.htm'">
          <img src="<%=ar.retPath%>/bits/adminicon.png" style="max-height:50px;max-width:50px">
          </li>
        </ul>

<% } %>      
      
<% if (loggedUser!=null) { %>    
  <ul class="navbar-nav">
    <li class="nav-item dropdown">
        <a 
        href="#"
        class="nav-link dropdown-toggle text-weaverbody"
        id="navbarWorkspaceDropdown"
        role="button"
        data-bs-toggle="dropdown-toggle-label ng-scope"
        aria-expanded="false"
        >
        <i class="fa fa-circle-o" aria-hidden="true"></i>
        <span class="dropdown-toggle-label" translate>Workspaces</span>
        </a>
        <ul class="dropdown-menu" aria-labelledby="navbarWorkspacesDropdown"
        >
<span class="dropdown-item">
  <%

   List<RUElement> recent = ar.getSession().recentlyVisited;
   for (RUElement rue : recent) {
       ar.write("\n<li><a href=\"");
       ar.write(ar.retPath);
       ar.write("t/");
       ar.write(rue.siteKey);
       ar.write("/");
       ar.write(rue.key);
       ar.write("/FrontPage.htm\">");
       ar.writeHtml(rue.displayName);
       ar.write("</a></li>");
   }
  
%>
</span>
      <li><hr class="dropdown-divider"></li>
      <li><a class="dropdown-item" href="#" 
        id="navbarRecentlyVisitedDropdown"
        data-bs-toggle="dropdown-toggle-label ng-scope" 
        aria-expanded="false"></a></li>
      <li class="divider"></li>
      <li><a class="dropdown-item" href="<%=userRelPath%>WatchedProjects.htm">Watched Workspaces</a></li>
      <li><a class="dropdown-item" href="<%=userRelPath%>OwnerProjects.htm">Administered</a></li>
      <li><a class="dropdown-item" href="<%=userRelPath%>ParticipantProjects.htm">Participant</a></li>
      <li><a class="dropdown-item" href="<%=userRelPath%>AllProjects.htm">All</a></li>
      </ul>
        </li>


        
        
<% } %>  
        
<% if (loggedUser==null) { %>
    <span class="navbar-brand">
      <a href="<%=ar.getSystemProperty("identityProvider")%>?openid.mode=quick&go=<%=URLEncoder.encode(currentPageURL, "UTF-8")%>">
        <h1>Login</h1>
      </a>
    </span>
    
<% } else { %>    
        <!-- Drop Down User -->
        <li class="nav-item dropdown">
          <a class="nav-link dropdown-toggle text-weaverbody"
          role="button"
          data-target="#"
          data-toggle="dropdown"
          aria-expanded="false"
          title="User: <% ar.writeHtml(userName); %>">
            <i class="fa fa-user" aria-hidden="true"></i>
            <span class="dropdown-toggle-label">
              <% ar.writeHtml(userName); %>
            </span>
          </a>
          <ul class="dropdown-menu bg-weaverbody text-weaverdark">
            <li><a class="dropdown-item" href="<%=userRelPath%>UserHome.htm">Home</a></li>
            <li><a class="dropdown-item" href="<%=userRelPath%>UserSettings.htm">Profile</a></li>
            <li><a class="dropdown-item" href="<%=userRelPath%>UserAlerts.htm">Updates</a></li>
            <li><a class="dropdown-item" href="<%=userRelPath%>EmailUser.htm">Email Sent</a></li>
            <li><a class="dropdown-item" href="<%=userRelPath%>NotificationSettings.htm">Withdraw</a></li>
            <li><a class="dropdown-item" href="<%=userRelPath%>Facilitators.htm">Facilitators</a></li>
            <li><a class="dropdown-item" href="<%=userRelPath%>LearningPath.htm">Learning Settings</a></li>
            <li><a class="dropdown-item" href="https://s06.circleweaver.com/TutorialList.html" target="Training">Training</a></li>
<%if(ar.isSuperAdmin()){ %>
            <li class="divider"></li>
            <li><a class="dropdown-item" href="<%=userRelPath%>../su/EmailListnerSettings.htm">Administration</a></li>
<%} %>
            <li class="divider"></li>
            <li><a class="dropdown-item" onclick='logOutPage();'>Log Out</a></li>
<% } %> 
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
<!-- END AppBar.jsp -->
<% out.flush(); %>
