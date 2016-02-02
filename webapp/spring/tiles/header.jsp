<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%/*

Parameter used :

    1. pageTitle    : Used to retrieve the page title from request.
    2. userKey      : This is Key of user who is logged in.
    3. pageId       : Id of a Workspace, used to fetch details of Workspace (NGPage).
    4. book         : This is key of a site, used here to get details of an Site (NGBook).
    5. viewingSelf  : This parameter is used to check if user is viewing himself/herself or other profile.
    6. headerType   : Used to check the header type whether it is from site, workspace or user on the basis of
                      it corrosponding tabs are displayed
    7. accountId    : This is key of a site, used here to get details of an Site (NGBook).

*/%><%!
    String pageTitle = null;
    String go="";
    String trncatePageTitle=null;
%><%

    String pageTitle = (String)request.getAttribute("pageTitle");
    if (pageTitle == null) {
        pageTitle = "";
    }
    String userKey = (String)request.getAttribute("userKey");

    String pageId = (String)request.getAttribute("pageId");
    String bookId = (String)request.getAttribute("book");
    String viewingSelfStr = (String)request.getAttribute("viewingSelf");

    String headerTypeStr = (String)request.getAttribute("headerType");
    String accountId = (String)request.getAttribute("accountId");

    String headerType = "";

    ar.assertNotPost();
    String deletedWarning = "";


    String navImage = ar.retPath+"navigation.jpg";

    NGContainer ngp =null;
    NGBook ngb=null;
    UserProfile userRecord = null;
    if(pageTitle == null && pageId != null){
        ngp  = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    }
    if(userKey != null){
        userKey = URLEncoder.encode(userKey);
        headerType = "user";
        userRecord = UserManager.getUserProfileByKey(userKey);
    }


    if (ngp!=null)
    {
        ar.setPageAccessLevels(ngp);
        pageTitle = ngp.getFullName();
        if(ngp instanceof NGPage) {
            ngb = ((NGPage)ngp).getSite();
        }
        else if(ngp instanceof NGBook) {
            ngb = ((NGBook)ngp);
        }
        if (ngp.isDeleted())
        {
            deletedWarning = "<img src=\""+ar.retPath+"deletedLink.gif\"> (DELETED)";
        }
        else if (ngp.isFrozen())
        {
            deletedWarning = " &#10052; (Frozen)";
        }
    }
    UserProfile uProf = ar.getUserProfile();
    if(viewingSelfStr != null && viewingSelfStr.length() > 0){
        boolean viewingSelf = Boolean.parseBoolean(viewingSelfStr);
        if(!viewingSelf){
            headerType="other";
        }
    }
    if(headerTypeStr != null){
        headerType = headerTypeStr;
    }

    String currentPageURL = ar.getCompleteURL();
    String encodedLoginMsg = URLEncoder.encode("Can't open form","UTF-8");

