<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="java.util.Date"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="java.text.SimpleDateFormat"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%@page import="org.socialbiz.cog.TaskArea"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of a workspace and here it is used to retrieve NGPage.

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
        allGoals.put(gr.getJSON4Goal(ngp));
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

var app = angular.module('myApp', ['ui.bootstrap','ngTagsInput','angularjs-datetime-picker']);
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {
    window.setMainPageTitle("Action Item Status");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.allGoals  = <%allGoals.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    console.log("All labels is: ", $scope.allLabels);
    $scope.stateName = <%stateName.write(out,2,4);%>;
    $scope.taskAreaList = <%taskAreaList.write(out,2,4);%>;
    $scope.filter = "";
    $scope.filterMap = {};
    $scope.showActive = true;
    $scope.showFuture = false;
    $scope.showCompleted = false;
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
            if (areaId!=null && areaId.length>0) {
                if (areaId==item.taskArea) {
                    src.push(item);
                }
            }
            else if (item.taskArea==null || item.taskArea.length==0) {
                src.push(item);
            }
        });
        for (var j=0; j<lcFilterList.length; j++) {
            var lcfilter = lcFilterList[j];
            var res = [];
            src.forEach( function(rec) {
                if (!$scope.showActive && rec.state>=2 && rec.state<=4) {
                    return;
                }
                if (!$scope.showFuture && rec.state==1) {
                    return;
                }
                if (!$scope.showCompleted && rec.state>=5) {
                    return;
                }
                if ($scope.filter.length==0) {
                    res.push(rec);
                    return;
                }
                if (rec.synopsis.toLowerCase().indexOf(lcfilter)>=0) {
                    res.push(rec);
                    return;
                }
                if (rec.description.toLowerCase().indexOf(lcfilter)>=0) {
                    res.push(rec);
                    return;
                }
                for (var i=rec.assignees.length-1; i>=0; i--) {
                    if (rec.assignees[i].toLowerCase().indexOf(lcfilter)>=0) {
                        res.push(rec);
                        return;
                    }
                }
            });
            src = res;
        }
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

    $scope.findGoals = function() {
        var lcFilterList = $scope.filter.toLowerCase().split(" ");
        $scope.allGoals.sort( function(a,b) {
            return a.rank-b.rank;
        });
        var src = $scope.allGoals;
        for (var j=0; j<lcFilterList.length; j++) {
            var lcfilter = lcFilterList[j];
            var res = [];
            src.forEach( function(rec) {
                if (!$scope.showActive && rec.state>=2 && rec.state<=4) {
                    return;
                }
                if (!$scope.showFuture && rec.state==1) {
                    return;
                }
                if (!$scope.showCompleted && rec.state>=5) {
                    return;
                }
                if ($scope.filter.length==0) {
                    res.push(rec);
                    return;
                }
                if (rec.synopsis.toLowerCase().indexOf(lcfilter)>=0) {
                    res.push(rec);
                    return;
                }
                if (rec.description.toLowerCase().indexOf(lcfilter)>=0) {
                    res.push(rec);
                    return;
                }
                for (var i=rec.assignees.length-1; i>=0; i--) {
                    if (rec.assignees[i].toLowerCase().indexOf(lcfilter)>=0) {
                        res.push(rec);
                        return;
                    }
                }
            });
            src = res;
        }
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
        var list = $scope.findGoals();

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
        }
        var otherPos = foundAt + amt;
        if (otherPos<0) {
            alert("can't move up off the beginning of the list");
        }
        if (otherPos>=list.length) {
            alert("can't move down off the end of the list");
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
        return AllPeople.findMatchingPeople(query);
    }

    $scope.createNewGoal = function() {
        var newRec = $scope.newGoal;
        newRec.id = "~new~";
        newRec.universalid = "~new~";
        newRec.assignTo = [];
        newRec.state = 2;
        newRec.assignTo = newRec.assignList;

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
    $scope.loadPersonList = function(query) {
        return AllPeople.findMatchingPeople(query);
    }

    $scope.setProspects = function(goal, newVal) {
        goal.prospects = newVal;
        $scope.saveGoal(goal);
    }
    $scope.setProspectArea = function(area, newVal) {
        area.prospects = newVal;
        $scope.saveArea(area);
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
            }
          }
        });

        modalInstance.result.then(function (modifiedGoal) {
            $scope.allGoals.map( function(item) {
                if (item.id == modifiedGoal.id) {
                    item.duedate = modifiedGoal.duedate;
                    item.status = modifiedGoal.status;
                }
            });
            $scope.saveGoal(modifiedGoal);
        }, function () {
          //cancel action
        });
    };

    $scope.getTaskAreas = function() {
        console.log("getting TaskAreas")
        var getURL = "taskAreas.json";
        $http.get(getURL)
        .success( function(data) {
            console.log("received TaskAreas", data);
            $scope.taskAreaList = data.taskAreas;
            $scope.taskAreaList.push( {name:"Unspecified"} );
            $scope.loaded = true;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    
    $scope.getTaskAreas();
    
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
                }
            }
        });

        modalInstance.result.then(function (modifiedTaskArea) {
            $scope.getTaskAreas();
        }, function () {
            $scope.getTaskAreas();
        });
    };
    
    
});

