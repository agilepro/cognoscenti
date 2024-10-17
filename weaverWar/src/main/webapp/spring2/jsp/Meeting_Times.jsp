<div class="card" id="cardstartTime">
  <div class="card-header">
    <span class="h5 card-title">Start Time</span>
  </div>
    <div class="card-body">
      
    
      <div class="col-12" ng-hide="'startTime'==editMeetingPart">
        <div class="row ps-0 mb-3">
            <span class="col-3 ">
              <button class="btn btn-wide btn-primary" ng-hide="'startTime'==editMeetingPart" ng-click="editMeetingPart='startTime'">Edit Meeting Time</button>
            </span>
        </div>
        <div class="row ps-0">
            <span class="col-3 h5">{{browserZone}}</span>
            <span class="col-7 h5">
              <div ng-show="meeting.startTime>0">
                {{meeting.startTime|date: "dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm"}}&nbsp;
              </div>
              <div ng-hide="meeting.startTime>0">
                <i>( To Be Determined )</i>
              </div>
            </span>
            <span class="col-1">
                <a href="meetingTime{{meeting.id}}.ics" title="Make a calendar entry for this meeting">
                  <i class="fa fa-calendar"></i></a> &nbsp; 
            </span>
        </div>
        <div class="row" ng-hide="meeting.startTime<=0">
          <span class="col-3">
             <button class="btn btn-short px-4" ng-click="getTimeZoneList()">Show Timezones</button><br/>
          </span>
        </div>
        <div class="row" ng-repeat="val in allDates">
          <span>{{val.zone}}</span>
          <span>{{val.time}}</span>
          <span></span>
       </div>
      </div>
      <div ng-show="'startTime'==editMeetingPart">
        <div class="well col-12" style="max-width:1000px">
          <div class="row d-flex">
            <span datetime-picker ng-model="meeting.startTime"
                  class="form-control">
              {{meeting.startTime|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm"}}
            </span></div>
            <span class="col-2 h6"> ({{browserZone}})</span><br/>
            <div class="row d-flex">
              <span class="col-2 ms-0 ps-0">
            <button class="btn btn-danger btn-raised" ng-click="editMeetingPart=null">Cancel</button></span>
            <span class="col-8">
            <button class="btn btn-wide btn-secondary btn-raised" ng-click="meeting.startTime=0;savePendingEdits()">To Be Determined</button></span>
            <span class="col-2">
            
            <button class="btn btn-primary btn-raised ms-auto" 
                    ng-click="createTime('timeSlots', meeting.startTime);savePendingEdits()">Save</button></span></div>
        </div>
      </div>
      <hr/>
    <h3 class="h5">Availability for Proposed Times</h3>
    

    

    <div class="container-fluid">
    <div class="row d-flex my-2 border-bottom border-1 border-secondary border-opacity-50">
      
      <span class="col-2 h6">{{browserZone}}</span>
      <span class="col-2 h6">Date and Time</span>
      <span class="col-1 mb-1 mt-0" ng-repeat="player in timeSlotResponders" title="{{player.name}}"    
          style="text-align:center">
          <span class="nav-item dropdown" >
            <span id="menu1" data-toggle="dropdown">
            <img class="rounded-5" 
                 ng-src="<%=ar.retPath%>icon/{{player.key}}.jpg" 
                 style="width:32px;height:32px" 
                 title="{{player.name}} - {{player.uid}}">
            </span>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1" style="margin-top: -75px;">
              <li role="presentation" style="background-color:lightgrey"><a class="dropdown-item" role="menuitem" 
                  tabindex="-1" style="text-decoration: none;text-align:center">
                  {{player.name}}<br/>{{player.uid}}</a></li>
              <li role="presentation" style="cursor:pointer"><a class="dropdown-item" role="menuitem" tabindex="-1"
                  ng-click="navigateToUser(player)">
                  <span class="fa fa-user"></span> Visit Profile</a></li>
            </ul>
          </span>
      </span>
    </div>
    <div class="row d-flex my-2" ng-repeat="time in meeting.timeSlots" ng-style="timeRowStyle(time)">
      <span class="col-2">
        <span class="nav-item dropdown">
            <button class="dropdown-toggle specCaretBtn" type="button"  d="menu"
                data-toggle="dropdown"> <span class="caret"></span> </button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu">
              <li role="presentation">
                  <a class="dropdown-item" role="menuitem" ng-click="removeTime(time.proposedTime)">
                  <i class="fa fa-times"></i>
                  Remove Proposed Time</a></li>
              <li role="presentation">
                  <a class="dropdown-item" role="menuitem" ng-click="console.log('foo');setMeetingTime(time.proposedTime)"><i class="fa fa-check"></i> Set Meeting to this Time</a></li>
            </ul>
        </span>
      </span>
      <span class="col-2">
          <div class="text-left pt-0">
          {{time.proposedTime |date:"dd-MMM-yyyy HH:mm"}}
          <span ng-show="time.proposedTime == meeting.startTime" class="text-primary fa fa-check"></span>
          </div>
      </span>
      <span class="col-1 text-center"  ng-repeat="resp in timeSlotResponders">
         <span class="nav-item col-1 dropdown "  >select
            <button class=" btn votingButton"  type="button"  d="menu" 
                data-toggle="dropdown"> 
                <span class="dropdown-item" ng-show="time.people[resp.uid]==1" title="Conflict for that time" style="color:red;">
                    <span class="fa fa-minus-circle"></span>
                    <span class="fa fa-minus-circle"></span></span>
                <span class="dropdown-item" ng-show="time.people[resp.uid]==2" title="Very uncertain, maybe unlikely" style="color:red;">
                    <span class="fa fa-question-circle"></span></span>
                <span class="dropdown-item" ng-show="time.people[resp.uid]==3" title="No response given">
                    <span class="text-secondary opacity-50 fa fa-question-circle"></span></span>
                <span class="dropdown-item" ng-show="time.people[resp.uid]==4" title="ok time for me" style="color:green;">
                    <span class="fa fa-plus-circle"></span></span>
                <span class="dropdown-item" ng-show="time.people[resp.uid]==5" title="good time for me" style="color:green;">
                    <span class="fa fa-plus-circle"></span>
                    <span class="fa fa-plus-circle"></span></span>
                &nbsp;
            </button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu" style="margin-top: -40px;">
              <li role="presentation">
                  <a class="dropdown-item" role="menuitem" ng-click="setVote('timeSlots', time.proposedTime, resp.uid, 5)">
                  <i class="fa fa-plus-circle" style="color:green"></i>
                  <i class="fa fa-plus-circle" style="color:green"></i>
                  Good Time</a></li>
              <li role="presentation">
                  <a class="dropdown-item" role="menuitem" ng-click="setVote('timeSlots', time.proposedTime, resp.uid, 4)">
                  <i class="fa fa-plus-circle" style="color:green"></i>
                  OK Time</a></li>
              <li role="presentation">
                  <a class="dropdown-item" role="menuitem" ng-click="setVote('timeSlots', time.proposedTime, resp.uid, 3)">
                  <i class="text-secondary opacity-50 fa fa-question-circle"></i>
                  No Response</a></li>
              <li role="presentation">
                  <a class="dropdown-item" role="menuitem" ng-click="setVote('timeSlots', time.proposedTime, resp.uid, 2)">
                  <i class="fa fa-question-circle" style="color:red"></i>
                  Uncertain</a></li>
              <li role="presentation">
                  <a class="dropdown-item" role="menuitem" ng-click="setVote('timeSlots', time.proposedTime, resp.uid, 1)">
                  <i class="fa fa-minus-circle" style="color:red"></i>
                  <i class="fa fa-minus-circle" style="color:red"></i>
                  Conflict at that Time</a></li>
            </ul>
        </span>
      </span>
    </div>
    </div>
    
    
    <div ng-hide="showTimeAdder">
        <button ng-click="showTimeAdder=true" 
                class="btn btn-wide btn-primary">Add Proposed Time</button>
    </div>

    <div ng-show="showTimeAdder" class="well px-2 py-3">
        Choose a time: <span datetime-picker ng-model="newProposedTime" class="form-control" style="display:inline">
          {{newProposedTime|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm"}}  
        </span> &nbsp; <span class="h6"> ({{browserZone}}) &nbsp;</span>
         and then <button ng-click="createTime('timeSlots', newProposedTime)" 
                 class="btn btn-primary btn-raised">Add It</button>
        &nbsp;
        or <button ng-click="showTimeAdder=false" 
                 class="btn btn-danger btn-raised">Cancel</button>
    </div>
    </div>
    </div>

