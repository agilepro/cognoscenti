<%@page errorPage="/spring2/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.streams.StreamHelper"
%><%@ include file="/include.jsp"
%><%

    ar.assertLoggedIn("New Users page should never be accessed when not logged in");
    if (!ar.isSuperAdmin()) {
        throw new Exception("New Users page should only be accessed by Super Admin");
    }
    JSONArray allUsers = new JSONArray();
    for (UserProfile user : UserManager.getStaticUserManager().getAllUserProfiles()) {
        allUsers.put(user.getFullJSON());
    }


%>
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    $scope.allUsers = <%allUsers.write(out,2,4);%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.filter="";
    
    $scope.updateServer = function(newProfile) {
        console.log("UPDATE PROFILE WITH", newProfile);
        var postURL = "../"+newProfile.key+"/updateProfile.json";
        $http.post(postURL, JSON.stringify(newProfile))
        .success( function(data) {
            var newList = [];
            $scope.allUsers.forEach( function(item) {
                if (item.key == newProfile.key) {
                    newList.push(data);
                }
                else {
                    newList.push(item);
                }
            });
            $scope.allUsers = newList;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    
    $scope.toggleDisabled = function(profile) {
        var newProfile = {};
        newProfile.key = profile.key;
        newProfile.disabled = !profile.disabled;
        $scope.updateServer(newProfile);
    }
    
    $scope.getUsers = function() {
        if (!$scope.filter || $scope.filter.length==0) {
            return $scope.allUsers;
        }
        var filterlc = $scope.filter.toLowerCase();
        var ret=[];
        $scope.allUsers.forEach( function(item) {
            if (item.name.toLowerCase().includes(filterlc)) {
                ret.push(item);
            }
            else if (item.uid.toLowerCase().includes(filterlc)) {
                ret.push(item);
            }
            else if (item.key.toLowerCase().includes(filterlc)) {
                ret.push(item);
            }
        });
        return ret;
    }
    
    $scope.sortUsersStr = function(fieldname) {
        if (fieldname === $scope.currentOrder) {
            console.log("sorting up "+fieldname);
            $scope.allUsers.sort( function(a,b) {
                if (a[fieldname]) {
                    return -(a[fieldname].localeCompare(b[fieldname]))
                }
                return 1;
            });
            $scope.currentOrder = "";
        }
        else {
            console.log("sorting down "+fieldname);
            $scope.allUsers.sort( function(a,b) {
                if (a[fieldname]) {
                    return a[fieldname].localeCompare(b[fieldname])
                }
                return -1;
            });
            $scope.currentOrder = fieldname;
        }
    }
    $scope.currentOrder = "";
    $scope.sortUsersNum = function(fieldname) {
        if (fieldname === $scope.currentOrder) {
            console.log("sorting up "+fieldname);
            $scope.allUsers.sort( function(a,b) {
                if (a[fieldname]>b[fieldname]) {
                    return -1;
                }
                return 1;
            });
            $scope.currentOrder = "";
        }
        else {
            console.log("sorting down "+fieldname);
            $scope.allUsers.sort( function(a,b) {
                if (a[fieldname]>b[fieldname]) {
                    return 1;
                }
                return -1;
            });
            $scope.currentOrder = fieldname;
        }
    }

});

</script>
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

<style>
.sorter {
    cursor:pointer;
    color:blue;
}
</style>

    <div class="h1" style="float:left;margin-top:0px">
            All Users
    </div>
    <div style="float:left;margin-left:30px" class="form-inline">
        <label>Filter</label> &nbsp; <input ng-model="filter" class="form-control"/>
    </div>
    <div style="clear:both"></div>
    
    <div>
        <table class="table">
            <thead>
                <tr>
                    <th>User Name <i class="fa fa-sort sorter" ng-click="sortUsersStr('name')"></i></th>
                    <th>Last Login <i class="fa fa-sort sorter" ng-click="sortUsersNum('lastLogin')"></i></th>
                    <th>Email <i class="fa fa-sort sorter" ng-click="sortUsersStr('uid')"></i></th>
                    <th>Disabled</th>
                    <th>Key <i class="fa fa-sort sorter" ng-click="sortUsersStr('key')"></i></th>
                </tr>
            </thead>
            <tbody>
                <tr ng-repeat="rec in getUsers() | limitTo: 1000">
                    <td><a href="../../v/FindPerson.htm?key={{rec.key}}">{{rec.name}}</a></td>
                    <td>{{rec.lastLogin | cdate}}</td>
                    <td><span ng-repeat="id in rec.ids">{{id}}<br/></span></td>
                    <td>
                        <button ng-hide="rec.disabled" style="background-color:lightgreen" ng-click="toggleDisabled(rec)">Disable</span>
                        <button ng-show="rec.disabled" style="background-color:pink" ng-click="toggleDisabled(rec)">Reenable</span>
                    </td>
                    <td><a href="../../v/FindPerson.htm?key={{rec.key}}">{{rec.key}}</a></td>
                </tr>
            </tbody>
        </table>
    </div>
</div>

