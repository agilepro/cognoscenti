<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%

    ar.assertLoggedIn("New Site page should never be accessed when not logged in");
    ar.assertSuperAdmin("Must be a super admin to see new site page");
    UserProfile uProf=ar.getUserProfile();
    
    String filter = ar.defParam("filter", "");
    int showMonth = 10;
    int showYear = 2024;
    
    Cognoscenti cog = Cognoscenti.getInstance(request);
    List<AddressListEntry> allEmail = new ArrayList<AddressListEntry>();
    
    JSONArray allSites = new JSONArray();
    for (NGPageIndex ngpi : cog.getAllSites()){
        NGBook site = ngpi.getSite();
        JSONObject jo = site.getConfigJSON();
        WorkspaceStats stats = site.getRecentStats();
        jo.put("stats", stats.getJSON());
        Ledger ledger = site.getLedger();
        jo.put("ledger", ledger.generateJson());
        
        LedgerCharge charge = ledger.getChargesOrNull(showYear, showMonth);
        double foundCharge = 0;
        if (charge!=null) {
            foundCharge = charge.amount;
        }
        jo.put("foundCharge", foundCharge);
        
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
    
    $scope.costCreator = 1;
    $scope.costReader = 0;
    $scope.costDocuments = 0;
    $scope.costActive = 2;
    $scope.costFrozen = 0;
    
    

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
    
    $scope.updateAllCosts = function() {
        console.log("updateAllCosts");
        $scope.allSites.forEach( function(item) {
            $scope.calculateCost(item);
        });
    }
    
    $scope.calculateCost = function(item) {
        console.log("ACTIVE = "+$scope.costActive);
        var total = (item.stats.numActive-item.workspaceGratis) * $scope.costActive;
        total = total + ((item.stats.editUserCount-item.editUserGratis) * $scope.costCreator);
        if (total < 0) {
            total = 0;
        }
        item.chargeThisMonth = total;
        return total;
    }
    $scope.updateAllCosts();
    
    $scope.recalcStats = function(site) {
        console.log("recalcStats");
        var getURL = "../../t/"+site.key+"/$/SiteStatistics.json?recalc=yes";
        $scope.showError=false;
        $http.get(getURL)
        .success( function(data) {
            site.stats = data.stats;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    
    $scope.chargeAllSites = function() {
        if (confirm("Are you sure you want to do this?")) {
            $scope.allSites.forEach( function(site) {
                $scope.chargeSite(site);
            });
        }
    };
    
    $scope.clearAllSites = function() {
        if (confirm("Are you sure you want get rid of ALL charges for this month?")) {
            $scope.allSites.forEach( function(site) {
                site.chargeThisMonth = 0;
                $scope.chargeSite(site);
            });
        }
    };
    
    $scope.chargeSite = function(site) {
        var postURL = "updateCharge.json";
        var postObj = {year: <%=showYear%>, month: <%=showMonth%>, site: site.key, amount: site.chargeThisMonth};
        var postdata = angular.toJson(postObj);
        $scope.showError = false;
        $http.post(postURL, postdata)
        .success( function(data) {
            console.log("SUCCESS: charged "+site.key+" == "+site.chargeThisMonth);
            site.foundCharge = site.chargeThisMonth;
            $scope.calculateCost(site);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    
});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<style>
.rightColumn {
    text-align:right;
}
</style>

<%@include file="ErrorPanel.jsp"%>

    <div class="h1">
        Site Cost Calculator Year=<%=showYear%> Month=<%=showMonth%>
    </div>
    
    <p>
        Filter
           <input type="text" ng-model="filterChars"/>
    </p>

    
    <div id="accountRequestDiv">
        <table class="table">
            <thead>
                <tr>
                    <th></th>
                    <th >Site Name</th>
                    <th >Status</th>
                    <th ng-show="showOwners"></th>
                    <th class="rightColumn">Cost</th>
                    <th class="rightColumn">Users</th>
                    <th class="rightColumn">Doc MB</th>
                    <th class="rightColumn">workspace</th>
                </tr>
            </thead>
            <tbody>
                <tr ng-repeat="rec in filterSites()">
                    <td>
                      <div class="dropdown">
                        <a class="btn btn-default dropdown-toggle" role="button" id="menu1" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                        <span class="caret"></span></a>
                        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                          <li role="presentation">
                              <a href="SiteDetails.htm?siteKey={{rec.key}}">View Details</a></li>
                          <li role="presentation">
                              <a href="SiteMerge.htm?site={{rec.key}}">See Layouts</a></li>
                          <li role="presentation">
                              <a role="menuitem" ng-click="addAdmin(rec)">Add Yourself to Owners</a></li>
                          <li role="presentation">
                              <a role="menuitem" ng-click="garbageCollect(rec)">Garbage Collect</a></li>
                          <li role="presentation">
                              <a role="menuitem" ng-click="recalcStats(rec)">Recalculate Stats</a></li>
                        </ul>
                      </div>
                      <button ng-click="recalcStats(rec)">recalc</button>
                      <button ng-click="chargeSite(rec)">charge</button>
                      <a href="SiteDetails.htm?siteKey={{rec.key}}">View Details</a>
                    </td>
                    <td><a href="../../t/{{rec.key}}/$/SiteAdmin.htm"><b>{{rec.names[0]}}</b></a></td>
                    <td><div ng-show="rec.isDeleted">Deleted</div>
                        <div ng-show="rec.frozen">Frozen</div>
                        <div ng-show="rec.offLine">OffLine</div>
                        <div ng-show="rec.movedTo">Moved</div>
                    </td>
                    <td></td>
                    <td class="rightColumn">
                        <br/>Balance $ {{rec.ledger.balance|number:2}}<br/>
                        (<%=showYear%>/<%=showMonth%>) has $ {{rec.foundCharge|number:2}}<br/>
                        <input ng-model="rec.chargeThisMonth"/>
                        </td>
                    <td class="rightColumn">
                        Paid {{rec.stats.editUserCount}}<br/>
                        Unpaid {{rec.stats.readUserCount}}<br/>
                        Gratis {{rec.editUserGratis}}<br/>
                        $ {{(rec.stats.editUserCount-rec.editUserGratis)*costCreator|number:2}}</td>
                    <td class="rightColumn">
                        {{rec.stats.sizeDocuments/1000000|number:0}}</td>
                    <td class="rightColumn">
                        Active: {{rec.stats.numActive}}<br/>
                        Frozen: {{rec.stats.numFrozen}}<br/>
                        Gratis: {{rec.workspaceGratis}}<br/>
                        $ {{(rec.stats.numActive-rec.workspaceGratis)*costActive|number:2}}</td>
                </tr>
            </tbody>
        </table>
    </div>

    <div class="well">
      <button class="btn btn-primary btn-raised" ng-click="chargeAllSites()">Charge All Sites</button>
      <button class="btn btn-primary btn-raised" ng-click="clearAllSites()">Clear Charges from All Sites</button>
    </div>



    <div class="h1">
        Email of all owners and executives
    </div>
    
<pre>
<% ar.writeHtml(emailAddressList.toString()); %>
</pre>

</div>

