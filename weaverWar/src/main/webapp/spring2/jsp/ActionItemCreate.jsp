<%@page errorPage="/spring2/jsp/error.jsp"
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
        window.setMainPageTitle("Create Action Item");
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
              size: 'xl',
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
 
  
<% if (userReadOnly) { %>

<div class="guideVocal" style="margin-top:80px">
    <p>You are not allowed to create an action item in this workspace, because
    you are an observer.  You can access documents, but you can 
    not add them or update them.</p>
    
    <p>If you wish to add or update action items, speak to the administrator about this 
    workspace / site and have your membership level changed to an
    active user.</p>
</div>

<% } else if (ngw.isFrozen()) { %>

<div class="guideVocal" style="margin-top:80px">
    <p>You are not able to create an action item in this workspace, because
    it is frozen.  Frozen workspaces can not be modified: nothing can be added
    or removed, including action items.</p>
    
    <p>If you wish to add or update action items, the workspace must be set into the 
    active (unfrozen) state in the workspace admin page.</p>
</div>

<% } else { %>

<div class="container-fluid col-md-10 ms-4">
    <div class="row shadow-lg p-3">
        <form class="horizontal-form">
            <fieldset>
            <!-- Form Control NAME Begin -->
                <div class="form-group d-flex my-3">
                    <label class="h6 col-1 control-label" title="Enter what needs to be done.">Goal of the Action Item</label>
                    <div class="col-md-10">
                        <input type="text" class="form-control" ng-model="newGoal.synopsis" title="What needs to be done?"/>
                    </div>
                </div>

            <!-- Form Control DATE Begin -->
            <div class="form-group d-flex my-3">
                <label class="col-1 h6 control-label" title="Date and time for the beginning of the meeting in YOUR time zone">
                    Date &amp; Time
                </label>
                <div class="col-md-10" title="Date and time for the beginning of the meeting in YOUR time zone">
                    <span datetime-picker ng-model="meeting.startTime" 
                        class="form-control" style="width:180px">{{meeting.startTime|sdate:"DD-MMM-YYYY &nbsp; HH:mm"}}
                    </span> 
                    <span style="padding:10px">{{browserZone}}</span>
                    <button ng-click="meeting.startTime=0" class="btn btn-default btn-raised">Clear</button>
                </div>
                
            </div>
            <!-- Form Control DESCRIPTION Begin -->
                <div class="form-group d-flex my-3">
                    <label class="col-1 h6 control-label">
                        Description
                    </label>
                    <div class="col-md-10">
                        <textarea ui-tinymce="tinymceOptions" ng-model="meeting.descriptionHtml" class="leafContent form-control" style="min-height:200px;"></textarea>
                    </div>
                </div>
            </fieldset>
          <div ng-show="meeting.agenda.length>0">
              <!-- Table MEETING AGENDA ITEMS Begin -->
              <div class="container-fluid col-11 ms-5">
                <div class="h4 my-4">Agenda Items</div>
                <div class="form-group ms-5">
              
                  <div class="row d-flex my-4 border-1 border-bottom py-2">
                      <span class="col-1 h6" title="Check this to include a copy of this agenda item in the new meeting">Clone</span>
                      <span class=" col-2 h6">Agenda Item</span>
                      <span class="col-5 h6">Description</span>
                      <span class="col-2 h6" title="Expected duration of the agenda item in minutes">Duration</span>
                  </div>
                  <div class="row d-flex my-4 border-1 border-bottom py-2" ng-repeat="rec in sortItems()">
                      <span class="col-1 actions">
                        <div class="checkbox">
                          <label title="Check this to include a copy of this agenda item in the new meeting">
                            <input type="checkbox" ng-model="rec.selected"><span class="checkbox-material"></span>
                          </label>
                        </div>
                      </span>
                      <span class="col-2"><b>{{rec.subject}}
                              <span ng-show="rec.topics.length()>0">(Linked Topic)</span>
                          </b>
                          </span>
                      <span class="col-5" style="line-height: 1.3;"><div ng-bind-html="trimDesc(rec)|wiki"></div></span>
                      <span class="col-2" title="Expected duration of the agenda item in minutes">
                          <input class="form-control" style="width:80px" ng-model="rec.duration"></span>
                      </div>
              </div>
          </div>
        </div>
          <!-- Form Control BUTTONS Begin -->

        </form>
                  <div class="mx-5 row col-10">
                    <span class="col-md-2 me-auto">
            <button class="btn btn-danger btn-raised " type="button"  onclick="history.back();">Cancel</button></span>
            <span class="col-md-2 ms-auto "><button class="btn btn-primary btn-raised ms-start" type="submit" ng-click="createMeeting()"><%=pageTitle%></button></span>

          </div>
      </div>
    </div>
  </div>
  
<% } %> 
  
</div>

<script src="<%=ar.retPath%>jscript/HtmlToMarkdown.js"></script>
<script src="<%=ar.retPath%>jscript/HtmlParser.js"></script>
<script src="<%=ar.baseURL%>jscript/TextMerger.js"></script>