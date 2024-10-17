<div class="card" id="cardstartTime">
  <div class="card-header">
    <span class="h5 card-title"> Settings 
    </span>
  </div>
  <div class="card-body">
    <div class="container-fluid">
      <div class="row my-3">
        <span class="col-3 h5">Name:</span>
        <span class="col-8" ng-hide="'name'==editMeetingPart">
          <b>{{meeting.name}}</b>
        </span>
      </div>
      <div class="row my-3">
        <div ng-hide="editMeetingDesc"></div>
        <span class="h5 col-3">Description:</span>
        <span class="col-8">
          <div ng-bind-html="meeting.descriptionHtml"></div>

        </span>

      </div>
      <div class="row my-3">
        <span class="col-3 h5">Total Duration:</span>
        <span class="col-8" ng-hide="'duration'==editMeetingPart">
          {{meeting.duration}} Minutes ({{meeting.totalDuration}} currently allocated, 
          ending at: {{meeting.startTime + (meeting.agendaDuration*60000) | date: 'HH:mm'}})
        </span>
      </div>
      <div class="row my-3">
        <span class="col-3 h5" style="cursor: text;">Called By:</span>
        <span class="col-8">
          {{meeting.owner}}
        </span>
      </div>
      <div class="row my-3">
        <span class="col-3 h5">Video Conference:</span>
        <span class="col-8" ng-hide="'conferenceUrl'==editMeetingPart">
          <a href="{{meeting.conferenceUrl}}" target="_blank">{{meeting.conferenceUrl}}</a>
        </span>
      </div>
      <div class="row my-3" >
        <span class="col-3 h5" style="cursor: text;">Previous Meeting: <span ng-show="previousMeeting.id"></span></span>
        <span class="col-8" >
          <a href="MeetingHtml.htm?id={{previousMeeting.id}}">
            {{previousMeeting.startTime|date: "dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm"}}</a> &nbsp; ({{browserZone}})</span>
      </div>
      <div class="row my-3" >
        <span class="col-3 h5" style="cursor: text;">
          Previous Minutes:
          <span ng-show="previousMeeting.minutesId"></span>
        </span>
        <span class="col-8">
            <span class="btn-comment"  style="margin:4px;" ng-click="navigateToTopic(previousMeeting.minutesLocalId)" title="Navigate to the discussion that holds the minutes for the previous meeting">
              Previous Minutes
            </span>
        </span>
      </div>
      <div class="row my-3" >
        <span class="h5 col-3">Reminder:
          <span ng-show="false"></span>
        </span>
        <span class="col-8" ng-hide="'reminderTime'==editMeetingPart">
          {{factoredTime}} {{timeFactor}} before the meeting. 
            <span ng-show="meeting.reminderSent<=0"> <i>Not sent.</i></span>
            <span ng-show="meeting.reminderSent>100"> Was sent {{meeting.reminderSent|date:'dd-MMM-yyyy H:mm'}}</span>
        </span>
        <span class="col-8" ng-show="'reminderTime'==editMeetingPart">

        </span>
      </div>
    </div>
  </div>
</div>




