<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to see a list of meetings");

    String userKey = ar.reqParam("userKey");

    UserProfile loggedUser = ar.getUserProfile();
    UserProfile displayedUser = UserManager.getUserProfileByKey(userKey);
    
    //NGPageIndex.clearLocksHeldByThisThread();
    Cognoscenti cog = ar.getCogInstance();

    UserCache userCache = cog.getUserCacheMgr().getCache(userKey);

    String refresh = ar.defParam("ref", null);
    if (refresh!=null) {
        userCache.refreshCache(cog);
        userCache.save();
    }

    JSONArray actionItems = userCache.getActionItems();
    JSONArray openActionItems = new JSONArray();
    for (int i=0; i<actionItems.length(); i++) {
        JSONObject oneItem = actionItems.getJSONObject(i);
        int state =  oneItem.getInt("state");
        if (state==3 || state==2) {
            openActionItems.put(oneItem);
        }
    }
    JSONArray proposals = userCache.getProposals();
    JSONArray openRounds = userCache.getOpenRounds();
    JSONArray futureMeetings = userCache.getFutureMeetings();
    
    JSONArray accWSpaces = new JSONArray();
    int count = 0;
    for (NGPageIndex ngpi : cog.getWorkspacesUserIsIn(displayedUser)) {
        accWSpaces.put(ngpi.getJSON4List());
    }
    
    JSONObject userCacheJSON = userCache.getAsJSON();

    List<WatchRecord> watchList = displayedUser.getWatchList();

    JSONArray wList = new JSONArray();
    count = 0;
    for (WatchRecord wr : watchList) {
        String pageKey = wr.pageKey;
        NGPageIndex ngpi = ar.getCogInstance().getWSByCombinedKey(pageKey);
        if (ngpi==null) {
            ngpi = ar.getCogInstance().lookForWSBySimpleKeyOnly(pageKey);
        }
        if (ngpi==null) {
            continue;
        }
        JSONObject wObj = ngpi.getJSON4List();
        wObj.put("visited", wr.lastSeen);
        wList.put(wObj);
    }

    JSONArray siteList = new JSONArray();
    for (NGBook site : displayedUser.findAllMemberSites()) {
        JSONObject jObj = site.getConfigJSON();
        WorkspaceStats stats = site.getRecentStats();
        jObj.put("numWorkspaces", stats.numWorkspaces);
        jObj.put("numTopics", stats.numTopics);
        siteList.put(jObj);
    }

%>

<script type="text/javascript">

var myApp = angular.module('myApp');
myApp.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Home for "+"<%ar.writeJS(displayedUser.getName());%>");
    $scope.futureMeetings  = <%futureMeetings.write(out,2,4);%>;
    $scope.futureMeetings.sort( function(a,b) {
        return a.startTime - b.startTime;
    });
    $scope.openActionItems = <%openActionItems.write(out,2,4);%>;
    $scope.openRounds  = <%openRounds.write(out,2,4);%>;
    $scope.proposals   = <%proposals.write(out,2,4);%>;

    $scope.wList       = <%wList.write(out,2,4);%>;
    $scope.accWSpaces  = <%accWSpaces.write(out,2,4);%>;
    
    $scope.siteList    = <%siteList.write(out,2,4);%>;
    $scope.displayedUser  = <% displayedUser.getJSON().write(out,2,4);%>;
    
    $scope.userCache   = <%userCacheJSON.write(out,2,4);%>;

    $scope.openActionItems.sort( function(a,b) {
        return a.duedate-b.duedate;
    });
    $scope.siteList.sort( function(a,b) {
        return a.numWorkspaces-b.numWorkspaces;
    });
    $scope.wList.sort( function(a,b) {
        return b.changed-a.changed;
    });
    $scope.accWSpaces.sort( function(a,b) {
        return b.changed-a.changed;
    });
    $scope.fixNull = function(str) {
        str = str.trim();
        if (str.length==0) {
            return "-No Name-";
        }
        return str;
    }
    $scope.fakeError = function() {
        errorPanelHandler($scope, "This pages makes no calls to server so no real way to cause an error");
    }
});
</script>



