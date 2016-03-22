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
            mainSiteId = ngpi.pageBookKey;
            NGBook site = ar.getCogInstance().getSiteByIdOrFail(mainSiteId);
            mainSiteName = site.getFullName();
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
<style>
#newMasthead{
  height:66px;
  background-color:transparent;
}
</style>

<script>

    menuStruct = <%mainList.write(out,2,4);%>;
    
    function changePage(dest) {
        window.location = dest;
    }

</script>


<script type="text/javascript">
    var retPath ='<%=ar.retPath%>';
    var headerType = '<%=headerTypeStr%>';
    var book='';
    var pageId = '<%=pageId%>';
    var userKey = "<%=userKey%>";
    var isSuperAdmin = "<%=ar.isSuperAdmin()%>";
</script>

<script type="text/javascript" src="<%=ar.retPath%>jscript/ddlevelsmenu.js"></script>


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



    <!-- Begin siteMasthead -->
    <div id="newMasthead">
        <div id="consoleName">
           <%
            if(isUserHeader) {
                if(userRecord!=null){
                    String userName = userRecord.getName();
                    if(userName.length()>60){
                        userName=userName.substring(0,60)+"...";
                    }
                    ar.write("User: <span title=\"");
                    ar.writeHtml(userName);
                    ar.write("\">");
                    ar.writeHtml(userName);
                    ar.write("</span>");
                }
            }
            else if(isSiteHeader) {
                if(pageTitle!=null){
                    ar.write("Site: <span title=\"");
                    ar.writeHtml(pageTitle);
                    ar.write("\">");
                    ar.writeHtml(trncatePageTitle);
                    ar.write(deletedWarning);
                    ar.write("</span>");
                }
            }
            else {
                if(pageTitle!=null){
                    ar.write("Workspace: <span title=\"");
                    ar.writeHtml(pageTitle);
                    ar.write("\">");
                    ar.writeHtml(trncatePageTitle);
                    ar.write(deletedWarning);
                    ar.write("</span>");
                }
            }
            %>
           <% if(ngb!=null){ %>
           Site: <a href="<%=ar.retPath%>v/<%ar.writeURLData(ngb.getKey());%>/$/accountListProjects.htm"
                     title="View the Site for this page"><%ar.writeHtml(ngb.getFullName());%></a>

           <% } %>
        </div>
        <div id="globalLinkArea">
          <ul id="globalLinks">
                <%
                    if(ar.isLoggedIn())
                    {
                        uProf = ar.getUserProfile();
                %>
                        <li><a href="<%=ar.retPath%>v/<%ar.writeHtml(loggedKey);%>/watchedProjects.htm"
                                title="Workspaces for the logged in user">Workspaces</a></li>
                        <li>|</li>
                        <li><a href="<%=ar.retPath%>v/<%ar.writeHtml(loggedKey);%>/userAlerts.htm"
                                title="Updates for the logged in user">Updates</a></li>
                        <li>|</li>
                        <li><a href="<%=ar.retPath%>v/<%ar.writeHtml(loggedKey);%>/userActiveTasks.htm"
                                title="Actions the user needs to attend to">To Do</a></li>
                        <li>|</li>
                        <li><a href="<%=ar.retPath%>v/<%ar.writeHtml(loggedKey);%>/userProfile.htm?active=1"
                                title="Profile for the logged in user">Settings</a></li>
                        <%if(ar.isSuperAdmin()){ %>
                            <li>|</li>
                            <li><a href="<%=ar.retPath%>v/<%ar.writeHtml(loggedKey);%>/emailListnerSettings.htm" title="Administration">Administration</a></li>
                        <%} %>
                        <li>|</li>
                        <li class="text last"><a onclick="logOutProvider();">Log Out</a></li>
               <%
                  }
                  else
                  {
               %>
                        <li><a href="<%=ar.retPath%>"
                               title="Initial Introduction Page">Welcome Page</a></li>
                        <li>|</li>
                        <li class="text last">
                            <a href="<%=ar.getSystemProperty("identityProvider")%>?openid.mode=quick&go=<%=URLEncoder.encode(currentPageURL, "UTF-8")%>">Login</a>
                        </li>
               <%
                  }
               %>
            </ul>
            </div>
        <%
        if (ar.isLoggedIn())
        {
            UserProfile uProf1 = ar.getUserProfile();
            %>
            <div id="welcomeMessage">
                Welcome, <%uProf1.writeLink(ar); %>
            </div>
            <%
        }
        else
        {
            %>
            <div id="welcomeMessage">
                Browser compatibility or setting problem
            </div>
            <%
        }
        %>
    </div>
    <!-- End siteMasthead -->

    <!-- Begin mainNavigation -->

    <div>
    <div id="mainNavigationLeft" >
        <div id="mainNavigationCenter">
            <div id="mainNavigationRight">
            </div>
        </div>
        <div id="mainNavigation" style="height:100px">
            <ul id="tabs" >
             <div  class="btn-group" style="margin-left:15px">

                <button class="btn btn-default" style="background:transparent;" 
                onClick="changePage('<%=ar.retPath%>v/<%=loggedKey%>/UserHome.htm')">
                Home</button>
                <button class="btn btn-default" style="background:transparent;"
                onClick="changePage('<%=ar.retPath%>v/<%=loggedKey%>/watchedProjects.htm')">
                Workspaces</button>
                <button class="btn btn-default" style="background:transparent;"
                onClick="changePage('<%=ar.retPath%>v/<%=loggedKey%>/userAccounts.htm')">
                Sites</button>
                <button class="btn btn-default" style="background:transparent;"
                onClick="alert('Organization not implemented yet')">
                Organization</button>
                <button class="btn btn-default" style="background:transparent;"
                onClick="alert('Add not implemented yet')">Add</button>
                <button class="btn btn-default" style="background:transparent;"
                onClick="alert('Help not implemented yet')">Help</button>
                <input class="input" type="text" style="padding:3px;margin:3px"></input>
                <button class="btn btn-default" style="background:transparent;"
                onClick="changePage('<%=ar.retPath%>v/<%=loggedKey%>/searchAllNotes.htm')">Search</button>

             </div>
           </ul>
        </div>

    </div>
         <div  class="btn-group" style="margin-left:15px">

            
           <%
            if(isUserHeader) {
                if(userRecord!=null){
                    String userName = userRecord.getName();
                    if(userName.length()>60){
                        userName=userName.substring(0,60)+"...";
                    }
                    %><button class="btn" onClick="changePage('UserHome.htm')"><%ar.writeHtml(userName);%></button><%
                }%>
            <button class="btn btn-default" onClick="changePage('userActiveTasks.htm')">To Do</button>
            <button class="btn btn-default" onClick="alert('not sure what Topics should do')">Topics</button>
            <button class="btn btn-default" onClick="changePage('userSettings.htm')">Settings</button>
            <button class="btn btn-default" onClick="changePage('watchedProjects.htm')">Watched</button>
            <button class="btn btn-default" onClick="changePage('templates.htm')">Templates</button>
            <button class="btn btn-default" onClick="changePage('ownerProjects.htm')">Administered</button>
            <button class="btn btn-default" onClick="changePage('participantProjects.htm')">Participant</button>
            <button class="btn btn-default" onClick="changePage('allProjects.htm')">All</button>
                    <%
            }
            else if(isSiteHeader) {
                if(mainSiteName!=null){
                    %><button class="btn" onClick="changePage('accountListProjects.htm')"><%ar.writeHtml(mainSiteName);%></button><%
                }%>
            <button class="btn btn-default" onClick="changePage('accountListProjects.htm')">Workspaces in Site</button>
            <button class="btn btn-default" onClick="changePage('SiteAdmin.htm')">Site Admin</button>
                    <%
            }
            else {
                if(pageTitle!=null){
                    %><button class="btn" onClick="changePage('frontPage.htm')">
                    <%ar.writeHtml(trncatePageTitle);%></button><%
                }%>
            <button class="btn btn-default" onClick="changePage('meetingList.htm')">Meetings</button>
            <button class="btn btn-default" onClick="changePage('notesList.htm')">Topics</button>
            <button class="btn btn-default" onClick="changePage('listAttachments.htm')">Documents</button>
            <button class="btn btn-default" onClick="changePage('goalList.htm')">Action Items</button>
            <button class="btn btn-default" onClick="changePage('admin.htm')">Workspace Admin</button>
            <button class="btn btn-default" onClick="changePage('labelList.htm')">Labels</button>
            <button class="btn btn-default" onClick="changePage('roleManagement.htm')">Roles</button>
            <button class="btn btn-default" onClick="changePage('decisionList.htm')">Decisions</button>
            <button class="btn btn-default" onClick="changePage('personal.htm')">Personal</button>
                    <%
            }
            %>

         </div>
    </div>

<!-- End mainNavigation -->

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
