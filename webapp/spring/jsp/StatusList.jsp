<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="java.util.Date"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="java.text.SimpleDateFormat"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of a workspace and here it is used to retrieve NGPage.

*/

    //String templateCacheDefeater = "";
    String templateCacheDefeater = "?t="+System.currentTimeMillis();

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Must be a member to see meetings");

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

var app = angular.module('myApp', ['ui.bootstrap','ngTagsInput']);
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {
    window.setMainPageTitle("Action Item Status");
    $scope.allGoals  = <%allGoals.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.stateName = <%stateName.write(out,2,4);%>;
    $scope.filter = "";
    $scope.filterMap = {};
    $scope.showActive = true;
    $scope.showFuture = false;
    $scope.showCompleted = false;
    $scope.isCreating = false;
    $scope.newGoal = {assignList:[]};
    $scope.dummyDate1 = new Date();

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
        var lcFilterList = $scope.filter.toLowerCase().split(" ");
        $scope.allGoals.sort( function(a,b) {
            return a.rank-b.rank;
        });
        var src = $scope.allGoals;
        for (var j=0; j<lcFilterList.length; j++) {
            var lcfilter = lcFilterList[j];
            var res = [];
            src.map( function(rec) {
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
        newRec.duedate = $scope.dummyDate1.getTime();

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
        console.log("CALL to setProspects");
        goal.prospects = newVal;
        $scope.saveGoal(goal);
    }

    $scope.openModalActionItem = function (item, goal) {

        var modalInstance = $modal.open({
          animation: false,
          templateUrl: '<%=ar.retPath%>templates/ModalActionItem.html<%=templateCacheDefeater%>',
          controller: 'ModalActionItemCtrl',
          size: 'lg',
          backdrop: "static",
          resolve: {
            item: function () {
              return item;
            },
            goal: function () {
              return goal;
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
              ng-click="isCreating=true">Create New Action Item</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="goalList.htm">Action Items View</a></li>
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
               <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
                 <li role="presentation" ng-repeat="rolex in allLabels">
                     <button role="menuitem" tabindex="-1" href="#"  ng-click="toggleLabel(rolex)" class="labelButton"
                     ng-hide="hasLabel(rolex.name)" style="background-color:{{rolex.color}};">
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
                              display-property="name" key-property="uid" on-tag-clicked="showUser($tag)">
                      <auto-complete source="loadPersonList($query)"></auto-complete>
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
            <tr><td style="height:10px"></td></tr>
            <tr>
                <td class="gridTableColummHeader"></td>
                <td style="width:20px;"></td>
                <td colspan="2">
                    <button class="btn btn-primary btn-raised" ng-click="createNewGoal()">Create New Action Item</button>
                    <button class="btn btn-primary btn-raised" ng-click="isCreating=false">Cancel</button>
                </td>
            </tr>
        </table>
    </div>

    <div style="height:20px;"></div>

<style>
.statusTable {
    width:100%;
}
.statusTable tr td{
    padding:3px;
    border-width:1px;
    border-style:solid;
    border-color:grey;
}
.statusTable tr th{
    padding:3px;
}
.taskStatus {
    white-space: nowrap;
    overflow: hidden;
    text-overflow:clip;
    max-width:100px;
}
.stoplight {
    height: 20px;
    width: 20px; 
    margin:0px;    
}
</style>

    <div  id="searchresultdiv0">
    <div class="taskListArea">
      <table class="statusTable">
         <tr>
           <th></th>
           <th>Synopsis</th>
           <th>Assigned</th>
           <th>Due Date</th>
           <th>Started</th>
           <th></th>
           <th>Status</th>
         </tr>
         <tr ng-repeat="rec in findGoals()">
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
              <a href="task{{rec.id}}.htm"><img src="<%=ar.retPath%>assets/goalstate/small{{rec.state}}.gif" /></a>
            </div>
          </td>
          <td  style="max-width:300px">
            <span style="cursor: pointer;" ng-click="rec.show=!rec.show">{{rec.synopsis}} ~ {{rec.description}}</span>
            <span ng-repeat="label in getGoalLabels(rec)">
              <button class="labelButton" style="background-color:{{label.color}};" ng-click="toggleLabel(label)">
              {{label.name}}
              </button>
            </span>
          </td>
          <td  class="taskStatus" >
            <div class="taskOverview">
              <div ng-repeat="ass in rec.assignees">
                  <a href="<%=ar.retPath%>v/FindPerson.htm?uid={{ass}}">{{getName(ass)}}</a></div>

            </div>
          </td>
          <td class="taskStatus" style="width:120px">
            <div class="taskStatus" ng-show="rec.duedate>100"  ng-click="openModalActionItem(null, rec)" >{{rec.duedate | date}}
            </div>
          </td>
          <td class="taskStatus" style="width:120px">
            <div class="taskStatus" ng-show="rec.startdate>100">{{rec.startdate | date}}
            </div>
          </td>
          <td style="width:72px;padding:0px;">
            <span>
                <img src="<%=ar.retPath%>assets/goalstate/green_off.png" ng-hide="rec.prospects=='good'"
                     title="Good shape" ng-click="setProspects(rec, 'good')" class="stoplight">
                <img src="<%=ar.retPath%>assets/goalstate/green_on.png"  ng-show="rec.prospects=='good'"
                     title="Good shape" class="stoplight">
                <img src="<%=ar.retPath%>assets/goalstate/yellow_off.png" ng-hide="rec.prospects=='ok'"
                     title="Warning" ng-click="setProspects(rec, 'ok')" class="stoplight">
                <img src="<%=ar.retPath%>assets/goalstate/yellow_on.png"  ng-show="rec.prospects=='ok'"
                     title="Warning" class="stoplight">
                <img src="<%=ar.retPath%>assets/goalstate/red_off.png" ng-hide="rec.prospects=='bad'"
                     title="In trouble" ng-click="setProspects(rec, 'bad')" class="stoplight">
                <img src="<%=ar.retPath%>assets/goalstate/red_on.png"  ng-show="rec.prospects=='bad'"
                     title="In trouble" class="stoplight">
            </span>
          </td>
          <td  style="max-width:300px">
            <div ng-click="openModalActionItem(null, rec)">{{rec.status}} &nbsp;</div>
          </td>
        </tr>
      </table>
    </div>
    </div>

</div>

<br/>
<br/>

<script src="<%=ar.retPath%>templates/ModalActionItemCtrl.js"></script>

