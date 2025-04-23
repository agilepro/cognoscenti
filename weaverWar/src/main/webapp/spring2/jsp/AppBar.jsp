<!-- BEGIN AppBar.jsp -->
<script>

  function changePage(dest) {
    window.location = dest;
  }
  function logOutPage() {
    SLAP.logOutProvider();
  }

  var retPath = '<%=ar.retPath%>';
  var headerType = '<%=headerTypeStr%>';
  var book = '';
  var pageId = '<%=pageId%>';
  var userKey = "<%=pageUserKey%>";
  var isSuperAdmin = "<%=ar.isSuperAdmin()%>";
</script>
<% if (!isSiteHeader) { %>
  <script>
        <% if (pageId != null && siteId != null) { %>
      book='<%=siteId%>';
        <% } %>
  </script>
  <% } else if(isSiteHeader){ %>
    <script>
        <% if (accountId != null) { %>
        var accountId = '<%=accountId %>';
        <% } else if (pageId != null) { %>
        var accountId = '<%=pageId%>';
        <% } %>
    </script>
    <% } %>
      <nav class="navbar navbar-expand-lg navbar-dark bg-primary py-0">
        <div class="container-fluid override">


          
          <!-- Logo Brand -->
          <a class="navbar-brand pb-2" href="<%=userRelPath%>UserHome.htm"
            title="Access your overall personal Weaver Home Page">
            <span class="fw-semibold fs-1 text-weaverbody">
              <img class="d-inline-block mx-2" alt="Weaver Logo" src="<%=ar.retPath%>new_assets/bits/header-icon.png">
              Weaver</span>
          </a>
          <!-- Search Bar -->
          <div class="row search">
            <form class="d-flex" role="search" action="searchAllNotes.htm">
              <div class="form-group specialweaver is-empty">
                <input type="text" class="form-control me-2" name="s" placeholder=" &#xF002; Search"
                  style="font-family:Arial, FontAwesome">
              </div>
            </form>
          </div>
          <!-- end Search Bar -->
                    <!-- toggle button for mobile nav -->
          <button class="navbar-toggler no-btn float-end" type="button" data-bs-toggle="collapse" data-bs-target="#topbar-nav"
            aria-controls="navbarNavAltMarkup" aria-expanded="false" aria-label="Toggle navigation">
            <span class="navbar-toggler-icon"></span>
          </button>
          <!-- end toggle button for mobile nav -->
          <!-- Start top navigation -->
          <div class="collapse navbar-collapse" id="topbar-nav">
            <ul class="navbar-nav ms-auto">
              <%if(ar.isSuperAdmin()){ %>
                <li class="nav-item" style="padding:5px" onclick="window.location = '<%=userRelPath%>../su/EmailListnerSettings.htm'">
                  <img src="<%=ar.retPath%>new_assets/bits/adminicon.png" style="max-height:50px;max-width:50px">
                </li>
            </ul>
            <% } %>
              <% if (loggedUser!=null) { %>
                <ul class="navbar-nav pe-3">
                  <!-- Drop Down help -->
                  <li class="nav-item dropdown">
                    <button class="nav-link dropdown-toggle text-weaverbody" id="navbarHelpDropdown" role="button"
                      data-bs-toggle="dropdown" aria-expanded="false">
                      <i class="fa fa-question-circle" aria-hidden="true"></i> Help</button>
                    <ul class="dropdown-menu" aria-labelledby="navbarHelpDropdown">
                      <li><a class="dropdown-item" href="<%=userRelPath%>LearningPath.htm">Learning Settings</a></li>
                      <li><a class="dropdown-item" href="https://s06.circleweaver.com/TutorialList.html"
                          target="Training">Training Videos</a></li>
                    </ul>
                  </li>
                  <!-- Drop Down Add -->
                  <li class="nav-item dropdown">
                    <button class="nav-link dropdown-toggle text-weaverbody" id="navbarAddDropdown" role="button"
                      data-bs-toggle="dropdown" aria-expanded="false">
                      <i class="fa fa-plus" aria-hidden="true"></i>
                      <span class="dropdown-toggle-label" translate>Add</span>
                    </button>
                    <ul class="dropdown-menu" aria-labelledby="navbarAddDropdown">
                      <li><a class="dropdown-item" href="AddSomething.htm?start=meeting">Meeting</a></li>
                      <li><a class="dropdown-item" href="NotesList.htm?start=create">Discussion</a></li>
                      <li><a class="dropdown-item" href="DocsAdd.htm">Document</a></li>
                      <li><a class="dropdown-item" href="GoalStatus.htm?start=create">Action Item</a></li>
                      <li><a class="dropdown-item" href="DecisionList.htm?start=create">Decision</a></li>
                      <li><a class="dropdown-item" href="SendNote.htm">Email</a></li>
                      <li><a class="dropdown-item" href="AddSomething.htm">Something Else</a></li>
                    </ul>
                  </li>
                  <!-- Drop Down Workspace -->
                  <li class="nav-item dropdown">
                    <button class="nav-link dropdown-toggle text-weaverbody" id="navbarWorkspaceDropdown"
                      role="button" data-bs-toggle="dropdown-toggle-label" aria-expanded="false">
                      <i class="fa fa-circle-o" aria-hidden="true"></i>
                      <span class="dropdown-toggle-label" translate>Workspaces</span>
                    </button>
                    <ul class="dropdown-menu" aria-labelledby="navbarWorkspacesDropdown">
                      <span class="dropdown-item">
                        <% List<RUElement> recent = ar.getSession().recentlyVisited; for (RUElement rue : recent) {
                          ar.write("\n<li><a href=\""); ar.write(ar.retPath); ar.write("t/"); ar.write(rue.siteKey);
                              ar.write("/"); ar.write(rue.key); ar.write("/FrontPage.htm\">");
                              ar.writeHtml(rue.displayName); ar.write("</a></li>"); } %>
                      </span>
                      <li>
                        <hr class="dropdown-divider">
                      </li>
                      <li><a class="dropdown-item" href="<%=userRelPath%>WatchedProjects.htm">Watched Workspaces</a>
                      </li>
                      <li><a class="dropdown-item" href="<%=userRelPath%>OwnerProjects.htm">Administered</a></li>
                      <li><a class="dropdown-item" href="<%=userRelPath%>ParticipantProjects.htm">Participant</a></li>
                      <li><a class="dropdown-item" href="<%=userRelPath%>AllProjects.htm">All</a></li>
                    </ul>
                  </li>
                  <% } %>
                    <!-- Drop Down User -->
                    <% if (loggedUser==null) { %>
                      <li class="nav-item dropdown">
                        <a class="nav-link dropdown-toggle" role="button" data-bs-toggle="dropdown"
                          aria-expanded="false" id="navbarProfileDropdown" href="<%=ar.getSystemProperty("identityProvider")%>?openid.mode=quick&go=<%=URLEncoder.encode(currentPageURL, "UTF-8")%>"
                            <h2>Login</h2>
                        </a>
                      </li>
                      <% } else { %>
                        <li class="nav-item dropdown">
                          <a class="nav-link dropdown-toggle text-weaverbody" data-target="#" role="button"
                            data-bs-toggle="dropdown-toggle-label" aria-expanded="false" title="User: <% ar.writeHtml(userName); %>">
                            <i class="fa fa-user" aria-hidden="true"></i>
                            <span class="dropdown-toggle-label">
                              <% ar.writeHtml(userName); %>
                            </span>
                          </a>
                          <ul class="dropdown-menu" aria-labelledby="navbarProfileDropdown">
                            <li><a class="dropdown-item" href="<%=userRelPath%>UserHome.htm">Home</a></li>
                            <li><a class="dropdown-item" href="<%=userRelPath%>UserSettings.htm">Profile</a></li>
                            <li><a class="dropdown-item" href="<%=userRelPath%>UserAlerts.htm">Updates</a></li>
                            <li><a class="dropdown-item" href="<%=userRelPath%>EmailUser.htm">Email Sent</a></li>
                            <li><a class="dropdown-item" href="<%=userRelPath%>NotificationSettings.htm">Withdraw</a>
                            </li>
                            <%if(ar.isSuperAdmin()){ %>
                              <li class="dropdown-divider"></li>
                              <li><a class="dropdown-item"
                                  href="<%=userRelPath%>../su/EmailListnerSettings.htm">Administration</a></li>
                              <%} %>
                                <li class="dropdown-divider"></li>
                                <li><a class="dropdown-item" onclick='logOutPage();'>Log Out</a></li>
                                <% } %>
                          </ul>
                        </li>
                </ul>
          </div>
        </div>
      </nav>
      <!-- END App Bar -->
      <!-- END AppBar.jsp -->
      <% out.flush(); %>