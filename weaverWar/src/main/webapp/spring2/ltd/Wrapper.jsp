<!DOCTYPE html>
<%@ page language="java" contentType="text/html;charset=UTF-8" pageEncoding="UTF-8"
%><%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"

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
    int slashPos = wrappedJSP.lastIndexOf("/");


    String title = ar.defParam("title", wrappedJSP);

    slashPos = title.lastIndexOf("/");
    if (slashPos>=0) {
        title = title.substring(slashPos+1);
    }

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
    String siteId = (String)request.getAttribute("siteId");

//this also indicates a site id
    String accountId = (String)request.getAttribute("siteId");

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
        if (siteId==null) {
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


//We always POST to an address that consumes the data, and then redirects to a display page,
//so the display page (like this one) should never experience a POST request
    if (!"DisplayException.jsp".equals(wrappedJSP)) {
        ar.assertNotPost();
    }

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
    UserProfile userPageUser = null;
    String pageUserName = "";
    if(isUserHeader && pageUserKey!=null){
        userPageUser = UserManager.getUserProfileByKey(pageUserKey);
        if (userPageUser!=null) {
            pageUserName = userPageUser.getName();
        }
    }

//TODO: why test for pageTitle being null here?
    if(pageTitle == null && pageId != null && !"$".equals(pageId)){
        ngp  = ar.getCogInstance().getWSBySiteAndKey(siteId, pageId).getWorkspace();
    }


    boolean isFrozen=false;
    boolean isDeleted=false;    
    if (ngp!=null) {
        ar.setPageAccessLevels(ngp);
        pageTitle = ngp.getFullName();
        if(ngp instanceof NGWorkspace) {
            ngb = ((NGWorkspace)ngp).getSite();
            showExperimental = ngb.getShowExperimental();
            if (loggedUser!=null) {
                ((NGWorkspace)ngp).registerJoining(loggedUser);
            }
        }
        else if(ngp instanceof NGBook) {
            ngb = ((NGBook)ngp);
            showExperimental = ngb.getShowExperimental();
        }
        if (ngp.isDeleted()) {
            isDeleted = true;
            deletedWarning = "<img src=\""+ar.retPath+"deletedLink.gif\"> (DELETED)";
        }
        else if (ngp.isFrozen()) {
            isFrozen=true;
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

    JSONObject loginInfoPrefetch = new JSONObject();
    if (ar.isLoggedIn()) {
        loginInfoPrefetch.put("userId", ar.getBestUserId());
        loginInfoPrefetch.put("userName", loggedUser.getName());
        loginInfoPrefetch.put("verified", true);
        loginInfoPrefetch.put("msg", "Previously logged into server");
    }
    else {
        //use this to indicate the very first display, before the page knows anything
        loginInfoPrefetch.put("haveNotCheckedYet", true);
    }

    
    JSONObject loginConfigSetup = new JSONObject();
    loginConfigSetup.put("providerUrl", ar.getSystemProperty("identityProvider"));
    loginConfigSetup.put("serverUrl",   ar.baseURL);

    String currentPageURL = ar.getCompleteURL();

    %>

<!-- BEGIN Wrapper.jsp Layout wrapping (jsp/<%=wrappedJSP%>) -->
<html lang="en">
<head>
    <link rel="shortcut icon" href="<%=ar.baseURL%>bits/favicon.ico" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="Content-Language" content="en-us" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta http-equiv="imagetoolbar" content="no" />
    <meta name="google-signin-client_id" content="866856018924-boo9af1565ijlrsd0760b10lqdqlorkg.apps.googleusercontent.com">
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <!-- INCLUDE the ANGULAR JS library -->
    <script src="<%=ar.baseURL%>new_assets/jscript/angular.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/angular-translate.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/ui-bootstrap-tpls.min.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/jquery-3.6.0.min.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/bootstrap.min.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/slap.js"></script>
    
    <link
    rel="stylesheet"
    href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"/>

    <script src='<%=ar.baseURL%>new_assets/jscript/tinymce/tinymce.min.js'></script>
    <script src='<%=ar.baseURL%>new_assets/jscript/tinymce/tinymce-ng.js'></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/textAngular-sanitize.min.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/ng-tags-input.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/MarkdownToHtml.js"></script>
    <script src="<%=ar.retPath%>new_assets/jscript/HtmlParser.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/TextMerger.js"></script>
    <script src="<%=ar.retPath%>new_assets/jscript/HtmlToMarkdown.js"></script>

    <script src="<%=ar.baseURL%>new_assets/jscript/common.js"></script>
    <link href="<%=ar.baseURL%>new_assets/jscript/ng-tags-input.css" rel="stylesheet">

    <!-- INCLUDE web fonts for icons -->
    <link href="<%=ar.retPath%>new_assets/assets/font-awesome/css/font-awesome.min.css" rel="stylesheet"
          data-semver="4.3.0" data-require="font-awesome@*" />
    <link href="<%=ar.retPath%>new_assets/assets/google/css/PT_Sans-Web.css" rel="stylesheet"/>

        

    <!-- Date and Time Picker -->

    <link rel="stylesheet" href="<%=ar.retPath%>new_assets/bits/angularjs-datetime-picker.css" />
    <script src="<%=ar.retPath%>new_assets/bits/angularjs-datetime-picker.js"></script>
    <script src="<%=ar.retPath%>new_assets/bits/moment.js"></script>
    <script>  moment().format(); </script>
    
    <!-- Bootstrap 5.0-->
    <link rel="stylesheet" href="<%=ar.retPath%>new_assets/css/bootstrap.min.css" />
    <link rel="stylesheet" href="<%=ar.retPath%>new_assets/css/weaver.min.css" />
    

 
    <title><% ar.writeHtml(title); %></title>

<script>
/* NEW UI TEMPPORARY SCRIPTS */
// TODO Remove this after removing the options dropdown
$(document).ready(function() {
    $('.rightDivContent').insertAfter('.title').css({float:'right','margin-right':0});
    $('.rightDivContent .dropdown-menu').addClass('pull-right');
    /* INIT Bootstrap Material Design */
   // $.material.init();
});

//Must initialize the app with all the right packages here, before the 
//individual pages create the controls
var myApp = angular.module('myApp', ['ui.bootstrap','ngTagsInput','ui.tinymce','angularjs-datetime-picker','pascalprecht.translate', 'ngSanitize']);

myApp.filter('cdate', function() {
  return function(x) {
    if (!x || x<10000000) {
        return "Not Set";
    }
    let diff = new Date().getTime() - x;
    if (diff>860000000 || diff<-860000000) {
        return moment(x).format("DD-MMM-YYYY");
    }
    return moment(x).format("DD-MMM @ HH:mm");
  };
});
myApp.filter('encode', function() {
  return window.encodeURIComponent;
});
myApp.filter('wiki', function() {
  return function(x) {
    return convertMarkdownToHtml(x);
  };
});

function setUpLearningMethods($scope, $modal, $http) {
    // learning path is not used on Limited pages
}
 </script>



</head>
<body ng-app="myApp" ng-controller="myCtrl" <% if(isFrozen) {%>class="bodyFrozen"<%}%> <% if(isDeleted) {%>class="bodyDeleted"<%}%>>
  <div class="bodyWrapper">

<!-- Begin AppBar -->
<%@ include file="AppBar.jsp" %>
<!-- End AppBar -->


<div class="container-fluid px-0" ng-cloak>
    <div class="row">

    <!-- Begin SideBar  -->
    <div class="d-flex">
      <%@ include file="SideBar.jsp" %>

    <!-- End SideBar -->

    <!-- Begin mainContent -->
    <div class="col-10 col-lg-11 main-content">

      <!-- BEGIN Title and Breadcrumb -->
      <nav aria-label="Breadcrumb">
        <ol class="breadcrumb px-3">
      <% if(!ar.isLoggedIn()) { %>
          <!-- user is not logged in, don't display any breadcrumbs -->
      <% } else if(isUserHeader) { %>

        <li class="breadcrumb-item"><a href="<%=ar.retPath%>v/<%=pageUserKey%>/UserSettings.htm">
            User: <% ar.writeHtml(pageUserName); %></a></li>
      <% } else if(isSiteHeader) { %>

      <li class="breadcrumb-item"><a href="<%=ar.retPath%>v/<%ar.writeURLData(accountKey);%>/$/SiteWorkspaces.htm">
            Site: '<%ar.writeHtml(mainSiteName);%>'</a></li>
      <% } else { %>

        <li class="breadcrumb-item"><a href="<%=ar.retPath%>v/<%ar.writeURLData(ngb.getKey());%>/$/SiteWorkspaces.htm"><%ar.writeHtml(ngb.getFullName());%></a></li>
        <li class="breadcrumb-item"><a href="<%=ar.retPath%>v/<%ar.writeURLData(ngb.getKey());%>/<%ar.writeURLData(ngp.getKey());%>/FrontPage.htm">
            <%ar.writeHtml(ngp.getFullName());%></a>
                <span style="color:gray">
                <%if (ngp.isDeleted()) {ar.write(" (DELETED) ");}
                  else if (ngp.isFrozen()) {ar.write(" (FROZEN) ");}%>
                </span>
            </li>
      <% } %>
        
      </ol>
      </nav>
      <script>
      function setMainPageTitle(str) {
          document.title = str + " - <%if (ngp!=null) { ar.writeJS(ngp.getFullName()); }%>";
      }
      </script>
      

      <!-- Welcome Message -->
      <div id="welcomeMessage"></div>


      <script>



      var knowWeAreLoggedIn = <%= ar.isLoggedIn() %>;
      function displayWelcomeMessagexx(info) {
          console.log('LOGGED IN', info);
      }
      function displayWelcomeMessage(info) {
          //console.log("WELCOME:", knowWeAreLoggedIn, info)
          var y = document.getElementById("welcomeMessage");
          if (knowWeAreLoggedIn && info.verified) {
              //nothing to do in this case
          }
          else if (knowWeAreLoggedIn && !info.verified) {
              //this encountered only when logging out
              //alert("Reloading because knowWeAreLoggedIn="+knowWeAreLoggedIn+" && info.verified="+info.verified);
              window.location.reload(true);
          }
          else if (!knowWeAreLoggedIn && info.verified) {
              //this encountered only when logging out
              
              //alert("Reloading because knowWeAreLoggedIn="+knowWeAreLoggedIn+" && info.verified="+info.verified);
              window.location.reload(true);
          }
          else if (info.haveNotCheckedYet) {
              y.innerHTML = 'Checking identity, please <a href="'
                  +SLAP.loginConfig.providerUrl
                  +'&go='+window.location+'"><span class="btn btn-primary btn-raised">Login</span></a>';
          }
          else if (!info.userId) {
              y.innerHTML = 'Not logged in, please <a href="'
                  +SLAP.loginConfig.providerUrl
                  +'?openid.mode=quick&go='+window.location+'"><span class="btn btn-primary btn-raised">Login</span></a>';
          }
          else if (!info.verified) {
              y.innerHTML = 'Hello <b>'+info.userName+'</b>.  Attempting Automatic Login.';
          }
          else {
              y.innerHTML = 'Hello <b>'+info.userName+'</b>.  You are now logged in.  Refreshing page.';
              window.location.reload();
          }
      }

      SLAP.initLogin(<% loginConfigSetup.write(out, 2, 2); %>, <% loginInfoPrefetch.write(out, 2, 2); %>, displayWelcomeMessage);
      console.log("WELCOME INIT:", knowWeAreLoggedIn);
      </script>



<h1 class="px-3 page-name" id="mainPageTitle"></h1>
      <!-- Begin Template Content (compiled separately) -->
      <jsp:include page="<%=wrappedJSP%>" />
      <!-- End Template Content (compiled separately) -->
    </div>
  </div>
</div>
<!-- End mainContent -->


<!-- End body wrapper -->

<script>
//every 25 minutes, query the server to keep session alive
window.setInterval(function() {
    if (!SLAP.loginInfo.verified) {
        console.log("Not logged in, no session.");
    }
    else {
        console.log("Keeping the session alive for: "+SLAP.loginInfo.userName+" ("+SLAP.loginInfo.userId+").");
        SLAP.queryTheServer();
    }
    return 0;
}, 1500000);

</script>

<script src="<%=ar.baseURL%>new_assets/jscript/translation.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/LearningEditModal.js"></script>
<script src="<%=ar.retPath%>new_assets/jscript/AllPeople.js"></script>
<script src="<%=ar.retPath%>new_assets/jscript/HtmlToMarkdown.js"></script>
<script src="<%=ar.retPath%>new_assets/jscript/HtmlParser.js"></script>
<script src="<%=ar.baseURL%>new_assets/jscript/TextMerger.js"></script>
<script src="<%=ar.retPath%>new_assets/jscript/SimultaneousEdit.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/AttachActionCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/AttachDocumentCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/DecisionModal.js"></script>
</body>
</html>

<!-- END Wrapper.jsp Layout - - <%= (System.currentTimeMillis()-renderStart) %> ms -->
