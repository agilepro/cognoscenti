<!DOCTYPE html>
<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
    long renderStart = System.currentTimeMillis();
    UserProfile loggedUser = ar.getUserProfile();
    
    String loggedKey = "";
    if (ar.isLoggedIn()) {
        loggedKey = loggedUser.getKey();
    }
    

    //this is the most important setting .. it is the name of the JSP file
    //that is being wrapped with a standard header and a footer.
    String wrappedJSP = ar.reqParam("wrappedJSP");
    String templateName = wrappedJSP+".jsp";
    int slashPos = wrappedJSP.lastIndexOf("/");
    String pageNiceTitle = wrappedJSP;
    if (slashPos>=0) {
        pageNiceTitle = wrappedJSP.substring(slashPos+1);
    }
    if ("FrontPage".equals(pageNiceTitle)) {
        pageNiceTitle = "Front Page";
    }
    else if ("MeetingList".equals(pageNiceTitle)) {
        pageNiceTitle = "Meetings";
    }
    else if ("NotesList".equals(pageNiceTitle)) {
        pageNiceTitle = "Topics";
    }
    else if ("ListAttachments".equals(pageNiceTitle)) {
        pageNiceTitle = "Documents";
    }
    else if ("GoalList".equals(pageNiceTitle)) {
        pageNiceTitle = "Action Items";
    }
    else if ("DecisionList".equals(pageNiceTitle)) {
        pageNiceTitle = "Decisions";
    }
    else if ("LabelList".equals(pageNiceTitle)) {
        pageNiceTitle = "Labels";
    }
    else if ("RoleManagement".equals(pageNiceTitle)) {
        pageNiceTitle = "Roles";
    }
    else if ("leaf_admin".equals(pageNiceTitle)) {
        pageNiceTitle = "Workspace Admin";
    }
    else if ("leaf_personal".equals(pageNiceTitle)) {
        pageNiceTitle = "Personal";
    }
    else if ("GoalEdit".equals(pageNiceTitle)) {
        pageNiceTitle = "Edit Action Item";
    }
    else if ("leaf_history".equals(pageNiceTitle)) {
        pageNiceTitle = "Activity Stream";
    }
    else if ("MeetingFull".equals(pageNiceTitle)) {
        pageNiceTitle = "Meeting Details";
    }
    else if ("accountListProjects".equals(pageNiceTitle)) {
        pageNiceTitle = "Workspaces in Site";
    }
    else if ("SiteAdmin".equals(pageNiceTitle)) {
        pageNiceTitle = "Site Admin";
    }
    else if ("NoteZoom".equals(pageNiceTitle)) {
        pageNiceTitle = "Discussion Topic";
    }
    else if ("docinfo".equals(pageNiceTitle)) {
        pageNiceTitle = "Access Document";
    }
    else if ("DocsRevise".equals(pageNiceTitle)) {
        pageNiceTitle = "Upload New Version";
    }
    else if ("editDetails".equals(pageNiceTitle)) {
        pageNiceTitle = "Edit Doc Details";
    }
    else if ("fileVersions".equals(pageNiceTitle)) {
        pageNiceTitle = "List Doc Versions";
    }
    else if ("UserAccounts".equals(pageNiceTitle)) {
        pageNiceTitle = "Sites You Manage";
    }
    else if ("leaf_accountRoleRequest".equals(pageNiceTitle)) {
        pageNiceTitle = "Site Role Request";
    }

    String title = ar.defParam("title", wrappedJSP);

    slashPos = title.lastIndexOf("/");
    if (slashPos>=0) {
        title = title.substring(slashPos+1);
    }
    String themePath = ar.getThemePath();
    Cognoscenti cog = ar.getCogInstance();


//pageTitle is a very strange variable.  It mostly is used to hold the value displayed
//just above the menu.  Usually "Workspace: My Workspace"   or "Site: my Site" or "User: Joe User"
//Essentially this depends upon the header type (workspace, site, or user).
//however the logic is quite convoluted in first detecting what header type it is, and then
//making sure that the right thing is in this value, and then truncating it sometimes.
    String pageTitle = (String)request.getAttribute("pageTitle");

//this indicates a user page
    String pageUserKey = (String)request.getAttribute("userKey");

//this indicates a workspace page
    String pageId = (String)request.getAttribute("pageId");

//this indicates a site id
    String bookId = (String)request.getAttribute("book");
//What is the difference beween bookid and accountid?  Account, Site, and Book at all the same thing.
//TODO: straighten this out to have only one.
//this also indicates a site id
    String accountId = (String)request.getAttribute("accountId");

