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



<nav class="navbar navbar-expand-lg bg-primary-subtle p-2">
    <div class="container-fluid">
        <a id="navbar-brand" href="<%=userRelPath%>UserHome.htm" title="Weaver Home Page">
            <img src="<%=ar.retPath%>bits/weaver-logo-header.png"></a>
        <div class="collapse navbar-collapse mx-3">
            <ul class="navbar-nav">
                <li class="nav-item dropdown">
                    <a class="nav-link dropdown-toggle text-primary" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">Administration <span class="caret"></span></a>
                    <ul class="dropdown-menu">
                        <li><a class="dropdown-item" href="ErrorList.htm" >Error List</a></li>
                        <li><a class="dropdown-item" href="EmailListnerSettings.htm" >Listener Settings</a></li>
                        <li><a class="dropdown-item" href="NotificationStatus.htm" >Notification Settings</a></li>
                        <li><a class="dropdown-item" href="UserList.htm" >Users</a></li>
                        <li><a class="dropdown-item" href="SiteRequests.htm" >Requested Sites</a></li>
                        <li><a class="dropdown-item" href="ListSites.htm" >List All Sites</a></li>
                        <li><a class="dropdown-item" href="EstimateCosts.htm" >Estimate Site Costs</a></li>
                        <li><a class="dropdown-item" href="EmailScanner.htm" >Scan All Email</a></li>
                        <li><a class="dropdown-item" href="EmailTest.htm" >Test Email</a></li>
                        <li><a class="dropdown-item" href="BlockedEmail.htm" >Blocked Email</a></li>
                    </ul>
                </li>
            </ul>
            <ul class="navbar-nav ms-auto">
                <li class="nav-item dropdown">
                    <a href="#" class="nav-link dropdown-toggle text-primary" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false"><% ar.writeHtml(userName); %><span class="caret"></span>
                    </a>
                    <ul class="dropdown-menu">
<% if (uProf==null) { %>
                        <li><a class="dropdown-item" href="<%=ar.getSystemProperty("identityProvider")%>?openid.mode=quick&go=<%=URLEncoder.encode(currentPageURL, "UTF-8")%>">
                Log In</a></li>
<% } else { %>
                        <li><a class="dropdown-item" onclick='logOutPage()'>Log Out</a></li>
<% } %>
                        <li><a class="dropdown-item" class="dropdown-item" href="<%=userRelPath%>UserSettings.htm">Profile</a></li>
                        <li><a class="dropdown-item" href="<%=userRelPath%>UserAlerts.htm">Updates</a></li>
                        <li><a class="dropdown-item" href="<%=userRelPath%>NotificationSettings.htm">Notifications</a></li>
                        <li><a class="dropdown-item" href="<%=userRelPath%>EmailListnerSettings.htm">Administration</a></li>
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