%>
<!-- header.jsp ** Standard Header Tile BEGIN --->

   <script type="text/javascript">
      var retPath ='<%=ar.retPath%>';
      var headerType = '';
      var book='';
      var pageId = '';
   </script>

    <link rel="stylesheet" href="<%=ar.retPath%>css/autocomplete.css" media="screen" type="text/css">
    <script type="text/javascript" src="<%=ar.retPath%>jscript/autocomplete.js"></script>

    <link href="<%=ar.retPath%>css/lightWindow.css" rel="styleSheet" type="text/css" media="screen" />

    <%if(headerType!=null){ %>
        <script type="text/javascript" src="<%=ar.retPath%>jscript/ddlevelsmenu.js"></script>
    <%} %>


    <%if(headerType.equalsIgnoreCase("index")){ %>
        <script type="text/javascript" src="<%=ar.retPath%>jscript/prototype.js"></script>
        <script type="text/javascript" src="<%=ar.retPath%>jscript/effects.js"></script>
        <script type="text/javascript" src="<%=ar.retPath%>jscript/lightWindow.js"></script>
    <%} %>

    <script type="text/javascript">
    var msg_separator = '<:>';
    var myPanel;
    var subPanel;
    function createPanel(header, bodyText, panelWidth){
        myPanel = new YAHOO.widget.Panel("panel", {
                                                width: panelWidth ,
                                                fixedcenter: true,
                                                constraintoviewport: true,
                                                underlay: "shadow",
                                                close: true,
                                                visible: false,
                                                draggable: true,
                                                modal:true
                                            });
        myPanel.setHeader(header);
        myPanel.setBody(bodyText);
        myPanel.render(document.body);
        myPanel.show();
    }
    function cancelPanel(){
         if(myPanel){
             myPanel.hide();
         }
    }
    var count = 0;
    function autoComplete(e,obj){
        autoAssignTextBox= obj.id;
        actionVal = "<%=ar.retPath%>t/getUsers.ajax";
        if(count == 0){
            doCompletion(e);
            count++;
        }
    }

    function markastemplate(pageId,action,URL,isfreezed){
        if(isfreezed == 'false'){
            var transaction = YAHOO.util.Connect.asyncRequest('POST', URL+"t/markAsTemplate.ajax?pageId="+pageId+"&action="+action, callbackresult);
        }else{
           openFreezeMessagePopup();
        }
    }

    var callbackresult = {
            success: function(o) {
                var respText = o.responseText;
                var json = eval('(' + respText+')');
                if(json.msgType == "success"){
                    if(typeof(flag)=='undefined'){
                        var action = json.action;
                        var markastemplateObj = document.getElementById("markastemplate");
                        var stopusingtemplateObj = document.getElementById("stopusingtemplate");
                        if(markastemplateObj && stopusingtemplateObj){
                            if(action == "MarkAsTemplate"){
                                markastemplateObj.style.display="";
                                stopusingtemplateObj.style.display="none";
                            }else{
                                markastemplateObj.style.display="none";
                                stopusingtemplateObj.style.display="";
                            }
                        }
                    }
                    else{
                        deleteRow();
                    }
                }
                else{
                    showErrorMessage("Result", json.msg , json.comments );
                }
            },
            failure: function(o) {
                    alert("markAsTemplate.ajax Error:" +o.responseText);
            }
        }

        //  This function is user to sort column which shows "Nice Print Time" (like Lat modfied, visited etc.) in Data Table
        //  In all data table , there should be column name "timePeriod" of type Number
        //  which is the visited/modified time in long/int.
        var sortDates = function(a, b, desc) {
            if(!YAHOO.lang.isValue(a)) {
                return (!YAHOO.lang.isValue(b)) ? 0 : 1;
            }
            else if(!YAHOO.lang.isValue(b)) {
                return -1;
            }
            var comp = YAHOO.util.Sort.compare;
            var compState = comp(a.getData("timePeriod"), b.getData("timePeriod"), desc);
            return compState;
        };

        function onSearch(){
            var  searchtext = trimme(document.getElementById("searchText").value);
            if(searchtext == ""){
                alert("Please enter search text.");
                document.getElementById("searchText").value = "";
                document.getElementById("searchText").focus();
                return false;
            }
            document.getElementById('searchForm').submit();
            return true;
        }




        function showHideReasonDiv(divId)
        {
            var reason_div = document.getElementById(divId);
            if(reason_div != null){
                if(reason_div.style.display=="block"){
                    reason_div.style.display="none";
                }else{
                    reason_div.style.display="block";
                }
            }
            return false;
        }

        function showErrorMessage(title, errorMsg, detailedMsg){
                if(myPanel != null){
                    cancelPanel();
                }

                var body = '<div class="generalArea">'+
                            '<div class="generalContent" align="center">'+
                                '<font size="3px">'+
                                    errorMsg+
                                '</font>'+
                                '<br/><br/>';

                if(typeof(detailedMsg) != 'undefined' && detailedMsg != "" ){
                    body += '<div align="left">'+
                                '<a href="#" onclick="showDetail()">Show Full Detail</a><br/>'+
                                    '<div id="detailErrDiv" style="display:none">'+
                                        '<textarea class="mywidth" rows="12" readonly>'+detailedMsg+'</textarea>'+
                                    '</div>'+
                                    '</div>'+
                                '<br/><br/>';
                }
                 body += '<input type="button" class="btn btn-primary" value="<fmt:message key="nugen.button.general.ok" />" name="option_btn" onclick="javascript:cancelPanel()"/>'+
                          '</div>'+
                          '</div>';
                createPanel(title,body,(title.length+errorMsg.length+350)+'px');
                myPanel.cfg.setProperty('modal', false);
            }
            function showDetail(){
                if(document.getElementById('detailErrDiv').style.display == 'block'){
                    document.getElementById('detailErrDiv').style.display = 'none';
                }else{
                    document.getElementById('detailErrDiv').style.display = 'block';
                }
            }

        function openFreezeMessagePopup(){
            var popup_title = "Workspace Frozen";
            var popup_body = '<div class="generalArea">'+
                '<div class="generalContent" align="center">'+
                    'You can not perform any operation in this workspace because this workspace has been frozen by administrator/owner.'+
                    '<br>'+
                    '<br>'+
                    '<input type="button" class="btn btn-primary"  value="Ok" onclick="cancelPanel()" >'+
                '</div>'+
            '</div>';
            createPanel(popup_title,popup_body, (popup_title.length+popup_body.length+350)+'px');
            return false;
        }

    </script>

    <!--[if IE 7]>
        <link href="<%=ar.retPath%>css/ie7styles.css" rel="styleSheet" type="text/css" media="screen" />
    <![endif]-->

