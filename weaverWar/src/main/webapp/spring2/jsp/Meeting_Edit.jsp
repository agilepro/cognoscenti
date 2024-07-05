
<div>
    <table class="table">
    <col width="150">
    <tr ng-show="meeting.state<=1">
      <td></td>
      <td>
          <button ng-click="toggleSpacer(item)" class="btn btn-primary btn-raised">
              <i class="fa fa-check-circle" ng-show="item.isSpacer"></i> 
              <i class="fa fa-circle-o" ng-hide="item.isSpacer"></i> Break Time</button>
          <button ng-click="moveItem(item,-1)" class="btn btn-primary btn-raised"
                  ng-hide="item.proposed">
              <i class="fa fa-arrow-up"></i> Move Up</a></li></button>
          <button ng-click="moveItem(item,1)" class="btn btn-primary btn-raised"
                  ng-hide="item.proposed">
              <i class="fa fa-arrow-down"></i> Move Down</a></li></button>
          <button ng-click="toggleProposed(item)" class="btn btn-primary btn-raised"
                  ng-show="item.proposed">
              <i class="fa fa-check"></i> Accept Proposed Item</a></li></button>
          <button ng-click="toggleProposed(item)" class="btn btn-primary btn-raised"
                  ng-hide="item.proposed">
              <i class="fa fa-reply"></i> Send to Backlog</a></li></button>
      </td>
    </tr>
    <tr ng-dblclick="openAgenda(item)">
      <td ng-click="openAgenda(item)" class="labelColumn">Subject:</td>
      <td ng-style="timerStyleComplete(item)"><span class="h2">
          <span ng-hide="item.isSpacer" >{{item.number}}. </span>{{item.subject}}</span></td>
    </tr>
    <tr ng-dblclick="openAgendaControlled(item,'Description')" ng-show="!item.isSpacer">
      <td ng-click="openAgendaControlled(item,'Description')" class="labelColumn">Description:</td>
      <td>
        <div ng-bind-html="item.descriptionHtml"></div>
        <div ng-hide="item.descriptionHtml && item.descriptionHtml.length>3" class="doubleClickHint">
            Double-click to description
        </div>
      </td>
    </tr>
    <tr ng-hide="item.isSpacer || !item.lastMeetingMinutes"  style="color: #888">
      <td class="labelColumn" ng-click="copyNotes(item)">Notes from last meeting:</td>
      <td ng-dblclick="copyNotes(item)">
        <div ng-bind-html="item.lastMeetingMinutes | wiki"></div>
      </td>
    </tr>
    <tr ng-hide="item.isSpacer">
      <td class="labelColumn" ng-click="openNotesDialog(item)">Notes/Minutes:</td>
      <td ng-dblclick="openNotesDialog(item)">
        <div ng-bind-html="item.minutes | wiki"></div>
        <div ng-hide="item.minutes" class="doubleClickHint">
            Double-click to edit notes
        </div>
      </td>
    </tr>
    <tr ng-hide="item.isSpacer">
      <td ng-click="openAttachAction(item)" class="labelColumn">Action Items:</td>
      <td title="double-click to modify the action items">
          <table class="table">
          <tr ng-repeat="goal in itemGoals(item)">
              <td>
                <a href="task{{goal.id}}.htm" title="access action item details">
                   <img ng-src="<%=ar.retPath%>assets/goalstate/small{{goal.state}}.gif"></a>
              </td>
              <td ng-dblclick="openModalActionItem(item, goal)">
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
              <td ng-dblclick="openModalActionItem(item, goal)">
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
          <div ng-hide="itemGoals(item).length>0" class="doubleClickHint">
              Double-click to add / remove action items
          </div>
      </td>
    </tr>
    <tr ng-hide="item.isSpacer">
      <td ng-click="openAttachDocument(item)" class="labelColumn">Attachments:</td>
      <td title="double-click to modify the attachments">
          <div ng-repeat="docid in item.docList track by $index" style="vertical-align: top">
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
          <div ng-hide="item.docList && item.docList.length>0" class="doubleClickHint">
              Double-click to add / remove attachments
          </div>
       </td>
    </tr>
    <tr  ng-dblclick="openAgenda(item)" ng-hide="item.isSpacer">
      <td ng-click="openAgenda(item)" class="labelColumn">Presenter:</td>
      <td>
        <div ng-repeat="presenter in item.presenterList">
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
        <div ng-hide="item.presenterList && item.presenterList.length>0" class="doubleClickHint">
            Double-click to set presenter
        </div>
      </td>
    </tr>
    <tr ng-dblclick="openAgenda(item)" ng-hide="item.proposed">
      <td ng-click="openAgenda(item)" class="labelColumn">Planned:</td>
      <td>{{item.duration|minutes}} minutes</td>
    </tr>
    <tr ng-dblclick="openAgenda(item)"  ng-hide="item.proposed">
      <td ng-click="openAgenda(item)" class="labelColumn">Actual:</td>
      <td ng-style="timerStyleComplete(item)">{{item.timerTotal|minutes}} minutes &nbsp; &nbsp; 
            <span ng-hide="item.timerRunning">
                <button ng-click="agendaStartButton(item)"><i class="fa fa-clock-o"></i> Start</button>
            </span>
            <span ng-show="item.timerRunning">
                <button ng-click="stopAgendaRunning()"><i class="fa fa-clock-o"></i> Stop</button>
            </span> &nbsp; &nbsp; 
            <span> Remaining: {{item.duration - item.timerTotal| minutes}}</span>
      </td>
    </tr>
    <tr ng-dblclick="openAgenda(item)" ng-show="item.proposed">
      <td ng-click="openAgenda(item)" class="labelColumn">Proposed:</td>
      <td ng-style="timerStyleComplete(item)">This item is proposed, and not accepted yet.  
          <button ng-click="toggleProposed(item)" class="btn btn-primary btn-raised"
                  ng-show="item.proposed">
              <i class="fa fa-check"></i> Accept Proposed Item</a></button>
      </td>
    </tr>
    <tr ng-dblclick="openAttachTopics(item)" ng-hide="item.isSpacer">
      <td ng-click="openAttachTopics(item)" class="labelColumn">Topics:</td>
      <td>
          <div ng-repeat="topic in itemTopics(item)" class="btn btn-sm btn-default btn-raised"  
                style="margin:4px;max-width:200px;overflow: hidden"
            ng-click="navigateToTopic(topic.universalid)">
            <i class="fa fa-lightbulb-o" style="font-size:130%"></i> {{topic.subject}}
          </div>
          <div ng-hide="itemTopics(item).length>0" class="doubleClickHint">
              Double-click to set or unset linked topic
          </div>
      </td>
    </tr>
    <tr ng-dblclick="item.readyToGo = ! item.readyToGo"  ng-hide="item.isSpacer">
      <td class="labelColumn" ng-click="item.readyToGo = ! item.readyToGo">Ready:</td>
      <td>
        <span ng-hide="item.readyToGo" >
            <img src="<%=ar.retPath%>assets/goalstate/agenda-not-ready.png"
                 title="Indicates that the agenda item does NOT have all of the documents, presentations, and is full prepared for the meeting."
                 style="width:24px;height=24px">
                 Not ready yet.
        </span>
        <span ng-show="item.readyToGo"  >
            <img src="<%=ar.retPath%>assets/goalstate/agenda-ready-to-go.png"
                 title="Indicates that the agenda item has all of the documents, presentations, and is full prepared for the meeting."
                 style="width:24px;height=24px">
                 Ready to go.  Presentation attached (if any).
        </span>
      </td>
    </tr>
    </table>
    <table style="max-width:800px">
      <tr ng-repeat="cmt in item.comments"  ng-hide="item.isSpacer">

          <%@ include file="/spring/jsp/CommentView.jsp"%>

      </tr>

      <tr  ng-hide="item.isSpacer">
        <td></td>
        <td>
        <div style="margin:20px;">
            <button ng-click="openMeetingComment(item, 1)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-comments-o"></i> Comment</button>
            <button ng-click="openMeetingComment(item, 2)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-star-o"></i> Proposal</button>
            <button ng-click="openMeetingComment(item, 3)" class="btn btn-default btn-raised">
                Create New <i class="fa fa-question-circle"></i> Round</button>
        </div>
        </td>
      </tr>
    </table>
    <div ng-hide="item">
        <div class="guideVocal">
            Create an agenda item for the meeting use the "+ New" button on the left.
        </div>
    </div>

</div>


