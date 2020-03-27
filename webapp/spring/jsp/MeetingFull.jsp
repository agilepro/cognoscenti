<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%@page import="org.socialbiz.cog.LicenseForUser"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.assertLoggedIn("Meeting page designed for people logged in");
    ar.setPageAccessLevels(ngw);
    
    String meetId          = ar.reqParam("id");
    MeetingRecord mRec     = ngw.findMeeting(meetId);

    UserProfile uProf = ar.getUserProfile();
    String userTimeZone = uProf.getTimeZone();
    
    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }


    if (!AccessControl.canAccessMeeting(ar, ngw, mRec)) {
        throw new Exception("Please log in to see this meeting.");
    }

    if (ar.ngp==null) {
        throw new Exception("NGP should not be null!!!!!!");
    }
    
    NGBook site = ngw.getSite();
    boolean isLoggedIn = (uProf!=null);
    String currentUser = "";
    String currentUserName = "Unknown";
    String currentUserKey = "";
    if (isLoggedIn) {
        currentUser = uProf.getUniversalId();
        currentUserName = uProf.getName();
        currentUserKey = uProf.getKey();
    }

    String targetRole = mRec.getTargetRole();
    if (targetRole==null || targetRole.length()==0) {
        mRec.setTargetRole(ngw.getPrimaryRole().getName());
    }
    JSONObject meetingInfo = mRec.getFullJSON(ar, ngw);
    
    JSONObject previousMeeting = new JSONObject();
    if (meetingInfo.has("previousMeeting")) {
        String previousId = meetingInfo.getString("previousMeeting");
        if (previousId.length()>0) {
            MeetingRecord previous = ngw.findMeetingOrNull(previousId);
            if (previous!=null) {
                previousMeeting = new JSONObject();
                JSONObject temp = previous.getFullJSON(ar, ngw);
                previousMeeting.put("startTime", temp.getLong("startTime"));
                previousMeeting.put("id", temp.getString("id"));
                previousMeeting.put("minutesId", temp.getString("minutesId"));
                if (temp.has("minutesLocalId")) {
                    previousMeeting.put("minutesLocalId", temp.getString("minutesLocalId"));
                }
            }
        }
    }
    
    JSONArray attachmentList = new JSONArray();
    for (AttachmentRecord doc : ngw.getAllAttachments()) {
        if (doc.isDeleted()) {
            continue;
        }
        attachmentList.put(doc.getJSON4Doc(ar, ngw));
    }

    JSONArray allGoals     = ngw.getJSONGoals();

    JSONArray allRoles = new JSONArray();
    for (NGRole aRole : ngw.getAllRoles()) {
        allRoles.put(aRole.getName());
    }

    JSONArray allTopics = new JSONArray();
    for (TopicRecord aNote : ngw.getAllDiscussionTopics()) {
        allTopics.put(aNote.getJSON(ngw));
    }

    JSONArray allLabels = ngw.getJSONLabels();

    String docSpaceURL = "";

    if (uProf!=null) {
        LicenseForUser lfu = new LicenseForUser(ar.getUserProfile());
        docSpaceURL = ar.baseURL +  "api/" + site.getKey() + "/" + ngw.getKey()
                    + "/summary.json?lic="+lfu.getId();
    }
    

    MeetingRecord backlog = ngw.getAgendaItemBacklog();
    
    List<File> allLayouts = MeetingRecord.getAllLayouts(ar, ngw);
    JSONArray allLayoutNames = new JSONArray();
    for (File aFile : allLayouts) {
        allLayoutNames.put(aFile.getName());
    }

/* PROTOTYPE

    $scope.meeting = {
      "agenda": [
        {
          "actionItems": [
            "BKLQHEHWG@clone-c-of-clone-4@8005",
            "HFCKCQHWG@clone-c-of-clone-4@0353"
          ],
          "desc": "An autocracy vests power in one autocratic.",
          "docList": [
            "VKSSSCSRG@sec-inline-xbrl@4841",
            "HGYDQWIWG@clone-c-of-clone-4@9358"
          ],
          "duration": 14,
          "id": "1695",
          "notes": "Randy says he is interested organization.",
          "position": 1,
          "subject": "Approve Advertising Plan"
        },
        {
          "actionItems": [],
          "desc": "Many new organizational support.",
          "docList": [],
          "duration": 5,
          "id": "2695",
          "notes": "",
          "position": 2,
          "subject": "Location of New Offices"
        }
      ],
      "duration": 60,
      "id": "0695",
      "meetingInfo": "Please join us in Austin, Texas 78701",
      "name": "Status Meeting",
      "startTime": 1434137400000,
      "state": 1
    };



    $scope.attachmentList = [
      {
        "attType": "FILE",
        "deleted": false,
        "description": "Original Contract from the SEC to Fujitsu",
        "id": "1002",
        "labelMap": {},
        "modifiedtime": 1391185776500,
        "modifieduser": "cparker@us.fujitsu.com",
        "name": "Contract 13-C-0113-Fujitsu.pdf",
        "public": false,
        "size": 409333,
        "universalid": "CSWSLRBRG@sec-inline-xbrl@0056",
        "upstream": true
      },

*/


%>

<style>
.meeting-icon {
   cursor:pointer;
   color:LightSteelBlue;
}

</style>

<script src="../../../jscript/AllPeople.js"></script>

<script>
var embeddedData = {};
embeddedData.pageId    = "<%ar.writeJS(pageId);%>";
embeddedData.meetId    = "<%ar.writeJS(meetId);%>";
embeddedData.userId    = "<%ar.writeJS(ar.getBestUserId());%>";
embeddedData.userZone  = "<%ar.writeJS(userTimeZone);%>";
embeddedData.previousMeeting = <%previousMeeting.write(out,2,2);%>;
embeddedData.allGoals  = <%allGoals.write(out,2,2);%>;
embeddedData.allRoles  = <%allRoles.write(out,2,2);%>;
embeddedData.allLabels = <%allLabels.write(out,2,2);%>;
embeddedData.backlogId = "<%=backlog.getId()%>";
embeddedData.retPath   = "<%=ar.retPath%>";
embeddedData.templateCacheDefeater   = "<%=templateCacheDefeater%>";
embeddedData.docSpaceURL = "<%ar.writeJS(docSpaceURL);%>"
embeddedData.siteInfo = <%site.getConfigJSON().write(out,2,2);%>;
embeddedData.allLayoutNames = <%allLayoutNames.write(out,2,4);%>;