<% if (!headerType.equals("site")) { %>
    <script>
        headerType = "<%=headerType%>";
        var userKey = "<%=userKey%>";
        var isSuperAdmin = "<%=ar.isSuperAdmin()%>";
        <% if (pageId != null && bookId != null) { %>
          pageId='<%=pageId%>';
          book='<%=bookId%>';
        <% } %>
    </script>

<% } else if(headerType.equals("site")){ %>
     <script>
        headerType = "<%=headerType%>";
        var userKey = "<%=userKey%>";

        <% if(accountId != null){ %>
        var accountId='<%=accountId %>';
        <% } else if(pageId!=null){ %>
        var accountId='<%=pageId%>';
        <% } %>
     </script>
<% } %>


    <!-- Begin siteMasthead -->
    <div id="siteMasthead">
        <img id="logoInterstage" src="<%=ar.retPath%>assets/logo_interstage.gif" alt="Interstage" width="145" height="38" />
        <div id="consoleName">
           <% if(ngb!=null){ %>
           Site: <a href="<%=ar.retPath%>v/<%ar.writeURLData(ngb.getKey());%>/$/accountListProjects.htm"
                     title="View the Site for this page"><%ar.writeHtml(ngb.getFullName());%></a>

           <% } %>
           <br />
           <%
            if(headerType.equals("user")) {
                if(userRecord!=null){
                    String userName = userRecord.getName();
                    if(userName.length()>60){
                        userName=userName.substring(0,60)+"...";
                    }
                    ar.write("User: <span title=\"");
                    ar.write(userName);
                    ar.write("\">");
                    ar.writeHtml(userName);
                    ar.write("</span>");
                }
            }
            else if(headerType.equals("site")) {
                if(pageTitle!=null){
                    if(pageTitle.length()>60){
                        trncatePageTitle=pageTitle.substring(0,60)+"...";
                    }else{
                        trncatePageTitle=pageTitle;
                    }
                    ar.write("Site: <span title=\"");
                    ar.write(pageTitle);
                    ar.write("\">");
                    ar.writeHtml(trncatePageTitle);
                    ar.write(deletedWarning);
                    ar.write("</span>");
                }
            }
            else {
                if(pageTitle!=null){
                    if(pageTitle.length()>60){
                        trncatePageTitle=pageTitle.substring(0,60)+"...";
                    }else{
                        trncatePageTitle=pageTitle;
                    }
                    ar.write("Workspace: <span title=\"");
                    ar.write(pageTitle);
                    ar.write("\">");
                    ar.writeHtml(trncatePageTitle);
                    ar.write(deletedWarning);
                    ar.write("</span>");
                }
            }
            %>
        </div>
        <div id="globalLinkArea">
          <ul id="globalLinks">
                <%
                    if(ar.isLoggedIn())
                    {
                        uProf = ar.getUserProfile();
                %>
                        <li><a href="<%=ar.retPath%>v/<%ar.writeHtml(uProf.getKey());%>/watchedProjects.htm"
                                title="Workspaces for the logged in user">Workspaces</a></li>
                        <li>|</li>
                        <li><a href="<%=ar.retPath%>v/<%ar.writeHtml(uProf.getKey());%>/userAlerts.htm"
                                title="Updates for the logged in user">Updates</a></li>
                        <li>|</li>
                        <li><a href="<%=ar.retPath%>v/<%ar.writeHtml(uProf.getKey());%>/userActiveTasks.htm"
                                title="Action Items for the logged in user">Goals</a></li>
                        <li>|</li>
                        <li><a href="<%=ar.retPath%>v/<%ar.writeHtml(uProf.getKey());%>/userProfile.htm?active=1"
                                title="Profile for the logged in user">Settings</a></li>
                        <%if(ar.isSuperAdmin()){ %>
                            <li>|</li>
                            <li><a href="<%=ar.retPath%>v/<%ar.writeHtml(uProf.getKey());%>/emailListnerSettings.htm" title="Administration">Administration</a></li>
                        <%} %>
                        <li>|</li>
                        <li class="text last"><a onclick="alert('Logout is not possible from this page, please navigate to another to log out')">Log Out</a></li>
               <%
                  }
                  else
                  {
               %>
                        <li><a href="<%=ar.retPath%>"
                                title="Initial Introduction Page">Welcome Page</a></li>
                        <li>|</li>
                        <li class="text last"><a onclick="alert('Login is not possible from this page, please navigate to another to log in')">Log in</a></li>
               <%
                  }
               %>
            </ul>
            </div>
        <%
        if (ar.isLoggedIn())
        {
            UserProfile uProf1 = ar.getUserProfile();
            %>
            <div id="welcomeMessage">
                Welcome, <%uProf1.writeLink(ar); %>
                <img id="logoFujitsu" src="<%=ar.retPath%>assets/logo_fujitsu.gif" alt="Fujitsu" width="86" height="38" />
            </div>
            <%
        }
        else
        {
            %>
            <div id="welcomeMessage">
                Not logged in
                <img id="logoFujitsu" src="<%=ar.retPath%>assets/logo_fujitsu.gif" alt="Fujitsu" width="86" height="38" />
            </div>
            <%
        }
        %>
    </div>
    <!-- End siteMasthead -->

    <!-- Begin mainNavigation -->
    <div id="mainNavigationLeft">
        <div id="mainNavigationCenter">
            <div id="mainNavigationRight">
            </div>
        </div>
        <div id="mainNavigation">

            <ul id="tabs">

                <div id="zoomOutButton" style="display: none;vertical-align:baseline;" align="right"  >
                    <input type="button" class="btn btn-primary" onclick="zoomOut()" value="<< Back in Workspace">
                </div>
            </ul>
        </div>

        <!--Top Drop Down Menu for User section HTML Starts Here -->
            <ul id="userSubMenu1" class="ddsubmenustyle"/></ul>
            <ul id="userSubMenu2" class="ddsubmenustyle"/></ul>
            <ul id="userSubMenu3" class="ddsubmenustyle"/></ul>
            <%if(ar.isSuperAdmin()){
            %>
            <ul id="userSubMenu4" class="ddsubmenustyle"/></ul>
            <%}%>

        <!--Top Drop Down Menu for workspace section HTML Starts Here -->
            <ul id="ddsubmenu1" class="ddsubmenustyle"/></ul>
            <ul id="ddsubmenu2" class="ddsubmenustyle"></ul>
            <ul id="ddsubmenu3" class="ddsubmenustyle"> </ul>
            <ul id="ddsubmenu4" class="ddsubmenustyle"></ul>

        <!--Top Drop Down Menu for Site section HTML Starts Here -->
            <ul id="accountSubMenu1" class="ddsubmenustyle"/></ul>
            <ul id="accountSubMenu2" class="ddsubmenustyle"></ul>
            <ul id="accountSubMenu4" class="ddsubmenustyle"> </ul>

    </div>

