<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.RUElement"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.SearchResultRecord"
%><%
/*

Parameters:

    1. searchResultRecord : This request attribute is used to get the Array of search result (SearchResultRecord[]).

*/

    List<SearchResultRecord> searchResults  = (List<SearchResultRecord>)request.getAttribute("searchResults");
    String searchText = ar.defParam("searchText", "");
    String b = ar.defParam("b", "All Books");
    String pf = ar.defParam("pf", "all");

%>

<body class="yui-skin-sam">

<div class="generalArea">
<form action="searchPublicNotes.htm" method="get" name="searchForm">
  <div class="generalHeading">Search for Content &nbsp;</div>
  <div class="generalContent">
    <div style="background-color:#f5f5f5; padding:10px">
      <table>
        <tr height="30px">
          <td width="120px"><b>Search Filter:</b></td>
          <td></td>
          <td>
            <select style="width:200px" name="pf">
              <option value="all" selected><fmt:message key="nugen.serach.filter.allProjects"/></option>
              <option value="member"><fmt:message key="nugen.serach.filter.userAsMemberProjects"/></option>
              <option value="admin"><fmt:message key="nugen.serach.filter.userAsOwnerProjects"/></option>
            </select> &nbsp;
            <select style="width:200px" name="b">
                <option value="All Books" selected="selected"><fmt:message key="nugen.serach.filter.AllAccounts"/></option>
                <%
                    for(NGBook site : NGBook.getAllSites())
                    {
                        String aname = site.getFullName();
                        String akey = site.getKey();
                        %>
                       <option value="<%ar.writeHtml(akey);%>"><%ar.writeHtml(aname);%></option><%
                    }
                %>
            </select>
          </td>
        </tr>
        <tr>
          <td width="120px"><b><fmt:message key="nugen.serach.textbox.label"/></b></td>
          <td></td>
          <td style="padding-bottom:6px"> <input type="text"  name="searchText" size="46" value="<%ar.writeHtml(searchText);%>"/>
        </tr>
        <tr>
          <td width="120px"></td>
          <td></td>
          <td><button type="submit" name="action" value="Search"><fmt:message key="nugen.serach.button.label"/></button></td>
        </tr>
      </table>
      <input type="hidden" name="encodingGuard" value="%E6%9D%B1%E4%BA%AC"/>
    </div>
  </div>
</form>
</div>


    <br/><div class="seperator">&nbsp;</div>
    <div class="generalHeading"><label id="resultsLbl">Search Result</label></div>
        <div id="container">
            <div id="searchresultdiv">
                    <table id="searchresultTable">
                        <thead>
                             <tr>
                                 <th >Project/Account Name</th>
                                 <th >Note Subject</th>
                             </tr>
                         </thead>
                         <tbody>
                        <%
                        for(SearchResultRecord srr : searchResults){
                        %>
                            <tr>
                                <td>
                                    <a href="#" onclick="return goToLink('<%=ar.baseURL%><%=srr.getPageLink()%>')" title='Access Project/Site'>
                                        <%ar.writeHtml(srr.getPageName());%>
                                    </a>
                                </td>
                                <td>
                                    <a href="#" onclick="return goToLink('<%=ar.baseURL%><%=srr.getNoteLink()%>')" title='Access Note'>
                                        <%ar.writeHtml(srr.getNoteSubject());%>
                                    </a>
                                </td>
                            </tr>


                        <%}
                        %>
                         </tbody>
                    </table>
                </div>
        </div>


<%@ include file="functions.jsp"%>
 </body>

<script type="text/javascript">
        function goToLink(link){
            document.location = link;
            return true;
        }
        YAHOO.util.Event.addListener(window, "load", function()
        {
            YAHOO.example.EnhanceFromMarkup = function()
            {
                var myColumnDefs = [
                    {key:"Project_Account_Name",label:"Project/Site Name",sortable:true,resizeable:true},
                    {key:"Note_Subject",label:"Note Subject",sortable:true,resizeable:true}
                    ];

                var myDataSource = new YAHOO.util.DataSource(YAHOO.util.Dom.get("searchresultTable"));
                myDataSource.responseType = YAHOO.util.DataSource.TYPE_HTMLTABLE;
                myDataSource.responseSchema = {
                    fields: [
                            {key:"Project_Account_Name"},
                            {key:"Note_Subject"}
                            ]
                };

                var oConfigs = {
                    paginator: new YAHOO.widget.Paginator({
                        rowsPerPage: 200
                    }),
                    initialRequest: "results=999999"
                };

                var myDataTable = new YAHOO.widget.DataTable("searchresultdiv", myColumnDefs, myDataSource, oConfigs,
                {caption:"",sortedBy:{key:"Project_Account_Name",dir:"Project_Account_Name"}});

                return {
                    oDS: myDataSource,
                    oDT: myDataTable
                };
            }();
        });
</script>
