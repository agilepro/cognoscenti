<!-- BEGIN slimHeader.jsp -->
<%!
/*

Parameter used :

    1. pageTitle    : Used to retrieve the page title from request.
    2. userKey      : This is Key of user who is logged in.
    3. pageId       : Id of a Workspace, used to fetch details of Workspace (NGPage).
    4. book         : This is key of a site, used here to get details of an Site (NGBook).
    5. viewingSelf  : This parameter is used to check if user is viewing himself/herself or other profile.
    6. headerType   : Used to check the header type whether it is from site, workspace or user on the basis of
                      it corrosponding tabs are displayed
    7. accountId    : This is key of a site, used here to get details of an Site (NGBook).

*/

    String go="";

%><%





//We always POST to an address that consumes the data, and then redirects to a display page,
//so the display page (like this one) should never experience a POST request
    ar.assertNotPost();

//TODO: determine what this does.
    String deletedWarning = "";

    NGContainer ngp =null;
    NGBook ngb=null;
    UserProfile userRecord = null;

//TODO: why test for pageTitle being null here?
    if(pageTitle == null && pageId != null){
        ngp  = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    }
    if(isUserHeader && userKey!=null){
        userRecord = UserManager.getUserProfileByKey(userKey);
    }


    if (ngp!=null)
    {
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
        if (ngp.isDeleted())
        {
            deletedWarning = "<img src=\""+ar.retPath+"deletedLink.gif\"> (DELETED)";
        }
        else if (ngp.isFrozen())
        {
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
<script>

    menuStruct = <%mainList.write(out,2,4);%>;

    function buildMainMenuBar(newStyleTabs){

        for(var j=0;j<newStyleTabs.length ;j++){

            var oneTab = newStyleTabs[j];
            if (oneTab.level><%=exposeLevel%>) {
                continue;
            }

            var subs=oneTab.subs;
            for(var  i=0;i<subs.length ;i++){
                var oneSub = subs[i];
                if (oneSub.experiment) {
                    if (<%=!showExperimental%>) {
                        continue;
                    }
                }
                var mainElement = document.getElementById(oneTab.ref);
                var newli= document.createElement('li');
                var newlink = document.createElement('a');
                var newspan = document.createElement('span');
                newlink.setAttribute('href',oneSub.href);
                newlink.setAttribute('href',oneSub.href);
                newspan.innerHTML=oneSub.name;
                newlink.appendChild(newspan);
                newli.appendChild(newlink);
                mainElement.appendChild(newli);
            }
        }

        var mainElement = document.getElementById("tabs");

        for(var  i=0;i<newStyleTabs.length ;i++){

            var oneTab = newStyleTabs[i];
            if (oneTab.level><%=exposeLevel%>) {
                continue;
            }

            var newli   = document.createElement('li');
            var newlink = document.createElement('a');

            var newspan = document.createElement('span');

            newlink.setAttribute('href',oneTab.href);
            newlink.setAttribute('rel',oneTab.ref);

            if(i==0){
                newli.className = 'mainNavLink1';
            }

            newspan.innerHTML=oneTab.name;

            newlink.appendChild(newspan);
            newli.appendChild(newlink);
            mainElement.appendChild(newli);

        }

        //TODO: convert to an Angular approach
        ddlevelsmenu.setup("tabs", "topbar");
    }

</script>


<script type="text/javascript">
    var retPath ='<%=ar.retPath%>';
    var headerType = '';
    var book='';
    var pageId = '';
</script>

<script type="text/javascript" src="<%=ar.retPath%>jscript/ddlevelsmenu.js"></script>


<% if (!isSiteHeader) { %>
    <script>
        headerType = "<%=headerTypeStr%>";
        var userKey = "<%=userKey%>";
        var isSuperAdmin = "<%=ar.isSuperAdmin()%>";
        <% if (pageId != null && bookId != null) { %>
          pageId='<%=pageId%>';
          book='<%=bookId%>';
        <% } %>
    </script>

<% } else if(isSiteHeader){ %>
     <script>
        headerType = "<%=headerTypeStr%>";
        var userKey = "<%=userKey%>";

        <% if(accountId != null){ %>
        var accountId='<%=accountId %>';
        <% } else if(pageId!=null){ %>
        var accountId='<%=pageId%>';
        <% } %>
     </script>
<% } %>



    <!-- Begin siteMasthead -->
    <div id="siteMasthead">
        <img id="logoInterstage" src="<%=ar.retPath%><%=ar.getThemePath()%>logo.gif" alt="Logo" width="145" height="38" />
        <div id="consoleName">
           <% if(ngb!=null){ %>
           Site: <a href="<%=ar.retPath%>v/<%ar.writeURLData(ngb.getKey());%>/$/accountListProjects.htm"
                     title="View the Site for this page"><%ar.writeHtml(ngb.getFullName());%></a>

           <% } %>
           <br />
           <%
            if(isUserHeader) {
                if(userRecord!=null){
                    String userName = userRecord.getName();
                    if(userName.length()>60){
                        userName=userName.substring(0,60)+"...";
                    }
                    ar.write("User: <span title=\"");
                    ar.write(userName);
                    ar.write("\">");
                    ar.writeHtml(userName);
                    ar.write("</span>");
                }
            }
            else if(isSiteHeader) {
                if(pageTitle!=null){
                    ar.write("Site: <span title=\"");
                    ar.write(pageTitle);
                    ar.write("\">");
                    ar.writeHtml(trncatePageTitle);
                    ar.write(deletedWarning);
                    ar.write("</span>");
                }
            }
            else {
                if(pageTitle!=null){
                    ar.write("Workspace: <span title=\"");
                    ar.write(pageTitle);
                    ar.write("\">");
                    ar.writeHtml(trncatePageTitle);
                    ar.write(deletedWarning);
                    ar.write("</span>");
                }
            }
            %>
        </div>
        <div id="globalLinkArea">
          <ul id="globalLinks">
                <%
                    if(ar.isLoggedIn())
                    {
                        uProf = ar.getUserProfile();
                %>
                        <li><a href="<%=ar.retPath%>v/<%ar.writeHtml(uProf.getKey());%>/watchedProjects.htm"
                                title="Workspaces for the logged in user">Workspaces</a></li>
                        <li>|</li>
                        <li><a href="<%=ar.retPath%>v/<%ar.writeHtml(uProf.getKey());%>/userAlerts.htm"
                                title="Updates for the logged in user">Updates</a></li>
                        <li>|</li>
                        <li><a href="<%=ar.retPath%>v/<%ar.writeHtml(uProf.getKey());%>/userActiveTasks.htm"
                                title="Actions the user needs to attend to">To Do</a></li>
                        <li>|</li>
                        <li><a href="<%=ar.retPath%>v/<%ar.writeHtml(uProf.getKey());%>/userProfile.htm?active=1"
                                title="Profile for the logged in user">Settings</a></li>
                        <%if(ar.isSuperAdmin()){ %>
                            <li>|</li>
                            <li><a href="<%=ar.retPath%>v/<%ar.writeHtml(uProf.getKey());%>/emailListnerSettings.htm" title="Administration">Administration</a></li>
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
    <div id="mainNavigationLeft">
        <div id="mainNavigationCenter">
            <div id="mainNavigationRight">
            </div>
        </div>
        <div id="mainNavigation">

            <ul id="tabs">

            </ul>
        </div>

        <!--Top Drop Down Menu for workspace section HTML Starts Here -->
            <ul id="ddsubmenu1" class="ddsubmenustyle"></ul>
            <ul id="ddsubmenu2" class="ddsubmenustyle"></ul>
            <ul id="ddsubmenu3" class="ddsubmenustyle"></ul>
            <ul id="ddsubmenu4" class="ddsubmenustyle"></ul>
            <ul id="ddsubmenu5" class="ddsubmenustyle"></ul>
            <ul id="ddsubmenu6" class="ddsubmenustyle"></ul>

    </div>

<script>
   buildMainMenuBar(menuStruct);
</script>

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
<!-- END slimHeader.jsp -->
<% out.flush(); %>
