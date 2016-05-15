<%
    
    //this is the most important setting .. it is the name of the JSP file
    //that is being wrapped with a standard header and a footer.
    String wrappedJSP = ar.reqParam("wrappedJSP");
    String templateName = wrappedJSP+".jsp";
    int slashPos = wrappedJSP.lastIndexOf("/");
    String jspName = wrappedJSP;
    if (slashPos>=0) {
        jspName = wrappedJSP.substring(slashPos+1);
    }
    if ("FrontPage".equals(jspName)) {
        jspName = "Front Page";
    }
    else if ("MeetingList".equals(jspName)) {
        jspName = "Meetings";
    }
    else if ("NotesList".equals(jspName)) {
        jspName = "Topics";
    }
    else if ("ListAttachments".equals(jspName)) {
        jspName = "Documents";
    }
    else if ("GoalList".equals(jspName)) {
        jspName = "Action Items";
    }
    else if ("DecisionList".equals(jspName)) {
        jspName = "Decisions";
    }
    else if ("LabelList".equals(jspName)) {
        jspName = "Labels";
    }
    else if ("RoleManagement".equals(jspName)) {
        jspName = "Roles";
    }
    else if ("leaf_admin".equals(jspName)) {
        jspName = "Workspace Admin";
    }
    else if ("leaf_personal".equals(jspName)) {
        jspName = "Personal";
    }
    else if ("GoalEdit".equals(jspName)) {
        jspName = "Edit Action Item";
    }
    else if ("leaf_history".equals(jspName)) {
        jspName = "Activity Stream";
    }
    else if ("MeetingFull".equals(jspName)) {
        jspName = "Meeting Details";
    }
    else if ("accountListProjects".equals(jspName)) {
        jspName = "Workspaces in Site";
    }
    else if ("SiteAdmin".equals(jspName)) {
        jspName = "Site Admin";
    }
    else if ("NoteZoom".equals(jspName)) {
        jspName = "Discussion Topic";
    }
    else if ("docinfo".equals(jspName)) {
        jspName = "Access Document";
    }
    else if ("DocsRevise".equals(jspName)) {
        jspName = "Upload New Version";
    }
    else if ("editDetails".equals(jspName)) {
        jspName = "Edit Doc Details";
    }
    else if ("fileVersions".equals(jspName)) {
        jspName = "List Doc Versions";
    }
    else if ("UserAccounts".equals(jspName)) {
        jspName = "Sites You Manage";
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
        

%>
<!-- BEGIN Wrapper.jsp Layout-->
<html>
<head>
    <!--fmt:setBundle basename="messages"/-->
    
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
    <script src="<%=ar.baseURL%>jscript/slap.js"></script>

    <script src="<%=ar.baseURL%>jscript/common.js"></script>
    <script src="<%=ar.baseURL%>jfunc.js"></script>

    <link href="<%=ar.retPath%>assets/font-awesome/css/font-awesome.min.css" rel="stylesheet"
          data-semver="4.3.0" data-require="font-awesome@*" />
    <link href="<%=ar.baseURL%>jscript/bootstrap.min.css" rel="stylesheet">

    <link href="<%=ar.retPath%>bits/weaverstyle.css" rel="styleSheet" type="text/css" media="screen" />
    <link href="<%=ar.retPath%>bits/weavertheme.css" rel="styleSheet" type="text/css" media="screen" />

    
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
  <div class="bodyWrapper">

<!-- Begin Top Navigation Area -->
<div class="topNav">
<%@ include file="WrapHeader2.jsp" %>
</div>
<!-- End Top Navigation Area -->

<!-- Begin mainContent -->
<div id="mainContent">
<jsp:include page="<%=templateName%>" />
</div>
<!-- End mainContent -->



</div><!-- End body wrapper -->
</body>
</html>
<!-- END WrapLayout2.jsp -->
