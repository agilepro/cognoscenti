<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.MeetingRecord"
%><%@page import="com.purplehillsbooks.weaver.LicenseForUser"
%><%@page import="com.purplehillsbooks.weaver.AccessControl"
%><%@page import="com.purplehillsbooks.weaver.mail.ChunkTemplate"
%><%@page import="com.purplehillsbooks.weaver.MicroProfileMgr"
%><%

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    String mode   = ar.defParam("mode", "Items");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.assertLoggedIn("Meeting page designed for people logged in");
    ar.setPageAccessLevels(ngw);
    
    JSONObject workspaceInfo = ngw.getConfigJSON();
    
    String meetId          = ar.reqParam("id");
    MeetingRecord mRec     = ngw.findMeeting(meetId);

    UserProfile uProf = ar.getUserProfile();
    String userTimeZone = uProf.getTimeZone();
    
    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }
    templateCacheDefeater = "?t="+System.currentTimeMillis();


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
    JSONObject meetingInfo = mRec.getFullJSON(ar, ngw, true);
    
    JSONObject previousMeeting = new JSONObject();
    if (meetingInfo.has("previousMeeting")) {
        String previousId = meetingInfo.getString("previousMeeting");
        if (previousId.length()>0) {
            MeetingRecord previous = ngw.findMeetingOrNull(previousId);
            if (previous!=null) {
                previousMeeting = new JSONObject();
                JSONObject temp = previous.getFullJSON(ar, ngw, true);
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
    
    
    List<File> allLayouts = MeetingRecord.getAllLayouts(ar, ngw);
    JSONArray allLayoutNames = new JSONArray();
    for (File aFile : allLayouts) {
        allLayoutNames.put(aFile.getName());
    }
    
    JSONObject meetingJSON = mRec.getFullJSON(ar, ngw, true);
    String agendaLayout = meetingJSON.optString("notifyLayout", "FullDetail.chtml");
    File agendaLayoutFile = MeetingRecord.findMeetingLayout(ar,ngw,agendaLayout);        
    String minutesLayout = meetingJSON.optString("defaultLayout", "FullDetail.chtml");
    File minutesLayoutFile = MeetingRecord.findMeetingLayout(ar,ngw,minutesLayout);
    String mnm = AccessControl.getAccessMeetParams(ngw, mRec); 

/* PROTOTYPE

    $scope.meeting = {
      "agenda": [
        {
          "aiList": [
            {...},
            {...}
          ],
          "description": "An autocracy vests power in one autocratic.",
          "duration": 14,
          "id": "1695",
          "position": 1,
          "subject": "Approve Advertising Plan"
        },
        {
          "aiList": [],
          "description": "Many new organizational support.",
          "duration": 5,
          "id": "2695",
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
        "description": "Original Contract from the SEC to example",
        "id": "1002",
        "labelMap": {},
        "modifiedtime": 1391185776500,
        "modifieduser": "cparker@example.com",
        "name": "Contract 13-C-0113-example.pdf",
        "public": false,
        "size": 409333,
        "universalid": "CSWSLRBRG@sec-inline-xbrl@0056"
      },

*/


%>

<style>
.labelColumn:hover {
    background-color:#ECB6F9;
    cursor:pointer;
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
embeddedData.retPath   = "<%=ar.retPath%>";
embeddedData.templateCacheDefeater   = "<%=templateCacheDefeater%>";
embeddedData.docSpaceURL = "<%ar.writeJS(docSpaceURL);%>"
embeddedData.siteInfo = <%site.getConfigJSON().write(out,2,2);%>;
embeddedData.allLayoutNames = <%allLayoutNames.write(out,2,4);%>;
embeddedData.mode     = "<%ar.writeJS(mode);%>";
embeddedData.workspaceInfo = <%workspaceInfo.write(out,2,4);%>;



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

    
<div ng-cloak>



<%@include file="ErrorPanel.jsp"%>



    <div class="upRightOptions rightDivContent">
      <button class="btn btn-default btn-raised" type="button" id="menu1" data-toggle="dropdown" style="{{meetingStateStyle(meeting.state)}}" ng-click="displayMode='Status'">
          State: {{meetingStateName()}}</button>
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
              href="meetingFull.htm?id={{meeting.id}}">Show Single Page Display</a></li>
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


<div ng-show="displayMode=='General'">
<%@include file="Meeting_Settings.jsp"%>
</div>


<div ng-show="displayMode=='Attendance'">
<%@include file="Meeting_Participants.jsp"%>
</div>    
    

<div ng-show="displayMode=='Times'">
<%@include file="Meeting_Times.jsp"%>
</div>


<div ng-show="displayMode=='Status'">
<%@include file="Meeting_Overview.jsp"%>
</div>


<div ng-show="displayMode=='Items'">
<%@include file="Meeting_Edit.jsp"%>
</div>




<link rel="stylesheet" type="text/css" href="<%=ar.baseURL%>meets/sharedStyles.css.chtml"/>

<div ng-show="displayMode=='Agenda'">
    Public link to this agenda:  '<a href="MeetPrint.htm?id=<%=meetId%>&tem={{meeting.notifyLayout}}&<%=mnm%>">{{meeting.name}}</a>' 
    (available to anonymous users)
    <div class="well" ng-bind-html="htmlAgenda">
    </div>
</div>
<div ng-show="displayMode=='Minutes'">
    Public link to these minutes:  '<a href="MeetPrint.htm?id=<%=meetId%>&tem={{meeting.defaultLayout}}&<%=mnm%>">
    {{meeting.name}}</a>' 
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
<script src="<%=ar.retPath%>templates/AttachDocumentCtrl.js"></script>
<script src="<%=ar.retPath%>templates/AttachTopicCtrl.js"></script>
<script src="<%=ar.retPath%>templates/AttachActionCtrl.js"></script>
<script src="<%=ar.retPath%>templates/AgendaCtrl.js"></script>
<script src="<%=ar.retPath%>templates/MeetingNotes.js"></script>
<script src="<%=ar.retPath%>jscript/HtmlToMarkdown.js"></script>
<script src="<%=ar.retPath%>jscript/HtmlParser.js"></script>
<script src="<%=ar.baseURL%>jscript/TextMerger.js"></script>