//apparently this is calculated elsewhere and passed in.
    String viewingSelfStr = (String)request.getAttribute("viewingSelf");

//this is another hint as to the header type
    String headerTypeStr = (String)request.getAttribute("headerType");

    if (headerTypeStr==null) {
        headerTypeStr="user";
    }
    boolean isBlankHeader   = headerTypeStr.equals("blank");   //used for welcome page and error pages, no nav bar
    boolean isSiteHeader    = headerTypeStr.equals("site");
    boolean isUserHeader    = headerTypeStr.equals("user");
    boolean isProjectHeader = headerTypeStr.equals("project");
    boolean showExperimental= false;

    if (isSiteHeader) {
        if (bookId==null) {
            throw new Exception("Program Logic Error: need a site id passed to a site style header");
        }
    }
    else if (isUserHeader) {
        //can not test for presence of a user or not .... because unlogged in warning use this
        //probably need a special header type for warnings...like not logged in
    }
    else if (isProjectHeader) {
        if (pageId==null || "$".equals(pageId)) {
            throw new Exception("Program Logic Error: need a pageId passed to a workspace style header");
        }
    }
    else if (!isBlankHeader) {
        throw new Exception("don't understand header type: "+headerTypeStr);
    }

    File themeRoot = cog.getConfig().getFileFromRoot(ar.getThemePath());
    File themeDefault = cog.getConfig().getFileFromRoot("theme/blue/");
    String menuName = "menu4"+headerTypeStr+".json";
    File menuFile = new File(themeRoot, menuName);
    if (!menuFile.exists()) {
        menuFile = new File(themeDefault, menuName);
    }
    if (!menuFile.exists()) {
        throw new Exception("Can not find a menu file for: "+menuFile.toString());
    }


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
    UserProfile userPageUser = null;
    String pageUserName = "";
    if(isUserHeader && pageUserKey!=null){
        userPageUser = UserManager.getUserProfileByKey(pageUserKey);
        pageUserName = userPageUser.getName();
    }

