
<div class="container-fluid">
    <h2 class="h3 page-name text-secondary">Agenda:</h2>

    <div class="container-fluid">
      <div class="row" ng-dblclick="openAgenda(item)">
        <span ng-click="openAgenda(item)"></span>
        <span ng-style="timerStyleComplete(item)"><h3 class="h4 text-secondary">
          <span ng-hide="item.isSpacer" >{{item.number}}. </span>{{item.subject}}</h3></span>
      </div>
      <div class="row">
        <div class="col-md-7">
          <div ng-dblclick="openAgendaControlled(item,'Description')" ng-show="!item.isSpacer" class="description-container">
            <h4 ng-click="openAgendaControlled(item,'Description')" class="h6 mb-auto">Description: </h4>
            <div class="p pt-4 flex-grow-1" ng-bind-html="item.descriptionHtml"></div>
            <span ng-hide="item.descriptionHtml && item.descriptionHtml.length>3" class="doubleClickHint">
            Double-click to edit description
            </span>
          </div>
        </div>
        <div class="col-md-5">
          <div class="timers" >
            <div class="row g-1 justify-content-between">
              <span class="col-md-5">
                <div class="m-2 py-2 fixed-width-sm text-center shadow" id="statusMenu" data-toggle="dropdown" style="{{meetingStateStyle(meeting.state)}}" ng-click="displayMode='Status'"><i class="fa fa-clock-o fa-2x"></i><br>
                  {{meetingStateName()}} Mode
                </div>
                          <span ng-hide="item.timerRunning">
                    <button class="btn-startTime btn-raised mx-2 my-3" ng-click="agendaStartButton(item)">Start</button>
                </span>
                <span ng-show="item.timerRunning">
                    <button class="btn-endTime btn-raised mx-2 my-3" ng-click="stopAgendaRunning()"><i class="fa fa-clock-o"></i> Stop</button>
                </span>
              
              
              </span>
              
              <span class="col-md-7">

                <div ng-click="openAgenda(item)" ng-hide="item.isSpacer">
                  <div ng-hide="item.presenterList && item.presenterList.length>0">
                  </div>
                  <div class="border-0 border shadow py-1 m-2 bg-weaverbody rounded">
                  <div type="button" class="btn btn-wide btn-raised btn-primary text-weaverbody px-md-4 mx-md-4 my-2 mx-sm-2">
                    <span ng-click="openAgenda(item)"></span> 
                    Edit Agenda Item
                  </div>                  
                  <div ng-repeat="presenter in item.presenterList">
                    <ul class="navbar-btn" >
                      <span class="fs-6 fw-bold mb-2" ng-click="openAgenda(item)">Presenter:</span>
                      <li class="nav-item dropdown" id="presenter" data-toggle="dropdown"> 
                        <img class="img-circle" ng-src="<%=ar.retPath%>icon/{{presenter.key}}.jpg" style="width:32px;height:32px" title="{{presenter.name}} - {{presenter.uid}}"> &nbsp; {{presenter.name}}
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
                  </div>
                  <span class="h6 ms-1"  ng-show="meeting.state>=2">
                    elapsed duration: {{meeting.timerTotal|minutes}}
                  </span>
                  <br>
                  <span class="h6 ms-1 fst-italic"  ng-show="meeting.state>=2">
                    time remaining: {{item.duration - item.timerTotal| minutes}}
                  </span>
                  <!-- button to select timer
                  <ul type="button" class="btn btn-raised btn-primary text-weaverbody mx-2 mb-3" >
                    <li class="nav-item dropdown">
                      <a id="timerSelect" role="button" data-bs-toggle="dropdown" aria-expanded="false"><i class="fa fa-clock-o"></i>&nbsp;&nbsp; Select Timer</a>
                      <ul class="dropdown-menu">
                        <li><a class="dropdown-item" ng-click="#">Count-up Timer<span class="timerStyleComplete"><br>Actual Time:
                          <span ng-style="timerStyleComplete(item)">{{item.timerTotal|minutes}} </span></span></a></li>
                          <li><a class="dropdown-item" ng-click="#">Count-down Timer<span class="timerStyleComplete"> <br>Remaining Time: <span ng-style="timerStyleComplete(item)"> {{item.duration - item.timerTotal| minutes}}</span></span></a>
                        </li>
                      </ul>
                    </li> 
                  </ul>-->
                </div>
              </span>
            </div>
        </div>
      </div>
    
      <hr/>
      <!--Minutes and Notes-->
      <div class="row px-3">
    <!-- Column 1 -->
      <div class="col-md-6 col-sm-12">
      <!--Current Meeting Minutes - top of first column-->
      <div class="card my-2">
        <div class="d-flex card-header" title="Current Meeting Minutes">
          <span ng-hide="item.isSpacer">
            <h4 class="h6" ng-click="openNotesDialog(item)">Current Meeting Minutes</h4>
          </span>
          
        </div><!--END Current Meeting Minutes card header-->
        <div class="card-body">
          <div ng-hide="item.isSpacer">
            <div class="modal-body" ng-style="bodyStyle()">
              <div class="form-group" >
                <span ng-click="openNotesDialog(item)">
                  <label for="labels">Status:</label>
                
                  <div ng-bind-html="item.minutes | wiki"></div>
                </span>
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
                      <img class="img-circle" ng-src="<%=ar.retPath%>icon/{{person.key}}.jpg" style="width:32px;height:32px" title="{{person.name}} - {{person.uid}}">
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
        <div class="row py-3 ">      
          <div type="button" class="btn btn-sm btn-outline-primary"><span ng-click="openAttachAction(item)"> Attach/Remove Action Items 
          </span>
        </div>
        </div>
        <!--END Buttons to trigger action item modals -->

      </div><!--END Action Items card body-->
          </div>
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
          <div class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseAttachments" aria-expanded="false" aria-labelledby="collapseAttachments" aria-controls="collapseAttachments"><i class="fa fa-paperclip"></i> &nbsp; Attachments:</div>
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
              <div ng-hide="item.docList && item.docList.length>0" class="doubleClickHint">Double-click to add / remove attachments
              </div>
      <!-- Buttons to trigger Documents modals -->
      <div class="container-fluid">
      <div class="row justify-content-center"> 
        <div type="button" class="btn btn-sm btn-outline-primary"><span ng-click="openAttachDocument(item)">  Attach/Upload Assets</span>
        </div>

      </div>
      </div>



            </div>
          </div>
        </div>
        </div>
      </div>
    </div><!--END Documents/Attachment-->

    <!--Forum-->
      <div class="col-md-4">
      <div ng-hide="item.isSpacer">
        <div class="accordion accordionAssets" 
      id="accordionForum">
      <div class="accordion-item">
        <div class="h6 accordion-header" id="headingForum">
          <div class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseForum" aria-expanded="false" aria-labelledby="headingForum" aria-controls="collapseForum"><i class="fa fa-lightbulb-o"></i>&nbsp;Forum:
          </div>
        </div>
        <div id="collapseForum" class="accordion-collapse collapse" data-bs-parent="#accordionForum">

          <div class="accordion-body">
            <div class="row d-flex mb-2 ms-0" 
            ng-repeat="topic in itemTopics(item)" style="cursor: pointer">
            <span ng-click="navigateToTopic(topic.universalid)" ><i class="fa fa-lightbulb-o fs-5" ></i>&nbsp;
            {{topic.subject}}</span></div>
            <div ng-hide="itemTopics(item).length>0" class="doubleClickHint">
              Double-click to set or unset linked topic
          </div>
