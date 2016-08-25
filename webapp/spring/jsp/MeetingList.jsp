<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%

    ar.assertLoggedIn("Must be logged in to see a list of meetings");

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();

    JSONArray meetings = new JSONArray();
    List<MeetingRecord> allMeets = ngp.getMeetings();
    MeetingRecord.sortChrono(allMeets);
    for (MeetingRecord oneRef : allMeets) {
        if (!oneRef.isBacklogContainer()) {
            meetings.put(oneRef.getListableJSON(ar));
        }
    }

%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.meetings = <%meetings.write(out,2,4);%>;
    $scope.newMeeting = {name:"",duration:60,startTime:0,id:"",meetingType:1};


    $scope.newMeetingTime = new Date();
    $scope.newMeetingHour = 12;
    $scope.newMeetingMinutes = 30;

    $scope.datePickOptions = {
        formatYear: 'yyyy',
        startingDay: 1
    };
    $scope.datePickDisable = function(date, mode) {
        return false;
    };
    $scope.datePickOpen = false;
    $scope.openDatePicker = function($event) {
        $event.preventDefault();
        $event.stopPropagation();
        $scope.datePickOpen = true;
    };

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
        var postURL = "meetingDelete.json";
        var postdata = angular.toJson(row);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            var newSet = [];
            for( var i =0; i<$scope.meetings.length; i++) {
                var irow = $scope.meetings[i];
                if (delId != irow.id) {
                    newSet.push(irow);
                }
            }
            $scope.meetings = newSet;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.createRow = function() {
        var postURL = "meetingCreate.json";
        $scope.newMeetingTime.setHours($scope.newMeetingHour, $scope.newMeetingMinutes,0,0);
        $scope.newMeeting.startTime = $scope.newMeetingTime.getTime();
        var postdata = angular.toJson($scope.newMeeting);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {

            $scope.meetings.push(data);
            $scope.newMeeting = {name:"",duration:60,startTime:0,id:""};
            $scope.showInput=false;
            $scope.sortItems();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.sortItems = function() {
        $scope.meetings.sort( function(a, b){
            return b.startTime - a.startTime;
        } );
    };


    $scope.meetingStateName = function(val) {
        if (val<=1) {
            return "Planning";
        }
        if (val==2) {
            return "Running";
        }
        if (val>2) {
            return "Completed";
        }
        return "Unknown";
    }

    $scope.meetingStateStyle = function(val) {
        if (val<=1) {
            return "background-color:white";
        }
        if (val==2) {
            return "background-color:lightgreen";
        }
        if (val>2) {
            return "background-color:gray";
        }
        return "Unknown";
    }

});
</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Meeting List
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="newMeeting.meetingType=1;showInput=true">New Meeting</a></li>
              <li role="presentation" class="divider"></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="agendaBacklog.htm">Agenda Item Backlog</a></li>
            </ul>
          </span>

        </div>
    </div>


    <div id="NewMeeting" class="well" ng-show="showInput" ng-cloak>
        <div class="rightDivContent">
            <a href="#" ng-click="showInput=false"><img src="<%= ar.retPath%>assets/iconBlackDelete.gif"/></a>
        </div>
        <div class="generalSettings">
            <table>
                <tr id="trspath">
                    <td class="gridTableColummHeader">Type:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2" class="form-inline form-group">
                        <input type="radio" ng-model="newMeeting.meetingType" value="1"
                            class="form-control" /> Circle Meeting   &nbsp;
                        <input type="radio" ng-model="newMeeting.meetingType" value="2"
                            class="form-control" /> Operational Meeting
                    </td>
                </tr>
                <tr><td style="height:30px"></td></tr>
                <tr id="trspath">
                    <td class="gridTableColummHeader">Name:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2"><input type="text" ng-model="newMeeting.name" class="form-control"  size="69" /></td>
                </tr>
                <tr><td style="height:30px"></td></tr>
                <tr id="trspath">
                    <td class="gridTableColummHeader">Date:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2" class="form-inline form-group">

                        <input type="text"
                        style="width:150;"
                        class="form-control"
                        datepicker-popup="dd-MMMM-yyyy"
                        ng-model="newMeetingTime"
                        is-open="datePickOpen"
                        min-date="minDate"
                        datepicker-options="datePickOptions"
                        date-disabled="datePickDisable(date, mode)"
                        ng-required="true"
                        ng-click="openDatePicker($event)"
                        close-text="Close"/>
                        at
                        <select style="width:50;" ng-model="newMeetingHour" class="form-control" >
                            <option value="0">00</option>
                            <option value="1">01</option>
                            <option value="2">02</option>
                            <option value="3">03</option>
                            <option value="4">04</option>
                            <option value="5">05</option>
                            <option value="6">06</option>
                            <option value="7">07</option>
                            <option value="8">08</option>
                            <option value="9">09</option>
                            <option>10</option>
                            <option>11</option>
                            <option>12</option>
                            <option>13</option>
                            <option>14</option>
                            <option>15</option>
                            <option>16</option>
                            <option>17</option>
                            <option>18</option>
                            <option>19</option>
                            <option>20</option>
                            <option>21</option>
                            <option>22</option>
                            <option>23</option>
                        </select> :
                        <select  style="width:50;" ng-model="newMeetingMinutes" class="form-control" >
                            <option value="0">00</option>
                            <option>15</option>
                            <option>30</option>
                            <option>45</option>
                        </select>
                    </td>
                </tr>

                <tr><td style="height:30px"></td></tr>
                <tr id="trspath">
                    <td class="gridTableColummHeader">Duration:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2"><input type="text" ng-model="newMeeting.duration" class="form-control blue" size="40" /></td>
                </tr>
                <tr><td style="height:30px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader"></td>
                    <td style="width:20px;"></td>
                    <td colspan="2">
                        <input type="submit" class="btn btn-primary" value="Create Meeting" ng-click="createRow()">
                        <input type="button" class="btn btn-primary" value="Cancel" ng-click="showInput=false">
                    </td>
                </tr>
            </table>
        </div>
    </div>


    <table class="gridTable2" width="100%">
        <tr class="gridTableHeader">
            <td width="50px"></td>
            <td width="300px">Meeting</td>
            <td width="80px">State</td>
            <td width="80px">Duration</td>
        </tr>
        <tr ng-repeat="rec in meetings">
            <td>
              <div class="dropdown">
                <button class="dropdown-toggle specCaretBtn" type="button"  d="menu" 
                    data-toggle="dropdown"> <span class="caret"></span> </button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li role="presentation"><a role="menuitem" tabindex="-1"
                      href="meetingFull.htm?id={{rec.id}}">View Meeting</a></li>
                  <li role="presentation"><a role="menuitem" tabindex="-1"
                      href="meeting.htm?id={{rec.id}}">Edit Meeting</a></li>
                  <li role="presentation"><a role="menuitem" tabindex="-1"
                      href="cloneMeeting.htm?id={{rec.id}}">Clone Meeting</a></li>
                  <li role="presentation" class="divider"></li>
                  <li role="presentation"><a role="menuitem" tabindex="-1"
                      href="#" ng-click="deleteRow(rec)">Delete Meeting</a></li>
                </ul>
              </div>
            </td>
            <td><b><a href="meetingFull.htm?id={{rec.id}}">{{rec.name}}</a></b> @ {{rec.startTime|date: "HH:mma 'on' dd-MMM-yyyy"}}</td>
            <td style="{{meetingStateStyle(rec.state)}}">{{meetingStateName(rec.state)}}</td>
            <td>{{rec.duration}}</td>
        </tr>
    </table>

</div>
