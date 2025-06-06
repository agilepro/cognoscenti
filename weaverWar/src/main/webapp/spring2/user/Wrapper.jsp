<!DOCTYPE html>
<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%
    long renderStart = System.currentTimeMillis();
    UserProfile loggedUser = ar.getUserProfile();
    ar.assertLoggedIn("user pages should be seen only while logged in");
    
    
    String loggedKey = loggedUser.getKey();


    //this is the most important setting .. it is the name of the JSP file
    //that is being wrapped with a standard header and a footer.
    String wrappedJSP = ar.reqParam("wrappedJSP");

    String title = ar.defParam("title", wrappedJSP);

    int slashPos = title.lastIndexOf("/");
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
    if (pageUserKey==null) {
        throw new Exception("User page does not have a user key");
    }

//this indicates a workspace page
    String siteId = (String)request.getAttribute("siteId");

//this also indicates a site id
    String accountId = (String)request.getAttribute("siteId");

//apparently this is calculated elsewhere and passed in.
    String viewingSelfStr = (String)request.getAttribute("viewingSelf");


//We always POST to an address that consumes the data, and then redirects to a display page,
//so the display page (like this one) should never experience a POST request
    ar.assertNotPost();

    UserProfile userPageUser = UserManager.getUserProfileByKey(pageUserKey);
    String pageUserName = userPageUser.getName();

    //this is the base path for the all of the menu options.
    //should not actually see any menu options if not logged in, however
    //need to give a value for this.
    String userRelPath = ar.retPath + "v/"+loggedUser.getKey()+"/";
    String userName = loggedUser.getName();
    

    JSONObject loginInfoPrefetch = new JSONObject();
    loginInfoPrefetch.put("userId", ar.getBestUserId());
    loginInfoPrefetch.put("userName", loggedUser.getName());
    loginInfoPrefetch.put("verified", true);
    loginInfoPrefetch.put("msg", "Previously logged into server");

    
    JSONObject loginConfigSetup = new JSONObject();
    loginConfigSetup.put("providerUrl", ar.getSystemProperty("identityProvider"));
    loginConfigSetup.put("serverUrl",   ar.baseURL);

    String currentPageURL = ar.getCompleteURL();

    %>

<!-- BEGIN Wrapper.jsp Layout wrapping (<%=wrappedJSP%>) -->
<html lang="en">
<head>
    <link rel="shortcut icon" href="<%=ar.baseURL%>bits/favicon.ico" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="Content-Language" content="en-us" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta http-equiv="imagetoolbar" content="no" />
    <meta name="viewport" content="user-scalable=no, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0" />
    <meta name="google-signin-client_id" content="866856018924-boo9af1565ijlrsd0760b10lqdqlorkg.apps.googleusercontent.com">
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <!-- INCLUDE the ANGULAR JS library -->
    <script src="<%=ar.baseURL%>new_assets/jscript/angular.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/angular-translate.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/ui-bootstrap-tpls.min.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/jquery.min.js"></script>
      <script src="<%=ar.baseURL%>spring2\node_modules\@popperjs\core\dist\umd\popper.min.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/bootstrap.min.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/slap.js"></script>
    <link
    rel="stylesheet" 
    href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"
    />

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

  <!-- Bootstrap 5.3.3-->

    <!-- Date and Time Picker -->

    <link rel="stylesheet" href="<%=ar.retPath%>new_assets/bits/angularjs-datetime-picker.css" />
    <script src="<%=ar.retPath%>new_assets/bits/angularjs-datetime-picker.js"></script>
    <script src="<%=ar.retPath%>new_assets/bits/moment.js"></script>
    <link rel="stylesheet" href="<%=ar.retPath%>new_assets/css/bootstrap.min.css" />
    <link rel="stylesheet" href="<%=ar.retPath%>new_assets/css/weaver.min.css" />
    <script>  moment().format(); </script>

    

 
    <title><% ar.writeHtml(title); %></title>

<script>
// TODO Remove this after removing the options dropdown
$(document).ready(function() {
    $('.rightDivContent').insertAfter('.title').css({float:'right','margin-right':0});
    $('.rightDivContent .dropdown-menu').addClass('pull-right');
    /* INIT Bootstrap Material Design */
    //$.material.init();
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
myApp.filter('wiki', function() {
  return function(x) {
    return convertMarkdownToHtml(x);
  };
});
function setMainPageTitle(str) {
  document.title = str;
}
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

 </script>


</head>
<body ng-app="myApp" ng-controller="myCtrl">
  <div class="bodyWrapper">

<!-- Begin AppBar -->
<%@ include file="AppBar.jsp" %>
<!-- End AppBar -->
<div class="container-fluid px-0" ng-cloak>
  <div class="row">
      <!--Sidebar Column -->
      <div class="d-flex">
        <%@ include file="SideBar_new.jsp" %>


    <!-- Begin mainContent -->
    <div class="col-10 col-lg-11 main-content">

      <!-- BEGIN Title and Breadcrumbs -->

      <nav aria-label="Breadcrumb">
      <ol class="breadcrumb px-3">
        <li class="breadcrumb-item"><a href="<%=ar.retPath%>v/<%=pageUserKey%>/UserSettings.htm">
            User: <% ar.writeHtml(pageUserName); %></a></li>
            &nbsp; &gt; &nbsp;
        
        </ol>
        </nav>
      
      <!-- Welcome Message -->
      <div id="welcomeMessage"></div>




<h1 class="page-name px-3" id="mainPageTitle"></h1>
      <!-- Begin Template Content (compiled separately) -->
      <jsp:include page="<%=wrappedJSP%>" />
      <!-- End Template Content (compiled separately) -->
      
        

      <% if(ar.isSuperAdmin()) { %>

        <hr/>
        <div class="well" style="margin:20px">
        <button ng-click="fakeError()">Cause Error</button> (This test function only appears for super administrators :-)
        </div>
      <% } %>
      
    </div>
  </div>


</div>
<!-- End mainContent -->




</div>
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


</body>
</html>

<!-- END Wrapper.jsp Layout - - <%= (System.currentTimeMillis()-renderStart) %> ms -->