<div ng-cloak>

<%@include file="../jsp/ErrorPanel.jsp"%>
<!-- MAIN CONTENT SECTION START -->

<div class="container-fluid">
    <div class="row col-12 d-flex">

<!-- COLUMN 1 -->
    <div class="col-md-4 col-sm-12">

        <div class="card my-2">
          <div class="d-flex align-items-center justify-content-between card-header" title="Access the list of all action items">
              <h3 class="h5 mb-0">Top Action Items</h3><a href="UserActiveTasks.htm"><i class="ms-5 fa fa-check-circle-o"></i>
                  
                      </a></div>
          <div class="card-body">
            <div ng-repeat="item in openActionItems | limitTo: 10" class="clipping">
                <img src="<%=ar.retPath%>new_assets/assets/goalstate/small{{item.state}}.gif">
                 <a href="<%=ar.retPath%>t/{{item.siteKey}}/{{item.projectKey}}/task{{item.id}}.htm">
                 {{item.synopsis}}</a>
            </div>
            <div ng-show="openActionItems.length>10">
                 <a href="UserActiveTasks.htm" 
                      class="btn btn-sm btn-default btn-raised" translate>See all...</a>
            </div>
          </div>
        </div>

        <div class="card my-3">
          <div class="d-flex align-items-center justify-content-between card-header" title="Go to a list of all meetings in the workspace">
              <h5 class="mb-0"><span translate>Planned Meetings</span></h5><a href="MeetingList.htm"><i class="ms-5 fa fa-gavel"></i></a>
          </div>
          <div class="card-body">
            <div  ng-repeat="item in futureMeetings | limitTo: 10"  class="clipping">

                 <a href="<%=ar.retPath%>t/{{item.siteKey}}/{{item.workspaceKey}}/{{item.address}}">
                 {{item.name}}, {{item.startTime|cdate}}</a>
            </div>
            <!-- should have a button here to get to all meetings -->
          </div>
        </div>
    </div>


<!-- COLUMN 2 -->
    <div class="col-md-4 col-sm-12">
        <div class="card my-2">
          <div class="d-flex align-items-center justify-content-between card-header" title="Access the list of response requests">
              <h3 class="h5 mb-0"><span translate>Need to Respond</span></h3>
                  <a href="userMissingResponses.htm">
                      <i class="fa fa-list"></i></a></div>
            <div class="card-body">
                <div ng-repeat="item in proposals | limitTo: 10" class="clipping">
                 <a href="<%=ar.retPath%>t/{{item.siteKey}}/{{item.workspaceKey}}/{{item.address}}">{{item.content}}</a>
                </div>
                <div ng-show="proposals.length>10">
                 <a href="userMissingResponses.htm" 
                     class="btn btn-sm btn-secondary btn-raised" translate>See all...</a>
                </div>
            </div>
        </div>

        <div class="card my-3">
            <div class="d-flex align-items-center justify-content-between card-header" title="Access the list of items to complete and post">
              <h3 class="h5 mb-0"><span translate>Need to Complete</span></h3>
                  <a href="userOpenRounds.htm">
                      <i class="fa fa-list"></i></a>
            </div>
            <div class="card-body">
               <div ng-repeat="item in openRounds | limitTo: 10" class="clipping">
                 <a href="<%=ar.retPath%>t/{{item.siteKey}}/{{item.workspaceKey}}/{{item.address}}">{{fixNull(item.content)}}</a>
               </div>
               <div ng-show="openRounds.length>10">
                 <a href="userOpenRounds.htm" 
                     class="btn btn-sm btn-default btn-raised" translate>See all...</a>
               </div>
            </div>
        </div>

        <div class="card my-3">
            <div class="d-flex align-items-center justify-content-between card-header" title="Access the list of Discussions to complete and post">
                <h3 class="h5 mb-0"><span translate>Draft Discussions</span></h3><a href="userDraftTopics.htm">
                <i class="fa fa-lightbulb-o ms-5"></i></a>
          </div>
          <div class="card-body">
               <div ng-repeat="item in userCache.draftTopics | limitTo: 10" class="clipping">
                 <a href="<%=ar.retPath%>t/{{item.siteKey}}/{{item.workspaceKey}}/noteZoom{{item.id}}.htm">{{fixNull(item.subject)}}</a>
               </div>
          </div>
       </div>
    </div>


