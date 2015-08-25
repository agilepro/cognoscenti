<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't perform search.");

    String b          = ar.reqParam("b");
    String scope      = ar.defParam("scope", "book");
    String qs         = ar.defParam("qs", "");
    String bookscoping = " checked=\"checked\"";
    String globalscoping = "";
    boolean isGlobalScope = !scope.equals("book");
    if (isGlobalScope)
    {
        bookscoping = "";
        globalscoping = " checked=\"checked\"";
    }

    String bookBit = "";
    String bookName = "";
    if (!isGlobalScope)
    {
        NGBook ngb2 = ar.getCogInstance().getSiteByIdOrFail(b);
        bookBit = "&b="+URLEncoder.encode(b, "UTF-8");
        bookName = ngb2.getFullName();
    }
    String servletURL = "servlet/DataFeedServlet?op=SEARCH&qs="
                       + URLEncoder.encode(qs, "UTF-8") + bookBit;


    pageTitle = "Search: "+qs;%>

<%@ include file="Header.jsp"%>

    <center>
        <br/>
        <form action="Search.jsp" method="get" name="searchForm">
        <h3>Search all Pages in account:
        <input type="radio" name="scope" value="book"<%=bookscoping%>>
        <%ar.writeHtml( bookName );%> or
        <input type="radio" name="scope" value="global"<%=globalscoping%>>
        All Sites
        </h3>
        <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
        <input type="hidden" name="b"          value="<%ar.writeHtml(b);%>">
            <table width="80%" class="Design8">
                <col width="10%"/>
                <col width="90%"/>
                <tr>
                    <td>Text</td>
                    <td class="odd">
                        <input type="text" name="qs" style="WIDTH: 95%;"
                               value="<%ar.writeHtml(qs);%>"/>
                    </td>
                </tr>
            </table>
            <br/>
            <button type="submit" name="action" value="Search">Search</button>
        </form>
    <center/>

    <script>

        function resetControls() {
            document.searchForm.qs.value="";
            document.searchForm.qs.focus();
        }

        function trim(sString)
        {
            if (sString.length==0)
                return sString;

            while (sString.substring(0,1) == ' ') {
                sString = sString.substring(1, sString.length);
            }
            while (sString.substring(sString.length-1, sString.length) == ' '){
                sString = sString.substring(0,sString.length-1);
            }
            return sString;
        }
    </script>

    <!-- Display the search results here -->
    <br/>
    <div><b><label id="resultsLbl">&nbsp;</label></b></div>
    <div id="searchresultdiv"></div>
    <script type="text/javascript">

        function performSearchAndDisplayResults()
        {

            // just return if the search string is empty.
            if(trim(document.searchForm.qs.value) == "")
            {
                return;
            }

            // for the loading Panel
            YAHOO.namespace("example.container");
            if (!YAHOO.example.container.wait)
            {
                // Initialize the temporary Panel to display while waiting for external content to load
                YAHOO.example.container.wait =
                        new YAHOO.widget.Panel("wait",
                                                { width: "240px",
                                                  fixedcenter: true,
                                                  close: false,
                                                  draggable: false,
                                                  zindex:4,
                                                  modal: true,
                                                  visible: false
                                                }
                                            );

                YAHOO.example.container.wait.setHeader("Loading, please wait...");
                YAHOO.example.container.wait.setBody("<img src=\"<%=ar.retPath%>loading.gif\"/>");
                YAHOO.example.container.wait.render(document.body);
            }
            // Show the loading Panel
            YAHOO.example.container.wait.show();

            // for data table.
            YAHOO.example.Local_XML = function()
            {
                var myDataSource, myDataTable, oConfigs;

                var connectionCallback = {
                    success: function(o) {

                        // hide the loading panel.
                        YAHOO.example.container.wait.hide();
                        //alert(o.responseXML.xml);
                        var xmlDoc = o.responseXML;

                        var formatUrl = function(elCell, oRecord, oColumn, sData)
                        {
                            elCell.innerHTML = "<a href='<%=ar.retPath%>" + oRecord.getData("PageLink") + "' target='_blank'>" + sData + "</a>";
                        };

                        var formatNameUrl = function(elCell, oRecord, oColumn, sData)
                        {
                            elCell.innerHTML = '<a href="<%=ar.retPath%>FindUser.jsp?id=' + encodeURIComponent(oRecord.getData("LastModifiedBy")) + '">' + sData + "</a>";
                        };
                        var myColumnDefs = [
                            {key:"No",label:"No",formatter:YAHOO.widget.DataTable.formatNumber,sortable:true,resizeable:true},
                            {key:"PageName",label:"Page", formatter:formatUrl, sortable:true,resizeable:true},
                            {key:"LastModifiedName",label:"Last Updated By", formatter:formatNameUrl, sortable:true, resizeable:true},
                            {key:"LastModifiedTime",label:"Last Updated On",sortable:true,resizeable:true}
                        ];

                        myDataSource = new YAHOO.util.DataSource(xmlDoc);
                        myDataSource.responseType = YAHOO.util.DataSource.TYPE_XML;
                        myDataSource.responseSchema = {
                            resultNode: "Result",

                            fields: [{key:"No", parser:"number"},
                              {key:"PageKey"},
                              {key:"PageName"},
                              {key:"PageLink"},
                              {key:"BookName"},
                              {key:"LastModifiedBy"},
                              {key:"LastModifiedName"},
                              {key:"LastModifiedTime"}]
                        };


                    oConfigs = { paginator: new YAHOO.widget.Paginator({rowsPerPage:200}), initialRequest:"results=99999999"};

                    myDataTable = new YAHOO.widget.DataTable(
                                      "searchresultdiv",
                                      myColumnDefs,
                                      myDataSource,
                                      oConfigs,
                                      {caption:"",sortedBy:{key:"No",dir:"desc"}}
                        );


                    },
                    failure: function(o)
                    {
                        // hide the loading panel.
                        YAHOO.example.container.wait.hide();
                    }
                };

                var servletURL = "<%ar.write(servletURL);%>";

                var getXML = YAHOO.util.Connect.asyncRequest("GET",servletURL, connectionCallback);

                return {
                    oDS: myDataSource,
                    oDT: myDataTable
                };
            }();

            document.getElementById("resultsLbl").firstChild.nodeValue = "Search Results for : " + document.searchForm.qs.value;
        }

        var actBtn1 = new YAHOO.widget.Button("actBtn1");
        var actBtn2 = new YAHOO.widget.Button("actBtn2");

        actBtn1.on('click', performSearchAndDisplayResults);
        actBtn2.on('click', resetControls);

    </script>

<%
    if (qs != null) {
%>
    <script>
        performSearchAndDisplayResults();
    </script>
<%
    }
%>

<a href="<%ar.writeHtml(servletURL);%>">xml data</a>

<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>

