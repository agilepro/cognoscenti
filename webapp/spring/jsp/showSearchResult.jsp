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

    JSONArray allResults = new JSONArray();
    for (SearchResultRecord srr : searchResults) {
        JSONObject oneRes = new JSONObject();
        oneRes.put("pageLink", srr.getPageLink());
        oneRes.put("pageName", srr.getPageName());
        oneRes.put("noteLink", srr.getNoteLink());
        oneRes.put("noteSubject", srr.getNoteSubject());
        allResults.put(oneRes);
    }

    JSONArray allSites = new JSONArray();
    for(NGBook site : NGBook.getAllSites())
    {
        JSONObject oneSite = new JSONObject();
        oneSite.put("name",site.getFullName());
        oneSite.put("key", site.getKey());
        allSites.put(oneSite);
    }

%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http, $modal) {
    $scope.allResults = <%allResults.write(out,2,4);%>;
    $scope.allSites = <%allSites.write(out,2,4);%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

});
</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>


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
                    <table id="searchresultTable" class="table">
                        <thead>
                             <tr>
                                 <th >Workspace/Site Name</th>
                                 <th >Topic Subject</th>
                             </tr>
                         </thead>
                         <tbody>
                            <tr ng-repeat="srr in allResults">
                                <td>
                                    <a href="<%=ar.baseURL%>{{srr.pageLink}}" title='Access Workspace/Site'>
                                        {{srr.pageName}}
                                    </a>
                                </td>
                                <td>
                                    <a href="<%=ar.baseURL%>{{srr.noteLink}}" title='Access Topic'>
                                        {{srr.noteSubject}}
                                    </a>
                                </td>
                            </tr>
                         </tbody>
                    </table>
                </div>
        </div>

</div>

