<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId : This is the id of a Workspace and here it is used to retrieve NGPage.

*/

    ar.assertLoggedIn("Must be logged in to see a list of meetings");


    UserProfile loggedUser = ar.getUserProfile();
    NGPageIndex.clearLocksHeldByThisThread();
    Cognoscenti cog = ar.getCogInstance();

    UserCache userCache = cog.getUserCacheMgr().getCache(loggedUser.getKey());

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

    List<WatchRecord> watchList = loggedUser.getWatchList();

    JSONArray wList = new JSONArray();
    for (WatchRecord wr : watchList) {
        String pageKey = wr.pageKey;
        NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(pageKey);
        if (ngpi==null) {
            continue;
        }
        JSONObject wObj = ngpi.getJSON4List();
        wObj.put("visited", wr.lastSeen);
        wList.put(wObj);
    }

    JSONArray siteList = new JSONArray();
    for (NGBook site : loggedUser.findAllMemberSites()) {
        JSONObject jObj = site.getConfigJSON();
        WorkspaceStats stats = site.getRecentStats(ar.getCogInstance());
        jObj.put("numWorkspaces", stats.numWorkspaces);
        jObj.put("numTopics", stats.numTopics);
        siteList.put(jObj);
    }


%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Home for <%ar.writeJS(loggedUser.getName());%>");
    $scope.futureMeetings  = <%futureMeetings.write(out,2,4);%>;
    $scope.futureMeetings.sort( function(a,b) {
        return a.startTime - b.startTime;
    });
    $scope.openActionItems = <%openActionItems.write(out,2,4);%>;
    $scope.openRounds  = <%openRounds.write(out,2,4);%>;
    $scope.proposals   = <%proposals.write(out,2,4);%>;

    $scope.wList       = <%wList.write(out,2,4);%>;
    $scope.siteList    = <%siteList.write(out,2,4);%>;
    $scope.loggedUser  = <% loggedUser.getJSON().write(out,2,4);%>;

    $scope.openActionItems.sort( function(a,b) {
        return a.duedate-b.duedate;
    });
    $scope.siteList.sort( function(a,b) {
        return a.numWorkspaces-b.numWorkspaces;
    });
    $scope.wList.sort( function(a,b) {
        return b.changed-a.changed;
    });
    $scope.fixNull = function(str) {
        str = str.trim();
        if (str.length==0) {
            return "-No Name-";
        }
        return str;
    }

});
</script>

<style>
.clipping {
    overflow: hidden;
    text-overflow: clip; 
    border-bottom:1px solid #EEEEEE;
    white-space: nowrap
}
</style>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>
    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
          <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
          Options: <span class="caret"></span></button>
          <ul class="dropdown-menu pull-right" role="menu" aria-labelledby="menu1">
            <li role="presentation"><a role="menuitem"
                href="userAlerts.htm">User Alerts</a></li>
            <li role="presentation"><a role="menuitem" href="UserHome.htm?ref=<%=ar.nowTime%>">
          Recalculate Page</a>
            </li>
          </ul>
      </span>
    </div>

    <style>
      .tripleColumn {
          border: 1px solid white;
          border-radius:5px;
          padding:5px;
          background-color:#FFFFFF;
          margin:6px
      }
      .headingfont {
          font-family: Arial, Helvetica, Verdana, sans-serif;
          font-size:20px;
          font-weight:normal;
      }
    </style>

<!-- COLUMN 1 -->
    <div class="col-md-4 col-sm-12">

        <div class="panel panel-default">
          <div class="panel-heading headingfont">
              <div style="float:left">Top Action Items</div>
              <div style="float:right">
                  <a href="<%=ar.retPath%>v/<%=loggedUser.getKey()%>/userActiveTasks.htm">
                      <i class="fa fa-list"></i></a></div>
              <div style="clear:both"></div>
          </div>
          <div class="panel-body">
            <div  ng-repeat="item in openActionItems | limitTo: 10" class="clipping">
                <img src="<%=ar.retPath%>/assets/goalstate/small{{item.state}}.gif">
                 <a href="<%=ar.retPath%>t/{{item.siteKey}}/{{item.projectKey}}/task{{item.id}}.htm">
                 {{item.synopsis}}</a>
            </div>
            <div ng-show="openActionItems.length>10">
                 <a href="<%=ar.retPath%>v/<%=loggedUser.getKey()%>/userActiveTasks.htm" class="btn btn-sm btn-default btn-raised">See all action items...</a>
            </div>
          </div>
        </div>

        <div class="panel panel-default">
          <div class="panel-heading headingfont">
              <div style="float:left">Upcoming Meetings</div>
              <div style="float:right">
                  <a href="<%=ar.retPath%>v/<%=loggedUser.getKey()%>/UserHome.htm">
                      <i class="fa fa-list"></i></a></div>
              <div style="clear:both"></div>
          </div>
          <div class="panel-body">
            <div  ng-repeat="item in futureMeetings | limitTo: 10"  class="clipping">

                 <a href="<%=ar.retPath%>t/{{item.siteKey}}/{{item.workspaceKey}}/{{item.address}}">
                 {{item.name}} @ {{item.startTime|date}}</a>
            </div>
            <!-- should have a button here to get to all meetings -->
          </div>
        </div>


    </div>


