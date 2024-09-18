

    <div class="container-fluid col-12">
      <div class="row d-flex" ng-dblclick="openAgenda(item)">
        <span ng-click="openAgenda(item)"></span>
        <span class="col-7" ng-style="timerStyleComplete(item)"><h3 class="h4 text-secondary">
          <span ng-hide="item.isSpacer" >{{item.number}}. </span>{{item.subject}}</h3></span>
          <span class="col-5"><em><a class="h5 text-secondary" href="{{meeting.conferenceUrl}}" target="_blank">Click Here to Join the Meeting Conference Call</a></em></span>

      </div>
      <div class="row d-flex">
        <div class="col-md-7">
          <div ng-dblclick="openAgendaControlled(item,'Description')" ng-show="!item.isSpacer" class="description-container">
            <div class="border border-2 border-primary-subtle py-2 px-4 m-4 " ng-bind-html="item.descriptionHtml"></div>
            <span ng-hide="item.descriptionHtml && item.descriptionHtml.length>3" class="doubleClickHint">
            Double-click to edit description
            </span>
          </div>
        </div>
        <div class="col-md-5">
          <div class="timers" >
            <div class="row g-1">
              <span class="col-md-5 me-3">
                <div class="m-2 py-2 fixed-width-sm text-center shadow" id="statusMenu" style="{{meetingStateStyle(meeting.state)}}"><i class="fa fa-clock-o fa-2x"></i><br>
                  {{meetingStateName()}} Mode
                </div>
                  
                          <span ng-hide="item.timerRunning">
                    <button class="btn-startTime btn-raised mx-2 my-3" ng-click="agendaStartButton(item)">Start</button>
                </span>
                <span ng-show="item.timerRunning">
                    <button class="btn-endTime btn-raised mx-2 my-3" ng-click="stopAgendaRunning()"><i class="fa fa-clock-o"></i> Stop</button>
                </span>

              
              </span>
              
              <span class="col-md-6">

                <div ng-click="openAgenda(item)" ng-hide="item.isSpacer">
                  <div class="mt-2" ng-hide="item.presenterList && item.presenterList.length>0"><b>Add Presenter</b>
                  </div>                 
                  
                  <div class="ps-0 mt-2" ng-repeat="presenter in item.presenterList">
                    <ul class="navbar-btn ps-3" >
                      <span class="fs-6 fw-bold mb-2" ng-click="openAgenda(item)"></span>
                      <li class="nav-item dropdown" id="presenter" data-toggle="dropdown"> 
                        <img class="rounded-5" ng-src="<%=ar.retPath%>icon/{{presenter.key}}.jpg" style="width:32px;height:32px" title="{{presenter.name}} - {{presenter.uid}}"> &nbsp; {{presenter.name}}
                        <ul class="dropdown-menu" role="menu" aria-labelledby="presenter">
                          <li style="background-color:lightgrey"><a class="dropdown-item" role="menuitem" tabindex="-1" >{{presenter.name}}<br/>{{presenter.uid}}</a>
                        </li>
                        <li>
                          <a class="dropdown-item" role="menuitem" tabindex="-1" ng-click="navigateToUser(presenter)">
                          <span class="fa fa-user"></span> Visit Profile</a>
                        </li>
                      </ul>
                    </li>
                    </ul>
                  </div>
                  <hr>
                  <div class="container px-3 gy-5">
                  <span class="h6 ms-0 fst-italic pb-5"  ng-show="meeting.state>=2">
                    item time remaining: {{item.duration - item.timerTotal| minutes}}
                  </span> <hr class="my-0">
                  <span class="h6 mt-2 ms-0 push-right"  ng-show="meeting.state>=2">
                    elapsed duration: <br>{{meeting.timerTotal|minutes}}  (meeting) 
                  </span>
                </div>
                 
                </div>

              </span>
                              
            </div>
            <div ng-dblclick="item.readyToGo = ! item.readyToGo"  ng-hide="item.isSpacer" >
              <div class="justify-content-center ms-2 mb-3 mt-2" ng-click="item.readyToGo = ! item.readyToGo">
              <span class="btn btn-comment mt-0" ng-hide="item.readyToGo" >
                  <b>Not <img src="<%=ar.retPath%>new_assets/assets/goalstate/agenda-not-ready.png"
                       title="Indicates that the agenda item does NOT have all of the documents, presentations, and is full prepared for the meeting."
                       style="width:24px;height:24px">
                        Ready</b>
              </span>
              <span class="btn-comment btn-wide py-2 " ng-show="item.readyToGo"  >
                  <b>Ready <img src="<%=ar.retPath%>new_assets/assets/goalstate/agenda-ready-to-go.png"
                       title="Indicates that the agenda item has all of the documents, presentations, and is full prepared for the meeting." style="width:24px;height:24px"> To Go </b>
                         Presentation attached (if any)
              </span></div>
            </div>
          </div>
          
      </div>
    
      <hr/>
      <!--Minutes and Notes-->
      <div class="row px-3">
    <!-- Column 1 -->
      <div class="col-md-6 col-sm-12">
      <!--Current Meeting Minutes - top of first column-->
      <div class="card my-2" ng-dblclick="openNotesDialog(item)">
        <div class="d-flex card-header" title="Current Meeting Minutes">
          <span ng-hide="item.isSpacer">
            <h4 class="h6" >Current Meeting Minutes</h4>
          </span>
          
        </div><!--END Current Meeting Minutes card header-->
        <div class="card-body">
          <div ng-hide="item.isSpacer">
            <div class="modal-body" ng-style="bodyStyle()">
              <div class="form-group" >
                <div>                
                  <div ng-bind-html="item.minutes | wiki"></div>
                </div>
              </div>
            </div>
          </div>
        </div><!--END Current Meeting Minutes card body-->
      </div><!--END Current Meeting Minutes card-->
      </div>
    <!-- Column 2 -->
      <div class="col-md-6 col-sm-12">
        <!--Previous Meeting Minutes - top of second column-->
        <div class="card my-2">
          <div class="d-flex card-header" title="Minutes from last meeting">
            <span ng-hide="item.isSpacer">
              <h4 class="h6" ng-click="copyNotes(item)">Last Meeting Minutes</h4>
            </span>
          </div><!--END Previous Meeting Minutes card header-->
          <div class="card-body">
            <div ng-hide="item.isSpacer">
              <div class="modal-body" ng-style="bodyStyle()">
                <div class="form-group">  
                  <span ng-click="copyNotes(item)">
                    <div ng-bind-html="item.lastMeetingMinutes | wiki"></div>
                  </span>
                </div>
              </div>
            </div>
          </div><!--END Precious Meeting Minutes card body-->
        </div><!--END Precious Meeting Minutes card-->
      </div>
      </div><!--END Minutes and Notes-->
      <hr/>
    <!--Assets Section-->
  <div class="container">
    <div class="row justify-content-center">
    <!--Action Items-->
    <div class="col-md-4">
      <div ng-hide="item.isSpacer">
        <div class="accordion accordionAssets" 
        id="accordionActionItems">
        <div class="accordion-item">
          <div class="h6 accordion-header" id="headingActionItems">
          <div class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseActionItems" aria-expanded="false" aria-labelledby="collapseActionItems" aria-controls="collapseActionItems">
            <i class="fa fa-check-circle-o"></i> &nbsp;Action Items:</div> 
          </div>
          <div id="collapseActionItems" class="accordion-collapse collapse" aria-labelledby="headingActionItems" data-bs-parent="#accordionActionItems">
          <div class="accordion-body">
            <div class="mb-2" ng-repeat="goal in itemGoals(item)">
                <a href="task{{goal.id}}" class="me-2" title="access action item details">
                  <img ng-src="<%=ar.retPath%>assets/goalstate/small{{goal.state}}.gif"></a>
                <span class="me-2" ng-click="openModalActionItem(item, goal)">{{goal.synopsis}}
                </span>
                <span class="ms-auto" ng-repeat="person in goal.assignTo">
                  <span class="dropdown" >
                    <span id="menuMbrs" data-toggle="dropdown">
                      <img class="rounded-5" ng-src="<%=ar.retPath%>icon/{{person.key}}.jpg" style="width:32px;height:32px" title="{{person.name}} - {{person.uid}}">
                    </span>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menuMbrs">
                      <li role="presentation" class="bg-secondary-10"><a role="menuitem" tabindex="-1">{{person.name}}<br/>{{person.uid}}</a></li>
                      <li role="presentation" style="cursor:pointer">
                        <a role="menuitem" tabindex="-1" ng-click="navigateToUser(person)">
                        <span class="fa fa-user"></span> Visit Profile
                        </a>
                      </li>
                    </ul>
                  </span>
                </span>
                <div ng-click="openModalActionItem(item, goal)">
                <span>{{goal.status}}</span>
                <div ng-repeat="ci in coal.checkitems">
                  <span ng-click="toggleCheckItem($event, goal, ci.index)" style="cursor:pointer">
                    <span ng-show="ci.checked"><i class="fa  fa-check-square-o"></i></span>
                    <span ng-hide="ci.checked"><i class="fa  fa-square-o"></i></span>&nbsp; 
                  </span>{{ci.name}}
                </div>
                </div>
            </div>
        <!--Button to create new action item-->
        <div class="container-fluid">
        <div class="row justify-content-center">      
          <div type="button" class="btn btn-sm btn-outline-primary"><span ng-click="openAttachAction(item)"> Attach/Remove Action Items 
          </span>
        </div>
        </div>
        <!--END Buttons to trigger action item modals -->

      </div>
          </div><!--END accordion body-->
        </div>
        </div><!--END Action Items accordion-->
      </div>
    </div>
    </div><!--END Action Items-->

    <!--Documents/Attachment-->
    <div class="col-md-4">
      <div ng-hide="item.isSpacer">
        <div class="accordion accordionAssets" id="accordionAttachments">
        <div class="accordion-item" >
          <div class="h6 accordion-header" id="headingAttachments">
          <div class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseAttachments" aria-expanded="false" aria-labelledby="collapseAttachments" aria-controls="collapseAttachments"><i class="fa fa-paperclip"></i> &nbsp; Files:</div>
          </div>
          <div id="collapseAttachments" class="accordion-collapse collapse" aria-labelledby="headingAttachments" data-bs-parent="#accordionAttachments">
            <div class="accordion-body">
              <div class="mb-2" ng-repeat="docid in item.docList track by $index">
                <div ng-repeat="fullDoc in getSelectedDocList(docid)"> 
                  <span ng-click="navigateToDoc(fullDoc.id)" title="access attachment">
                    <img src="<%=ar.retPath%>new_assets/assets/images/iconFile.png" ng-show="fullDoc.attType=='FILE'">
                    <img src="<%=ar.retPath%>new_assets/assets/images/iconUrl.png" ng-show="fullDoc.attType=='URL'">
                  </span> &nbsp;
                  <span ng-click="downloadDocument(fullDoc)" title="download attachment">
                    <span class="fa fa-external-link" ng-show="fullDoc.attType=='URL'"></span>
                    <span class="fa fa-download" ng-hide="fullDoc.attType=='URL'"></span>
                  </span> &nbsp; 
                  {{fullDoc.name}}
                </div>
              </div>
              <div ng-hide="item.docList && item.docList.length>0" class="doubleClickHint">
              </div>
      <!-- Buttons to trigger Documents modals -->
      <div class="container-fluid">
      <div class="row justify-content-center"> 
        <div type="button" class="btn btn-sm btn-outline-primary">
          <span ng-click="openAttachDocument(item)">  Attach/Upload Files</span>
        </div>
      </div>
      </div>



            </div>
          </div>
        </div>
        </div>
      </div>
    </div><!--END Documents/Attachment-->

    <!--Discussion-->
      <div class="col-md-4">
      <div ng-hide="item.isSpacer">
        <div class="accordion accordionAssets" 
      id="accordionForum">
      <div class="accordion-item">
        <div class="h6 accordion-header" id="headingForum">
          <div class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseForum" aria-expanded="false" aria-labelledby="headingForum" aria-controls="collapseForum"><i class="fa fa-lightbulb-o"></i>&nbsp;Discussions:
          </div>
        </div>
        <div id="collapseForum" class="accordion-collapse collapse" data-bs-parent="#accordionForum">

          <div class="accordion-body">
            <div class="row d-flex mb-2 ms-0" 
            ng-repeat="topic in itemTopics(item)" style="cursor: pointer">
            <span ng-click="navigateToTopic(topic.universalid)" ><i class="fa fa-lightbulb-o fs-5" ></i>&nbsp;
            {{topic.subject}}</span>
          </div>
            <div ng-hide="itemTopics(item).length>0" class="doubleClickHint">
          </div>
