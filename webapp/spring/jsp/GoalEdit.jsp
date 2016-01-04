<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="java.util.Date"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="java.text.SimpleDateFormat"
%><%@page import="org.socialbiz.cog.TemplateRecord"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%@page import="org.socialbiz.cog.AgendaItem"
%><%@ include file="/spring/jsp/include.jsp"
%><%!

    SimpleDateFormat formatter  = new SimpleDateFormat ("MM/dd/yyyy");

%><%
/*
Required parameters:

    1. pageId   : This is the id of an Workspace and here it is used to retrieve NGPage.
    2. bookList : This is the list of sites which is set in request attribute, used here to show
                  dropdown list of sites.
    3. taskId   : This parameter is id of a task and here it is used to get current task detail (GoalRecord)
                  and to pass current task id value when submitted.
    4. book     : This request attribute provide the key of account which is used to select account from the
                  list of all sites by-default when the page is rendered.

*/

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Must be a member to see meetings");

    String taskId = ar.reqParam("taskId");
    GoalRecord currentTaskRecord=ngp.getGoalOrFail(taskId);

    UserProfile uProf = ar.getUserProfile();

    //needed to prompt for the site to build a new workspace in
    List<NGBook> bookList = (List<NGBook>)request.getAttribute("bookList");
    List<HistoryRecord> histRecs = currentTaskRecord.getTaskHistory(ngp);
    JSONArray allHist = new JSONArray();
    for (HistoryRecord history : histRecs) {
        allHist.put(history.getJSON(ngp, ar));
    }

    List<NGPageIndex> templates = new ArrayList<NGPageIndex>();
    for(TemplateRecord tr : uProf.getTemplateList()){
        String pageKey = tr.getPageKey();
        NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(pageKey);
        if (ngpi!=null){
            templates.add(ngpi);
        }
    }
    NGPageIndex.sortInverseChronological(templates);

    //NEEDED???
    String book = (String)request.getAttribute("book");

    JSONObject goalInfo = currentTaskRecord.getJSON4Goal(ngp);
    JSONArray allLabels = ngp.getJSONLabels();

    JSONObject stateName = new JSONObject();
    stateName.put("0", BaseRecord.stateName(0));
    stateName.put("1", BaseRecord.stateName(1));
    stateName.put("2", BaseRecord.stateName(2));
    stateName.put("3", BaseRecord.stateName(3));
    stateName.put("4", BaseRecord.stateName(4));
    stateName.put("5", BaseRecord.stateName(5));
    stateName.put("6", BaseRecord.stateName(6));
    stateName.put("7", BaseRecord.stateName(7));
    stateName.put("8", BaseRecord.stateName(8));
    stateName.put("9", BaseRecord.stateName(9));

    JSONArray subGoals = new JSONArray();
    for (GoalRecord child : currentTaskRecord.getSubGoals()) {
        subGoals.put(child.getJSON4Goal(ngp));
    }

    JSONArray allPeople = UserManager.getUniqueUsersJSON();
    JSONArray linkedTopics = new JSONArray();
    String goalUniversalId = currentTaskRecord.getUniversalId();
    for (NoteRecord aNote : ngp.getAllNotes()) {
        for (String linkedAction : aNote.getActionList()) {
            if (linkedAction.equals(goalUniversalId)) {
                linkedTopics.put(aNote.getJSON(ngp));
            }
        }
    }

    JSONArray linkedMeetings = new JSONArray();
    for (MeetingRecord meet : ngp.getMeetings()) {
        for (AgendaItem ai : meet.getAgendaItems()) {
            for (String actionId : ai.getActionItems()) {
                if (actionId.equals(goalUniversalId)) {
                    linkedMeetings.put(meet.getListableJSON(ar));
                }
            }
        }
    }

    JSONArray attachmentList = ngp.getJSONAttachments(ar);


/*** PROTOTYPE

    $scope.goalInfo  = {
      "assignTo": [{
        "name": "Alex Demo",
        "uid": "alex@kswenson.oib.com"
      }],
      "description": "test",
      "duedate": 0,
      "duration": 0,
      "enddate": 0,
      "id": "9270",
      "modifiedtime": 0,
      "modifieduser": "",
      "priority": 0,
      "projectKey": "facility-1-wellness-circle",
      "projectname": "Facility 1 Wellness Circle",
      "rank": 40,
      "siteKey": "socio",
      "sitename": "Sociocracy Prototype",
      "startdate": 0,
      "state": 2,
      "status": "",
      "synopsis": "asdfasdfasdf",
      "universalid": "MHYDHNLWG@facility-1-wellness-circle@9270"
    };

*/

%>



