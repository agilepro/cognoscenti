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

    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    String startMode = ar.defParam("start", "nothing");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKey(siteId,pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    ar.assertAccessWorkspace("Must be a member to see decisions");
    NGBook site = ngp.getSite();

    JSONArray allDecisions = new JSONArray();
    for (DecisionRecord dr : ngp.getDecisions()) {
        allDecisions.put(dr.getJSON4Decision(ngp, ar));
        out.write("\n<!-- "+dr.getAttributeLong("reviewDate")+" -->\n");
    }

    UserProfile uProf = ar.getUserProfile();

    JSONArray allLabels = ngp.getJSONLabels();
    boolean isFrozen = ngp.isFrozen();
    boolean canUpdate = ar.canUpdateWorkspace();


/*** PROTOTYPE

    $scope.allDecisions = [
      {
        "decision": "This is what we decided ...",    //markdown
        "labelMap": {},
        "num": 1,
        "timestamp": 0,
        "universalid": "JSELCWFYG@emmanueldemo@DEC0"
      },
      ....
   ]


*/

%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Decision List");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.allDecisions = <%allDecisions.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.isFrozen = <%= isFrozen %>;
    $scope.startMode = "<%ar.writeJS(startMode);%>";
    $scope.filter = "";
    $scope.filterMap = {};
    $scope.canUpdate = <%=canUpdate%>;
    $scope.onlyNeedReview = false;

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

    function receiveDecisions(newDecisionList) {
        $scope.allDecisions = newDecisionList;
        $scope.allDecisions.forEach( function(item) {
            item.html = convertMarkdownToHtml(item.decision);
        });
        console.log("DECISION LIST:", $scope.allDecisions);
    }
    receiveDecisions($scope.allDecisions);

    $scope.findDecisions = function() {
        var filterlist = parseLCList($scope.filter);
        var src = $scope.allDecisions;
        var curTime = new Date().getTime();
        if ($scope.onlyNeedReview) {
            var res = [];
            src.forEach( function(item) {
                if (item.reviewDate>0 && item.reviewDate < curTime) {
                    res.push(item);
                }
            });
            src = res;
        }
        $scope.allLabelFilters().map( function(label) {
            var res = [];
            src.map( function(item) {
                if (item.labelMap[label.name]) {
                    res.push(item);
                }
            });
            src = res;
        });
        res = [];
        src.map( function(item) {
            if (containsOne(item.decision,filterlist)) {
                res.push(item);
            }
        });
        res.sort(function(a, b){return b.num-a.num});
        return res;
    };

    $scope.startCreating = function() {
        if ($scope.isFrozen) {
            alert("You are not able to create a new decision because this workspace is frozen");
            return;
        }
        if (!$scope.canUpdate) {
            alert("You are not able to create a new decision because you are a READ-ONLY user");
            return;
        }
        var newDec = {num:"~new~",universalid:"~new~",timestamp:new Date().getTime(),labelMap:{}}
        $scope.openDecisionEditor(newDec);
    }

    $scope.saveDecision = function(newRec) {
        if (!$scope.canUpdate) {
            alert("You are not able to save a new decision because you are a READ-ONLY user");
            return;
        }
        var isPreserved = (!newRec.deleteMe)
        var postURL = "updateDecision.json?did="+newRec.num;
        var postData = angular.toJson(newRec);
        console.log("SAVE DECISION:", newRec);
        $http.post(postURL, postData)
        .success( function(data) {
            var newList = [];
            console.log("SUCCESS DECISION:", data);
            $scope.allDecisions.forEach( function(item) {
                if (item.num != data.num) {
                    newList.push(item);
                }
            });
            if (isPreserved) {
                newList.push(data);
            }
            receiveDecisions(newList);
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


    $scope.openDecisionEditor = function (decision) {
        if ($scope.isFrozen) {
            alert("You are not able to edit decisions because this workspace is frozen");
            return;
        }
        if (!$scope.canUpdate) {
            alert("You are not able to edit decisions because you are a READ-ONLY user");
            return;
        }
        var modalInstance = $modal.open({
            animation: false,
            templateUrl: "<%=ar.retPath%>templates/DecisionModal.html?t="+new Date().getTime(),
            controller: 'DecisionModalCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                decision: function () {
                    return JSON.parse(JSON.stringify(decision));
                },
                allLabels: function() {
                    return $scope.allLabels;
                },
                siteInfo: function() {
                    return $scope.siteInfo;
                }
            }
        });

        modalInstance.result.then(function (modifiedDecision) {
            $scope.saveDecision(modifiedDecision);
        }, function () {
            //cancel action - nothing really to do
        });
    };
    
    $scope.reviewStyle = function(date) {
        var diff = (date-(new Date()).getTime())/(24*60*60*1000);
        if (diff<0) {
            return {"color":"red","font-weight": "bold"};
        }
        else if (diff<14) {
            return {"color":"orange"};
        }
        return {"color":"lightgrey"};
    }
    
    $scope.advanceDate = function(decision) {
        if ($scope.isFrozen) {
            alert("You are not able to change due dates on decisions because the workspace is frozen");
            return;
        }
        if (!$scope.canUpdate) {
            alert("You are not able to change due dates on decisions because you are a READ-ONLY user");
            return;
        }
        decision.reviewDate = decision.reviewDate + (365*24*60*60*1000);
        $scope.saveDecision(decision);
    }
    if ($scope.startMode=="create") {
        $scope.startCreating();
        $scope.startMode="nothing";
    }
});


