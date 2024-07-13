
<div class="container-fluid">
    <h2 class="h3 page-name text-secondary">Agenda:</h2>

    <div class="container-fluid">
      <div class="row" ng-dblclick="openAgenda(item)">
        <span ng-click="openAgenda(item)"></span>
        <span ng-style="timerStyleComplete(item)"><h3 class="h4 text-secondary">
          <span ng-hide="item.isSpacer" >{{item.number}}. </span>{{item.subject}}</h3></span>
      </div>
      <div class="row">
        <div class="col-7">
          <div ng-dblclick="openAgendaControlled(item,'Description')" ng-show="!item.isSpacer" class="description-container">
            <h4 ng-click="openAgendaControlled(item,'Description')" class="h6 mb-auto">Description: </h4>
            <div class="p pt-4 flex-grow-1" ng-bind-html="item.descriptionHtml"></div>
            <span ng-hide="item.descriptionHtml && item.descriptionHtml.length>3" class="doubleClickHint">
            Double-click to edit description
            </span>
          </div>
        </div>
        <div class="col-5">
          <div class="timers" >
            <div class="row g-1 justify-content-between">
              <span class="col-6">
                <div class="m-2 pt-2 fixed-width-sm" id="statusMenu" data-toggle="dropdown" style="{{meetingStateStyle(meeting.state)}}" ng-click="displayMode='Status'"><i class="fa fa-clock-o fa-2x"></i><br>
                  {{meetingStateName()}} Mode
                          <span ng-hide="item.timerRunning">
                    <button class="btn fixed-width-sm" ng-click="agendaStartButton(item)">Start</button>
                </span>
                <span ng-show="item.timerRunning">
                    <button class="btn fixed-width-sm" ng-click="stopAgendaRunning()"><i class="fa fa-clock-o"></i> Stop</button>
                </span>
              </div>
              
              </span>

              <span class="col-6">

                <div ng-click="openAgenda(item)" ng-hide="item.isSpacer">
                  <div ng-hide="item.presenterList && item.presenterList.length>0">
                  </div>
                  <div type="button" class="btn btn-flex btn-raised btn-primary text-weaverbody"><span ng-click="openAgenda(item)"></span> <!--data-bs-toggle="modal" data-bs-target="#agendaItem"> --><i class="fa fa-user"></i> &nbsp;Select Presenter
                  </div>                  
                  <div class="my-2" ng-repeat="presenter in item.presenterList">
                    <span class="dropdown" >
                      <span id="menu1" data-toggle="dropdown">
                        <img class="img-circle" ng-src="<%=ar.retPath%>icon/{{presenter.key}}.jpg" style="width:32px;height:32px" title="{{presenter.name}} - {{presenter.uid}}">
                      </span>
                      <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                        <li role="presentation" style="background-color:lightgrey"><a role="menuitem" tabindex="-1" >{{presenter.name}}<br/>{{presenter.uid}}</a>
                        </li>
                        <li role="presentation" class="dropdown-item">
                          <a role="menuitem" tabindex="-1" ng-click="navigateToUser(presenter)">
                          <span class="fa fa-user"></span> Visit Profile</a>
                        </li>
                      </ul>
                    </span>
                      {{presenter.name}}
                  </div>
                  <ul class="navbar-nav ps-1 btn btn-flex btn-raised btn-primary text-weaverbody">
                    <li class="nav-item dropdown"><a class="nav-link dropdown-toggle" id="timerSelect" role="button" data-bs-toggle="dropdown" aria-expanded="false"><i class="fa fa-clock-o"></i> 
                      <span class="dropdown-toggle-label" translate>Set Timer</span></a>
                      <ul class="dropdown-menu">
                        <li><a class="dropdown-item" ng-click="timerStyleComplete(item)">Count-up Timer<span class="timerStyleComplete"><br>Actual Time:
                          <span ng-style="timerStyleComplete(item)">{{item.timerTotal|minutes}} </span></span></a></li>
                          <li><a class="dropdown-item" ng-click="timerStyleComplete(item)">Count-down Timer<span class="timerStyleComplete"> <br>Remaining Time: <span ng-style="timerStyleComplete(item)"> {{item.duration - item.timerTotal| minutes}}</span></span></a>
                        </li>
                      </ul>
                    </li> 
                  </ul>
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
                <label for="labels">Status:</label>
                <textarea ng-model="agendaData.new" class="form-control markDownEditor" style="height:250px;width:80%"
                placeholder="Enter meeting notes" ng-disabled="!isEditing"></textarea>
              </div>
            </div>
          </div>
          <div class="modal-footer">
              <button ng-hide="id=='~new~'" class="btn btn-warning btn-raised me-auto"
                  type="button" ng-click="ok()">Exit</button>
              <button ng-hide="agendaData.needsMerge" class="btn">
                  <input type="checkbox" ng-model="autoMerge"> Automatically Merge (danger)
              </button>
              <button ng-show="agendaData.needsMerge" class="btn btn-danger btn-raised"
                  type="button" ng-click="mergeNewData()"><i class="fa fa-exclamation-triangle"></i> Merge Changes from Others</button>
          </div>
        </div><!--END Current Meeting Minutes card body-->
      </div><!--END Current Meeting Minutes card-->
      </div>
    <!-- Column 2 -->
      <div class="col-md-6 col-sm-12">
        <!--Previous Meeting Minutes - top of second column-->
        <div class="card my-2">
          <div class="d-flex card-header" title="Minutes from last meeting">
            <span> <!--ng-hide="item.isSpacer || !item.lastMeetingMinutes">-->
              <h4 class="h6" ng-click="copyNotes(item)">Last Meeting Minutes</h4>
            </span>
            <span ng-dblclick="copyNotes(item)">
              <div ng-bind-html="item.lastMeetingMinutes | wiki"></div>
            </span>
          </div><!--END Precious Meeting Minutes card header-->
          <div class="card-body">
            <span ng-dblclick="copyNotes(item)">
              <div ng-hide="item.lastMeetingMinutes" class="doubleClickHint">
              Double-click to copy notes
              </div>
            </span>
          </div><!--END Precious Meeting Minutes card body-->
        </div><!--END Precious Meeting Minutes card-->
      </div>
      </div><!--END Minutes and Notes-->
      <hr/>
    <!--Assets Section-->
  <div class="container">
    <div class="row justify-content-center">
    <!--Action Items-->
    <div class="col-4">
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
    <div class="col-4">
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
      <div class="col-4">
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
  <div class="row row-cols-3">



      <div class="d-flex col-12 mb-3">
          <button ng-click="openMeetingComment(item, 1)" class="btn-comment btn-raised mx-2 my-md-3 my-sm-3">
              Create New <i class="fa fa-comments-o"></i> Comment</button>
          <button ng-click="openMeetingComment(item, 2)" class="btn-comment btn-raised mx-2 my-md-3 my-sm-3">
              Create New <i class="fa fa-star-o"></i> Proposal</button>
          <button ng-click="openMeetingComment(item, 3)" class="btn-comment btn-raised mx-2 my-md-3 my-sm-3">
              Create New <i class="fa fa-question-circle"></i> Round</button>
      </div>

     
  </div> <hr/>
      <div ng-repeat="cmt in item.comments"  ng-hide="item.isSpacer">

        <%@ include file="/spring/jsp/CommentView.jsp"%>

    </div>
  <!--END Create Comment/Proposal/Round Row-->




    <div ng-hide="item">
        <div class="guideVocal">
            Create an agenda item for the meeting use the "+ New" button on the left.
        </div>
    </div>

    </div>

  <!--Modals for meeting_edit.jsp-->