<!-- COLUMN 3 -->
    <div class="col-md-4 col-sm-12">

        <div class="card my-2">
          <div class="d-flex align-items-center justify-content-between card-header" title="Access the list of workspaces you are watching">
              <h3 class="h5 mb-0"><span translate>Watched Workspaces</span></h3>
                  <a href="WatchedProjects.htm">
                      <i class="ms-5 fa fa-list"></i></a></div>
          <div class="card-body">
               <div ng-repeat="item in wList | limitTo: 10" class="clipping">
                   <a href="<%=ar.retPath%>t/{{item.siteKey}}/{{item.pageKey}}/FrontPage.htm">
                   {{item.name}}
                   </a>
               </div>
               <div ng-show="wList.length>10">
                 <a href="WatchedProjects.htm" 
                     class="btn btn-sm btn-default btn-raised" translate>See all...</a>
               </div>
          </div>
        </div>

        <div class="card my-3">
          <div class="d-flex align-items-center justify-content-between card-header" title="Access the list of workspaces you can access">
              <h3 class="h5 mb-0"><span translate>Accessible Workspaces</span></h3>
                  <a href="ParticipantProjects.htm">
                      <i class="ms-5 fa fa-list"></i></a></div>
          <div class="card-body">
               <div ng-repeat="item in accWSpaces | limitTo: 10" class="clipping">
                   <a href="<%=ar.retPath%>t/{{item.siteKey}}/{{item.pageKey}}/FrontPage.htm">
                   {{item.name}}
                   </a>
               </div>
               <div ng-show="wList.length>10">
                 <a href="ParticipantProjects.htm" 
                     class="btn btn-sm btn-default btn-raised" translate>See all...</a>
               </div>
          </div>
        </div>


        <div class="card my-3">
          <div class="d-flex align-items-center justify-content-between card-header" title="Access the list of sites you manage">
              <h3 class="h5 mb-0"><span translate>Sites you Manage</span></h3>
                  <a href="userSites.htm">
                      <i class="ms-5 fa fa-list"></i></a></div>
          <div class="card-body">
               <div ng-repeat="item in siteList | limitTo: 10" class="clipping">
                   <a href="<%=ar.retPath%>t/{{item.key}}/$/SiteAdmin.htm">
                   {{item.names[0]}}
                   </a>
               </div>
               <div ng-show="siteList.length>10">
                 <a href="userSites.htm" 
                     class="btn btn-sm btn-default btn-raised" translate>See all...</a>
               </div>
           </div>
       </div>
    </div>
    </div>
</div>
<div class="row"><hr class="divider"> </div>
<div class="row"> 
    <div class="mx-5 col-md-10 d-flex align-items center">

        <a class="btn btn-primary btn-raised m-1" href="UserHome.htm?ref=<%=ar.nowTime%>" translate
            title="{{'Use this option if you want to see changes that occurred in the past 24 hours'|translate}}">
      Recalculate Page</a>
    <a class="btn btn-primary btn-raised m-1" 
        href="UserAlerts.htm" translate
        title="{{'A list of things that have changed in the pages that you watch'|translate}}">
        User Alerts</a> 
    <a class="btn btn-primary btn-raised m-1" 
        href="EmailUser.htm" translate
        title="{{'All email sent to this user'|translate}}">
        Email</a>
    </div>
</div>
</div>




