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
            mainWorkspaceId = wl.get(0).pageKey;
            NGPageIndex ngpi = cog.getWSByCombinedKey(mainWorkspaceId);
            if (ngpi==null) {
                //transition to combined key for everyone someday
                ngpi = cog.lookForWSBySimpleKeyOnly(mainWorkspaceId);
            }
            if (ngpi!=null) {
                mainSiteId = ngpi.wsSiteKey;
                NGBook site = ar.getCogInstance().getSiteByIdOrFail(mainSiteId);
                mainSiteName = site.getFullName();
            }
        }
    }
    String accountKey = ar.defParam("siteId", null);
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

    JSONObject loginInfoPrefetch = new JSONObject();
    if (ar.isLoggedIn()) {
        loginInfoPrefetch.put("userId", ar.getBestUserId());
        loginInfoPrefetch.put("userName", uProf.getName());
        loginInfoPrefetch.put("verified", true);
        loginInfoPrefetch.put("msg", "Previously logged into server");
    }
    else {
        //use this to indicate the very first display, before the page knows anything
        loginInfoPrefetch.put("haveNotCheckedYet", true);
    }
    JSONObject adminLoginConfig = new JSONObject();
    adminLoginConfig.put("providerUrl", ar.getSystemProperty("identityProvider"));
    adminLoginConfig.put("serverUrl",   ar.baseURL);


    String currentPageURL = ar.getCompleteURL();
   
    %>


<script>
    
    function changePage(dest) {
        window.location = dest;
    }
    function logOutPage() {
        SLAP.logOutProvider();
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
             aria-haspopup="true" aria-expanded="false">Administration <span class="caret"></span></a>
          <ul class="dropdown-menu">
            <li><a href="ErrorList.htm" >Error List</a></li>
            <li><a href="EmailListnerSettings.htm" >Listener Settings</a></li>
            <li><a href="NotificationStatus.htm" >Notification Settings</a></li>
            <li><a href="UserList.htm" >Users</a></li>
            <li><a href="SiteRequests.htm" >Requested Sites</a></li>
            <li><a href="ListSites.htm" >List All Sites</a></li>
            <li><a href="EmailScanner.htm" >Scan All Email</a></li>
            <li><a href="EmailTest.htm" >Test Email</a></li>
            <li><a href="BlockedEmail.htm" >Blocked Email</a></li>
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
            <li><a onclick='logOutPage()'>Log Out</a></li>
<% } %>
            <li><a href="<%=userRelPath%>UserSettings.htm">Profile</a></li>
            <li><a href="<%=userRelPath%>UserAlerts.htm">Updates</a></li>
            <li><a href="<%=userRelPath%>NotificationSettings.htm">Notifications</a></li>
            <li><a href="<%=userRelPath%>EmailListnerSettings.htm">Administration</a></li>
          </ul>
        </li>
      </ul>
    </div>
  </div>
</nav>



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
    console.log("Welcome message", info);
}


SLAP.initLogin(<% adminLoginConfig.write(out, 2, 2); %>, <% loginInfoPrefetch.write(out, 2, 2); %>, displayWelcomeMessage);
</script>
<!-- END WrapHeader2.jsp -->
<% out.flush(); %>
