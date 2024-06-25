

        
        <div class="container">
          <div class="accordion" id="accordionSettings">
            <div class="accordion-item">
              <h2 class="accordion-header" onclick="toggleAccordion(event)"id="mtgSettings">
                <button class="accordion-button" type="button" data-bs-toggle="collapse" data-bs-target="#collapseMtgSettings" aria-expanded="true" aria-controls="collapseMtgSettings"> Settings 
                </button>
              </h2>
              <div id="collapseMtgSettings" class="accordion-collapse collapse show" aria-labelledby="mtgSettings" data-bs-parent="#accordionSettings">
                <div class="accordion-body">

        <table class="table">
          <tr>
            <td ng-click="editMeetingPart='name'" class="labelColumn">Name:</td>
            <td ng-hide="'name'==editMeetingPart" ng-dblclick="editMeetingPart='name'">
              <b>{{meeting.name}}</b>
            </td>
            <td ng-show="'name'==editMeetingPart">
                <div class="well form-horizontal form-group" style="max-width:400px">
                    <input ng-model="meeting.name"  class="form-control">
                    <button class="btn btn-primary btn-raised" ng-click="savePendingEdits()">Save</button>
                </div>
            </td>
          </tr>
          <tr>
            <td ng-click="editMeetingDesc=true" class="labelColumn">Description:<br/>(incl. purpose, goals, location, conference link)</td>
            <td ng-dblclick="editMeetingDesc=true">
              <div ng-bind-html="meeting.descriptionHtml"></div>
              <div ng-hide="meeting.descriptionHtml && meeting.descriptionHtml.length>3" class="doubleClickHint">
                  Double-click to edit description
              </div>
            </td>
          </tr>
          <tr>
            <td ng-click="editMeetingPart='duration'" class="labelColumn">Total Duration:</td>
            <td ng-hide="'duration'==editMeetingPart" ng-dblclick="editMeetingPart='duration'">
              {{meeting.duration}} Minutes ({{meeting.totalDuration}} currently allocated, 
              ending at: {{meeting.startTime + (meeting.agendaDuration*60000) | date: 'HH:mm'}})
            </td>
            <td ng-show="'duration'==editMeetingPart" >
                <div class="well form-inline form-group" style="max-width:400px">
                    <input ng-model="meeting.duration" style="width:60px;"  class="form-control" >
                    Minutes ({{meeting.totalDuration}} currently allocated)<br/>
                    <button class="btn btn-primary btn-raised" ng-click="savePendingEdits()">Save</button>
                </div>
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
            <td ng-click="editMeetingPart='reminderTime'" class="labelColumn">Reminder:</td>
            <td ng-hide="'reminderTime'==editMeetingPart" ng-dblclick="editMeetingPart='reminderTime'">
              {{factoredTime}} {{timeFactor}} before the meeting. 
                <span ng-show="meeting.reminderSent<=0"> <i>Not sent.</i></span>
                <span ng-show="meeting.reminderSent>100"> Was sent {{meeting.reminderSent|date:'dd-MMM-yyyy H:mm'}}</span>
            </td>
            <td ng-show="'reminderTime'==editMeetingPart">
                <div class="well form-inline form-group" style="max-width:600px">
                    <input ng-model="factoredTime" style="width:60px;"  class="form-control" >
                    <select ng-model="timeFactor" class="form-control" ng-change="">
                        <option>Minutes</option>
                        <option>Days</option>
                        </select>
                    before the meeting, ({{meeting.reminderTime}} minutes)<br/>
                    <button class="btn btn-primary btn-raised" ng-click="savePendingEdits()">Save</button>
                </div>
            </td>
          </tr>
          <tr>
              <td></td>
              <td><button ng-click="expertMode = !expertMode" class="btn btn-default btn-raised">Expert Mode</button></td>
          </tr>
          <tr ng-show="expertMode">
            <td ng-click="editMeetingPart='notifyLayout'" class="labelColumn">Agenda Layout:</td>
            <td ng-hide="'notifyLayout'==editMeetingPart" ng-dblclick="editMeetingPart='notifyLayout'">
              {{meeting.notifyLayout}} 
            </td>
            <td ng-show="'notifyLayout'==editMeetingPart">
              <div class="well form-inline form-group" style="max-width:400px">
                <select class="form-control"  ng-model="meeting.notifyLayout" ng-options="n for n in allLayoutNames"></select>
                <button class="btn btn-primary btn-raised" ng-click="savePendingEdits()">Save</button>
              </div>
            </td>
          </tr>
          <tr ng-show="expertMode">
            <td ng-click="editMeetingPart='defaultLayout'" class="labelColumn">Minutes Layout:</td>
            <td ng-hide="'defaultLayout'==editMeetingPart" ng-dblclick="editMeetingPart='defaultLayout'">
              {{meeting.defaultLayout}} 
            </td>
            <td ng-show="'defaultLayout'==editMeetingPart">
              <div class="well form-inline form-group" style="max-width:400px">
                <select class="form-control"  ng-model="meeting.defaultLayout" ng-options="n for n in allLayoutNames"></select>
                <button class="btn btn-primary btn-raised" ng-click="savePendingEdits()">Save</button>
              </div>
            </td>
          </tr>
          <tr ng-show="expertMode">
            <td ng-click="editMeetingPart='targetRole'" class="labelColumn">Target Role:</td>
            <td ng-hide="'targetRole'==editMeetingPart" ng-dblclick="editMeetingPart='targetRole'">
              <a href="RoleManagement.htm">{{meeting.targetRole}}</a>
              <span ng-hide="roleEqualsParticipants || meeting.state<=0" style="color:red">
                  . . . includes people who are not meeting participants!
              </span>
            </td>
            <td ng-show="'targetRole'==editMeetingPart">
                <div class="well form-inline form-group" style="max-width:400px">
                    <select class="form-control" ng-model="meeting.targetRole" 
                            ng-options="value for value in allRoles" ng-change="checkRole()"></select>
                    <button class="btn btn-primary btn-raised" ng-click="savePendingEdits()">Save</button>
                </div>
            </td>
          </tr>
        </table>
      </div>

    <div ng-show="editMeetingDesc" style="width:100%">
        <div class="well leafContent">
            <div ui-tinymce="tinymceOptions" ng-model="meeting.descriptionHtml"
                 class="leafContent" style="min-height:200px;" ></div>
            <button ng-click="savePendingEdits()" class="btn btn-primary btn-raised">Save</button>
            <button ng-click="revertAllEdits()" class="btn btn-warning btn-raised">Cancel</button>
        </div>
    </div>
</div>
</div>
</div>