<script type="text/javascript">
 Tab = function(href,name){
          this.name=name;
          this.href=href;

      };
TabRef = function(href,name,ref){
          this.name=name;
          this.href=href;
          this.ref=ref;
      };


function createTabs(){
    var mainElement = document.getElementById("tabs");
    var arrayOfTabs;
    var shortPath = "t/"+book+"/"+pageId;
    var homePath = shortPath + "/frontPage.htm";
    if (shortPath == "t///projectHome.htm") {
        homePath = "";
    }
    if(headerType == "user"){
        arrayOfTabs = [
            new TabRef(retPath+"v/"+userKey+"/watchedProjects.htm","Projects","userSubMenu1"),
            new TabRef(retPath+"v/"+userKey+"/userAlerts.htm","Updates",""),
            new TabRef(retPath+"v/"+userKey+"/userActiveTasks.htm","Action Items","userSubMenu2"),
            new TabRef(retPath+"v/"+userKey+"/userSettings.htm","Settings","userSubMenu3")
        ];

        if(isSuperAdmin=="true"){
            arrayOfTabs.push(new TabRef(retPath+"v/"+userKey+"/emailListnerSettings.htm","Administration","userSubMenu4"));
        }
    }
    else if(headerType == "site") {
        arrayOfTabs = [
            new TabRef(retPath+"t/"+accountId+"/$/accountListProjects.htm","Site Workspaces","accountSubMenu2"),
            new TabRef(retPath+"t/"+accountId+"/$/account_settings.htm","Site Settings","accountSubMenu4")
        ];
    }
    else if(headerType == "project") {
        arrayOfTabs = [
            new TabRef(retPath+"t/"+book+"/"+pageId+"/history.htm","Workspace Stream",""),
            new TabRef(retPath+"t/"+book+"/"+pageId+"/notesList.htm","Workspace Topics","ddsubmenu1"),
            new TabRef(retPath+"t/"+book+"/"+pageId+"/goalList.htm","Workspace Action Items","ddsubmenu2"),
            new TabRef(retPath+"t/"+book+"/"+pageId+"/listAttachments.htm","Workspace Documents","ddsubmenu3"),
            new TabRef(retPath+"t/"+book+"/"+pageId+"/personal.htm","Workspace Settings","ddsubmenu4")
        ];
    }
    else  {
        arrayOfTabs = [
            new TabRef(retPath+homePath,"Home","")
        ];
    }

    for(var  i=0;i<arrayOfTabs.length ;i++){

        var newli   = document.createElement('li');
        var newlink = document.createElement('a');

        var newspan = document.createElement('span');

        newlink.setAttribute('href',arrayOfTabs[i].href);
        newlink.setAttribute('rel',arrayOfTabs[i].ref);

        if(arrayOfTabs[i].name=="Workspace Stream" ){
            newli.className = 'mainNavLink1';
        }
        if(arrayOfTabs[i].name=="Workspaces" ){
            newli.className = 'mainNavLink1';
        }

        if(specialTab=="null" && ((arrayOfTabs[i].name=="Project Stream")||(arrayOfTabs[i].name=="Projects") ||(arrayOfTabs[i].name=="Site Topics"))){
            newli.className = 'mainNavLink1 selected';
        }
        else if(specialTab==arrayOfTabs[i].name){
            if( (arrayOfTabs[i].name=="Workspace Stream")||
                (arrayOfTabs[i].name=="Workspaces") ){
                newli.className = 'mainNavLink1 selected';
            }
            else {
                newli.className = 'selected';
            }
        }

        newspan.innerHTML=arrayOfTabs[i].name;

        newlink.appendChild(newspan);
        newli.appendChild(newlink);
        mainElement.appendChild(newli);

    }
    ddlevelsmenu.setup("tabs", "topbar");
}

