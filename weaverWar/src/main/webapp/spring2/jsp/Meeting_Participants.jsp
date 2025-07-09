
<div class="card" id="cardparticipants">
    <div class="card-header">
        <span class="h5 card-title">Meeting Participants: 
        </span> 
    </div>
    <div class="card-body well ">
        <span class="col-md-2 override" ng-hide="editMeetingPart=='participants'">
            
            <button class="btn btn-wide btn-secondary btn-raised" 
                    ng-click="startParticipantEdit()"
                    title="change the people invited to the meeting">
                Change Participants </button>
        </span>
        <span class="col-md-3 float-end"><a class="btn btn-wide btn-comment btn-raised" href="EmailCompose.htm?meet={{meetId}}"> Send Email <i class="fa fa-envelope-o"></i> About Meeting</a>
          </span>
    </div>
    <section class="well"  ng-show="editMeetingPart=='participants'">
        <div class="row d-flex col-12 my-2">
            <label class="col-md-2 control-label h5" for="alsoalsoTo">Invited:</label>
            <div class="col-md-10">
                <tags-input ng-model="meeting.participants" placeholder="Enter user name or id" display-property="name" key-property="uid" on-tag-clicked="toggleSelectedPerson($tag)" replace-spaces-with-dashes="false" add-on-space="true" add-on-comma="true" on-tag-added="cleanUpAlsoTo()" on-tag-removed="cleanUpAlsoTo()"> 
                    <auto-complete source="loadPersonList($query)" min-length="1"></auto-complete>
                </tags-input>
            </div>
        </div>
        <div class="row d-flex mt-3 ms-2">
            <label class="col-md-2 control-label h6">Invite Role Players:</label>
            <div class="col-md-10 d-flex flex-wrap">
                <div ng-repeat="role in allRoles" > 
                    <button class="btn-comment btn-wide btn-raised" 
                            ng-click="addPlayers(role)">
                        {{role.name}}</button>
                </div>
            </div>
        </div>
    

        <!--Clear-->
        <div class="row d-flex col-12 m-2">
            <div class="form-group d-flex">
                <label class="col-md-2 control-label h6">Clear Addressees:</label>
                <span class="col-md-10">
                        <button class="btn-comment btn-wide btn-raised" 
                                ng-click="meeting.participants = []" 
                                title="Add all the people invited to the meeting">
                            Clear Addressees</button>
                </span>
            </div>
        </div>
        <button class="btn-secondary btn-wide btn-raised float-end" 
                ng-click="finishEditParticipants()" 
                title="close the addressing mode">Change Complete</button>
        <div class="clearfix"></div>
    </section>
    <div class="col-12" ng-hide="editMeetingPart=='participants'">
    <div class="row d-flex border-opacity-25 border-bottom border-secondary ms-4">
        <span class="col-1 h6">  </span>
        <span class="col-2 h6" title="Name of the participant">Name</span>
        <span class="col-1 h6 text-center" title="Click on these to record whether the user attended or not">Attended</span>
        <span class="col-2 h6 text-center" title="Shows whether the user is expected to be there or not">Expected</span>
        <span class="col-2 h6 text-left" title="Shows the user explanation of whether they will attend or not">Situation</span>
        <span class="col-1 h6 text-center" title="Shows what the user selected during the time selection phase, if anything">Available</span>
        <span class="col-1 h6 text-center" title="Shows an indicator when this person is online and has accessed meeting in last 30 minutes">On</span>
    </div>
    <div class="row d-flex form-inline form-group my-3 ms-4" ng-repeat="(key, pers) in meeting.people">
        <span class="col-1"  title="Name of the participant">
            <span class="nav-item dropdown" >
              <span id="menu1" data-toggle="dropdown">
              <img class="rounded-5" 
                   ng-src="<%=ar.retPath%>icon/{{pers.key}}.jpg" 
                   style="width:32px;height:32px" 
                   title="{{pers.name}} - {{pers.uid}}">
              </span>
              <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                <li role="presentation" style="background-color:lightgrey"><a class="dropdown-item" role="menuitem" 
                    tabindex="-1" style="text-decoration: none;">
                    {{pers.name}}<br/>{{pers.uid}}</a></li>
                <li role="presentation" style="cursor:pointer"><a class="dropdown-item" role="menuitem"
                    ng-click="navigateToUser(pers)">
                    <span class="fa fa-user"></span> Visit Profile</a></li>
                <li role="presentation" style="cursor:pointer"><a class="dropdown-item" role="menuitem"
                    ng-click="removeParticipant(pers)">
                    <span class="fa fa-times"></span> Remove User</a></li>
              </ul>
            </span>
        </span>
        <span class="col-2" style="overflow:hidden;white-space:nowrap">
          {{pers.name}}
        </span>
        <span class="col-1 text-center" ng-click="toggleAttend(pers)" title="Click on these to record whether the user attended or not">
          <span ng-show="pers.attended" style="color:green" title="indicates that the user did attend meeting">
              <span class=" fa fa-check "></span></span>
          <span ng-hide="pers.attended"   title="indicates that the user did not attend meeting">
              <span class="text-secondary opacity-50 fa fa-question-circle"></span></span>
        </span>
        <span class="col-2 text-center" title="Double-click to edit">
            <div class="pt-0 btn border-opacity-10 border-1 rounded-2 text-center" ng-hide="editSitch.uid==pers.uid" ng-click="toggleEditSitch(pers)" >{{pers.expect}}</div>
            <div class="pt-0 btn border-opacity-10 border-1 rounded-2 text-center" ng-show="editSitch.uid==pers.uid">
                <select ng-model="pers.expect" class="form-control p-1 btn-wide border-opacity-10 rounded-2" >
                   <option>Unknown</option>
                   <option>Yes</option>
                   <option>Maybe</option>
                   <option>No</option>
                </select>
            </div>
        </span>
        <span class="col-2 text-left"  title="Shows the user explanation of whether they will attend or not">
            <div ng-hide="editSitch.uid==pers.uid" ng-click="toggleEditSitch(pers)">{{pers.situation}}</div>
            <div  ng-show="editSitch.uid==pers.uid">
                <input class="form-control border-opacity-10 rounded-2" ng-model="pers.situation"  style="width: 200px; height: 34px; background-color: #fefefe;"/>
                <button ng-click="stopEditSitch(pers)" class="btn btn-default btn-primary btn-raised">Close</button>
            </div>
        </span>
        <span class="col-1 text-center" title="Shows what the user selected during the time selection phase, if anything">
              <span ng-show="pers.available==1" title="Conflict for that time" style="color:red;">
                  <span class="fa fa-minus-circle"></span>
                  <span class="fa fa-minus-circle"></span></span>
              <span ng-show="pers.available==2" title="Very uncertain, maybe unlikely" style="color:red;">
                  <span class="fa fa-question-circle"></span></span>
              <span ng-show="pers.available==3" title="No response given" >
                  <span class="text-secondary opacity-50 fa fa-question-circle"></span></span>
              <span ng-show="pers.available==4" title="ok time for me" style="color:green;">
                  <span class="fa fa-plus-circle"></span></span>
              <span ng-show="pers.available==5" title="good time for me" style="color:green;">
                  <span class="fa fa-plus-circle"></span>
                  <span class="fa fa-plus-circle"></span></span>
        
        </span>
        <span class="col-1 text-center" title="Shows an indicator when this person is online and has accessed meeting in last 30 minutes">
          <span ng-show="isPresent(pers.uid)" style="color:green;text-align:center;" title="this user is online and has accessed this meeting recently"><span class="fa fa-user"></span></span>
          <span ng-hide="isPresent(pers.uid)" style="color:#eeeeee;text-align:center;" title="this user has not accessed this meeting recently"><span class="fa fa-circle-thin"></span></span>
        </span>
    </div>
    </div>
    
    
  </div>
