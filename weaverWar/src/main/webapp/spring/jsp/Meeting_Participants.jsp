
    <div style="max-width:800px">
      <div style="margin:10px;vertical-align:middle">
          <span class="h2">Meeting Participants: </span> 
          <span ng-hide="editMeetingPart=='participants'">
              <button class="btn btn-default btn-primary btn-raised" 
                      ng-click="startParticipantEdit()"
                      title="Add more people to the list below">
              <span class="fa fa-plus"></span> Add Participants </button>
          </span>
      </div>
      <div class="well" ng-show="editMeetingPart=='participants'">
          <div>
              <tags-input ng-model="participantEditCopy" 
                          placeholder="Enter users to send notification email to"
                          display-property="name" key-property="uid"
                          replace-spaces-with-dashes="false" add-on-space="true" add-on-comma="true">
                  <auto-complete source="loadPersonList($query)" min-length="1"></auto-complete>
              </tags-input>
          </div>
          <div>
          <span class="dropdown">
              <button class="btn btn-default btn-primary btn-raised" 
                      ng-click="addParticipants()"
                      title="Add these people to the list of participants">
              <span class="fa fa-plus"></span> Add </button>
              <button class="btn btn-default btn-danger btn-raised" type="button" 
                      ng-click="editMeetingPart=''"
                      title="Ignore what has been put here and close box">
              Cancel </button>
              <button class="btn btn-default btn-raised" ng-click="appendRolePlayers()" 
                      ng-hide="roleEqualsParticipants" 
                      title="Look at the workspace role, and suggest anyone not already a participant">
                  Add Everyone from {{meeting.targetRole}}
              </button>
          </span>
          </div>
      </div>
      <table class="table">
      <tr>
          <th></th>
          <th title="Name of the participant">Name</th>
          <th title="Click on these to record whether the user attended or not">Attended</th>
          <th title="Shows whether the user is expected to be there or not">Expected</th>
          <th title="Shows the user explanation of whether they will attend or not">Situation</th>
          <th title="Shows what the user selected during the time selection phase, if anything">Avail</th>
          <th title="Shows an indicator when this person is online and has accessed meeting in last 30 minutes">On</th>
      </tr>
      <tr class="comment-inner" ng-repeat="(key, pers) in meeting.people" class="form-inline form-group">
          <td >
              <span class="dropdown" >
                <span id="menu1" data-toggle="dropdown">
                <img class="img-circle" 
                     ng-src="<%=ar.retPath%>icon/{{pers.key}}.jpg" 
                     style="width:32px;height:32px" 
                     title="{{pers.name}} - {{pers.uid}}">
                </span>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                      tabindex="-1" style="text-decoration: none;text-align:center">
                      {{pers.name}}<br/>{{pers.uid}}</a></li>
                  <li role="presentation" style="cursor:pointer"><a role="menuitem"
                      ng-click="navigateToUser(pers)">
                      <span class="fa fa-user"></span> Visit Profile</a></li>
                  <li role="presentation" style="cursor:pointer"><a role="menuitem"
                      ng-click="removeParticipant(pers)">
                      <span class="fa fa-times"></span> Remove User</a></li>
                </ul>
              </span>
          </td>
          <td style="overflow:hidden;white-space:nowrap;width:90px">
            {{pers.name}}
          </td>
          <td ng-click="toggleAttend(pers.uid)">
            <span ng-show="didAttend(pers.uid)" style="color:green" title="indicates that the user did attend meeting">
                <span class="fa fa-check"></span></span>
            <span ng-hide="didAttend(pers.uid)" style="color:#eeeeee"  title="indicates that the user did not attend meeting">
                <span class="fa fa-question-circle"></span></span>
          </td>
          <td ng-dblclick="toggleEditSitch(pers)">
              <div ng-hide="editSitch.uid==pers.uid">{{pers.expect}}</div>
              <div ng-show="editSitch.uid==pers.uid">
                  <select ng-model="editSitch.expect" class="form-control" style="padding:0">
                     <option>Unknown</option>
                     <option>Yes</option>
                     <option>Maybe</option>
                     <option>No</option>
                  </select>
                  
              </div>
          </td>
          <td  ng-dblclick="toggleEditSitch(pers)">
              <div ng-hide="editSitch.uid==pers.uid">{{pers.situation}}</div>
              <div ng-show="editSitch.uid==pers.uid">
                  <input ng-model="editSitch.situation" class="form-control" style="width:400px;"/>
                  <button ng-click="toggleEditSitch(pers)" class="btn btn-sm btn-primary btn-raised">Close</button>
              </div>
          </td>
          <td>
                <span ng-show="pers.available==1" title="Conflict for that time" style="color:red;">
                    <span class="fa fa-minus-circle"></span>
                    <span class="fa fa-minus-circle"></span></span>
                <span ng-show="pers.available==2" title="Very uncertain, maybe unlikely" style="color:red;">
                    <span class="fa fa-question-circle"></span></span>
                <span ng-show="pers.available==3" title="No response given" style="color:#eeeeee;">
                    <span class="fa fa-question-circle"></span></span>
                <span ng-show="pers.available==4" title="ok time for me" style="color:green;">
                    <span class="fa fa-plus-circle"></span></span>
                <span ng-show="pers.available==5" title="good time for me" style="color:green;">
                    <span class="fa fa-plus-circle"></span>
                    <span class="fa fa-plus-circle"></span></span>
          
          </td>
          <td>
            <span ng-show="isPresent(pers.uid)" style="color:green;text-align:center;" title="this user is online and has accessed this meeting recently"><span class="fa fa-user"></span></span>
            <span ng-hide="isPresent(pers.uid)" style="color:#eeeeee;text-align:center;" title="this user has not accessed this meeting recently"><span class="fa fa-circle-thin"></span></span>
          </td>
      </tr>
      </table>
      
      
    </div>
