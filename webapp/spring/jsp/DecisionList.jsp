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

    JSONArray allDecisions = new JSONArray();
    for (DecisionRecord dr : ngp.getDecisions()) {
        allDecisions.put(dr.getJSON4Decision(ngp, ar));
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

    $scope.allDecisions = [
      {
        "html": "<p>\nThis is what we decided ...<\/p>\n",
        "labelMap": {},
        "num": 1,
        "timestamp": 0,
        "universalid": "JSELCWFYG@emmanueldemo@DEC0"
      },
      ....
   ]


*/

%>

<link href="<%=ar.retPath%>jscript/textAngular.css" rel="stylesheet" />
<script src="<%=ar.retPath%>jscript/textAngular-rangy.min.js"></script>
<script src="<%=ar.retPath%>jscript/textAngular-sanitize.min.js"></script>
<script src="<%=ar.retPath%>jscript/textAngular.min.js"></script>



<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap', 'textAngular']);
app.controller('myCtrl', function($scope, $http, $modal) {
    $scope.allDecisions = <%allDecisions.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.stateName = <%stateName.write(out,2,4);%>;
    $scope.allPeople = <%allPeople.write(out,2,4);%>;
    $scope.filter = "";
    $scope.filterMap = {};
    $scope.newDecision = {num:"~new~",universalid:"~new~"};
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

    $scope.findDecisions = function() {
        var filterlist = $scope.filter.split(" ");
        var src = $scope.allDecisions;
        $scope.allLabelFilters().map( function(label) {
            var res = [];
            src.map( function(item) {
                if (item.labelMap[label.name]) {
                    res.push(item);
                }
            });
            src = res;
        });
        for (var j=0; j<filterlist.length; j++) {
            var lcfilter = filterlist[j].toLowerCase();
            var res = [];
            src.map( function(item) {
                if (item.html.toLowerCase().indexOf(lcfilter) >=0) {
                    res.push(item);
                }
            });
            src = res;
        }
        src.sort(function(a, b){return b.num-a.num});
        return src;
    };

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
    $scope.startCreating = function() {
        $scope.newDecision = {num:"~new~",universalid:"~new~",labelMap:{}};
        $scope.openDecisionEditor($scope.newDecision);
    }
    $scope.startEditing = function(rec) {
        $scope.newDecision = rec;
    }

    $scope.saveDecision = function(newRec) {

        var postURL = "updateDecision.json?did="+newRec.num;
        var postData = angular.toJson(newRec);
        $http.post(postURL, postData)
        .success( function(data) {
            var newList = [];
            $scope.allDecisions.map( function(item) {
                if (item.num != data.num) {
                    newList.push(item);
                }
            });
            newList.push(data);
            $scope.allDecisions = newList;
            $scope.newDecision = {num:"~new~",universalid:"~new~"};
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
    $scope.getDecisionLabels = function(decision) {
        var res = [];
        $scope.allLabels.map( function(val) {
            if (decision.labelMap[val.name]) {
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
    $scope.getGoalLabels = function(rec) {
        var res = [];
        $scope.allLabels.map( function(val) {
            if (rec.labelMap[val.name]) {
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
        return "Unknown "+uid;
    }
    $scope.getLink = function(uid) {
        var person = $scope.getPeople(uid);
        if (person.length==0) {
            return uid;
        }
        return "<%=ar.retPath%>v/"+person[0].key+"/userSettings.htm";
    }


    $scope.openDecisionEditor = function (decision) {

        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/DecisionModal.html',
            controller: 'ModalInstanceCtrl',
            size: 'lg',
            resolve: {
                decision: function () {
                    return JSON.parse(JSON.stringify(decision));
                },
                allLabels: function() {
                    return $scope.allLabels;
                }
            }
        });

        modalInstance.result.then(function (modifiedDecision) {
            $scope.saveDecision(modifiedDecision);
        }, function () {
            //cancel action - nothing really to do
        });
    };
});


</script>
<script src="<%=ar.retPath%>templates/DecisionModal.js"></script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Decisions
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  ng-click="startCreating()">Create New Decision</a></li>
            </ul>
          </span>

        </div>
    </div>


    <div class="well">
        Filter <input ng-model="filter"> &nbsp;
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


  <div  id="searchresultdiv0">
    <div class="taskListArea">
      <table id="ActiveTask" style="min-width:800px">
         <tr ng-repeat="rec in findDecisions()" id="node1503" class="ui-state-default"
             style="background: linear-gradient(#EEE, white); margin: 5px;border-style:solid;border-color:#FFF;border-width:12px">
                <td style="padding:3px;vertical-align:top;margin:5px;">
                  <div class="dropdown" style="padding:4px">
                    <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                    <span class="caret"></span></button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation"><a role="menuitem" tabindex="-1"
                          ng-click="openDecisionEditor(rec)">Edit Decision</a></li>
                    </ul>
                  </div>
                </td>
                <td style="padding:3px;vertical-align:top;;margin:5px;" id="DEC{{rec.num}}">
                  <a href="decisionList.htm#DEC{{rec.num}}"><span style="font-size:200%;">{{rec.num}}</span></a>
                </td>
                <td style="padding:3px;vertical-align:top;;margin:5px;">
                  <div class="leafContent" style="padding:0px">
                    <div id="{{rec.id}}_1" style="max-width:800px;width:100%;color:#88F;margin:2px;vertical-align:bottom;">
                        <div class="taskOverview">
                            <i>{{rec.timestamp|date}}</i>
                            <span ng-repeat="label in getGoalLabels(rec)">
                              <button class="btn btn-sm labelButton" style="background-color:{{label.color}};" ng-click="toggleLabel(label)">
                                  {{label.name}}
                              </button>
                            </span>
                        </div>
                    </div>
                    <div ng-click="rec.show=!rec.show" >
                        <div ng-bind-html="rec.html" style="max-width:800px;"></div>
                    </div>
                    <div ng-show="rec.sourceType==4">
                        See source <a href="<%=ar.retPath%>{{rec.sourceUrl}}">proposal</a>
                    </div>
                  </div>
                </td>

        </tr>
      </table>
    </div>
  </div>



</div>



