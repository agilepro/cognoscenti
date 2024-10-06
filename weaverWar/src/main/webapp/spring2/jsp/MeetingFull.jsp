<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.MeetingRecord"
%><%@page import="com.purplehillsbooks.weaver.LicenseForUser"
%><%@page import="com.purplehillsbooks.weaver.AccessControl"
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
    if (uProf==null) {
        throw new Exception("Please log in to see this meeting.");
    }     
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
    String currentUser = uProf.getUniversalId();
    String currentUserName = uProf.getName();
    String currentUserKey = uProf.getKey();
    boolean canUpdate = ngw.canUpdateWorkspace(uProf) || ar.isSuperAdmin();

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
        "modifieduser": "cparker@us.example.com",
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

<script src="../../new_assets/jscript/AllPeople.js"></script>

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
embeddedData.canUpdate = <%=canUpdate%>;



</script>
<script src="../../../spring2/jsp/MeetingHtml.js"></script>


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
.bordereddiv {
    margin:15px;
    border: 2px skyblue solid;
    border-radius:15px;
    padding:20px;
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


<%if (true) { %>
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
          State: {{meetingStateName()}} <span class="caret"></span></button>
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
          <li role="presentation"><a role="menuitem"
              title="Compose an email messsage about this meeting and send it"
              href="SendNote.htm?meet={{meeting.id}}&layout={{meeting.defaultLayout}}">Send Email about Meeting</a></li>
          <li role="presentation"><a role="menuitem"
              title="Display the meeting as a HTML page that can be copied into an editor"
              href="MeetingHtml.htm?id={{meeting.id}}">Show Tabbed Meeting Display</a></li>
          <li role="presentation"><a role="menuitem"
              title="Return back to the list of all meetings in the workspace"
              href="MeetingList.htm">List All Meetings</a></li>
        </ul>
      </span>

    </div>
<% } %>


<hr/>
<div class="bordereddiv">
<%@include file="Meeting_Settings.jsp"%>
</div>

<hr/>
<div class="bordereddiv">
<%@include file="Meeting_Participants.jsp"%>
</div>    
    
<hr/>
<div class="bordereddiv">
<%@include file="Meeting_Times.jsp"%>
</div>

<hr/>
<div class="bordereddiv">
<%@include file="Meeting_Overview.jsp"%>
</div>



<div ng-repeat="item in getAgendaItems()">
<hr/>
<div class="bordereddiv">
<%@include file="Meeting_Edit.jsp"%>
</div>
</div>




<link rel="stylesheet" type="text/css" href="<%=ar.baseURL%>meets/sharedStyles.css.chtml"/>

<div class="bordereddiv">
    Public link to this agenda:  '<a href="MeetPrint.htm?id=<%=meetId%>&tem={{meeting.notifyLayout}}&<%=mnm%>">{{meeting.name}}</a>' 
    (available to anonymous users)
    <div class="well" ng-bind-html="htmlAgenda">
    </div>
</div>
<div class="bordereddiv">
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




<script src="<%=ar.retPath%>new_assets/templates/ActionItemCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/AttachDocumentCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/AttachTopicCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/AttachActionCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/AgendaCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/MeetingNotes.js"></script>
<script src="<%=ar.retPath%>new_assets/jscript/HtmlToMarkdown.js"></script>
<script src="<%=ar.retPath%>new_assets/jscript/HtmlParser.js"></script>
<script src="<%=ar.baseURL%>new_assets/jscript/TextMerger.js"></script>
