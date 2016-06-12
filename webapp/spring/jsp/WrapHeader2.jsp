<!-- BEGIN WrapHeader2.jsp -->
<%

//We always POST to an address that consumes the data, and then redirects to a display page,
//so the display page (like this one) should never experience a POST request
    ar.assertNotPost();
    
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
    if(pageTitle == null && pageId != null){
        ngp  = ar.getCogInstance().getProjectByKeyOrFail(pageId);
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

<nav class="navbar navbar-default">
  <div >
    <div class="navbar-header">
        <a href="<%=userRelPath%>UserHome.htm" title="Weaver Home Page"><img src="<%=ar.retPath%>bits/weavericon.png"></a>
    </div>
    <div class="collapse navbar-collapse">
      <ul class="nav navbar-nav">
        <li class="dropdown">
          <a class="dropdown-toggle" data-toggle="dropdown" role="button" 
             aria-haspopup="true" aria-expanded="false">Workspaces <span class="caret"></span></a>
          <ul class="dropdown-menu">
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
            <li role="separator" class="divider"></li>
            <li><a href="<%=userRelPath%>watchedProjects.htm">Watched Workspaces</a></li>
            <li><a href="<%=userRelPath%>templates.htm">Templates</a></li>
            <li><a href="<%=userRelPath%>ownerProjects.htm">Administered</a></li>
            <li><a href="<%=userRelPath%>participantProjects.htm">Participant</a></li>
            <li><a href="<%=userRelPath%>allProjects.htm">All</a></li>
          </ul>
        </li>
        <li class="dropdown">
          <a class="dropdown-toggle" data-toggle="dropdown" role="button" 
             aria-haspopup="true" aria-expanded="false">Sites <span class="caret"></span></a>
          <ul class="dropdown-menu">
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
      </ul>
      <form class="navbar-form navbar-left" role="search" action="searchAllNotes.htm">
        <div class="form-group">
          <input type="text" class="form-control" name="s" placeholder="Search">
        </div>
        <button type="submit" class="btn btn-default">Submit</button>
      </form>
      <ul class="nav navbar-nav navbar-right">
        <li class="dropdown">
          <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" 
             aria-haspopup="true" aria-expanded="false"><% ar.writeHtml(userName); %><span class="caret"></span></a>
          <ul class="dropdown-menu">
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
    </div>
  </div>
</nav>

<ol class="breadcrumb">
<% if(isUserHeader) { %>
  <li>Users</li>
  <li><a href="<%=userRelPath%>UserHome.htm"><% ar.writeHtml(userName); %></a></li>
  <li><% ar.writeHtml(jspName); %></li>
<% } else if(isSiteHeader) { %>
  <li>Site</li>
  <li><a href="<%=ar.retPath%>v/<%ar.writeURLData(accountKey);%>/$/accountListProjects.htm">
      <%ar.writeHtml(title);%></a></li>
  <li><% ar.writeHtml(jspName); %></li>
<% } else { %>
  <li>Workspace</li>
  <li><a href="<%=ar.retPath%>v/<%ar.writeURLData(ngb.getKey());%>/$/accountListProjects.htm"><%ar.writeHtml(ngb.getFullName());%></a></li>
  <li><a href="<%=ar.retPath%>v/<%ar.writeURLData(ngb.getKey());%>/<%ar.writeURLData(ngp.getKey());%>/frontPage.htm">
      <%ar.writeHtml(ngp.getFullName());%></a></li>
  <li><% ar.writeHtml(jspName); %></li>
<% } %>
</ol>

<% if(isSiteHeader) { %>

<ul id="tabs" class="nav nav-tabs" data-tabs="tabs">
    <li<%if("Workspaces in Site".equals(jspName)){%> class="active"<%}%>>
        <a href="accountListProjects.htm">Workspaces in Site</a></li>
    <li<%if("Site Admin".equals(jspName)){%> class="active"<%}%>>
        <a href="SiteAdmin.htm">Site Admin</a></li>
</ul>

<% } else if(!isUserHeader) { %>

<ul id="tabs" class="nav nav-tabs" data-tabs="tabs">
    <li<%if("Front Page".equals(jspName)){%> class="active"<%}%>><a href="frontPage.htm">Front Page</a></li>
    <li<%if("Meetings".equals(jspName)){%> class="active"<%}%>><a href="meetingList.htm">Meetings</a></li>
    <li<%if("Topics".equals(jspName)){%> class="active"<%}%>><a href="notesList.htm">Topics</a></li>
    <li<%if("Documents".equals(jspName)){%> class="active"<%}%>><a href="listAttachments.htm">Documents</a></li>
    <li<%if("Action Items".equals(jspName)){%> class="active"<%}%>><a href="goalList.htm">Action Items</a></li>
    <li<%if("Decisions".equals(jspName)){%> class="active"<%}%>><a href="decisionList.htm">Decisions</a></li>
    <li<%if("Labels".equals(jspName)){%> class="active"<%}%>><a href="labelList.htm">Labels</a></li>
    <li<%if("Roles".equals(jspName)){%> class="active"<%}%>><a href="roleManagement.htm">Roles</a></li>
    <li<%if("Workspace Admin".equals(jspName)){%> class="active"<%}%>><a href="admin.htm">Workspace Admin</a></li>
    <li<%if("Personal".equals(jspName)){%> class="active"<%}%>><a href="personal.htm">Personal</a></li>
</ul>

<% } %>


 
    <div id="welcomeMessage"></div>


<script>
function validateDelimEmails(field) {
    var count = 1;
    var result = "";
    var spiltedEmails;
    var value = trimme(field.value);
    if(value != ""){
        if(value.indexOf(";") != -1){
            spiltedEmails = value.split(";");
        }else if(value.indexOf(",") != -1){
            spiltedEmails = value.split(",");
        }else if(value.indexOf("\n") != -1){
            spiltedEmails = value.split("\n");
        }else{
            value = value+";";
            spiltedEmails = value.split(";");
        }
        for(var i = 0;i < spiltedEmails.length;i++){
            var email_id = trimme(spiltedEmails[i]);
            if(email_id != ""){
                if(!validateEmail(email_id)){
                    result += "  "+count+".    "+email_id+" \n";
                    count++;
                }
            }
        }
    }
    if(result != ""){
        alert("Below is the list of id(s) which does not look like an email. Please enter an email id(s).\n\n"+result);
        field.focus();
        return false;
    }

    return true;
}


function displayWelcomeMessage(info) {
    var y = document.getElementById("welcomeMessage");
    if (info.haveNotCheckedYet) {
        y.innerHTML = 'Checking identity, please <a href="'
            +loginConfig.providerUrl
            +'&go='+window.location+'">Login</a>.';
    }
    else if (!info.userName) {
        y.innerHTML = 'Not logged in, please <a href="'
            +loginConfig.providerUrl
            +'?openid.mode=quick&go='+window.location+'">Login</a>.';
    }
    else if (!info.verified) {
        y.innerHTML = 'Hello <b>'+info.userName+'</b>.  Attempting Automatic Login.';
    }
    else {
        y.innerHTML = 'Welcome <b>'+info.userName+'</b>.  <a target="_blank" href="'
            +loginConfig.providerUrl
            +'?openid.mode=logout&go='+window.location+'">Logout</a>.';
    }
}


initLogin(<% loginConfig.write(out, 2, 2); %>, <% loginInfo.write(out, 2, 2); %>, displayWelcomeMessage);
</script>
<!-- END WrapHeader2.jsp -->
<% out.flush(); %>
