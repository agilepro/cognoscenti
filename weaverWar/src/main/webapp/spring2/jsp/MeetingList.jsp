<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to see a list of meetings");

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    String localId = ar.baseURL + "t/"+siteId+"/"+pageId+"/";
    String siteInfoURL = ar.baseURL + "t/"+siteId+"/$/siteInfo.json";
    
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    NGBook site = ngp.getSite();
    boolean userCanUpdate = !ar.isReadOnly(); 

%>

<script src="../../../jscript/AllPeople.js"></script>

<script type="text/javascript">
WCACHE.putObj("<%ar.writeJS(siteInfoURL);%>", <%site.getConfigJSON().write(out,2,4);%>, <%=System.currentTimeMillis()%>);

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Meeting List");
    $scope.siteProxy = getSiteProxy("<%ar.writeJS(ar.baseURL);%>", "<%ar.writeJS(siteId);%>");
    $scope.wsProxy = $scope.siteProxy.getWorkspaceProxy("<%ar.writeJS(pageId);%>", $scope);
    $scope.siteInfo = WCACHE.getObj("<%ar.writeJS(siteInfoURL);%>");
    $scope.meetings = [];
    $scope.wsProxy.getMeetingList(data => {$scope.meetings = data.meetings});
    console.log("MEETINGS", $scope.meetings);
    $scope.browserZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    
    $scope.getMeetings = function() {
        return $scope.meetings;
    }
    $scope.newMeeting = {
        name:"",
        duration:60,
        startTime:(new Date()).getTime(),
        id:"",
        meetingType:1,
        state:0,
        reminderTime:60
    };
    $scope.isInAttendance = false;
    
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

    $scope.onTimeSet = function (newDate) {
        $scope.newMeeting.startTime = newDate.getTime();
        console.log("NEW TIME:", newDate);
    }


    $scope.datePickOptions = {
        formatYear: 'yyyy',
        startingDay: 1
    };
    $scope.datePickDisable = function(date, mode) {
        return false;
    };
    $scope.datePickOpen = false;
    $scope.openDatePicker = function($event) {
        $event.preventDefault();
        $event.stopPropagation();
        $scope.datePickOpen = true;
    };

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.wsProxy.failure = $scope.reportError;



    $scope.deleteRow = function(row) {
        if (row.state > 0) {
            if (!confirm("Are you sure you want to delete meeting?\n"+row.name+"\n"+new Date(row.startTime))) {
                return;
            }
        }
        var delId = row.id;
        var postURL = "meetingDelete.json";
        var postdata = angular.toJson(row);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            var newSet = [];
            for( var i =0; i<$scope.meetings.length; i++) {
                var irow = $scope.meetings[i];
                if (delId != irow.id) {
                    newSet.push(irow);
                }
            }
            $scope.meetings = newSet;
            WCACHE.putObj(localKey+"meetingList.json", newSet, new Date().getTime());
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };



    $scope.meetingStateName = function(val) {
        if (val<=0) {
            return "Draft";
        }
        if (val==1) {
            return "Planning";
        }
        if (val==2) {
            return "Running";
        }
        if (val>2) {
            return "Completed";
        }
        return "Unknown";
    }

    $scope.meetingStateStyle = function(val) {
        if (val<=0) {
            return "background-color:#f0c85a";
        }
        if (val<=1) {
            return "background-color:#7dc7ff";
        }
        if (val==2) {
            return "background-color:#c3b9c9";
        }
        if (val>2) {
            return "background-color:#6c666e";
        }
        return "Unknown";
    }
    
    $scope.createMeeting = function() {
        window.location = "MeetingCreate.htm";
    }
});
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
        <h1 class="d-inline page-name" id="mainPageTitle">Meeting List</h1>
    </span>
</div>

<!-- MAIN CONTENT SECTION START -->
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

    <div class="container-fluid override col-12 ms-4">
        <div class="well">
            <span>
                <button class="btn btn-wide btn-secondary btn-raised " ng-click="createMeeting()">Create New Meeting</button>
            </span>
        </div>
        <div class="row my-2 border-1 border-bottom gridTableHeader">
            <span class="col-1 h6" >Actions</span>
            <span class="col-1 h6" >Agenda</span>
            <span class="col-3 h6" >Meeting</span>
            <span class="col-2 h6" >Date ({{browserZone}})</span>
            <span class="col-1 h6" >Minutes</span>
            <span class="col-1 h6" >State</span>
            <span class="col-1 text-center h6" >Duration</span>
        </div>
        <div class="row my-2 py-2" ng-repeat="rec in meetings">
            <span class="actions col-1">
              <a role="menuitem" tabindex="-1" title="Clone Meeting" href="CloneMeeting.htm?id={{rec.id}}">
                <button type="button" name="clone" class="btn btn-sm btn-comment">
                    <span class="fa fa-clone"></span></button>
                </a>
              <a role="menuitem" tabindex="-1" title="Delete Meeting" href="#" ng-click="deleteRow(rec)">
                <button type="button" name="delete" class="btn btn-sm btn-comment bg-danger-subtle text-danger">
                    <span class="fa fa-trash"></span>
                </button>
              </a>
            </span>
            <span class="actions col-1"><a title="Meeting Agenda" 
                 href="{{rec.agendaUrl}}">
                <button type="button" name="edit" class="btn btn-sm btn-comment"> 
                    <span class="fa fa-file-o"></span>
                </button>
              </a>
            </span>
            <span class="col-3"><b><a title="Meeting User Interface" 
                 href="MeetingHtml.htm?id={{rec.id}}">
                {{rec.name}}</a></b>
            </span>
            <span class="col-2">
                <span ng-show="rec.startTime>0">{{rec.startTime|date: "dd-MMM-yyyy 'at' HH:mm"}}</span>
                <span ng-show="rec.startTime<=0"><i>( To Be Determined )</i></span>
            </span>
            <span class="col-1 actions">
              <a role="menuitem" tabindex="-1" title="Meeting Minutes" 
                 href="{{rec.minutesUrl}}">
                <button type="button" name="edit" class="btn btn-sm btn-comment">
                    <span class="fa fa-file-text-o"></span>
                </button>
              </a>
            </span>
            <span class="btn col-1 p-2" style="{{meetingStateStyle(rec.state)}}">{{meetingStateName(rec.state)}}</span>
            <span class="col-1 text-center">{{rec.duration}}</span>
        </div>
    </div>
<% if (userCanUpdate) { %>
    <div class="row ms-4 override">
        <div class="d-flex col-2 m-2">
            
        </div>
    </div>
<% } %>
    <div class="guideVocal" ng-show="meetings.length==0" style="margin-top:80px">
    There are no meetings in this workspace yet.<br/>
    
<% if (userCanUpdate) { %>  <br/>  Create a meeting records to hold the agenda of an upcoming meeting.  
    <br/>
    Later use the meeting record to check everyone in, help
    keep notes, and generate the minutes of the meeting.
<% } %>    
    </div>
    
    <div class="row ms-4 override">
        <div class="d-flex col-2 m-2">
          <a href="PickMeeting.wmf">
            <button class="btn btn-wide btn-comment btn-raised"><i class="fa fa-mobile"></i> View Mobile UI</button>
          </a>
        </div>
    </div>

    
</div>
