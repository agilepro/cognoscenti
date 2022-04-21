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
.sublist {
    padding: 0px 5px !important;
    background-color: white;
    border: 5px #F0D7F7 solid;
    color: black;
    overflow: hidden;
    text-overflow: clip;
    white-space: nowrap;
}
.sublist ul li {
    padding: 2px;
}
.sublist ul li a {
    color: black;
}
</style>
<!-- #F0D7F7;  #F2EBF4 -->

  <!-- Logo Brand -->
  <a class="navbar-brand" href="<%=userRelPath%>UserHome.htm" title="Access your overall personal Weaver Home Page">
    <img class="hidden-xs" alt="Weaver Icon" src="<%=ar.retPath%>bits/header-icon.png">
    <span class="weaver-logo">Weaver</span>
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
      
<%if(ar.isSuperAdmin()){ %>
      <li style="padding:5px" onclick="window.location = '<%=userRelPath%>../su/emailListnerSettings.htm'">
          <img src="<%=ar.retPath%>/bits/adminicon.png" style="max-height:50px;max-width:50px">
          </li>
<% } %>      
      
<% if (loggedUser!=null) { %>      
      <li class="dropdown">
            <a class="dropdown-toggle"
            data-target="#"
            data-toggle="dropdown"
            aria-expanded="false"
            title="Workspaces">
              <i class="fa fa-circle-o" aria-hidden="true"></i>
              <span class="dropdown-toggle-label" translate>Workspaces</span>
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
            <li><a href="<%=userRelPath%>WatchedProjects.htm">Watched Workspaces</a></li>
            <li><a href="<%=userRelPath%>OwnerProjects.htm">Administered</a></li>
            <li><a href="<%=userRelPath%>ParticipantProjects.htm">Participant</a></li>
            <li><a href="<%=userRelPath%>AllProjects.htm">All</a></li>
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
            <li><a href="<%=userRelPath%>UserHome.htm">Home</a></li>
            <li><a href="<%=userRelPath%>UserSettings.htm">Profile</a></li>
            <li><a href="<%=userRelPath%>UserAlerts.htm">Updates</a></li>
            <li><a href="<%=userRelPath%>EmailUser.htm">Email Sent</a></li>
            <li><a href="<%=userRelPath%>NotificationSettings.htm">Withdraw</a></li>
            <li><a href="https://www.youtube.com/playlist?list=PL-y45TQ2Eb40eQWwH5NjyIjgepk_MonlB">Training</a></li>
<%if(ar.isSuperAdmin()){ %>
            <li class="divider"></li>
            <li><a href="<%=userRelPath%>../su/emailListnerSettings.htm">Administration</a></li>
<%} %>
            <li class="divider"></li>
            <li><a onclick='logOutPage();'>Log Out</a></li>
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
