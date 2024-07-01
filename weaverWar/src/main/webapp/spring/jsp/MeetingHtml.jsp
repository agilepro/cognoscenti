<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.MeetingRecord"
%><%@page import="com.purplehillsbooks.weaver.LicenseForUser"
%><%@page import="com.purplehillsbooks.weaver.AccessControl"
%><%@page import="com.purplehillsbooks.weaver.mail.ChunkTemplate"
%><%@page import="com.purplehillsbooks.weaver.MicroProfileMgr"
%><%

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    String mode   = ar.defParam("mode", "Settings");
    ar.assertLoggedIn("Meeting page designed for people logged in");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
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
          "actionItems": [
            "BKLQHEHWG@clone-c-of-clone-4@8005",
            "HFCKCQHWG@clone-c-of-clone-4@0353"
          ],
          "description": "An autocracy vests power in one autocratic.",
          "docList": [
            "VKSSSCSRG@sec-inline-xbrl@4841",
            "HGYDQWIWG@clone-c-of-clone-4@9358"
          ],
          "duration": 14,
          "id": "1695",
          "position": 1,
          "subject": "Approve Advertising Plan"
        },
        {
          "actionItems": [],
          "description": "Many new organizational support.",
          "docList": [],
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
embeddedData.canUpdate = <%=canUpdate%>;

</script>
<script>
    function toggleAccordion(event) {
    var currentItem = event.currentTarget.parentElement;
    var accordion = currentItem.parentElement;
    var items = accordion.getElementsByClassName('accordion-item');
  
    // Close all accordion items
    for (var i = 0; i < items.length; i++) {
      items[i].classList.remove('active');
      items[i].querySelector('.accordion-content').style.display = 'none';
    }
  
    // Open the clicked accordion item
    currentItem.classList.add('active');
    currentItem.querySelector('.accordion-content').style.display = 'block';
  }
  </script>

<script src="../../../spring/jsp/MeetingHtml.js"></script>




    
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>
<!-- heading row with mode selection -->
<div class="row col-12 m-2">
    <div class="d-flex">
        <div class="page-name ps-5 bold primary-60">
            <h1 class="h3-bold mb-0" id="mainPageTitle">Untitled Page</h1>
        </div>
    </div>
</div><!--end heading row with mode selection -->

<div class="container-fluid">

        <div class="row">
            <div class="col-12 col-md-auto fixed-width border-end border-1 border-secondary"><!--Meeting Setting Panel-->
<!--Setup Accordion-->
                <div class="accordion" id="accordionSetup">
    <div class="accordion-item">
        <div class="accordion-header" id="headingOne">
            <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseOne" aria-expanded="false" aria-controls="collapseOne">
                <h3 class="h5 mb-0">Setup Tools</h3>
            </button>
        </div>
        <div id="collapseOne" class="accordion-collapse collapse" aria-labelledby="headingOne" data-bs-parent="#accordionSetup">
            <div class="accordion-body">
                <div class="justify-content-between"> 
                    <span class="btn btn-setup btn-flex">
                    <button ng-click="changeMeetingMode('General')"  ng-class="labelButtonClass('General')" >Settings</button></span>
                    <span class="btn btn-setup btn-flex">
                    <button ng-click="changeMeetingMode('Attendance')" ng-class="labelButtonClass('Attendance')" >Participants</button></span>
                    <span class="btn btn-setup btn-flex">
                    <button ng-click="changeMeetingMode('Facilitate')" ng-class="labelButtonClass('Facilitate')" >Note Taker</button></span>
                </div>
            </div>
        </div>
    </div>
                </div>
<hr/>
<!--Agenda Panel-->
                <div style="height: 0.5rem">&nbsp;</div>
                <h3 class="h5 mb-0">Agenda:</h3>
                <div ng-repeat="item in getAgendaItems()">
                    <div ng-style="itemTabStyleComplete(item)" ng-click="changeMeetingMode('Items');setSelectedItem(item)" ng-hide="item.proposed" ng-dblclick="openAgenda(selectedItem)">
                        <div class="d-flex justify-content-start">
                            <span ng-show="item.proposed" style="color:grey">SHOULD NEVER SHOW THIS</span>
                            <span ng-show="item.isSpacer" style="color:grey">Break</span>
                            <span ng-show="!item.proposed && !item.isSpacer" >{{item.number}}. &nbsp;</span>
        <br/>
                            <button ng-class="labelButtonClass('Items', item)"  >{{item.subject}}</button>
                            <span style="ms-auto" ng-hide="item.proposed">{{item.schedule | date: 'HH:mm'}} &nbsp;</span>
                        </div>
                    </div>
                </div>
<hr/>
                <div class="d-flex justify-content-start">
                    <h3 class="h6">Proposed End Time:</h3>
                    <span class="h6 ms-5">{{meeting.startTime + (meeting.agendaDuration*60000) | date: 'HH:mm'}} &nbsp;</span>
                </div>
                <div style="height:0.5rem">&nbsp;</div>

                <div class="d-flex justify-content-start text-weaverlight"><h3 class="h6 mb-0 me-4">Anticipated End:</h3> 
                    <span class="h6 ms-5">{{meeting.startTime + (meeting.agendaDuration*60000) | date: 'HH:mm'}} &nbsp;
                    </span> 
                </div>

                <div ng-repeat="item in getAgendaItems()">
                    <div ng-style="itemTabStyleComplete(item)" ng-click="changeMeetingMode('Items');setSelectedItem(item)" ng-show="item.proposed"
         ng-dblclick="openAgenda(selectedItem)">
        <span ng-show="item.proposed">Proposed</span>
        <button ng-class="labelButtonClass('Items', item)"  >{{item.subject}}</button>
                    </div>
                </div>
<hr/>
                <div class="d-flex justify-content-center m-2" ng-show="meeting.state<3">
                    <button ng-click="createAgendaItem()" class="btn btn-primary btn-raised" data-bs-target="#agendaItem" data-bs-toggle="modal">+ New</button>
                </div> <!--END OF Agenda Panel-->
                
<!--Static Display buttons-->
<!--Agenda and Minutes buttons start - relocate to  -->
                <h3 class="h5 mt-4 mb-2">Static Displays:</h3>
                <div class="my-3 d-flex justify-content-start">
                <div class="smallButton mx-3">
                    <button ng-click="changeMeetingMode('Agenda')"       ng-class="btn-small" ><img src="<%=ar.retPath%>\assets\navicon\agendaIcon.png"></br> Agenda
                    </button>
                </div>
                <div class="smallButton mx-3">
                    <button ng-click="changeMeetingMode('Minutes')"  ng-class="btn-small"> <img src="<%=ar.retPath%>\assets\navicon\minutesIcon.png"></br> Minutes
                    </button>
                </div>

                </div>
<!--Preparation Status Row-->
    <div class="d-flex col-12 mt-5">
        <div ng-dblclick="item.readyToGo = ! item.readyToGo"  ng-hide="item.isSpacer">
        <div class="labelColumn" ng-click="item.readyToGo = ! item.readyToGo">Ready:</div>
        <span ng-hide="item.readyToGo" >
            <img src="<%=ar.retPath%>assets/goalstate/agenda-not-ready.png"
                 title="Indicates that the agenda item does NOT have all of the documents, presentations, and is full prepared for the meeting."
                 style="width:24px;height=24px">
                 Not ready yet.
        </span>
        <span ng-show="item.readyToGo"  >
            <img src="<%=ar.retPath%>assets/goalstate/agenda-ready-to-go.png"
                 title="Indicates that the agenda item has all of the documents, presentations, and is full prepared for the meeting.">
                 Ready to go.  Presentation attached (if any).
        </span>
        </div>

        <span  ng-dblclick="openAgenda(item)" ng-hide="item.proposed">
            <button ng-click="toggleProposed(item)" class="btn btn-primary btn-raised" ng-show="item.proposed">
              <a><i class="fa fa-check"></i> Accept Proposed Item</a></button>
          <!--<div ng-click="openAgenda(item)" class="labelColumn">Proposed Item</div>
          <span>{{item.status}}</span>
          <div ng-style="timerStyleComplete(item)"> This item is proposed, and not accepted yet. </div>-->
        </span>
        
    </div>
  </div><!--END Preparation Status Row-->
           
<!--Agenda and Minutes buttons end bottom of left column-->

            <div class="d-flex col-9"><div class="contentColumn">

<!-- ============================================================================================== -->

<div ng-show="displayMode=='Agenda'">Public link to this agenda:  '<a href="MeetPrint.htm?id=<%=meetId%>&tem={{meeting.notifyLayout}}&<%=mnm%>">{{meeting.name}}</a>' 
    (available to anonymous users)
                        <div ng-bind-html="htmlAgenda"></div>
                </div>
                <div ng-show="displayMode=='Minutes'">Public link to these minutes:  '<a href="MeetPrint.htm?id=<%=meetId%>&tem={{meeting.defaultLayout}}&<%=mnm%>">{{meeting.name}}</a>' 
    (available to anonymous users)
                        <div ng-bind-html="htmlMinutes"> </div>
                </div>

<div ng-show="displayMode=='Attendance'">
    <%@include file="Meeting_Participants.jsp"%>
</div>    

<div ng-show="displayMode=='Facilitate'">
        <%@include file="Meeting_Facilitate.jsp"%>
</div>

<div ng-show="displayMode=='Items'">
    <div ng-repeat="item in [selectedItem]">
            <%@include file="Meeting_Edit.jsp"%>
    </div>
</div>
<div ng-show="displayMode=='General'">
    <%@include file="Meeting_Settings.jsp"%>
    <%@include file="Meeting_Overview.jsp"%>
    <%@include file="Meeting_Times.jsp"%>
</div>







</div>
<!-- ============================================================================================== -->



<link rel="stylesheet" type="text/css" href="<%=ar.baseURL%>meets/sharedStyles.css.chtml"/>

                <div ng-show="meeting.agenda.length==0" class="guideVocal">This meeting does not have any agenda items.<br/> Use the <button class="btn btn-sm btn-primary btn-raised" ng-click="createAgendaItem()">+ NEW</button> button in the left column to create an agenda item.
                </div>
            


   
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
        </div>
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