<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http, $modal) {
    $scope.goalInfo  = <%goalInfo.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.stateName = <%stateName.write(out,2,4);%>;
    $scope.subGoals  = <%subGoals.write(out,2,4);%>;
    $scope.allPeople = <%allPeople.write(out,2,4);%>;
    $scope.allHist   = <%allHist.write(out,2,4);%>;
    $scope.linkedTopics = <%linkedTopics.write(out,2,4);%>;
    $scope.linkedMeetings = <%linkedMeetings.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;

    $scope.newPerson = "";

    $scope.editGoalInfo = false;
    $scope.showCreateSubProject = false;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.setState = function(newState) {
        $scope.goalInfo.state=newState;
        $scope.saveGoal();
    }
    $scope.startEdit = function() {
        $scope.editGoalInfo=true;
        $scope.showAccomplishment=false;
        $scope.copyDatesToDummies();
    }
    $scope.saveGoal = function() {
        $scope.goalInfo.duedate = $scope.dummyDate1.getTime();
        $scope.goalInfo.startdate = $scope.dummyDate2.getTime();
        $scope.goalInfo.enddate = $scope.dummyDate3.getTime();
        var postURL = "updateGoal.json?gid="+$scope.goalInfo.id;
        var postdata = angular.toJson($scope.goalInfo);
        $scope.showError=false;
        $scope.editGoalInfo=false;
        $scope.showAccomplishment=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.goalInfo = data;
            $scope.copyDatesToDummies();
            $scope.refreshHistory();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.undoGoalChanges = function() {
        var postURL = "updateGoal.json?gid="+$scope.goalInfo.id;
        var dummyObj = {};
        dummyObj.id = $scope.goalInfo.id;
        dummyObj.universalid = $scope.goalInfo.universalid;
        var postdata = angular.toJson(dummyObj);
        $scope.showError=false;
        $scope.editGoalInfo=false;
        $scope.showAccomplishment=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.goalInfo = data;
            $scope.copyDatesToDummies();
            $scope.refreshHistory();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.saveAccomplishment = function() {
        $scope.goalInfo.newAccomplishment = $scope.newAccomplishment;
        $scope.saveGoal();
    }
    $scope.addPerson = function() {
        var player = $scope.newPerson;
        if (typeof player == "string") {
            var pos = player.lastIndexOf(" ");
            var name = player.substring(0,pos).trim();
            var uid = player.substring(pos).trim();
            player = {name: name, uid: uid};
        }
        $scope.goalInfo.assignTo.push(player);
        $scope.saveGoal();
    }
    $scope.removePerson = function(person) {
        var res = $scope.goalInfo.assignTo.map( function(one) {
            return (person.uid != one.uid);
        });
        $scope.goalInfo.assignTo = res;
        $scope.saveGoal();
    }
    $scope.visitPlayer = function(player) {
        window.location = "<%=ar.retPath%>v/FindPerson.htm?uid="+player.uid;
    }
    $scope.bestName = function(person) {
        if (person.name) {
            return person.name;
        }
        return person.uid;
    }
    $scope.getPeople = function(filter) {
        var lcfilter = filter.toLowerCase();
        var res = [];
        var last = $scope.allPeople.length;
        for (var i=0; i<last; i++) {
            var rec = $scope.allPeople[i];
            if (rec.name.toLowerCase().indexOf(lcfilter)>=0) {
                res.push(rec);
            }
        }
        return res;
    }
    $scope.refreshHistory = function() {
        var postURL = "getGoalHistory.json?gid="+$scope.goalInfo.id;
        $scope.showError=false;
        $http.get(postURL)
        .success( function(data) {
            $scope.allHist = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.goalProspectsName = function() {
        if ($scope.goalInfo.prospects=="good") {
            return "Good";
        }
        if ($scope.goalInfo.prospects=="ok") {
            return "Warning";
        }
        return "Trouble";
    };
    $scope.goalProspectsStyle = function() {
        if ($scope.goalInfo.prospects=="good") {
            return "background-color:lightgreen";
        }
        if ($scope.goalInfo.prospects=="ok") {
            return "background-color:yellow";
        }
        if ($scope.goalInfo.prospects=="bad") {
            return "background-color:red";
        }
        return "background-color:lavender";
    }
    $scope.setProspects = function(newVal) {
        $scope.goalInfo.prospects = newVal;
        $scope.saveGoal();
        $scope.refreshHistory();
    }

    $scope.copyDatesToDummies = function() {
        $scope.dummyDate1 = new Date($scope.goalInfo.duedate);
        $scope.dummyDate2 = new Date($scope.goalInfo.startdate);
        $scope.dummyDate3 = new Date($scope.goalInfo.enddate);
    }
    $scope.copyDatesToDummies();
    $scope.datePickOptions = {
        formatYear: 'yyyy',
        startingDay: 1
    };
    $scope.datePickDisable = function(date, mode) {
        return false;
    };
    $scope.datePickOpen1 = false;
    $scope.datePickOpen2 = false;
    $scope.datePickOpen3 = false;
    $scope.openDatePicker1 = function($event) {
        $event.preventDefault();
        $event.stopPropagation();
        if ($scope.dummyDate1.getTime()<=0) {
            $scope.dummyDate1 = new Date();
        }
        $scope.datePickOpen1 = true;
    };
    $scope.openDatePicker2 = function($event) {
        $event.preventDefault();
        $event.stopPropagation();
        if ($scope.dummyDate2.getTime()<=0) {
            $scope.dummyDate2 = new Date();
        }
        $scope.datePickOpen2 = true;
    };
    $scope.openDatePicker3 = function($event) {
        $event.preventDefault();
        $event.stopPropagation();
        if ($scope.dummyDate3.getTime()<=0) {
            $scope.dummyDate3 = new Date();
        }
        $scope.datePickOpen3 = true;
    };
    $scope.hasLabel = function(searchName) {
        return $scope.goalInfo.labelMap[searchName];
    }
    $scope.toggleLabel = function(label) {
        $scope.goalInfo.labelMap[label.name] = !$scope.goalInfo.labelMap[label.name];
    }
    $scope.getGoalLabels = function(goal) {
        var res = [];
        $scope.allLabels.map( function(val) {
            if (goal.labelMap[val.name]) {
                res.push(val);
            }
        });
        return res;
    }
    $scope.navigateToTopic = function(oneTopic) {
        window.location="noteZoom"+oneTopic.id+".htm";
    }
    $scope.navigateToMeeting = function(meet) {
        window.location="meetingFull.htm?id="+meet.id;
    }

    $scope.itemHasDoc = function(doc) {
        var res = false;
        var found = $scope.goalInfo.docLinks.forEach( function(docid) {
            if (docid == doc.universalid) {
                res = true;
            }
        });
        return res;
    }
    $scope.getDocs = function() {
        return $scope.attachmentList.filter( function(oneDoc) {
            return $scope.itemHasDoc(oneDoc);
        });
    }

    $scope.navigateToDoc = function(doc) {
        window.location="docinfo"+doc.id+".htm";
    }
    $scope.openAttachDocument = function () {

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>templates/AttachDocument.html',
            controller: 'AttachDocumentCtrl',
            size: 'lg',
            resolve: {
                docList: function () {
                    return JSON.parse(JSON.stringify($scope.goalInfo.docLinks));
                },
                attachmentList: function() {
                    return $scope.attachmentList;
                }
            }
        });

        attachModalInstance.result
        .then(function (docList) {
            $scope.goalInfo.docLinks = docList;
            $scope.saveGoal(['docLinks']);
        }, function () {
            //cancel action - nothing really to do
        });
    };

});

function addvalue() {
    if(flag==false){
        document.getElementById("projectname").value=projectNameTitle;
    }
}

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            <img src="<%=ar.retPath%>assets/goalstate/large{{goalInfo.state}}.gif" />
            {{stateName[goalInfo.state]}} Action Item
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="startEdit()">Edit Details</a></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="showAccomplishment=!showAccomplishment;editGoalInfo=false;">Record Accomplishment</a></li>
              <!--li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="showCreateSubGoal=!showCreateSubGoal">Create Sub Action</a></li>
              <li role="presentation"><a role="menuitem"
                  href="#" ng-click="showCreateSubProject=!showCreateSubProject">Convert to Workspace</a></li-->
            </ul>
          </span>

        </div>
    </div>

    <table width="100%" ng-hide="editGoalInfo">
        <tr>
            <td class="gridTableColummHeader">Summary:</td>
            <td style="width:20px;"></td>
            <td ng-click="startEdit()">
                <b>{{goalInfo.synopsis}}</b>
                ~ {{goalInfo.description}}
                <span ng-repeat="label in getGoalLabels(goalInfo)">
                  <button class="btn btn-sm labelButton" style="background-color:{{label.color}};">
                    {{label.name}}
                  </button>
                </span>
            </td>
        </tr>
        <tr><td height="10px"></td></tr>
        <tr>
            <td class="gridTableColummHeader">Assigned To:</td>
            <td style="width:20px;"></td>
            <td>
              <span class="dropdown" ng-repeat="person in goalInfo.assignTo">
                <button class="btn btn-sm dropdown-toggle" type="button" id="menu1"
                   data-toggle="dropdown" style="margin:2px;padding: 2px 5px;font-size: 11px;">
                   {{bestName(person)}}</button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                   <li role="presentation"><a role="menuitem" title="{{person.name}} {{person.uid}}"
                      ng-click="removePerson(person)">Remove Address:<br/>{{person.name}}<br/>{{person.uid}}</a></li>
                   <li role="presentation"><a role="menuitem" title="Visit {{person.name}}" target="_blank"
                      href="<%=ar.retPath%>v/FindPerson.htm?uid={{person.uid}}">Visit User Page</li>
                </ul>
              </span>
              <span >
                <button class="btn btn-sm btn-primary" ng-click="showAddEmail=!showAddEmail"
                    style="margin:2px;padding: 2px 5px;font-size: 11px;">+</button>
              </span>
            </td>
        </tr>
        <tr ng-show="showAddEmail"><td height="10px"></td></tr>
        <tr ng-show="showAddEmail">
            <td ></td>
            <td style="width:20px;"></td>
            <td class="form-inline form-group">
                <button ng-click="addPerson();showAddEmail=false" class="form-control btn btn-primary">
                    Add This Email</button>
                <input type="text" ng-model="newPerson"  class="form-control"
                    placeholder="Enter Email Address" style="width:350px;"
                    typeahead="person as person.name for person in getPeople($viewValue) | limitTo:12">
            </td>
        </tr>
        <tr><td height="20px"></td></tr>
        <tr>
            <td class="gridTableColummHeader">Status:</td>
            <td style="width:20px;"></td>
            <td ng-click="startEdit()">
                {{goalInfo.status}}
            </td>
        </tr>
        <tr>
            <td ></td>
            <td style="width:20px;"></td>
            <td ng-click="startEdit()">
                <span ng-show="goalInfo.duedate>0">   <b>Due:</b>   {{goalInfo.duedate|date}}   &nbsp; &nbsp; </span>
                <span ng-show="goalInfo.startdate>0"> <b>Start:</b> {{goalInfo.startdate|date}} &nbsp; &nbsp; </span>
                <span ng-show="goalInfo.enddate>0">   <b>End:</b>   {{goalInfo.enddate|date}}   &nbsp; &nbsp; </span>
            </td>
        </tr>
        <tr><td height="20px"></td></tr>
        <tr><td></td><td></td>
            <td>
                <button class="btn btn-default" ng-click="setState(2)" ng-show="goalInfo.state<2">
                    Mark <img src="<%=ar.retPath%>assets/goalstate/small2.gif"> Offered</button>
                <button class="btn btn-default" ng-click="setState(3)" ng-show="goalInfo.state<3">
                    Mark <img src="<%=ar.retPath%>assets/goalstate/small3.gif"> Accepted</button>
                <button class="btn btn-default" ng-click="setState(5)" ng-show="goalInfo.state<5">
                    Mark <img src="<%=ar.retPath%>assets/goalstate/small5.gif"> Completed</button>

                <span class="dropdown">
                    <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                    Other <span class="caret"></span></button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation">
                          <a role="menuitem" tabindex="-1" href="#" ng-click="setState(1)">
                              Mark <img src="<%=ar.retPath%>assets/goalstate/small1.gif"> Unstarted
                          </a>
                      </li>
                      <li role="presentation">
                          <a role="menuitem" tabindex="-1" href="#" ng-click="setState(2)">
                              Mark <img src="<%=ar.retPath%>assets/goalstate/small2.gif"> Offered
                          </a>
                      </li>
                      <li role="presentation">
                          <a role="menuitem" tabindex="-1" href="#" ng-click="setState(3)">
                              Mark <img src="<%=ar.retPath%>assets/goalstate/small3.gif"> Accepted
                          </a>
                      </li>
                      <li role="presentation">
                          <a role="menuitem" tabindex="-1" href="#" ng-click="setState(4)">
                              Mark <img src="<%=ar.retPath%>assets/goalstate/small4.gif"> Waiting
                          </a>
                      </li>
                      <li role="presentation">
                          <a role="menuitem" tabindex="-1" href="#" ng-click="setState(5)">
                              Mark <img src="<%=ar.retPath%>assets/goalstate/small5.gif"> Completed
                          </a>
                      </li>
                      <li role="presentation">
                          <a role="menuitem" tabindex="-1" href="#" ng-click="setState(6)">
                              Mark <img src="<%=ar.retPath%>assets/goalstate/small6.gif"> Skipped
                          </a>
                      </li>
                      <li role="presentation">
                          <a role="menuitem" tabindex="-1" href="#" ng-click="setState(7)">
                              Mark <img src="<%=ar.retPath%>assets/goalstate/small7.gif"> Reviewing
                          </a>
                      </li>
                      <li role="presentation">
                          <a role="menuitem" tabindex="-1" href="#" ng-click="setState(8)">
                              Mark <img src="<%=ar.retPath%>assets/goalstate/small8.gif"> Paused
                          </a>
                      </li>
                    </ul>
                </span>
                &nbsp; Prospect:
                <span>
                    <img src="<%=ar.retPath%>assets/goalstate/green_off.png" ng-hide="goalInfo.prospects=='good'"
                         title="Good shape" ng-click="setProspects('good')">
                    <img src="<%=ar.retPath%>assets/goalstate/green_on.png"  ng-show="goalInfo.prospects=='good'"
                         title="Good shape">
                    <img src="<%=ar.retPath%>assets/goalstate/yellow_off.png" ng-hide="goalInfo.prospects=='ok'"
                         title="Warning" ng-click="setProspects('ok')">
                    <img src="<%=ar.retPath%>assets/goalstate/yellow_on.png"  ng-show="goalInfo.prospects=='ok'"
                         title="Warning">
                    <img src="<%=ar.retPath%>assets/goalstate/red_off.png" ng-hide="goalInfo.prospects=='bad'"
                         title="In trouble" ng-click="setProspects('bad')">
                    <img src="<%=ar.retPath%>assets/goalstate/red_on.png"  ng-show="goalInfo.prospects=='bad'"
                         title="In trouble">
                </span>
            </td>
        </tr>
        <tr><td height="50px"></td></tr>
        <tr>
            <td class="gridTableColummHeader">Linked Documents:</td>
            <td style="width:20px;"></td>
            <td >
                <span ng-repeat="doc in getDocs()" class="btn btn-sm btn-default"  style="margin:4px;"
                    ng-click="navigateToDoc(doc)">
                    <img src="<%=ar.retPath%>assets/images/iconFile.png"> {{doc.name}}
                </span>
                  <button class="btn btn-sm btn-primary" ng-click="openAttachDocument()"
                      title="Attach a document">
                      ADD </button>
            </td>
        </tr>
        <tr><td height="10px"></td></tr>
        <tr>
            <td class="gridTableColummHeader">Linked Topics:</td>
            <td style="width:20px;"></td>
            <td >
                <span ng-repeat="topic in linkedTopics" class="btn btn-sm btn-default"  style="margin:4px;"
                    ng-click="navigateToTopic(topic)">
                    <i class="fa fa-lightbulb-o" style="font-size:130%"></i> {{topic.subject}}
                </span>
            </td>
        </tr>
        <tr><td height="10px"></td></tr>
        <tr>
            <td class="gridTableColummHeader">Linked Meetings:</td>
            <td style="width:20px;"></td>
            <td >
                <span ng-repeat="meet in linkedMeetings" class="btn btn-sm btn-default"  style="margin:4px;"
                    ng-click="navigateToMeeting(meet)">
                    <i class="fa fa-gavel" style="font-size:130%"></i> {{meet.name}}
                </span>
            </td>
        </tr>
        <tr><td height="10px"></td></tr>
    </table>

    <table width="100%"  ng-show="editGoalInfo" class="well">

        <tr><td height="10px"></td></tr>
        <tr>
            <td class="gridTableColummHeader">Synopsis:</td>
            <td style="width:20px;"></td>
            <td><input ng-model="goalInfo.synopsis" class="form-control"/></td>
            <td style="width:40px;"></td>
        </tr>
        <tr><td height="10px"></td></tr>
        <tr>
            <td class="gridTableColummHeader">Description:</td>
            <td style="width:20px;"></td>
            <td><textarea ng-model="goalInfo.description" class="form-control"></textarea></td>
            <td style="width:40px;"></td>
        </tr>
        <tr><td height="10px"></td></tr>
        <tr>
            <td class="gridTableColummHeader">Labels:</td>
            <td style="width:20px;"></td>
            <td>
              <span class="dropdown" ng-repeat="role in allLabels">
                <button class="btn btn-sm dropdown-toggle labelButton" type="button" id="menu2"
                   data-toggle="dropdown" style="background-color:{{role.color}};"
                   ng-show="hasLabel(role.name)">{{role.name}}</button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
                   <li role="presentation"><a role="menuitem" title="{{add}}"
                      ng-click="toggleLabel(role)">Remove Label:<br/>{{role.name}}</a></li>
                </ul>
              </span>
              <span>
                 <span class="dropdown">
                   <button class="btn btn-sm btn-primary dropdown-toggle" type="button" id="menu1" data-toggle="dropdown"
                   style="padding: 2px 5px;font-size: 11px;"> + </button>
                   <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                     <li role="presentation" ng-repeat="rolex in allLabels">
                         <button role="menuitem" tabindex="-1" href="#"  ng-click="toggleLabel(rolex)" class="btn btn-sm labelButton"
                         ng-hide="hasLabel(rolex.name)" style="background-color:{{rolex.color}};">
                             {{rolex.name}}</button></li>
                   </ul>
                 </span>
              </span>
            </td>
        </tr>
        <tr><td height="20px"></td></tr>
        <tr>
            <td class="gridTableColummHeader">Status:</td>
            <td style="width:20px;"></td>
            <td><textarea ng-model="goalInfo.status" class="form-control"></textarea></td>
        </tr>
        <tr>
            <td class="gridTableColummHeader">Due Date:</td>
            <td style="width:20px;"></td>
            <td>
                <input type="text"
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
                    close-text="Close"/>
            </td>
        </tr>
        <tr><td height="10px"></td></tr>
        <tr>
            <td class="gridTableColummHeader">Start Date:</td>
            <td style="width:20px;"></td>
            <td>
                <input type="text"
                    style="width:150;margin-top:10px;"
                    class="form-control"
                    datepicker-popup="dd-MMMM-yyyy"
                    ng-model="dummyDate2"
                    is-open="datePickOpen2"
                    min-date="minDate"
                    datepicker-options="datePickOptions"
                    date-disabled="datePickDisable(date, mode)"
                    ng-required="true"
                    ng-click="openDatePicker2($event)"
                    close-text="Close"/>
            </td>
        </tr>
        <tr><td height="10px"></td></tr>
        <tr>
            <td class="gridTableColummHeader">End Date:</td>
            <td style="width:20px;"></td>
            <td>
                <input type="text"
                    style="width:150;margin-top:10px;"
                    class="form-control"
                    datepicker-popup="dd-MMMM-yyyy"
                    ng-model="dummyDate3"
                    is-open="datePickOpen3"
                    min-date="minDate"
                    datepicker-options="datePickOptions"
                    date-disabled="datePickDisable(date, mode)"
                    ng-required="true"
                    ng-click="openDatePicker3($event)"
                    close-text="Close"/>
            </td>
        </tr>
        <tr><td height="10px"></td></tr>
        <tr><td></td><td></td>
            <td>
                <button class="btn btn-primary" ng-click="saveGoal()">Save Edits</button>
                <button class="btn btn-primary" ng-click="undoGoalChanges()">Cancel</button>
            </td>
        </tr>
        <tr><td height="10px"></td></tr>
    </table>



    <table width="100%"  ng-show="showAccomplishment" class="well">

        <tr><td height="20px"></td></tr>
        <tr>
            <td class="gridTableColummHeader">Accomplishments:</td>
            <td style="width:20px;"></td>
            <td><textarea ng-model="newAccomplishment" class="form-control"></textarea></td>
            <td style="width:40px;"></td>
        </tr>
        <tr><td height="10px"></td></tr>
        <tr><td></td><td></td>
            <td>
                <button class="btn btn-primary" ng-click="saveAccomplishment()">Save Accomplishment</button>
                <button class="btn btn-primary" ng-click="showAccomplishment=false">Cancel</button>
            </td>
        </tr>
        <tr><td height="20px"></td></tr>
    </table>

    <table width="100%">
        <tr><td height="20px"></td></tr>
        <tr ng-show="subGoals.length>0">
            <td class="gridTableColummHeader">Sub Action Items:</td>
            <td style="width:20px;"></td>
            <td>
                <div ng-repeat="sub in subGoals">
                    <a href="task{{sub.id}}.htm">
                        <img src="<%=ar.retPath%>assets/goalstate/small{{sub.state}}.gif">
                        {{sub.synopsis}} ~ {{sub.description}}
                    </a>
                </div>
            </td>
        </tr>
    </table>





                <div class="TabbedPanelsContent" ng-show="showCreateSubProject">
                    <div class="generalHeading">Create Sub Workspace</div>
                    <div class="well">
                        <div class="generalContent">
                    <%
                        if(bookList!=null && bookList.size()<1){
                    %>
                            <div id="loginArea">
                                <span class="black">
                                    <fmt:message key="nugen.userhome.PermissionToCreateProject.text"/>
                                </span>
                            </div>
                    <%
                        }
                                    else
                                    {
                                        String actionPath=ar.retPath+"t/"+ngp.getSite().getKey()+"/"+ngp.getKey()+"/createProjectFromTask.form";
                                        String goToUrl =ar.getRequestURL()+"?taskId="+taskId;
                    %>
                            <form name="projectform" action='<%=actionPath%>' method="post" autocomplete="off" >
                                <table>
                                    <tr><td style="height:20px"></td></tr>
                                    <tr>
                                        <td class="gridTableColummHeader">Sub Workspace Name:</td>
                                        <td style="width:20px;"></td>
                                        <td>
                                            <input type="text" onblur="validateProjectField()" class="inputGeneral"
                                            name="projectname" id="projectname" value="<%ar.writeHtml(currentTaskRecord.getSynopsis());%>"
                                            onKeyup="updateVal();" onblur="addvalue();" />
                                        </td>
                                    </tr>
                                    <tr>
                                        <td class="gridTableColummHeader"></td>
                                        <td style="width:20px;"></td>
                                        <td width="396px">
                                            <b>Note:</b> From here you can create a new subproject.The subproject will be connected to this activity, and will be completed when the subproject process is completed.
                                        </td>
                                    </tr>
                                    <tr><td style="height:10px"></td></tr>
                                    <tr>
                                        <td class="gridTableColummHeader">Select Template:</td>
                                        <td style="width:20px;"></td>
                                        <td><Select class="selectGeneral" id="templateName" name="templateName">
                                            <option value="" selected>Select</option>
                                            <%
                                                for (NGPageIndex ngpi : templates){
                                                    %><option value="<%=ngpi.containerKey%>" ><%
                                                    ar.writeHtml(ngpi.containerName);
                                                    %></option><%
                                                }
                                            %>
                                                    </Select></td>
                                      </tr>
                                      <tr><td style="height:15px"></td></tr>
                                      <tr>
                                          <td class="gridTableColummHeader"><fmt:message key="nugen.userhome.Account"/></td>
                                          <td style="width:20px;"></td>
                                          <td><select class="selectGeneral" name="accountId" id="accountId">
                                            <%
                                                for (NGBook nGBook : bookList) {
                                                    String id =nGBook.getKey();
                                                    String bookName= nGBook.getFullName();
                                                    if((book!=null && id.equalsIgnoreCase(book))) {
                                                        %><option value="<%=id%>" selected><%
                                                    }
                                                    else {
                                                        %><option value="<%=id%>"><%
                                                    }
                                                    ar.writeHtml(bookName);
                                                    %></option><%
                                                }
                                            %>
                                          </select></td>
                                     </tr>
                                     <tr><td style="height:15px"></td></tr>
                                     <tr>
                                         <td class="gridTableColummHeader" style="vertical-align:top"><fmt:message key="nugen.project.desc.text"/></td>
                                         <td style="width:20px;"></td>
                                         <td><textarea name="description" id="description" class="textAreaGeneral" rows="4" tabindex=7></textarea></td>
                                     </tr>
                                     <tr><td style="height:10px"></td></tr>
                                     <tr>
                                         <td class="gridTableColummHeader"></td>
                                         <td style="width:20px;"></td>
                                         <td>
                                             <input type="button" value="Create Sub Workspace" class="btn btn-primary" onclick="createProject();" />
                                             <input type="hidden" name="goUrl" value="<%ar.writeHtml(goToUrl);%>" />
                                             <input type="hidden" id="parentProcessUrl" name="parentProcessUrl"
                                                value="<%ar.writeHtml(currentTaskRecord.getWfxmlLink(ar).getCombinedRepresentation());%>" />
                                         </td>

                                     </tr>
                                </table>
                            </form>
                  <%
                    }
                  %>
                        </div>
                        <!-- End here -->
                      </div>
                </div>
                <div class="TabbedPanelsContent" ng-show="showCreateSubGoal">
                    <div class="generalHeading">Create Sub Action</div>
                    <div class="well">
                        <div id="container">
                            <form name="createSubTaskForm" action="createSubTask.form" method="post">
                                <input type="hidden" name="go" id="go" value="<%ar.writeHtml(ar.getCompleteURL());%>"/>
                                <input type="hidden" name="assignto" value=""/>
                                    <table width="100%" border="0" cellpadding="0" cellspacing="0">
                                        <tr>
                                            <td colspan="3">
                                                <table width="100%" border="0" cellpadding="0" cellspacing="0">
                                                    <tr><td height="22px"></td></tr>
                                                    <tr>
                                                        <td class="gridTableColummHeader"><fmt:message key="nugen.process.taskname.display.text"/>:</td>
                                                        <td style="width:20px;"></td>
                                                        <td>
                                                            <input type="text" class="inputGeneral" name="taskname" id="taskname" tabindex=1 value ='<fmt:message key="nugen.process.taskname.textbox.text"/>'  onKeyup="updateTaskVal();" onfocus="clearField('taskname');" onblur="defaultTaskValue('taskname');"/>&nbsp;
                                                            <input type="hidden" name="taskId" value="<%=taskId%>" />
                                                        </td>
                                                    </tr>
                                                    <tr><td height="15px"></td></tr>
                                                    <tr>
                                                        <td class="gridTableColummHeader"><fmt:message key="nugen.process.assignto.text"/></td>
                                                        <td style="width:20px;"></td>
                                                        <td><input type="text" class="wickEnabled" name="assignto_SubTask" id="assignto_SubTask" style="height:20px" tabindex=2 value='<fmt:message key="nugen.process.emailaddress.textbox.text"/>' onkeydown="updateAssigneeVal();" autocomplete="off" onkeyup="autoComplete(event,this);"  onfocus="clearFieldAssignee('assignto_SubTask');initsmartInputWindowVlaue('smartInputFloater1','smartInputFloaterContent1');" onblur="defaultAssigneeValue('assignto_SubTask');"/>
                                                            <div style="position:relative;text-align:left">
                                                                <table class="floater" style="position:absolute;top:0;left:0;background-color:#cecece;display:none;visibility:hidden;width:397px"
                                                                    id="smartInputFloater1" rules="none" cellpadding="0" cellspacing="0" width="100%">
                                                                    <tr><td id="smartInputFloaterContent1" nowrap="nowrap"></td></tr>
                                                                </table>
                                                            </div>
                                                        </td>
                                                    </tr>
                                                    <tr><td height="15px"></td></tr>
                                                </table>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td colspan="3">
                                                <div id="assignTask" style="display: inline">
                                                    <table width="100%" border="0" cellpadding="0" cellspacing="0">
                                                        <tr>
                                                            <td class="gridTableColummHeader"><fmt:message key="nugen.process.priority.text"/></td>
                                                            <td style="width:20px;"></td>
                                                            <td>
                                                                <table>
                                                                    <tr>
                                                                        <td>
                                                                            <select name="priority" tabindex="4">
                                                                                <option selected="selected" value ="0"><fmt:message key="nugen.process.priority.High"/></option>
                                                                                <option value="1"><fmt:message key="nugen.process.priority.Medium"/></option>
                                                                                <option value="2"><fmt:message key="nugen.process.priority.Low"/></option>
                                                                            </select>
                                                                        </td>
                                                                        <td style="width:20px;"></td>
                                                                        <td style="color:#000000"><b><fmt:message key="nugen.project.duedate.text"/></b></td>
                                                                        <td style="width:10px;"></td>
                                                                        <td>
                                                                            <input class="inputGeneral" type="text" style="width:100px" name="dueDate" id="dueDate" value="" readonly="1" tabindex="6"/>
                                                                        </td>
                                                                        <td style="width:5px;"></td>
                                                                        <td>
                                                                            <img src="<%=ar.retPath%>/jscalendar/img.gif" id="btn_dueDate" style="cursor: pointer;" title="Date selector"/>
                                                                        </td>
                                                                    </tr>
                                                                </table>
                                                            </td>
                                                        </tr>
                                                        <tr><td height="15px"></td></tr>
                                                        <tr>
                                                            <td class="gridTableColummHeader"><fmt:message key="nugen.project.desc.text"/></td>
                                                            <td style="width:20px;"></td>
                                                            <td><textarea name="description" id="description" class="textAreaGeneral" rows="4" tabindex=7></textarea></td>
                                                        </tr>
                                                        <tr><td height="10px"></td></tr>
                                                        <tr>
                                                            <td class="gridTableColummHeader"></td>
                                                            <td style="width:20px;"></td>
                                                            <td><input type="button" value="Create Sub Action Item" class="btn btn-primary" tabindex=3 onclick="createSubTask();"/></td>
                                                        </tr>
                                                    </table>
                                                </div>
                                            </td>
                                        </tr>
                                        <tr><td height="40px"></td></tr>
                                    </table>
                                </form>
                            </div>
                        </div>
                    </div>




        <!-- ========================================================================= -->
        <div style="height:30px"></div>
        <div class="generalHeading">History &amp; Accomplishments
        </div>
        <div>
                <table >
                    <tr><td style="height:10px"></td>
                    </tr>
                    <tr ng-repeat="rec in allHist">
                        <td class="projectStreamIcons"  style="padding:10px;">
                            <img class="img-circle" src="<%=ar.retPath%>users/{{rec.responsible.image}}"
                                 alt="" width="50" height="50" /></td>
                        <td colspan="2"  class="projectStreamText"  style="padding:10px;max-width:600px;">
                            {{rec.time|date}} -
                            <a href="<%=ar.retPath%>v/{{rec.responsible.key}}/userSettings.htm" title="access the profile of this user, if one exists">
                                                                    <span class="red">{{rec.responsible.name}}</span>
                            </a>
                            <br/>
                            {{rec.ctxType}} -
                            <a href="">{{rec.ctxName}}</a> was {{rec.event}} - {{rec.comment}}
                            <br/>

                        </td>
                   </tr>
                </table>
        </div>



    <script type="text/javascript">

        var isfreezed = '<%=ngp.isFrozen()%>';
        var flag=false;
        var emailflag=false;
        var taskNameRequired = '<fmt:message key="nugen.process.taskname.required.error.text"/>';
        var taskName = '<fmt:message key="nugen.process.taskname.textbox.text"/>';
        var emailadd='<fmt:message key="nugen.process.emailaddress.textbox.text"/>'
        var goToUrl  ='<%=ar.getRequestURL()%>'+'?taskId='+<%=taskId%>;

        function createProject(){
        <%if (!ngp.isFrozen()) {%>
            document.forms["projectform"].submit();
        <%}else{%>
            return openFreezeMessagePopup();
        <%}%>
        }

        var callbackprocess = {
           success: function(o) {
               var respText = o.responseText;
               var json = eval('(' + respText+')');
               if(json.msgType != "success"){
                   showErrorMessage("Result", json.msg , json.comments );
              }
           },
           failure: function(o) {
                   alert("callbackprocess Error:" +o.responseText);
           }
        }

    function updateAssigneeVal(){
        emailflag=true;
    }


    function createSubTask(){
        if(isfreezed == 'false'){
            var taskname =  document.getElementById("taskname");
            var assignto =  document.getElementById("assignto_SubTask");

            if(taskname.value=='' || taskname.value==null){
                alert(taskNameRequired);
                    return false;
            }

            if(assignto.value==emailadd){
                document.getElementById("assignto_SubTask").value="";
            }
            document.forms["createSubTaskForm"].elements["assignto"].value = assignto.value;
            document.forms["createSubTaskForm"].submit();
        }else{
            return openFreezeMessagePopup();
        }
    }

    function updateTaskVal(){
        flagSubTask=true;
    }

    function clearField(elementName) {
        var task=document.getElementById(elementName).value;
        if(task==taskName){
            document.getElementById(elementName).value="";
            document.getElementById(elementName).style.color="black";
        }
    }

    function defaultTaskValue(elementName) {
        var task=document.getElementById(elementName).value;
        if(task==""){
            flag=false;
            document.getElementById(elementName).value=taskName;
            document.getElementById(elementName).style.color = "gray";
        }
    }

</script>


</div>

<script src="<%=ar.retPath%>templates/AttachDocumentCtrl.js"></script>


