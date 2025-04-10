
    <div style="max-width:800px">
      <div class="row d-flex mb-4">
          <span class="h2">Meeting Participants: </span> 
      </div>

      <div class="col-12 m-4">
        <div class="row-cols-7 d-flex border-opacity-25 border-bottom border-secondary">
            <span class="col h6">  </span>
            <span class="col h6" title="Name of the participant">Name</span>
            <span class="col h6" title="Click on these to record whether the user attended or not">Attended</span>
            <span class="col h6" title="Shows whether the user is expected to be there or not">Expected</span>
            <span class="col h6" title="Shows the user explanation of whether they will attend or not">Situation</span>
            <span class="col h6" title="Shows what the user selected during the time selection phase, if anything">Avail</span>
            <span class="col h6" title="Shows an indicator when this person is online and has accessed meeting in last 30 minutes">On</span>
        </div>
        <div class="row-cols-7 d-flex form-inline form-group my-3" ng-repeat="(key, pers) in meeting.people">
            <span class="col"  title="Name of the participant">
                <span class="nav-item dropdown" >
                  <span id="menu1" data-toggle="dropdown">
                  <img class="rounded-5" 
                       ng-src="<%=ar.retPath%>icon/{{pers.key}}.jpg" 
                       style="width:32px;height:32px" 
                       title="{{pers.name}} - {{pers.uid}}">
                  </span>
                  <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                    <li role="presentation" style="background-color:lightgrey"><a class="dropdown-item" role="menuitem" 
                        tabindex="-1" style="text-decoration: none;text-align:center">
                        {{pers.name}}<br/>{{pers.uid}}</a></li>
                    <li role="presentation" style="cursor:pointer"><a class="dropdown-item" role="menuitem"
                        ng-click="navigateToUser(pers)">
                        <span class="fa fa-user"></span> Visit Profile</a></li>
                  </ul>
                </span>
            </span>
            <span class="col" style="overflow:hidden;white-space:nowrap;width:90px" title="Click on these to record whether the user attended or not">
              {{pers.name}}
            </span>
            <span class="col" ng-click="toggleAttend(pers)" title="Click on these to record whether the user attended or not">
              <span ng-show="pers.attended" style="color:green" title="indicates that the user did attend meeting">
                  <span class=" fa fa-check "></span></span>
              <span ng-hide="pers.attended"   title="indicates that the user did not attend meeting">
                  <span class="text-secondary opacity-50 fa fa-question-circle"></span></span>
            </span>
            <span class="col" ng-dblclick="toggleEditSitch(pers)" title="Shows whether the user is expected to be there or not">
                <div class=" pt-0" ng-hide="editSitch.uid==pers.uid">{{pers.expect}}</div>
                <div ng-show="editSitch.uid==pers.uid">
                    <select ng-model="editSitch.expect" class="form-control p-1 btn-wide" >
                       <option>Unknown</option>
                       <option>Yes</option>
                       <option>Maybe</option>
                       <option>No</option>
                    </select>
                    
                </div>
            </span>
            <span class="col"  ng-dblclick="toggleEditSitch(pers)" title="Shows the user explanation of whether they will attend or not">
                <div ng-hide="editSitch.uid==pers.uid">{{pers.situation}}</div>
                <div ng-show="editSitch.uid==pers.uid">
                    <input class="form-control" ng-model="editSitch.situation"  style="width:400px; height: 25px;"/>
                    <button ng-click="toggleEditSitch(pers)" class="btn btn-default btn-danger btn-raised pull-right">Close</button>
                </div>
            </span>
            <span class="col" title="Shows what the user selected during the time selection phase, if anything">
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
            <span class="col" title="Shows an indicator when this person is online and has accessed meeting in last 30 minutes">
              <span ng-show="isPresent(pers.uid)" style="color:green;text-align:center;" title="this user is online and has accessed this meeting recently"><span class="fa fa-user"></span></span>
              <span ng-hide="isPresent(pers.uid)" style="color:#eeeeee;text-align:center;" title="this user has not accessed this meeting recently"><span class="fa fa-circle-thin"></span></span>
            </span>
        </div>
      </div>
      
      
    </div>
