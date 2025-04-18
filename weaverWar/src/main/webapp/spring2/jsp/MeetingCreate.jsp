<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@ include file="/functions.jsp"
%><%@page import="java.util.Calendar"
%><%

    String go = ar.getCompleteURL();
    ar.assertLoggedIn("Must be logged in to see anything about a user");

    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKey(siteId,pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    NGBook site = ngw.getSite();

    JSONObject meetingInfo = null;
    String meetId          = ar.defParam("id", null);
    String pageTitle = "Clone Meeting";
    long proposedStartTime = 0;
    if (meetId == null) {
        pageTitle = "Create Meeting";
        meetingInfo = new JSONObject();
        //make it for top of next hour
        Calendar cal = Calendar.getInstance();
        cal.set(Calendar.MINUTE, 0);
        cal.set(Calendar.SECOND, 0);
        cal.set(Calendar.MILLISECOND, 0);
        cal.roll(Calendar.HOUR_OF_DAY, 1);
        proposedStartTime = cal.getTime().getTime();
        JSONArray newAgenda = new JSONArray();
        
        JSONObject firstItem = new JSONObject();
        firstItem.put("selected", true);
        firstItem.put("subject", "Check In");
        firstItem.put("description", "Go around the circle and get the status from everyone.");
        firstItem.put("duration", 10);
        newAgenda.put(firstItem);
        
        JSONObject secItem = new JSONObject();
        secItem.put("selected", true);
        secItem.put("subject", "Admin");
        secItem.put("description", "Admin:\n* Announcements\n* Accept agenda\n* Review/approve last meeting minutes\n* Next meeting time");
        secItem.put("duration", 10);
        newAgenda.put(secItem);
        
        JSONObject thirdItem = new JSONObject();
        thirdItem.put("selected", true);
        thirdItem.put("subject", "Report:");
        thirdItem.put("description", "Ahead of the meeting, include any report(s) to be given during the meeting.");
        thirdItem.put("duration", 10);
        newAgenda.put(thirdItem);

        JSONObject fourthItem = new JSONObject();
        fourthItem.put("selected", true);
        fourthItem.put("subject", "Discussion:");
        fourthItem.put("description", "Ahead of the meeting, include any exploration(s) to be discussed during the meeting.");
        fourthItem.put("duration", 10);
        newAgenda.put(fourthItem);

        JSONObject fifthItem = new JSONObject();
        fifthItem.put("selected", true);
        fifthItem.put("subject", "Decision:");
        fifthItem.put("description", "Ahead of the meeting, include any decision(s) to be made during the meeting.");
        fifthItem.put("duration", 10);
        newAgenda.put(fifthItem);
        
        JSONObject sixthItem = new JSONObject();
        sixthItem.put("selected", true);
        sixthItem.put("subject", "Closing");
        sixthItem.put("description", "Evaluation of meeting and possible discussions for next meeting.");
        sixthItem.put("duration", 10);
        newAgenda.put(sixthItem);
        
        meetingInfo.put("agenda", newAgenda);
    }
    else {
        MeetingRecord oneRef   = ngw.findMeeting(meetId);
        meetingInfo = oneRef.getFullJSON(ar, ngw, true);
        //make it for 7 days later
        proposedStartTime =  meetingInfo.getLong("startTime") + 7L*24L*3600000;
    }
    //meetingInfo.put("id","~new~");

    meetingInfo.put("startTime", proposedStartTime);
    boolean userReadOnly = ar.isReadOnly(); 
%>


<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("<%=pageTitle%>");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.meeting = <%meetingInfo.write(out,2,4);%>;
    $scope.browserZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    $scope.meeting.descriptionHtml = convertMarkdownToHtml($scope.meeting.description);

    var n = new Date().getTimezoneOffset();
    var tzNeg = n<0;
    if (tzNeg) {
        n = -n;
    }
    var tzHours = Math.floor(n/60);
    var tzMinutes = n - (tzHours*60);
    var tzFiddle = (100 + tzHours)*100 + tzMinutes;
    var txFmt = tzFiddle.toString().substring(1);
    if (tzNeg) {
        txFmt = "+".concat(txFmt);
    }
    else {
        txFmt = "-".concat(txFmt);
    }
    $scope.tzIndicator = txFmt;

    $scope.onTimeSet = function (newDate, secondparam) {
        $scope.meeting.startTime = newDate.getTime();
    }

    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 300;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.sortItems = function() {
        $scope.meeting.agenda.sort( function(a, b){
            return a.position - b.position;
        } );
        return $scope.meeting.agenda;
    }

    $scope.createMeeting = function() {
        if (!$scope.meeting.name) {
            alert("Please enter a name for the meeting");
            return;
        }
        if (!$scope.meeting.descriptionHtml) {
            alert("Please a short description for the meeting");
            return;
        }
        
        var minutesFromNow = Math.floor(($scope.meeting.startTime - (new Date()).getTime()) / 60000);
        if ($scope.meeting.startTime>1000000 && minutesFromNow<0) {
            if (!confirm("Warning: this meeting is being scheduled for time in the past.  An email message will be sent immediately informing people of the meeting before you get a chance to change the date.   If you mean to schedule a meeting for the future, press 'Cancel' and correct the date.   Do you still want to create a meeting for the past?")) {
                return;
            }
        }
        else if ($scope.meeting.startTime>1000000 && $scope.meeting.reminderTime>0 &&
                minutesFromNow < $scope.meeting.reminderTime) {
            if (!confirm("Warning: this meeting is scheduled for "+minutesFromNow+" minutes from now.  An email reminder scheduled to be sent "+$scope.meeting.reminderTime+" minutes before the meeting will be sent immediately.   You should make sure that the information here is ready for that email to be sent.   Is everything ready to create the meeting and send the email?")) {
                return;
            }
        }
        var newMeeting = {};
        newMeeting.state = 0;
        newMeeting.attended = [];
        newMeeting.rollCall = [];
        newMeeting.reminderSent = -1;
        newMeeting.id = "~new~";
        newMeeting.duration = $scope.meeting.duration;
        newMeeting.previousMeeting = $scope.meeting.id;
        newMeeting.description = HTML2Markdown($scope.meeting.descriptionHtml, {});
        newMeeting.name = $scope.meeting.name;
        newMeeting.reminderTime = $scope.meeting.reminderTime;
        newMeeting.startTime = $scope.meeting.startTime;
        newMeeting.targetRole = $scope.meeting.targetRole;
        newMeeting.participants = $scope.meeting.participants;
        newMeeting.defaultLayout = $scope.meeting.defaultLayout;
        newMeeting.notifyLayout = $scope.meeting.notifyLayout;
        newMeeting.agenda = [];
        $scope.meeting.agenda.forEach( function(agendaItem) {
            if (agendaItem.selected) {
                var newAgenda = JSON.parse(JSON.stringify(agendaItem));
                newAgenda.readyToGo = false;
                newAgenda.timerElapsed = 0;
                newAgenda.comments = [];
                newMeeting.agenda.push(newAgenda);
            }
        });
        var postURL = "meetingCreate.json";
        var postdata = angular.toJson(newMeeting);
        //console.log("Structure gor creting meeting", newMeeting);
        //confirm("click OK to create meeting");
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            window.location = "MeetingList.htm";
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.trimDesc = function(item) {
        if (item.description.length > 100) {
            return item.description.substring(0,100);
        }
        return item.description;
    }
});
app.filter('sdate', function() {
    return function(input, fmtString) {
        if (!fmtString) {
            fmtString = "dd-MMM-yyyy"
        }
        if (input<=0) {
            return "(to be determined)";
        }
        return moment(input).format(fmtString);
    };
});

