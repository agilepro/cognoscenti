<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="java.util.Date"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="java.text.SimpleDateFormat"
%><%@page import="org.socialbiz.cog.LicenseForUser"
%><%@page import="org.socialbiz.cog.AgendaItem"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of an Workspace and here it is used to retrieve NGPage.
    3. taskId   : This parameter is id of a task and here it is used to get current task detail (GoalRecord)
                  and to pass current task id value when submitted.


*/

    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Must be a member to see meetings");

    String taskId = ar.reqParam("taskId");
    GoalRecord currentTaskRecord=ngp.getGoalOrFail(taskId);
    NGBook site = ngp.getSite();

    UserProfile uProf = ar.getUserProfile();

    List<HistoryRecord> histRecs = currentTaskRecord.getTaskHistory(ngp);
    JSONArray allHist = new JSONArray();
    for (HistoryRecord history : histRecs) {
        allHist.put(history.getJSON(ngp, ar));
    }

    List<NGPageIndex> templates = uProf.getValidTemplates(ar.getCogInstance());

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

    JSONArray linkedTopics = new JSONArray();
    String goalUniversalId = currentTaskRecord.getUniversalId();
    for (TopicRecord aNote : ngp.getAllNotes()) {
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
    
    LicenseForUser lfu = new LicenseForUser(ar.getUserProfile());
    String docSpaceURL = ar.baseURL +  "api/" + site.getKey() + "/" + ngp.getKey()
                    + "/summary.json?lic="+lfu.getId();

    JSONArray taskAreaList = new JSONArray();
    for (TaskArea ta : ngp.getTaskAreas()) {
        taskAreaList.put(ta.getMinJSON());
    }
    taskAreaList.put(new JSONObject().put("name", "Unspecified"));

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

var app = angular.module('myApp', ['ui.bootstrap','ngTagsInput','angularjs-datetime-picker']);
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {
    window.setMainPageTitle("Action Item Details");
    $scope.goalInfo  = <%goalInfo.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.stateName = <%stateName.write(out,2,4);%>;
    $scope.subGoals  = <%subGoals.write(out,2,4);%>;
    $scope.allHist   = <%allHist.write(out,2,4);%>;
    $scope.linkedTopics = <%linkedTopics.write(out,2,4);%>;
    $scope.linkedMeetings = <%linkedMeetings.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.taskAreaList = <%taskAreaList.write(out,2,4);%>;

    $scope.newPerson = "";
    $scope.selectedPersonShow = false;
    $scope.selectedPerson = "";

    $scope.inviteMsg = "Hello,\n\nYou have been asked by '<%ar.writeHtml(uProf.getName());%>' to"
                    +" participate in an action item of the project '<%ar.writeHtml(ngp.getFullName());%>'."
                    +"\n\nThe links below will make registration quick and easy, and after that you will be able to"
                    +" participate directly with the others through the site.";    
    
    $scope.tagEntry = [];
    $scope.updateTagEntry = function() {
        var newList = [];
        $scope.goalInfo.assignTo.forEach( function(item) {
           var nix = {};
           nix.name = item.name; 
           nix.uid  = item.uid; 
           nix.key  = item.key; 
           newList.push(nix)
        });
        $scope.tagEntry = newList;
    }
    $scope.updateTagEntry();
    $scope.copyTagsToRecord = function() {
        var newList = [];
        $scope.tagEntry.forEach( function(item) {
            var nix = {};
            if (item.uid) {
                nix.name = item.name; 
                nix.uid  = item.uid; 
                nix.key  = item.key;
            }
            else {
                nix.name = item.name; 
                nix.uid  = item.name;
            }    
           newList.push(nix)
        });
        var hasChanged = ($scope.goalInfo.assignTo.length != newList.length);
        $scope.goalInfo.assignTo = newList;
        if (hasChanged) {
            $scope.saveGoal();
        }
    }
    $scope.$watch(function(scope) {
        return $scope.tagEntry.length;
    }, function() {
        $scope.copyTagsToRecord();
    });    
    $scope.loadPersonList = function(query) {
        return AllPeople.findMatchingPeople(query);
    }
    $scope.toggleSelectedPerson = function(tag) {
        $scope.selectedPersonShow = !$scope.selectedPersonShow;
        $scope.selectedPerson = tag;
    }
    
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
    $scope.startEdit = function(startMode) {
        $scope.openModalActionItem(startMode);
    }
    $scope.saveGoal = function() {
        var postURL = "updateGoal.json?gid="+$scope.goalInfo.id;
        var postdata = angular.toJson($scope.goalInfo);
        $scope.showError=false;
        $scope.editGoalInfo=false;
        $scope.showAccomplishment=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.goalInfo = data;
            $scope.refreshHistory();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.undoGoalChanges = function() {
        var postURL = "fetchGoal.json?gid="+$scope.goalInfo.id;
        $scope.showError=false;
        $scope.editGoalInfo=false;
        $scope.showAccomplishment=false;
        $http.get(postURL)
        .success( function(data) {
            console.log("CALL to success from undoGoalChanges");
            $scope.goalInfo = data;
            $scope.refreshHistory();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.saveAccomplishment = function() {
        console.log("CALL to saveAccomplishment");
        $scope.goalInfo.newAccomplishment = $scope.newAccomplishment;
        $scope.saveGoal();
    }
    $scope.addPerson = function() {
        console.log("CALL to addPerson");
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
        console.log("CALL to removePerson");
        var res = $scope.goalInfo.assignTo.filter( function(one) {
            return (person.uid != one.uid);
        });
        $scope.goalInfo.assignTo = res;
        console.log("About to Save:", res);
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
    $scope.changeRAG = function(newRAG) {
        console.log("CALL to changeRAG");
        $scope.goalInfo.prospects = newRAG;
        $scope.saveGoal();
        $scope.refreshHistory();
    }

    $scope.onTimeSet = function (newDate, param) {
        $scope.goalInfo[param] = newDate.getTime();
    }

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
        window.location="noteZoom"+encodeURIComponent(oneTopic.id)+".htm";
    }
    $scope.navigateToMeeting = function(meet) {
        window.location="meetingFull.htm?id="+encodeURIComponent(meet.id);
    }
    $scope.navigateToUser = function(player) {
        window.location="<%=ar.retPath%>v/FindPerson.htm?uid="+encodeURIComponent(player.uid);
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

    $scope.getFullDoc = function(docId) {
        var doc = {};
        $scope.attachmentList.filter( function(item) {
            if (item.universalid == docId) {
                doc = item;
            }
        });
        return doc;
    }
    $scope.navigateToDocOld = function(doc) {
        if (!doc.id) {
            console.log("DOCUMENT without id", doc);
            alert("That document does not have an id");
            return;
        }
        window.location="docinfo"+doc.id+".htm";
    }
    $scope.navigateToDoc = function(docId) {
        var doc = $scope.getFullDoc(docId);
        window.location="docinfo"+doc.id+".htm";
    }
    $scope.navigateToDocDetails = function(docId) {
        var doc = $scope.getFullDoc(docId);
        window.location="editDetails"+doc.id+".htm";
    }
    $scope.sendDocByEmail = function(docId) {
        var doc = $scope.getFullDoc(docId);
        window.location="sendNote.htm?att="+doc.id;
    }
    $scope.downloadDocument = function(docId) {
        var doc = $scope.getFullDoc(docId);
        window.location="a/"+doc.name;
    }
    $scope.unattachDocFromItem = function(docId) {
        var newList = [];
        $scope.goalInfo.docLinks.forEach( function(iii) {
            if (iii != docId) {
                newList.push(iii);
            }
        });
        $scope.goalInfo.docLinks = newList;
        $scope.saveGoal(['docLinks']);
    }
    $scope.openAttachDocument = function () {

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>templates/AttachDocument.html<%=templateCacheDefeater%>',
            controller: 'AttachDocumentCtrl',
            size: 'lg',
            resolve: {
                docList: function () {
                    return JSON.parse(JSON.stringify($scope.goalInfo.docLinks));
                },
                attachmentList: function() {
                    return $scope.attachmentList;
                },
                docSpaceURL: function() {
                    return "<%ar.writeJS(docSpaceURL);%>";
                }
            }
        });

        attachModalInstance.result
        .then(function (docList) {
            console.log("CALL to save from openAttachDocument");
            $scope.goalInfo.docLinks = docList;
            $scope.saveGoal(['docLinks']);
        }, function () {
            //cancel action - nothing really to do
        });
    };

    $scope.openInviteSender = function (player) {

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/InviteModal.html<%=templateCacheDefeater%>',
            controller: 'InviteModalCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                email: function () {
                    return player.uid;
                },
                msg: function() {
                    return $scope.inviteMsg;
                }
            }
        });

        modalInstance.result.then(function (message) {
            $scope.inviteMsg = message.msg;
            message.userId = player.uid;
            message.name = player.name;
            message.return = "<%=ar.baseURL%><%=ar.getResourceURL(ngp, "frontPage.htm")%>";
            $scope.sendEmailLoginRequest(message);
        }, function () {
            //cancel action - nothing really to do
        });
    };
    
    
    $scope.openModalActionItem = function (startMode) {

        var modalInstance = $modal.open({
          animation: false,
          templateUrl: '<%=ar.retPath%>templates/ActionItem.html<%=templateCacheDefeater%>',
          controller: 'ActionItemCtrl',
          size: 'lg',
          backdrop: "static",
          resolve: {
            goal: function () {
              return $scope.goalInfo;
            },
            taskAreaList: function () {
              return $scope.taskAreaList;
            },
            allLabels: function () {
              return $scope.allLabels;
            },
            startMode: function () {
              return startMode;
            }
          }
        });

        modalInstance.result.then(function (modifiedGoal) {
            $scope.goalInfo = modifiedGoal;
        }, function () {
          //cancel action
        });
    };
    
});

