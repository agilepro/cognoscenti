<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of a workspace and here it is used to retrieve NGWorkspace.

*/

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    
    String meetId          = ar.reqParam("id");
    String mnm             = ar.defParam("mnm", null);
    MeetingRecord meeting  = ngw.findMeeting(meetId);
    JSONObject meetingObj = meeting.getFullJSON(ar, ngw, true);
    
    JSONArray timeSlots = meetingObj.getJSONArray("timeSlots");
    if (timeSlots.length()==0) {
        long startTime = meeting.getStartTime();
        if (startTime>0) {
            meeting.findOrCreateProposedTime("timeSlots", startTime);
            meetingObj = meeting.getFullJSON(ar, ngw, true);
        }
    }
    
    boolean isScheduled = meeting.isScheduled();
    String canAttend = ""; 
    String userSituation = "";
    
    

    String emailId    = ar.defParam("emailId", null);
    if (ar.isLoggedIn()) {
        emailId = ar.getBestUserId();
    }
    
    String magicNumber = AccessControl.getAccessMeetParams(ngw, meeting);


%>


<!-- ************************ xxx/MeetingAvail.jsp ************************ -->
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Meeting Availability:");
    $scope.meeting = {};
    $scope.emailId = "<% ar.writeJS(emailId); %>";
    $scope.canAttend = "<% ar.writeJS(canAttend); %>";
    $scope.userSituation = "<% ar.writeJS(userSituation); %>";
    $scope.oldAttend = "<% ar.writeJS(canAttend); %>";
    $scope.oldSituation = "<% ar.writeJS(userSituation); %>";
    

    <% if (ar.isLoggedIn()) {%>
    $scope.emailId = "<%ar.writeJS(emailId);%>";
    $scope.userName = "<%ar.writeJS(ar.getUserProfile().getName());%>";
    localStorage.setItem('userEmail', $scope.emailId);
    localStorage.setItem('userName', $scope.userName);
    <% } else {%>
    $scope.emailId = localStorage.getItem('userEmail');
    $scope.userName = localStorage.getItem('userName');
    <% } %>
    $scope.editEmailId = $scope.emailId;
    $scope.savedAttendInfo = false;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        console.log("Encountered problem: ",serverErr);
    };
    
    $scope.setMeetingData = function(data) {
        console.log("Received meeting data: ", data);
        if (!data.meetingInfo) {
            data.meetingInfo = "";
        }
        $scope.timerCorrection = data.serverTime - new Date().getTime();
        $scope.meeting = data;

        $scope.editHead=false;
        $scope.editDesc=false;
        if (data.reminderTime%1440 == 0) {
            $scope.timeFactor="Days"
        }
        else {
            $scope.timeFactor="Minutes"
        }
        if ($scope.timeFactor=="Days") {
            $scope.factoredTime = $scope.meeting.reminderTime / 1440;
        }
        else {
            $scope.factoredTime = $scope.meeting.reminderTime;
        }
        data.timeSlots.sort(function(a,b) {
            return a.proposedTime - b.proposedTime;
        });
        $scope.timeSlotResponders = calcResponders(data.timeSlots, $scope.emailId);
        
        $scope.findAttendSettings();
    }
    $scope.findAttendSettings = function() {
        $scope.canAttend = "";
        $scope.userSituation = "";
        $scope.meeting.rollCall.forEach( function(item) {
            if ($scope.emailId == item.uid) {
                $scope.canAttend = item.attend;
                $scope.userSituation = item.situation;
            }
        });
    }
    $scope.setMeetingData(<%meetingObj.write(out,2,4);%>);
    
    $scope.setVote = function(fieldName, time, resp, newVal) {
        var isCurrent = ("timeSlots" == fieldName);
        var obj = {action:"SetValue", isCurrent: isCurrent, time: time, user: resp, value:newVal};
        var postURL = "proposedTimes.json?id="+$scope.meeting.id+"&<% ar.writeJS(magicNumber); %>";
        var postdata = angular.toJson(obj);
        $http.post(postURL,postdata)
        .success( function(data) {
            $scope.setMeetingData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }

    $scope.saveSituation = function() {
        var obj = {uid: $scope.emailId, attend: $scope.canAttend, situation: $scope.userSituation};
        var postURL = "setSituation.json?id="+$scope.meeting.id+"&<% ar.writeJS(magicNumber); %>";
        console.log("Request to: "+postURL);
        var postdata = angular.toJson(obj);
        $http.post(postURL,postdata)
        .success( function(data) {
            $scope.setMeetingData(data);
            $scope.savedAttendInfo = true;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }

    
    $scope.columnStyle = function(user) {
        if (user==$scope.emailId) {
            return {"background-color": 'lightyellow',"text-align":"center"};
        } 
        else {
            return {"background-color": 'white',"text-align":"center"};
        }
    }
    
    $scope.goToDiscussion = function() {
    <% if (ar.isLoggedIn()) {%>
        window.location = "MeetingHtml.htm?id="+$scope.meeting.id;
    <% } else {%>
        SLAP.loginUserRedirect();
    <% } %>
    }
    
    $scope.clearEmail = function() {
        $scope.emailId = "";
    }
    $scope.saveAddresses = function() {
        if (!$scope.editEmailId) {
            alert("Please enter an email address");
            return;
        }
        
        if (!$scope.userName) {
            alert("Please enter a Name");
            return;
        }
        $scope.emailId = $scope.editEmailId
        localStorage.setItem('userEmail', $scope.editEmailId);
        localStorage.setItem('userName', $scope.userName);
        $scope.findAttendSettings();
    }
    
    
});

function calcResponders(slots, curUser) {
    var res = [];
    slots.forEach( function(oneTime) {
        Object.keys(oneTime.people).forEach( function(person) {
            if (res.indexOf(person)<0) {
                res.push(person);
            }
        });
    });
    if (res.indexOf(curUser)<0) {
        res.push(curUser);
    }
    res.sort();
    return res;
}


function reloadIfLoggedIn() {
    if (SLAP.loginInfo.verified) {
        window.location = "<%= ar.getCompleteURL() %>";
    }
}
</script>


<style>
.spacey tr td {
    padding: 5px 10px;
}
label {
    color: black;
}
.comment-outer {
    max-width:600px;
}
</style>



<div class="bodyWrapper"  style="margin:50px;max-width:800px">


    <table class="table">
      <tr>
        <td>Name</td>
        <td><b>{{meeting.name}}</b></td>
      </tr>
      <tr>
        <td>Description</td>
        <td><div ng_bind-html="meeting.description|wiki"></div></td>
      </tr>
      <tr>
        <td>Video Conference</td>
        <td><a href="{{meeting.conferenceUrl}}" target="_blank">{{meeting.conferenceUrl}}</a></td>
      </tr>
<% if (isScheduled) { %>
      <tr>
        <td>Date/Time</td>
        <td>{{meeting.startTime |date:"dd-MMM-yyyy &nbsp; HH:mm"}}</td>
      </tr>
<% } %>
      <tr>
        <td>Info</td>
        <td>You can view the
            <a href="MeetPrint.htm?id={{meeting.id}}&tem={{meeting.notifyLayout}}&mnm=<%=mnm%>">Agenda</a> or the 
            <a href="MeetPrint.htm?id={{meeting.id}}&tem={{meeting.defaultLayout}}&mnm=<%=mnm%>">Minutes</a>
        </td>
      </tr>
<% if (!ar.isLoggedIn()) { %>
      <tr ng-show="emailId">
        <td>Email</td>
        <td> {{emailId}}  <button class="btn btn-default btn-raised"
             ng-click="clearEmail()">That is not me!   Change it.</button></td>
      </tr>
<% } %>
    </table>


<% if (isScheduled) { %>
    <div class="comment-outer comment-state-active"
         title="Shows whether you can attend or not.">
      <div style="color:gray">Let everyone know your current situation</div>
      
      <div style="padding:20px" ng-hide="emailId">
        
            <div>Please enter/verify your email address</div>
            <div><input class="form-control" ng-model="editEmailId" placeholder="Enter email"/></div>
            <div>And your name</div>
            <div><input class="form-control" ng-model="userName" placeholder="Enter name"/></div>
            <div><button class="btn btn-primary btn-raised" ng-click="saveAddresses()"
                title="Save these verified values">Save & Continue</button></div>
      </div>

      <div style="padding:20px" ng-show="emailId">
         <label>Do you expect to attend at this time? </label>
         <div>
           <select ng-model="canAttend" class="form-control" style="padding:0">
                 <option>Unknown</option>
                 <option>Yes</option>
                 <option>Maybe</option>
                 <option>No</option>
              </select>
         </div>
         <br/>
         <label>Additional details others attendees should know:</label>
         <div>
           <textarea ng-model="userSituation" class="form-control" style="min-width:400px;min-height=200px"></textarea>
         </div>
         <div ng-show="canAttend!=oldAttend || userSituation!=oldSituation">
           <button ng-click="saveSituation()" class="btn btn-primary btn-raised">Save This</button>
         <span ng-show="savedAttendInfo">
           <i>Thanks for updating.  Everyone appreciates you letting them know this.</i>
         </span>
         </div>
      </div>
      
    </div>
<% } else { %>
    <div class="comment-outer comment-state-active" 
         title="Shows what time slots people might be able to attend.">
      <div >Indicate whether these times would be good for you</div>
      <div style="padding:20px" ng-hide="emailId">
        
            <div>Please enter/verify your email address</div>
            <div><input class="form-control" ng-model="editEmailId" placeholder="Enter email"/></div>
            <div>And your name</div>
            <div><input class="form-control" ng-model="userName" placeholder="Enter name"/></div>
            <div><button class="btn btn-primary btn-raised" ng-click="saveAddresses()"
                title="Save these verified values">Save & Continue</button></div>
      </div>
      <div class="comment-inner" ng-show="emailId">
          <table class="table">
          <tr>
              <th>Time</th>
              <th style="width:20px;"></th>
              <th ng-repeat="resp in timeSlotResponders" title="{{resp}}"     
                  ng-style="columnStyle(resp)">
                <span class="dropdown" >
                    {{resp|limitTo:6}}
                </span>
              
              </th>
          </tr>
          <tr ng-repeat="time in meeting.timeSlots">
              <td><div ng-click="setProposedTime(time.proposedTime)">{{time.proposedTime |date:"dd-MMM-yyyy HH:mm"}}</div></td>
              <td style="width:20px;"></td>
              <td ng-repeat="resp in timeSlotResponders"   
                  ng-style="columnStyle(resp)">
                 <span class="dropdown">
                    <button class="dropdown-toggle btn votingButton" type="button"  d="menu" style="margin:0px;width:100%;height:100%"
                        data-toggle="dropdown"> &nbsp; 
                        <span ng-show="time.people[resp]==1" title="very bad time for me" style="color:red;">
                            <span class="fa fa-minus-circle"></span>
                            <span class="fa fa-minus-circle"></span></span>
                        <span ng-show="time.people[resp]==2" title="bad time for me" style="color:red;">
                            <span class="fa fa-minus-circle"></span></span>
                        <span ng-show="time.people[resp]==3" title="don't know" style="color:#eeeeee;">
                            <span class="fa fa-question-circle"></span></span>
                        <span ng-show="time.people[resp]==4" title="ok time for me" style="color:green;">
                            <span class="fa fa-plus-circle"></span></span>
                        <span ng-show="time.people[resp]==5" title="good time for me" style="color:green;">
                            <span class="fa fa-plus-circle"></span>
                            <span class="fa fa-plus-circle"></span></span>
                        &nbsp;
                    </button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu">
                      <li role="presentation">
                          <a role="menuitem" ng-click="setVote('timeSlots', time.proposedTime, resp, 5)">
                          <i class="fa fa-plus-circle" style="color:green"></i>
                          <i class="fa fa-plus-circle" style="color:green"></i>
                          Good Time</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="setVote('timeSlots', time.proposedTime, resp, 4)">
                          <i class="fa fa-plus-circle" style="color:green"></i>
                          OK Time</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="setVote('timeSlots', time.proposedTime, resp, 3)">
                          <i class="fa fa-question-circle" style="color:gray"></i>
                          Unknown</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="setVote('timeSlots', time.proposedTime, resp, 2)">
                          <i class="fa fa-minus-circle" style="color:red"></i>
                          Bad time</a></li>
                      <li role="presentation">
                          <a role="menuitem" ng-click="setVote('timeSlots', time.proposedTime, resp, 1)">
                          <i class="fa fa-minus-circle" style="color:red"></i>
                          <i class="fa fa-minus-circle" style="color:red"></i>
                          Impossible</a></li>
                    </ul>
                </span>
              </td>
          </tr>
          </table>
       </div>
    </div>
<% } %>

        
    <div style="margin:25px">
<% if (!ar.isLoggedIn()) {%>
            For more options <button class="btn btn-primary btn-raised" ng-click="goToDiscussion()"
                title="Link to the full discussion with all the options">Login</button>
<% } else {%>
            For more options <button class="btn btn-primary btn-raised" ng-click="goToDiscussion()"
                title="Link to the full discussion with all the options">Go To Full Meeting Display</button>
<% } %>
    </div>


</div>


  </div>
