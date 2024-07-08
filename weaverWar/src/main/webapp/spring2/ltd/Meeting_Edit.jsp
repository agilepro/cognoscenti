<table width="100%"><tr>
<td style="width:180px;border-right:4px black solid;vertical-align: top;">
<div ng-repeat="item in getAgendaItems()">
    <div ng-style="itemTabStyleComplete(item)" ng-click="setSelectedItem(item)" ng-hide="item.proposed"
         ng-dblclick="openAgenda(selectedItem)">
        <span ng-show="item.proposed" style="color:grey">SHOULD NEVER SHOW THIS</span>
        <span ng-show="item.isSpacer" style="color:grey">Break</span>
        <span ng-show="!item.proposed && !item.isSpacer" >{{item.number}}.</span>
        <span style="float:right" ng-hide="item.proposed">{{item.schedule | date: 'HH:mm'}} &nbsp;</span>
        <br/>
        {{item.subject}}
    </div>
</div>
<div>
    <span style="float:right">{{meeting.startTime + (meeting.agendaDuration*60000) | date: 'HH:mm'}} &nbsp;</span>
</div>
<div style="height:70px">&nbsp;</div>

<div ng-repeat="item in getAgendaItems()">
    <div ng-style="itemTabStyleComplete(item)" ng-click="setSelectedItem(item)" ng-show="item.proposed"
         ng-dblclick="openAgenda(selectedItem)">
        <span ng-show="item.proposed" style="color:grey">Proposed</span>
        <br/>
        {{item.subject}}
    </div>
</div>


    <hr/>

