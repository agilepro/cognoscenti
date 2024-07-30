<div class="accordion" id="accordionOverview"> 
    <div class="accordion-item collapsed">
      <h2 class="accordion-header" onclick="toggleAccordion(event)" id="mtgOverview">
        <button class="accordion-button" type="button" data-bs-toggle="collapse" data-bs-target="#collapseMtgOverview" aria-expanded="false" aria-controls="collapseMtgOverview"> Overview 
        </button>
      </h2>
      <div id="collapseMtgOverview" class="accordion-collapse collapse" aria-labelledby="mtgOverview" data-bs-parent="#accordionOverview">
        <div class="accordion-body">
          <div class="well" ng-cloak>
            <table>
        <tr>
        <td>
          <div class="{{meeting.state==0 ? 'buttonSpacerOn' : 'buttonSpacerOff'}}">
            <span class="btn btn-flex btn-raised" style="{{meetingStateStyle(0)}}" 
                  ng-click="changeMeetingState(0)">Draft</span>
          </div>
        </td>
        <td><i class="my-4 mx-2 fa fa-arrow-right" aria-hidden="true"></i></td>
        <td>
          <div class="{{meeting.state==1 ? 'buttonSpacerOn' : 'buttonSpacerOff'}}">
            <span class="btn btn-flex btn-raised" style="{{meetingStateStyle(1)}}" 
                  ng-click="changeMeetingState(1)">Planning</span>
          </div>
        </td>
        <td><i class="my-4 mx-2 fa fa-arrow-right" aria-hidden="true"></i></td>
        <td>
          <div class="{{meeting.state==2 ? 'buttonSpacerOn' : 'buttonSpacerOff'}}">
            <span class="btn btn-flex btn-raised" style="{{meetingStateStyle(2)}}" 
                  ng-click="changeMeetingState(2)">Running</span>
          </div>
        </td>
        <td><i class="my-4 mx-2 fa fa-arrow-right" aria-hidden="true"></i></td>
        <td>
          <div class="{{meeting.state==3 ? 'buttonSpacerOn' : 'buttonSpacerOff'}}">
            <span class="btn btn-flex btn-raised" style="{{meetingStateStyle(3)}}" 
                  ng-click="changeMeetingState(3)">Completed</span>
          </div>
        </td>
        </tr>
            </table>
            <div ng-show="meeting.state<=2">
          <p ng-show="meeting.state<=0">Meeting is in draft mode and is hidden from the participants.
            Advance the meeting to planning mode to let them know about it
            before the meeting starts.</p>
          <p ng-show="meeting.state==1">
          Meeting is in planning mode until the time that the meeting starts.
          </p>
          <p ng-show="meeting.state==2">
          Meeting is in running mode and will allow updates normally done during the meeting.
          </p>
            </div>
            <table class="table">
        <tr>
          <th></th>
          <th>Presenter</th>
          <th>Start</th>
          <th>Planned<br/>Duration</th>
          <th></th>
          <th ng-show="meeting.state==2">Actual<br/>Duration</th>
          <th ng-show="meeting.state==2">Remaining</th>
          <th></th>
        </tr>
        <tr ng-repeat="item in getAgendaItems()" ng-style="timerStyleComplete(item)" ng-hide="item.proposed" >
          <td  ng-dblclick="openAgenda(item)">
                <span ng-show="item.isSpacer" >--</span>
                <span ng-hide="item.isSpacer" >{{item.number}}.</span>
                {{item.subject}} 
          </td>
          <td ng-dblclick="openAgenda(item)">
              <span ng-repeat="person in item.presenterList">
                  <span class="dropdown" >
                    <span id="menu1" data-toggle="dropdown">
                    <img class="rounded-5" 
                        ng-src="<%=ar.retPath%>icon/{{person.key}}.jpg" 
                        style="width:32px;height:32px" 
                        title="{{person.name}} - {{person.uid}}">
                    </span>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                          tabindex="-1" style="text-decoration:none; text-align:center">
                          {{person.name}}<br/>{{person.uid}}</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="navigateToUser(person)">
                          <span class="fa fa-user"></span>Visit Profile</a></li>
                    </ul>
                  </span>
              </span>
          </td>
          <td ng-dblclick="openAgenda(item)" >
          <span>{{item.schedule | date: 'HH:mm'}} &nbsp;</span>
          </td>
          <td ng-dblclick="openAgenda(item)" >
                {{item.duration}}
          </td>
          <td >
                <span ng-hide="meeting.state!=2 || item.proposed || item.timerRunning">
                    <button ng-click="agendaStartButton(item)"><i class="fa fa-clock-o"></i> Start</button>
                </span>
                <span ng-hide="meeting.state!=2 || item.proposed || !item.timerRunning">
                    <button ng-click="stopAgendaRunning()"><i class="fa fa-clock-o"></i> Stop</button>
                </span>
          </td>
          <td ng-dblclick="openAgenda(item)" ng-show="meeting.state==2">
                <span>{{item.timerTotal| minutes}}</span>
          </td>
          <td ng-dblclick="openAgenda(item)" ng-show="meeting.state==2">
                <span>{{item.duration - item.timerTotal| minutes}}</span>
          </td>
          <td ng-style="timerStyleComplete(item)" >
            <span style="float:right;margin-left:10px;color:red" ng-show="!isCompleted()"  ng-click="deleteItem(item)" 
                  title="delete agenda item">
                <i class="fa fa-trash"></i>
            </span>
            <span style="float:right" ng-hide="item.readyToGo || isCompleted()" >
                <img src="<%=ar.retPath%>assets/goalstate/agenda-not-ready.png"
                    ng-dblclick="toggleReady(item)"
                    title="Indicates that the agenda item does NOT have all of the documents, presentations, and is full prepared for the meeting."
                    style="width:24px;height:24px;float:right">
            </span>
            <span style="float:right" ng-show="item.readyToGo && !isCompleted()"  >
                <img src="<%=ar.retPath%>assets/goalstate/agenda-ready-to-go.png"
                     ng-dblclick="toggleReady(item)"
                     title="Indicates that the agenda item has all of the documents, presentations, and is full prepared for the meeting."
                     style="width:24px;height:24px">
            </span>
            <span style="float:right; margin-right:10px" ng-show="!isCompleted()"  ng-click="moveItem(item,-1)" 
                  title="Move agenda item up if possible">
                <i class="fa fa-arrow-up"></i>
            </span>
            <span style="float:right;margin-right:10px" ng-show="!isCompleted()"  ng-click="moveItem(item,1)" 
                  title="Move agenda item down if possible">
                <i class="fa fa-arrow-down"></i>
            </span>
          </td>
        </tr>
        <tr>
            <td></td>
            <td></td>
            <td>{{meeting.startTime + (meeting.agendaDuration*60000) | date: 'HH:mm'}}</td>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
        </tr>
        <tr ng-repeat="item in getAgendaItems()" ng-style="timerStyleComplete(item)" ng-show="item.proposed" >
          <td  ng-dblclick="openAgenda(item)">
                <span>--</span>
                {{item.subject}} 
          </td>
          <td>
          </td>
          <td ng-dblclick="openAgenda(item)" >
                {{item.duration| minutes}}
          </td>
          <td ></td>
          <td ng-dblclick="openAgenda(item)"></td>
          <td ng-dblclick="openAgenda(item)"></td>
          <td ng-style="timerStyleComplete(item)" >
            <span style="float:right;margin-left:10px;color:red" ng-show="!isCompleted()"  ng-click="deleteItem(item)" 
                  title="delete agenda item">
                <i class="fa fa-trash"></i>
            </span>
            <span style="float:right;margin-right:10px" ng-click="toggleProposed(item)" 
                  title="Accept this proposed agenda item">
               ACCEPT
            </span>
          </td>
        </tr>        
      </table>

      </div>

        <div ng-show="meeting.state>=3">
          <p>Meeting is completed and no more updates are expected.</p>
        <table class="table">
        <tr>
          <th></th>
          <th>Presenter</th>
          <th>Planned Duration</th>
          <th>Actual Duration</th>
        </tr>
        <tr ng-repeat="item in getAgendaItems()" ng-dblclick="openAgenda(item)" ng-style="timerStyleComplete(item)">
          <td>
                <span ng-show="item.proposed || item.isSpacer" >--</span>
                <span ng-hide="item.proposed || item.isSpacer" >{{item.number}}.</span>

                {{item.subject}} 
          </td>
          <td>
              <span ng-repeat="person in item.presenterList">
                  <span class="dropdown" >
                    <span id="menu1" data-toggle="dropdown">
                    <img class="rounded-5" 
                         ng-src="<%=ar.retPath%>icon/{{person.key}}.jpg" 
                         style="width:32px;height:32px" 
                         title="{{person.name}} - {{person.uid}}">
                    </span>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                          tabindex="-1" style="text-decoration: none;text-align:center">
                          {{person.name}}<br/>{{person.uid}}</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="navigateToUser(person)">
                          <span class="fa fa-user"></span> Visit Profile</a></li>
                    </ul>
                  </span>

              </span>
          </td>
          <td >
                <span >
                    {{item.duration}}
                </span>
          </td>
          <td >
                <span >
                    {{item.timerTotal| minutes}}
                </span>
          </td>
        </tr>
      </table>
    </div>
    </div>
  </div>
    </div>
</div>