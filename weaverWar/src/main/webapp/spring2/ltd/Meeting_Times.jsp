<div class="card " id="cardstartTime">
  <div class="card-header">
    <span class="h5 card-title">Start Time</span>
  </div>
  <div class="card-body">

    <h5>Availability for Proposed Times</h5>

    <div class="container-fluid">
      <div class="row mb-0">
        <span class="col-2 h6">{{browserZone}}</span>
      </div>
        <div class="row d-flex mt-0 mb-2 border-bottom border-1 border-secondary border-opacity-50">
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
    
    



    