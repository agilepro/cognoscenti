<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.SiteRequest"
%><%@page import="com.purplehillsbooks.weaver.SiteReqFile"
%><%@page import="com.purplehillsbooks.weaver.WorkspaceStats"
%><%
    ar.assertLoggedIn("Must be logged in to see anything about a user");

    UserProfile uProf = (UserProfile)request.getAttribute("userProfile");
    if (uProf == null) {
        throw new NGException("nugen.exception.cant.find.user",null);
    }

    UserProfile  operatingUser =ar.getUserProfile();
    if (operatingUser==null) {
        //this should never happen, and if it does it is not the users fault
        throw new ProgramLogicError("user profile setting is null.  No one appears to be logged in.");
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


    <a class="btn-comment btn-raised m-4" href="NewSiteRequest.htm">Request New Site</a>
    
    <div class="generalContent my-4">
        <div class="col-12 table">
            <div class="row">
                <span class="col-2 my-3 ms-3 h5 text-secondary">Site Name</span>
                <span class="col-5 my-3 ms-3 h5 text-secondary">Site Description</span>
                <span class="col-2 my-3 ms-3 h5 text-secondary">Workspaces</span>
                <span class="col-2 my-3 ms-3 h5 text-secondary">Topics</span><hr>
            </div>
            
            <div class="row " ng-repeat="rec in siteList">
                <span class="col-2 my-3 ms-3 text-secondary ">
                    <a href="<%=ar.retPath%>t/{{rec.siteKey}}/$/SiteWorkspaces.htm" title="navigate to the site" class="bg-transparent">{{rec.siteName}}</a>
                </span>
                <span class="col-5 my-3 ms-3 text-secondary">{{rec.siteDesc}}</span>
                <span class="col-2 my-3 ms-3 text-secondary">{{rec.numWorkspaces}}</span>
                <span class="col-2 my-3 ms-3 text-secondary">{{rec.numTopics}}</span>
            </div>
        </div>
<div class="container-fluid mx-3">
    <div class="guideVocal" ng-show="siteList.length==0">
        <p ng-show="reqNum>0">User <% uProf.writeLink(ar); %> has requested {{reqNum}} sites.</p>
        <p ng-show="reqNum==0"><b>User <% uProf.writeLink(ar); %> does not have any sites.</b></p>
        <p>A site is required if you want to create your own projects in your own space.  Every workspace belongs to one site.</p>

        <p>You do not need a site in order to participate in workspaces that have already been created.<br/>
        Other site owners may give you permission to create workspaces in their sites.</p>

        <form name="createAccountForm" method="GET" action="NewSiteRequest.htm">
            <input type="submit" class="btn btn-sm btn-comment btn-wide btn-primary"  Value="Request New Site">
        </form>
        <br/>
        <p>Use this button to request a new site from the system administrator.</p>

        <p>If approved, you will be able to create your own new workspaces in your site, <br/>
        and you will be able to authorize others to create workspaces in your site.</p>

    </div>

    <div class="h1" ng-show="requestList.length>0"><br/>Status of Site Requests</div>
    <div class="generalContent" ng-show="requestList.length>0">
        <div id="accountRequestPaging"></div>
        <div id="accountRequestDiv">
            <div class="col-12 table">
                <div class="row">
                    <span class="col-2 my-3 ms-3 h5 text-secondary">Proposed Name</span>
                    <span class="col-5 my-3 ms-3 h5 text-secondary">Description</span>
                    <span class="col-2 my-3 ms-3 h5 text-secondary">Status</span>
                    <span class="col-2 my-3 ms-3 h5 text-secondary">Date</span>
                </div>
                <div class="row" ng-repeat="rec in requestList">
                    <span class="col-2 my-3 ms-3 h5 text-secondary">
                        <span ng-show="rec.status=='Granted'">
                            <a href="<%=ar.retPath%>t/{{rec.siteId}}/$/SiteWorkspaces.htm">{{rec.siteName}}</a>
                        </span>
                        <span ng-hide="rec.status=='Granted'">{{rec.siteName}}</span>
                    </span>
                    <span class="col-5 my-3 ms-3 h5 text-secondary">{{rec.purpose}}</span>
                    <span class="col-2 my-3 ms-3 h5 text-secondary">{{rec.status}}</span>
                    <span class="col-2 my-3 ms-3 h5 text-secondary">{{rec.modTime |cdate}}</span>
                </div>
            </div>
        </div>
    </div>

  </div>
</div>

