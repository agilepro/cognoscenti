<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%@page import="org.socialbiz.cog.LicenseForUser"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%@page import="org.socialbiz.cog.mail.ChunkTemplate"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    String mode   = ar.defParam("mode", "Agenda");
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
    
    JSONObject meetingJSON = mRec.getFullJSON(ar, ngw);
    String agendaLayout = meetingJSON.optString("notifyLayout", "FullDetail.chtml");
    File agendaLayoutFile = MeetingRecord.findMeetingLayout(ar,ngw,agendaLayout);        
    String minutesLayout = meetingJSON.optString("defaultLayout", "FullDetail.chtml");
    File minutesLayoutFile = MeetingRecord.findMeetingLayout(ar,ngw,minutesLayout);
    String mnm = AccessControl.getAccessMeetParams(ngw, mRec); 

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

.comment-outer {
    border: 1px solid lightgrey;
    border-radius:8px;
    padding:5px;
    margin-top:15px;
    background-color:#EEE;
    cursor: pointer;
}
.comment-inner {
    border: 1px solid lightgrey;
    border-radius:6px;
    padding:5px;
    background-color:white;
}
.comment-state-draft {
    background-color:yellow;
}
.comment-state-active {
    background-color:#DEF;
}
.comment-state-complete {
    background-color:#EEE;
}
.comment-phase-change {
    border: 1px solid #DFD;
    background-color:#EFE;
}
.invisibleButton {
    color: #fff;
}
.invisibleButton:hover {
    color: black;
    background-color:#eee;
}

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
embeddedData.mode     = "<%ar.writeJS(mode);%>";

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
    padding:5px;
    cursor:pointer;
}
.agendaTitleSelected {
    font-size: 130%;
    font-weight: bold;
    padding:5px;
    cursor:pointer;
    color:white;
    background-color:black;
}
.agendaTitle:hover {
    font-size: 130%;
    font-weight: bold;
    padding:5px;
    cursor:pointer;
    color:black;
    background-color:skyblue;
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
.buttonSpacerOff {
    padding: 10px;
    background-color:red;
}
.buttonSpacerOn {
    padding: 10px;
    background-color:green;
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
      <button class="btn btn-default btn-raised" type="button" id="menu1" data-toggle="dropdown" style="{{meetingStateStyle(meeting.state)}}" ng-click="displayMode='Status'">
          State: {{stateName()}}</button>
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
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
              href="meetingFull.htm?id={{meeting.id}}">Show OLD Display</a></li>
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

      <div class="leafContent">
        <span style="font-size:150%;font-weight: bold;">
            <i class="fa fa-gavel" style="font-size:130%"></i>
            {{meeting.name}}
        </span>
      </div>


<div>

<button onclick="window.location.assign('meetingHtml.htm?id='+embeddedData.meetId+'&mode=Agenda')"   
        ng-class="statusButtonClass('Agenda')"  >Agenda</button>
<button onclick="window.location.assign('meetingHtml.htm?id='+embeddedData.meetId+'&mode=Minutes')" 
        ng-class="statusButtonClass('Minutes')" >Minutes</button>
<button ng-click="displayMode='Times'"    ng-class="statusButtonClass('Times')"   >Schedule</button>
<button ng-click="displayMode='General'"  ng-class="statusButtonClass('General')" >General</button>
<button ng-click="displayMode='Status'"   ng-class="statusButtonClass('Status')"  >Status</button>
<button ng-click="displayMode='Attendance'" ng-class="statusButtonClass('Attendance')">Attendance</button>
<button ng-click="displayMode='Items'"    ng-class="statusButtonClass('Items')"   >Items</button>
</div>

<div ng-show="displayMode=='Status'">
    <div class="well" ng-cloak>
        <table>
        <tr>
        <td class="{{meeting.state==0 ? buttonSpacerOn : buttonSpacerOff}}">
            <span class="btn btn-default btn-raised" style="{{meetingStateStyle(0)}}" 
                  ng-click="changeMeetingState(0)">Draft</span></td>
        <td>----&gt;</td>
        <td class="{{meeting.state==1 ? buttonSpacerOn : buttonSpacerOff}}">
            <span class="btn btn-default btn-raised" style="{{meetingStateStyle(1)}}" 
                  ng-click="changeMeetingState(1)">Planning</span></td>
        <td>----&gt;</td>
        <td class="{{meeting.state==2 ? buttonSpacerOn : buttonSpacerOff}}">
            <span class="btn btn-default btn-raised" style="{{meetingStateStyle(2)}}" 
                  ng-click="changeMeetingState(2)">Running</span></td>
        <td>----&gt;</td>
        <td class="{{meeting.state==3 ? buttonSpacerOn : buttonSpacerOff}}">
            <span class="btn btn-default btn-raised" style="{{meetingStateStyle(3)}}" 
                  ng-click="changeMeetingState(3)">Completed</span></td>
        </tr>
        </table>
      <div ng-show="meeting.state<=0">
          <p>Meeting is in draft mode and is hidden from the participants.
             Advance the meeting to planning mode to let them know about it
             before the meeting starts.</p>
             
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
              Go To Planning </button>
          </span>
          <span class="dropdown" ng-show="sendMailNow">
              <button class="btn btn-default btn-primary btn-raised" type="button" ng-click="postIt(true)"
                      title="Post this topic and send email">
              Prepare Announcement &amp; Go To Planning</button>
          </span>
          </div>
      </div>
      <div ng-show="meeting.state==1">
          <p>Meeting is in planning mode until the time that the meeting starts.</p>
      </div>
      <div ng-show="meeting.state==2">
          <p>Meeting is in running mode and will allow updates normally done during the meeting.</p>
      <table class="table">
        <tr>
          <th></th>
          <th>Planned Time</th>
          <th></th>
          <th>Elapsed</th>
          <th></th>
          <th>Remaining</th>
        </tr>
        <tr ng-repeat="item in getAgendaItems()">
          <td>
                <span ng-show="item.proposed  || item.isSpacer" >--</span>
                <span ng-hide="item.proposed  || item.isSpacer" >{{item.number}}.</span>

                {{item.subject}} 
          </td>
          <td ng-style="timerStyleComplete(item)">
                {{item.duration| minutes}}
          </td>
          <td ng-style="timerStyleComplete(item)">
                <span ng-hide="item.timerRunning">
                    <button ng-click="agendaStartButton(item)"><i class="fa fa-clock-o"></i> Start</button>
                </span>
                <span ng-show="item.timerRunning">
                    <button ng-click="stopAgendaRunning()"><i class="fa fa-clock-o"></i> Stop</button>
                </span>
          </td>
          <td ng-style="timerStyleComplete(item)">
                {{item.timerTotal| minutes}}
          </td>
          <td>
              <!--button ng-click="setItemTime(item,'incr')">+1</button-->
              <!--button ng-click="setItemTime(item,'decr')">-1</button-->
              <!--button ng-click="setItemTime(item,'ceil')">Round Up</button-->
              <!--button ng-click="setItemTime(item,'floor')">Round Down</button-->
          </td>
          <td>
                {{item.duration - item.timerTotal| minutes}}
          </td>
        </tr>
      </table>

      </div>
      <div ng-show="meeting.state>=3">
          <p>Meeting is completed and no more updates are expected.</p>
      <table class="table">
        <tr>
          <td></td>
          <td>Planned Time</td>
          <td>Used Time</td>
        </tr>
        <tr ng-repeat="item in getAgendaItems()">
          <td>
                <span ng-show="item.proposed" >--</span>
                <span ng-hide="item.proposed" >{{item.number}}.</span>

                {{item.subject}} 
          </td>
          <td>
                <span ng-hide="item.timerRunning" style="padding:5px">
                    {{item.duration| minutes}}
                </span>
                <span ng-show="item.timerRunning" ng-style="timerStyle(item)">
                    {{item.duration| minutes}}
                </span>
          </td>
          <td>
                <span ng-hide="item.timerRunning" style="padding:5px">
                    {{item.timerTotal| minutes}}
                </span>
                <span ng-show="item.timerRunning" ng-style="timerStyle(item)">
                    {{item.timerTotal| minutes}}
                </span>
          </td>
        </tr>
      </table>
    </div>
    </div>

</div>

<div ng-show="displayMode=='General'">

      <div ng-hide="editMeetingDesc">
        <table class="table">
          <col width="130px">
          <col width="20px">
          <col width="*">
          <tr>
            <td ng-click="editMeetingPart='name'">Name:</td>
            <td class="invisibleButton" ng-click="editMeetingPart='name'">
              <i class="fa fa-edit"></i>
            </td>
            <td ng-hide="'name'==editMeetingPart" ng-click="editMeetingPart='name'">
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
            <td ng-click="editMeetingPart='startTime'">Scheduled Time:</td>
            <td class="invisibleButton" ng-click="editMeetingPart='startTime'">
              <i class="fa fa-edit"></i>
            </td>
            <td ng-hide="'startTime'==editMeetingPart" ng-click="editMeetingPart='startTime'">
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
            <td ng-click="editMeetingPart='duration'">Duration:</td>
            <td class="invisibleButton" ng-click="editMeetingPart='duration'">
              <i class="fa fa-edit"></i>
            </td>
            <td ng-hide="'duration'==editMeetingPart" ng-click="editMeetingPart='duration'">
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
            <td ng-click="editMeetingPart='reminderTime'">Reminder:</td>
            <td class="invisibleButton" ng-click="editMeetingPart='reminderTime'">
              <i class="fa fa-edit"></i>
            </td>
            <td ng-hide="'reminderTime'==editMeetingPart" ng-click="editMeetingPart='reminderTime'">
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
            <td ng-click="editMeetingPart='notifyLayout'">Agenda Layout:</td>
            <td class="invisibleButton" ng-click="editMeetingPart='notifyLayout'">
              <i class="fa fa-edit"></i>
            </td>
            <td ng-hide="'notifyLayout'==editMeetingPart" ng-click="editMeetingPart='notifyLayout'">
              {{meeting.notifyLayout}} 
            </td>
            <td ng-show="'notifyLayout'==editMeetingPart">
              <div class="well form-inline form-group" style="max-width:400px">
                <select class="form-control"  ng-model="meeting.notifyLayout" ng-options="n for n in allLayoutNames"></select>
                <button class="btn btn-primary btn-raised" ng-click="savePendingEdits()">Save</button>
              </div>
            </td>
          </tr>
          <tr>
            <td ng-click="editMeetingPart='defaultLayout'">Minutes Layout:</td>
            <td class="invisibleButton" ng-click="editMeetingPart='defaultLayout'">
              <i class="fa fa-edit"></i>
            </td>
            <td ng-hide="'defaultLayout'==editMeetingPart" ng-click="editMeetingPart='defaultLayout'">
              {{meeting.defaultLayout}} 
            </td>
            <td ng-show="'defaultLayout'==editMeetingPart">
              <div class="well form-inline form-group" style="max-width:400px">
                <select class="form-control"  ng-model="meeting.defaultLayout" ng-options="n for n in allLayoutNames"></select>
                <button class="btn btn-primary btn-raised" ng-click="savePendingEdits()">Save</button>
              </div>
            </td>
          </tr>
          <tr>
            <td ng-click="editMeetingPart='targetRole'">Target Role:</td>
            <td class="invisibleButton" ng-click="editMeetingPart='targetRole'">
              <i class="fa fa-edit"></i>
            </td>
            <td ng-hide="'targetRole'==editMeetingPart" ng-click="editMeetingPart='targetRole'">
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
            <td ng-click="editMeetingPart='participants'">Participants:</td>
            <td class="invisibleButton" ng-click="editMeetingPart='participants'">
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
            <td ng-click="editMeetingDesc=true">Description:</td>
            <td class="invisibleButton" ng-click="editMeetingDesc=true">
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
              <a href="meetingFull.htm?id={{previousMeeting.id}}">
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

</div>
    
<!-- Here is the voting for proposed time section -->
    
    
<div ng-show="displayMode=='Times'">


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

<div ng-show="displayMode=='Attendance'">

<!-- THIS IS THE ROLL CALL SECTION -->

    <div class="well" title="Use this to let others know whether you expect to attend the meeting or not">
      <div><h3 style="margin:5px"><% ar.writeHtml(currentUserName); %>, will you attend?</h3></div>
        <div class="form-inline form-group">
            <select ng-model="mySitch.attend" class="form-control">
                <option>Unknown</option>
                <option>Yes</option>
                <option>Maybe</option>
                <option>No</option>
            </select>
            Details:
            <input type="text" ng-model="mySitch.situation" class="form-control" style="width:400px;"
                   placeholder="Enter a clarification of whether you will attend">
            <button class="btn btn-primary btn-raised" ng-click="saveSituation()">Save</button>
        </div>
    </div>





    <div style="max-width:800px">
      <table class="table">
      <tr>
          <th>Name</th>
          <th>Attended</th>
          <th>Expected</th>
          <th>Situation</th>
      </tr>
      <tr class="comment-inner" ng-repeat="pers in peopleStatus">
          <td>{{pers.name}}</td>
          <td ng-click="toggleAttend(pers.uid)">
            <span ng-show="didAttend(pers.uid)" style="color:green"><span class="fa fa-plus-circle"></span></span>
            <span ng-hide="didAttend(pers.uid)" style="color:#eeeeee"><span class="fa fa-question-circle"></span></span>
          </td>
          <td>{{pers.attend}}</td>
          <td>{{pers.situation}}</td>
      </tr>
      </table>
    </div>


</div>    
    


<div ng-show="displayMode=='Items'">

<table width="100%"><tr>
<td style="width:150px;border-right:4px black solid;vertical-align: top;">
<div ng-repeat="item in getAgendaItems()">
    <div ng-class="item.position==selectedItem.position?'agendaTitleSelected':'agendaTitle'" ng-click="setSelectedItem(item)">
        <span ng-show="item.proposed || item.isSpacer" >--.</span>
        <span ng-show="!item.proposed && !item.isSpacer" >{{item.number}}.</span>
        {{item.subject}} 
    </div>
</div>
<%if (isLoggedIn) { %>
    <hr/>
    <div style="margin:20px;" ng-show="meeting.state<3">
        <button ng-click="createAgendaItem()" class="btn btn-primary btn-raised">+ New</button>
    </div>

<% } %>
</td>
<td ng-repeat="item in [selectedItem]" style="vertical-align: top;">
    <table class="table">
    <col width="150">
    <tr>
      <td></td>
      <td>
          <button ng-click="toggleSpacer(selectedItem)" class="btn btn-primary btn-raised">
              <i class="fa fa-check-circle" ng-show="selectedItem.isSpacer"></i> 
              <i class="fa fa-circle-o" ng-hide="selectedItem.isSpacer"></i> Break Time</button>
          <button ng-click="moveItem(selectedItem,-1)" class="btn btn-primary btn-raised">
              <i class="fa fa-arrow-up"></i>Move Up</a></li></button>
          <button ng-click="moveItem(selectedItem,1)" class="btn btn-primary btn-raised">
              <i class="fa fa-arrow-down"></i>Move Down</a></li></button>
      </td>
    </tr>
    <tr  ng-click="openAgenda(selectedItem)">
      <td>Subject:</td>
      <td>{{selectedItem.subject}}</td>
    </tr>
    <tr  ng-click="openAgenda(selectedItem)" ng-hide="selectedItem.isSpacer">
      <td>Description:</td>
      <td><div ng-bind-html="selectedItem.desc"></div></td>
    </tr>
    <tr  ng-click="openAgenda(selectedItem)" ng-hide="selectedItem.isSpacer">
      <td>Presenter:</td>
      <td><div ng-repeat="pres in selectedItem.presenterList">{{pres.name}}</div></td>
    </tr>
    <tr  ng-click="openAgenda(selectedItem)">
      <td>Planned:</td>
      <td>{{selectedItem.duration|minutes}}</td>
    </tr>
    <tr  ng-click="openAgenda(selectedItem)">
      <td>Actual:</td>
      <td>{{selectedItem.timerTotal|minutes}}</td>
    </tr>
    <tr ng-click="openAttachTopics(selectedItem)" ng-hide="selectedItem.isSpacer">
      <td>Topic:</td>
      <td>
          <span ng-repeat="topic in itemTopics(selectedItem)" class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
            ng-click="navigateToTopic(selectedItem.topicLink)">
            <i class="fa fa-lightbulb-o" style="font-size:130%"></i> {{topic.subject}}
          </span>
      </td>
    </tr>
    <tr ng-hide="selectedItem.isSpacer">
      <td ng-click="openAttachDocument(selectedItem)">Attachments:</td>
              <td><div ng-repeat="docid in selectedItem.docList track by $index" style="vertical-align: top">
                  <span class="dropdown" title="Access this attachment">
                      <button class="attachDocButton" id="menu1" data-toggle="dropdown">
                      <img src="<%=ar.retPath%>assets/images/iconFile.png"> 
                      </button>
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
                  {{getFullDoc(docid).name}}
              </div>
<%if (isLoggedIn) { %>
              <button class="btn btn-sm btn-primary btn-raised" ng-click="openAttachDocument(selectedItem)"
                  title="Attach a document">
                  ADD </button>
<% } %>
           </td>
        </tr>
    <tr ng-hide="selectedItem.isSpacer">
      <td ng-click="openAttachAction(selectedItem)">Action Items:</td>
      <td><div ng-repeat="goal in itemGoals(selectedItem)">
          <div>
            <img ng-src="<%=ar.retPath%>assets/goalstate/small{{goal.state}}.gif">
            {{goal.synopsis}}
          </div>
          </div>
<%if (isLoggedIn) { %>
              <button class="btn btn-sm btn-primary btn-raised" ng-click="openAttachAction(selectedItem)"
                  title="Attach an action item">
                  ADD </button>
<% } %>
      </td>
    </tr>
    <tr ng-click="toggleReady(selectedItem)"  ng-hide="selectedItem.isSpacer">
      <td>Ready:</td>
      <td>
        <span ng-hide="selectedItem.readyToGo" >
            <img src="<%=ar.retPath%>assets/goalstate/agenda-not-ready.png"
                 title="Indicates that the agenda item does NOT have all of the documents, presentations, and is full prepared for the meeting."
                 style="width:24px;height=24px">
                 Not ready yet.
        </span>
        <span ng-show="selectedItem.readyToGo"  >
            <img src="<%=ar.retPath%>assets/goalstate/agenda-ready-to-go.png"
                 title="Indicates that the agenda item has all of the documents, presentations, and is full prepared for the meeting."
                 style="width:24px;height=24px">
                 Ready to go.
        </span>
      </td>
    </tr>
      <tr ng-hide="selectedItem.isSpacer">
        <td style="width:50px;vertical-align:top;padding:15px;">Notes/Minutes:</td>
        <td>
          <div class="comment-inner" ng-bind-html="selectedItem.minutes"></div>
        </td>
      </tr>
      <tr ng-repeat="cmt in selectedItem.comments"  ng-hide="selectedItem.isSpacer">

          <%@ include file="/spring/jsp/CommentView.jsp"%>

      </tr>
<%if (isLoggedIn) { %>
      <tr  ng-hide="selectedItem.isSpacer">
        <td></td>
        <td>
        <div style="margin:20px;">
            <button ng-click="openCommentCreator(selectedItem, 1)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-comments-o"></i> Comment</button>
            <button ng-click="openCommentCreator(selectedItem, 2)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-star-o"></i> Proposal</button>
            <button ng-click="openCommentCreator(selectedItem, 3)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-question-circle"></i> Round</button>
        </div>
        </td>
      </tr>
<% } %>
    </table>
</td>
</tr></table>






</div>
            
<hr/>


<!-- Here is the voting for future meeting proposed time section -->
    
<div ng-show="displayMode=='Times'">
    
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

</div>


<div ng-show="displayMode=='Agenda'">
    <div class="well">
    <%
    
    ChunkTemplate.streamIt(ar.w, agendaLayoutFile,   meetingJSON, ar.getUserProfile().getCalendar() );         
    
%>
    </div>
    Public Link to this:  <a href="MeetPrint.htm?id=<%=meetId%>&tem=<%=agendaLayout%>&<%=mnm%>"><%ar.writeHtml(mRec.getName());%></a> 
    (available to anonymous users)
</div>
<div ng-show="displayMode=='Minutes'">
    <div class="well">
    <%
    
    ChunkTemplate.streamIt(ar.w, minutesLayoutFile,   meetingJSON, ar.getUserProfile().getCalendar() );         
    
%>
    </div>
    Public Link to this:  <a href="MeetPrint.htm?id=<%=meetId%>&tem=<%=minutesLayout%>&<%=mnm%>"><%ar.writeHtml(mRec.getName());%></a> 
    (available to anonymous users)
</div>



<span>
Anticipated end: {{meeting.startTime + (meeting.agendaDuration*60000) | date: 'HH:mm'}},
</span> 

   
<span ng-show="meeting.state>=2">
 elapsed duration: {{meeting.timerTotal|minutes}},
<button ng-click="stopAgendaRunning()" ng-show="meeting.state==2"><i class="fa fa-clock-o"></i> Stop</button>
</span>

    

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
