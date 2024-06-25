
<div class="container-fluid">
    <h2 class="h3 page-name text-secondary">Agenda:</h2>

    <div class="container-fluid">
      <div class="row" ng-dblclick="openAgenda(item)">
        <span ng-click="openAgenda(item)" class="labelColumn"></span>
        <span ng-style="timerStyleComplete(item)"><h3 class="h4 text-secondary">
          <span ng-hide="item.isSpacer" >{{item.number}}. </span>{{item.subject}}</h3></span>
      </div>
      <div class="row">
        <div class="col-6">
          <div ng-dblclick="openAgendaControlled(item,'Description')" ng-show="!item.isSpacer" class="description-container">
            <h4 ng-click="openAgendaControlled(item,'Description')" class="h6 mb-auto">Description: </h4>
            <div class="p pt-4 flex-grow-1" ng-bind-html="item.descriptionHtml"></div>
            <span ng-hide="item.descriptionHtml && item.descriptionHtml.length>3" class="doubleClickHint">
            Double-click to edit description
            </span>
          </div>
        </div>
        <div class="col-6">
          <div class="timers col-auto ms-auto" >
            <div class="row col-12">
              <span class="col-4">
              <span ng-dblclick="openAgenda(item)"  ng-hide="item.proposed">
                <span ng-hide="item.timerRunning">
                    <button class="btn btn-md m-1 fixed-width-sm" ng-click="agendaStartButton(item)">Start</button>
                </span>
                <span ng-show="item.timerRunning">
                    <button class="btn btn-md m-1 fixed-width-sm" ng-click="stopAgendaRunning()"><i class="fa fa-clock-o"></i> Stop</button>
                </span>
              </span>
              </span>
              <span class="col-4">
              <span ng-click="openAgenda(item)">Actual Time:</span><br>
                <span ng-style="timerStyleComplete(item)">{{item.timerTotal|minutes}} </span>
              </span>
              <span class="col-4" ng-dblclick="openAgenda(item)" ng-hide="item.isSpacer">
                  <!--<div ng-click="openAgenda(item)" class="h6"> Presenter: </div>-->
                  <div ng-repeat="presenter in item.presenterList">
                    <span class="dropdown" >
                      <span id="menu1" data-toggle="dropdown">
                        <img class="img-circle" ng-src="<%=ar.retPath%>icon/{{presenter.key}}.jpg" style="width:32px;height:32px" title="{{presenter.name}} - {{presenter.uid}}">
                      </span>
                      <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                        <li role="presentation" style="background-color:lightgrey"><a role="menuitem" tabindex="-1" style="text-decoration: none;text-align:center">{{presenter.name}}<br/>{{presenter.uid}}</a>
                        </li>
                        <li role="presentation" style="cursor:pointer">
                          <a role="menuitem" tabindex="-1" ng-click="navigateToUser(presenter)">
                          <span class="fa fa-user"></span> Visit Profile</a>
                        </li>
                      </ul>
                    </span>
                      {{presenter.name}}
                  </div>
                  <div ng-hide="item.presenterList && item.presenterList.length>0">
                  </div>
                  <div type="button" class="m-2 btn btn-sm btn-outline-primary fixed-width-sm" data-bs-toggle="modal" data-bs-target="#agendaItem"> Select Presenter
                  </div>
              </span>
            </div>
          
            <div class="row col-12">
                <div class="col-4 ms-3 me-2 pt-2 fixed-width-sm" id="statusMenu" data-toggle="dropdown" style="{{meetingStateStyle(meeting.state)}}" ng-click="displayMode='Status'"><i class="fa fa-clock-o fa-2x"></i><br>
        {{meetingStateName()}} Mode
                </div>
                <span class="col-4">
                <span> Remaining Time: </span><span ng-style="timerStyleComplete(item)"> {{item.duration - item.timerTotal| minutes}}</span>
              </span>

                
                <span class="col-4" ng-dblclick="openAgenda(item)" ng-hide="item.proposed">
                    <div ng-click="openAgenda(item)" class="labelColumn">Proposed:</div>
                    <span>{{item.status}}</span>
                    <div ng-style="timerStyleComplete(item)"><!--This item is proposed, and not accepted yet.  -->
                      <button ng-click="toggleProposed(item)" class="btn btn-primary btn-raised" ng-show="item.proposed">
                        <a><i class="fa fa-check"></i> Accept Proposed Item</a></button>
                    </div>
                </span>
      
            </div>
          </div>
        </div>
      </div>
    <!-- Set Presenter Modal -->