function addvalue() {
    if(flag==false){
        document.getElementById("projectname").value=projectNameTitle;
    }
}

</script>
<script src="../../../jscript/AllPeople.js"></script>

<div ng-app="myApp" ng-controller="myCtrl">


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

    <div  id="searchresultdiv0">
    <div>
      <table style="width:100%">
        <tr>
           <th></th>
           <th>Synopsis</th>
           <th>Assigned</th>
           <th title="The date the action item is due to be completed">Due Date</th>
           <th title="The date the action item was accepted and started">Started</th>
           <th title="Give a Red-Yellow-Green indication of how it is going"></th>
           <th title="A written summary of the current status">Status</th>
        </tr>
        <tbody ng-repeat="area in taskAreaList">
          <tr class="headerRow">
            <td colspan="2" ng-click="openTaskAreaEditor(area)">{{area.name}}&nbsp;</td>
            <td colspan="3">
                <div ng-repeat="ass in area.assignees">
                  <a href="<%=ar.retPath%>v/FindPerson.htm?uid={{ass.uid}}">{{ass.name}}</a>
                </div>
            </td>
            <td style="width:72px;padding:0px;" title="Give a Red-Yellow-Green indication of how it is going">
              <span>
                <img src="<%=ar.retPath%>assets/goalstate/red_off.png" ng-hide="area.prospects=='bad'"
                     title="Red: In trouble" ng-click="setProspectsArea(area, 'bad')" class="stoplight">
                <img src="<%=ar.retPath%>assets/goalstate/red_on.png"  ng-show="area.prospects=='bad'"
                     title="Red: In trouble" class="stoplight">
                <img src="<%=ar.retPath%>assets/goalstate/yellow_off.png" ng-hide="area.prospects=='ok'"
                     title="Yellow: Warning" ng-click="setProspectsArea(area, 'ok')" class="stoplight">
                <img src="<%=ar.retPath%>assets/goalstate/yellow_on.png"  ng-show="area.prospects=='ok'"
                     title="Yellow: Warning" class="stoplight">
                <img src="<%=ar.retPath%>assets/goalstate/green_off.png" ng-hide="area.prospects=='good'"
                     title="Green: Good shape" ng-click="setProspectsArea(area, 'good')" class="stoplight">
                <img src="<%=ar.retPath%>assets/goalstate/green_on.png"  ng-show="area.prospects=='good'"
                     title="Green: Good shape" class="stoplight">
              </span>
            </td>
            <td ng-click="openTaskAreaEditor(area)" title="A written summary of the current status">{{area.status}}</td>
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
            <td  style="max-width:300px"  ng-click="openModalActionItem(rec, 'details')"
               title="The synopsis (name) and description of the action item.">
              <span style="cursor: pointer;" ng-click="rec.show=!rec.show">{{rec.synopsis}} ~ {{rec.description}}</span>
              <span ng-repeat="label in getGoalLabels(rec)">
                <button class="labelButton" style="background-color:{{label.color}};" ng-click="toggleLabel(label)">
                  {{label.name}}
                </button>
              </span>
            </td>
            <td title="People assigned to complete this action item.">
              <div>
                <div ng-repeat="ass in rec.assignees">
                  <a href="<%=ar.retPath%>v/FindPerson.htm?uid={{ass}}">{{getName(ass)}}</a>
                </div>
              </div>
            </td>
            <td style="width:120px"  ng-click="openModalActionItem(rec, 'status')"
                title="The date the action item is due to be completed">
              <div ng-show="rec.duedate>100" >
                {{rec.duedate | date}}
              </div>
            </td>
            <td style="width:120px" ng-click="openModalActionItem(rec, 'details')"
                title="The date the action item was accepted and started">
              <div ng-show="rec.startdate>100">{{rec.startdate | date}}
              </div>
            </td>
            <td style="width:72px;padding:0px;" title="Give a Red-Yellow-Green indication of how it is going">
              <span>
                <img src="<%=ar.retPath%>assets/goalstate/red_off.png" ng-hide="rec.prospects=='bad'"
                     title="Red: In trouble" ng-click="setProspects(rec, 'bad')" class="stoplight">
                <img src="<%=ar.retPath%>assets/goalstate/red_on.png"  ng-show="rec.prospects=='bad'"
                     title="Red: In trouble" class="stoplight">
                <img src="<%=ar.retPath%>assets/goalstate/yellow_off.png" ng-hide="rec.prospects=='ok'"
                     title="Yellow: Warning" ng-click="setProspects(rec, 'ok')" class="stoplight">
                <img src="<%=ar.retPath%>assets/goalstate/yellow_on.png"  ng-show="rec.prospects=='ok'"
                     title="Yellow: Warning" class="stoplight">
                <img src="<%=ar.retPath%>assets/goalstate/green_off.png" ng-hide="rec.prospects=='good'"
                     title="Green: Good shape" ng-click="setProspects(rec, 'good')" class="stoplight">
                <img src="<%=ar.retPath%>assets/goalstate/green_on.png"  ng-show="rec.prospects=='good'"
                     title="Green: Good shape" class="stoplight">
              </span>
            </td>
            <td  style="max-width:300px"  ng-click="openModalActionItem(rec, 'status')"
                 title="A textual description of the current status of the action item.">
              <div>{{rec.status}} &nbsp;</div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
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