<!-- Agenda Item Modal 
    <div class="modal fade" id="agendaItem" data-bs-backdrop="static" data-bs-keyboard="false" tabindex="-1" aria-labelledby="agendaItemLabel" aria-hidden="true">
  <div class="modal-dialog modal-xl">
    <div class="modal-content">
      <div class="modal-header"><h4 class="modal-title" id="agendaItemLabel">Agenda Item Settings</h4>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <div class="container-fluid">
          <div class="card col-md-12 align-top">
            <div class="card-body container-fluid">
              <div class="row">
                <div class="col-6">
                <div class="form-group">
                <label for="labels">Name of Agenda Item:</label>
                <input ng-model="agendaItem.subject"  class="form-control" style="max-width:400px;" placeholder="Enter Agenda Item Name"/>
                </div>
                <div class="form-check my-3 mx-2">
                    <input class="form-check-input form-control-md" type="checkbox"  ng-model="agendaItem.isSpacer">
                    This is a break time (check if true)
                </div>
                <div class="form-group row g-3">
                  <div class="col-auto">
                    <label for="labels">Planned Duration: (minutes)</label>
                    <input ng-model="agendaItem.duration" class="form-control" />
                  </div>
              &nbsp;
                <div class="form-group row g-3">
                  <div class="col-auto">
                    <label for="labels">Actual Duration: (minutes)</label>
                    <input ng-model="agendaItem.previousElapsed"  class="form-control"  ng-hide="agendaItem.timerRunning"/>
                    <span class="form-control" ng-show="agendaItem.timerRunning">{{agendaItem.previousElapsed}}
                    </span>
                  </div>
                </div>
              </div>
                </div>
                <div class="col-6">
                  <div class="form-group">
                  <label for="labels">Presenter:</label>
                  <tags-input ng-model="agendaItem.presenterList" placeholder="Enter user name or id" display-property="name" key-property="uid" on-tag-added="updatePresenters()"  on-tag-removed="updatePresenters()">
                    <auto-complete source="getPeople($query)" min-length="1"></auto-complete>
                  </tags-input>
                  </div>
                  <div class="form-check my-3 mx-2">
                  <input class="form-check-input" type="checkbox"  ng-model="agendaItem.proposed" />
                    Proposed Item
                  </div>
                  <div class="form-group">
                  <label for="labels">Description:</label>
                  <textarea ng-model="agendaItem.descriptionHtml" class="form-control markDownEditor" placeholder="Enter description" ng-ui-tinymce="tinymceOptions"></textarea>
                  </div>
                </div>
            </div>
          </div>
        </div>
        </div>
      <div class="modal-footer">
        <button type="button" class="me-auto btn btn-danger" data-bs-dismiss="modal" ng-click="cancel()">Close</button>
        <button type="button" class="btn btn-primary" ng-click="ok()">Update</button>
      </div>
      </div>
  </div>
  </div>-->
    </div> 
   
    
  