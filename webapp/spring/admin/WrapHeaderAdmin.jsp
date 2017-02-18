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
                mainSiteId = ngpi.wsSiteKey;
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

    UserProfile uProf = ar.getUserProfile();
    //this is the base path for the all of the menu options.
    //should not actually see any menu options if not logged in, however
    //need to give a value for this.
    
    
    String userRelPath = ar.retPath + "v/"+uProf.getKey()+"/";
    String userName = uProf.getName();

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
   
    %>


<script>
    
    function changePage(dest) {
        window.location = dest;
    }

    var retPath ='<%=ar.retPath%>';
</script>



<nav class="navbar navbar-default">
  <div >
    <div class="navbar-header">
        <a id="weaver-logo-header" href="<%=userRelPath%>UserHome.htm" title="Weaver Home Page"><img src="<%=ar.retPath%>bits/weaver-logo-header.png"></a>
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
      <ul class="nav navbar-nav">
        <li class="dropdown">
          <a class="dropdown-toggle" data-toggle="dropdown" role="button" 
             aria-haspopup="true" aria-expanded="false">Administration <span class="caret"></span></a>
          <ul class="dropdown-menu">
            <li><a href="errorLog.htm" >Error Log</a></li>
            <li><a href="emailListnerSettings.htm" >Listener Settings</a></li>
            <li><a href="lastNotificationSend.htm" >Notification Settings</a></li>
            <li><a href="newUsers.htm" >New Users</a></li>
            <li><a href="requestedAccounts.htm" >Requested Sites</a></li>
            <li><a href="allSites.htm" >All Sites</a></li>
          </ul>
        </li>
      </ul>
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
            <li><a href="<%=userRelPath%>emailListnerSettings.htm">Administration</a></li>
          </ul>
        </li>
      </ul>
    </div>
  </div>
</nav>


 
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