function addvalue() {
    if(flag==false){
        document.getElementById("projectname").value=projectNameTitle;
    }
}

</script>

<style>
.clickable:hover {
    cursor:pointer;
    background-color:#DDEEFF;
}
.clickable {
    cursor:pointer;
}
</style>

<script src="../../../jscript/AllPeople.js"></script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="statusList.htm">List Action Items</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="#" ng-click="startEdit('details')">Edit Details</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="#" ng-click="showAccomplishment=!showAccomplishment;editGoalInfo=false;">Record Accomplishment</a></li>
          <!--li role="presentation"><a role="menuitem" tabindex="-1"
              href="#" ng-click="showCreateSubGoal=!showCreateSubGoal">Create Sub Action</a></li>
          <li role="presentation"><a role="menuitem"
              href="#" ng-click="showCreateSubProject=!showCreateSubProject">Convert to Workspace</a></li-->
        </ul>
      </span>
    </div>
    
<style>
.spaceyTable {
    width:100%;
}
.spaceyTable tr td{
    padding:10px;
}
.gridTableColummHeader {
    max-width:150px;
}
</style>    

    <table ng-hide="editGoalInfo" class="spaceyTable">
        <tr class="clickable" ng-click="startEdit('assignee')" 
            title="Click here to update the status of this action item">
            <td class="gridTableColummHeader">
                <img ng-src="<%=ar.retPath%>assets/goalstate/large{{goalInfo.state}}.gif" />
            </td>
            <td>
                {{stateName[goalInfo.state]}} Action Item
            </td>
        </tr>
        <tr class="clickable" ng-click="startEdit('details')" 
            title="Click here to update the description of this action item">
            <td class="gridTableColummHeader">Summary:</td>
            <td>
                <b>{{goalInfo.synopsis}}</b>
                ~ {{goalInfo.description}}
                <span ng-repeat="label in getGoalLabels(goalInfo)">
                  <button class="labelButton" style="background-color:{{label.color}};">
                    {{label.name}}
                  </button>
                </span>
            </td>
        </tr>
        <tr title="The action item can be assigned to any number of people who will receive reminders until it is completed.">
            <td class="gridTableColummHeader">Assigned To:</td>
            <td>
              <tags-input ng-model="tagEntry" placeholder="Enter user name or id" display-property="name" key-property="uid" on-tag-clicked="toggleSelectedPerson($tag)">
                  <auto-complete source="loadPersonList($query)"></auto-complete>
              </tags-input>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
                   <li role="presentation"><a role="menuitem" title="{{add}}"
                      ng-click="">Remove Label:<br/>{{role.name}}</a></li>
                </ul>
            </td>
        </tr>
        <tr ng-show="selectedPersonShow">
            <td class="gridTableColummHeader"></td>
            <td class="well"> 
               for <b>{{selectedPerson.name}}</b>:
               <button ng-click="navigateToUser(selectedPerson)" class="btn btn-info">
                   Visit Profile</button>
               <button ng-click="openInviteSender(selectedPerson)" class="btn btn-info">
                   Invite</button>
               <button ng-click="selectedPersonShow=false" class="btn btn-info">
                   Hide</button>
            </td>
        </tr>
        <tr class="clickable" ng-click="startEdit('status')" 
            title="Click here to update the status of this action item">
            <td class="gridTableColummHeader">Status:</td>
            <td>
                {{goalInfo.status}}
                <span ng-hide="goalInfo.status" class="instruction" 
                      style="border:1px solid gray;padding:5px 20px">
                    Click here to record status</span>
            </td>
        </tr>
        <tr title="Red-Yellow-Green is a high-level status saying how things are going generally">
            <td class="gridTableColummHeader">R-Y-G:</td>
            <td>
                <span>
                    <img src="<%=ar.retPath%>assets/goalstate/red_off.png" ng-hide="goalInfo.prospects=='bad'"
                         title="In trouble" ng-click="changeRAG('bad')">
                    <img src="<%=ar.retPath%>assets/goalstate/red_on.png"  ng-show="goalInfo.prospects=='bad'"
                         title="In trouble">
                    <img src="<%=ar.retPath%>assets/goalstate/yellow_off.png" ng-hide="goalInfo.prospects=='ok'"
                         title="Warning" ng-click="changeRAG('ok')">
                    <img src="<%=ar.retPath%>assets/goalstate/yellow_on.png"  ng-show="goalInfo.prospects=='ok'"
                         title="Warning">
                    <img src="<%=ar.retPath%>assets/goalstate/green_off.png" ng-hide="goalInfo.prospects=='good'"
                         title="Good shape" ng-click="changeRAG('good')">
                    <img src="<%=ar.retPath%>assets/goalstate/green_on.png"  ng-show="goalInfo.prospects=='good'"
                         title="Good shape">
                </span>
            </td>
        </tr>
        <tr class="clickable" ng-click="startEdit('status')" 
            ng-show="goalInfo.duedate>0 || goalInfo.startdate>0 || goalInfo.enddate>0"
            title="Click here to update the dates of this action item">
            <td ></td>
            <td >
                <span ng-show="goalInfo.duedate>0">   
                    <b>Due:</b>   
                    {{goalInfo.duedate|date}}   &nbsp; &nbsp; </span>
                <span ng-show="goalInfo.startdate>0" ng-click="startEdit('details')"> 
                    <b>Start:</b> 
                    {{goalInfo.startdate|date}} &nbsp; &nbsp; </span>
                <span ng-show="goalInfo.enddate>0" ng-click="startEdit('details')">
                    <b>End:</b>   
                    {{goalInfo.enddate|date}}   &nbsp; &nbsp; </span>
            </td>
        </tr>
        <tr><td></td>
            <td>
                <button class="btn btn-default btn-raised" ng-click="setState(2)" ng-show="goalInfo.state<2">
                    Mark <img src="<%=ar.retPath%>assets/goalstate/small2.gif"> Offered</button>
                <button class="btn btn-default btn-raised" ng-click="setState(3)" ng-show="goalInfo.state<3">
                    Mark <img src="<%=ar.retPath%>assets/goalstate/small3.gif"> Accepted</button>
                <button class="btn btn-default btn-raised" ng-click="setState(5)" ng-show="goalInfo.state<5">
                    Mark <img src="<%=ar.retPath%>assets/goalstate/small5.gif"> Completed</button>

                <span class="dropdown">
                    <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
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
                      <!--li role="presentation">
                          <a role="menuitem" tabindex="-1" href="#" ng-click="setState(4)">
                              Mark <img src="<%=ar.retPath%>assets/goalstate/small4.gif"> Waiting
                          </a>
                      </li-->
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
                      <!--li role="presentation">
                          <a role="menuitem" tabindex="-1" href="#" ng-click="setState(7)">
                              Mark <img src="<%=ar.retPath%>assets/goalstate/small7.gif"> Reviewing
                          </a>
                      </li-->
                      <!--li role="presentation">
                          <a role="menuitem" tabindex="-1" href="#" ng-click="setState(8)">
                              Mark <img src="<%=ar.retPath%>assets/goalstate/small8.gif"> Paused
                          </a>
                      </li-->
                    </ul>
                </span>
            </td>
        </tr>
        <tr>
              <td>Attachments: </td>
              <td ><span ng-repeat="docid in goalInfo.docLinks" style="vertical-align: top">
                  <span class="dropdown" title="Access this attachment">
                      <button class="attachDocButton" id="menu1" data-toggle="dropdown">
                      <img src="<%=ar.retPath%>assets/images/iconFile.png"> 
                      {{getFullDoc(docid).name | limitTo : 15}}</button>
                      <ul class="dropdown-menu" role="menu" aria-labelledby="menu1" style="cursor:pointer">
                        <li role="presentation" style="background-color:lightgrey">
                            <a role="menuitem" 
                            title="This is the full name of the document"
                            ng-click="navigateToDoc(docid)">{{getFullDoc(docid).name}}</a></li>
                        <li role="presentation"><a role="menuitem" 
                            title="Use DRAFT to set the meeting without any notifications going out"
                            ng-click="navigateToDoc(docid)">Access Document</a></li>
                        <li role="presentation"><a role="menuitem"
                            title="Use PLAN to allow everyone to get prepared for the meeting"
                            ng-click="downloadDocument(docid)">Download File</a></li>
                        <li role="presentation"><a role="menuitem"
                            title="Use RUN while the meeting is actually in session"
                            ng-click="navigateToDocDetails(docid).htm">Document Details</a></li>
                        <li role="presentation"><a role="menuitem"
                            title="Use RUN while the meeting is actually in session"
                            ng-click="sendDocByEmail(docid)">Send by Email</a></li>
                        <li role="presentation"><a role="menuitem"
                            title="Use RUN while the meeting is actually in session"
                            ng-click="unattachDocFromItem(docid)">Un-attach</a></li>
                      </ul>
                  </span>
              </span>
              <button class="btn btn-sm btn-primary btn-raised" ng-click="openAttachDocument()"
                  title="Attach a document">
                  ADD </button>
           </td>
        </tr>
        <tr>
            <td title="On the discussion topic page, you can link action items, and those topics will appear here">Linked Topics:</td>
            <td title="On the discussion topic page, you can link action items, and those topics will appear here">
                <span ng-repeat="topic in linkedTopics" class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
                    ng-click="navigateToTopic(topic)">
                    <i class="fa fa-lightbulb-o" style="font-size:130%"></i> {{topic.subject}}
                </span>
                <span ng-show="!linkedTopics || linkedTopics.length==0" style="color:lightgray">
                    No discussion topics have links to this action item.
                </span>
            </td>
        </tr>
        <tr>
            <td title="On the meeting page, you can link action items, and those meetings will appear here">
                Linked Meetings:</td>
            <td title="On the meeting page, you can link action items, and those meetings will appear here">
                <span ng-repeat="meet in linkedMeetings" class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
                    ng-click="navigateToMeeting(meet)">
                    <i class="fa fa-gavel" style="font-size:130%"></i> {{meet.name}}
                </span>
                <span ng-show="!linkedMeetings || linkedMeetings.length==0" style="color:lightgray">
                    No meetings have links to this action item.
                </span>
            </td>
        </tr>
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
                <button class="btn btn-primary btn-raised" ng-click="saveAccomplishment()">Save Accomplishment</button>
                <button class="btn btn-primary btn-raised" ng-click="showAccomplishment=false">Cancel</button>
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
                        <img ng-src="<%=ar.retPath%>assets/goalstate/small{{sub.state}}.gif">
                        {{sub.synopsis}} ~ {{sub.description}}
                    </a>
                </div>
            </td>
        </tr>
    </table>

<script>
function updateVal(){
  flag=true;
}
</script>



                <div class="TabbedPanelsContent" ng-show="showCreateSubProject">
                    <div class="generalSubHeading">Create Sub Workspace</div>
                    <div class="well">
                        <div class="generalContent">
                    <%
                        List<NGBook> bookList = NGBook.getAllSites();
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
                                                for (NGBook nGBook : NGBook.getAllSites()) {
                                                    String id =nGBook.getKey();
                                                    String bookName= nGBook.getFullName();
                                                    if((siteId!=null && id.equalsIgnoreCase(siteId))) {
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
                                             <input type="button" value="Create Sub Workspace" class="btn btn-primary btn-raised" onclick="createProject();" />
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
                    <div class="generalSubHeading">Create Sub Action</div>
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
                                                            <td><input type="button" value="Create Sub Action Item" class="btn btn-primary btn-raised" tabindex=3 onclick="createSubTask();"/></td>
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
        <div class="generalSubHeading">History &amp; Accomplishments
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

<script src="<%=ar.retPath%>templates/ActionItemCtrl.js"></script>
<script src="<%=ar.retPath%>templates/AttachDocumentCtrl.js"></script>
<script src="<%=ar.retPath%>templates/InviteModal.js"></script>


