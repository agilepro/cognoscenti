<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.EmailRecord"
%><%@page import="org.socialbiz.cog.OptOutAddr"
%><%

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    ar.assertMember("Must be a member to see meetings");
    NGBook ngb = ngw.getSite();

    JSONArray eGenList = ngw.getJSONEmailGenerators(ar);
    
    //email must have a subject otherwise the UI will no allow selection of it
    for (int i=0; i<eGenList.length(); i++) {
        JSONObject oneEmail = eGenList.getJSONObject(i);
        String subject = oneEmail.getString("subject");
        if (subject.trim().length()==0) {
            oneEmail.put("subject", "No Subject");
        }
    }

%>

<script>

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Email Prepared");
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

    $scope.deleteEmail = function(rec) {
        rec.deleteIt = true;
        var postURL = "emailGeneratorUpdate.json?id="+rec.id;
        var postdata = angular.toJson(rec);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            var newList = [];
            $scope.eGenList.forEach( function(item) {
                if (item.id != rec.id) {
                    newList.push(item);
                }
            });
            $scope.eGenList = newList;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }

});

</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

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
            <td ng-show="rec.state<=1">
              <a role="menuitem" tabindex="-1" title="Delete Email" href="#" ng-click="deleteEmail(rec)">
                <button type="button" name="delete" class='btn btn-warning'>
                    <span class="fa fa-trash"></span>
                </button>
              </a>
            </td>
            <td ng-hide="rec.state<=1">{{bestDate(rec)|date:'M/d/yy H:mm'}}</td>
        </tr>
    </table>

</div>


