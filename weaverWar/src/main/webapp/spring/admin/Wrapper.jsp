<!DOCTYPE html>
<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
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
<html>
<head>
    <link rel="shortcut icon" href="<%=ar.baseURL%>bits/favicon.ico" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="Content-Language" content="en-us" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta http-equiv="imagetoolbar" content="no" />

    <!-- INCLUDE the ANGULAR JS library -->
    <script src="<%=ar.baseURL%>jscript/angular.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/angular-translate.js"></script>
    <script src="<%=ar.baseURL%>jscript/ui-bootstrap-tpls.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/jquery.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/bootstrap.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/slap.js"></script>

    <script src='<%=ar.baseURL%>jscript/tinymce/tinymce.min.js'></script>
    <script src='<%=ar.baseURL%>jscript/tinymce/tinymce-ng.js'></script>
    <script src="<%=ar.baseURL%>jscript/textAngular-sanitize.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/ng-tags-input.js"></script>
 
    <script src="<%=ar.baseURL%>jscript/common.js"></script>

    <link href="<%=ar.retPath%>assets/font-awesome/css/font-awesome.min.css" rel="stylesheet"
          data-semver="4.3.0" data-require="font-awesome@*" />
    <link href="<%=ar.baseURL%>jscript/bootstrap.min.css" rel="stylesheet">
    <link href="<%=ar.baseURL%>jscript/ng-tags-input.css" rel="stylesheet">

    <link href="<%=ar.retPath%>bits/superAdminStyle.css" rel="styleSheet" type="text/css" media="screen" />
    
    <script src="<%=ar.retPath%>bits/moment.js"></script>
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
<div class="topNav">
<%@ include file="WrapHeaderAdmin.jsp" %>
</div>
<!-- End Top Navigation Area -->

<!-- Begin mainContent -->
<div id="mainContent">
<jsp:include page="<%=wrappedJSP%>" />
</div>
<!-- End mainContent -->



</div><!-- End body wrapper -->
</body>
</html>

<!-- END Wrapper.jsp Layout - - <%= (System.currentTimeMillis()-renderStart) %> ms -->