function GetFirstHundredNoHtml(input) {
     var limit = 100;
     var inTag = false;
     var res = "";
     for (var i=0; i<input.length && limit>0; i++) {
         var ch = input.charAt(i);
         if (inTag) {
             if ('>' == ch) {
                 inTag=false;
             }
             //ignore all other characters while in the tag
         }
         else {
             if ('<' == ch) {
                 inTag=true;
             }
             else {
                 res = res + ch;
                 limit--;
             }
         }
     }
     return res;
 }

 

</script>

<div class="container-fluid override mb-4 mx-3 d-inline-flex">
    <span class="dropdown mt-1">
        <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
            data-bs-toggle="dropdown" aria-expanded="false">
        </button>
        <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
            <li>
                <button class="dropdown-item" onclick="window.location.reload(true)">Refresh</button>
            </li>
        </ul>
    </span>
    <span>
        <h1 class="d-inline page-name" id="mainPageTitle"><%=pageTitle%></h1>
    </span>
</div>

<div ng-cloak>

  <%@include file="ErrorPanel.jsp"%>
 
  
<% if (userReadOnly) { %>

<div class="guideVocal" style="margin-top:80px">
    <p>You are not allowed to create a meeting in this workspace, because
    you are an unpaid user.  You can access documents, but you can 
    not add them or update them.</p>
    
    <p>If you wish to add or update meetings, speak to the administrator of this 
    workspace / site and have your membership level changed to an
    active user.</p>
</div>

<% } else if (ngw.isFrozen()) { %>

<div class="guideVocal" style="margin-top:80px">
    <p>You are not able to create a meeting in this workspace, because
    it is frozen.  Frozen workspaces can not be modified: nothing can be added
    or removed, including meetings.</p>
    
    <p>If you wish to add or update meetings, the workspace must be set into the 
    active (unfrozen) state in the workspace admin page.</p>
</div>

<% } else { %>

<div class="container-fluid override col-md-12 ms-4">
    <div class="row shadow-lg p-3">
        <form class="horizontal-form">
            <fieldset>
            <!-- Form Control NAME Begin -->
                <div class="form-group d-flex my-3">
                    <label class="h6 col-1 control-label" title="Choose a name for the meeting that will be suitable for the entire series of meetings.">Meeting Name</label>
                    <div class="col-md-10">
                        <input type="text" class="form-control" ng-model="meeting.name" title="Choose a name for the meeting that will be suitable for the entire series of meetings."/>
                    </div>
                </div>

            <!-- Form Control DATE Begin -->
            <div class="form-group d-flex my-3">
                <label class="col-1 h6 control-label" title="Date and time for the beginning of the meeting in YOUR time zone">
                    Date &amp; Time
                </label>
                <div class="col-md-10" title="Date and time for the beginning of the meeting in YOUR time zone">
                    <span datetime-picker ng-model="meeting.startTime" 
                        class="form-control" style="width:180px">{{meeting.startTime|sdate:"DD-MMM-YYYY &nbsp; HH:mm"}}
                    </span> 
                    <span style="padding:10px">{{browserZone}}</span>
                    <button ng-click="meeting.startTime=0" class="btn btn-comment btn-raised">Clear</button>
                </div>
                
            </div>
            <!-- Form Control DESCRIPTION Begin -->
                <div class="form-group d-flex my-3">
                    <label class="col-1 h6 control-label">
                        Description
                    </label>
                    <div class="col-md-10">
                        <textarea ui-tinymce="tinymceOptions" ng-model="meeting.descriptionHtml" class="leafContent form-control" style="min-height:200px;"></textarea>
                    </div>
                </div>
            </fieldset>
          <div ng-show="meeting.agenda.length>0">
              <!-- Table MEETING AGENDA ITEMS Begin -->
              <div class="container-fluid col-11 ms-5">
                <div class="h4 my-4">Agenda Items</div>
                <div class="form-group ms-5">
              
                  <div class="row d-flex my-4 border-1 border-bottom py-2">
                      <span class="col-1 h6" title="Check this to include a copy of this agenda item in the new meeting">Clone</span>
                      <span class=" col-2 h6">Agenda Item</span>
                      <span class="col-5 h6">Description</span>
                      <span class="col-2 h6" title="Expected duration of the agenda item in minutes">Duration</span>
                  </div>
                  <div class="row d-flex my-4 border-1 border-bottom py-2" ng-repeat="rec in sortItems()">
                      <span class="col-1 actions">
                        <div class="checkbox">
                          <label title="Check this to include a copy of this agenda item in the new meeting">
                            <input type="checkbox" ng-model="rec.selected"><span class="checkbox-material"></span>
                          </label>
                        </div>
                      </span>
                      <span class="col-2"><b>{{rec.subject}}
                              <span ng-show="rec.topics.length()>0">(Linked Topic)</span>
                          </b>
                          </span>
                      <span class="col-5" style="line-height: 1.3;"><div ng-bind-html="trimDesc(rec)|wiki"></div></span>
                      <span class="col-2" title="Expected duration of the agenda item in minutes">
                          <input class="form-control" style="width:80px" ng-model="rec.duration"></span>
                      </div>
              </div>
          </div>
        </div>
          <!-- Form Control BUTTONS Begin -->

        </form>
                  <div class="mx-5 row col-10 d-flex">
                    <span class="col-md-2">
                        <button class="btn btn-danger btn-raised btn-default" type="button"  onclick="history.back();">Cancel</button></span>
                    <span class="col-md-3 ms-auto">
                        <button class="btn btn-default btn-primary btn-raised ms-start" type="submit" ng-click="createMeeting()"><%=pageTitle%></button></span>

          </div>
      </div>
    </div>
  </div>
  
<% } %> 
  
</div>

<script src="<%=ar.retPath%>jscript/HtmlToMarkdown.js"></script>
<script src="<%=ar.retPath%>jscript/HtmlParser.js"></script>
<script src="<%=ar.baseURL%>jscript/TextMerger.js"></script>