<div class="modal fade" id="agendaItem" data-bs-backdrop="static" data-bs-keyboard="false" tabindex="-1" aria-labelledby="agendaItemLabel" aria-hidden="true">
  <div class="modal-dialog modal-xl">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <div class="container-fluid">
          <div class="card col-md-12 align-top">
            <div class="card-header border-1">
              Agenda Item Settings
            </div>
            <div class="card-body container-fluid">
              <div class="row">
                <div class="col-6">
                <div class="form-group">
                <label for="labels">Name of Agenda Item:</label>
                <input ng-model="agendaItem.subject"  class="form-control" style="max-width:400px;"
                           placeholder="Enter Agenda Item Name"/>
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
                  <input class="form-check-input" type="checkbox"  ng-model="agendaItem.proposed"/>
                    Proposed (remove check to accept)
                </div>
                </div>
              </div>
            </div>
            </div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="me-auto btn btn-danger" data-bs-dismiss="modal">Close</button>
        <button type="button" class="btn btn-primary">Update</button>
      </div>
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
        </div>
        <div class="card-body">
            <span ng-dblclick="openNotesDialog(item)">
              <div ng-bind-html="item.minutes | wiki"></div>
              <div ng-hide="item.minutes" class="doubleClickHint">
              Double-click to edit notes
              </div>
            </span>
        </div>
      </div>
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
          </div>
          <div class="card-body">
            <span ng-dblclick="copyNotes(item)">
              <div ng-hide="item.lastMeetingMinutes" class="doubleClickHint">
              Double-click to copy notes
              </div>
            </span>
          </div>
        </div>
      </div>
      </div><!--END Minutes and Notes-->
      <hr/>
    <!--Assets Row-->
  <div class="container">
    <div class="row justify-content-center">
    <!--Action Items-->
    <div class="col-4">
      <div ng-hide="item.isSpacer">
        <div class="accordion accordionAssets" id="accordionActionItems">
        <div class="accordion-item">
          <div class="h6 accordion-header" id="headingActionItems">
          <div class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseActionItems" aria-expanded="true" aria-labelledby="collapseActionItems" aria-controls="collapseActionItems">
            <i class="fa fa-check-circle-o"></i> &nbsp;Action Items:</div> 
          </div>
          <div id="collapseActionItems" class="accordion-collapse collapse show" aria-labelledby="headingActionItems" data-bs-parent="#accordionActionItems">
          <div class="acordion-body">
            <div ng-repeat="person in goal.assignTo">
              <span class="dropdown" >
            <span id="menuMbrs" data-toggle="dropdown"><img class="img-circle" 
                   ng-src="<%=ar.retPath%>icon/{{person.key}}.jpg" 
                   style="width:32px;height:32px" 
                   title="{{person.name}} - {{person.uid}}">
            </span>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menuMbrs">
              <li role="presentation" class="bg-secondary-10"><a role="menuitem" tabindex="-1">
                  {{person.name}}<br/>{{person.uid}}</a></li>
              <li role="presentation" style="cursor:pointer">
                <a role="menuitem" tabindex="-1" ng-click="navigateToUser(person)">
                  <span class="fa fa-user"></span> Visit Profile
                </a>
              </li>
            </ul>
              </span>
            </div>
<!-- Buttons to trigger action item modals -->
        <!--Button to create new action item-->
        <div class="container-fluid">
        <div class="row py-3 gap-2 justify-content-center">      
          <div type="button" class="col-5 btn btn-sm btn-outline-primary" data-bs-toggle="modal" data-bs-target="#createActionItem"> Create New Action Item 
          </div>
        <!--Button to attach or remove existing action items-->
          <div type="button" class="col-5 btn btn-sm btn-outline-primary" data-bs-toggle="modal" data-bs-target="#attachAction"> Attach/Remove Existing Action Items 
          </div>
        </div>
        </div>

