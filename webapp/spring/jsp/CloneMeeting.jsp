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

    //make it for 7 days later
    meetingInfo.put("startTime",  meetingInfo.getLong("startTime") + 7L*24L*3600000 );

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

var app = angular.module('myApp', ['ui.bootstrap', 'ui.tinymce', 'ui.bootstrap.datetimepicker']);
app.controller('myCtrl', function($scope, $http) {
    $scope.meeting = <%meetingInfo.write(out,2,4);%>;

    var n = new Date().getTimezoneOffset();
    var tzNeg = n<0;
    if (tzNeg) {
        n = -n;
    }
    var tzHours = Math.floor(n/60);
    var tzMinutes = n - (tzHours*60);
    var tzFiddle = (100 + tzHours)*100 + tzMinutes;
    var txFmt = tzFiddle.toString().substring(1);
    if (tzNeg) {
        txFmt = "+".concat(txFmt);
    }
    else {
        txFmt = "-".concat(txFmt);
    }
    $scope.tzIndicator = txFmt;

    $scope.onTimeSet = function (newDate, secondparam) {
        $scope.meeting.startTime = newDate.getTime();
        console.log("NEW TIME:", newDate);
    }

    $scope.extractDateParts = function() {
        var last = $scope.meeting.agenda.length;
        var runTime = new Date($scope.meeting.startTime);
        $scope.meeting.agenda.forEach( function(item) {
            item.schedule = runTime;
            runTime = new Date( runTime.getTime() + (item.duration*60000) );
        });
        $scope.meeting.endTime = runTime;
    };
    $scope.extractDateParts();
    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 300;

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
                  Date &amp; Time
                </label>
                <div class="col-md-10">
                  <a class="dropdown-toggle form-control" id="dropdown2" role="button" data-toggle="dropdown" data-target="#" href="#">
                    {{ meeting.startTime | date:'dd-MMM-yyyy' }} &nbsp;at&nbsp; {{ meeting.startTime | date:'HH:mm' }} &nbsp; &nbsp; {{tzIndicator}}
                  </a>
                  <ul class="dropdown-menu" role="menu" aria-labelledby="dLabel">
                    <datetimepicker
                         data-ng-model="meeting.startTime"
                         data-datetimepicker-config="{ dropdownSelector: '#dropdown2',minuteStep: 15}"
                         data-on-set-time="onTimeSet(newDate)"/>
                  </ul>
                </div>
                <br/><!-- stupid extra line to get next DIV to start at the beginning of a line, why do i have to do this? -->
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
            <button type="button" class="btn btn-warning btn-raised" onclick="history.back();">Cancel</button>
            <button type="submit" class="btn btn-primary btn-raised"  ng-click="createMeeting()">Clone Meeting</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</div>