</script>

<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              ng-click="startCreating()">Create New Decision</a></li>
        </ul>
      </span>
    </div>


    <div class="well">
        Filter <input ng-model="filter"> &nbsp;
        <span ng-repeat="role in allLabelFilters()">
            <button class="labelButton" type="button" id="menu2"
               style="background-color:{{role.color}};"
               ng-show="hasLabel(role.name)" 
               ng-click="toggleLabel(role)">{{role.name}} <i class="fa fa-close"></i></button>
        </span>
        <span>
             <span class="dropdown">
               <button class="btn btn-sm btn-primary btn-raised dropdown-toggle" 
                       type="button" id="menu2" data-toggle="dropdown"
                       title="Add Filter by Label"><i class="fa fa-filter"></i></button>
               <ul class="dropdown-menu" role="menu" aria-labelledby="menu1" 
                   style="width:320px;left:-130px">
                 <li role="presentation" ng-repeat="rolex in allLabels" style="float:left">
                     <button ng-click="toggleLabel(rolex)" class="labelButton" 
                     ng-hide="hasLabel(rolex.name)" style="background-color:{{rolex.color}}">
                         {{rolex.name}}</button>
                 </li>
               </ul>
             </span>
        </span>
        <span>
            <input type="checkbox" ng-model="onlyNeedReview"/> Only Overdue
        </span>
    </div>


  <div  id="searchresultdiv0">
    <div class="taskListArea">
      <table id="ActiveTask" style="min-width:800px">
         <tr ng-repeat="rec in findDecisions()" id="node1503" class="ui-state-default" ng-dblclick="openDecisionEditor(rec)"
             style="background: linear-gradient(#EEE, white); margin: 5px;border-style:solid;border-color:#FFF;border-width:12px">
                <td style="padding:3px;vertical-align:top;margin:5px;">
<% if (canUpdate) { %>
                  <div class="dropdown" style="padding:4px">
                    <button class="dropdown-toggle specCaretBtn" type="button"  d="menu" 
                        data-toggle="dropdown"> <span class="caret"></span> </button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation"><a role="menuitem" tabindex="-1"
                          ng-click="openDecisionEditor(rec)" 
                          title="Open the decision edit box.">
                          Edit Decision</a></li>
                      <li role="presentation"><a role="menuitem" tabindex="-1"
                          ng-click="advanceDate(rec)" translate
                          title="Sets the review date to be one year later than currently set">
                          Advance Review Date 1 Year</a></li>
                    </ul>
                  </div>
<% } %>
                </td>
                <td style="padding:3px;vertical-align:top;;margin:5px;" id="DEC{{rec.num}}">
                  <a href="DecisionList.htm#DEC{{rec.num}}"><span style="font-size:200%;">{{rec.num}}</span></a>
                </td>
                <td style="padding:3px;vertical-align:top;;margin:5px;">
                  <div class="leafContent" style="padding:0px">
                    <div id="{{rec.id}}_1" style="max-width:800px;width:100%;color:#88F;margin:2px;vertical-align:bottom;">
                        <div class="taskOverview">
                            <i>{{rec.timestamp|cdate}}</i>
                            <span ng-repeat="label in getGoalLabels(rec)">
                              <button class="labelButton" style="background-color:{{label.color}};color:black;" 
                                     ng-click="toggleLabel(label)">
                                  {{label.name}}
                              </button>
                            </span>
                            <span ng-show="rec.reviewDate>10000" ng-style="reviewStyle(rec.reviewDate)">&nbsp; - &nbsp; Review By: {{rec.reviewDate|cdate}}</span>
                        </div>
                    </div>
                    <div ng-click="rec.show=!rec.show" >
                        <div ng-bind-html="rec.html" style="max-width:800px;"></div>
                    </div>
                    <div ng-show="rec.sourceType==4">
                        See topic <a href="<%=ar.retPath%>{{rec.sourceUrl}}">discussion</a>
                    </div>
                    <div ng-show="rec.sourceType==7">
                        See meeting <a href="<%=ar.retPath%>{{rec.sourceUrl}}">discussion</a>
                    </div>
                    <div ng-show="rec.sourceType==8">
                        See document <a href="<%=ar.retPath%>{{rec.sourceUrl}}">discussion</a>
                    </div>
                  </div>
                </td>

        </tr>
      </table>
    </div>
  </div>


      <div class="guideVocal" ng-show="allDecisions.length==0">
    You have no decisions in this workspace yet.
    You can create them using a option from the pull-down in the upper right of this page.
    They can also be created from a proposal or a comment anywhere.
    </div>


</div>

<script src="<%=ar.retPath%>templates/DecisionModal.js"></script>
<script src="<%=ar.baseURL%>templates/EditLabelsCtrl.js"></script>
<script src="<%=ar.retPath%>jscript/HtmlToMarkdown.js"></script>
<script src="<%=ar.retPath%>jscript/HtmlParser.js"></script>
<script src="<%=ar.baseURL%>jscript/TextMerger.js"></script>



