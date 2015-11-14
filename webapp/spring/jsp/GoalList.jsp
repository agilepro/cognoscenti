<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="java.util.Date"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="java.text.SimpleDateFormat"
%><%@page import="org.socialbiz.cog.TemplateRecord"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of a workspace and here it is used to retrieve NGPage.
    2. book     : This request attribute provide the key of account which is used to select account from the
                  list of all sites by-default when the page is rendered.

*/

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Must be a member to see meetings");

    List<GoalRecord> allGoalsRaw = ngp.getAllGoals();
    JSONArray allGoals = new JSONArray();
    for (GoalRecord gr : allGoalsRaw) {
        allGoals.put(gr.getJSON4Goal(ngp));
    }

    UserProfile uProf = ar.getUserProfile();


    Vector<NGPageIndex> templates = new Vector<NGPageIndex>();
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

    JSONArray allPeople = UserManager.getUniqueUsersJSON();


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

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.allGoals  = <%allGoals.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.stateName = <%stateName.write(out,2,4);%>;
    $scope.allPeople = <%allPeople.write(out,2,4);%>;
    $scope.filter = "";
    $scope.filterMap = {};
    $scope.showActive = true;
    $scope.showFuture = false;
    $scope.showCompleted = false;
    $scope.isCreating = false;
    $scope.newGoal = {assignOne:{name:""}};
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
        for (var j=0; j<allReqLabels.length; j++) {
            var requiredLabel = allReqLabels[j].name;
            var res = [];
            src.map( function(rec) {
                if (rec.labelMap[requiredLabel]) {
                    res.push(rec);
                }
            });
            src = res;
        }
        return src;
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

    $scope.getPeople = function(viewValue) {
        var newVal = [];
        for( var i=0; i<$scope.allPeople.length; i++) {
            var onePeople = $scope.allPeople[i];
            if (onePeople.uid.indexOf(viewValue)>=0) {
                newVal.push(onePeople);
            }
            else if (onePeople.name.indexOf(viewValue)>=0) {
                newVal.push(onePeople);
            }
        }
        return newVal;
    }

    $scope.createNewGoal = function() {
        var newRec = $scope.newGoal;
        newRec.id = "~new~";
        newRec.universalid = "~new~";
        newRec.assignTo = [];
        newRec.state = 2;
        newRec.assignTo.push(newRec.assignOne);
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
        console.log("PERSON: "+JSON.stringify(person[0]));
        if (person[0].name) {
            return person[0].name;
        }
        return "Unknown "+uid;
    }
    $scope.getLink = function(uid) {
        var person = $scope.getPeople(uid);
        if (person.length==0) {
            return uid;
        }
        return "<%=ar.retPath%>v/"+person[0].key+"/userSettings.htm";
    }

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
            Action Items
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  ng-click="isCreating=true">Create New Action Item</a></li>
            </ul>
          </span>

        </div>
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
            <button class="btn btn-sm dropdown-toggle labelButton" type="button" id="menu2"
               data-toggle="dropdown" style="background-color:{{role.color}};"
               ng-show="hasLabel(role.name)">{{role.name}} <i class="fa fa-close"></i></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
               <li role="presentation"><a role="menuitem" title="{{add}}"
                  ng-click="toggleLabel(role)">Remove Filter:<br/>{{role.name}}</a></li>
            </ul>
        </span>
        <span>
             <span class="dropdown">
               <button class="btn btn-sm btn-primary dropdown-toggle" type="button" id="menu2" data-toggle="dropdown"
                       title="Add Filter by Label"><i class="fa fa-filter"></i></button>
               <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
                 <li role="presentation" ng-repeat="rolex in allLabels">
                     <button role="menuitem" tabindex="-1" href="#"  ng-click="toggleLabel(rolex)" class="btn btn-sm labelButton"
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
                    <input type="text" ng-model="newGoal.assignOne" class="form-control" placeholder="Who should do it"
                       typeahead="person as person.name for person in getPeople($viewValue) | limitTo:12">
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
                    <button class="btn btn-primary" ng-click="createNewGoal()">Create New Action Item</button>
                    <button class="btn btn-primary" ng-click="isCreating=false">Cancel</button>
                </td>
            </tr>
        </table>
    </div>

    <div style="height:20px;"></div>



    <div  id="searchresultdiv0">
    <div class="taskListArea">
      <ul id="ActiveTask">
         <div ng-repeat="rec in findGoals()" id="node1503" class="ui-state-default" style="background-color: #F8F8F8; margin-bottom: 5px;">
            <div>
            <div style="float: left;margin:7px">
              <div class="dropdown">
                <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                <span class="caret"></span></button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li role="presentation"><a role="menuitem" tabindex="-1"
                      href="task{{rec.id}}.htm">Edit Action Item</a></li>
                  <li role="presentation" ng-show="rec.state<2">
                      <a role="menuitem" tabindex="-1" ng-click="makeState(rec, 2)">
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
            <div style="float: left;margin:7px">
              <a href="task{{rec.id}}.htm"><img src="<%=ar.retPath%>assets/goalstate/small{{rec.state}}.gif" /></a>
            </div>
            <div style="float: left;margin:3px;">
              <div>
                <span style="font-size: 17px;cursor: pointer;" ng-click="rec.show=!rec.show">{{rec.synopsis}}</span>
                <span ng-repeat="label in getGoalLabels(rec)">
                  <button class="btn btn-sm labelButton" style="background-color:{{label.color}};" ng-click="toggleLabel(label)">
                  {{label.name}}
                  </button>
                </span>

                <div class="taskOverview">Assigned to:
                   <span class="red" ng-repeat="ass in rec.assignees"><a href="{{getLink(ass)}}">{{getName(ass)}}</a>, </span>

                </div>
                <div ng-show="rec.show" id="{{rec.id}}_1" style="max-width:800px;">
                    <div class="taskOverview">Requested by:
                         <span class="red" ng-repeat="ass in rec.requesters"><a href="{{getLink(ass)}}">{{getName(ass)}}</a>, </span>
                    </div>
                    <div class="taskStatus">Description: {{rec.description}}</div>
                    <div class="taskStatus">Priority:  <span style="color:red">{{rec.priority}}</span></div>
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

</div>



