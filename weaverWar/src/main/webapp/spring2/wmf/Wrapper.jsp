<!DOCTYPE html>
<%@page errorPage="/spring/anon/Error.jsp"
%><%@ include file="/include.jsp"
%><%
    String title = "Weaver Meeting";
    NGWorkspace ngw =null;
    NGBook ngb=null;
    Cognoscenti cog=null;
    
    String wrappedJSP = ar.reqParam("wrappedJSP"); 

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

%>

<!-- BEGIN wmf/Wrapper.jsp Layout wrapping (<%=wrappedJSP%>) -->  
<html>
<head>
    <link rel="shortcut icon" href="<%=ar.baseURL%>bits/favicon.ico" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="Content-Language" content="en-us" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta http-equiv="imagetoolbar" content="no" />
    <meta name="viewport" content="user-scalable=no, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0" />

    <title><% ar.writeHtml(title); %></title>
    <script src="<%=ar.baseURL%>jscript/angular.js"></script>
    <script src="<%=ar.baseURL%>jscript/jquery.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/bootstrap.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/ui-bootstrap-tpls.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/slap.js"></script>
    <script src='<%=ar.baseURL%>jscript/tinymce/tinymce.min.js'></script>
    <script src='<%=ar.baseURL%>jscript/tinymce/tinymce-ng.js'></script>
    <script src="<%=ar.baseURL%>jscript/textAngular-sanitize.min.js"></script>
    <script src="<%=ar.retPath%>bits/moment.js"></script>
    <script src="<%=ar.baseURL%>jscript/MarkdownToHtml.js"></script>
    
        <link href="<%=ar.retPath%>assets/font-awesome/css/font-awesome.min.css" rel="stylesheet"
          data-semver="4.3.0" data-require="font-awesome@*" />
    <link href="<%=ar.baseURL%>bits/WeaverMobileFirstStyle.css" rel="stylesheet">
    <!-- Bootstrap 5.0-->
    <link rel="stylesheet" href="<%=ar.retPath%>css/bootstrap.min.css" />
    <link rel="stylesheet" href="<%=ar.retPath%>css/weaver.min.css" />
<script>


//Must initialize the app with all the right packages here, before the 
//individual pages create the controlles
var myApp = angular.module('myApp', ['ui.bootstrap','ui.tinymce','ngSanitize']);

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
myApp.filter('pdate', function() {
  return function(x) {
    if (!x || x<100000000) {
        return "Time To Be Determined";
    }
    return moment(x).format("DD-MMM-YYYY  HH:mm");
  };
});
myApp.filter('wiki', function() {
  return function(x) {
    return convertMarkdownToHtml(x);
  };
});
myApp.filter('encode', function() {
  return window.encodeURIComponent;
});

function reloadIfLoggedIn(info) {
    //nothingn to with slap at this time
}
SLAP.initLogin(<% loginConfigSetup.write(out, 2, 2); %>, <% loginInfoPrefetch.write(out, 2, 2); %>, reloadIfLoggedIn);

 </script>

</head>
<body ng-app="myApp" ng-controller="myCtrl" >
  
  


<!-- Begin mainContent -->
<div class="main-content">

    <!-- Begin Template Content (compiled separately) -->
    <jsp:include page="<%=wrappedJSP%>" />
    <!-- End Template Content (compiled separately) -->
</div>

</body>
</html>

<!-- END Wrapper.jsp Layout-->
