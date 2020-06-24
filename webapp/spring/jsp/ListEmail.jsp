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
app.controller('myCtrl', function($scope, $http, AllPeople) {
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
    $scope.imageName = function(player) {
        if (player.key) {
            return player.key+".jpg";
        }
        else {
            var lc = player.uid.toLowerCase();
            var ch = lc.charAt(0);
            var i =1;
            while(i<lc.length && (ch<'a'||ch>'z')) {
                ch = lc.charAt(i); i++;
            }
            return "fake-"+ch+".jpg";
        }
    }
    $scope.navigateToUser = function(player) {
        window.location="<%=ar.retPath%>v/FindPerson.htm?uid="+encodeURIComponent(player.key);
    }
    $scope.filteredRecs = function(){
        var filterList = parseLCList($scope.filter);
        if (filterList.length==0) {
            return $scope.eGenList;
        }
        var res = [];
        $scope.eGenList.forEach( function(item) {
            if (containsOne(item.subject, filterList)) {
                res.push(item);
            }
        });
        return res;
    }

});

</script>
<script src="../../../jscript/AllPeople.js"></script>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" href="listEmail.htm">
              Email Prepared</a>
          </li>
          <li role="presentation"><a role="menuitem" href="emailSent.htm">
              Email Sent</a>
          </li>
          <li role="presentation" class="divider"></li>
          <li role="presentation"><a role="menuitem" href="SendNote.htm">
              Create Email</a>
          </li>
        </ul>
      </span>
    </div>
    
    <div>
        Filter: <input ng-model="filter">
    </div>
    <div style="height:20px;"></div>

    <table class="table" width="100%">
        <tr class="gridTableHeader">
            <td width="50px">From</td>
            <td width="250px">Subject</td>
            <td width="50px">State</td>
            <td width="100px">Date</td>
        </tr>
        <tr ng-repeat="rec in filteredRecs()">
            <td>
                  <span class="dropdown">
                    <span id="menu1" data-toggle="dropdown">
                    <img class="img-circle" src="<%=ar.retPath%>icon/{{imageName(rec.fromUser)}}" 
                         style="width:32px;height:32px" title="{{rec.fromUser.name}} - {{rec.fromUser.uid}}">
                    </span>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                          tabindex="-1" ng-click="" style="text-decoration: none;text-align:center">
                          {{rec.fromUser.name}}<br/>{{rec.fromUser.uid}}</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="navigateToUser(rec.fromUser)">
                          <span class="fa fa-user"></span> Visit Profile</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="openInviteSender(rec.fromUser)">
                          <span class="fa fa-envelope-o"></span> Send Invitation</a></li>
                    </ul>
                  </span>
            </td>
            <td><a href="SendNote.htm?id={{rec.id}}">{{rec.subject}}</a></td>
            <td>{{stateName(rec.state)}}</td>
            <td ng-show="rec.state<=1">
              <a role="menuitem" tabindex="-1" title="Delete Email" href="#" ng-click="deleteEmail(rec)">
                <button type="button" name="delete" class='btn btn-warning'>
                    <span class="fa fa-trash"></span>
                </button>
              </a>
            </td>
            <td ng-hide="rec.state<=1">{{bestDate(rec)|date:'dd-MMM-yyyy H:mm'}}</td>
        </tr>
    </table>

</div>


