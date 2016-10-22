<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="functions.jsp"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%@page import="org.socialbiz.cog.AgendaItem"
%><%

    String go = ar.getCompleteURL();
    ar.assertMember("Must be a member to see meetings");

    String pageId      = ar.reqParam("pageId");
    NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngw);
    NGBook ngb = ngw.getSite();
    JSONObject backlogInfo = ngw.getAgendaItemBacklog().getFullJSON(ar, ngw);

%>

<script type="text/javascript">

var app = angular.module('myApp', []);
app.controller('myCtrl', function($scope, $http) {
    $scope.meeting = <%backlogInfo.write(out,2,4);%>;
    $scope.newAgendaItem = {subject:"",duration:5,desc:"",id:""};
    $scope.showInput = false;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.deleteRow = function(row) {
        var delId = row.id;
        var postURL = "agendaDelete.json?id="+$scope.meeting.id;
        var postdata = angular.toJson(row);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            var newSet = [];
            for( var i =0; i<$scope.meeting.agenda.length; i++) {
                var irow = $scope.meeting.agenda[i];
                if (delId != irow.id) {
                    newSet.push(irow);
                }
            }
            $scope.meeting.agenda = newSet;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.createRow = function() {
        var postURL = "agendaAdd.json?id="+$scope.meeting.id;
        var postdata = angular.toJson($scope.newAgendaItem);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {

            $scope.meeting.agenda.push(data);
            $scope.newAgendaItem = {subject:"",duration:5,desc:"",id:""};
            $scope.showInput=false;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.createMinutes = function() {
        var postURL = "createMinutes.json?id="+$scope.meeting.id;
        var postdata = angular.toJson("");
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.meeting = data;
            $scope.showInput=false;
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

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Backlog of Agenda Items
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="showInput=!showInput">Add Agenda Item</a></li>
              <li role="presentation" class="divider"></li>
              <li role="presentation"><a role="menuitem"
                  href="meetingList.htm">List All Meetings</a></li>
            </ul>
          </span>

        </div>
    </div>

        <div id="NewAgenda" class="well" ng-show="showInput" ng-cloak>
            <div class="rightDivContent">
                <a href="#" ng-click="showInput=false"><img src="<%= ar.retPath%>assets/iconBlackDelete.gif"/></a>
            </div>
            <div class="generalSettings">
                <table>
                    <tr id="trspath">
                        <td class="gridTableColummHeader">Subject:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2"><input type="text" ng-model="newAgendaItem.subject" class="form-control" size="69" /></td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr id="trspath">
                        <td class="gridTableColummHeader">Description:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2"><textarea ng-model="newAgendaItem.desc" rows="5" cols="69" class="form-control" /></textarea></td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr id="trspath">
                        <td class="gridTableColummHeader">Duration:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2"><input type="text" ng-model="newAgendaItem.duration" class="form-control" size="40" /></td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                            <input type="submit" class="btn btn-primary btn-raised" value="Create Agenda Item" ng-click="createRow()">
                            <input type="button" class="btn btn-primary btn-raised" value="Cancel" ng-click="showInput=false">
                        </td>
                    </tr>
                </table>
            </div>
        </div>
        <div style="height:30px;"></div>

        <table class="gridTable2" width="100%">
            <tr class="gridTableHeader">
                <td width="200px">Agenda Item</td>
                <td width="200px">Description</td>
                <td width="50px">Duration</td>
                <td width="50px">Action</td>
            </tr>
            <tr ng-repeat="rec in meeting.agenda">
                <td >
                    {{rec.position}}. <b><a href="agendaItem.htm?id={{meeting.id}}&aid={{rec.id}}">{{rec.subject}}</a></b>
                    </td>
                <td>{{rec.desc}}</td>
                <td>{{rec.duration}}</td>
                <td>
                   <img src="<%=ar.retPath%>assets/iconDelete.gif" ng-click="deleteRow(rec)"/>
                </td>
            </tr>
        </table>
    </div>
</div>
