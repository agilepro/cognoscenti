<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="java.util.Date"
%><%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@page import="java.text.SimpleDateFormat"
%><%@page import="com.purplehillsbooks.weaver.LicenseForUser"
%><%@page import="com.purplehillsbooks.weaver.AgendaItem"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of an Workspace and here it is used to retrieve NGWorkspace.
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
    ar.assertAccessWorkspace("Must be a member to see this task");
    boolean canUpdate = ar.canUpdateWorkspace();

    String taskId = ar.reqParam("taskId");
    GoalRecord currentTaskRecord=ngp.getGoalOrFail(taskId);
    NGBook site = ngp.getSite();

    UserProfile uProf = ar.getUserProfile();

    List<HistoryRecord> histRecs = currentTaskRecord.getTaskHistory(ngp);
    JSONArray allHist = new JSONArray();
    for (HistoryRecord history : histRecs) {
        allHist.put(history.getJSON(ngp, ar));
    }


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
    for (TopicRecord aNote : ngp.getAllDiscussionTopics()) {
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

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {
    window.setMainPageTitle("Action Item Details");
    $scope.siteId = "<%ar.writeJS(siteId);%>";
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.goalInfo  = <%goalInfo.write(out,2,4);%>;
    $scope.fullDocList = [];
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.stateName = <%stateName.write(out,2,4);%>;
    $scope.subGoals  = <%subGoals.write(out,2,4);%>;
    $scope.allHist   = <%allHist.write(out,2,4);%>;
    $scope.linkedTopics = <%linkedTopics.write(out,2,4);%>;
    $scope.linkedMeetings = <%linkedMeetings.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.taskAreaList = <%taskAreaList.write(out,2,4);%>;
    $scope.docSpaceURL = "<%ar.writeJS(docSpaceURL);%>";
    $scope.canUpdate = <%=canUpdate%>;

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
        return AllPeople.findMatchingPeople(query, $scope.goalInfo.siteKey);
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
    $scope.constructCheckItems = function() {
        var list = [];
        if ($scope.goalInfo.checklist) {
            var lines = $scope.goalInfo.checklist.split("\n");
            var idx = 0;
            lines.forEach( function(item) {
                item = item.trim();
                if (item && item.length>0) {
                    if (item.indexOf("x ")==0) {
                        list.push( {name: item.substring(2), checked:true, index: idx} );
                        idx++;
                    }
                    else {
                        list.push( {name: item, checked:false, index: idx} );
                        idx++;
                    } 
                }
            });
        }
        $scope.checkitems = list;
    }
    $scope.toggleCheckItem = function(changeIndex) {
        if (!$scope.canUpdate) {
            alert("Unable to update meeting because you are a READ-ONLY user");
            return;
        }
        $scope.checkitems.forEach( function(item) {
            if (item.index==changeIndex) {
                item.checked = !item.checked;
            }
        });
        var newList = [];
        $scope.checkitems.forEach( function(item) {
            if (item.checked) {
                newList.push("x " + item.name);
            }
            else {
                newList.push(item.name);
            }
        });
        $scope.goalInfo.checklist = newList.join("\n");
        $scope.saveGoal();
    }
    $scope.constructCheckItems();
    $scope.saveGoal = function() {
        if (!$scope.canUpdate) {
            alert("Unable to update meeting because you are a READ-ONLY user");
            return;
        }
        var postURL = "updateGoal.json?gid="+$scope.goalInfo.id;
        var postdata = angular.toJson($scope.goalInfo);
        $scope.showError=false;
        $scope.editGoalInfo=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            setGoalData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.refreshActionItem = function() {
        var postURL = "fetchGoal.json?gid="+$scope.goalInfo.id;
        $scope.showError=false;
        $scope.editGoalInfo=false;
        $http.get(postURL)
        .success( function(data) {
            setGoalData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    function setGoalData(newGoal) {
        let tempList = [];
        newGoal.docLinks.forEach( function(docid) {
            tempList.push($scope.getFullDoc(docid));
        });
        $scope.fullDocList = tempList;
        $scope.goalInfo = newGoal;
        $scope.constructCheckItems();
        $scope.refreshHistory();
    }
    
    
    $scope.saveAccomplishment = function() {
        if (!$scope.canUpdate) {
            alert("Unable to update meeting because you are a READ-ONLY user");
            return;
        }
        $scope.goalInfo.newAccomplishment = $scope.newAccomplishment;
        $scope.saveGoal();
    }
    $scope.addPerson = function() {
        if (!$scope.canUpdate) {
            alert("Unable to update meeting because you are a READ-ONLY user");
            return;
        }
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
    $scope.updatePlayers = function() {
        $scope.tagEntry = cleanUserList($scope.tagEntry);
    }    
    $scope.removePerson = function(person) {
        if (!$scope.canUpdate) {
            alert("Unable to update meeting because you are a READ-ONLY user");
            return;
        }
        var res = $scope.goalInfo.assignTo.filter( function(one) {
            return (person.uid != one.uid);
        });
        $scope.goalInfo.assignTo = res;
        $scope.saveGoal();
    }
    $scope.visitPlayer = function(player) {
        window.location = "<%=ar.retPath%>v/FindPerson.htm?uid="+player.key;
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
    $scope.changeRYG = function(newRAG) {
        if (!$scope.canUpdate) {
            alert("Unable to update meeting because you are a READ-ONLY user");
            return;
        }
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
        window.location="meetingHtml.htm?id="+encodeURIComponent(meet.id);
    }
    $scope.navigateToUser = function(player) {
        window.location="<%=ar.retPath%>v/FindPerson.htm?uid="+encodeURIComponent(player.key);
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
    $scope.navigateToDoc = function(doc) {
        window.location="DocDetail.htm?aid="+doc.id;
    }
    $scope.sendDocByEmail = function(doc) {
        window.location="SendNote.htm?att="+doc.id;
    }
    $scope.downloadDocument = function(doc) {
        window.location="a/"+doc.name;
    }
    $scope.unattachDocFromItem = function(docId) {
        if (!$scope.canUpdate) {
            alert("Unable to update meeting because you are a READ-ONLY user");
            return;
        }
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
        if (!$scope.canUpdate) {
            alert("Unable to update meeting because you are a READ-ONLY user");
            return;
        }

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>templates/AttachDocument.html<%=templateCacheDefeater%>',
            controller: 'AttachDocumentCtrl',
            size: 'lg',
            resolve: {
                containingQueryParams: function() {
                    return "goal="+$scope.goalInfo.id;
                },
                docSpaceURL: function() {
                    return $scope.docSpaceURL;
                }
            }
        });

        attachModalInstance.result
        .then(function (docList) {
            $scope.goalInfo.docLinks = docList;
            $scope.saveGoal(['docLinks']);
        }, function () {
            $scope.refreshActionItem();
        });
    };

    $scope.openInviteSender = function (player) {
        if (!$scope.canUpdate) {
            alert("Unable to update meeting because you are a READ-ONLY user");
            return;
        }

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
            message.return = "<%=ar.baseURL%><%=ar.getResourceURL(ngp, "FrontPage.htm")%>";
            $scope.sendEmailLoginRequest(message);
        }, function () {
            $scope.refreshActionItem();
        });
    };
    
    
    $scope.openModalActionItem = function (startMode) {
        if (!$scope.canUpdate) {
            alert("Unable to update meeting because you are a READ-ONLY user");
            return;
        }

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
            },
            siteInfo: function () {
              return $scope.siteInfo;
            }
          }
        });

        modalInstance.result.then(function (modifiedGoal) {
            $scope.goalInfo = modifiedGoal;
            $scope.constructCheckItems();
        }, function () {
            $scope.refreshActionItem();
        });
    };
    $scope.refreshActionItem();
    
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

<div>

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="GoalStatus.htm">List Action Items</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="#" ng-click="startEdit('details')">Edit Details</a></li>
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
            <td >
                <img ng-src="<%=ar.retPath%>assets/goalstate/large{{goalInfo.state}}.gif" />
            </td>
            <td>
                {{stateName[goalInfo.state]}} Action Item
            </td>
        </tr>
        <tr class="clickable" ng-click="startEdit('details')" 
            title="Click here to update the description of this action item">
            <td >Summary:</td>
            <td>
                <div><b>{{goalInfo.synopsis}}</b></div>
                <div ng-bind-html="goalInfo.description|wiki"></div>
                <span ng-repeat="label in getGoalLabels(goalInfo)">
                  <button class="labelButton" style="background-color:{{label.color}};">
                    {{label.name}}
                  </button>
                </span>
            </td>
        </tr>
        <tr title="The action item can be assigned to any number of people who will receive reminders until it is completed." class="clickable">
            <td  ng-click="startEdit('assignee')" >Assigned To:</td>
            <td>
                <div ng-repeat="player in goalInfo.assignTo"  style="height:40px">
                  <span class="dropdown" >
                    <span id="menu1" data-toggle="dropdown">
                    <img class="img-circle" 
                         ng-src="<%=ar.retPath%>icon/{{player.key}}.jpg" 
                         style="width:32px;height:32px" 
                         title="{{player.name}} - {{player.uid}}">
                    </span>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                          tabindex="-1" style="text-decoration: none;text-align:center">
                          {{player.name}}<br/>{{player.uid}}</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="navigateToUser(player)">
                          <span class="fa fa-user"></span> Visit Profile</a></li>
                    </ul>
                  </span>
                  <span>{{player.name}}</span>
                </div>
                
            </td>
        </tr>
        <tr ng-show="selectedPersonShow">
            <td ></td>
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
            <td >Status:</td>
            <td>
                {{goalInfo.status}}
                <span ng-hide="goalInfo.status" class="instruction"
                      style="border:1px solid gray;padding:5px 20px">
                    Click here to record status</span>
            </td>
        </tr>
        <tr class="clickable"  
            title="Manage the check list of items to do for this action">
            <td ng-click="startEdit('status')" >Checklist:</td>
            <td>
                <div ng-repeat="ci in checkitems" ng-click="toggleCheckItem(ci.index)">
                    <span ng-show="ci.checked"><i class="fa  fa-check-square-o"></i></span>
                    <span ng-hide="ci.checked"><i class="fa  fa-square-o"></i></span>
                    &nbsp; {{ci.name}}
                </div>
                <span ng-hide="checkitems.length>0" class="instruction" ng-click="startEdit('assignee')"
                      style="border:1px solid gray;padding:5px 20px">
                    Click here to create a checklist</span>
            </td>
        </tr>
        <tr title="Red-Yellow-Green is a high-level status saying how things are going generally">
            <td >R-Y-G:</td>
            <td>
                <span>
                    <img src="<%=ar.retPath%>assets/goalstate/red_off.png" ng-hide="goalInfo.prospects=='bad'"
                         title="In trouble" ng-click="changeRYG('bad')">
                    <img src="<%=ar.retPath%>assets/goalstate/red_on.png"  ng-show="goalInfo.prospects=='bad'"
                         title="In trouble">
                    <img src="<%=ar.retPath%>assets/goalstate/yellow_off.png" ng-hide="goalInfo.prospects=='ok'"
                         title="Warning" ng-click="changeRYG('ok')">
                    <img src="<%=ar.retPath%>assets/goalstate/yellow_on.png"  ng-show="goalInfo.prospects=='ok'"
                         title="Warning">
                    <img src="<%=ar.retPath%>assets/goalstate/green_off.png" ng-hide="goalInfo.prospects=='good'"
                         title="Good shape" ng-click="changeRYG('good')">
                    <img src="<%=ar.retPath%>assets/goalstate/green_on.png"  ng-show="goalInfo.prospects=='good'"
                         title="Good shape">
                </span>
            </td>
        </tr>
        <tr class="clickable" ng-click="startEdit('details')" 
            ng-show="goalInfo.duedate>0 || goalInfo.startdate>0 || goalInfo.enddate>0"
            title="Click here to update the dates of this action item">
            <td ></td>
            <td >
                <span ng-show="goalInfo.duedate>0">   
                    <b>Due:</b>   
                    {{goalInfo.duedate|cdate}}   &nbsp; &nbsp; </span>
                <span ng-show="goalInfo.startdate>0" ng-click="startEdit('details')"> 
                    <b>Start:</b> 
                    {{goalInfo.startdate|cdate}} &nbsp; &nbsp; </span>
                <span ng-show="goalInfo.enddate>0" ng-click="startEdit('details')">
                    <b>End:</b>   
                    {{goalInfo.enddate|cdate}}   &nbsp; &nbsp; </span>
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
                    </ul>
                </span>
            </td>
        </tr>
        <tr class="clickable" >
            <td class="labelColumn" ng-click="openAttachDocument()">Attachments:</td>
            <td ng-dblclick="openAttachDocument()">
                <div ng-repeat="doc in fullDocList" style="vertical-align: top">
                  <span ng-show="doc.attType=='FILE'">
                      <span ng-click="navigateToDoc(doc)"><img src="<%=ar.retPath%>assets/images/iconFile.png"></span>
                      &nbsp;
                      <span ng-click="downloadDocument(doc)"><span class="fa fa-download"></span></span>
                  </span>
                  <span  ng-show="doc.attType=='URL'">
                      <span ng-click="navigateToDoc(doc)"><img src="<%=ar.retPath%>assets/images/iconUrl.png"></span>
                      &nbsp;
                      <span ng-click="navigateToLink(doc)"><span class="fa fa-external-link"></span></span>
                  </span>
                  &nbsp;
                  <span ng-click="sendDocByEmail(doc)"><span class="fa fa-envelope-o"></span></span>&nbsp;
                  &nbsp; {{doc.name}}
                </div>
                <div ng-hide="fullDocList && fullDocList.length>0" class="doubleClickHint">
                    Double-click to add / remove attachments
                </div>
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





    <table width="100%">
        <tr><td height="20px"></td></tr>
        <tr ng-show="subGoals.length>0">
            <td >Sub Action Items:</td>
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
                            <img class="img-circle" src="<%=ar.retPath%>icon/{{rec.responsible.key}}.jpg"
                                 alt="" width="50" height="50" /></td>
                        <td colspan="2"  class="projectStreamText"  style="padding:10px;max-width:600px;">
                            {{rec.time|cdate}} -
                            <a href="<%=ar.retPath%>v/{{rec.responsible.key}}/UserSettings.htm" title="access the profile of this user, if one exists">
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


