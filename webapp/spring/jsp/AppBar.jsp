<!-- BEGIN AppBar.jsp -->
<%

//We always POST to an address that consumes the data, and then redirects to a display page,
//so the display page (like this one) should never experience a POST request
    if (!"DisplayException".equals(wrappedJSP)) {
        ar.assertNotPost();
    }

    String mainWorkspaceId = "";
    String mainSiteId = "";
    String mainSiteName = "";
    if (ar.isLoggedIn()) {
        List<WatchRecord> wl = loggedUser.getWatchList();
        if (wl.size()>0) {
            mainWorkspaceId = wl.get(0).getPageKey();
            NGPageIndex ngpi = cog.getContainerIndexByKey(mainWorkspaceId);
            if (ngpi!=null) {
                mainSiteId = ngpi.pageBookKey;
                NGBook site = ar.getCogInstance().getSiteByIdOrFail(mainSiteId);
                mainSiteName = site.getFullName();
            }
        }
    }
    String accountKey = ar.defParam("accountId", null);
    NGBook site = null;
    if (accountKey!=null) {
        site = cog.getSiteByIdOrFail(accountKey);
        mainSiteName = site.getFullName();
    }


//TODO: determine what this does.
    String deletedWarning = "";

    NGContainer ngp =null;
    NGBook ngb=null;
    UserProfile userRecord = null;

//TODO: why test for pageTitle being null here?
    if(pageTitle == null && pageId != null && !"$".equals(pageId)){
        ngp  = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    }
    if(isUserHeader && userKey!=null){
        userRecord = UserManager.getUserProfileByKey(userKey);
    }


    if (ngp!=null) {
        ar.setPageAccessLevels(ngp);
        pageTitle = ngp.getFullName();
        if(ngp instanceof NGPage) {
            ngb = ((NGPage)ngp).getSite();
            showExperimental = ngb.getShowExperimental();
        }
        else if(ngp instanceof NGBook) {
            ngb = ((NGBook)ngp);
            showExperimental = ngb.getShowExperimental();
        }
        if (ngp.isDeleted()) {
            deletedWarning = "<img src=\""+ar.retPath+"deletedLink.gif\"> (DELETED)";
        }
        else if (ngp.isFrozen()) {
            deletedWarning = " &#10052; (Frozen)";
        }
    }
    UserProfile uProf = ar.getUserProfile();
    //this is the base path for the all of the menu options.
    //should not actually see any menu options if not logged in, however
    //need to give a value for this.
    String userRelPath = ar.retPath + "v/$/";
    String userName = "GUEST";
    if (uProf!=null) {
        userRelPath = ar.retPath + "v/"+uProf.getKey()+"/";
        userName = uProf.getName();
    }
    int exposeLevel = 1;
    if (ar.isSuperAdmin()) {
        exposeLevel = 2;
    }
    JSONObject loginInfo = new JSONObject();
    if (ar.isLoggedIn()) {
        loginInfo.put("userId", ar.getBestUserId());
        loginInfo.put("userName", uProf.getName());
        loginInfo.put("verified", true);
        loginInfo.put("msg", "Previously logged into server");
    }
    else {
        //use this to indicate the very first display, before the page knows anything
        loginInfo.put("haveNotCheckedYet", true);
    }
    JSONObject loginConfig = new JSONObject();
    loginConfig.put("providerUrl", ar.getSystemProperty("identityProvider"));
    loginConfig.put("serverUrl",   ar.baseURL);


    String currentPageURL = ar.getCompleteURL();
    String encodedLoginMsg = URLEncoder.encode("Can't open form","UTF-8");
    String trncatePageTitle = pageTitle;
    if (pageTitle!=null && pageTitle.length()>60){
        trncatePageTitle=pageTitle.substring(0,60)+"...";
    }



    %>


<script>

    function changePage(dest) {
        window.location = dest;
    }

    var retPath ='<%=ar.retPath%>';
    var headerType = '<%=headerTypeStr%>';
    var book='';
    var pageId = '<%=pageId%>';
    var userKey = "<%=userKey%>";
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


  <!-- Logo Brand -->
  <a class="navbar-brand" href="<%=userRelPath%>UserHome.htm" title="Weaver Home Page">
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
            <ul class="dropdown-menu pull-right">
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
          <ul class="dropdown-menu pull-right">
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
          <ul class="dropdown-menu pull-right">
<% if (uProf==null) { %>
            <li><a href="<%=ar.getSystemProperty("identityProvider")%>?openid.mode=quick&go=<%=URLEncoder.encode(currentPageURL, "UTF-8")%>">
                Log In</a></li>
<% } else { %>
            <li><a onclick='logOutProvider();'>Log Out</a></li>
<% } %>
            <li><a href="<%=userRelPath%>userSettings.htm">Profile</a></li>
            <li><a href="<%=userRelPath%>userAlerts.htm">Updates</a></li>
            <li><a href="<%=userRelPath%>notificationSettings.htm">Notifications</a></li>
<%if(ar.isSuperAdmin()){ %>
            <li><a href="<%=userRelPath%>emailListnerSettings.htm">Administration</a></li>
<%} %>
          </ul>
        </li>
        </ul>
      </ul>
      <!-- END App Bar -->
      <!-- BEGIN Input Search -->
      <div class="search navbar-left collapse">
        <form class="navbar-form" role="search" action="searchAllNotes.htm">
          <div class="form-group is-empty">
            <input type="text" class="form-control" name="s" placeholder="Search">
          </div>
        </form>
      </div>
      <!-- END Input Search -->
    </div>
</nav>
<!-- END AppBar.jsp -->
<% out.flush(); %>
