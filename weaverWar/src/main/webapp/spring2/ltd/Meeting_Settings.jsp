      <div>
        <table class="table">
          <col width="130px">
          <col width="*">
          <tr>
            <td>Name:</td>
            <td >
              <b>{{meeting.name}}</b>
            </td>
          </tr>
          <tr>
            <td>Description:</td>
            <td >
              <div ng-bind-html="meeting.descriptionHtml"></div>
              <div ng-hide="meeting.descriptionHtml && meeting.descriptionHtml.length>3" class="doubleClickHint">
                  Double-click to edit description
              </div>
            </td>
          </tr>
          <tr>
            <td>Total Duration:</td>
            <td ng-dblclick="editMeetingPart='duration'">
              {{meeting.duration}} Minutes ({{meeting.totalDuration}} currently allocated, 
              ending at: {{meeting.startTime + (meeting.agendaDuration*60000) | date: 'HH:mm'}})
            </td>
          </tr>
          <tr>
            <td>Called By:</td>
            <td>
              {{meeting.owner}}
            </td>
          </tr>
          <tr ng-show="previousMeeting.id">
            <td>Previous Meeting:</td>
            <td>
              <a href="MeetingHtml.htm?id={{previousMeeting.id}}">
                {{previousMeeting.startTime|date: "dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm"}}</a> 
                <span>&nbsp; ({{browserZone}})</span>
            </td>
          </tr>
          <tr ng-show="previousMeeting.minutesId">
            <td>Previous Minutes:</td>
            <td>
                <span class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
                     ng-click="navigateToTopic(previousMeeting.minutesLocalId)"
                     title="Navigate to the discussion topic that holds the minutes for the previous meeting">
                     Previous Minutes
                </span>
            </td>
          </tr>
          <tr ng-show="false">
            <td >Reminder:</td>
            <td ng-hide="'reminderTime'==editMeetingPart" ng-dblclick="editMeetingPart='reminderTime'">
              {{factoredTime}} {{timeFactor}} before the meeting. 
                <span ng-show="meeting.reminderSent<=0"> <i>Not sent.</i></span>
                <span ng-show="meeting.reminderSent>100"> Was sent {{meeting.reminderSent|date:'dd-MMM-yyyy H:mm'}}</span>
            </td>
          </tr>
          <tr>
              <td></td>
              <td><button ng-click="expertMode = !expertMode" class="btn btn-default btn-raised">Expert Mode</button></td>
          </tr>
          <tr ng-show="expertMode">
            <td>Agenda Layout:</td>
            <td >
              {{meeting.notifyLayout}} 
            </td>
          </tr>
          <tr ng-show="expertMode">
            <td>Minutes Layout:</td>
            <td >
              {{meeting.defaultLayout}} 
            </td>
          </tr>
          <tr ng-show="expertMode">
            <td>Target Role:</td>
            <td>
              <a href="RoleManagement.htm">{{meeting.targetRole}}</a>
            </td>
          </tr>
        </table>
      </div>

