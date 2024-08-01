<div class="accordion" id="accordionstartTime">
  <div class="accordion-item collapsed">
    <h2 class="accordion-header" onclick="toggleAccordion(event)" id="mtgstartTime">
      <button class="accordion-button" type="button" data-bs-toggle="collapse" data-bs-target="#collapseMtgstartTime" aria-expanded="true" aria-controls="collapseMtgstartTime"> Scheduled Start Time 
      </button>
    </h2>
    <div id="collapseMtgstartTime" class="accordion-collapse collapse" aria-labelledby="mtgstartTime" data-bs-parent="#accordionstartTime">
      <div class="accordion-body">
    <div class="well">
      <button class="btn btn-sm btn-primary" ng-hide="'startTime'==editMeetingPart" 
          ng-click="editMeetingPart='startTime'">Edit</button>
    
      <table class="table" ng-hide="'startTime'==editMeetingPart">
        <tr>
            <td>{{browserZone}}</td>
            <td>
              <div ng-show="meeting.startTime>0">
                {{meeting.startTime|date: "dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm"}}&nbsp;
              </div>
              <div ng-hide="meeting.startTime>0">
                <i>( To Be Determined )</i>
              </div>
            </td>
            <td>
                <a href="meetingTime{{meeting.id}}.ics" title="Make a calendar entry for this meeting">
                  <i class="fa fa-calendar"></i></a> &nbsp; 
            </td>
        </tr>
        <tr ng-hide="meeting.startTime<=0">
          <td>
             <button class="btn btn-sm btn-primary" ng-click="getTimeZoneList()">Show Timezones</button><br/>
          </td>
          <td></td>
          <td></td>
        </tr>
        <tr ng-repeat="val in allDates">
          <td>{{val.zone}}</td>
          <td>{{val.time}}</td>
          <td></td>
       </tr>
      </table>
      <div ng-show="'startTime'==editMeetingPart">
        <div class="well" style="max-width:500px">
            <span datetime-picker ng-model="meeting.startTime"
                  class="form-control">
              {{meeting.startTime|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm"}}
            </span>
            <span>&nbsp; ({{browserZone}})</span><br/>
            <button class="btn btn-primary btn-raised" 
                    ng-click="createTime('timeSlots', meeting.startTime);savePendingEdits()">Save</button>
            <button class="btn btn-primary btn-raised" ng-click="meeting.startTime=0;savePendingEdits()">To Be Determined</button>
            <button class="btn btn-warning btn-raised" ng-click="editMeetingPart=null">Cancel</button>
        </div>
      </div>
    </div>

    <hr/>
    <h3 class="h5">Availability for Proposed Times</h3>

    <div class="table">
    <div class="row d-flex my-2 border-bottom border-1 border-secondary border-opacity-50">
      <span class="col-1"></span>
      <span class="col-2 h6">Date and Time<br/>{{browserZone}}</span>
      <span class="col-1" ng-repeat="player in timeSlotResponders" title="{{player.name}}"    
          style="text-align:center">
          <span class="nav-item dropdown" >
            <span id="menu1" data-toggle="dropdown">
            <img class="rounded-5" 
                 ng-src="<%=ar.retPath%>icon/{{player.key}}.jpg" 
                 style="width:32px;height:32px" 
                 title="{{player.name}} - {{player.uid}}">
            </span>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
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
      <span class="col-1">
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
      <span class="col-1 text-center0" ng-repeat="resp in timeSlotResponders">
         <span class="nav-item col-1 dropdown">select
            <button class=" btn votingButton" type="button"  d="menu" 
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
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu">
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
                class="btn btn-sm btn-wide btn-primary" ">Add Proposed Time</button>
    </div>

    <div ng-show="showTimeAdder" class="well">
        Choose a time: <span datetime-picker ng-model="newProposedTime" class="form-control" style="display:inline">
          {{newProposedTime|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm"}}  
        </span> 
        and then <button ng-click="createTime('timeSlots', newProposedTime)" 
                 class="btn btn-primary btn-raised">Add It</button>
        &nbsp; ({{browserZone}}) &nbsp;
        or <button ng-click="showTimeAdder=false" 
                 class="btn btn-warning btn-raised">Cancel</button>
    </div>
      </div>
    </div>
</div>
</div>