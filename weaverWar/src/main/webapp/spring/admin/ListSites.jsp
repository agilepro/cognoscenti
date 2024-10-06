<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%

    ar.assertLoggedIn("New Site page should never be accessed when not logged in");
    ar.assertSuperAdmin("Must be a super admin to see new site page");
    UserProfile uProf=ar.getUserProfile();
    
    String filter = ar.defParam("filter", "");
    
    Cognoscenti cog = Cognoscenti.getInstance(request);
    List<AddressListEntry> allEmail = new ArrayList<AddressListEntry>();
    
    JSONArray allSites = new JSONArray();
    for (NGPageIndex ngpi : cog.getAllSites()){
        NGBook site = ngpi.getSite();
        JSONObject jo = site.getConfigJSON();
        WorkspaceStats stats = site.getRecentStats();
        jo.put("stats", stats.getJSON());
        allSites.put(jo);
        
        for (AddressListEntry ale : site.getPrimaryRole().getExpandedPlayers(site)) {
            AddressListEntry.addIfNotPresent(allEmail, ale);
        }
        for (AddressListEntry ale : site.getSecondaryRole().getExpandedPlayers(site)) {
            AddressListEntry.addIfNotPresent(allEmail, ale);
        }
    }
    
    boolean notFirstTime = false;
    StringBuilder emailAddressList = new StringBuilder();
    for (AddressListEntry ale : allEmail) {
        if (notFirstTime) {
            emailAddressList.append(",\n");
        }
        notFirstTime = true;
        emailAddressList.append(ale.getEmail());
    }

%>
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    $scope.allSites = <%allSites.write(out,2,4);%>;
    $scope.showSiteDate = true;
    $scope.showWSDate = true;
    $scope.showOwners = true;
    $scope.filterChars = "<%=filter%>";
    

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.notDone = function(rec) {
        return (rec.status == "requested");
    }

    $scope.sortSites = function() {
        $scope.allSites.sort( function(a,b) {
            return (b.stats.recentChange-a.stats.recentChange);
        });
    }
    $scope.sortSites();
    $scope.addAdmin = function(rec) {
        if (confirm("Are you sure you want to add youself as an owner of the site: "
                    +rec.names[0]+" ("+rec.key+")")) {
            var siteKey = rec.key;
            var postURL = "takeOwnershipSite.json";
            var postObj = {};
            postObj.key = rec.key;
            var postdata = angular.toJson(postObj);
            $scope.showError=false;
            $http.post(postURL, postdata)
            .success( function(data) {
                var newList = [];
                $scope.allSites.forEach( function(item) {
                    if (item.key==siteKey) {
                        newList.push(data);
                    }
                    else {
                        newList.push(item);
                    }
                });
                $scope.allSites = newList;
            })
            .error( function(data, status, headers, config) {
                $scope.reportError(data);
            });
        }
    };
    
    $scope.filterSites = function() {
        if (!$scope.filterChars) {
            return $scope.allSites;
        }
        var filter = $scope.filterChars.toLowerCase();
        var ret = [];
        $scope.allSites.forEach( function(item) {
            if (item.names[0].toLowerCase().indexOf(filter)>=0) {
                ret.push(item);
            }
            else if (item.key.toLowerCase().indexOf(filter)>=0) {
                ret.push(item);
            }
        });
        return ret;
    }
    
    $scope.garbageCollect = function(rec) {
        if (confirm("Are you sure you want to delete parts from site: "
                    +rec.names[0]+" ("+rec.key+")")) {
            var siteKey = rec.key;
            var postURL = "garbageCollect.json";
            var postObj = {};
            postObj.key = rec.key;
            var postdata = angular.toJson(postObj);
            $scope.showError=false;
            $http.post(postURL, postdata)
            .success( function(data) {
                console.log("GC got success: ", data);
                var newList = [];
                $scope.allSites.forEach( function(item) {
                    if (item.key!=siteKey) {
                        newList.push(item);
                    }
                });
                $scope.allSites = newList;
            })
            .error( function(data, status, headers, config) {
                $scope.reportError(data);
            });
        }
    };
    
});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="h1">
        All Sites
    </div>
    
    <p>
        Filter
           <input type="text" ng-model="filterChars"/>
        Include 
           <input type="checkBox" ng-model="showSiteDate"> Site Change
           <input type="checkBox" ng-model="showWSDate"> WS Change
           <input type="checkBox" ng-model="showOwners"> Owners   
    </p>

    <div id="accountRequestDiv">
        <table class="table">
            <thead>
                <tr>
                    <th></th>
                    <th >ID</th>
                    <th >Site Name</th>
                    <th  ng-show="showSiteDate">Site Change</th>
                    <th ng-show="showWSDate">WS Change</th>
                    <th >Status</th>
                    <th ng-show="showOwners">Owners</th>
                    <th >WS</th>
                    <th >Topics</th>
                    <th >Users</th>
                    <th >Meetings</th>
                    <th >Docs</th>
                </tr>
            </thead>
            <tbody>
                <tr ng-repeat="rec in filterSites()">
                    <td>
                      <div class="dropdown">
                        <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                        <span class="caret"></span></button>
                        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                          <li role="presentation">
                              <a href="SiteDetails.htm?siteKey={{rec.key}}">View Details</a></li>
                          <li role="presentation">
                              <a href="SiteMerge.htm?site={{rec.key}}">See Layouts</a></li>
                          <li role="presentation">
                              <a role="menuitem" ng-click="addAdmin(rec)">Add Yourself to Owners</a></li>
                          <li role="presentation">
                              <a role="menuitem" ng-click="garbageCollect(rec)">Garbage Collect</a></li>
                        </ul>
                      </div>
                    </td>
                    <td>{{rec.key}}</td>
                    <td><a href="../../t/{{rec.key}}/$/SiteStats.htm"><b>{{rec.names[0]}}</b></a></td>
                    <td ng-show="showSiteDate">{{rec.changed|cdate}}</td>
                    <td ng-show="showWSDate">{{rec.stats.recentChange|cdate}}</td>
                    <td><div ng-show="rec.isDeleted">Deleted</div>
                        <div ng-show="rec.frozen">Frozen</div>
                        <div ng-show="rec.offLine">OffLine</div>
                        <div ng-show="rec.movedTo">Moved</div>
                    </td>
                    <td ng-show="showOwners"><div ng-repeat="owner in rec.owners">{{owner.name}}</div></td>
                    <td>{{rec.stats.numWorkspaces}}</td>
                    <td>{{rec.stats.numTopics}}</td>
                    <td>{{rec.stats.numUsers}}</td>
                    <td>{{rec.stats.numMeetings}}</td>
                    <td>{{rec.stats.numDocs}}</td>
                </tr>
            </tbody>
        </table>
    </div>

    <div class="h1">
        Email of all owners and executives
    </div>
    
<pre>
<% ar.writeHtml(emailAddressList.toString()); %>
</pre>

</div>

