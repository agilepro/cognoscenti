
<div class="card" id="cardstartTime">
  <div class="card-header">
    <span class="h5 card-title"> Settings 
    </span>
  </div>
  <div class="card-body">
        <div class="container-fluid">
          <div class="row d-flex">
            <span ng-click="editMeetingPart='name'" class="col-2 labelColumn">Name:</span>
            <span class="col-8" ng-hide="'name'==editMeetingPart" ng-click="editMeetingPart='name'">
              <b>{{meeting.name}}</b>
            </span>
            <span class="col-8" ng-show="'name'==editMeetingPart">
                <div class="well form-horizontal form-group">
                    <input ng-model="meeting.name"  class="form-control">
                    <button class="btn btn-primary btn-raised" ng-click="savePendingEdits()">Save</button>
                </div>
            </span>
          </div>
          <div class="row">
            <div ng-hide="editMeetingDesc"></div>
            <span ng-click="editMeetingDesc=true" class="labelColumn col-2">Description:</span>
            <span ng-click="editMeetingDesc=true" class="col-8">
              <div ng-bind-html="meeting.descriptionHtml"></div><span class="mt-0"><i class="pull-right">(include purpose, goals, location, conference link)</i></span>
              <div ng-hide="meeting.descriptionHtml && meeting.descriptionHtml.length>3" class="doubleClickHint">
                  Double-click to edit description
              </div>
            </span>
            <div ng-show="editMeetingDesc" style="width:100%">
              <div class="well leafContent">
                  <div ui-tinymce="tinymceOptions" ng-model="meeting.descriptionHtml"
                       class="leafContent" style="min-height:200px;" ></div>
                       <div class="d-flex">
                  <button ng-click="revertAllEdits()" class="btn btn-danger btn-raised">Cancel</button>
                  <button ng-click="savePendingEdits()" class="btn btn-primary btn-raised ms-auto">Save</button></div>
                  
              </div>
          </div>
          </div>
          <div class="row">
            <span ng-click="editMeetingPart='duration'" class="col-2 labelColumn">Total Duration:</span>
            <span class="col-8 mt-2" ng-hide="'duration'==editMeetingPart" ng-dblclick="editMeetingPart='duration'">
              {{meeting.duration}} Minutes ({{meeting.totalDuration}} currently allocated, 
              ending at: {{meeting.startTime + (meeting.agendaDuration*60000) | date: 'HH:mm'}})
            </span>
            <span class="col-8 mt-2" ng-show="'duration'==editMeetingPart" >
                <div class="well form-inline form-group" style="max-width:400px">
                    <input ng-model="meeting.duration" style="width:60px;"  class="form-control" >
                    Minutes ({{meeting.totalDuration}} currently allocated)<br/>
                    <button class="btn btn-primary btn-raised" ng-click="savePendingEdits()">Save</button>
                </div>
            </span>
          </div>
          <div class="row">
            <span class="col-2 labelColumn" style="cursor: text;">Called By:</span>
            <span class="col-8 mt-2">
              {{meeting.owner}}
            </span>
          </div>
          <div class="row d-flex">
            <span ng-click="editMeetingPart='conferenceUrl'" class="col-2 labelColumn">Video Conference:</span>
            <span class="col-8" ng-hide="'conferenceUrl'==editMeetingPart">
              <a href="{{meeting.conferenceUrl}}" target="_blank">{{meeting.conferenceUrl}}</a>
            </span>
            <span class="col-8" ng-show="'conferenceUrl'==editMeetingPart">
                <div class="well form-horizontal form-group">
                    <input ng-model="meeting.conferenceUrl"  class="form-control">
                    <button class="btn btn-primary btn-raised" ng-click="savePendingEdits()">Save</button>
                </div>
            </span>
          </div>
          <div class="row" >
            <span class="col-2 labelColumn" style="cursor: text;">Previous Meeting: <span ng-show="previousMeeting.id"></span></span>
            <span class="col-8 mt-2" >
              <a href="MeetingHtml.htm?id={{previousMeeting.id}}">
                {{previousMeeting.startTime|date: "dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm"}}</a> &nbsp; ({{browserZone}})</span>
            
            
          </div>
          <div class="row" >
            <span class="col-2 labelColumn" style="cursor: text;">Previous Minutes:<span ng-show="previousMeeting.minutesId"></span></span>
            <span class="col-8" >
                <span class="btn btn-sm btn-comment btn-outline-secondary"  style="margin:4px;"
                     ng-click="navigateToTopic(previousMeeting.minutesLocalId)"
                     title="Navigate to the discussion that holds the minutes for the previous meeting">
                     Previous Minutes
                </span>
            </span>
          </div>
          <div class="row" >
            <span ng-click="editMeetingPart='reminderTime'" class="labelColumn col-2">Reminder:<span ng-show="false"></span></span>
            <span class="col-8 mt-2" ng-hide="'reminderTime'==editMeetingPart" ng-dblclick="editMeetingPart='reminderTime'">
              {{factoredTime}} {{timeFactor}} before the meeting. 
                <span ng-show="meeting.reminderSent<=0"> <i>Not sent.</i></span>
                <span ng-show="meeting.reminderSent>100"> Was sent {{meeting.reminderSent|date:'dd-MMM-yyyy H:mm'}}</span>
            </span>
            <span class="col-8 mt-2" ng-show="'reminderTime'==editMeetingPart">
                <div class="well form-inline form-group" style="max-width:600px">
                    <input ng-model="factoredTime" style="width:60px;"  class="form-control my-2" >
                    <select ng-model="timeFactor" class="form-control my-2" ng-change="">
                        <option>Minutes</option>
                        <option>Days</option>
                        </select>
                    before the meeting, ({{meeting.reminderTime}} minutes)<br/>
                    <button class="btn btn-primary btn-sm btn-raised" ng-click="savePendingEdits()">Save</button>
                </div>
            </span>
          </div>
          <div class="row" >
              <span class="col-2 ms-5 my-3"><button ng-click="expertMode = !expertMode" class="btn btn-secondary btn-sm  btn-raised">Expert Mode</button></span>
              
          </div>
          <div class="row" ng-show="expertMode">
            <span ng-click="editMeetingPart='notifyLayout'" class="labelColumn col-2">Agenda Layout:</span>
            <span class="col-8" ng-hide="'notifyLayout'==editMeetingPart" ng-dblclick="editMeetingPart='notifyLayout'">
              {{meeting.notifyLayout}} 
            </span>
            <span class="col-8" ng-show="'notifyLayout'==editMeetingPart">
              <div class="well form-inline form-group" style="max-width:400px">
                <select class="form-control"  ng-model="meeting.notifyLayout" ng-options="n for n in allLayoutNames"></select>
                <button class="btn btn-primary btn-raised" ng-click="savePendingEdits()">Save</button>
              </div>
            </span>
          </div>
          <div class="row" ng-show="expertMode">
            <span ng-click="editMeetingPart='defaultLayout'" class="col-2 labelColumn">Minutes Layout:</span>
            <span class="col-8" ng-hide="'defaultLayout'==editMeetingPart" ng-dblclick="editMeetingPart='defaultLayout'">
              {{meeting.defaultLayout}} 
            </span>
            <span class="col-8" ng-show="'defaultLayout'==editMeetingPart">
              <div class="well form-inline form-group" style="max-width:400px">
                <select class="form-control"  ng-model="meeting.defaultLayout" ng-options="n for n in allLayoutNames"></select>
                <button class="btn btn-primary btn-raised" ng-click="savePendingEdits()">Save</button>
              </div>
            </span>
          </div>
          <div class="row" ng-show="expertMode">
            <span ng-click="editMeetingPart='targetRole'" class="col-2 labelColumn">Target Role:</span>
            <span class="col-8" ng-hide="'targetRole'==editMeetingPart" ng-dblclick="editMeetingPart='targetRole'">
              <a href="RoleManagement.htm" target="_blank">{{meeting.targetRole}}</a>
              <span ng-hide="roleEqualsParticipants || meeting.state<=0" style="color:red">
                  . . . includes people who are not meeting participants!
              </span>
            </span>
            <span class="col-8" ng-show="'targetRole'==editMeetingPart">
                <div class="well form-inline form-group" style="max-width:400px">
                    <select class="form-control" ng-model="meeting.targetRole" 
                            ng-options="value for value in allRoles" ng-change="checkRole()"></select>
                    <button class="btn btn-primary btn-raised" ng-click="savePendingEdits()">Save</button>
                </div>
            </span>
          </div>
        </div>
  </div>


</div>
