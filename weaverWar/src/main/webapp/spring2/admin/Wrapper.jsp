<!DOCTYPE html>
<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/spring2/jsp/include.jsp"
%><%
    long renderStart = System.currentTimeMillis();
    ar.assertLoggedIn("Must be logged in for administration pages");
    UserProfile loggedUser = ar.getUserProfile();
    
    String loggedKey = loggedUser.getKey();
        
    //this is the most important setting .. it is the name of the JSP file
    //that is being wrapped with a standard header and a footer.
    String wrappedJSP = ar.reqParam("wrappedJSP");
    int slashPos = wrappedJSP.lastIndexOf("/");
    String jspName = wrappedJSP;
    if (slashPos>=0) {
        jspName = wrappedJSP.substring(slashPos+1);
    }
    Cognoscenti cog = ar.getCogInstance();
    
    
%>
<!-- BEGIN Wrapper.jsp Layout-->
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
    <script src="<%=ar.baseURL%>new_assets/jscript/slap.js"></script>

    <link
    rel="stylesheet"
    href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"/>


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


    <title>Administration Page</title>
    
    
<script>
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

var myApp = angular.module('myApp', ['ui.bootstrap','ngTagsInput','pascalprecht.translate']);

myApp.filter('cdate', function() {
  return function(x) {
    if (!x || x<10000000) {
        return "Not Set";
    }
    let diff = new Date().getTime() - x;
    if (diff>860000000 || diff<-860000000) {
        return moment(x).format("DD MMM YYYY");
    }
    return moment(x).format("DD MMM @ HH:mm");
  };
});

 </script>


</head>
<body>
  <div class="bodyWrapper">

<!-- Begin Top Navigation Area -->

<%@ include file="WrapHeaderAdmin.jsp" %>
</div>
<!-- End Top Navigation Area -->

<!-- Begin mainContent -->
<div id="mainContent" class="m-2">
<jsp:include page="<%=wrappedJSP%>" />
</div>
<!-- End mainContent -->



</div><!-- End body wrapper -->
</body>
</html>

<!-- END Wrapper.jsp Layout - - <%= (System.currentTimeMillis()-renderStart) %> ms -->