</td>
<td ng-repeat="item in [selectedItem]" style="vertical-align: top;">

    <table class="table" ng-show="item.id">
    <col width="150">
    <tr >
      <td >Subject:</td>
      <td ng-style="timerStyleComplete(item)"><span class="h2">{{selectedItem.subject}}</span></td>
    </tr>
    <tr ng-hide="selectedItem.isSpacer">
      <td >Notes/Minutes:</td>
      <td >
        <div ng-bind-html="selectedItem.minutesHtml"></div>
      </td>
    </tr>
    <tr ng-hide="selectedItem.isSpacer">
      <td >Action Items:</td>
      <td title="double-click to modify the action items">
          <table class="table">
          <tr ng-repeat="goal in itemGoals(selectedItem)">
              <td>
                <a href="task{{goal.id}}.htm" title="access action item details">
                   <img ng-src="<%=ar.retPath%>assets/goalstate/small{{goal.state}}.gif"></a>
              </td>
              <td>
                {{goal.synopsis}}
              </td>
              <td>
                <div ng-repeat="person in goal.assignTo">
                  <span class="dropdown" >
                    <span id="menu1" data-toggle="dropdown">
                    <img class="img-circle" 
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
                </div>
              </td>
              <td >
                <div>{{goal.status}}</div>
                <div ng-repeat="ci in goal.checkitems" >
                  <span ng-click="toggleCheckItem($event, goal, ci.index)" style="cursor:pointer">
                    <span ng-show="ci.checked"><i class="fa  fa-check-square-o"></i></span>
                    <span ng-hide="ci.checked"><i class="fa  fa-square-o"></i></span>
                  &nbsp; 
                  </span>
                  {{ci.name}}
                </div>
              </td>
          </tr>
          </table>
      </td>
    </tr>
    <tr ng-hide="selectedItem.isSpacer">
      <td >Attachments:</td>
      <td title="double-click to modify the attachments">
          <div ng-repeat="docid in selectedItem.docList track by $index" style="vertical-align: top">
              <div ng-repeat="fullDoc in getSelectedDocList(docid)"> 
                  <span ng-click="navigateToDoc(fullDoc.id)" title="access attachment">
                    <img src="<%=ar.retPath%>assets/images/iconFile.png" ng-show="fullDoc.attType=='FILE'">
                    <img src="<%=ar.retPath%>assets/images/iconUrl.png" ng-show="fullDoc.attType=='URL'">
                  </span> &nbsp;
                  <span ng-click="downloadDocument(fullDoc)" title="download attachment">
                    <span class="fa fa-external-link" ng-show="fullDoc.attType=='URL'"></span>
                    <span class="fa fa-download" ng-hide="fullDoc.attType=='URL'"></span>
                  </span> &nbsp; 
                  {{fullDoc.name}}
              </div>
          </div>
       </td>
    </tr>
    <tr  ng-hide="selectedItem.isSpacer">
      <td >Presenter:</td>
      <td>
        <div ng-repeat="presenter in selectedItem.presenterList">
              <span class="dropdown" >
                <span id="menu1" data-toggle="dropdown">
                <img class="img-circle" 
                     ng-src="<%=ar.retPath%>icon/{{presenter.key}}.jpg" 
                     style="width:32px;height:32px" 
                     title="{{presenter.name}} - {{presenter.uid}}">
                </span>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                      tabindex="-1" style="text-decoration: none;text-align:center">
                      {{presenter.name}}<br/>{{presenter.uid}}</a></li>
                  <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                      ng-click="navigateToUser(presenter)">
                      <span class="fa fa-user"></span> Visit Profile</a></li>
                </ul>
              </span>
            {{presenter.name}}
        </div>
      </td>
    </tr>
    <tr  ng-show="!selectedItem.isSpacer">
      <td >Description:</td>
      <td>
        <div ng-bind-html="selectedItem.descriptionHtml"></div>
      </td>
    </tr>
    <tr ng-hide="item.proposed">
      <td >Planned:</td>
      <td>{{selectedItem.duration|minutes}} minutes</td>
    </tr>
    <tr ng-hide="item.proposed">
      <td >Actual:</td>
      <td ng-style="timerStyleComplete(item)">{{selectedItem.timerTotal|minutes}} minutes &nbsp; &nbsp; 
            <span ng-hide="item.timerRunning">
                <button ng-click="agendaStartButton(item)"><i class="fa fa-clock-o"></i> Start</button>
            </span>
            <span ng-show="item.timerRunning">
                <button ng-click="stopAgendaRunning()"><i class="fa fa-clock-o"></i> Stop</button>
            </span> &nbsp; &nbsp; 
            <span> Remaining: {{item.duration - item.timerTotal| minutes}}</span>
      </td>
    </tr>
    <tr ng-show="item.proposed">
      <td >Proposed:</td>
      <td ng-style="timerStyleComplete(item)">This item is proposed, and not accepted yet.  
          <button ng-click="toggleProposed(selectedItem)" class="btn btn-primary btn-raised"
                  ng-show="selectedItem.proposed">
              <i class="fa fa-check"></i> Accept Proposed Item</a></button>
      </td>
    </tr>
    <tr  ng-hide="selectedItem.isSpacer">
      <td >Topics:</td>
      <td>
          <div ng-repeat="topic in itemTopics(selectedItem)" class="btn btn-sm btn-default btn-raised"  
                style="margin:4px;max-width:200px;overflow: hidden"
            ng-click="navigateToTopic(topic.universalid)">
            <i class="fa fa-lightbulb-o" style="font-size:130%"></i> {{topic.subject}}
          </div>
      </td>
    </tr>
    <tr ng-hide="selectedItem.isSpacer">
      <td class="labelColumn" >Ready:</td>
      <td>
        <span ng-hide="selectedItem.readyToGo" >
            <img src="<%=ar.retPath%>assets/goalstate/agenda-not-ready.png"
                 title="Indicates that the agenda item does NOT have all of the documents, presentations, and is full prepared for the meeting."
                 style="width:24px;height=24px">
                 Not ready yet.
        </span>
        <span ng-show="selectedItem.readyToGo"  >
            <img src="<%=ar.retPath%>assets/goalstate/agenda-ready-to-go.png"
                 title="Indicates that the agenda item has all of the documents, presentations, and is full prepared for the meeting."
                 style="width:24px;height=24px">
                 Ready to go.  Presentation attached (if any).
        </span>
      </td>
    </tr>
    </table>
    <table style="max-width:800px">
      <tr ng-repeat="cmt in selectedItem.comments"  ng-hide="selectedItem.isSpacer">

          <%@ include file="/spring/jsp/CommentView.jsp"%>

      </tr>

      <tr  ng-hide="selectedItem.isSpacer">
        <td></td>
        <td>
        <div style="margin:20px;">
            <button ng-click="openMeetingComment(selectedItem, 1)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-comments-o"></i> Comment</button>
            <button ng-click="openMeetingComment(selectedItem, 2)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-star-o"></i> Proposal</button>
            <button ng-click="openMeetingComment(selectedItem, 3)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-question-circle"></i> Round</button>
        </div>
        </td>
      </tr>
    </table>

</td>
</tr></table>