</script>
<script src="../../../spring/jsp/MeetingFull.js"></script>


<style>
[ng\:cloak], [ng-cloak], [data-ng-cloak], [x-ng-cloak], .ng-cloak, .x-ng-cloak {
  display: none !important;
}

.blankTitle {
    font-size: 130%;
    font-weight: bold;
}
.agendaTitle {
    font-size: 130%;
    font-weight: bold;
    border-style:dotted;
    border-color:white;
}
.agendaTitle:hover {
    font-size: 130%;
    font-weight: bold;
    border-style:dotted;
    border-color:lightblue;
    cursor:pointer;
}
.spaceyTable tr td {
    padding:5px;
}
.spacydiv {
    padding:5px;
}
.votingButton {
    padding:2px;
    margin:0px;
    font-size: 130%;
}
</style>

<div ng-app="myApp" ng-controller="myCtrl" ng-cloak>

<%@include file="ErrorPanel.jsp"%>


<%if (isLoggedIn) { %>
    <div class="upRightOptions rightDivContent">
      <span class="dropdown" ng-show="meeting.state<=0">
          <button class="btn btn-default btn-primary btn-raised"
                  ng-click="startSend()"
                  title="Post this meeting to allow others to start planning for it">
          Post Meeting </button>
      </span>
      <span class="dropdown" title="Control the way people see this meeting." 
            ng-hide="meeting.state<=0">
          <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown" style="{{meetingStateStyle(meeting.state)}}">
          State: {{stateName()}} <span class="caret"></span></button>
          <ul class="dropdown-menu" role="menu" aria-labelledby="menu1" style="cursor:pointer">
            <li role="presentation"><a role="menuitem" 
                title="Use DRAFT to set the meeting without any notifications going out"
                ng-click="changeMeetingState(0)">Draft Meeting</a></li>
            <li role="presentation"><a role="menuitem"
                title="Use PLAN to allow everyone to get prepared for the meeting"
                ng-click="changeMeetingState(1)">Plan Meeting</a></li>
            <li role="presentation"><a role="menuitem"
                title="Use RUN while the meeting is actually in session"
                ng-click="changeMeetingState(2)">Run Meeting</a></li>
            <li role="presentation"><a role="menuitem"
                title="Use COMPLETE after the meeting is over and to generate minutes"
                ng-click="changeMeetingState(3)">Complete Meeting</a></li>
          </ul>
      </span>
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              title="Opens or closes all of the agenda items for the meeting"
              href="#" ng-click="showAll()" >Show All Items</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              title="Show who has responded about whether they will attend or not"
              href="#" ng-click="toggleRollCall()" >Show Roll Call</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              title="Show who has responded about whether they will attend or not"
              href="#" ng-click="showTimeSlots=true" >Show Proposed Times</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              title="Show who has responded about whether they will attend or not"
              href="#" ng-click="showFutureSlots=true" >Show Next Meeting Times</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              title="Create a new agenda item at the bottom of the meeting"
              href="#" ng-click="createAgendaItem()" >Propose Agenda Item</a></li>
          <li role="presentation"><a role="menuitem"
              title="Compose an email messsage about this meeting and send it"
              href="SendNote.htm?meet={{meeting.id}}&layout={{meeting.defaultLayout}}">Send Email about Meeting</a></li>
          <li role="presentation"><a role="menuitem"
              title="Open the editor for the minutes of the meeting"
              ng-click="openEditor()">Edit Meeting Notes</a></li>
          <li role="presentation"><a role="menuitem"
              title="Display the meeting as a HTML page that can be copied into an editor"
              href="meetingHtml.htm?id={{meeting.id}}">Show NEW Meeting Display</a></li>
          <li role="presentation"><a role="menuitem"
              title="Display the meeting as a HTML page that can be copied into an editor"
              href="MeetMerge.htm?id={{meeting.id}}&tem=FullDetail.chtml">Show Meeting Layouts</a></li>
          <li role="presentation" class="divider"></li>
          <li role="presentation"><a role="menuitem"
              title="Generate the meeting minutes from the agenda items and put in a discussion topic"
              ng-click="createMinutes()">Generate Minutes</a></li>
          <li role="presentation" ng-show="meeting.minutesId"><a role="menuitem"
              title="Navigate to the discussion topic that holds the minutes for this meeting"
              href="noteZoom{{meeting.minutesLocalId}}.htm">View Minutes</a></li>
          <li role="presentation" class="divider"></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              title="Make a copy of this meeting for a new timeslot"
              href="CloneMeeting.htm?id={{meeting.id}}">Clone Meeting</a></li>
          <li role="presentation"><a role="menuitem"
              title="Return back to the list of all meetings in the workspace"
              href="MeetingList.htm">List All Meetings</a></li>
        </ul>
      </span>

    </div>
<% } %>


    <div class="well" ng-show="addressMode" ng-cloak>
      <h2>Confirm Meeting Participants:</h2>
      <div>
          <tags-input ng-model="meeting.participants" 
                      placeholder="Enter users to send notification email to"
                      display-property="name" key-property="uid"
                      replace-spaces-with-dashes="false" add-on-space="true" add-on-comma="true"
                      on-tag-added="updatePlayers()" 
                      on-tag-removed="updatePlayers()">
              <auto-complete source="loadPersonList($query)" min-length="1"></auto-complete>
          </tags-input>
      </div>
      <div class="spacydiv" ng-show="meetingInPast">
          <b>Warning:</b> 
          <span class="dropdown" style="color:white;background-color:red">This meeting is scheduled for a time in the past!</span>
      </div>
      <div class="spacydiv" >
          <b>Announcement:</b> 
          <input type="checkbox" ng-model="sendMailNow"> <span class="dropdown">Send email announcement now.</span>
      </div>
      <div class="spacydiv" ng-show="calcAutSendTimes() && reminderImmediate">
          <b>Reminder:</b> 
          <span class="dropdown" style="color:red;background-color:yellow" >Warning: meeting time is so soon that the email reminder message will be send immediately.</span>
      </div>
      <div class="spacydiv"  ng-show="reminderLater">
          <b>Reminder:</b> 
          <span class="dropdown">Automatic email reminder message scheduled for {{reminderDate|date: "yyyy-MM-dd HH:mm"}}.</span>
      </div>
      <div class="spacydiv"  ng-show="reminderNone">
          <b>Reminder:</b> 
          <span class="dropdown">No automatic email reminder message will be sent.</span>
      </div>
      <div>
      <span class="dropdown" ng-hide="sendMailNow">
          <button class="btn btn-default btn-primary btn-raised" type="button" ng-click="postIt(false)"
                  title="Post this topic but don't send any email">
          Post Without Announcement </button>
      </span>
      <span class="dropdown" ng-show="sendMailNow">
          <button class="btn btn-default btn-primary btn-raised" type="button" ng-click="postIt(true)"
                  title="Post this topic and send email">
          Post &amp; Prepare Announcement </button>
      </span>
      <span class="dropdown">
          <button class="btn btn-default btn-warning btn-raised" type="button" ng-click="addressMode = false"
                  title="Cancel and leave this in draft mode.">
          Cancel </button>
      </span>
      </div>
      

    </div>




    <div style="width:100%">
      <div class="leafContent">
        <span style="font-size:150%;font-weight: bold;">
            <i class="fa fa-gavel" style="font-size:130%"></i>
            {{meeting.name}}
        </span>
      </div>
      <br/>
      <div ng-hide="editMeetingDesc">
        <table class="table">
          <col width="130px">
          <col width="20px">
          <col width="*">
          <tr>
            <td>Name:</td>
            <td ng-click="editMeetingPart='name'">
              <i class="fa fa-edit"></i>
            </td>
            <td ng-hide="'name'==editMeetingPart">
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
            <td>Scheduled Time:</td>
            <td ng-click="editMeetingPart='startTime'">
              <i class="fa fa-edit"></i>
            </td>
            <td ng-hide="'startTime'==editMeetingPart">
              <div ng-show="meeting.startTime>0">
                {{meeting.startTime|date: "dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm"}}&nbsp;
                ({{browserZone}})
                <a href="meetingTime{{meeting.id}}.ics" title="Make a calendar entry for this meeting">
                  <i class="fa fa-calendar"></i></a> &nbsp; 
                <span ng-click="getTimeZoneList()"><i class="fa fa-eye"></i> Timezones</span><br/>
                <span ng-repeat="val in allDates">{{val}}<br/></span>
              </div>
              <div ng-hide="meeting.startTime>0">
                <i>( To Be Determined )</i>
              </div>
            </td>
            <td ng-show="'startTime'==editMeetingPart">
                <div class="well" style="max-width:400px">
                    <span datetime-picker ng-model="meeting.startTime"
                          class="form-control">
                      {{meeting.startTime|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm"}}
                    </span>
                    <span>&nbsp; ({{browserZone}})</span><br/>
                    <button class="btn btn-primary btn-raised" ng-click="savePendingEdits()">Save</button>
                    <button class="btn btn-warning btn-raised" ng-click="meeting.startTime=0;savePendingEdits()">To Be Determined</button>
                </div>
            </td>
          </tr>
          <tr>
            <td>Duration:</td>
            <td ng-click="editMeetingPart='duration'">
              <i class="fa fa-edit"></i>
            </td>
            <td ng-hide="'duration'==editMeetingPart">
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
            <td>Reminder:</td>
            <td ng-click="editMeetingPart='reminderTime'">
              <i class="fa fa-edit" ng-click="editMeetingPart='reminderTime'"></i>
            </td>
            <td ng-hide="'reminderTime'==editMeetingPart">
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
            <td>Called By:</td>
            <td></td>
            <td>
              {{meeting.owner}}
            </td>
          </tr>
          <tr>
            <td>Agenda Layout:</td>
            <td ng-click="editMeetingPart='notifyLayout'">
              <i class="fa fa-edit"></i>
            </td>
            <td ng-hide="'notifyLayout'==editMeetingPart">
              {{meeting.notifyLayout}} <a href="MeetMerge.htm?id={{meeting.id}}&tem={{meeting.notifyLayout}}"><i class="fa fa-eye"></i></a>
            </td>
            <td ng-show="'notifyLayout'==editMeetingPart">
              <div class="well form-inline form-group" style="max-width:400px">
                <select class="form-control"  ng-model="meeting.notifyLayout" ng-options="n for n in allLayoutNames"></select>
                <button class="btn btn-primary btn-raised" ng-click="savePendingEdits()">Save</button>
              </div>
            </td>
          </tr>
          <tr>
            <td>Minutes Layout:</td>
            <td ng-click="editMeetingPart='defaultLayout'">
              <i class="fa fa-edit"></i>
            </td>
            <td ng-hide="'defaultLayout'==editMeetingPart">
              {{meeting.defaultLayout}} <a href="MeetMerge.htm?id={{meeting.id}}&tem={{meeting.defaultLayout}}"><i class="fa fa-eye"></i></a>
            </td>
            <td ng-show="'defaultLayout'==editMeetingPart">
              <div class="well form-inline form-group" style="max-width:400px">
                <select class="form-control"  ng-model="meeting.defaultLayout" ng-options="n for n in allLayoutNames"></select>
                <button class="btn btn-primary btn-raised" ng-click="savePendingEdits()">Save</button>
              </div>
            </td>
          </tr>
          <tr>
            <td>Target Role:</td>
            <td ng-click="editMeetingPart='targetRole'">
              <i class="fa fa-edit"></i>
            </td>
            <td ng-hide="'targetRole'==editMeetingPart">
              <a href="roleManagement.htm">{{meeting.targetRole}}</a>
              <span ng-hide="roleEqualsParticipants || meeting.state<=0" style="color:red">
                  . . . includes people who are not meeting participants!
              </span>
              <span ng-hide="meeting.state>0" style="color:red">
                  (This role is consulted at the time you POST the meeting)
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
          <tr>
            <td>Participants:</td>
            <td ng-click="editMeetingPart='participants'">
              <i class="fa fa-edit"></i>
            </td>
            <td class="form-inline form-group" ng-hide="'participants'==editMeetingPart">
                <span ng-repeat="player in meeting.participants" title="{{player.name}}"    
                  style="text-align:center">
                  <span class="dropdown" >
                    <span id="menu1" data-toggle="dropdown">
                    <img class="img-circle" 
                         ng-src="<%=ar.retPath%>icon/{{player.image}}" 
                         style="width:32px;height:32px" 
                         title="{{player.name}} - {{player.uid}}">
                    </span>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                          tabindex="-1" style="text-decoration: none;text-align:center">
                          {{player.name}}<br/>{{player.uid}}</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="navigateToUser(player)">
                          <span class="fa fa-user"></span> Visit Profile</a></li>
                    </ul>
                  </span>
                </span>
            </td>
            <td class="form-inline form-group" ng-show="'participants'==editMeetingPart">
              <div>
                  <tags-input ng-model="meeting.participants" 
                      placeholder="Enter users to send notification email to"
                      display-property="name" key-property="uid"
                      replace-spaces-with-dashes="false" add-on-space="true" add-on-comma="true"
                      on-tag-added="updatePlayers()" 
                      on-tag-removed="updatePlayers()">
                      <auto-complete source="loadPersonList($query)" min-length="1"></auto-complete>
                  </tags-input>
                  <button class="btn btn-primary btn-raised" ng-click="savePendingEdits()">Save</button>
                  <button class="btn btn-default btn-raised" ng-click="appendRolePlayers()" ng-hide="roleEqualsParticipants">
                      Add Everyone from {{meeting.targetRole}}
                  </button>
              </div>
            </td>
          </tr>
          <tr>
            <td>Description:</td>
            <td ng-click="editMeetingDesc=true">
              <i class="fa fa-edit"></i>
            </td>
            <td>
              <div ng-bind-html="meeting.meetingInfo"></div>
            </td>
          </tr>
          <tr ng-show="isCompleted()">
            <td>Minutes:</td>
            <td></td>
            <td>
                <div ng-show="minutesDraft && meeting.minutesId">
                   Draft:
                   <span class="btn btn-sm btn-default btn-raised"  style="margin:4px;background-color:yellow;"
                         title="Navigate to the discussion topic with the minutes for this meeting"
                         ng-click="navigateToTopic(meeting.minutesLocalId)">
                         View Minutes
                   </span>
                   <span class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
                         title="if you are happy with the draft minutes as they are, use this to publish them to everyone"
                         ng-click="postMinutes(meeting.minutesLocalId)">
                         Post Minutes as they are
                   </span>
                </div>
                <div ng-show="!minutesDraft && meeting.minutesId">
                   Posted:
                   <span class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
                         ng-click="navigateToTopic(meeting.minutesLocalId)">
                         View Minutes
                   </span>
                </div>
                <div ng-hide="meeting.minutesId">
                   <span class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
                         title="Takes the minutes entires and comments and puts them into a single discussion topic document"
                         ng-click="createMinutes()">
                         Generate Minutes
                   </span>
                </div>
            </td>
          </tr>
          <tr ng-show="previousMeeting.id">
            <td>Previous Meeting:</td>
            <td></td>
            <td>
              <a href="meetingHtml.htm?id={{previousMeeting.id}}">
                {{previousMeeting.startTime|date: "dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm"}}</a> 
                <span>&nbsp; ({{browserZone}})</span>
            </td>
          </tr>
          <tr ng-show="previousMeeting.minutesId">
            <td>Previous Minutes:</td>
            <td></td>
            <td>
                <span class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
                     ng-click="navigateToTopic(previousMeeting.minutesLocalId)"
                     title="Navigate to the discussion topic that holds the minutes for the previous meeting">
                     Previous Minutes
                </span>
            </td>
          </tr>
          <tr ng-show="isCompleted()">
            <td>Attendees:</td>
            <td></td>
            <td>
                <span ng-repeat="person in getAttended() track by $index">{{person.name}}, </span>
            </td>
          </tr>
          <tr><td></td><td></td><td></td>
          </tr>
        </table>
      </div>

    <div ng-show="editMeetingDesc" style="width:100%">
        <div class="well leafContent">
            <div ui-tinymce="tinymceOptions" ng-model="meeting.meetingInfo"
                 class="leafContent" style="min-height:200px;" ></div>
            <button ng-click="savePendingEdits()" class="btn btn-primary btn-raised">Save</button>
            <button ng-click="revertAllEdits()" class="btn btn-warning btn-raised">Cancel</button>
        </div>
    </div>


    
<!-- Here is the voting for proposed time section -->
    
    

    <div class="comment-outer"  
         title="Shows what time slots people might be able to attend.">
      <div ng-click="showTimeSlots=!showTimeSlots">Proposed Meeting Times 
          <span ng-hide="showTimeSlots || meeting.startTime<=0"><a>(Click to view)</a></span> </div>
      <div class="comment-inner" ng-show="showTimeSlots || meeting.startTime<=0">
          <table class="table">
          <tr>
              <th></th>
              <th>Time ({{browserZone}})</th>
              <th style="width:20px;"></th>
              <th ng-repeat="player in timeSlotResponders" title="{{player.name}}"    
                  style="text-align:center">
                  <span class="dropdown" >
                    <span id="menu1" data-toggle="dropdown">
                    <img class="img-circle" 
                         ng-src="<%=ar.retPath%>icon/{{player.image}}" 
                         style="width:32px;height:32px" 
                         title="{{player.name}} - {{player.uid}}">
                    </span>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                          tabindex="-1" style="text-decoration: none;text-align:center">
                          {{player.name}}<br/>{{player.uid}}</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="navigateToUser(player)">
                          <span class="fa fa-user"></span> Visit Profile</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="removeVoter('timeSlots',player.uid)">
                          <span class="fa fa-times"></span> Remove User </a></li>
                    </ul>
                  </span>
              </th>
          </tr>
          <tr ng-repeat="time in meeting.timeSlots">
              <td>
                <span class="dropdown">
                    <button class="dropdown-toggle specCaretBtn" type="button"  d="menu"
                        data-toggle="dropdown"> <span class="caret"></span> </button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu">
                      <li role="presentation">
                          <a role="menuitem" ng-click="removeTime('timeSlots',time.proposedTime)">
                          <i class="fa fa-times"></i>
                          Remove Proposed Time</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="console.log('foo');setMeetingTime(time.proposedTime)"><i class="fa fa-check"></i> Set Meeting to this Time</a></li>
                    </ul>
                </span>
              </td>
              <td><div ng-click="setProposedTime(time.proposedTime)">
                  {{time.proposedTime |date:"dd-MMM-yyyy HH:mm"}}
                  <span ng-show="time.proposedTime == meeting.startTime" class="fa fa-check"></span>
              </div></td>
              <td style="width:20px;"></td>
              <td ng-repeat="resp in timeSlotResponders"   
                  style="text-align:center">
                 <span class="dropdown">
                    <button class="dropdown-toggle btn votingButton" type="button"  d="menu" style="margin:0px"
                        data-toggle="dropdown"> &nbsp;
                        <span ng-show="time.people[resp.uid]==1" title="Conflict for that time" style="color:red;">
                            <span class="fa fa-minus-circle"></span>
                            <span class="fa fa-minus-circle"></span></span>
                        <span ng-show="time.people[resp.uid]==2" title="Very uncertain, maybe unlikely" style="color:red;">
                            <span class="fa fa-question-circle"></span></span>
                        <span ng-show="time.people[resp.uid]==3" title="No response given" style="color:#eeeeee;">
                            <span class="fa fa-question-circle"></span></span>
                        <span ng-show="time.people[resp.uid]==4" title="ok time for me" style="color:green;">
                            <span class="fa fa-plus-circle"></span></span>
                        <span ng-show="time.people[resp.uid]==5" title="good time for me" style="color:green;">
                            <span class="fa fa-plus-circle"></span>
                            <span class="fa fa-plus-circle"></span></span>
                        &nbsp;
                    </button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu">
                      <li role="presentation">
                          <a role="menuitem" ng-click="setVote('timeSlots', time.proposedTime, resp.uid, 5)">
                          <i class="fa fa-plus-circle" style="color:green"></i>
                          <i class="fa fa-plus-circle" style="color:green"></i>
                          Good Time</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="setVote('timeSlots', time.proposedTime, resp.uid, 4)">
                          <i class="fa fa-plus-circle" style="color:green"></i>
                          OK Time</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="setVote('timeSlots', time.proposedTime, resp.uid, 3)">
                          <i class="fa fa-question-circle" style="color:gray"></i>
                          No Response</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="setVote('timeSlots', time.proposedTime, resp.uid, 2)">
                          <i class="fa fa-question-circle" style="color:red"></i>
                          Uncertain</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="setVote('timeSlots', time.proposedTime, resp.uid, 1)">
                          <i class="fa fa-minus-circle" style="color:red"></i>
                          <i class="fa fa-minus-circle" style="color:red"></i>
                          Conflict at that Time</a></li>
                    </ul>
                </span>
              </td>
          </tr>
          </table>
          <table class="spaceyTable"><tr>
          <td>
            <button ng-click="createTime('timeSlots', newProposedTime)" class="btn btn-primary btn-raised">Add Proposed Time</button>
          </td>
          <td>
            <span datetime-picker ng-model="newProposedTime" class="form-control" style="display:inline">
              {{newProposedTime|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm"}}  
            </span> 
              &nbsp; ({{browserZone}})
          </td>
          </tr><tr>
          <td>
            <button ng-click="addProposedVoter('timeSlots', newProposedVoter)" class="btn btn-primary btn-raised">Add Voter</button>
          </td>
          <td>
            <input type="text" ng-model="newProposedVoter" class="form-control" 
               placeholder="Enter email address"
               typeahead="person.uid as person.name for person in getPeople($viewValue) | limitTo:12">
          </td>
          </tr></table>
       </div>
    </div>        
    
    
<!-- THIS IS THE ROLL CALL SECTION -->


    <div class="comment-outer" style="margin:40px" ng-show="editAttendees()">
      <div><h2 style="margin:5px">Attendance List</h2></div>
      <div class="comment-inner">
        <div class="form-inline form-group" style="margin:20px">
           Attendees:
           <button class="btn btn-sm" ng-repeat="person in getAttended()" style="margin:3px;"
                   ng-click="removeAttendee(person)">{{person.name}}</button>
        </div>
        <div class="form-inline form-group" style="margin:20px">
            <button class="btn btn-primary btn-raised" ng-click="addYouself()" 
                    ng-hide="isInAttendees">Add Yourself</button> &nbsp;
            Email Address: 
            <input type="text" ng-model="newAttendee" class="form-control" 
               placeholder="Enter email address" style="margin: 10px"
               typeahead="person.uid as person.name for person in getPeople($viewValue) | limitTo:12">
            <button class="btn btn-primary btn-raised" ng-click="addAttendee()"
                    ng-show="newAttendee">
               Add It </button>
        </div>
      </div>
    </div>


    <div class="comment-outer" ng-show="showRollBox()" 
         title="Shows what people have said about being able to attend the meeting.">
      <div style="float:right" ng-click="toggleRollCall()"><i class="fa fa-close"></i></div>
      <div>Roll Call</div>
      <table class="table">
      <tr>
          <th>Name</th>
          <th style="width:20px;"></th>
          <th>Attending</th>
          <th>Situation</th>
      </tr>
      <tr class="comment-inner" ng-repeat="pers in peopleStatus">
          <td>{{pers.name}}</td>
          <td  style="width:20px;">
              <div ng-show="pers.uid=='<%ar.writeJS(currentUser);%>'" style="cursor:pointer;"
              ng-click="toggleRollCall()">
                  <i class="fa fa-edit"></i></div></td>
          <td>{{pers.attend}}</td>
          <td>{{pers.situation}}</td>
      </tr>
      </table>
    </div>
    
    
    


<style>
.agendaItemFull {
    border: 1px solid lightgrey;
    border-radius:10px;
    margin-top:20px;
}
.agendaItemBlank {
    background-color:lightgray;
    margin-top:20px;
}
</style>
<script>
</script>



<div ng-repeat="item in getAgendaItems()">
    <div class="agendaItemBlank" ng-show="item.isSpacer">
      <div style="padding:5px;">
        <div style="width:100%">
                <span class="blankTitle" ng-click="showItemMap[item.id]=!showItemMap[item.id]">
                    {{item.subject}} </span>  &nbsp;
<%if (isLoggedIn) { %>
                <span class="dropdown">
                    <button class="dropdown-toggle specCaretBtn" type="button"  d="menu"
                        data-toggle="dropdown"> <span class="caret"></span> </button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu">
                      <li role="presentation">
                          <a role="menuitem" ng-click="openAgenda(item)">
                          <i class="fa fa-cogs"></i>
                          Edit Agenda Item</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="moveItem(item,-1)"><i class="fa fa-arrow-up"></i> Move Up</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="moveItem(item,1)"><i class="fa fa-arrow-down"></i> Move Down</a></li>
                    </ul>
                </span>
<% } %>
                <span>
                    <i>({{item.duration}} minutes) {{item.schedule | date: 'HH:mm'}}
                      - {{item.scheduleEnd | date: 'HH:mm'}} </i>
                </span>
        </div>
      </div>
    </div>
    <div class="agendaItemFull"  ng-hide="item.isSpacer">
    <table style="width:100%">

                          <!--  AGENDA HEADER -->
      <tr>
        <td style="width:100%">
          <div style="padding:5px;">
            <div style="width:100%">
                <span class="agendaTitle" ng-click="showItemMap[item.id]=!showItemMap[item.id]">
                    <span ng-show="item.proposed" >--</span>
                    <span ng-hide="item.proposed" >{{item.number}}.</span>
                    
                    {{item.subject}} </span>  &nbsp;
<%if (isLoggedIn) { %>
                <span class="dropdown">
                    <button class="dropdown-toggle specCaretBtn" type="button"  d="menu"
                        data-toggle="dropdown"> <span class="caret"></span> </button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu">
                      <li role="presentation">
                          <a role="menuitem" ng-click="showItemMap[item.id]=!showItemMap[item.id]">
                          <i class="fa fa-sort"></i>
                          <span>Open / Close</span>
                          </a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="openAgenda(item)">
                          <i class="fa fa-edit"></i>
                          Edit Agenda Item</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="openAttachDocument(item)"><i class="fa fa-book"></i>
                             Docs Add/Remove</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="openAttachAction(item)"><i class="fa fa-flag"></i>
                             Action Items Add/Remove</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="openAttachTopics(item)"><i class="fa fa-lightbulb-o"></i>
                              <span ng-hide="item.topicLink">Set</span>
                              <span ng-show="item.topicLink">Change</span>
                              Discussion Topic</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="toggleReady(item)"><i class="fa fa-thumbs-o-up"></i>
                             Toggle Ready Flag</a></li>
                      <li role="presentation" >
                          <a role="menuitem" ng-click="toggleProposed(item)"><i class="fa fa-thumbs-o-up"></i>
                             Toggle Accepted/Proposed</a></li>
                      <li role="presentation" ng-hide="item.proposed">
                          <a role="menuitem" ng-click="moveItem(item,-1)"><i class="fa fa-arrow-up"></i>
                             Move Up</a></li>
                      <li role="presentation" ng-hide="item.proposed">
                          <a role="menuitem" ng-click="moveItem(item,1)"><i class="fa fa-arrow-down"></i>
                             Move Down</a></li>
                       <li role="presentation">
                          <a role="menuitem" ng-click="moveItemToBacklog(item)"><i class="fa fa-trash"></i>
                              Remove Item</a></li>

                   </ul>
                </span>
                <span ng-show="item.proposed" style="background-color:yellow;padding:3px;cursor:pointer" ng-click="toggleProposed(item)">Proposed</span>
                <span ng-show="meeting.state==2">
                    <span ng-hide="item.timerRunning" style="padding:5px">
                        <button ng-click="agendaStartButton(item)"><i class="fa fa-clock-o"></i> Start</button>
                        Elapsed: {{item.timerTotal| minutes}}
                        Remaining: {{item.duration - item.timerTotal| minutes}}
                    </span>
                    <span ng-show="item.timerRunning" ng-style="timerStyleComplete(item)">
                        <button ng-click="stopAgendaRunning()"><i class="fa fa-clock-o"></i> Stop</button>
                        Elapsed: {{item.timerTotal| minutes}}
                        Remaining: {{item.duration - item.timerTotal| minutes}}
                    </span>
                </span>
                <span ng-show="meeting.state>2">
                    <span ng-show="item.timerTotal>0" style="padding:5px">
                        Duration: {{item.timerTotal| minutes}}
                    </span>
                </span>
                <span style="float:right" ng-hide="item.readyToGo || isCompleted() || item.proposed" >
                    <img src="<%=ar.retPath%>assets/goalstate/agenda-not-ready.png"
                         ng-click="toggleReady(item)"
                         title="Indicates that the agenda item does NOT have all of the documents, presentations, and is full prepared for the meeting."
                         style="width:24px;height=24px;float:right">
                </span>
                <span style="float:right" ng-show="item.readyToGo && !isCompleted() && !item.proposed"  >
                    <img src="<%=ar.retPath%>assets/goalstate/agenda-ready-to-go.png"
                         ng-click="toggleReady(item)"
                         title="Indicates that the agenda item has all of the documents, presentations, and is full prepared for the meeting."
                         style="width:24px;height=24px">
                </span>
                <span style="float:right;margin-right:10px" ng-show="!isCompleted() && !item.proposed"  ng-click="moveItem(item,-1)" title="Move agenda item up if possible">
                    <i class="fa fa-arrow-up"></i>
                </span>
                <span style="float:right;margin-right:10px" ng-show="!isCompleted() && !item.proposed"  ng-click="moveItem(item,1)" title="Move agenda item down if possible">
                    <i class="fa fa-arrow-down"></i>
                </span>
                <span style="float:right;margin-right:10px" ng-show="item.proposed"  ng-click="toggleProposed(item)" title="Accept this proposed agenda item">
                   ACCEPT</i>
                </span>
<% } %>
            </div>
            <div>
                <i ng-click="openAgenda(item)">
                <i class="fa fa-edit"></i> {{item.schedule | date: 'HH:mm'}} ({{item.duration}} minutes)<span ng-repeat="pres in item.presenterList">, {{pres.name}}</span></i>
            </div>
          </div>
        </td> 
      </tr>

                          <!--  AGENDA BODY -->
      <tr ng-show="showItemMap[item.id]">
        <td style="width:100%" ng-click="openAgenda(item, 'Description')">
           <button ng-show="item.lockUser.uid && item.lockUser.uid.length>0" class="btn btn-sm" style="background-color:lightyellow;margin-left:20px;">
               {{item.lockUser.name}} is editing.
           </button>
           <div class="leafContent">
             <div ng-bind-html="item.desc"></div>
           </div>
        </td>
      </tr>

                          <!--  AGENDA ATTACHMENTS -->
      <tr ng-show="showItemMap[item.id] && itemTopics(item).length>0" >
        <td>
           <div style="margin:10px;">
              <b>Discussion Topic: </b>
              <span ng-repeat="topic in itemTopics(item)" class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
                   ng-click="navigateToTopic(item.topicLink)">
                    <i class="fa fa-lightbulb-o" style="font-size:130%"></i> {{topic.subject}}
              </span>
           </div>
        </td>
      </tr>
      <tr ng-show="showItemMap[item.id]">
        <td>
           <table style="margin:10px;"><tr>
              <td><b>Attachments: </b></td>
              <td><span ng-repeat="docid in item.docList track by $index" style="vertical-align: top">
                  <span class="dropdown" title="Access this attachment">
                      <button class="attachDocButton" id="menu1" data-toggle="dropdown">
                      <img src="<%=ar.retPath%>assets/images/iconFile.png"> 
                      {{getFullDoc(docid).name |limitTo:15}}</button>
                      <ul class="dropdown-menu" role="menu" aria-labelledby="menu1" style="cursor:pointer">
                        <li role="presentation" style="background-color:lightgrey">
                            <a role="menuitem" 
                            title="This is the full name of the document"
                            ng-click="navigateToDoc(docid)">{{getFullDoc(docid).name}}</a></li>
                        <li role="presentation"><a role="menuitem" target="_blank"
                            title="Visit the access page where you can download the document and see comments about it"
                            ng-click="navigateToDoc(docid)">Access Document</a></li>
                        <li role="presentation"><a role="menuitem" target="_blank"
                            title="Directly download the document"
                            ng-click="downloadDocument(docid)">Download File</a></li>
                        <li role="presentation"><a role="menuitem" target="_blank"
                            title="View the document details before accessing it"
                            ng-click="navigateToDocDetails(docid).htm">Document Details</a></li>
                        <li role="presentation"><a role="menuitem" target="_blank"
                            title="create a new email with this document attached"
                            ng-click="sendDocByEmail(docid)">Send by Email</a></li>
                        <li role="presentation"><a role="menuitem" target="_blank"
                            title="remove this document from this agenda item"
                            ng-click="unattachDocFromItem(item, docid)">Un-attach</a></li>
                      </ul>
                  </span>
              </span>
<%if (isLoggedIn) { %>
              <button class="btn btn-sm btn-primary btn-raised" ng-click="openAttachDocument(item)"
                  title="Attach a document">
                  ADD </button>
<% } %>
           </td></tr></table>
        </td>
      </tr>


                          <!--  AGENDA Action ITEMS -->
      <tr ng-show="showItemMap[item.id] && itemGoals(item).length>0">
        <td style="width:100%">
           <div style="height:15px"></div>
           <table class="table">
           <tr>
              <th></th>
              <th></th>
              <th>Synopsis</th>
              <th>Assignee</th>
              <th>Due</th>
              <th title="Red-Yellow-Green assessment of status">R-Y-G</th>
              <th>Status</th>
           </tr>
           <tr ng-repeat="goal in itemGoals(item)" style="margin-left:30px;">
              <td>
                  <span class="dropdown">
                    <button class="dropdown-toggle specCaretBtn" type="button"  d="menu"
                        data-toggle="dropdown"> <span class="caret"></span> </button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
                      <li role="presentation"><a role="menuitem"
                          ng-click="openModalActionItem(item,goal)">Edit Quick</a></li>
                      <li role="presentation"><a role="menuitem"
                          href="task{{goal.id}}.htm">Edit Task</a></li>
                      <li role="presentation" class="divider"></li>
                      <li role="presentation"><a role="menuitem"
                          ng-click="removeGoalFromItem(item, goal)">Remove Action Item</a></li>
                    </ul>
                  </span>
              </td>
              <td style="width:20px;">
              <a href="task{{goal.id}}.htm" class="leafContent"   >
                <img ng-src="<%=ar.retPath%>assets/goalstate/small{{goal.state}}.gif">
              </a>
              </td>
              <td style="max-width:300px;" ng-click="openModalActionItem(item,goal,'details')">
              <b>{{goal.synopsis}}</b> ~ {{goal.description}}
              </td>
              <td ng-click="openModalActionItem(item,goal,'assignee')">
              <span ng-repeat="person in goal.assignTo"> {{person.name}}<br/></span>
              </td>
              <td ng-click="openModalActionItem(item,goal)" style="width:100px;">
              <span ng-show="goal.duedate>=0">{{goal.duedate|date}} </span>
              </td>
              <td style="width:120px;" title="Red-Yellow-Green assessment of status">
                  <img src="<%=ar.retPath%>assets/goalstate/red_off.png" ng-hide="goal.prospects=='bad'"
                       title="Red: In trouble" ng-click="changeGoalState(goal, 'bad')">
                  <img src="<%=ar.retPath%>assets/goalstate/red_on.png"  ng-show="goal.prospects=='bad'"
                       title="Red: In trouble" >
                  <img src="<%=ar.retPath%>assets/goalstate/yellow_off.png" ng-hide="goal.prospects=='ok'"
                       title="Yellow: Warning" ng-click="changeGoalState(goal, 'ok')">
                  <img src="<%=ar.retPath%>assets/goalstate/yellow_on.png"  ng-show="goal.prospects=='ok'"
                       title="Yellow: Warning" >
                  <img src="<%=ar.retPath%>assets/goalstate/green_off.png" ng-hide="goal.prospects=='good'"
                       title="Green: Good shape" ng-click="changeGoalState(goal, 'good')">
                  <img src="<%=ar.retPath%>assets/goalstate/green_on.png"  ng-show="goal.prospects=='good'"
                       title="Green: Good shape">
              </td>
              <td style="max-width:300px;" ng-click="openModalActionItem(item,goal)">
                {{goal.status}}
              </td>
           </tr>
           </table>
        </td>
      </tr>

      </table>
      </div>



                          <!--  AGENDA comments -->
      <table ng-show="showItemMap[item.id] && !item.isSpacer" >
      <tr>
        <td style="width:50px;vertical-align:top;padding:15px;"></td>
        <td>
          <div class="comment-outer" ng-show="item.minutes">
            <div>Minutes</div>
            <div class="comment-inner" ng-bind-html="item.minutes"></div>
          </div>
        </td>
      </tr>
      <tr ng-repeat="cmt in item.comments">

          <%@ include file="/spring/jsp/CommentView.jsp"%>

      </tr>
<%if (isLoggedIn) { %>
      <tr>
        <td></td>
        <td>
        <div style="margin:20px;">
            <button ng-click="openCommentCreator(item, 1)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-comments-o"></i> Comment</button>
            <button ng-click="openCommentCreator(item, 2)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-star-o"></i> Proposal</button>
            <button ng-click="openCommentCreator(item, 3)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-question-circle"></i> Round</button>
        </div>
        </td>
      </tr>
<% } %>
    </table>
    </div>


            
<hr/>

<span>
Anticipated end: {{meeting.startTime + (meeting.agendaDuration*60000) | date: 'HH:mm'}},
</span> 

   
<span ng-show="meeting.state>=2">
 elapsed duration: {{meeting.timerTotal|minutes}},
<button ng-click="stopAgendaRunning()" ng-show="meeting.state==2"><i class="fa fa-clock-o"></i> Stop</button>
</span>

    
<%if (isLoggedIn) { %>
    <hr/>
    <div style="margin:20px;" ng-show="meeting.state<3">
        <button ng-click="createAgendaItem()" class="btn btn-primary btn-raised">Propose New Agenda Item</button>
    </div>

<% } %>

<!-- Here is the voting for future meeting proposed time section -->
    
    
    <div class="comment-outer" style="margin-top:50px" 
         title="Shows what time slots people might be able to attend for the next meeting.">
      <div ng-click="showFutureSlots=!showFutureSlots">Future Meeting Times
          <span ng-hide="showFutureSlots"><a>(Click to view)</a></span></div>
      <div class="comment-inner" ng-show="showFutureSlots" >
          <table class="table">
          <tr>
              <th></th>
              <th>Time ({{browserZone}})</th>
              <th style="width:20px;"></th>
              <th ng-repeat="player in futureSlotResponders" title="{{player.name}}"    
                  style="text-align:center">
                  <span class="dropdown" >
                    <span id="menu1" data-toggle="dropdown">
                    <img class="img-circle" 
                         ng-src="<%=ar.retPath%>icon/{{player.image}}" 
                         style="width:32px;height:32px" 
                         title="{{player.name}} - {{player.uid}}">
                    </span>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                          tabindex="-1" style="text-decoration: none;text-align:center">
                          {{player.name}}<br/>{{player.uid}}</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="navigateToUser(player)">
                          <span class="fa fa-user"></span> Visit Profile</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="removeVoter('futureSlots',player.uid)">
                          <span class="fa fa-times"></span> Remove User </a></li>
                    </ul>
                  </span>
              </th>
          </tr>
          <tr ng-repeat="time in meeting.futureSlots">
              <td>
                <span class="dropdown">
                    <button class="dropdown-toggle specCaretBtn" type="button"  d="menu"
                        data-toggle="dropdown"> <span class="caret"></span> </button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu">
                      <li role="presentation">
                          <a role="menuitem" ng-click="removeTime('futureSlots',time.proposedTime)">
                          <i class="fa fa-times"></i>
                          Remove Proposed Time</a></li>
                    </ul>
                </span>
              </td>
              <td><div ng-click="setProposedTime(time.proposedTime)">{{time.proposedTime |date:"dd-MMM-yyyy HH:mm"}}</div></td>
              <td style="width:20px;"></td>
              <td ng-repeat="resp in futureSlotResponders"   
                  style="text-align:center">
                 <span class="dropdown">
                    <button class="dropdown-toggle btn votingButton" type="button"  d="menu" style="margin:0px"
                        data-toggle="dropdown"> &nbsp;
                        <span ng-show="time.people[resp.uid]==1" title="Conflict for that time" style="color:red;">
                            <span class="fa fa-minus-circle"></span>
                            <span class="fa fa-minus-circle"></span></span>
                        <span ng-show="time.people[resp.uid]==2" title="Very uncertain, maybe unlikely" style="color:red;">
                            <span class="fa fa-question-circle"></span></span>
                        <span ng-show="time.people[resp.uid]==3" title="No response given" style="color:#eeeeee;">
                            <span class="fa fa-question-circle"></span></span>
                        <span ng-show="time.people[resp.uid]==4" title="ok time for me" style="color:green;">
                            <span class="fa fa-plus-circle"></span></span>
                        <span ng-show="time.people[resp.uid]==5" title="good time for me" style="color:green;">
                            <span class="fa fa-plus-circle"></span>
                            <span class="fa fa-plus-circle"></span></span>
                        &nbsp;
                    </button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu">
                      <li role="presentation">
                          <a role="menuitem" ng-click="setVote('futureSlots', time.proposedTime, resp.uid, 5)">
                          <i class="fa fa-plus-circle" style="color:green"></i>
                          <i class="fa fa-plus-circle" style="color:green"></i>
                          Good Time</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="setVote('futureSlots', time.proposedTime, resp.uid, 4)">
                          <i class="fa fa-plus-circle" style="color:green"></i>
                          OK Time</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="setVote('futureSlots', time.proposedTime, resp.uid, 3)">
                          <i class="fa fa-question-circle" style="color:gray"></i>
                          No Response</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="setVote('futureSlots', time.proposedTime, resp.uid, 2)">
                          <i class="fa fa-question-circle" style="color:red"></i>
                          Uncertain</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="setVote('futureSlots', time.proposedTime, resp.uid, 1)">
                          <i class="fa fa-minus-circle" style="color:red"></i>
                          <i class="fa fa-minus-circle" style="color:red"></i>
                          Conflict at that Time</a></li>
                    </ul>
                </span>
              </td>
          </tr>
          </table>
          <table class="spaceyTable"><tr>
          <td>
            <button ng-click="createTime('futureSlots', newProposedTime)" class="btn btn-primary btn-raised">Add Future Time</button>
          </td>
          <td>
            <span datetime-picker ng-model="newProposedTime" class="form-control" style="display:inline">
              {{newProposedTime|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm"}}
            </span>
            <span>&nbsp; ({{browserZone}})</span>
          </td>
          </tr><tr>
          <td>
            <button ng-click="addProposedVoter('futureSlots', newProposedVoter)" class="btn btn-primary btn-raised">Add Voter</button>
          </td>
          <td>
            <input type="text" ng-model="newProposedVoter" class="form-control" 
               placeholder="Enter email address"
               typeahead="person.uid as person.name for person in getPeople($viewValue) | limitTo:12">
          </td>
          </tr></table>
       </div>
    </div>

    <br/>
    Refreshed {{refreshCount}} times.   {{refreshStatus}}<br/>
    <br/>
    <br/>
    <br/>
    <br/>
    
</div>

<script src="<%=ar.retPath%>templates/ActionItemCtrl.js"></script>
<script src="<%=ar.retPath%>templates/CommentModal.js"></script>
<script src="<%=ar.retPath%>templates/ResponseModal.js"></script>
<script src="<%=ar.retPath%>templates/OutcomeModal.js"></script>
<script src="<%=ar.retPath%>templates/DecisionModal.js"></script>
<script src="<%=ar.retPath%>templates/AttachDocumentCtrl.js"></script>
<script src="<%=ar.retPath%>templates/AttachTopicCtrl.js"></script>
<script src="<%=ar.retPath%>templates/AttachActionCtrl.js"></script>
<script src="<%=ar.retPath%>templates/AgendaCtrl.js"></script>