<!-- Create Action Item Modal -->
        <div class="modal fade" id="createActionItem" data-bs-backdrop="static" data-bs-keyboard="false" tabindex="-1" aria-labelledby="createActionItemLabel" aria-hidden="true">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <div class="container-fluid">
          <div class="card col-md-12 align-top">
             <div class="card-header border-1">Create New Action Item</div>
            <div class="card-body">
              <div class="form-group">
                <div>
                  <label>Synopsis:</label>
                  <input type="text" ng-model="newGoal.synopsis" class="form-control" placeholder="What should be done">
                </div>
                <div>
                  <label class="gridTableColummHeader">Assignee:</label>
                    <tags-input ng-model="newGoal.assignTo" placeholder="Enter user name or id" 
                                display-property="name" key-property="uid" on-tag-clicked="showUser($tag)">
                        <auto-complete source="loadPersonList($query)" min-length="1"></auto-complete>
                    </tags-input>
                </div>
                <div>
                  <label class="gridTableColummHeader">Description:</label>
                      <textarea type="text" ng-model="newGoal.description" class="form-control markDownEditor"
                          style="width:450px;height:100px" placeholder="Details"></textarea>
                </div>
                <div>
                  <label class="gridTableColummHeader">Due Date:</label>
                      <span datetime-picker ng-model="newGoal.dueDate"  
                          class="form-control" style="max-width:300px;height:25px">
                          {{newGoal.dueDate|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm  '&nbsp;  GMT'Z"}}
                      </span> 
                      <!--input type="text"
                          style="width:150;margin-top:10px;"
                          class="form-control"
                          datepicker-popup="dd-MMMM-yyyy"
                          ng-model="dummyDate1"
                          is-open="datePickOpen1"
                          min-date="minDate"
                          datepicker-options="datePickOptions"
                          date-disabled="datePickDisable(date, mode)"
                          ng-required="true"
                          ng-click="openDatePicker1($event)"
                          close-text="Close"/-->
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="me-auto btn btn-danger" data-bs-dismiss="modal">Close</button>
        <button type="button" class="btn btn-primary">Create Action Item</button>
      </div>
    </div>
  </div>
        </div>
<!-- Attach Action Item Modal -->
        <div class="modal fade" id="attachAction" data-bs-backdrop="static" data-bs-keyboard="false" tabindex="-1" aria-labelledby="attachActionLabel" aria-hidden="true">
  <div class="modal-dialog modal-xl">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="attachActionLabel">Attach/Remove Existing Action Items</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <div class="container-fluid">
          <div class="row g-0">
          <div class="card col-md-6 align-top">
            <div class="card-header border-1">Existing Action Items - Filter
              &nbsp;<input type="text" ng-model="realFilter"></div>
            <div class="card-body">
              <div class="docTable">
                <div ng-repeat="act in filterActions()" ng-click="addActionToList(act)" title="Click to add this action item to the list" style="cursor:pointer">
                  <span>
                    <img ng-src="../../../assets/goalstate/small{{act.state}}.gif"> {{act.synopsis | limitTo:50}}
                  </span>
                  <span>
                    <button ng-hide="itemHasAction(act)" class="btn btn-sm btn-outline-primary">
                      <i class="fa fa-arrow-right"></i>
                    </button>
                    <button ng-show="itemHasAction(act)" class="btn btn-sm btn-outline-secondary">&nbsp; &nbsp;</button>
                  </span>
                </div>
                <div ng-show="filterActions().length == 0">
                  <span colspan="2" class="text-muted">
                    No action items to choose from.<br/><br/>
                    Use 'Create New Action' above.
                  </span>
                </div>  
              </div>
              </div>
          </div>
          <div class="card col-md-6 align-top">
            <div class="card-header border-1">Selected Action Items</div>
            <div class="card-body">
              <div class="docTable">
                <div ng-repeat="act in itemActions()" ng-click="removeActionFromList(act)" title="Click to remove this action item from the list" style="cursor:pointer">
                  <span>
                    <img ng-src="../../../assets/goalstate/small{{act.state}}.gif"> {{act.synopsis | limitTo:50}}
                  </span>
                  <span>
                    <button class="btn">
                      <i class="fa fa-close"></i> &nbsp;
                    </button>
                  </span>
                </div>
                <div ng-show="itemActions().length == 0">
                  <span colspan="2" class="text-muted">
                    No actions items attached.<br/><br/>
                    <span ng-show="filterActions().length > 0">Click on an action item on the left, to add to the list here on the right.</span>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
        </div>
      </div>
      <div class="modal-footer">
              <button type="button" class="me-auto btn btn-danger me-auto" data-bs-dismiss="modal">Close</button>
              <button type="button" class="btn btn-primary">Attach Action Item</button>
      </div>
    </div>
  </div>
        </div>
          </div><!--END Action Items card body-->
          </div>
        </div>
        </div><!--END Action Items accordion-->
      </div>
    </div>
    <!--END Action Items-->

    <!--Documents/Attachment-->
    <div class="col-4">
      <div ng-hide="item.isSpacer">
        <div class="accordion accordionAssets" id="accordionAttachments">
        <div class="accordion-item" >
          <div class="h6 accordion-header" id="headingAttachments">
          <div class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseAttachments" aria-expanded="true" aria-labelledby="collapseAttachments" aria-controls="collapseAttachments"><i class="fa fa-paperclip"></i> &nbsp; Attachments:</div>
          </div>
          <div id="collapseAttachments" class="accordion-collapse collapse show" aria-labelledby="headingAttachments" data-bs-parent="#accordionAttachments">
            <div class="accordion-body">
              <div ng-repeat="docid in item.docList track by $index">
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
              <div ng-hide="item.docList && item.docList.length>0">
              </div>
      <!-- Buttons to trigger Documents modals -->
      <div class="container-fluid">
      <div class="row justify-content-center">        
        <div type="button" class="col-4 btn btn-sm btn-outline-primary" data-bs-toggle="modal" data-bs-target="#attachDocs"> Attach Document
        </div>

        <div type="button" class="col-4 btn btn-sm btn-outline-primary" data-bs-toggle="modal" data-bs-target="#uploadDocs"> Upload New Document
        </div>

        <div type="button" class="col-4 btn btn-sm btn-outline-primary" data-bs-toggle="modal" data-bs-target="#newWebLink"> New Web Link
        </div>
      </div>
      </div>
      <!-- Attach Docs Modal -->
              <div class="modal fade" id="attachDocs" data-bs-backdrop="static" data-bs-keyboard="false" tabindex="-1" aria-labelledby="attachDocsLabel" aria-hidden="true">
                <div class="modal-dialog modal-xl">
                  <div class="modal-content">
                    <div class="modal-header">
                      <h5 class="modal-title" id="attachDocsLabel">Attach Documents</h5>
                      <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                      <div class="container-fluid">
                        <div class="row g-0">
                          <div class="card col-md-6 align-top">
                            <div class="card-header border-1"> Available Documents - Filter &nbsp;<input type="text" ng-model="realDocumentFilter"> 
                            </div>
                            <div class="card-body">
                              <div class="docTable">
                                <div ng-repeat="doc in filterDocs()" ng-click="addDocToItem(doc)" style="cursor:pointer" 
                                title="Click to add document to the list.">
                                <span >
                                    <img src="../../../assets/images/iconFile.png"/> {{doc.name|limitTo:40}}
                                </span>
                                <span>
                                  <button ng-hide="itemHasDoc(doc)"
                                        class="btn" >&nbsp; <i class="fa fa-arrow-right"></i></button>
                                  <button  ng-show="itemHasDoc(doc)"
                                        class="btn" title="Document is already added.">&nbsp; &nbsp;</button>
                                </span>
                            </div>
                            <div ng-show="filterDocs().length==0">
                                <span class="instruction">No documents to choose from.<br/><br/>Drag and drop a document to upload.</span>
                            </div>
                          </div>
                            </div>
                          </div>
                          <div class="card col-md-6 align-top">
                        <div class="card-header border-1"> Selected Documents </div>
                        <div class="card-body">
                          <div class="docTable">
                            <div ng-repeat="doc in itemDocs()" ng-click="removeDocFromItem(doc)" 
                                title="Click to remove document from list." style="cursor:pointer">
                                <span >
                                    <img src="../../../assets/images/iconFile.png"/> {{doc.name|limitTo:40}} </span>
                                <span>
                                    <button class="btn"><i class="fa fa-close"></i> &nbsp;</button>
                                </span>
                            </div>
                            <div ng-show="itemDocs().length==0">
                                <span class="instruction">Nothing chosen to be attached.<br/><br/>
                                <span ng-show="filterDocs().length>0">Click on a document on the left, to add to the attachments listed here on the right.</span></span>
                            </div>
                          </div>
                        </div>

                      </div>
                        </div>
                      </div>
                        <div class="modal-footer">
                          <button type="button" class="btn btn-danger me-auto" data-bs-dismiss="modal">Close</button>
                          <button type="button" class="btn btn-primary">Attach Document</button>
                        </div>
                  </div>
                </div>
                </div>
              </div>
      <!-- Upload Docs Modal -->
              <div class="modal fade" id="uploadDocs" data-bs-backdrop="static" data-bs-keyboard="false" tabindex="-1" aria-labelledby="uploadDocsLabel" aria-hidden="true">
        <div class="modal-dialog modal-xl">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title" id="uploadDocsLabel">Upload Documents</h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
              <div class="container-fluid">
                <div class="card col-md-12 align-top">
                    <div class="card-header border-1"> Upload Documents </div>
                    <div class="card-body">
                      <div class="docTable">
                        <div>
                          <div ng-repeat="fp in fileProgress" class="well" style="min-width:400px;">
                            <div >
                                <div class="me-auto"><b>{{fp.file.name}}</b></div>
                                <div class="ms-auto">{{fp.status}}</div>
                            </div>
                            <div ng-hide="fp.done">
                               How is this document related to this workspace?:<br/>
                               <textarea ng-model="fp.description" class="form-control markDownEditor"></textarea>
                            </div>
                            <div style="padding:3px;" ng-hide="fp.done">
                                <div style="text-align:center">{{fp.status}}:  {{fp.loaded|number}} of {{fp.file.size|number}} bytes</div>
                                <div class="progress">
                                    <div class="progress-bar progress-bar-success" role="progressbar"
                                         aria-valuenow="50" aria-valuemin="0" aria-valuemax="100"
                                         style="width:{{fp.percent}}%">
                                    </div>
                                </div>
                            </div>
                            <div ng-hide="fp.done">
                                <button ng-click="startUpload(fp)" class="btn btn-primary btn-raised">Upload</button>
                                <button ng-click="cancelUpload(fp)" class="btn btn-primary btn-raised">Cancel</button>
                            </div>
                          </div>
                        </div>
                        <div ng-show="!fileProgress || fileProgress.length==0" 
                           style="width:100%;text-align:center">
                          <span class="instruction">
                              To upload new file: Drop  anywhere in panel
                          </span>
                        </div>
                      </div>
                    </div>
                </div>
              </div>
            </div>
          </div>
        </div>
              </div>
      <!-- New Web Link Modal -->
              <div class="modal fade" id="newWebLink" data-bs-backdrop="static" data-bs-keyboard="false" tabindex="-1" aria-labelledby="newWebLinkLabel" aria-hidden="true">
        <div class="modal-dialog modal-xl">
          <div class="modal-content">
            <div class="modal-header">

              <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
              <div class="container-fluid">
                <div class="card col-md-12 align-top">
                    <div class="card-header border-1"> New Web Link </div>
                    <div class="card-body">
                      <div class="form-group">
                        <div>
                          <label>URL:</label>
                          <input ng-model="newLink.url" class="form-control"></input>
                        </div>
                        <div>
                          <label>Name:</label>
                          <input ng-model="newLink.name" class="form-control"></input>
                        </div>  
                        <div>
                          <label>Description:</label>
                          <textarea ng-model="newLink.description" class="form-control"></textarea>
                        </div>

                      </div>
                    </div>
                </div>
              </div>
            </div>
          </div>
        </div>
              </div>
            </div>
          </div>
        </div>
        </div>
      </div>
    </div>
    <!--END Documents/Attachment-->

    <!--Forum-->
    <div class="col-4">
      <div ng-hide="item.isSpacer">
        <div class="accordion accordionAssets" 
      id="accordionForum">
      <div class="accordion-item">
        <div class="h6 accordion-header" id="headingForum">
          <div class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseForum" aria-expanded="true" aria-labelledby="headingForum" aria-controls="collapseForum"><i class="fa fa-lightbulb-o"></i>&nbsp;Forum:
          </div>
        </div>
        <div id="collapseForum" class="accordion-collapse collapse show" data-bs-parent="#accordionForum">

          <div class="accordion-body">
            <div ng-repeat="topic in itemTopics(item)" class="btn btn-sm btn-default btn-raised" ng-click="navigateToTopics(topic.universalid)">
            </div>{{topic.subject}}</div>
            <!--This is where the button for opening the forum is with the idea that if there are no forums it will still shop up-->
<!-- Button trigger modal -->
        <div class="container-fluid">
          <div class="row gap-2 justify-content-center">
            <div type="button" class="col-10 btn btn-sm btn-outline-primary" data-bs-toggle="modal" data-bs-target="#attachForum">Attach Forum Discussion
            </div>
          </div>
        </div>
<!-- Modal -->
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
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-danger me-auto" data-bs-dismiss="modal">Close</button>
        <button type="button" class="btn btn-primary">Attach Forum Discussions</button>
      </div>
    </div>
  </div>
            </div>
<div>&nbsp;</div>
          </div><!--END accordion body-->
        </div>
        </div>
      </div>  
    </div>
    <!--END Forum-->
    </div>
  </div>
  <!--END Assets Row-->
  <hr/>
  <!--Create Comment/Proposal/Round Row-->
  <div class="row row-cols-3">
    <div ng-repeat="cmt in item.comments"  ng-hide="item.isSpacer">

        <%@ include file="/spring/jsp/CommentView.jsp"%>

    </div>


      <div class="d-flex col-12 justify-content-center">
          <button ng-click="openMeetingComment(item, 1)" class="btn-comment btn-raised mx-2 my-md-3 my-sm-3">
              Create New <i class="fa fa-comments-o"></i> Comment</button>
          <button ng-click="openMeetingComment(item, 2)" class="btn-comment btn-raised mx-2 my-md-3 my-sm-3">
              Create New <i class="fa fa-star-o"></i> Proposal</button>
          <button ng-click="openMeetingComment(item, 3)" class="btn-comment btn-raised mx-2 my-md-3 my-sm-3">
              Create New <i class="fa fa-question-circle"></i> Round</button>
      </div>


  </div>
  <!--END Create Comment/Proposal/Round Row-->
  <hr/>
  <hr/>
  <!--Logistics Row 1-->
        <div ng-dblclick="item.readyToGo = ! item.readyToGo"  ng-hide="item.isSpacer">
        <div class="labelColumn" ng-click="item.readyToGo = ! item.readyToGo">Ready:</div>
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
      </div>
    </div>
  </div>


    <div ng-hide="item">
        <div class="guideVocal">
            Create an agenda item for the meeting use the "+ New" button on the left.
        </div>
    </div>

  </div>
    <!--<tr ng-show="meeting.state<=1">
      
      start top 4 buttons for moving agenda items
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
              <i class="fa fa-reply"></i> Backlog</a></li></button>
      </td> 
      end top 4 buttons for moving agenda items
    
    </tr>-->

  