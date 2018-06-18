<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="functions.jsp"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%@page import="java.util.Calendar"
%><%

    String go = ar.getCompleteURL();
    ar.assertLoggedIn("Must be logged in to see anything about a user");

    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKey(siteId,pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    NGBook site = ngw.getSite();

    JSONObject meetingInfo = null;
    String meetId          = ar.defParam("id", null);
    String pageTitle = "Clone Meeting";
    long proposedStartTime = 0;
    if (meetId == null) {
        pageTitle = "Create Meeting";
        meetingInfo = new JSONObject();
        //make it for top of next hour
        Calendar cal = Calendar.getInstance();
        cal.set(Calendar.MINUTE, 0);
        cal.set(Calendar.SECOND, 0);
        cal.set(Calendar.MILLISECOND, 0);
        cal.roll(Calendar.HOUR_OF_DAY, 1);
        proposedStartTime = cal.getTime().getTime();
        meetingInfo.put("agenda", new JSONArray());
    }
    else {
        MeetingRecord oneRef   = ngw.findMeeting(meetId);
        meetingInfo = oneRef.getFullJSON(ar, ngw);
        //make it for 7 days later
        proposedStartTime =  meetingInfo.getLong("startTime") + 7L*24L*3600000;
    }
    //meetingInfo.put("id","~new~");

    meetingInfo.put("startTime", proposedStartTime);

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

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("<%=pageTitle%>");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.meeting = <%meetingInfo.write(out,2,4);%>;
    $scope.browserZone = Intl.DateTimeFormat().resolvedOptions().timeZone;

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
        if (!$scope.meeting.name) {
            alert("Please enter a name for the meeting");
            return;
        }
        if (!$scope.meeting.meetingInfo) {
            alert("Please a short description for the meeting");
            return;
        }
        
        var postURL = "meetingCreate.json";
        var minutesFromNow = Math.floor(($scope.meeting.startTime - (new Date()).getTime()) / 60000);
        if ($scope.meeting.startTime>1000000 && minutesFromNow<0) {
            console.log("STARTTIME is: ", $scope.meeting.startTime);
            if (!confirm("Warning: this meeting is being scheduled for time in the past.  An email message will be sent immediately informing people of the meeting before you get a chance to change the date.   If you mean to schedule a meeting for the future, press 'Cancel' and correct the date.   Do you still want to create a meeting for the past?")) {
                return;
            }
        }
        else if ($scope.meeting.startTime>1000000 && $scope.meeting.reminderTime>0 &&
                minutesFromNow < $scope.meeting.reminderTime) {
            if (!confirm("Warning: this meeting is scheduled for "+minutesFromNow+" minutes from now.  An email reminder scheduled to be sent "+$scope.meeting.reminderTime+" minutes before the meeting will be sent immediately.   You should make sure that the information here is ready for that email to be sent.   Is everything ready to create the meeting and send the email?")) {
                return;
            }
        }
        var newMeeting = {};
        newMeeting.state = 0;
        newMeeting.attended = [];
        newMeeting.rollCall = [];
        newMeeting.reminderSent = -1;
        newMeeting.id = "~new~";
        newMeeting.duration = $scope.meeting.duration;
        newMeeting.previousMeeting = $scope.meeting.id;
        newMeeting.meetingInfo = $scope.meeting.meetingInfo;
        newMeeting.name = $scope.meeting.name;
        newMeeting.reminderTime = $scope.meeting.reminderTime;
        newMeeting.startTime = $scope.meeting.startTime;
        newMeeting.targetRole = $scope.meeting.targetRole;
        newMeeting.agenda = [];
        $scope.meeting.agenda.forEach( function(agendaItem) {
            if (agendaItem.selected) {
                var newAgenda = JSON.parse(JSON.stringify(agendaItem));
                newAgenda.readyToGo = false;
                newAgenda.comments = [];
                newMeeting.agenda.push(newAgenda);
            }
        });
        var postdata = angular.toJson(newMeeting);
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
app.filter('sdate', function() {
    return function(input, fmtString) {
        if (!fmtString) {
            fmtString = "dd-MMM-yyyy"
        }
        if (input<=0) {
            return "(to be determined)";
        }
        return moment(input).format(fmtString);
    };
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
              <label class="col-md-2 control-label" title="Choose a name for the meeting that will be suitable for the entire series of meetings.">Name</label>
              <div class="col-md-10">
                <input type="text" class="form-control" ng-model="meeting.name"
                       title="Choose a name for the meeting that will be suitable for the entire series of meetings."/>
              </div>
            </div>
            <!-- Form Control DATE Begin -->
            <div class="form-group form-inline">
                <label class="col-md-2 control-label" title="Date and time for the beginning of the meeting in YOUR time zone">
                  Date &amp; Time
                </label>
                <div class="col-md-10" 
                         title="Date and time for the beginning of the meeting in YOUR time zone">
                  <span datetime-picker ng-model="meeting.startTime" 
                        class="form-control" style="width:180px">
                      {{meeting.startTime|sdate:"DD-MMM-YYYY &nbsp; HH:mm"}}
                  </span> 
                  <span style="padding:10px">{{browserZone}}</span>
                  <button ng-click="meeting.startTime=0" class="btn btn-default btn-raised">Clear</button>
                </div>
                <br/><!-- stupid extra line to get next DIV to start at the beginning of a line, why do i have to do this? -->
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
          <div ng-show="meeting.agenda.length>0">
              <!-- Table MEETING AGENDA ITEMS Begin -->
              <h3>Cloning Agenda Items</h3>
              <div class="form-group">
              <table class="table table-striped table-hover" width="100%">
                  <tr>
                      <th width="30px" title="Check this to include a copy of this agenda item in the new meeting">Clone</th>
                      <th width="200px">Agenda Item</th>
                      <th width="200px">Description</th>
                      <th width="50px" title="Expected duration of the agenda item in minutes">Duration</th>
                  </tr>
                  <tr ng-repeat="rec in sortItems()">
                      <td class="actions">
                        <div class="checkbox">
                          <label title="Check this to include a copy of this agenda item in the new meeting">
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
                      <td title="Expected duration of the agenda item in minutes">
                          <input class="form-control" style="width:80px" ng-model="rec.duration"></td>
                  </tr>
              </table>
          </div>
        </div>
          <!-- Form Control BUTTONS Begin -->
          <div class="form-group text-right">
            <button type="button" class="btn btn-warning btn-raised" onclick="history.back();">Cancel</button>
            <button type="submit" class="btn btn-primary btn-raised"  ng-click="createMeeting()"><%=pageTitle%></button>
          </div>
        </form>
      </div>
    </div>
  </div>
</div>
