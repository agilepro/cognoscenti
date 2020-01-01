<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%

    ar.assertLoggedIn("Must be logged in to see a list of meetings");

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    String localId = ar.baseURL + "t/"+siteId+"/"+pageId+"/";
    String siteInfoURL = ar.baseURL + "t/"+siteId+"/$/siteInfo.json";
    
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    NGBook site = ngp.getSite();

%>

<script src="../../../jscript/AllPeople.js"></script>

<script type="text/javascript">
WCACHE.putObj("<%ar.writeJS(siteInfoURL);%>", <%site.getConfigJSON().write(out,2,4);%>, <%=System.currentTimeMillis()%>);

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Meetings");
    $scope.siteProxy = getSiteProxy("<%ar.writeJS(ar.baseURL);%>", "<%ar.writeJS(siteId);%>");
    $scope.wsProxy = $scope.siteProxy.getWorkspaceProxy("<%ar.writeJS(pageId);%>", $scope);
    $scope.siteInfo = WCACHE.getObj("<%ar.writeJS(siteInfoURL);%>");
    $scope.meetings = [];
    $scope.wsProxy.getMeetingList(data => {$scope.meetings = data.meetings; console.log("GOT IT", $scope.meetings)});
    
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
            return "background-color:yellow";
        }
        if (val<=1) {
            return "background-color:white";
        }
        if (val==2) {
            return "background-color:lightgreen";
        }
        if (val>2) {
            return "background-color:gray";
        }
        return "Unknown";
    }
    
    $scope.createMeeting = function() {
        window.location = "CloneMeeting.htm";
    }
});
</script>



<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

<div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              title="Create a new meeting record"
              href="CloneMeeting.htm" ><i class="fa fa-plus"></i>New Meeting</a></li>
          
        </ul>
      </span>
</div>

    <table class="table table-striped table-hover" width="100%">
        <tr class="gridTableHeader">
            <th width="100px"></th>
            <th width="200px">Meeting</th>
            <th width="200px">Date ({{0|date: "'GMT'Z"}})</th>
            <th width="80px">State</th>
            <th width="80px">Duration</th>
        </tr>
        <tr ng-repeat="rec in meetings">
            <td class="actions">
              <a role="menuitem" tabindex="-1" title="Edit Meeting" href="meetingFull.htm?id={{rec.id}}">
                <button type="button" name="edit" class='btn btn-primary'>
                    <span class="fa fa-edit"></span>
                </button>
              </a>
              <a role="menuitem" tabindex="-1" title="Clone Meeting" href="CloneMeeting.htm?id={{rec.id}}">
                <button type="button" name="clone" class='btn btn-default'>
                    <span class="fa fa-clone"></span>
                </button>
              </a>
              <a role="menuitem" tabindex="-1" title="Delete Meeting" href="#" ng-click="deleteRow(rec)">
                <button type="button" name="delete" class='btn btn-warning'>
                    <span class="fa fa-trash"></span>
                </button>
              </a>
            </td>
            <td><b><a title="View Meeting" href="meetingFull.htm?id={{rec.id}}">{{rec.name}}</a></b></td>
            <td>
                <span ng-show="rec.startTime>0">{{rec.startTime|date: "dd-MMM-yyyy 'at' HH:mm"}}</span>
                <span ng-show="rec.startTime<=0"><i>( To Be Determined )</i></span>
            </td>
            <td style="{{meetingStateStyle(rec.state)}}">{{meetingStateName(rec.state)}}</td>
            <td>{{rec.duration}}</td>
        </tr>
    </table>
    
    <button class="btn btn-primary btn-raised" ng-click="createMeeting()"><i class="fa fa-plus"></i> Create New Meeting</button>
    <div class="guideVocal" ng-show="meetings.length==0" style="margin-top:80px">
    You have no meetings in this workspace yet.<br/>
    <br/>
    Create a meeting records to hold the agenda of an upcoming meeting.<br/>
    Later use the meeting record to check everyone in, help
    keep notes, and generate the minutes of the meetng.
    </div>
    
    
</div>
