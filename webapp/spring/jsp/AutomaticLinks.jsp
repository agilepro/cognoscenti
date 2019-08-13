<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%@page import="org.socialbiz.cog.NGTerm"
%><%

    ar.assertLoggedIn("Must be logged in to see a list of meetings");

    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    NGPageIndex ngpi = ar.getCogInstance().getWorkspaceBySiteAndKeyOrFail(siteId, pageId);
    ar.setPageAccessLevels(ngp);
    NGWorkspace ngp = ngpi.getWorkspace();
    NGBook ngb = ngp.getSite();


//GET the Recently Visited Workspaces
    JSONArray recentList = new JSONArray();
    NGSession ngsession = ar.ngsession;
    if (ngsession!=null) {
        List<RUElement> recent = ngsession.recentlyVisited;
        RUElement.sortByDisplayName(recent);
        for (RUElement rue : recent) {
            NGPageIndex angpi = ar.getCogInstance().getWSByCombinedKey(rue.key);
            if (angpi!=null && angpi.isProject()) {
                recentList.put(angpi.getJSON4List());
            }
        }
    }

//GET Inbound Link
    JSONArray inboundLinks = new JSONArray();
    for (NGPageIndex refB : ngpi.getInLinkPages()) {
         inboundLinks.put(ngpi.getJSON4List());
    }

//GET Outbound Link
    JSONArray outboundLinks = new JSONArray();
    for (NGPageIndex refB : ngpi.getOutLinkPages()) {
         outboundLinks.put(ngpi.getJSON4List());
    }


//GET all the TAGS and linked projects
    JSONArray allTags = new JSONArray();
    for (NGTerm aTerm : ngpi.hashTags) {
        JSONObject termObj = new JSONObject();
        termObj.put("tag", aTerm.sanitizedName);
        JSONArray projs = new JSONArray();
        for (NGPageIndex projectWithTag : aTerm.targetLeaves) {
            projs.put(projectWithTag.getJSON4List());
        }
        termObj.put("projects", projs);
        allTags.put(termObj);
    }

%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Automatic Links");
    $scope.recentList    = <% recentList.write(out,2,4);%>;
    $scope.allTags       = <% allTags.write(out,2,4);%>;
    $scope.outboundLinks = <% outboundLinks.write(out,2,4);%>;
    $scope.inboundLinks  = <% inboundLinks.write(out,2,4);%>;


    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };


});
</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <table class="table">
      <col width="30%">
      <col width="70%">
      <tr class="gridTableHeader">
        <td>Tag Value</td>
        <td>Workspace Using Tag</td>
      </tr>
      <tr ng-repeat="oneTag in allTags">
        <td>#{{oneTag.tag}}</td>
        <td>
          <div ng-repeat="projs in oneTag.projects">
            <a href="<%=ar.retPath%>t/{{projs.siteKey}}/{{projs.pageKey}}/frontPage.htm">{{projs.name}}</a><br/>
          </div>
        </td>
      </tr>
      <tr class="gridTableHeader">
        <td></td>
        <td>Workspace Links</td>
      </tr>
      <tr>
        <td>To This Workspace</td>
        <td>
          <div ng-repeat="projs in inboundLinks">
            <a href="<%=ar.retPath%>t/{{projs.siteKey}}/{{projs.pageKey}}/frontPage.htm">{{projs.name}}</a><br/>
          </div>
        </td>
      </tr>
      <tr>
        <td>From This Workspace</td>
        <td>
          <div ng-repeat="projs in outboundLinks">
            <a href="<%=ar.retPath%>t/{{projs.siteKey}}/{{projs.pageKey}}/frontPage.htm">{{projs.name}}</a><br/>
          </div>
        </td>
      </tr>
      <tr>
        <td>Recently Visited</td>
        <td>
          <div ng-repeat="projs in recentList">
            <a href="<%=ar.retPath%>t/{{projs.siteKey}}/{{projs.pageKey}}/frontPage.htm">{{projs.name}}</a><br/>
          </div>
        </td>
      </tr>
    </table>

</div>
