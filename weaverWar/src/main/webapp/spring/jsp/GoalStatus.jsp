<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="java.util.Date"
%><%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@page import="java.text.SimpleDateFormat"
%><%@page import="com.purplehillsbooks.weaver.MicroProfileMgr"
%><%@page import="com.purplehillsbooks.weaver.TaskArea"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of a workspace and here it is used to retrieve NGWorkspace.

*/

    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }

    String pageId  = ar.reqParam("pageId");
    String siteId  = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Must be a member to see meetings");
    NGBook site = ngp.getSite();

    List<GoalRecord> allGoalsRaw = ngp.getAllGoals();
    JSONArray allGoals = new JSONArray();
    for (GoalRecord gr : allGoalsRaw) {
        if (!gr.isPassive()) {
            allGoals.put(gr.getJSON4Goal(ngp));
        }
    }

    UserProfile uProf = ar.getUserProfile();


    List<NGPageIndex> templates = uProf.getValidTemplates(ar.getCogInstance());

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
    
    JSONArray taskAreaList = new JSONArray();
    for (TaskArea ta : ngp.getTaskAreas()) {
        taskAreaList.put(ta.getMinJSON());
    }
    taskAreaList.put(new JSONObject().put("name", "Unspecified"));

/*** PROTOTYPE

    $scope.allGoals  = {
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
    window.setMainPageTitle("Action Item Status");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.allGoals  = <%allGoals.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.stateName = <%stateName.write(out,2,4);%>;
    $scope.taskAreaList = <%taskAreaList.write(out,2,4);%>;
    $scope.filter = "";
    $scope.filterMap = {};
    $scope.showActive = true;
    $scope.showFuture = false;
    $scope.showCompleted = false;
    $scope.showRecent = true;
    $scope.showChecklists = true;
    $scope.showDescription = true;
    $scope.mineOnly = false;
    $scope.isCreating = false;
    $scope.newGoal = {assignList:[],id:"~new~",labelMap:{}};

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

    $scope.findGoalsInArea = function(areaId) {
        var lcFilterList = $scope.filter.toLowerCase().split(" ");
        $scope.allGoals.sort( function(a,b) {
            return a.rank-b.rank;
        });
        var src = [];
        $scope.allGoals.forEach( function(item) {
            item.html = convertMarkdownToHtml(item.description);
            if (areaId!=null && areaId.length>0) {
                if (areaId==item.taskArea) {
                    src.push(item);
                }
            }
            else if (item.taskArea==null || item.taskArea.length==0) {
                src.push(item);
            }
        });
        var res = [];
        src.forEach( function(rec) {
            if (goalMatchedFilter(rec, lcFilterList)) {
                res.push(rec);
            }
        });
        src = res;
        var allReqLabels = $scope.allLabelFilters();
        allReqLabels.forEach( function(label) {
            var requiredLabel = label.name;
            var res = [];
            src.forEach( function(rec) {
                if (rec.labelMap[requiredLabel]) {
                    res.push(rec);
                }
            });
            src = res;
        });
        return src;
    };
    
    function goalMatchedFilter(rec, lcFilterList) {
        var recentTime = (new Date()).getTime() - 7*24*60*60*1000;
        if ($scope.mineOnly) {
            var found = false;
            rec.assignees.forEach( function(ass) {
                if (ass == SLAP.loginInfo.userId) {
                    found = true;
                }
            });
            if (!found) {
                return false;
            }
        }
        let isRecent = ($scope.showRecent && (rec.modifiedtime > recentTime || rec.startdate > recentTime || rec.enddate > recentTime));
        if (!isRecent && !$scope.showActive && rec.state>=2 && rec.state<=4) {
            return false;
        }
        if (!isRecent && !$scope.showFuture && rec.state==1) {
            return false;
        }
        if (!isRecent && !$scope.showCompleted && rec.state>=5) {
            return false;
        }
        if ($scope.filter.length==0) {
            return true;
        }
        if (containsOne(rec.synopsis.toLowerCase(),lcFilterList)) {
            return true;
        }
        if (containsOne(rec.description.toLowerCase(),lcFilterList)) {
            return true;
        }
        for (var i=rec.assignees.length-1; i>=0; i--) {
            if (containsOne(rec.assignees[i].toLowerCase(),lcFilterList)) {
                return true;
            }
        }
        return false;
    }

    $scope.findGoals = function() {
        var lcFilterList = parseLCList($scope.filter);
        $scope.allGoals.sort( function(a,b) {
            return a.rank-b.rank;
        });
        var src = $scope.allGoals;
        var res = [];
        src.forEach( function(rec) {
            if (goalMatchedFilter(rec, lcFilterList)) {
                res.push(rec);
            }
        });
        src = res;
        var allReqLabels = $scope.allLabelFilters();
        allReqLabels.forEach( function(label) {
            var requiredLabel = label.name;
            var res = [];
            src.forEach( function(rec) {
                if (rec.labelMap[requiredLabel]) {
                    res.push(rec);
                }
            });
            src = res;
        });
        return src;
    };    
    $scope.swapItems = function(item, amt) {
        let movingUp = (amt<0);
        var list = $scope.findGoalsInArea(item.taskArea);
        console.log("List is: ", list);

        var foundAt = -1;
        var index = -1;
        list.forEach( function(ele) {
            index++;
            if (ele.id == item.id) {
                foundAt = index;
            }
        });
        if (foundAt<0) {
            alert("Could not find the item in the current filtered list: "+item.synopsis);
            return;
        }
        var otherPos = foundAt + amt;
        if (otherPos<0) {
            alert("can't move up off the beginning of the list or out of a task group "+item.taskArea);
            return;
        }
        if (otherPos>=list.length) {
            alert("can't move down off the end of the list or out of a task group "+item.taskArea);
            return;
        }
        var otherItem = list[otherPos];
        var otherRank = otherItem.rank;
        otherItem.rank = item.rank;
        item.rank = otherRank;

        $scope.saveGoals([otherItem,item]);
    }

    $scope.replaceGoal = function(goal) {
        var newList = $scope.allGoals.filter( function(item) {
            return item.id != goal.id;
        });
        newList.push(goal);
        $scope.allGoals = newList;
        $scope.constructAllCheckItems();
    }
    $scope.saveGoal = function(goal) {
        var postURL = "updateGoal.json?gid="+goal.id;
        var objForUpdate = {};
        objForUpdate.id = goal.id;
        objForUpdate.universalid = goal.universalid;
        objForUpdate.rank = goal.rank;  
        objForUpdate.prospects = goal.prospects;  
        objForUpdate.duedate = goal.duedate;  
        objForUpdate.status = goal.status;  
        objForUpdate.checklist = goal.checklist;  
        var postdata = angular.toJson(objForUpdate);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.replaceGoal(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.saveArea = function(area) {
        var postURL = "taskArea"+area.id+".json";
        var postdata = angular.toJson(area);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            //do nothing for now
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.saveGoals = function(goalList) {
        var postURL = "updateMultiGoal.json";
        var objectList = [];

        goalList.forEach( function(item) {
            var objForUpdate = {};
            objForUpdate.id = item.id;
            objForUpdate.universalid = item.universalid;
            objForUpdate.rank = item.rank;  //only thing that could have been changed
            objectList.push(objForUpdate);
        });
        var envelope = {};
        envelope.list = objectList;

        var postdata = angular.toJson(envelope);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            data.list.forEach( function(dataItem) {
                $scope.replaceGoal(dataItem);
            });
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };


    $scope.makeState = function(rec, newState) {
        var newRec = {};
        newRec.id = rec.id;
        newRec.universalid = rec.universalid;
        newRec.state = newState;
        newRec.modifiedtime = new Date().getTime();
        newRec.modifieduser = SLAP.loginInfo.userId;

        var postURL = "updateGoal.json?gid="+rec.id;
        var postdata = angular.toJson(newRec);
        $http.post(postURL, postdata)
        .success( function(data) {
            rec.state = data.state;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }

    $scope.getPeople = function(query) {
        return AllPeople.findMatchingPeople(query, $scope.siteInfo.key);
    }

    $scope.createNewGoal = function() {
        var newRec = $scope.newGoal;
        newRec.id = "~new~";
        newRec.universalid = "~new~";
        newRec.assignTo = [];
        newRec.state = 2;
        newRec.assignTo = newRec.assignList;
        newRec.modifiedtime = new Date().getTime();
        newRec.modifieduser = SLAP.loginInfo.userId;

        var postURL = "updateGoal.json?gid=~new~";
        var postData = angular.toJson(newRec);
        $http.post(postURL, postData)
        .success( function(data) {
            $scope.allGoals.push(data);
            $scope.newGoal = {};
            $scope.isCreating = false;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.datePickOptions = {
        formatYear: 'yyyy',
        startingDay: 1
    };
    $scope.datePickDisable = function(date, mode) {
        return false;
    };
    $scope.datePickOpen1 = false;
    $scope.openDatePicker1 = function($event) {
        $event.preventDefault();
        $event.stopPropagation();
        $scope.datePickOpen1 = true;
    };
    $scope.getGoalLabels = function(goal) {
        var res = [];
        $scope.allLabels.map( function(val) {
            if (goal.labelMap[val.name]) {
                res.push(val);
            }
        });
        return res;
    }
    $scope.hasLabel = function(searchName) {
        return $scope.filterMap[searchName];
    }
    $scope.toggleLabel = function(label) {
        $scope.filterMap[label.name] = !$scope.filterMap[label.name];
    }
    $scope.allLabelFilters = function() {
        var res = [];
        $scope.allLabels.map( function(val) {
            if ($scope.filterMap[val.name]) {
                res.push(val);
            }
        });
        return res;
    }
    $scope.getName = function(uid) {
        var person = $scope.getPeople(uid);
        if (!person) {
            return uid;
        }
        if (person.length==0) {
            return uid;
        }
        if (person[0].name) {
            return person[0].name;
        }
        return "("+uid+")";
    }
    $scope.getLink = function(uid) {
        var person = $scope.getPeople(uid);
        return "<%=ar.retPath%>v/FindPerson.htm?uid="+encodeURIComponent(uid);
    }
    $scope.showUser = function(tag) {
        //alert("gotcha:" + tag.name);
    }

    $scope.setProspects = function(goal, newVal, $event) {
        goal.prospects = newVal;
        $scope.saveGoal(goal);
        $event.stopPropagation();
    }
    $scope.setProspectArea = function(area, newVal, $event) {
        area.prospects = newVal;
        $scope.saveArea(area);
        $event.stopPropagation();
    }

    $scope.openModalActionItem = function (goal, startMode) {

        var modalInstance = $modal.open({
          animation: false,
          templateUrl: '<%=ar.retPath%>templates/ActionItem.html<%=templateCacheDefeater%>',
          controller: 'ActionItemCtrl',
          size: 'lg',
          backdrop: "static",
          resolve: {
            goal: function () {
              return goal;
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
            siteId: function () {
              return $scope.siteInfo.key;
            }
          }
        });

        modalInstance.result.then(function (modifiedGoal) {
            let newList = [];
            $scope.allGoals.map( function(item) {
                let found = false;
                if (item.id == modifiedGoal.id) {
                    newList.push(modifiedGoal);
                    found = true;
                }
                else {
                    newList.push(modifiedGoal);
                }
                if (!found) {
                    newList.push(modifiedGoal);
                }
            });
            $scope.saveGoal(modifiedGoal);
            var lcFilterList = $scope.filter.toLowerCase().split(" ");
            if (!goalMatchedFilter(modifiedGoal, lcFilterList)) {
                alert("Note: the action item you created does not match your current filter criteria ("+$scope.filter+")\nand will not appear in the list.\nModify your filter to see it.")
            }
        }, function () {
          //cancel action
        });
    };

    $scope.getTaskAreas = function() {
        var getURL = "taskAreas.json";
        $http.get(getURL)
        .success( function(data) {
            $scope.taskAreaList = data.taskAreas;
            $scope.taskAreaList.push( {name:"Unspecified"} );
            $scope.loaded = true;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    
    $scope.getTaskAreas();
    
    $scope.constructAllCheckItems = function() {
        $scope.allGoals.forEach( function(actionItem) {
            var list = [];
            if (actionItem.checklist) {
                var lines = actionItem.checklist.split("\n");
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
            actionItem.checkitems = list;
        });
    }
    $scope.toggleCheckItem = function($event,item, changeIndex) {
        item.checkitems.forEach( function(item) {
            if (item.index==changeIndex) {
                item.checked = !item.checked;
            }
        });
        var newList = [];
        item.checkitems.forEach( function(item) {
            if (item.checked) {
                newList.push("x " + item.name);
            }
            else {
                newList.push(item.name);
            }
        });
        item.checklist = newList.join("\n");
        $scope.saveGoal(item);
        $event.stopPropagation();
    }
    
    $scope.constructAllCheckItems();
    
    
    $scope.openTaskAreaEditor = function (ta) {
        
        if (!ta.id) {
            alert("This group ("+ta.name+") is not a real task area and you can not edit it...");
            return;
        }

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/TaskAreaModal.html<%=templateCacheDefeater%>',
            controller: 'TaskAreaCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                id: function () {
                    return ta.id;
                },
                siteId: function() {return $scope.siteInfo.key}
            }
        });

        modalInstance.result.then(function (modifiedTaskArea) {
            $scope.getTaskAreas();
        }, function () {
            $scope.getTaskAreas();
        });
    };
    
    $scope.imageName = function(player) {
        if (player.key) {
            if (player.key.indexOf("@")<0) {
                return player.key+".jpg";
            }
        }
        var lc = player.uid.toLowerCase();
        var ch = lc.charAt(0);
        var i =1;
        while(i<lc.length && (ch<'a'||ch>'z')) {
            ch = lc.charAt(i); i++;
        }
        return "fake-"+ch+".jpg";
    }
    $scope.navigateToUser = function(player) {
        window.location="<%=ar.retPath%>v/FindPerson.htm?uid="+encodeURIComponent(player.key);
    }

});

function addvalue() {
    if(flag==false){
        document.getElementById("projectname").value=projectNameTitle;
    }
}

</script>
<script src="../../../jscript/AllPeople.js"></script>

<div>


<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              ng-click="openModalActionItem(newGoal,'details')">Create New Action Item</a></li>
          <li role="presentation" class="divider"></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="goalList.htm">Action Items View</a></li>
          <li role="presentation"><a style="color:lightgrey">Status List View</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="taskAreas.htm">Manage Task Areas</a></li>
        </ul>
      </span>
    </div>


    <div class="well" ng-show="!isCreating">
        Filter <input ng-model="filter"> &nbsp;
        <span style="vertical-align:middle;" ><input type="checkbox" ng-model="showActive">
            Active</span> &nbsp;
        <span style="vertical-align:middle;" ><input type="checkbox" ng-model="showFuture">
            Future</span> &nbsp;
        <span style="vertical-align:middle;" ><input type="checkbox" ng-model="showCompleted">
            Completed</span>
        <span style="vertical-align:middle;" ><input type="checkbox" ng-model="showRecent">
            Recent</span>
        <span style="vertical-align:middle;" ><input type="checkbox" ng-model="mineOnly">
            Only Mine</span>
        <span class="dropdown" ng-repeat="role in allLabelFilters()">
            <button class="labelButton" type="button" id="menu2"
               data-toggle="dropdown" style="background-color:{{role.color}};"
               ng-show="hasLabel(role.name)">{{role.name}} <i class="fa fa-close"></i></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
               <li role="presentation"><a role="menuitem" title="{{add}}"
                  ng-click="toggleLabel(role)">Remove Filter:<br/>{{role.name}}</a></li>
            </ul>
        </span>
        <span>
             <span class="dropdown">
               <button class="btn btn-sm btn-primary btn-raised dropdown-toggle" type="button" id="menu2" data-toggle="dropdown"
                       title="Add Filter by Label"><i class="fa fa-filter"></i></button>
               <ul class="dropdown-menu" role="menu" aria-labelledby="menu1" 
                   style="width:320px;left:-130px">
                 <li role="presentation" ng-repeat="rolex in allLabels" style="float:left">
                     <button role="menuitem" tabindex="-1" ng-click="toggleLabel(rolex)" class="labelButton" 
                     ng-hide="hasLabel(rolex.name)" style="background-color:{{rolex.color}}">
                         {{rolex.name}}</button>
                 </li>
               </ul>
             </span>
        </span>
        <span style="vertical-align:middle;" ><input type="checkbox" ng-model="showChecklists">
            Show Checklists</span>
        <span style="vertical-align:middle;" ><input type="checkbox" ng-model="showDescription">
            Show Description</span>
    </div>




<style>
.statusTable {
    width:100%;
    border-collapse: separate;
}
.headerRow td {
    padding:3px;
    padding-top:20px;
    background-color:#EEE;
}
.outlined td {
    padding:3px;
    border-width:1px;
    border-style:solid;
    border-color:grey;
}
.statusTable tr th{
    padding:3px;
}
.stoplight {
    height: 20px;
    width: 20px; 
    margin:0px;    
}
</style>

  <table style="width:100%">
    <tr>
       <th></th>
       <th>Synopsis</th>
       <th>Assigned</th>
       <th title="Dates that the action was started, due, and completed">Dates</th>
       <th title="Give a Red-Yellow-Green indication of how it is going"></th>
       <th title="A written summary of the current status">Status</th>
    </tr>
    <tbody ng-repeat="area in taskAreaList">
      <tr class="headerRow">
        <td colspan="2" ng-dblclick="openTaskAreaEditor(area)">{{area.name}}&nbsp;</td>
        <td colspan="2">
            <div ng-repeat="person in area.assignees">
              <span class="dropdown">
                <span id="menu1" data-toggle="dropdown">
                <img class="img-circle" src="<%=ar.retPath%>icon/{{imageName(person)}}" 
                     style="width:32px;height:32px" title="{{person.name}} - {{person.uid}}">
                </span>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                      tabindex="-1" ng-click="" style="text-decoration: none;text-align:center">
                      {{person.name}}<br/>{{person.uid}}</a></li>
                  <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                      ng-click="navigateToUser(person)">
                      <span class="fa fa-user"></span> Visit Profile</a></li>
                </ul>
              </span>
            </div>
        </td>
        <td style="width:72px;padding:0px;" title="Give a Red-Yellow-Green indication of how it is going">
          <span>
            <img src="<%=ar.retPath%>assets/goalstate/red_off.png" ng-hide="area.prospects=='bad'"
                 title="Red: In trouble" ng-click="setProspectArea(area, 'bad', $event)" class="stoplight">
            <img src="<%=ar.retPath%>assets/goalstate/red_on.png"  ng-show="area.prospects=='bad'"
                 title="Red: In trouble" class="stoplight">
            <img src="<%=ar.retPath%>assets/goalstate/yellow_off.png" ng-hide="area.prospects=='ok'"
                 title="Yellow: Warning" ng-click="setProspectArea(area, 'ok', $event)" class="stoplight">
            <img src="<%=ar.retPath%>assets/goalstate/yellow_on.png"  ng-show="area.prospects=='ok'"
                 title="Yellow: Warning" class="stoplight">
            <img src="<%=ar.retPath%>assets/goalstate/green_off.png" ng-hide="area.prospects=='good'"
                 title="Green: Good shape" ng-click="setProspectArea(area, 'good', $event)" class="stoplight">
            <img src="<%=ar.retPath%>assets/goalstate/green_on.png"  ng-show="area.prospects=='good'"
                 title="Green: Good shape" class="stoplight">
          </span>
        </td>
        <td ng-dblclick="openTaskAreaEditor(area)" title="A written summary of the current status">{{area.status}}</td>
      </tr>
      <tr ng-repeat="rec in findGoalsInArea(area.id)" class="outlined">
        <td  style="width:70px">
        <div style="float:left;margin:3px">
          <div class="dropdown">
            <button class="dropdown-toggle specCaretBtn" type="button"  d="menu" 
                data-toggle="dropdown"> <span class="caret"></span> </button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem"
                  href="task{{rec.id}}.htm">Edit Action Item</a></li>
              <li role="presentation"><a role="menuitem"
                  ng-click="swapItems(rec, -1)">Move Up</a></li>
              <li role="presentation"><a role="menuitem"
                  ng-click="swapItems(rec, 1)">Move Down</a></li>
              <li role="presentation" ng-show="rec.state<2">
                  <a role="menuitem" ng-click="makeState(rec, 2)">
                      <img src="<%=ar.retPath%>assets/goalstate/small2.gif" alt="accepted"  />
                      Start & Offer
                  </a>
              </li>

              <li role="presentation" ng-show="rec.state==2">
                  <a role="menuitem" tabindex="-1" ng-click="makeState(rec, 3)">
                      <img src="<%=ar.retPath%>assets/goalstate/small3.gif" alt="accepted"  />
                      Mark Accepted
                  </a>
              </li>
              <li role="presentation" ng-show="rec.state!=5">
                  <a role="menuitem" tabindex="-1" ng-click="makeState(rec, 5)">
                      <img src="<%=ar.retPath%>assets/goalstate/small5.gif" alt="completed"  />
                      Mark Completed
                  </a>
              </li>
            </ul>
          </div>
        </div>
        <div style="float:left;margin:2px">
          <a href="task{{rec.id}}.htm">
            <img ng-src="<%=ar.retPath%>assets/goalstate/small{{rec.state}}.gif" /></a>
        </div>
        </td>
        <td  style="max-width:300px"  ng-dblclick="openModalActionItem(rec, 'details')"
           title="The synopsis (name) and description of the action item.">
          <div style="cursor: pointer;" ><b>{{rec.synopsis}}</b></span>
          <span ng-repeat="label in getGoalLabels(rec)">
            <button class="labelButton" style="background-color:{{label.color}};" ng-click="toggleLabel(label)">
              {{label.name}}
            </button>
          </span>
          </div>
          <div ng-show="showDescription" ng-bind-html="rec.html"></div>
        </td>
        <td title="People assigned to complete this action item." style="width:70px">
          <div>
            <div ng-repeat="person in rec.assignTo">
              <span class="dropdown">
                <span id="menu1" data-toggle="dropdown">
                <img class="img-circle" src="<%=ar.retPath%>icon/{{imageName(person)}}" 
                     style="width:32px;height:32px" title="{{person.name}} - {{person.uid}}">
                </span>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                      tabindex="-1" ng-click="" style="text-decoration: none;text-align:center">
                      {{person.name}}<br/>{{person.uid}}</a></li>
                  <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                      ng-click="navigateToUser(person)">
                      <span class="fa fa-user"></span> Visit Profile</a></li>
                </ul>
              </span>
            </div>
          </div>
        </td>
        <td style="width:150px"  ng-dblclick="openModalActionItem(rec, 'status')"
            title="Dates the action item was started, due, or completed">
          <div ng-show="rec.startdate>100" >
            start: {{rec.startdate | cdate}}
          </div>
          <div ng-show="rec.duedate>100" >
            due: {{rec.duedate | cdate}}
          </div>
          <div ng-show="rec.enddate>100" >
            end: {{rec.enddate | cdate}}
          </div>
        </td>
        <td style="width:72px;padding:0px;" title="Give a Red-Yellow-Green indication of how it is going"
            ng-dblclick="openModalActionItem(rec, 'status')">
          <span>
            <img src="<%=ar.retPath%>assets/goalstate/red_off.png" ng-hide="rec.prospects=='bad'"
                 title="Red: In trouble" ng-click="setProspects(rec, 'bad', $event)" class="stoplight">
            <img src="<%=ar.retPath%>assets/goalstate/red_on.png"  ng-show="rec.prospects=='bad'"
                 title="Red: In trouble" class="stoplight">
            <img src="<%=ar.retPath%>assets/goalstate/yellow_off.png" ng-hide="rec.prospects=='ok'"
                 title="Yellow: Warning" ng-click="setProspects(rec, 'ok', $event)" class="stoplight">
            <img src="<%=ar.retPath%>assets/goalstate/yellow_on.png"  ng-show="rec.prospects=='ok'"
                 title="Yellow: Warning" class="stoplight">
            <img src="<%=ar.retPath%>assets/goalstate/green_off.png" ng-hide="rec.prospects=='good'"
                 title="Green: Good shape" ng-click="setProspects(rec, 'good', $event)" class="stoplight">
            <img src="<%=ar.retPath%>assets/goalstate/green_on.png"  ng-show="rec.prospects=='good'"
                 title="Green: Good shape" class="stoplight">
          </span>
        </td>
        <td  style="max-width:300px"  ng-dblclick="openModalActionItem(rec, 'status')"
             title="A textual description of the current status of the action item.">
          <div>{{rec.status}} &nbsp;</div>
          <div ng-show="showChecklists" style="cursor:context-menu">
              <div ng-repeat="ci in rec.checkitems" >
                <span ng-click="toggleCheckItem($event,rec,ci.index)" style="cursor:pointer">
                  <span ng-show="ci.checked"><i class="fa  fa-check-square-o"></i></span>
                  <span ng-hide="ci.checked"><i class="fa  fa-square-o"></i></span>
                &nbsp; 
                </span>
                {{ci.name}}
              </div>
          </div>
        </td>
      </tr>
    </tbody>
  </table>
  
  <div class="guideVocal" ng-show="filter"> 
     You are only displaying action items with "<b>{{filter}}</b>" in them.  Some items might be hidden.
  </div>
    
<br/>
<br/>

    <div class="guideVocal" ng-show="allGoals.length==0">
    You have no action items in this workspace yet.
    You can create them using a option from the pull-down in the upper right of this page.
    They can be assigned to people, given due dates, and tracked to completion.
    </div>

</div>



<script src="<%=ar.retPath%>templates/ActionItemCtrl.js"></script>
<script src="<%=ar.retPath%>templates/TaskAreaModal.js"></script>
<script src="<%=ar.baseURL%>jscript/MarkdownToHtml.js"></script>
