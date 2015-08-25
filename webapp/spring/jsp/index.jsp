<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"%>
<%

    if (!Cognoscenti.getInstance(request).isInitialized()) {
        String go = ar.getCompleteURL();
        String configDest = ar.retPath + "init/config.htm?go="+URLEncoder.encode(go);
        response.sendRedirect(configDest);
    }

%>

<style type="text/css">
    html {
        background-color:#C1BFC0;
        background-image:url('../assets/homePageBg.jpg');
        background-repeat:no-repeat;
        background-position:center top;
    }
    body {
        font-family:Arial,Helvetica,Verdana,sans-serif;
        font-size:100.1%;
        color:#000000;
        background-color:transparent;
    }
    #bodyWrapper {
        margin:0px auto 45px auto;
        width:935px;
        position:relative;
    }
</style>
<body class="yui-skin-sam">
    <table cellpadding="0" cellspacing="0" width="100%">
        <tr>
            <td width="900px" style="text-align:center;">
                <table cellpadding="0" cellspacing="0">
                    <tr>
                        <td colspan="2" class="homePageBanner">&nbsp;</td>
                    </tr>
                    <tr>
                        <td align="left">
                            <table cellpadding="0" cellspacing="0">
                                <tr>
                                    <td class="avatarAPlatform">&nbsp;</td>
                                </tr>
                                <tr>
                                    <td class="homePageContent">
                                        Stop wasting your time chasing emails, and start organizing and planning to accomplish things.<br /><br />
                                        With a few keystrokes you make a place for a project which can be accessed from anywhere,
                                        but only the people you designate.
                                        Goals can be assigned to anyone with an email address,<br>and automatic email notification
                                        keeps everyone informed.<br>It is quick and easy to sign up for a free site.
                                    </td>
                                </tr>
                            </table>
                        </td>

                        <td>
                            <table cellpadding="0" cellspacing="0">
                                <tr>
                                    <td colspan="2" class="homePageSearchArea">
                                        <b>Search this Site for Content</b><br />
                                        <form id="searchForm" name="searchForm" action="<%=ar.retPath%>t/searchPublicNotes.htm">
                                            <table cellpadding="0" cellspacing="0">
                                                <tr>
                                                    <td class="searchInput">
                                                        <input type="text" class="inputButton" id="searchText" name="searchText" />
                                                    </td>
                                                    <td class="searchButton" onclick="return onSearch();">&nbsp;</td>
                                                </tr>
                                            </table>
                                        </form>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="registerButton" onclick="login();">&nbsp;</td>
                                    <td class="loginLink">
                                        Already a member<br /><a href="<%=ar.baseURL%>t/EmailLoginForm.htm?go=<%ar.writeURLData(ar.getCompleteURL());%>">Log In</a> here.
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                    <tr><td colspan="2" class="greenSeperator"></td></tr>
                    <tr>
                        <td colspan="2" class="homePageFeatureArea">
                            <table cellpadding="0" cellspacing="0">
                                <tr>
                                    <td class="featureOverview">&nbsp;</td>
                                </tr>
                                <tr>
                                    <td>
                                        <table cellpadding="0" cellspacing="0" width="100%">
                                            <tr>
                                                <td>
                                                    Creating a project
                                                    <div class="createProject">
                                                        <a href="../assets/createProjectBig.gif" class="lWOn" title="Creating a Project"><img src="../assets/createProjectSmall.gif" width="195" height="157" border="0"></a>
                                                    </div>
                                                </td>
                                                <td>
                                                    Managing Goals
                                                    <div class="createTask">
                                                        <a href="../assets/createTaskBig.gif" class="lWOn" title="Managing Goals"><img src="../assets/createTaskSmall.gif" width="195" height="157" border="0"></a>
                                                    </div>
                                                </td>
                                                <td>
                                                    Sharing Notes
                                                    <div class="sharingNotes">
                                                        <a href="../assets/sharingNotesBig.gif" class="lWOn" title="Sharing Notes"><img src="../assets/sharingNotesSmall.gif" width="195" height="157" border="0"></a>
                                                    </div>
                                                </td>
                                                <td>
                                                    Attaching Documents
                                                    <div class="attachingDocument">
                                                        <a href="../assets/attachingDocumentBig.gif" class="lWOn" title="Attaching Documents"><img src="../assets/attachingDocumentSmall.gif" width="195" height="157" border="0"></a>
                                                    </div>
                                                </td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>



    <script type="text/javascript">

        YAHOO.util.Event.addListener(window, "load", function()
        {


            YAHOO.example.EnhanceFromMarkup = function()
            {
                var myColumnDefs = [
                    {key:"bookid",label:"<fmt:message key='nugen.generatInfo.main.BookId'/>",sortable:true,resizeable:true},
                    {key:"members",label:"<fmt:message key='nugen.generatInfo.main.Members' />",sortable:true,resizeable:true},
                    {key:"desc",label:"<fmt:message key='nugen.generatInfo.main.Description' />",sortable:false,resizeable:true}];

                var myDataSource = new YAHOO.util.DataSource(YAHOO.util.Dom.get("pagelist"));
                myDataSource.responseType = YAHOO.util.DataSource.TYPE_HTMLTABLE;
                myDataSource.responseSchema = {
                    fields: [{key:"bookid"},
                            {key:"members"},
                            {key:"desc"}]
                };

                var oConfigs = {
                    paginator: new YAHOO.widget.Paginator({
                        rowsPerPage: 200
                    }),
                    initialRequest: "results=999999"
                };


                var myDataTable = new YAHOO.widget.DataTable("listofpagesdiv", myColumnDefs, myDataSource, oConfigs,
                {caption:"",sortedBy:{key:"bookid",dir:"desc"}});

                return {
                    oDS: myDataSource,
                    oDT: myDataTable
                };
            }();
        });

        function login(){
            window.location ='<%=ar.baseURL%>t/EmailLoginForm.htm?go=<%ar.writeURLData(ar.getCompleteURL());%>';
        }
    </script>

<%@ include file="functions.jsp"%>
</body>