<!-- COLUMN 2 -->
    <div class="col-md-4 col-sm-12">


        <div class="panel panel-default">
          <div class="panel-heading headingfont">
              <div style="float:left">Need to Respond</div>
              <div style="float:right">
                  <a href="<%=ar.retPath%>v/<%=loggedUser.getKey()%>/userMissingResponses.htm">
                      <i class="fa fa-list"></i></a></div>
              <div style="clear:both"></div>
          </div>
          <div class="panel-body">
              <div ng-repeat="item in proposals | limitTo: 10" class="clipping">
                 <a href="<%=ar.retPath%>t/{{item.siteKey}}/{{item.workspaceKey}}/{{item.address}}">{{item.content}}</a>
               </div>
               <div ng-show="proposals.length>10">
                 <a href="<%=ar.retPath%>v/<%=loggedUser.getKey()%>/userMissingResponses.htm" class="btn btn-sm btn-default btn-raised">See all ...</a>
               </div>
          </div>
        </div>



        <div class="panel panel-default">
          <div class="panel-heading headingfont">
              <div style="float:left">Need to Complete</div>
              <div style="float:right">
                  <a href="<%=ar.retPath%>v/<%=loggedUser.getKey()%>/userOpenRounds.htm">
                      <i class="fa fa-list"></i></a></div>
              <div style="clear:both"></div>
          </div>
          <div class="panel-body">
               <div ng-repeat="item in openRounds | limitTo: 10" class="clipping">
                 <a href="<%=ar.retPath%>t/{{item.siteKey}}/{{item.workspaceKey}}/{{item.address}}">{{fixNull(item.content)}}</a>
               </div>
               <div ng-show="openRounds.length>10">
                 <a href="<%=ar.retPath%>v/<%=loggedUser.getKey()%>/userOpenRounds.htm" class="btn btn-sm btn-default btn-raised">See all...</a>
               </div>
          </div>
       </div>
    </div>


<!-- COLUMN 3 -->
    <div class="col-md-4 col-sm-12">

        <div class="panel panel-default">
          <div class="panel-heading headingfont">
              <div style="float:left">Workspaces you Watch</div>
              <div style="float:right">
                  <a href="<%=ar.retPath%>v/<%=loggedUser.getKey()%>/watchedProjects.htm">
                      <i class="fa fa-list"></i></a></div>
              <div style="clear:both"></div>
          </div>
          <div class="panel-body">
               <div ng-repeat="item in wList | limitTo: 10" class="clipping">
                   <a href="<%=ar.retPath%>t/{{item.siteKey}}/{{item.pageKey}}/frontPage.htm">
                   {{item.name}}
                   </a>
               </div>
               <div ng-show="wList.length>10">
                 <a href="<%=ar.retPath%>v/<%=loggedUser.getKey()%>/watchedProjects.htm" class="btn btn-sm btn-default btn-raised">See all...</a>
               </div>
          </div>
        </div>



        <div class="panel panel-default">
          <div class="panel-heading headingfont">
              <div style="float:left">Sites you Manage</div>
              <div style="float:right">
                  <a href="<%=ar.retPath%>v/<%=loggedUser.getKey()%>/userAccounts.htm">
                      <i class="fa fa-list"></i></a></div>
              <div style="clear:both"></div>
          </div>
          <div class="panel-body">
               <div ng-repeat="item in siteList | limitTo: 10" class="clipping">
                   <a href="<%=ar.retPath%>t/{{item.key}}/$/accountListProjects.htm">
                   {{item.names[0]}}
                   </a>
               </div>
               <div ng-show="siteList.length>10">
                 <a href="<%=ar.retPath%>v/<%=loggedUser.getKey()%>/userAccounts.htm" class="btn btn-sm btn-default btn-raised">See all...</a>
               </div>
               </ul>
           </div>
       </div>
    </div>


</div>
