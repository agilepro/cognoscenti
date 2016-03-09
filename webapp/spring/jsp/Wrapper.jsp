<!DOCTYPE html>
<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ taglib uri="http://tiles.apache.org/tags-tiles" prefix="tiles"
%><%
    long renderStart = System.currentTimeMillis();
    
    //this is the most important setting .. it is the name of the JSP file
    //that is being wrapped with a standard header and a footer.
    String templateName = ar.reqParam("wrappedJSP")+".jsp";

    
    String title = ar.defParam("title", ar.reqParam("wrappedJSP")); 
    int slashPos = title.lastIndexOf("/");
    if (slashPos>=0) {
        title = title.substring(slashPos+1);
    }
    String themePath = ar.getThemePath();
    Cognoscenti cog = ar.getCogInstance();

    UserProfile loggedUser = ar.getUserProfile();
    
    
//pageTitle is a very strange variable.  It mostly is used to hold the value displayed
//just above the menu.  Usually "Workspace: My Workspace"   or "Site: my Site" or "User: Joe User"
//Essentially this depends upon the header type (workspace, site, or user).
//however the logic is quite convoluted in first detecting what header type it is, and then
//making sure that the right thing is in this value, and then truncating it sometimes.
    String pageTitle = (String)request.getAttribute("pageTitle");

//this indicates a user page
    String userKey = (String)request.getAttribute("userKey");

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
        //if (userKey==null) {
        //    throw new Exception("Program Logic Error: need a userKey passed to a user style header");
        //}
        //can not test for presence of a user or not .... because unlogged in warning use this
        //probably need a special header type for warnings...like not logged in
    }
    else if (isProjectHeader) {
        if (pageId==null) {
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
    JSONObject menuWrapper = JSONObject.readFromFile(menuFile);
    JSONArray mainList = menuWrapper.getJSONArray("mainList");
    
    boolean weaverMenus = false;
    String loggedKey = "";
    if (ar.isLoggedIn()) {
        weaverMenus = loggedUser.getWeaverMenu();
        loggedKey = loggedUser.getKey();
    }
    

%>
<!-- BEGIN Wrapper.jsp Layout-->
<html>
<head>
    <fmt:setBundle basename="messages"/>
    
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

    
    <title><% ar.writeHtml(title); %></title>
    
    
    
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
<% if (weaverMenus) { %>
<%@ include file="WrapHeader2.jsp" %>
<% } else { %>
<%@ include file="WrapHeader.jsp" %>
<% } %>
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
<jsp:include page="<%=templateName%>" />
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
<%@ include file="WrapFooter.jsp" %>
        </div>
    </div>
</div>
<!-- End siteFooter -->

    </div>
    <!-- End body wrapper -->
</body>
</html>
<!-- END Wrapper.jsp Layout - - <%= (System.currentTimeMillis()-renderStart) %> ms -->
