<!DOCTYPE html>
<%@page errorPage="/spring2/anon/Error.jsp"
%><%@ include file="/include.jsp"
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
    
    JSONArray learningModes = new JSONArray();
    boolean expectedLoginState = ar.isLoggedIn();
    String currentPageURL = ar.getCompleteURL();
    UserProfile user = ar.getUserProfile();
    
    String loggedKey = "";
    if (ar.isLoggedIn()) {
        loggedKey = user.getKey();
        UserPage userPage = user.getUserPage();

        learningModes = userPage.getLearningPathForUser(wrappedJSP);
        if (learningModes.length()==0) {
            learningModes = new JSONArray();
            JSONObject lm = new JSONObject();
            lm.put("description", "Learn about "+wrappedJSP
                    +"\n\nMust create some text for this before you can hide it");
            lm.put("done", false);
            lm.put("mode", "standard");
            learningModes.put(lm);
        }
        JSONObject learningMode = null;
        for (JSONObject oneLearn : learningModes.getJSONObjectList()) {
            learningMode = oneLearn;
            break;
        }
    }


%>

<!-- BEGIN anon/Wrapper.jsp Layout wrapping (<%=wrappedJSP%>) -->  
<html>
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
<!-- INCLUDE the ANGULAR JS library -->
    <script src="<%=ar.baseURL%>new_assets/jscript/angular.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/angular-translate.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/ui-bootstrap-tpls.min.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/jquery-3.6.0.min.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/slap.js"></script>

    <!-- Are these needed -->
    <script src="<%=ar.baseURL%>new_assets/jscript/tinymce/tinymce.min.js"></script>
    <script src="<%=ar.baseURL%>new_assets/jscript/tinymce/tinymce-ng.js"></script>
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

        <link rel="stylesheet" href="<%=ar.retPath%>new_assets/bits/angularjs-datetime-picker.css" />
    <script src="<%=ar.retPath%>new_assets/bits/angularjs-datetime-picker.js"></script>
    <script src="<%=ar.retPath%>new_assets/bits/moment.js"></script>

    <!--Bootstrap 5.0-->
    <link rel="stylesheet" href="<%=ar.retPath%>new_assets/css/bootstrap.min.css" />
    <link href="<%=ar.retPath%>new_assets/css/superAdminStyle.css" rel="styleSheet" type="text/css" media="screen" />
      <link rel="stylesheet" href="<%=ar.retPath%>new_assets/css/weaver.min.css" />
      
    <script>  moment().format(); </script>
 
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
myApp.filter('wiki', function() {
  return function(x) {
    return convertMarkdownToHtml(x);
  };
});
myApp.filter('encode', function() {
  return window.encodeURIComponent;
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

function setUpLearningMethods($scope, $modal, $http) {
    console.log("setUpLearningMethods for <%=loggedKey%>");
    $scope.learningModes = <% learningModes.write(out, 2, 2); %>;
    $scope.learningMode = {done: true, mode:"standard"};
    
    $scope.findLearningMode = function() {
        $scope.learningMode = {done: true, mode:"standard"};
        $scope.learningModes.forEach(function(item) {
            if (!item.done && $scope.learningMode.done) {
                $scope.learningMode = item;
            }
        });
        console.log("LEARNING MODE", $scope.learningMode);
    }
    
    $scope.findLearningMode();
    
    $scope.markLearningDone = function() {
        $scope.learningMode.done = true;
        $scope.findLearningMode();
    }
    
    $scope.openLearningEditor = function () {
        console.log("trying ot open it");
        var modalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>templates/LearningEditModal.html?t=<%=System.currentTimeMillis()%>',
            controller: 'LearningEditCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                wrappedJSP: function () {
                    return "<%=wrappedJSP%>";
                }
            }
        });
        modalInstance.result
        .then(function () {
            window.location.reload();
        }, function () {
            window.location.reload();
        });
        
    }
    
    $scope.setLearningDone = function(option) {
        console.log("MARK DONE", $scope.learningMode);
        var toPost = {}
        toPost.jsp = "<%=wrappedJSP%>";
        toPost.mode = $scope.learningMode.mode;
        toPost.done = option;        
        var postdata = angular.toJson(toPost);
        var postURL = "MarkLearningDone.json";
        console.log(postURL,toPost);
        $http.post(postURL, postdata)
        .success( function(data) {
            window.location.reload();
        })
        .error( function(data) {
            errorPanelHandler($scope, data);
        });
    }
    $scope.toggleLearningDone = function() {
        $scope.setLearningDone(true);
    }
        
    mainScope = $scope;
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
