<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="functions.jsp"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%

    String go = ar.getCompleteURL();
    ar.assertLoggedIn("Must be logged in to see anything about a user");

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();

    String meetId          = ar.reqParam("id");
    MeetingRecord oneRef   = ngp.findMeeting(meetId);
    JSONObject meetingInfo = oneRef.getFullJSON(ar, ngp);

%>
<style>
  .full button span {
    background-color: limegreen;
    border-radius: 32px;
    color: black;
  }
  .partially button span {
    background-color: orange;
    border-radius: 32px;
    color: black;
  }
</style>


<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.meeting = <%meetingInfo.write(out,2,4);%>;

    $scope.extractDateParts = function() {
        $scope.meetingTime = new Date($scope.meeting.startTime + (3600000 * 24 * 7));
        $scope.meetingHour = $scope.meetingTime.getHours();
        $scope.meetingMinutes = $scope.meetingTime.getMinutes();
        var last = $scope.meeting.agenda.length;
        var runTime = $scope.meetingTime;
        for (var i=0; i<last; i++) {
            var item = $scope.meeting.agenda[i];
            item.schedule = runTime;
            runTime = new Date( runTime.getTime() + (item.duration*60000) );
        }
        $scope.meeting.endTime = runTime;
    };
    $scope.extractDateParts();

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

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.sortItems = function() {
        $scope.meeting.agenda.sort( function(a, b){
            return a.position - b.position;
        } );
        return $scope.meeting.agenda;
    }

    $scope.createMeeting = function() {
        var postURL = "meetingCreate.json";
        $scope.meetingTime.setHours($scope.meetingHour, $scope.meetingMinutes,0,0);
        $scope.meeting.startTime = $scope.meetingTime.getTime();
        $scope.meeting.state = 1;
        var postdata = angular.toJson($scope.meeting);
        alert(postdata);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            window.location = "meetingList.htm";
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.trimDesc = function(item) {
        return GetFirstHundredNoHtml(item.desc);
        //return item.desc;
    }
});

function GetFirstHundredNoHtml(input) {
     var limit = 100;
     var inTag = false;
     var res = "";
     for (var i=0; i<input.length && limit>0; i++) {
         var ch = input.charAt(i);
         if (inTag) {
             if ('>' == ch) {
                 inTag=false;
             }
             //ignore all other characters while in the tag
         }
         else {
             if ('<' == ch) {
                 inTag=true;
             }
             else {
                 res = res + ch;
                 limit--;
             }
         }
     }
     return res;
 }

</script>


<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading">Clone Meeting
    </div>
    <br />


    <div id="NewMeeting">
        <div class="generalSettings">
            <table>
                <tr id="trspath">
                    <td class="gridTableColummHeader">Type:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2" class="form-inline form-group">
                        <input type="radio" ng-model="meeting.meetingType" value="1"
                            class="form-control" /> Circle Meeting   &nbsp
                        <input type="radio" ng-model="meeting.meetingType" value="2"
                            class="form-control" /> Operational Meeting
                    </td>
                </tr>
                <tr><td style="height:30px"></td></tr>
                <tr id="trspath">
                    <td class="gridTableColummHeader">Name:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2"><input type="text" ng-model="meeting.name" class="form-control"  size="69" /></td>
                </tr>
                <tr><td style="height:30px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader">Date:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2" class="form-inline form-group">

                        <input type="text"
                        style="width:150;"
                        class="form-control"
                        datepicker-popup="dd-MMMM-yyyy"
                        ng-model="meetingTime"
                        is-open="datePickOpen"
                        datepicker-options="datePickOptions"
                        date-disabled="datePickDisable(date, mode)"
                        ng-required="true"
                        ng-click="openDatePicker($event)"
                        close-text="Close"/>
                        at
                        <select style="width:50;" ng-model="meetingHour" class="form-control" >
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
                        <select  style="width:50;" ng-model="meetingMinutes" class="form-control" >
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
                    <td colspan="2"><input type="text" ng-model="meeting.duration" class="form-control blue" size="10" /></td>
                </tr>
                <tr><td style="height:30px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader"></td>
                    <td style="width:20px;"></td>
                    <td colspan="2">
                        <input type="submit" class="btn btn-primary" value="Create Meeting" ng-click="createMeeting()">
                    </td>
                </tr>
            </table>
        </div>
    </div>

    <table class="gridTable2" width="100%">
        <tr class="gridTableHeader">
            <td width="30px"> Copy</td>
            <td width="200px">Agenda Item</td>
            <td width="200px">Description</td>
            <td width="50px">Duration</td>
        </tr>
        <tr ng-repeat="rec in sortItems()">
            <td >
                <button ng-click="rec.selected=!rec.selected" class="btn btn-default"
                  title="Check the agenda items to carry to the new meeting,  an X means it is not being copied.">
                <span ng-hide="rec.selected"><img src="<%=ar.retPath%>assets/iconClose.gif"/></span>
                <span ng-show="rec.selected"><img src="<%=ar.retPath%>assets/iconBlueCheck.gif"/></span>
                </button>
            </td>
            <td><b><a href="agendaItem.htm?id={{meeting.id}}&aid={{rec.id}}">{{rec.subject}}</a></b>
                </td>
            <td style="line-height: 1.3;">{{trimDesc(rec)}}</td>
            <td>{{rec.duration}}</td>
        </tr>
    </table>


</div>