//TODO: why test for pageTitle being null here?
    if(pageTitle == null && pageId != null && !"$".equals(pageId)){
        ngp  = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
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
    //this is the base path for the all of the menu options.
    //should not actually see any menu options if not logged in, however
    //need to give a value for this.
    String userRelPath = ar.retPath + "v/$/";
    String userName = "GUEST";
    if (loggedUser!=null) {
        userRelPath = ar.retPath + "v/"+loggedUser.getKey()+"/";
        userName = loggedUser.getName();
    }
    int exposeLevel = 1;
    if (ar.isSuperAdmin()) {
        exposeLevel = 2;
    }
    JSONObject loginInfo = new JSONObject();
    if (ar.isLoggedIn()) {
        loginInfo.put("userId", ar.getBestUserId());
        loginInfo.put("userName", loggedUser.getName());
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
    
<!-- BEGIN Wrapper.jsp Layout-->
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="Content-Language" content="en-us" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta http-equiv="imagetoolbar" content="no" />
    <meta name="viewport" content="user-scalable=no, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0" />

    <!-- INCLUDE the ANGULAR JS library -->
    <script src="<%=ar.baseURL%>jscript/angular.js"></script>
    <script src="<%=ar.baseURL%>jscript/ui-bootstrap-tpls.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/jquery.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/bootstrap.min.js"></script>

    <script src='<%=ar.baseURL%>jscript/tinymce/tinymce.min.js'></script>
    <script src='<%=ar.baseURL%>jscript/tinymce/tinymce-ng.js'></script>
    <script src="<%=ar.baseURL%>jscript/textAngular-sanitize.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/ng-tags-input.js"></script>

    <script src="<%=ar.baseURL%>jscript/slap.js"></script>
    <script src="<%=ar.baseURL%>jscript/common.js"></script>
    <!--script src="<%=ar.baseURL%>jfunc.js"></script-->
    <link href="<%=ar.baseURL%>jscript/bootstrap.min.css" rel="stylesheet">
    <link href="<%=ar.baseURL%>jscript/ng-tags-input.css" rel="stylesheet">

    <!-- Bootstrap Material Design -->
    <script src="<%=ar.baseURL%>jscript/bootstrap-material-design/ripples.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/bootstrap-material-design/material.min.js"></script>
    <link rel="stylesheet" href="<%=ar.baseURL%>css/bootstrap-material-design/bootstrap-material-design.min.css" media="screen">
    <link rel="stylesheet" href="<%=ar.baseURL%>css/bootstrap-material-design/ripples.min.css" media="screen">

	<!-- INCLUDE web fonts -->
    <link href="<%=ar.retPath%>assets/font-awesome/css/font-awesome.min.css" rel="stylesheet"
          data-semver="4.3.0" data-require="font-awesome@*" />
	   <link href="<%=ar.retPath%>assets/google/css/PT_Sans-Web.css" rel="stylesheet"/>

    <link href="<%=ar.retPath%>bits/main.min.css" rel="styleSheet" type="text/css" media="screen" />
    <link href="<%=ar.retPath%>bits/fixed-sidebar.min.css" rel="styleSheet" type="text/css" media="screen" />

    <title><% ar.writeHtml(title); %></title>

<script>
/* NEW UI TEMPPORARY SCRIPTS */
// TODO Remove this after removing the options dropdown
$(document).ready(function() {
    $('.rightDivContent').insertAfter('.title').css({float:'right','margin-right':0});
    $('.rightDivContent .dropdown-menu').addClass('pull-right');
    /* INIT Bootstrap Material Design */
    $.material.init();
});

/* INIT tinyMCE */
tinyMCE.PluginManager.add('stylebuttons', function(editor, url) {
  ['p', 'h1', 'h2', 'h3'].forEach(function(name){
   editor.addButton("style-" + name, {
       tooltip: "Toggle " + name,
         text: name.toUpperCase(),
         onClick: function() { editor.execCommand('mceToggleFormat', false, name); },
         onPostRender: function() {
             var self = this, setup = function() {
                 editor.formatter.formatChanged(name, function(state) {
                     self.active(state);
                 });
             };
             editor.formatter ? setup() : editor.on('init', setup);
         }
     })
  });
});

function standardTinyMCEOptions() {
    return {
		handle_event_callback: function (e) {
		// put logic here for keypress
		},
        plugins: "link,stylebuttons",
        inline: false,
        menubar: false,
        body_class: 'leafContent',
        statusbar: false,
        toolbar: "style-p, style-h1, style-h2, style-h3, bullist, outdent, indent | bold, italic, link |  cut, copy, paste, undo, redo",
        target_list: false,
        link_title: false
	};
}
 </script>


</head>
<body>
  <div class="bodyWrapper">

<!-- Begin AppBar -->
<%@ include file="AppBar.jsp" %>
<!-- End AppBar -->


<div class="container-fluid">
  <div class="row">

    <!-- Begin SideBar  -->
    <div class="col-sm-3 col-lg-2">
      <%@ include file="SideBar.jsp" %>
    </div>
    <!-- End SideBar -->

    <!-- Begin mainContent -->
    <div class="col-sm-9 col-lg-10 main-content">

      <!-- BEGIN Title and Breadcrump -->
      <ol class="title">
      <% if(isUserHeader) { %>
        <li class="page-name"><h1><a href="<%=ar.retPath%>v/<%=pageUserKey%>/userSettings.htm"><% ar.writeHtml(pageUserName); %></a></h1></li>
      <% } else if(isSiteHeader) { %>
      <li class="page-name"><h1><a href="<%=ar.retPath%>v/<%ar.writeURLData(accountKey);%>/$/accountListProjects.htm">
            <%ar.writeHtml(title);%></a></h1></li>
      <% } else { %>
        <li class="link"><a href="<%=ar.retPath%>v/<%ar.writeURLData(ngb.getKey());%>/$/accountListProjects.htm"><%ar.writeHtml(ngb.getFullName());%></a></li>
        <li class="link"><a href="<%=ar.retPath%>v/<%ar.writeURLData(ngb.getKey());%>/<%ar.writeURLData(ngp.getKey());%>/frontPage.htm">
            <%ar.writeHtml(ngp.getFullName());%></a></li>
      <% } %>
        <li class="page-name"><h1><% ar.writeHtml(pageNiceTitle); %></h1></li>
      </ol>
      <!-- BEGIN Title and Breadcrump -->

      <!-- Welcome Message -->
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
                  +'&go='+window.location+'"><span class="btn btn-primary">Login</span></a>';
          }
          else if (!info.userName) {
              y.innerHTML = 'Not logged in, please <a href="'
                  +loginConfig.providerUrl
                  +'?openid.mode=quick&go='+window.location+'"><span class="btn btn-primary">Login</span></a>';
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

      <!-- Begin Template Content (compiled separately) -->
      <jsp:include page="<%=templateName%>" />
      <!-- End Template Content (compiled separately) -->
    </div>
  </div>
</div>
<!-- End mainContent -->

</div>
<!-- End body wrapper -->
</body>
</html>

<!-- END Wrapper.jsp Layout - - <%= (System.currentTimeMillis()-renderStart) %> ms -->
