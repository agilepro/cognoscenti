<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%@page import="org.socialbiz.cog.LicenseForUser"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%

    String pageId      = ar.reqParam("pageId");
    NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngw);
    String meetId          = ar.reqParam("id");
    MeetingRecord mRec     = ngw.findMeeting(meetId);

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
    UserProfile uProf = ar.getUserProfile();
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
    for (TopicRecord aNote : ngw.getAllNotes()) {
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
</style>

<script>
var embeddedData = {};
embeddedData.pageId    = "<%ar.writeJS(pageId);%>";
embeddedData.meetId    = "<%ar.writeJS(meetId);%>";
embeddedData.meeting   = <%meetingInfo.write(out,2,2);%>;
embeddedData.previousMeeting = <%previousMeeting.write(out,2,2);%>;
embeddedData.allGoals  = <%allGoals.write(out,2,2);%>;
embeddedData.allRoles  = <%allRoles.write(out,2,2);%>;
embeddedData.allLabels = <%allLabels.write(out,2,2);%>;
embeddedData.backlogId = "<%=backlog.getId()%>";
embeddedData.retPath   = "<%=ar.retPath%>";
embeddedData.templateCacheDefeater   = "<%=templateCacheDefeater%>";
embeddedData.docSpaceURL = "<%ar.writeJS(docSpaceURL);%>"
embeddedData.siteInfo = <%site.getConfigJSON().write(out,2,2);%>;

</script>
<script src="../../../spring/jsp/MeetingFull.js"></script>

<script src="../../../jscript/AllPeople.js"></script>

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

</style>

<div ng-app="myApp" ng-controller="myCtrl" ng-cloak>

<%@include file="ErrorPanel.jsp"%>


<%if (isLoggedIn) { %>
    <div class="upRightOptions rightDivContent">
      <span class="dropdown" title="Control the way people see this meeting.">
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
              title="Create a new agenda item at the bottom of the meeting"
              href="#" ng-click="createAgendaItem()" >Create Agenda Item</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              title="A special view mode to sort and arrange the agenda items more easily"
              href="meeting.htm?id={{meeting.id}}" >Arrange Agenda</a></li>
          <li role="presentation"><a role="menuitem"
              title="Compose an email messsage about this meeting and send it"
              href="sendNote.htm?meet={{meeting.id}}">Send Email about Meeting</a></li>
          <li role="presentation"><a role="menuitem"
              title="Display the meeting as a HTML page that can be copied into an editor"
              href="meetingHtml.htm?id={{meeting.id}}">Show Flat Display</a></li>
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
              href="cloneMeeting.htm?id={{meeting.id}}">Clone Meeting</a></li>
          <li role="presentation"><a role="menuitem"
              title="Return back to the list of all meetings in the workspace"
              href="meetingList.htm">List All Meetings</a></li>
        </ul>
      </span>

    </div>
<% } %>

    <div style="width:100%">
      <div class="leafContent">
        <span style="font-size:150%;font-weight: bold;">
            <i class="fa fa-gavel" style="font-size:130%"></i>
            {{meeting.name}}
        </span>
      </div>
      <br/>
      <div ng-hide="editMeetingInfo || editMeetingDesc">
        <table class="table">
          <col width="130px">
          <col width="20px">
          <col width="*">
          <tr>
            <td>Name:</td>
            <td>
              <i class="fa fa-edit" ng-click="editMeetingInfo=true"></i>
            </td>
            <td>
              <b>{{meeting.name}}</a>
            </td>
          </tr>
          <tr>
            <td>Scheduled Time:</td>
            <td>
              <i class="fa fa-edit" ng-click="editMeetingInfo=true"></i>
            </td>
            <td>
              {{meeting.startTime|date: "dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm  '&nbsp;  GMT'Z"}}
              &nbsp; &nbsp;
              <a href="meetingTime{{meeting.id}}.ics" title="Make a calendar entry for this meeting">
                  <i class="fa fa-calendar"></i></a> &nbsp; 
              <span ng-click="getTimeZoneList()"><i class="fa fa-eye"></i> Timezones</span><br/>
              <span ng-repeat="val in allDates">{{val}}<br/></span>
            </td>
          </tr>
          <tr>
            <td>Reminder:</td>
            <td>
              <i class="fa fa-edit" ng-click="editMeetingInfo=true"></i>
            </td>
            <td>
              {{factoredTime}} {{timeFactor}} before the meeting. 
                <span ng-show="meeting.reminderSent<=0"> <i>Not sent.</i></span>
                <span ng-show="meeting.reminderSent>100"> Was sent {{meeting.reminderSent|date:'dd-MMM-yyyy H:mm'}}
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
            <td>Target Role:</td>
            <td>
              <i class="fa fa-edit" ng-click="editMeetingInfo=true"></i>
            </td>
            <td>
              <a href="roleManagement.htm">{{meeting.targetRole}}</a>
            </td>
          </tr>
          <tr>
            <td>Description:</td>
            <td>
              <i class="fa fa-edit" ng-click="editMeetingDesc=true"></i>
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
                {{previousMeeting.startTime|date: "dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm  '&nbsp;  GMT'Z"}}</a>
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
                <span ng-repeat="person in getAttended()">{{person.name}}, </span>
            </td>
          </tr>
          <tr><td></td><td></td><td></td>
          </tr>
        </table>
      </div>
      <div class="well" ng-show="editMeetingInfo">
        <table class="spaceyTable">
            <tr id="trspath">
                <td>Type:</td>
                <td colspan="2" class="form-inline form-group">
                    <input type="radio" ng-model="meeting.meetingType" value="1"
                        class="form-control" /> Circle Meeting   &nbsp;
                    <input type="radio" ng-model="meeting.meetingType" value="2"
                        class="form-control" /> Operational Meeting
                </td>
            </tr>
            <tr>
                <td>Name:</td>
                <td colspan="2"><input ng-model="meeting.name"  class="form-control"></td>
            </tr>
            <tr>
                <td>Date & Time:</td>
                <td class="dropdown">
                <div style="position:relative">
                  <span datetime-picker ng-model="meeting.startTime" class="form-control" >
                      {{meeting.startTime|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm  '&nbsp;  GMT'Z"}}
                  </span> 
                </div>
                </td> 
            </tr>
            <tr>
                <td>Duration:</td>
                <td colspan="2" class="form-inline form-group">
                    <input ng-model="meeting.duration" style="width:60px;"  class="form-control" >
                    Minutes ({{meeting.totalDuration}} currently allocated)
                </td>
            </tr>
            <tr>
                <td>Send Reminder:</td>
                <td colspan="2" class="form-inline form-group">
                    <input ng-model="factoredTime" style="width:60px;"  class="form-control" >
                    <select ng-model="timeFactor" class="form-control">
                        <option>Minutes</option>
                        <option>Days</option>
                        </select>
                    before the meeting, ({{meeting.reminderTime}} minutes)
                </td>
            </tr>
            <tr>
                <td></td>
                <td colspan="2" class="form-inline form-group">
                    {{meeting.startTime-(meeting.reminderTime*60000)|date:'dd-MMM-yyyy H:mm'}}
                </td>
            </tr>
            <tr>
                <td>Reminder:</td>
                <td colspan="2" class="form-inline form-group">
                    <span ng-show="meeting.reminderSent==0"> <i>Not yet sent.</i></span>
                    <span ng-show="meeting.reminderSent>100"> Was sent {{meeting.reminderSent|date:'dd-MMM-yyyy H:mm'}}
                    </span>
                </td>
            </tr>
            <tr>
                <td>Target Role:</td>
                <td colspan="2" class="form-inline form-group">
                    <select class="form-control" ng-model="meeting.targetRole" ng-options="value for value in allRoles"></select>
                </td>
            </tr>
            <tr>
                <td></td>
                <td colspan="2" class="form-inline form-group">
                    <button ng-click="savePendingEdits()" class="btn btn-primary btn-raised">Save</button>
                    <button ng-click="revertAllEdits()" class="btn btn-warning btn-raised">Cancel</button>
                </td>
            </tr>


          </table>
       </div>
    </div>
    <div ng-show="editMeetingDesc" style="width:100%">
        <div class="well leafContent">
            <div ui-tinymce="tinymceOptions" ng-model="meeting.meetingInfo"
                 class="leafContent" style="min-height:200px;" ></div>
            <button ng-click="savePendingEdits()" class="btn btn-primary btn-raised">Save</button>
            <button ng-click="revertAllEdits()" class="btn btn-warning btn-raised">Cancel</button>
        </div>
    </div>

<!-- THIS IS THE ROLL CALL SECTION -->

    <div ng-repeat="sitch in mySitch" class="comment-outer" style="margin:40px" ng-show="showSelfRegister()"
         title="Use this to let others know whether you expect to attend the meeting or not">
      <div><h3 style="margin:5px"><% ar.writeHtml(currentUserName); %>, will you attend?</h3></div>
      <div class="comment-inner">
        <div class="form-inline form-group" style="margin:20px">
            <select ng-model="sitch.attend" class="form-control">
                <option>Unknown</option>
                <option>Yes</option>
                <option>Maybe</option>
                <option>No</option>
            </select>
            Details:
            <input type="text" ng-model="sitch.situation" class="form-control" style="width:400px;">
            <button class="btn btn-primary btn-raised" ng-click="saveSituation()">Save</button>
        </div>

      </div>
    </div>


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

<%if (!isLoggedIn) { %>
    <div class="leafContent">
        Log in to see more details about this meeting.
    </div>
<% } %>


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

Total Elapsed Time: {{meeting.timerTotal|minutes}}  <button ng-click="stopAgendaRunning()">Stop Timer</button>

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
                    {{item.number}}.
                    <i ng-show="item.topicLink" class="fa fa-lightbulb-o"></i>
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
                      <li role="presentation">
                          <a role="menuitem" ng-click="moveItem(item,-1)"><i class="fa fa-arrow-up"></i>
                             Move Up</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="moveItem(item,1)"><i class="fa fa-arrow-down"></i>
                             Move Down</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="moveItemToBacklog(item)"><i class="fa fa-trash"></i>
                              Remove Item</a></li>

                   </ul>
                </span>
                <span ng-show="meeting.state==2">
                    <span ng-hide="item.timerRunning" style="padding:5px">
                        <button ng-click="agendaStartButton(item)">Start</button>
                        Elapsed: {{item.timerTotal| minutes}}
                        Remaining: {{item.duration - item.timerTotal| minutes}}
                    </span>
                    <span ng-show="item.timerRunning" style="background-color:darkred;color:white;padding:5px">
                        <span>Running</span>
                        Elapsed: {{item.timerTotal| minutes}}
                        Remaining: {{item.duration - item.timerTotal| minutes}}
                    </span>
                </span>
                <span style="float:right" ng-hide="item.readyToGo || isCompleted()" >
                    <img src="<%=ar.retPath%>assets/goalstate/agenda-not-ready.png"
                         ng-click="toggleReady(item)"
                         title="Indicates that the agenda item does NOT have all of the documents, presentations, and is full prepared for the meeting."
                         style="width:24px;height=24px;float:right">
                </span>
                <span style="float:right" ng-show="item.readyToGo && !isCompleted()"  >
                    <img src="<%=ar.retPath%>assets/goalstate/agenda-ready-to-go.png"
                         ng-click="toggleReady(item)"
                         title="Indicates that the agenda item has all of the documents, presentations, and is full prepared for the meeting."
                         style="width:24px;height=24px">
                </span>
                <span style="float:right;margin-right:10px" ng-show="!isCompleted()"  ng-click="moveItem(item,-1)" title="Move agenda item up if possible">
                    <i class="fa fa-arrow-up"></i>
                </span>
                <span style="float:right;margin-right:10px" ng-show="!isCompleted()"  ng-click="moveItem(item,1)" title="Move agenda item down if possible">
                    <i class="fa fa-arrow-down"></i>
                </span>
<% } %>
            </div>
            <div>
                <i ng-click="startItemDetailEdit(item)">
                {{item.schedule | date: 'HH:mm'}} ({{item.duration}} minutes)<span ng-repeat="pres in item.presenterList">, {{pres.name}}</span></i>
            </div>
          </div>
        </td>
      </tr>

                          <!--  AGENDA BODY -->
      <tr ng-show="showItemMap[item.id]">
        <td ng-hide="editItemDescMap[item.id] && myUserId == item.lockUser.uid" style="width:100%">
           <button ng-show="item.lockUser.uid && item.lockUser.uid.length>0" class="btn btn-sm" style="background-color:lightyellow;margin-left:20px;">
               {{item.lockUser.name}} is editing.
           </button>
           <div class="leafContent">
             <div ng-bind-html="item.desc"></div>
           </div>
        </td>
        <td ng-show="editItemDescMap[item.id] && myUserId == item.lockUser.uid" style="width:100%">
           <div class="well leafContent">
             <div ng-model="item.desc" ui-tinymce="tinymceOptions"></div>

             <button ng-click="saveEditUnlockDesciption(item)" class="btn btn-primary btn-raised">Save</button>
             <button ng-click="cancelEditUnlockDesciption(item)" class="btn btn-warning btn-raised">Cancel</button>
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
           <div style="margin:10px;">
              <b>Attachments: </b>
              <span ng-repeat="docid in item.docList" class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
                   ng-click="navigateToDoc(docid)">
                      <img src="<%=ar.retPath%>assets/images/iconFile.png"> {{getFullDoc(docid).name}}
              </span>
<%if (isLoggedIn) { %>
              <button class="btn btn-sm btn-primary btn-raised" ng-click="openAttachDocument(item)"
                  title="Attach a document">
                  ADD </button>
<% } %>
           </div>
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
            <button ng-click="openCommentCreator(item, 5)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-file-code-o"></i> Minutes</button>
        </div>
        </td>
      </tr>
<% } %>
    </table>
    </div>

<%if (isLoggedIn) { %>
    <hr/>
    <div style="margin:20px;" ng-show="meeting.state<3">
        <button ng-click="createAgendaItem()" class="btn btn-primary btn-raised">Create New Agenda Item</button>
    </div>


    Refreshed {{refreshCount}} times.   {{refreshStatus}}<br/>

<% } %>


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