function createSubLinks(){

    var arrayOfSubMenu=0;
    var arrayOfMainMenu=0;

    if(headerType == "site") {

        var accountSubMenu2 = [new Tab(retPath+"t/"+accountId+"/$/accountListProjects.htm","List Workspaces"),
            new Tab(retPath+"t/"+accountId+"/$/accountCreateProject.htm","Create New Workspace"),
            new Tab(retPath+"t/"+accountId+"/$/accountCloneProject.htm","Clone Remote Workspace"),
            new Tab(retPath+"t/"+accountId+"/$/convertFolderProject.htm","Convert Folder to Workspace"),
            new Tab(retPath+"t/"+accountId+"/$/searchAllNotes.htm", "Search Topics")
        ];
        var accountSubMenu4 = [new Tab(retPath+"t/"+accountId+"/$/personal.htm","Personal"),
            new Tab(retPath+"t/"+accountId+"/$/permission.htm","Permissions"),
            new Tab(retPath+"t/"+accountId+"/$/roleRequest.htm","Role Requests"),
            new Tab(retPath+"t/"+accountId+"/$/admin.htm","Admin")
        ];
        arrayOfSubMenu=["accountSubMenu2","accountSubMenu4"];
        arrayOfMainMenu =[accountSubMenu2, accountSubMenu4];
    }
    else if(headerType == "user"){

        var arrayOfTabs1 = [new Tab(retPath+"v/"+userKey+"/watchedProjects.htm","Watched Workspaces"),
            new Tab(retPath+"v/"+userKey+"/notifiedProjects.htm","Notified Workspaces"),
            new Tab(retPath+"v/"+userKey+"/ownerProjects.htm","Administered Workspaces"),
            new Tab(retPath+"v/"+userKey+"/templates.htm","Templates"),
            new Tab(retPath+"v/"+userKey+"/participantProjects.htm","Participant Workspaces"),
            new Tab(retPath+"v/"+userKey+"/allProjects.htm","All Workspaces"),
            new Tab(retPath+"t/"+userKey+"/searchAllNotes.htm", "Search Topics"),
            new Tab(retPath+"v/"+userKey+"/userCreateProject.htm","Create New Workspace")
        ];

        var arrayOfTabs2 = [new Tab(retPath+"v/"+userKey+"/userActiveTasks.htm","Action Items"),
            new Tab(retPath+"v/"+userKey+"/ShareRequests.htm","Share Requests"),
            new Tab(retPath+"v/"+userKey+"/RemoteProfiles.htm","Remote Profiles"),
            new Tab(retPath+"v/"+userKey+"/userRemoteTasks.htm","Remote Action Items"),
            new Tab(retPath+"v/"+userKey+"/Agents.htm","Personal Assistant")
        ];

        var arrayOfTabs3 = [new Tab(retPath+"v/"+userKey+"/userSettings.htm","Personal"),
            new Tab(retPath+"v/"+userKey+"/userContacts.htm","Contacts"),
            new Tab(retPath+"v/"+userKey+"/userConnections.htm","Connections"),
            new Tab(retPath+"v/"+userKey+"/userAccounts.htm","Sites"),
            new Tab(retPath+"v/"+userKey+"/notificationSettings.htm","Unsubscribe")
        ];

        if(isSuperAdmin=="true"){
            var arrayOfTabs4 = [new Tab(retPath+"v/"+userKey+"/emailListnerSettings.htm","Email"),
                new Tab(retPath+"v/"+userKey+"/lastNotificationSend.htm","Last Notification Send"),
                new Tab(retPath+"v/"+userKey+"/errorLog.htm",      "Error Log"),
                new Tab(retPath+"v/"+userKey+"/newUsers.htm",      "New Users"),
                new Tab(retPath+"v/"+userKey+"/requestedAccounts.htm","Requested Sites"),
            ];
            arrayOfSubMenu  =["userSubMenu1","userSubMenu2","userSubMenu3","userSubMenu4"];
            arrayOfMainMenu =[ arrayOfTabs1,  arrayOfTabs2,  arrayOfTabs3,  arrayOfTabs4]
        }
        else{
            arrayOfSubMenu  =["userSubMenu1","userSubMenu2","userSubMenu3"];
            arrayOfMainMenu =[ arrayOfTabs1,  arrayOfTabs2,  arrayOfTabs3]
        }


    }

    else{   //This is the Project case

        var arrayOfTabs1 = [
            new Tab(retPath+"t/"+book+"/"+pageId+"/frontPage.htm",   "List Topics"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/automaticLinks.htm","Automatic Links"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/searchAllNotes.htm","Search All Topics"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/exportPDF.htm",   "Generate PDF"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/editNote.htm?public=true",  "Create New Note &gt;")
        ];

        var arrayOfTabs2 = [
            new Tab(retPath+"t/"+book+"/"+pageId+"/goalList.htm",             "List Action Items"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/meetingList.htm",          "Meeting List"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/agendaBacklog.htm",        "Agenda Item Backlog")
        ];

        var arrayOfTabs3 = [
            new Tab(retPath+"t/"+book+"/"+pageId+"/listAttachments.htm",   "List Documents"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/docsFolder.htm",        "Document Folders"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/docsAdd.htm",           "Add Document"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/SyncAttachment.htm",    "Synchonize") ,
            new Tab(retPath+"t/"+book+"/"+pageId+"/reminders.htm",         "Reminders"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/emailReminder.htm",     "Ask Someone to Attach File"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/docsDeleted.htm",       "Deleted Documents"),
        ];
        var arrayOfTabs4 = [
            new Tab(retPath+"t/"+book+"/"+pageId+"/personal.htm",      "Personal"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/permission.htm",    "Permissions"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/roleRequest.htm",   "Role Requests") ,
            new Tab(retPath+"t/"+book+"/"+pageId+"/admin.htm",         "Admin" ),
            new Tab(retPath+"t/"+book+"/"+pageId+"/labelList.htm",     "Labels" ),
            new Tab(retPath+"t/"+book+"/"+pageId+"/listEmail.htm",     "Email Prepared"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/emailSent.htm",     "Email Sent"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/streamingLinks.htm","Streaming Links"),
            new Tab(retPath+"t/"+book+"/"+pageId+"/synchronizeUpstream.htm","Synchronize Upstream")
        ];
        arrayOfSubMenu=["ddsubmenu1","ddsubmenu2","ddsubmenu3","ddsubmenu4"];
        arrayOfMainMenu =[arrayOfTabs1,arrayOfTabs2,arrayOfTabs3,arrayOfTabs4]
    }

    for(var  j=0;j<arrayOfSubMenu.length ;j++){
        var arrayOfTabs=arrayOfMainMenu[j];
        for(var  i=0;i<arrayOfTabs.length ;i++){
            var mainElement = document.getElementById(arrayOfSubMenu[j]);
            var newli= document.createElement('li');
            var newlink = document.createElement('a');
            var newspan = document.createElement('span');
            newlink.setAttribute('href',arrayOfTabs[i].href);
            if (arrayOfTabs[i].name.indexOf('&gt;')>0) {
                newlink.setAttribute('target','_blank');
            }
            newlink.setAttribute('href',arrayOfTabs[i].href);
            newspan.innerHTML=arrayOfTabs[i].name;
            newlink.appendChild(newspan);
            newli.appendChild(newlink);
            mainElement.appendChild(newli);
        }
    }
}



createSubLinks();
createTabs();
</script>

<!-- End mainNavigation -->

<form id="validate" action="<%=ar.retPath%>t/validateHtml.validate" method="post">
<textarea id="output" name="output" rows="50" cols="70" style="display:none"></textarea>
</form>
<script>
   function getSourceCode(){
            var url = '<%=ar.getCompleteURL()%>';
            YAHOO.util.Connect.asyncRequest('GET',url ,visibilitySubmitResponse);
   }




       var visibilitySubmitResponse ={
               success: function(o) {
                   var respText = o.responseText;
                   document.getElementById("output").value = respText;
                   document.getElementById("validate").submit();
               },
               failure: function(o) {
                    alert("validateSubmitResponse Error:" +o.responseText);
               }
       }


        function validateDelimEmails(field) {
            var count = 1;
            var result = "";
            var spiltedEmails;
            var value = trimme(field.value);
            if(value != ""){
                if(value.indexOf(";") != -1){
                    spiltedEmails = value.split(";");
                }else if(value.indexOf(",") != -1){
                    spiltedEmails = value.split(",");
                }else if(value.indexOf("\n") != -1){
                    spiltedEmails = value.split("\n");
                }else{
                    value = value+";";
                    spiltedEmails = value.split(";");
                }
                for(var i = 0;i < spiltedEmails.length;i++){
                    var email_id = trimme(spiltedEmails[i]);
                    if(email_id != ""){
                        if(!validateEmail(email_id)){
                            result += "  "+count+".    "+email_id+" \n";
                            count++;
                        }
                    }
                }
            }
            if(result != ""){
                alert("Below is the list of id(s) which does not look like an email. Please enter an email id(s).\n\n"+result);
                field.focus();
                return false;
            }

            return true;
        }
</script>
<!-- /header.jsp ** Standard Header Tile END --->
<% out.flush(); %>
