<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.SiteRequest"
%><%@page import="com.purplehillsbooks.weaver.SiteReqFile"
%><%@page import="com.purplehillsbooks.weaver.WorkspaceStats"
%><%
    ar.assertLoggedIn("Must be logged in to see anything about a user");

    UserProfile uProf = (UserProfile)request.getAttribute("userProfile");
    if (uProf == null) {
        throw WeaverException.newBasic("Can not find that user profile to display.");
    }

    UserProfile  operatingUser =ar.getUserProfile();
    if (operatingUser==null) {
        //this should never happen, and if it does it is not the users fault
        throw WeaverException.newBasic("user profile setting is null.  No one appears to be logged in.");
    }

    boolean viewingSelf = uProf.getKey().equals(operatingUser.getKey());

    JSONArray siteList = new JSONArray();
    for (NGBook site : uProf.findAllMemberSites()) {
        JSONObject jObj = new JSONObject();
        jObj.put("siteKey",  site.getKey());
        jObj.put("siteDesc", site.getDescription());
        jObj.put("siteName",     site.getFullName());
        WorkspaceStats stats = site.getRecentStats();
        jObj.put("numWorkspaces", stats.numWorkspaces);
        jObj.put("numTopics", stats.numTopics);
        siteList.put(jObj);
    }

    JSONArray requestList = new JSONArray();
    JSONArray superList = new JSONArray();

    boolean isSuper = ar.isSuperAdmin();
    SiteReqFile siteReqFile = new SiteReqFile(ar.getCogInstance());
    List<SiteRequest> allRequests = siteReqFile.getAllSiteReqs();
    for (SiteRequest oneRequest: allRequests) {
        if(uProf.hasAnyId(oneRequest.getRequester())) {
            requestList.put(oneRequest.getJSON());
        }
        if (isSuper && oneRequest.getStatus().equalsIgnoreCase("requested")) {
            superList.put(oneRequest.getJSON());
        }
    }
%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Sites You Participate In");
    $scope.siteList = <%siteList.write(out,2,4);%>;
    $scope.requestList = <%requestList.write(out,2,4);%>;
    $scope.superList = <%superList.write(out,2,4);%>;
    $scope.filter = "";
    $scope.reqNum = <%=requestList.length()%>;

    $scope.showInput = false;
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
  <div class="userPageContents">

  <%@include file="../jsp/ErrorPanel.jsp"%>


    <a class="btn btn-default btn-raised" href="NewSiteRequest.htm">Request New Site</a>
    
    <div class="generalContent">
        <table class="table" width="100%">
            <tr>
                <td>Site Name</td>
                <td>Site Description</td>
                <td>Workspaces</td>
                <td>Topics</td>
            </tr>
            <tr ng-repeat="rec in siteList">
                <td>
                    <a href="<%=ar.retPath%>t/{{rec.siteKey}}/$/SiteWorkspaces.htm" title="navigate to the site">{{rec.siteName}}</a>
                </td>
                <td>{{rec.siteDesc}}</td>
                <td>{{rec.numWorkspaces}}</td>
                <td>{{rec.numTopics}}</td>
            </tr>
        </table>

    </div>

    <div class="guideVocal" ng-show="siteList.length==0">
        <p ng-show="reqNum>0">User <% uProf.writeLink(ar); %> has requested {{reqNum}} sites.</p>
        <p ng-show="reqNum==0"><b>User <% uProf.writeLink(ar); %> does not have any sites.</b></p>
        <p>A site is required if you want to create your own projects in your own space.  Every workspace belongs to one site.</p>

        <p>You do not need an site in order to participate on projects that have already been created.<br/>
        Other site owners may give you permission to create projects in their sites.</p>

        <form name="createAccountForm" method="GET" action="NewSiteRequest.htm">
            <input type="submit" class="btn btn-sm"  Value="Request New Site">
        </form>
        <p>Use this button to request an site from the system administrator.</p>

        <p>If approved, you will be able to create your own new projects in your site, <br/>
        and you will be able to authorize others to create projects in your site.</p>

    </div>

    <div class="h1" ng-show="requestList.length>0"><br/>Status of Site Requests</div>
    <div class="generalContent" ng-show="requestList.length>0">
        <div id="accountRequestPaging"></div>
        <div id="accountRequestDiv">
            <table class="table" width="100%">
                <tr class="gridTableHeader">
                    <td>Proposed Name</td>
                    <td>Description</td>
                    <td>Status</td>
                    <td>Date</td>
                </tr>
                <tr ng-repeat="rec in requestList">
                    <td>
                        <span ng-show="rec.status=='Granted'">
                            <a href="<%=ar.retPath%>t/{{rec.siteId}}/$/SiteWorkspaces.htm">{{rec.siteName}}</a>
                        </span>
                        <span ng-hide="rec.status=='Granted'">{{rec.siteName}}</span>
                    </td>
                    <td>{{rec.purpose}}</td>
                    <td>{{rec.status}}</td>
                    <td>{{rec.modTime |cdate}}</td>
                </tr>
            </table>
        </div>
    </div>

  </div>
</div>

