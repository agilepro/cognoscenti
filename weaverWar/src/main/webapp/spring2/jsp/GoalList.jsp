<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="java.util.Date"
%><%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@page import="java.text.SimpleDateFormat"
%><%@page import="com.purplehillsbooks.weaver.MicroProfileMgr"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of a workspace and here it is used to retrieve NGWorkspace.

*/
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    ar.assertAccessWorkspace("Must be a member to see meetings");

    NGBook site = ngp.getSite();
    List<GoalRecord> allGoalsRaw = ngp.getAllGoals();
    JSONArray allGoals = new JSONArray();
    for (GoalRecord gr : allGoalsRaw) {
        if (!gr.isPassive()) {
            allGoals.put(gr.getJSON4Goal(ngp));
        }
    }

    UserProfile uProf = ar.getUserProfile();

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
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Action Items");
    $scope.allGoals  = <%allGoals.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.stateName = <%stateName.write(out,2,4);%>;
    $scope.siteId = "<%ar.writeJS(siteId);%>";
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.taskAreaList = <%taskAreaList.write(out,2,4);%>;
    $scope.filter = "";
    $scope.filterMap = {};
    $scope.showActive = true;
    $scope.showFuture = false;
    $scope.showCompleted = false;
    $scope.isCreating = false;
    $scope.newGoal = {assignList:[]};

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

    $scope.findGoals = function() {
        var lcFilterList = parseLCList($scope.filter);
        $scope.allGoals.sort( function(a,b) {
            return a.rank-b.rank;
        });
        var res = [];
        $scope.allGoals.map( function(rec) {
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
            if (containsOne(rec.synopsis, lcFilterList)) {
                res.push(rec);
                return;
            }
            if (containsOne(rec.description, lcFilterList)) {
                res.push(rec);
                return;
            }
            for (var i=rec.assignees.length-1; i>=0; i--) {
                if (containsOne(rec.assignees[i], lcFilterList)) {
                    res.push(rec);
                    return;
                }
            }
        });
        var src = res;
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
        objForUpdate.rank = goal.rank;  //only thing that could have been changed
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
        return AllPeople.findMatchingPeople(query, $scope.siteId);
    }

    $scope.updatePlayers = function() {
        $scope.newGoal.assignList = cleanUserList($scope.newGoal.assignList);
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
        return "<%=ar.retPath%>v/FindPerson.htm?key="+encodeURIComponent(uid);
    }
    $scope.showUser = function(tag) {
        //alert("gotcha:" + tag.name);
    }
    
    
    $scope.openModalActionItem = function (goal, startMode) {

        var modalInstance = $modal.open({
          animation: true,
          templateUrl: '<%=ar.retPath%>new_assets/templates/ActionItem.html<%=templateCacheDefeater%>',
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
            siteInfo: function () {
              return $scope.siteInfo;
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


});

function addvalue() {
    if(flag==false){
        document.getElementById("projectname").value=projectNameTitle;
    }
}

</script>
<script src="../../../jscript/AllPeople.js"></script>

<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

    <div class="container-fluid">
      <div class="row">
        <div class="col-md-auto fixed-width border-end border-1 border-secondary">
            <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" 
              ng-click="isCreating=true">Create New Action Item</a>
            </span>
          <hr/>
          <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" href="GoalList.htm">Action Items View</a></span>
          <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" 
              href="GoalStatus.htm">Status List View</a></span>
              <span class="btn btn-secondary btn-comment btn-raised m-3 pb-2 pt-0" type="button"><a class="nav-link" href="TaskAreas.htm">Manage Task Areas</a></span>
        </div>
<div class="d-flex col-9"><div class="contentColumn">
    <div class="well" ng-show="!isCreating">
        Filter <input ng-model="filter"> &nbsp;
        <span style="vertical-align:middle;" ><input type="checkbox" ng-model="showActive">
            Active</span> &nbsp;
        <span style="vertical-align:middle;" ><input type="checkbox" ng-model="showFuture">
            Future</span> &nbsp;
        <span style="vertical-align:middle;" ><input type="checkbox" ng-model="showCompleted">
            Completed</span>
        <span class="dropdown" ng-repeat="role in allLabelFilters()">
            <button class="labelButton" ng-click="toggleLabel(role)"
               style="background-color:{{role.color}};"
               ng-show="hasLabel(role.name)">{{role.name}} <i class="fa fa-close"></i></button>
        </span>
        <span>
             <span class="dropdown">
               <button class="btn btn-sm btn-primary btn-raised dropdown-toggle" type="button" 
                       id="menu2" data-toggle="dropdown"
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


    <div class="well generalSettings" ng-show="isCreating">
        <table>
           <tr>
                <td class="gridTableColummHeader">New Synopsis:</td>
                <td style="width:20px;"></td>
                <td colspan="2">
                    <input type="text" ng-model="newGoal.synopsis" class="form-control" placeholder="What should be done">
                </td>
           </tr>
           <tr><td style="height:10px"></td></tr>
           <tr>
                <td class="gridTableColummHeader">Assignee:</td>
                <td style="width:20px;"></td>
                <td colspan="2">
                  <tags-input ng-model="newGoal.assignList" placeholder="Enter user name or id"
                              display-property="name" key-property="uid" on-tag-clicked="showUser($tag)"
                      replace-spaces-with-dashes="false" add-on-space="true" add-on-comma="true"
                      on-tag-added="updatePlayers()" 
                      on-tag-removed="updatePlayers()">
                      <auto-complete source="getPeople($query)" min-length="1"></auto-complete>
                  </tags-input>
                </td>
            </tr>
            <tr><td style="height:10px"></td></tr>
            <tr>
                <td class="gridTableColummHeader">Description:</td>
                <td style="width:20px;"></td>
                <td colspan="2">
                    <textarea type="text" ng-model="newGoal.description" class="form-control"
                        style="width:450px;height:100px" placeholder="Details"></textarea>
                </td>
            </tr>
            <tr><td style="height:10px"></td></tr>
            <tr>
                <td class="gridTableColummHeader">Due Date:</td>
                <td style="width:20px;"></td>
                <td colspan="2">
                    <span datetime-picker ng-model="newRec.duedate"  
                        class="form-control" style="max-width:300px; min-height: 25px;">
                        {{newRec.duedate|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm  '&nbsp;  GMT'Z"}}
                    </span> 
                </td>
            </tr>
            <tr><td style="height:10px"></td></tr>
            <tr>
                <td class="gridTableColummHeader"></td>
                <td style="width:20px;"></td>
                <td colspan="3">
                    <button class="btn btn-danger btn-default" ng-click="isCreating=false">Cancel</button>
                    <button class="btn btn-primary btn-wide ms-5" ng-click="createNewGoal()">Create New Action Item</button>
                    
                </td>
            </tr>
        </table>
    </div>

    <div style="height:20px;"></div>



    <div  id="searchresultdiv0">
    <div class="taskListArea">
        <div class="row">
            <div id="ActiveTask">
                <div ng-repeat="rec in findGoals()" id="node1503" class="ui-state-default" style="background-color: #F8F8F8; margin-bottom: 5px;">
                    <span>
                <ul type="button" class="btn-tiny btn btn-outline-secondary m-2"  >
                    <li class="nav-item dropdown"> <a class=" dropdown-toggle" id="GoalList" role="button" data-bs-toggle="dropdown" aria-expanded="false"><span class="caret"></span> </a>
                        <ul class="dropdown-menu" role="menu" aria-labelledby="Actionlist">
                    <li><a class="dropdown-item" role="menuitem"
                      ng-click="openModalActionItem(rec, 'details')">Edit Action Item</a></li>
                      <li><a class="dropdown-item" role="menuitem" tabindex="-1"
                      ng-click="swapItems(rec, -1)">Move Up</a></li>
                      <li><a class="dropdown-item" role="menuitem" tabindex="-1"
                      ng-click="swapItems(rec, 1)">Move Down</a></li>
                      <li ng-show="rec.state<2">
                      <li class="dropdown-item" role="menuitem" tabindex="-1"  ng-click="makeState(rec, 2)">
                          <img src="<%=ar.retPath%>assets/goalstate/small2.gif" alt="accepted"  />
                          Start & Offer
                      </li>
                  </li>

                  <li ng-show="rec.state==2">
                      <a class="dropdown-item" role="menuitem" tabindex="-1" ng-click="makeState(rec, 3)">
                          <img src="<%=ar.retPath%>assets/goalstate/small3.gif" alt="accepted"  />
                          Mark Accepted
                      </a>
                  </li>
                  <li ng-show="rec.state!=5">
                      <a class="dropdown-item" role="menuitem" tabindex="-1" ng-click="makeState(rec, 5)">
                          <img src="<%=ar.retPath%>assets/goalstate/small5.gif" alt="completed"  />
                          Mark Completed
                      </a>
                  </li>
                        </ul>
                    </li>
                </ul>   
            </span>
            
                <span class="col-1 ms-3 fw-bold" style="cursor: pointer;"> 
                    <a href="task{{rec.id}}.htm"><img ng-src="<%=ar.retPath%>assets/goalstate/small{{rec.state}}.gif" /></a>
                </span>
                <span class="col-4 ms-3 fw-bold" style="cursor: pointer;" ng-click="rec.show=!rec.show">{{rec.synopsis}}                    
                </span>

                <span ng-repeat="label in getGoalLabels(rec)">
                  <button class="labelButton" style="background-color:{{label.color}};" ng-click="toggleLabel(label)">
                  {{label.name}}
                  </button>
                </span>

                <span class="col-5 taskOverview mx-2 fw-bold">Assigned to:
                   <span class="red" ng-repeat="ass in rec.assignees"><a href="<%=ar.retPath%>v/FindPerson.htm?key={{ass}}">{{getName(ass)}}</a>, </span>

                </span>
                <div ng-show="rec.show" id="{{rec.id}}_1" style="max-width:800px;">
                    <div class="taskOverview" ng-dblclick="openModalActionItem(rec, 'details')">
                        Requested by:
                         <span class="red" ng-repeat="ass in rec.requesters"><a href="{{getLink(ass)}}">{{getName(ass)}}</a>, </span>
                    </div>
                    <div class="taskStatus">Description: {{rec.description}}</div>
                    <div class="taskStatus">Priority:  <span style="color:red">{{rec.priority}}</span>
                        <span ng-show="rec.needEmail"> - email scheduled - </span>
                    </div>
                    <div class="taskStatus">Status: {{rec.status}}  - (rank {{rec.rank}})</div>
                    <div class="taskToolBar">
                        Action:
                        &nbsp;&nbsp;&nbsp;&nbsp;
                        <span ng-show="rec.state<2">
                            <a title="Start & Offer the Activity" ng-click="makeState(rec, 2)">
                                <img src="<%=ar.retPath%>assets/goalstate/small2.gif" alt="accepted"  />
                                <b>Start/Offer</b></a>
                            </span>
                        &nbsp;&nbsp;&nbsp;&nbsp;
                        <span ng-show="rec.state==2">
                            <a title="Accept the activity" ng-click="makeState(rec, 3)">
                                <img src="<%=ar.retPath%>assets/goalstate/small3.gif" alt="accepted"  />
                                <b>Mark Accepted</b></a>
                            </span>
                        &nbsp;&nbsp;&nbsp;&nbsp;
                        <span ng-show="rec.state!=5">
                            <a title="Complete this activity" ng-click="makeState(rec, 5)">
                                <img src="<%=ar.retPath%>assets/goalstate/small5.gif" alt="completed"  />
                                <b>Mark Completed</b></a>
                            </span>
                    </div>
                </div>
                </div>
              </div>
              <br style="clear: left;" />
            </div>
        </div>
      </ul>
    </div>
    </div>

    <div class="guideVocal" ng-show="allGoals.length==0">
    You have no action items in this workspace yet.
    You can create them using a option from the pull-down in the upper right of this page.
    They can be assigned to people, given due dates, and tracked to completion.
    </div>

    
</div>

<script src="<%=ar.retPath%>templates/ActionItemCtrl.js"></script>