<!-- Button trigger modal -->
<div class="container-fluid">
  <div class="row py-3 ">      
    <div type="button" class="btn btn-sm btn-outline-primary"><span ng-click="openAttachTopics(item)"> Attach/Remove Discussion Forums 
    </span>
  </div>
  </div>
<!-- ForumModal -->
            <div class="modal fade" id="attachForum" data-bs-backdrop="static" data-bs-keyboard="false" tabindex="-1" aria-labelledby="attachForumLabel" aria-hidden="true">
  <div class="modal-dialog modal-xl">
    <div class="modal-content">
      <div class="modal-header">
        <h4 class="modal-title" id="attachForumLabel">Link to Forum Discussions</h4>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <div class="container-fluid">
          <div class="row">
            <div class="col-6">
              <div class="card my-2 border-1"> 
                <div class="d-flex card-header" title="Existing Topics-Filter">
                Existing Topics - Filter &nbsp;<input type="text" ng-model="realDocumentFilter">
                </div>
                <div class="card-body">
                  <div class="docTable">
                    <div ng-repeat="doc in filterDocs()" ng-click="addTopicToItem(doc)" style="cursor:pointer"
                    title="Click to link to this topic">
                      <span> {{doc.subject}} </span>
                      <span>
                        <button ng-hide="itemHasDoc(doc)"
                            class="btn" >&nbsp; <i class="fa fa-arrow-right"></i></button>
                        <button ng-show="itemHasDoc(doc)"
                            class="btn">&nbsp; &nbsp;</button>
                      </span>
                    </div>
                    <div ng-show="filterDocs().length==0">
                      <span class="instruction">No topics to choose from.<br/><br/>Filter: {{realDocumentFilter}}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="col-6">
              <div class="card my-2 border-1">
                <div class="d-flex card-header" title="Selected Topics"> 
                Selected Topics
                </div>
                <div class="car-body">
                  <div class="docTable">
                    <div ng-repeat="topic in fullTopics" ng-click="removeTopicFromItem(topic)" 
                    title="Click to unlink the discussion topic"  style="cursor:pointer">
                    <span> {{topic.subject}} </span>
                    <span>
                        <button class="btn"><i class="fa fa-close"></i> &nbsp;</button>
                    </span>
                    </div>
                    <div ng-show="fullTopics.length==0">
                    <span class="instruction">No topic linked..<br/><br/>
                    <span ng-show="filterDocs().length>0">Click on an topic on the left, to set it here on the right.  Since only one can be linked it will replace whatever was linked before.</span></span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      
      <div class="modal-footer">
        <button type="button" class="btn btn-danger me-auto" data-bs-dismiss="modal">Close</button>
        <button type="button" class="btn btn-primary">Attach Forum Discussions</button>
      </div>
    </div>
    </div>
  </div>
            </div>
<div>&nbsp;</div>
          </div><!--END accordion body-->
        </div>
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
          <button ng-click="openMeetingComment(item, 1)" class="btn-comment btn-raised mx-2 my-md-3 my-sm-3">
              Create New <i class="fa fa-comments-o"></i> Comment</button>
          <button ng-click="openMeetingComment(item, 2)" class="btn-comment btn-raised mx-2 my-md-3 my-sm-3">
              Create New <i class="fa fa-star-o"></i> Proposal</button>
          <button ng-click="openMeetingComment(item, 3)" class="btn-comment btn-raised mx-2 my-md-3 my-sm-3">
              Create New <i class="fa fa-question-circle"></i> Round</button>
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
   
    
  