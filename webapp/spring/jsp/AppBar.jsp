<!-- BEGIN AppBar.jsp -->

<script>

    function changePage(dest) {
        window.location = dest;
    }

    var retPath ='<%=ar.retPath%>';
    var headerType = '<%=headerTypeStr%>';
    var book='';
    var pageId = '<%=pageId%>';
    var userKey = "<%=pageUserKey%>";
    var isSuperAdmin = "<%=ar.isSuperAdmin()%>";
</script>


<% if (!isSiteHeader) { %>
    <script>
        <% if (pageId != null && bookId != null) { %>
          book='<%=bookId%>';
        <% } %>
    </script>

<% } else if(isSiteHeader){ %>
     <script>
        <% if(accountId != null){ %>
        var accountId='<%=accountId %>';
        <% } else if(pageId!=null){ %>
        var accountId='<%=pageId%>';
        <% } %>
     </script>
<% } %>



<nav class="navbar navbar-default appbar">
<div class="container-fluid">

  <!-- Subnavi Collapse Button -->
  <button type="button" class="navbar-toggle visible-xs" data-toggle="collapse" data-target=".navbar-responsive-collapse">
    <span class="icon-bar"></span>
    <span class="icon-bar"></span>
    <span class="icon-bar"></span>
  </button>

<style>
.tighten li a {
    padding: 0px 5px !important;
    background-color: white;
}
.tighten li {
    background-color: white;
}
.tighten {
    padding: 5px !important;
    border: 5px #F0D7F7 solid !important;
    max-width:300px;
    background-color: white !important;
}
</style>
<!-- #F0D7F7;  #F2EBF4 -->

  <!-- Logo Brand -->
  <a class="navbar-brand" href="<%=userRelPath%>UserHome.htm" title="Access your overall personal Weaver Home Page">
    <img class="hidden-xs" alt="Weaver Icon" src="<%=ar.retPath%>bits/header-icon.png">
    <h1>Weaver</h1>
  </a>

  <!-- Drop Down Workspaces -->
  <ul class="nav navbar-nav appbar-nav">
      <li class="visible-xs">
        <a class="dropdown-toggle"
          data-target=".search"
          data-toggle="collapse"
          title="Search"
          id="toggle-search">
          <i class="fa fa-search" aria-hidden="true"></i>
        </a>
      </li>
      

      
<% if (loggedUser!=null) { %>      
      <li class="dropdown">
            <a class="dropdown-toggle"
            data-target="#"
            data-toggle="dropdown"
            aria-expanded="false"
            title="Workspaces">
              <i class="fa fa-circle-o" aria-hidden="true"></i>
              <span class="dropdown-toggle-label">
                Workspaces
              </span>
              <div class="ripple-container"></div>
            </a>
            <ul class="dropdown-menu pull-right tighten">
<%

   List<RUElement> recent = ar.getSession().recentlyVisited;
   for (RUElement rue : recent) {
       ar.write("\n<li><a href=\"");
       ar.write(ar.retPath);
       ar.write("t/");
       ar.write(rue.siteKey);
       ar.write("/");
       ar.write(rue.key);
       ar.write("/frontPage.htm\">");
       ar.writeHtml(rue.displayName);
       ar.write("</a></li>");
   }

%>
            <li class="divider"></li>
            <li><a href="<%=userRelPath%>watchedProjects.htm">Watched Workspaces</a></li>
            <li><a href="<%=userRelPath%>templates.htm">Templates</a></li>
            <li><a href="<%=userRelPath%>ownerProjects.htm">Administered</a></li>
            <li><a href="<%=userRelPath%>participantProjects.htm">Participant</a></li>
            <li><a href="<%=userRelPath%>allProjects.htm">All</a></li>
          </ul>
        </li>


<% if (false) { %>   
<!-  REMOVED the Sites menu as it is not so useful it needs to always be on the screen
     Adding a small menu item to the personal list should be enough -->     
        <!-- Drop Down Sites -->
        <li>
          <a class="dropdown-toggle"
          data-target="#"
          data-toggle="dropdown"
          aria-expanded="false"
          title="Sites">
            <i class="fa fa-sitemap" aria-hidden="true"></i>
            <span class="dropdown-toggle-label">
              Sites
            </span>
          </a>
          <ul class="dropdown-menu pull-right tighten">
<%

   Properties seenSite = new Properties();
   for (RUElement rue : recent) {
       if (seenSite.get(rue.siteKey)!=null) {
           continue;
       }
       seenSite.put(rue.siteKey, rue.siteKey);
       ar.write("\n<li><a href=\"");
       ar.write(ar.retPath);
       ar.write("t/");
       ar.write(rue.siteKey);
       ar.write("/$/accountListProjects.htm\">");
       ar.writeHtml(rue.siteKey);
       ar.write("</a></li>");
   }

%>
            <li role="separator" class="divider"></li>
            <li><a href="<%=userRelPath%>userAccounts.htm">List Sites</a></li>
          </ul>
        </li>
<% } %>         
        
<% } %>  
        
        <!-- Drop Down User -->
        <li>
          <a class="dropdown-toggle"
          data-target="#"
          data-toggle="dropdown"
          aria-expanded="false"
          title="User: <% ar.writeHtml(userName); %>">
            <i class="fa fa-user" aria-hidden="true"></i>
            <span class="dropdown-toggle-label">
              <% ar.writeHtml(userName); %>
            </span>
          </a>
          <ul class="dropdown-menu pull-right tighten">
<% if (loggedUser==null) { %>
            <li><a href="<%=ar.getSystemProperty("identityProvider")%>?openid.mode=quick&go=<%=URLEncoder.encode(currentPageURL, "UTF-8")%>">
                Log In</a></li>
<% } else { %>
            <li><a href="<%=userRelPath%>UserHome.htm">Home</a></li>
            <li><a href="<%=userRelPath%>userSettings.htm">Profile</a></li>
            <li><a href="<%=userRelPath%>userAlerts.htm">Updates</a></li>
            <li><a href="<%=userRelPath%>notificationSettings.htm">Notifications</a></li>
<%if(ar.isSuperAdmin()){ %>
            <li class="divider"></li>
            <li><a href="<%=userRelPath%>../su/emailListnerSettings.htm">Administration</a></li>
<%} %>
            <li class="divider"></li>
            <li><a onclick='logOutProvider();'>Log Out</a></li>
<% } %> 
          </ul>
        </li>
        </ul>
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
