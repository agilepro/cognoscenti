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
.labelColumn:hover {
    background-color:#ECB6F9;
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
<script src="../../../spring/jsp/MeetingHtml.js"></script>


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
    padding:5px;
    cursor:pointer;
    border: 3px solid white;
    border-right: none;
}
.agendaTitleSelected {
    font-size: 130%;
    padding:5px;
    border: 3px solid black;
    border-right: none;
    cursor:pointer;
}
.agendaTitle:hover {
    font-size: 130%;
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
    border: 5px solid white;
    padding:5px;
}
.buttonSpacerOn {
    border: 5px solid lightgrey;
    padding:5px;
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

<div>

<button ng-click="changeMeetingMode('Agenda')"   ng-class="statusButtonClass('Agenda')"  >Agenda</button>
<button ng-click="changeMeetingMode('Minutes')"  ng-class="statusButtonClass('Minutes')" >Minutes</button>
<button ng-click="changeMeetingMode('General')"  ng-class="statusButtonClass('General')" >Settings</button>
<button ng-click="changeMeetingMode('Attendance')" ng-class="statusButtonClass('Attendance')">Participants</button>
<button ng-click="changeMeetingMode('Times')"    ng-class="statusButtonClass('Times')"   >Start Time</button>
<button ng-click="changeMeetingMode('Status')"   ng-class="statusButtonClass('Status')"  >Overview</button>
<button ng-click="changeMeetingMode('Items')"    ng-class="statusButtonClass('Items')"   >Edit</button>
</div>



<!-- ============================================================================================== -->


<div ng-show="displayMode=='Times'">

    <div class="well">
      <h3>Scheduled Time</h3>
          
      <table class="table">
        <tr>
            <td>{{browserZone}}</td>
            <td>
              <div ng-show="meeting.startTime>0">
                {{meeting.startTime|date: "dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm"}}&nbsp;
                <a href="meetingTime{{meeting.id}}.ics" title="Make a calendar entry for this meeting">
                  <i class="fa fa-calendar"></i></a> &nbsp; 
                <button ng-click="getTimeZoneList()">Show Timezones</button><br/>
                <span ng-repeat="val in allDates">{{val}}<br/></span>
              </div>
              <div ng-hide="meeting.startTime>0">
                <i>( To Be Determined )</i>
              </div>
            </td>
        </tr>
      </table>
      <button ng-hide="'startTime'==editMeetingPart" class="btn btn-primary btn-raised" 
          ng-click="editMeetingPart='startTime'">Edit Start Time</button>
      <div ng-show="'startTime'==editMeetingPart">
        <div class="well" style="max-width:500px">
            <span datetime-picker ng-model="meeting.startTime"
                  class="form-control">
              {{meeting.startTime|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm"}}
            </span>
            <span>&nbsp; ({{browserZone}})</span><br/>
            <button class="btn btn-primary btn-raised" 
                    ng-click="createTime('timeSlots', meeting.startTime);savePendingEdits()">Save</button>
            <button class="btn btn-primary btn-raised" ng-click="meeting.startTime=0;savePendingEdits()">To Be Determined</button>
            <button class="btn btn-warning btn-raised" ng-click="editMeetingPart=null">Cancel</button>
        </div>
      </div>
    </div>

    <hr/>
    <h3>Proposed Times ({{browserZone}})</h3>

    <table class="table">
    <tr>
      <th></th>
      <th>Date and Time</th>
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
                  <a role="menuitem" ng-click="removeTime(time.proposedTime)">
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
    
    
    <div ng-hide="showTimeAdder">
        <button ng-click="showTimeAdder=true" 
                class="btn btn-primary btn-raised">Add Proposed Time</button>
    </div>

    <div ng-show="showTimeAdder" class="well">
        Choose a time: <span datetime-picker ng-model="newProposedTime" class="form-control" style="display:inline">
          {{newProposedTime|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm"}}  
        </span> 
        and then <button ng-click="createTime('timeSlots', newProposedTime)" 
                 class="btn btn-primary btn-raised">Add It</button>
        &nbsp; ({{browserZone}}) &nbsp;
        or <button ng-click="showTimeAdder=false" 
                 class="btn btn-warning btn-raised">Cancel</button>
    </div>
    
</div>

<div ng-show="displayMode=='General'">

      <div ng-hide="editMeetingDesc">
        <table class="table">
          <col width="130px">
          <col width="*">
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
            <td>Called By:</td>
            <td>
              {{meeting.owner}}
            </td>
          </tr>
          <tr>
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
          <tr>
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
          <tr>
            <td ng-click="editMeetingPart='targetRole'" class="labelColumn">Target Role:</td>
            <td ng-hide="'targetRole'==editMeetingPart" ng-dblclick="editMeetingPart='targetRole'">
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
            <td ng-click="editMeetingDesc=true" class="labelColumn">Description:</td>
            <td ng-dblclick="editMeetingDesc=true">
              <div ng-bind-html="meeting.meetingInfo"></div>
              <div ng-hide="meeting.meetingInfo && meeting.meetingInfo.length>6" class="doubleClickHint">
                  Double-click to edit description
              </div>
            </td>
          </tr>
          <tr ng-show="previousMeeting.id">
            <td>Previous Meeting:</td>
            <td>
              <a href="meetingHtml.htm?id={{previousMeeting.id}}">
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








<div ng-show="displayMode=='Status'">
    <div class="well" ng-cloak>
        <table>
        <tr>
        <td>
          <div class="{{meeting.state==0 ? 'buttonSpacerOn' : 'buttonSpacerOff'}}">
            <span class="btn btn-default btn-raised" style="{{meetingStateStyle(0)}}" 
                  ng-click="changeMeetingState(0)">Draft</span>
          </div>
        </td>
        <td>----&gt;</td>
        <td>
          <div class="{{meeting.state==1 ? 'buttonSpacerOn' : 'buttonSpacerOff'}}">
            <span class="btn btn-default btn-raised" style="{{meetingStateStyle(1)}}" 
                  ng-click="changeMeetingState(1)">Planning</span>
          </div>
        </td>
        <td>----&gt;</td>
        <td>
          <div class="{{meeting.state==2 ? 'buttonSpacerOn' : 'buttonSpacerOff'}}">
            <span class="btn btn-default btn-raised" style="{{meetingStateStyle(2)}}" 
                  ng-click="changeMeetingState(2)">Running</span>
          </div>
        </td>
        <td>----&gt;</td>
        <td>
          <div class="{{meeting.state==3 ? 'buttonSpacerOn' : 'buttonSpacerOff'}}">
            <span class="btn btn-default btn-raised" style="{{meetingStateStyle(3)}}" 
                  ng-click="changeMeetingState(3)">Completed</span>
          </div>
        </td>
        </tr>
        </table>
      <div ng-show="meeting.state<=0">
          <p>Meeting is in draft mode and is hidden from the participants.
             Advance the meeting to planning mode to let them know about it
             before the meeting starts.</p>
      </div>
      <div ng-show="meeting.state<=2">
          <p ng-show="meeting.state==1">
          Meeting is in planning mode until the time that the meeting starts.
          </p>
          <p ng-show="meeting.state==2">
          Meeting is in running mode and will allow updates normally done during the meeting.
          </p>
      <table class="table">
        <tr>
          <th></th>
          <th>Start</th>
          <th>Planned Duration</th>
          <th></th>
          <th>Actual Duration</th>
          <th>Remaining</th>
          <th></th>
        </tr>
        <tr ng-repeat="item in getAgendaItems()" ng-style="timerStyleComplete(item)" ng-hide="item.proposed" >
          <td  ng-dblclick="openAgenda(item)">
                <span ng-show="item.isSpacer" >--</span>
                <span ng-hide="item.isSpacer" >{{item.number}}.</span>
                {{item.subject}} 
          </td>
          <td ng-dblclick="openAgenda(item)" >
          <span>{{item.schedule | date: 'HH:mm'}} &nbsp;</span>
          </td>
          <td ng-dblclick="openAgenda(item)" >
                {{item.duration| minutes}}
          </td>
          <td >
                <span ng-hide="meeting.state!=2 || item.proposed || item.timerRunning">
                    <button ng-click="agendaStartButton(item)"><i class="fa fa-clock-o"></i> Start</button>
                </span>
                <span ng-hide="meeting.state!=2 || item.proposed || !item.timerRunning">
                    <button ng-click="stopAgendaRunning()"><i class="fa fa-clock-o"></i> Stop</button>
                </span>
          </td>
          <td ng-dblclick="openAgenda(item)">
                <span ng-show="meeting.state==2">{{item.timerTotal| minutes}}</span>
          </td>
          <td ng-dblclick="openAgenda(item)">
                <span ng-show="meeting.state==2">{{item.duration - item.timerTotal| minutes}}</span>
          </td>
          <td ng-style="timerStyleComplete(item)" >
            <span style="float:right" ng-hide="item.readyToGo || isCompleted()" >
                <img src="<%=ar.retPath%>assets/goalstate/agenda-not-ready.png"
                     ng-dblclick="toggleReady(item)"
                     title="Indicates that the agenda item does NOT have all of the documents, presentations, and is full prepared for the meeting."
                     style="width:24px;height=24px;float:right">
            </span>
            <span style="float:right" ng-show="item.readyToGo && !isCompleted()"  >
                <img src="<%=ar.retPath%>assets/goalstate/agenda-ready-to-go.png"
                     ng-dblclick="toggleReady(item)"
                     title="Indicates that the agenda item has all of the documents, presentations, and is full prepared for the meeting."
                     style="width:24px;height=24px">
            </span>
            <span style="float:right;margin-right:10px" ng-show="!isCompleted()"  ng-click="moveItem(item,-1)" 
                  title="Move agenda item up if possible">
                <i class="fa fa-arrow-up"></i>
            </span>
            <span style="float:right;margin-right:10px" ng-show="!isCompleted()"  ng-click="moveItem(item,1)" 
                  title="Move agenda item down if possible">
                <i class="fa fa-arrow-down"></i>
            </span>
          </td>
        </tr>
        <tr>
            <td></td>
            <td>{{meeting.startTime + (meeting.agendaDuration*60000) | date: 'HH:mm'}}</td>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
        </tr>
        <tr>
            <td><br/><br/><b>Proposed:</b></td>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
        </tr>
        <tr ng-repeat="item in getAgendaItems()" ng-style="timerStyleComplete(item)" ng-show="item.proposed" >
          <td  ng-dblclick="openAgenda(item)">
                <span>--</span>
                {{item.subject}} 
          </td>
          <td>
          </td>
          <td ng-dblclick="openAgenda(item)" >
                {{item.duration| minutes}}
          </td>
          <td ></td>
          <td ng-dblclick="openAgenda(item)"></td>
          <td ng-dblclick="openAgenda(item)"></td>
          <td ng-style="timerStyleComplete(item)" >
            <span style="float:right;margin-right:10px" ng-click="toggleProposed(item)" 
                  title="Accept this proposed agenda item">
               ACCEPT</i>
            </span>
          </td>
        </tr>        
      </table>
      <div style="margin:20px;">
        <button ng-click="createAgendaItem()" class="btn btn-primary btn-raised">+ New Agenda Item</button>
      </div>

      </div>
      <div ng-show="meeting.state>=3">
          <p>Meeting is completed and no more updates are expected.</p>
      <table class="table">
        <tr>
          <td></td>
          <td>Planned Time</td>
          <td>Used Time</td>
        </tr>
        <tr ng-repeat="item in getAgendaItems()" ng-dblclick="openAgenda(item)" ng-style="timerStyleComplete(item)">
          <td>
                <span ng-show="item.proposed || item.isSpacer" >--</span>
                <span ng-hide="item.proposed || item.isSpacer" >{{item.number}}.</span>

                {{item.subject}} 
          </td>
          <td >
                <span >
                    {{item.duration| minutes}}
                </span>
          </td>
          <td >
                <span >
                    {{item.timerTotal| minutes}}
                </span>
          </td>
        </tr>
      </table>
    </div>
    </div>

</div>

   
<!-- Here is the voting for proposed time section -->
    
    


<div ng-show="displayMode=='Attendance'">

<!-- THIS IS THE ROLL CALL SECTION -->

    <div class="well" title="Use this to let others know whether you expect to attend the meeting or not" ng-show="meeting.state==1">
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
      <tr class="comment-inner" ng-repeat="pers in meeting.participants">
          <td>
            <img class="img-circle" 
                 ng-src="<%=ar.retPath%>icon/{{pers.image}}" 
                 style="width:32px;height:32px" 
                 title="{{pers.name}} - {{pers.uid}}"> &nbsp; 
            {{pers.name}}
          </td>
          <td ng-click="toggleAttend(pers.uid)">
            <span ng-show="didAttend(pers.uid)" style="color:green"><span class="fa fa-plus-circle"></span></span>
            <span ng-hide="didAttend(pers.uid)" style="color:#eeeeee"><span class="fa fa-question-circle"></span></span>
          </td>
          <td>{{expectAttend[pers.uid]}}</td>
          <td>{{expectSituation[pers.uid]}}</td>
      </tr>
      </table>
      
      <div ng-hide="editMeetingPart=='participants'">
          <button class="btn btn-default btn-primary btn-raised" type="button" 
                  ng-click="editMeetingPart='participants'"
                  title="Post this topic but don't send any email">
          Adjust Meeting Participants </button>
      </div>
      <div class="well" ng-show="editMeetingPart=='participants'">
          <h2>Adjust Participants:</h2>
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
          <div>
          <span class="dropdown">
              <button class="btn btn-default btn-primary btn-raised" type="button" 
                      ng-click="savePendingEdits()"
                      title="Post this topic but don't send any email">
              Save </button>
              <button class="btn btn-default btn-raised" ng-click="appendRolePlayers()" 
                      ng-hide="roleEqualsParticipants">
                  Add Everyone from {{meeting.targetRole}}
              </button>
          </span>
          </div>
      </div>
      
    </div>


</div>    
    


<div ng-show="displayMode=='Items'">

<table width="100%"><tr>
<td style="width:180px;border-right:4px black solid;vertical-align: top;">
<div ng-repeat="item in getAgendaItems()">
    <div ng-style="itemTabStyleComplete(item)" ng-click="setSelectedItem(item)" ng-hide="item.proposed"
         ng-dblclick="openAgenda(selectedItem)">
        <span ng-show="item.proposed" style="color:grey">Proposed</span>
        <span ng-show="item.isSpacer" style="color:grey">Break</span>
        <span ng-show="!item.proposed && !item.isSpacer" >{{item.number}}.</span>
        <span style="float:right" ng-hide="item.proposed">{{item.schedule | date: 'HH:mm'}} &nbsp;</span>
        <br/>
        {{item.subject}}
    </div>
</div>
<div>
    <span style="float:right">{{meeting.startTime + (meeting.agendaDuration*60000) | date: 'HH:mm'}} &nbsp;</span>
</div>
<div style="height:70px">&nbsp;</div>

<div ng-repeat="item in getAgendaItems()">
    <div ng-style="itemTabStyleComplete(item)" ng-click="setSelectedItem(item)" ng-show="item.proposed"
         ng-dblclick="openAgenda(selectedItem)">
        <span ng-show="item.proposed" style="color:grey">Proposed</span>
        <br/>
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
    <table class="table" ng-show="item">
    <col width="150">
    <tr>
      <td></td>
      <td>
          <button ng-click="toggleSpacer(selectedItem)" class="btn btn-primary btn-raised">
              <i class="fa fa-check-circle" ng-show="selectedItem.isSpacer"></i> 
              <i class="fa fa-circle-o" ng-hide="selectedItem.isSpacer"></i> Break Time</button>
          <button ng-click="moveItem(selectedItem,-1)" class="btn btn-primary btn-raised"
                  ng-hide="selectedItem.proposed">
              <i class="fa fa-arrow-up"></i>Move Up</a></li></button>
          <button ng-click="moveItem(selectedItem,1)" class="btn btn-primary btn-raised"
                  ng-hide="selectedItem.proposed">
              <i class="fa fa-arrow-down"></i>Move Down</a></li></button>
          <button ng-click="toggleProposed(selectedItem)" class="btn btn-primary btn-raised"
                  ng-show="selectedItem.proposed">
              <i class="fa fa-check"></i>Accept Proposed Item</a></li></button>
      </td>
    </tr>
    <tr ng-dblclick="openAgenda(selectedItem)">
      <td ng-click="openAgenda(selectedItem)" class="labelColumn">Subject:</td>
      <td ng-style="timerStyleComplete(item)">{{selectedItem.subject}}</td>
    </tr>
    <tr ng-hide="selectedItem.isSpacer">
      <td class="labelColumn" ng-click="openNotesDialog(selectedItem)">Notes/Minutes:</td>
      <td ng-dblclick="openNotesDialog(selectedItem)">
        <div ng-bind-html="selectedItem.minutes"></div>
        <div ng-hide="selectedItem.minutes" class="doubleClickHint">
            Double-click to edit notes
        </div>
      </td>
    </tr>
    <tr ng-dblclick="openAgenda(selectedItem,'Description')" ng-hide="selectedItem.isSpacer">
      <td ng-click="openAgenda(selectedItem,'Description')" class="labelColumn">Description:</td>
      <td>
        <div ng-bind-html="selectedItem.desc"></div>
        <div ng-hide="selectedItem.desc && selectedItem.desc.length>10" class="doubleClickHint">
            Double-click to description
        </div>
      </td>
    </tr>
    <tr  ng-dblclick="openAgenda(selectedItem)" ng-hide="selectedItem.isSpacer">
      <td ng-click="openAgenda(selectedItem)" class="labelColumn">Presenter:</td>
      <td><div ng-repeat="pres in selectedItem.presenterList">{{pres.name}}</div>
        <div ng-hide="selectedItem.presenterList && selectedItem.presenterList.length>0" class="doubleClickHint">
            Double-click to set presenter
        </div>
      </td>
    </tr>
    <tr ng-dblclick="openAgenda(selectedItem)" ng-hide="item.proposed">
      <td ng-click="openAgenda(selectedItem)" class="labelColumn">Planned:</td>
      <td>{{selectedItem.duration|minutes}} minutes</td>
    </tr>
    <tr ng-dblclick="openAgenda(selectedItem)"  ng-hide="item.proposed">
      <td ng-click="openAgenda(selectedItem)" class="labelColumn">Actual:</td>
      <td ng-style="timerStyleComplete(item)">{{selectedItem.timerTotal|minutes}} minutes &nbsp; &nbsp; 
            <span ng-hide="item.timerRunning">
                <button ng-click="agendaStartButton(item)"><i class="fa fa-clock-o"></i> Start</button>
            </span>
            <span ng-show="item.timerRunning">
                <button ng-click="stopAgendaRunning()"><i class="fa fa-clock-o"></i> Stop</button>
            </span> &nbsp; &nbsp; 
            <span> Remaining: {{item.duration - item.timerTotal| minutes}}</span>
      </td>
    </tr>
    <tr ng-dblclick="openAgenda(selectedItem)" ng-show="item.proposed">
      <td ng-click="openAgenda(selectedItem)" class="labelColumn">Proposed:</td>
      <td ng-style="timerStyleComplete(item)">This item is proposed, and not accepted yet.  
          <button ng-click="toggleProposed(selectedItem)" class="btn btn-primary btn-raised"
                  ng-show="selectedItem.proposed">
              <i class="fa fa-check"></i> Accept Proposed Item</a></button>
      </td>
    </tr>
    <tr ng-dblclick="openAttachTopics(selectedItem)" ng-hide="selectedItem.isSpacer">
      <td ng-click="openAttachTopics(selectedItem)" class="labelColumn">Topic:</td>
      <td>
          <div ng-repeat="topic in itemTopics(selectedItem)" class="btn btn-sm btn-default btn-raised"  
                style="margin:4px;max-width:200px;overflow: hidden"
            ng-click="navigateToTopic(selectedItem.topicLink)">
            <i class="fa fa-lightbulb-o" style="font-size:130%"></i> {{topic.subject}}
          </div>
          <div ng-hide="itemTopics(selectedItem).length>0" class="doubleClickHint">
              Double-click to set or unset linked topic
          </div>
      </td>
    </tr>
    <tr ng-hide="selectedItem.isSpacer" ng-dblclick="openAttachDocument(selectedItem)">
      <td ng-click="openAttachDocument(selectedItem)" class="labelColumn">Attachments:</td>
      <td title="double-click to modify the attachments">
          <div ng-repeat="docid in selectedItem.docList track by $index" style="vertical-align: top">
              <div ng-repeat="fullDoc in [getFullDoc(docid)]">
                  <span ng-click="navigateToDoc(docid)">
                    <img src="<%=ar.retPath%>assets/images/iconFile.png" ng-show="fullDoc.attType=='FILE'">
                    <img src="<%=ar.retPath%>assets/images/iconUrl.png" ng-show="fullDoc.attType=='URL'">
                  </span> &nbsp;
                  <span ng-click="downloadDocument(fullDoc)">
                    <span class="fa fa-external-link" ng-show="fullDoc.attType=='URL'"></span>
                    <span class="fa fa-download" ng-hide="fullDoc.attType=='URL'"></span>
                  </span> &nbsp; 
                  {{fullDoc.name}}
              </div>
          </div>
          <div ng-hide="selectedItem.docList && selectedItem.docList.length>0" class="doubleClickHint">
              Double-click to add / remove attachments
          </div>
       </td>
    </tr>
    <tr ng-hide="selectedItem.isSpacer" ng-dblclick="openAttachAction(selectedItem)">
      <td ng-click="openAttachAction(selectedItem)" class="labelColumn">Action Items:</td>
      <td><div ng-repeat="goal in itemGoals(selectedItem)">
          <div>
            <img ng-src="<%=ar.retPath%>assets/goalstate/small{{goal.state}}.gif">
            {{goal.synopsis}}
          </div>
          </div>
          <div ng-hide="itemGoals(selectedItem).length>0" class="doubleClickHint">
              Double-click to add / remove action items
          </div>
      </td>
    </tr>
    <tr ng-dblclick="selectedItem.readyToGo = ! selectedItem.readyToGo"  ng-hide="selectedItem.isSpacer">
      <td class="labelColumn" ng-click="selectedItem.readyToGo = ! selectedItem.readyToGo">Ready:</td>
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
                 Ready to go.  Presentation attached (if any).
        </span>
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
    <div ng-hind="item">
        <div class="guideVocal">
            Create an agenda item for the meeting use the "+ New" button on the left.
        </div>
    </div>
</td>
</tr></table>






</div>
            




<style>
.emailbody {
    font-family: Arial,Helvetica Neue,Helvetica,sans-serif; 
    border-bottom: 2px solid skyblue;
    padding:5px;
    text-align: center;
}
.niceTable {
    width: 100%;
    max-width:800px;  
}
.niceTable tr td { 
    padding:8px;
    vertical-align: top;   
}
.smallPrint {
    font-size:-2;
}
.docPill {
    padding:3px;
    background-color: #EEEEFF;
    border: solid 1px gray;
    border-radius:5px;
    margin:5px;
}
</style>
<div ng-show="displayMode=='Agenda'">
    Public Link to this:  <a href="MeetPrint.htm?id=<%=meetId%>&tem=<%=agendaLayout%>&<%=mnm%>"><%ar.writeHtml(mRec.getName());%> Agenda</a> 
    (available to anonymous users)
    <div class="well" ng-bind-html="htmlAgenda">
    </div>
</div>
<div ng-show="displayMode=='Minutes'">
    Public Link to this:  <a href="MeetPrint.htm?id=<%=meetId%>&tem=<%=minutesLayout%>&<%=mnm%>"><%ar.writeHtml(mRec.getName());%> Minutes</a> 
    (available to anonymous users)
    <div class="well"> 
    <div ng-bind-html="htmlMinutes"> </div>
    </div>
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
<script src="<%=ar.retPath%>templates/MeetingNotes.js"></script>
