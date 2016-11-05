<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.EmailRecord"
%><%@page import="org.socialbiz.cog.OptOutAddr"
%><%

    String pageId      = ar.reqParam("pageId");
    NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngw);
    ar.assertMember("Must be a member to see meetings");
    NGBook ngb = ngw.getSite();

    JSONArray eGenList = ngw.getJSONEmailGenerators(ar);



%>

<script>

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.eGenList = <%eGenList.write(out,2,4);%>;
    $scope.filter = "";
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.bestDate = function(rec) {
        if (rec.state==2) {
            return rec.scheduleTime;
        }
        else if (rec.state==3) {
            return rec.sendDate;
        }
        else return (new Date()).getTime();
    }
    $scope.sortInverseChron = function() {
        var nowTime = (new Date()).getTime();
        $scope.eGenList.sort( function(a, b){
            return $scope.bestDate(b)-$scope.bestDate(a);
        });
    };
    $scope.sortInverseChron();
    $scope.getFiltered = function() {
        var searchVal = $scope.filter.toLowerCase();
        if ($scope.filter==null || $scope.filter.length==0) {
            return $scope.eGenList;
        };
        var res = [];
        $scope.eGenList.map( function(oneEmail) {
            var foundIt = oneEmail.subject.toLowerCase().indexOf(searchVal)>=0;
            oneEmail.alsoTo.map( function( oneTo ) {
                if (oneTo.uid.toLowerCase().indexOf(searchVal)>=0) {
                    foundIt = true;
                }
            });
            oneEmail.attachments.map( function( oneAtt ) {
                if (oneAtt.name.toLowerCase().indexOf(searchVal)>=0) {
                    foundIt = true;
                }
                else if (oneAtt.description.toLowerCase().indexOf(searchVal)>=0) {
                    foundIt = true;
                }
            });
            if (foundIt) {
                res.push(oneEmail);
            };
        });
        return res;
    }

    $scope.stateName = function(val) {
        if (val<=1) {
            return "Draft";
        }
        if (val==2) {
            return "Scheduled";
        }
        return "Sent";
    }

    $scope.namePart = function(full) {
        var pos = full.indexOf("�");
        if (pos<0) {
            pos = full.indexOf("<");
        }
        if (pos>3) {
            return full.substring(0,pos);
        }
        return full;
    }


});

</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Email Prepared
        </div>
        <!--div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="">Do Nothing</a></li>
            </ul>
          </span>

        </div-->
    </div>


    <div>
        Filter: <input ng-model="filter">
    </div>
    <div style="height:20px;"></div>

    <table class="gridTable2" width="100%">
        <tr class="gridTableHeader">
            <td width="50px">From</td>
            <td width="250px">Subject</td>
            <td width="50px">State</td>
            <td width="100px">Date</td>
        </tr>
        <tr ng-repeat="rec in eGenList">
            <td>{{namePart(rec.from)}}</td>
            <td><a href="sendNote.htm?id={{rec.id}}">{{rec.subject}}</a></td>
            <td>{{stateName(rec.state)}}</td>
            <td>{{bestDate(rec)|date:'M/d/yy H:mm'}}</td>
        </tr>
    </table>

</div>


