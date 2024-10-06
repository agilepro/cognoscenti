<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%




%>

<script>

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    
    $scope.reportError = function(serverErr) {
        console.log("ERROR", serverErr);
        alert("error occurred check browser console");
    };
    
    $scope.queryMailStatus = function() {
        var postURL = "MailProblems.json";
        $http.get(postURL)
        .success( function(data) {
            console.log("MailProblemsUser.json RECEIVED", data);
            $scope.mailBlockers = data.blocks;
            $scope.mailBounces = data.bounces;
            $scope.mailSpams = data.spams;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.queryMailStatus();
    
    $scope.findUser = function(email) {
        window.open("../FindPerson.htm?uid="+email, '_blank');
    }
    
});
</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>


    <div ng-show="mailBlockers" class="well" style="max-width:1000px">
        <h2>Mail Provider Refused to Deliver</h2>
        
        <div ng-show="mailBlockers.length==0">No email blockers found</div>
        
        <table class="table">
            <tr>
                <td>Blocked</td>
                <td>Email</td>
                <td>Reason</td>
                <td>Status</td>
            </tr>
            <tr ng-repeat="block in mailBlockers">
                <td>{{block.created*1000|date}}</td>
                <td ng-click="findUser(block.email)">{{block.email}}</td>
                <td><div style="max-width:400px;">{{block.reason}}</div></td>
                <td>{{block.status}}</td>
            </tr>
        </table>
    
    </div>

    <div ng-show="mailBlockers" class="well" style="max-width:1000px">
        <h2>Mail Bounced due to Address Problems</h2>
        
        <div ng-show="mailBounces.length==0">No bounces found</div>
        
        <table class="table">
            <tr>
                <td>Bounced</td>
                <td>Email</td>
                <td>Reason</td>
                <td>Status</td>
            </tr>
            <tr ng-repeat="block in mailBounces">
                <td>{{block.created*1000|date}}</td>
                <td ng-click="findUser(block.email)">{{block.email}}</td>
                <td><div style="max-width:400px;">{{block.reason}}</div></td>
                <td>{{block.status}}</td>
            </tr>
        </table>
    
    </div>
    <div ng-show="mailSpams" class="well" style="max-width:1000px">
        <h2>Mail Marked by Receiver as Spam</h2>
        
        <div ng-show="mailSpams.length==0">No bounces found</div>
        
        <table class="table">
            <tr>
                <td>Spammed</td>
                <td>Email</td>
                <td>Reason</td>
                <td>Status</td>
            </tr>
            <tr ng-repeat="block in mailSpams">
                <td>{{block.created*1000|date}}</td>
                <td ng-click="findUser(block.email)">{{block.email}}</td>
                <td><div style="max-width:400px;">{{block.reason}}</div></td>
                <td>{{block.status}}</td>
            </tr>
        </table>
    
    </div>
    
    
    <div style="margin:50px"></div>
    
    
</div>    