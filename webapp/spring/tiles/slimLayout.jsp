<!DOCTYPE html>
<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ taglib uri="http://tiles.apache.org/tags-tiles" prefix="tiles"
%><%
    String title=(String)request.getAttribute("title");
    String themePath = ar.getThemePath();
    long renderStart = System.currentTimeMillis();

%>
<!-- BEGIN slimLayout.jsp -->
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="Content-Language" content="en-us" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta http-equiv="imagetoolbar" content="no" />

    <!-- INCLUDE the ANGULAR JS library -->
    <script src="<%=ar.baseURL%>jscript/angular.js"></script>
    <script src="<%=ar.baseURL%>jscript/ui-bootstrap-tpls.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/jquery.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/bootstrap.min.js"></script>

    <script src='<%=ar.baseURL%>jscript/tinymce/tinymce.min.js'></script>
    <script src='<%=ar.baseURL%>jscript/tinymce/tinymce-ng.js'></script>
    <script src="<%=ar.baseURL%>jscript/textAngular-sanitize.min.js"></script>

    <link href="<%=ar.baseURL%>css/body.css" rel="styleSheet" type="text/css" media="screen" />
    <script src="<%=ar.baseURL%>jscript/nugen_plain.js"></script>
    <script src="<%=ar.baseURL%>jscript/slap.js"></script>

    <link href="<%=ar.retPath%>css/tabs.css" rel="styleSheet" type="text/css" media="screen" />

    <script src="<%=ar.baseURL%>jscript/common.js"></script>
    <script src="<%=ar.baseURL%>jfunc.js"></script>
    <script src="<%=ar.baseURL%>jscript/tabs.js"></script>

    <link href="<%=ar.retPath%>assets/font-awesome/css/font-awesome.min.css" rel="stylesheet"
          data-semver="4.3.0" data-require="font-awesome@*" />
    <link href="<%=ar.baseURL%>jscript/bootstrap.min.css" rel="stylesheet">

    <link href="<%=ar.retPath%>css/reset.css" rel="styleSheet" type="text/css" media="screen" />
    <link href="<%=ar.retPath%>css/ddlevelsmenu-base.css" rel="styleSheet" type="text/css" media="screen" />
    <link href="<%=ar.retPath%>css/global.css" rel="styleSheet" type="text/css" media="screen" />
    <link href="<%=ar.retPath%><%=themePath%>theme.css" rel="styleSheet" type="text/css" media="screen" />

    
    <title><tiles:getAsString name="title"/><%
    if(title!=null) {
        ar.write(" : ");
        ar.write(title);
    }
    %></title>
    
    
    
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
</script>


</head>
<body>
    <!-- Start SLIM body wrapper -->
    <div class="bodyWrapper">

<!-- Begin Top Navigation Area -->
<div class="topNav">
<tiles:insertAttribute name="header" />
</div>
<!-- End Top Navigation Area -->

<!-- Begin mainSiteContainer -->
<div id="mainSiteContainerDetails">
    <div id="mainSiteContainerDetailsRight">
        <table width="100%">
            <tr>
                <td valign="top">
                    <!-- Begin mainContent (Body area) -->
                        <div id="mainContent">
<tiles:insertAttribute name="body" />
                        </div>
                    <!-- End mainContent (Body area) -->
                </td>
            </tr>
        </table>
    </div>
</div>
<!-- End mainSiteContainer -->

<!-- Begin siteFooter -->
<div id="siteFooter">
    <div id="siteFooterRight">
        <div id="siteFooterCenter">
<tiles:insertAttribute name="footer" />
        </div>
    </div>
</div>
<!-- End siteFooter -->

    </div>
    <!-- End body wrapper -->
</body>
</html>
<!-- END slimLayout.jsp - - <%= (System.currentTimeMillis()-renderStart) %> ms -->
