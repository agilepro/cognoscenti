<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.Ledger"
%><%

    ar.assertLoggedIn("New Site page should never be accessed when not logged in");
    ar.assertSuperAdmin("Must be a super admin to see new site page");
    UserProfile uProf=ar.getUserProfile();
    
    Cognoscenti cog = Cognoscenti.getInstance(request);
    String siteKey = ar.reqParam("siteKey");
    
    NGBook theSite = cog.getSiteByIdOrFail(siteKey);
    Ledger ledger = theSite.getLedger();
    
    long timestamp = System.currentTimeMillis();
    int year = Ledger.getYear(timestamp);
    int month = Ledger.getMonth(timestamp);
    

%>
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    $scope.theSite = <%theSite.getConfigJSON().write(out,2,4);%>;
    $scope.siteStats = <%theSite.getStatsJSON(cog).write(out,2,4);%>;
    knownKeys = ["executives","changed","owners","names","key","rootFolder"];
    $scope.boolKeys = ["frozen","isDeleted","showExperimental","offLine"];
    $scope.stdKeys = ["workspaceLimit", "frozenLimit", "editUserLimit", "viewUserLimit", "emailLimit", "fileSpaceLimit"];
    for (var propertyName in $scope.theSite) {
        var found = false;
        knownKeys.forEach( function(item) {
           if (propertyName==item) {
               found=true;
           } 
        });
        $scope.boolKeys.forEach( function(item) {
           if (propertyName==item) {
               found=true;
           } 
        });
        $scope.stdKeys.forEach( function(item) {
           if (propertyName==item) {
               found=true;
           } 
        });
        if (!found) {
            $scope.stdKeys.push(propertyName);
        }
    }
    $scope.siteLedger = <%ledger.generateJson().write(out, 2, 4);%>;
    
    
    
    $scope.year = <%=year%>;
    $scope.month = <%=month%>;
    $scope.day = 1;
    $scope.paymentAmt = 0;
    $scope.chargeAmt = 0;
    $scope.planName = "Trial";
    

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
                $scope.theSite = data;
            })
            .error( function(data, status, headers, config) {
                $scope.reportError(data);
            });
        }
    };

    $scope.saveProp = function(propName) {
        if (confirm("Are you sure?\n"+$scope.theSite[propName])) {
            var postURL = "../../t/" + $scope.theSite.key + "/$/updateSiteInfo.json";
            var postObj = {};
            postObj[propName] = $scope.theSite[propName];
            postObj.key = $scope.theSite.key;
            var postdata = angular.toJson(postObj);
            $scope.showError=false;
            $http.post(postURL, postdata)
            .success( function(data) {
                $scope.theSite = data;
            })
            .error( function(data, status, headers, config) {
                $scope.reportError(data);
            });
        }
        $scope.editKey='';
    };
    $scope.cancelSave = function() {
        $scope.editKey='';
    }
    $scope.startEdit = function(propName) {
        $scope.editKey=propName;
    }
    $scope.switchAndSave = function(propName) {
        $scope.theSite[propName] = !$scope.theSite[propName];
        $scope.saveProp(propName);
    };
    
    $scope.recordPayment = function() {
        postObj = {};
        postObj.year = $scope.year;
        postObj.month = $scope.month;
        postObj.day = $scope.day;
        postObj.amount = parseFloat($scope.paymentAmt);
        postObj.site = $scope.theSite.key;
        var postURL = "recordPayment.json";
        var postdata = angular.toJson(postObj);
        console.log("SENDING: ", postdata);
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.siteLedger = data;
            alert("payment recorded successfully");
            console.log("PAYMENT: ", data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
        
    }
    $scope.makeCharge = function() {
        postObj = {};
        postObj.year = $scope.year;
        postObj.month = $scope.month;
        postObj.day = $scope.day;
        postObj.amount = parseFloat($scope.chargeAmt);
        postObj.site = $scope.theSite.key;
        var postURL = "updateCharge.json";
        var postdata = angular.toJson(postObj);
        console.log("SENDING: ", postdata);
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.siteLedger = data;
            alert("payment recorded successfully");
            console.log("CHARGE: ", data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.setPlan = function() {
        postObj = {};
        postObj.year = $scope.year;
        postObj.month = $scope.month;
        postObj.day = $scope.day;
        postObj.planName = $scope.planName;
        postObj.site = $scope.theSite.key;
        var postURL = "setPlan.json";
        var postdata = angular.toJson(postObj);
        console.log("SENDING: ", postdata);
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.siteLedger = data;
            alert("plan set successfully");
            console.log("PLAN: ", data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
   
   
});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="h1">
        Sites Details: {{theSite.names[0]}}
    </div>

    <table class="table">
        <thead>
            <tr>
                <th></th>
                <th >Property</th>
                <th >Value</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td></td>
                <td>key</td>
                <td>{{theSite.key}}</td>
            </tr>
            <tr>
                <td></td>
                <td>names</td>
                <td><a href="../../t/{{theSite.key}}/$/SiteStats.htm"><b>{{theSite.names[0]}}</b></a>
                </td>
            </tr>
            <tr>
                <td></td>
                <td>changed</td>
                <td>{{theSite.changed|date}}</td>
            </tr>
            <tr>
                <td></td>
                <td>rootFolder</td>
                <td>{{theSite.rootFolder}}</td>
            </tr>
            <tr>
                <td>
                  <div class="dropdown">
                    <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                    <span class="caret"></span></button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation">
                          <a role="menuitem" ng-click="addAdmin(theSite)">Add Yourself to Owners</a></li>
                    </ul>
                  </div>
                </td>
                <td>owners</td>
                <td><div ng-repeat="u in theSite.owners">{{u.name}} ({{u.uid}})</div>
                </td>
            </tr>
            <tr>
                <td></td>
                <td>executives</td>
                <td><div ng-repeat="u in theSite.executives">{{u.name}} ({{u.uid}})</div>
                </td>
            </tr>
            <tr ng-repeat="key in stdKeys">
                <td>
                  <div class="dropdown">
                    <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                    <span class="caret"></span></button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation">
                          <a role="menuitem" ng-click="startEdit(key)">Edit</a></li>
                    </ul>
                  </div>
                </td>
                <td>{{key}}</td>
                <td>
                    <div ng-hide="key==editKey">{{theSite[key]}}</div>
                    <div ng-show="key==editKey">
                        <input class="form-control" style="width:400px" ng-model="theSite[key]">
                        <button class="btn btn-primary" ng-click="saveProp(key)">Save</button>
                        <button class="btn btn-warning" ng-click="cancelSave()">Cancel</button>
                    </div>
                </td>
            </tr>
            <tr ng-repeat="key in boolKeys">
                <td>
                  <div class="dropdown">
                    <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                    <span class="caret"></span></button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation">
                          <a role="menuitem" ng-click="startEdit(key)">Edit</a></li>
                    </ul>
                  </div>
                </td>
                <td>{{key}}</td>
                <td>
                    <div ng-hide="key==editKey">{{theSite[key]}}</div>
                    <div ng-show="key==editKey">
                        Change to {{!theSite[key]}}?  
                        <button class="btn btn-primary" ng-click="switchAndSave(key)">Save</button>
                        <button class="btn btn-warning" ng-click="cancelSave()">Cancel</button>
                    </div>
                </td>
            </tr>
        </tbody>
    </table>
    
    <hr/>
    
    <div class="well">
    <h2>Site Payment</h2>
        
    <table class="table">
      <tr>
        <td>
          Year
        </td>
        <td>
          <input ng-model="year"/>
        </td>
      </tr>
      <tr>
        <td>
          Month
        </td>
        <td>
          <input ng-model="month"/>
        </td>
      </tr>
      <tr>
        <td>
          Day
        </td>
        <td>
          <input ng-model="day"/>
        </td>
      </tr>
      <tr>
        <td>
          Plan
        </td>
        <td>
          <input ng-model="planName"/>
          <button ng-click="setPlan()">Set Plan</button>
        </td>
      </tr>
      <tr>
        <td>
          Payment
        </td>
        <td>
          <input ng-model="paymentAmt"/>
          <button ng-click="recordPayment()">Record Payment</button>
        </td>
      </tr>
      <tr>
        <td>
          Charge
        </td>
        <td>
          <input ng-model="chargeAmt"/>
          <button ng-click="makeCharge()">Make Charge</button>
        </td>
      </tr>
    </table>
    
    </div>
    
    
    <div>
    <table class="table">
      <tr ng-repeat="plan in siteLedger.plans">
        <td>PLAN</td>
        <td>{{plan.planName}}</td>
        <td>{{plan.year}} / {{ (plan.month + "").padStart(2 ,"0") }}</td>
        <td>End: {{plan.endDate|cdate}}</td>
      </tr>
      <tr ng-repeat="charge in siteLedger.charges">
        <td>CHARGE</td>
        <td>$ {{charge.amount}}</td>
        <td>{{charge.year}} / {{(charge.month + "").padStart(2 ,"0")}}</td>
        <td></td>
      </tr>
      <tr ng-repeat="pay in siteLedger.payments">
        <td>PAYMENT</td>
        <td>$ {{pay.amount}}</td>
        <td>{{pay.year}} / {{(pay.month + "").padStart(2 ,"0")}} / {{(pay.day + "").padStart(2 ,"0")}}</td>
        <td>Detail: {{pay.detail}}</td>
      </tr>
    </table>
    
    </div>
    
</div>


