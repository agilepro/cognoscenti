<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="functions.jsp"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%

    String go = ar.getCompleteURL();
    ar.assertLoggedIn("Must be logged in to see anything about a user");

    String pageId      = ar.reqParam("pageId");
    NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngw);
    NGBook ngb = ngw.getSite();

    String meetId          = ar.reqParam("id");
    MeetingRecord oneRef   = ngw.findMeeting(meetId);
    JSONObject meetingInfo = oneRef.getFullJSON(ar, ngw);

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

var app = angular.module('myApp', ['ui.bootstrap', 'ui.tinymce']);
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
    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 300;

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
        var minutesFromNow = Math.floor(($scope.meeting.startTime - (new Date()).getTime()) / 60000);
        if (minutesFromNow<0) {
            if (!confirm("Warning: this meeting is being scheduled for time in the past.  An email message will be sent immediately informing people of the meeting before you get a chance to change the date.   If you mean to schedule a meeting for the future, press 'Cancel' and correct the date.   Do you still want to create a meeting for the past?")) {
                return;
            }
        }
        else if ($scope.meeting.reminderTime>0 && 
                minutesFromNow < $scope.meeting.reminderTime) {
            if (!confirm("Warning: this meeting is scheduled for "+minutesFromNow+" minutes from now.  An email reminder scheduled to be sent "+$scope.meeting.reminderTime+" minutes before the meeting will be sent immediately.   You should make sure that the information here is ready for that email to be sent.   Is everything ready to create the meeting and send the email?")) {
                return;
            }
        }
       $scope.meeting.state = 1;
        $scope.meeting.attended = [];
        $scope.meeting.rollCall = [];
        $scope.meeting.reminderSent = -1;
        $scope.meeting.id = "~new~";
        $scope.meeting.agenda.forEach( function(agendaitem) {
            agendaitem.readyToGo = false;
            agendaitem.comments = [];
        });
        var postdata = angular.toJson($scope.meeting);
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

<style>
.spaceyTable tr td {
    padding:8px;
}
</style>

<div ng-app="myApp" ng-controller="myCtrl">

  <%@include file="ErrorPanel.jsp"%>
  <div class="container">
    <div class="col-md-11">
      <div class="well">
        <form class="horizontal-form">
          <fieldset>
            <!-- Form Control NAME Begin -->
            <div class="form-group">
              <label class="col-md-2 control-label">Name</label>
              <div class="col-md-10">
                <input type="text" class="form-control" ng-model="meeting.name"/>
              </div>
            </div>
            <!-- Form Control DATE Begin -->
            <div class="form-group">
                <label class="col-md-2 control-label">
                  Date
                </label>
                <div class="col-md-10 container">
                  <div class="col-md-4">
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
                  </div>
                  <div class="col-md-1"><button type="button" class="form-control" disabled="1">at</button></div>
                  <div class="col-md-3">
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
                    </select>
                  </div>
                  <div class="col-md-1"><button type="button" class="form-control" disabled="1">:</button></div>
                  <div class="col-md-3">
                    <select  style="width:50;" ng-model="meetingMinutes" class="form-control" >
                        <option value="0">00</option>
                        <option>15</option>
                        <option>30</option>
                        <option>45</option>
                    </select>
                  </div>
                </div>
            </div>
            <!-- Form Control TYPE Begin -->
            <div class="form-group">
              <label class="col-md-2 control-label">Type</label>
              <div class="col-md-10">
                <div class="radio radio-primary">
                  <label>
                    <input type="radio" ng-model="meeting.meetingType" value="1"
                        class="form-control">
                        <span class="circle"></span>
                        <span class="check"></span>
                        Circle Meeting
                  </label>
                  <label>
                    <input type="radio" ng-model="meeting.meetingType" value="2"
                        class="form-control">
                        <span class="circle"></span>
                        <span class="check"></span>
                        Operational Meeting
                  </label>
                </div>
              </div>
            </div>
            <!-- Form Control DESCRIPTION Begin -->
            <div class="form-group">
                <label class="col-md-2 control-label">
                  Description
                </label>
                <div class="col-md-10">
                  <textarea ui-tinymce="tinymceOptions" ng-model="meeting.meetingInfo"
                       class="leafContent form-control" style="min-height:200px;"></textarea>
                </div>
            </div>
          </fieldset>
          <!-- Table MEETING AGENDA ITEMS Begin -->
          <h3>Cloning Agenda Items</h3>
          <div class="form-group">
          <table class="table table-striped table-hover" width="100%">
              <tr>
                  <th width="30px">Clone</th>
                  <th width="200px">Agenda Item</th>
                  <th width="200px">Description</th>
                  <th width="50px">Duration</th>
              </tr>
              <tr ng-repeat="rec in sortItems()">
                  <td class="actions">
                    <div class="checkbox">
                      <label>
                        <input type="checkbox" ng-model="rec.selected"><span class="checkbox-material"></span>
                      </label>
                    </div>
                  </td>
                  <td><b><a href="agendaItem.htm?id={{meeting.id}}&aid={{rec.id}}">{{rec.subject}}</a>
                          <span ng-show="rec.topicLink">(Linked Topic)
                          </span>
                      </b>
                      </td>
                  <td style="line-height: 1.3;">{{trimDesc(rec)}}</td>
                  <td>{{rec.duration}}</td>
              </tr>
          </table>
        </div>
          <!-- Form Control BUTTONS Begin -->
          <div class="form-group text-right">
            <button type="button" class="btn btn-default btn-raised" onclick="history.back();">Cancel</button>
            <button type="submit" class="btn btn-primary btn-raised"  ng-click="createMeeting()">Clone Meeting</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</div>
