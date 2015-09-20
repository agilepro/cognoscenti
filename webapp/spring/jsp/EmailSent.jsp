<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.EmailRecordMgr"
%><%@page import="org.socialbiz.cog.EmailRecord"
%><%@page import="org.socialbiz.cog.EmailRecordMgr"
%><%@page import="org.socialbiz.cog.OptOutAddr"
%><%

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Must be a member to see meetings");
    NGBook ngb = ngp.getSite();

    JSONArray emailList = new JSONArray();
    for (EmailRecord eRec : ngp.getAllEmail() ) {
        emailList.put(eRec.getJSON());
    }

/* PROTOTYPE EMAIL RECORD
      {
        "from": "Keith local Test <kswenson@us.fujitsu.com>",
        "sendDate": 1431876589439,
        "status": "Sent",
        "subject": "This is a new NOTE",
        "to": ["kswenson@us.fujitsu.com"]
      },
*/


%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.emailList = <%emailList.write(out,2,4);%>;
    $scope.filter = "";
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.sortInverseChron = function() {
        $scope.emailList.sort( function(a, b){
            return b.sendDate - a.sendDate;
        });
    };
    $scope.sortInverseChron();
    $scope.getFiltered = function() {
        var searchVal = $scope.filter.toLowerCase();
        var res = [];
        if ($scope.filter==null || $scope.filter.length==0) {
            res = $scope.emailList;
        }
        else {
            $scope.emailList.map( function(oneEmail) {
                var foundIt = oneEmail.subject.toLowerCase().indexOf(searchVal)>=0;
                oneEmail.to.map( function( oneTo ) {
                    if (oneTo.toLowerCase().indexOf(searchVal)>=0) {
                        foundIt = true;
                    }
                });
                if (foundIt) {
                    res.push(oneEmail);
                };
            });
        }
        res = res.sort( function(a,b) {
            return $scope.bestDate(b)-$scope.bestDate(a);
        });
        return res;
    }
    $scope.namePart = function(val) {
        var pos = val.indexOf('«');
        if (pos<0) {
            pos = val.indexOf('<');
        }
        if (pos<0) {
            return val;
        }
        return val.substring(0,pos);
    }

    $scope.bestDate = function(rec) {
        if (rec.status == "Sent" || rec.status == "Failed") {
            return rec.sendDate;
        }
        else {
            return (new Date()).getTime();
        }
    }
});

</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Email Sent
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="">Do Nothing</a></li>
            </ul>
          </span>

        </div>
    </div>


        <div>
            Filter: <input ng-model="filter">
        </div>
        <div style="height:20px;"></div>
        <table class="gridTable2" width="100%">
            <tr class="gridTableHeader">
                <td width="100px">From</td>
                <td width="300px">Subject</td>
                <td width="100px">Recipient</td>
                <td width="50px">Status</td>
                <td width="100px">Send Date</td>
            </tr>
            <tr ng-repeat="rec in getFiltered()|limitTo: 50">
                <td>{{namePart(rec.from)}}</td>
                <td>{{rec.subject}}</td>
                <td><span ng-repeat="addr in rec.to">{{addr}}, </span></td>
                <td>{{rec.status}}</td>
                <td>{{bestDate(rec) |date:'M/d/yy H:mm'}}</td>
            </tr>
        </table>

</div>