<!-- Button trigger modal -->
          <div class="container-fluid">
  <div class="row justify-content-center ">      
    <div type="button" class="btn btn-sm btn-outline-primary">
      <span ng-click="openAttachTopics(item)"> Attach/Remove Discussions 
    </span>
  </div>
  </div>
<!-- ForumModal -->
          </div>
        </div><!--END accordion body-->
        </div>
      </div>  
      </div><!--END Forum-->
    </div><!--END Assets Row-->
  </div><!--END Assets Section-->
  <div>&nbsp;</div>
  <hr/>
  <!--Create Comment/Proposal/Round Row-->
  <div class="row row-md-cols-3">



      <div class="d-flex col-sm-12 mb-3">
          <button ng-click="openMeetingComment(item, 1)" class="btn-comment btn-wide btn-raised px-3 mx-2 my-3">
              Create New <i class="fa fa-comments-o"></i> Comment</button>
          <button ng-click="openMeetingComment(item, 2)" class="btn-comment btn-wide btn-raised px-3 mx-2 my-3">
              Create New <i class="fa fa-star-o"></i> Proposal</button>
          <button ng-click="openMeetingComment(item, 3)" class="btn-comment btn-wide btn-raised px-3 mx-2 my-3">
              Create New <i class="fa fa-question-circle"></i> Round</button>
          <button ng-click="openAgenda(item)" class="btn btn-primary btn-raised ms-auto my-md-3 my-sm-3">
            Edit Agenda Item</button>
      </div>

      
  </div> <hr/>
      <div ng-repeat="cmt in item.comments"  ng-hide="item.isSpacer">

        <%@ include file="/spring2/jsp/CommentView.jsp"%>

    </div>
  <!--END Create Comment/Proposal/Round Row-->




    <div ng-hide="item">
        <div class="guideVocal">
            Create an agenda item for the meeting use the "+ New" button on the left.
        </div>
    </div>
    </div>
    </div> 
   
    
  