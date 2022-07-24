<!DOCTYPE html>
<%@page errorPage="/spring/anon/Error.jsp"
%><%@ include file="/spring/anon/include.jsp"
%><%
    String title = "sss";
    NGWorkspace ngw =null;
    NGBook ngb=null;
    Cognoscenti cog=null;
    
    String wrappedJSP = ar.reqParam("wrappedJSP"); 
    cog = ar.getCogInstance();
    String pageId = (String)request.getAttribute("pageId");
    String siteId = (String)request.getAttribute("siteId");
    if (pageId!=null  && !"$".equals(pageId)) {
        ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
        if (ngw!=null) {
            ngb = ngw.getSite();
        }
    }
    else if (siteId!=null) {
        ngb = cog.getSiteById(siteId);
    }
    
    
    JSONObject loginInfoPrefetch = new JSONObject();
    if (ar.isLoggedIn()) {
        loginInfoPrefetch.put("userId", ar.getBestUserId());
        loginInfoPrefetch.put("userName", ar.getUserProfile().getName());
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
    
    boolean expectedLoginState = ar.isLoggedIn();


%>

<!-- BEGIN Wrapper.jsp Layout wrapping (<%=wrappedJSP%>) -->  
<html>
<head>
    <link rel="shortcut icon" href="<%=ar.baseURL%>bits/favicon.ico" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="Content-Language" content="en-us" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta http-equiv="imagetoolbar" content="no" />
    <meta name="viewport" content="user-scalable=no, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0" />
    <meta name="google-signin-client_id" content="866856018924-boo9af1565ijlrsd0760b10lqdqlorkg.apps.googleusercontent.com">

    <!-- INCLUDE the ANGULAR JS library -->
    <script src="<%=ar.baseURL%>jscript/angular.js"></script>
    <script src="<%=ar.baseURL%>jscript/angular-translate.js"></script>
    <script src="<%=ar.baseURL%>jscript/ui-bootstrap-tpls.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/jquery.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/bootstrap.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/slap.js"></script>
    <link href="<%=ar.baseURL%>jscript/bootstrap.min.css" rel="stylesheet">

    <script src='<%=ar.baseURL%>jscript/tinymce/tinymce.min.js'></script>
    <script src='<%=ar.baseURL%>jscript/tinymce/tinymce-ng.js'></script>
    <script src="<%=ar.baseURL%>jscript/textAngular-sanitize.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/ng-tags-input.js"></script>
    <script src="<%=ar.baseURL%>jscript/MarkdownToHtml.js"></script>
    <script src="<%=ar.retPath%>jscript/HtmlParser.js"></script>
    <script src="<%=ar.baseURL%>jscript/TextMerger.js"></script>
    <script src="<%=ar.retPath%>jscript/HtmlToMarkdown.js"></script>


    <script src="<%=ar.baseURL%>jscript/common.js"></script>
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

    <link href="<%=ar.retPath%>bits/fixed-sidebar.min.css" rel="styleSheet" type="text/css" media="screen" />

    <!-- Date and Time Picker -->
    <link rel="stylesheet" href="<%=ar.retPath%>bits/angularjs-datetime-picker.css" />
    <script src="<%=ar.retPath%>bits/angularjs-datetime-picker.js"></script>
    <script src="<%=ar.retPath%>bits/moment.js"></script>
    <script>  moment().format(); </script>

    <!-- Weaver specific tweaks -->
    <link href="<%=ar.retPath%>bits/main.min.css" rel="styleSheet" type="text/css" media="screen" />

 
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

//Must initialize the app with all the right packages here, before the 
//individual pages create the controlles
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

function reloadIfLoggedIn(info) {
    //the deal is: this Wrapper.jsp is designed for people who are not logged in
    //but if we ever discover we are logged in, we need to refresh to get the new display.
    if (SLAP.loginInfo.verified && !<%=expectedLoginState%>) {
        window.location = "<%= ar.getCompleteURL() %>";
    }
}
SLAP.initLogin(<% loginConfigSetup.write(out, 2, 2); %>, <% loginInfoPrefetch.write(out, 2, 2); %>, reloadIfLoggedIn);

function setMainPageTitle(str) {
    document.getElementById("mainPageTitle").innerHTML = str;
    document.title = str + " - <%if (ngw!=null) { ar.writeJS(ngw.getFullName()); }%>";
}

 </script>


</head>
<body ng-app="myApp" ng-controller="myCtrl">
  
  
<div class="bodyWrapper">

<!-- Begin mainContent -->
<div class="main-content">
<%@ include file="AnonNavBar.jsp" %>

    <!-- BEGIN Title and Breadcrump -->
    <div class="col col-lg-12">
      <ol class="title">
          <!-- user is not logged in, don't display any breadcrumbs -->
        <li class="page-name"><h1 id="mainPageTitle">Welcome to Weaver</h1></li>
      </ol>
    </div>

    <!-- Begin Template Content (compiled separately) -->
    <jsp:include page="<%=wrappedJSP%>" />
    <!-- End Template Content (compiled separately) -->
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

<script src="<%=ar.baseURL%>jscript/translation.js"></script>

</body>
</html>

<!-- END Wrapper.jsp Layout-->
