<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%

    ar.assertLoggedIn("Must be logged in to see a list of meetings");

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();

    JSONArray meetings = new JSONArray();
    List<MeetingRecord> allMeets = ngp.getMeetings();
    MeetingRecord.sortChrono(allMeets);
    for (MeetingRecord oneRef : allMeets) {
        if (!oneRef.isBacklogContainer()) {
            meetings.put(oneRef.getListableJSON(ar));
        }
    }

%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap','ui.bootstrap.datetimepicker']);
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Meetings");
    $scope.meetings = <%meetings.write(out,2,4);%>;
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
    
});
</script>



<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>


<div class="btn-toolbar primary-toolbar">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              title="Create a new meeting record"
              href="cloneMeeting.htm" ><i class="fa fa-plus"></i>New Meeting</a></li>
          <li role="presentation"><a role="menuitem" 
              title="Access agenda items removed from other meetings"
              href="agendaBacklog.htm" ><i class="fa fa-list-alt material-icons"></i> Agenda Backlog</a></li>
          
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
              <a role="menuitem" tabindex="-1" title="Clone Meeting" href="cloneMeeting.htm?id={{rec.id}}">
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
            <td>{{rec.startTime|date: "dd-MMM-yyyy 'at' HH:mm"}}</td>
            <td style="{{meetingStateStyle(rec.state)}}">{{meetingStateName(rec.state)}}</td>
            <td>{{rec.duration}}</td>
        </tr>
    </table>

</div>
