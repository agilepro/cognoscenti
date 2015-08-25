<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="functions.jsp"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%@page import="org.socialbiz.cog.AgendaItem"
%><%

    String go = ar.getCompleteURL();
    ar.assertMember("Must be a member to see meetings");

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();
    String meetId      = ar.reqParam("id");
    MeetingRecord meeting = ngp.findMeeting(meetId);
    String agendaId      = ar.reqParam("aid");

    JSONObject meetingInfo = meeting.getFullJSON(ar, ngp);
    JSONObject agendaInfo = null;

    boolean isNew = "~new~".equals(agendaId);
    if (isNew) {
        agendaInfo = new JSONObject();
        agendaInfo.put("id", "~new~");
        agendaInfo.put("position", 999);
        agendaInfo.put("actionItems", new JSONArray());
        agendaInfo.put("docList", new JSONArray());
    }
    else {
        AgendaItem selectedItem = meeting.findAgendaItem(agendaId);
        agendaInfo = selectedItem.getJSON(ar);
    }

    JSONArray goalList = ngp.getJSONGoals();
    JSONArray attachmentList = ngp.getJSONAttachments(ar);

    JSONArray allPeople = UserManager.getUniqueUsersJSON();


/* PROTOTYPE

    $scope.agendaItem = {
      "actionItems": [
        "MHYDHNLWG@facility-1-wellness-circle@9270",
        "SHEUIJMWG@facility-1-wellness-circle@9848",
        "SHEUIJMWG@facility-1-wellness-circle@8593",
        "SHEUIJMWG@facility-1-wellness-circle@6543",
        "SHEUIJMWG@facility-1-wellness-circle@9774"
      ],
      "desc": "This is the first procedure that we need to look at.  Details details details...",
      "docList": ["EZIGICMWG@facility-1-wellness-circle@8170"],
      "duration": 10,
      "id": "6746",
      "notes": "",
      "position": 1,
      "subject": "New Procedure to View"
    };

    $scope.attachmentList = [{
      "attType": "FILE",
      "deleted": false,
      "description": "",
      "id": "8170",
      "labelMap": {"NO Game": true},
      "modifiedtime": 1433396730716,
      "modifieduser": "kswenson@us.fujitsu.com",
      "name": "Wines_of_Silicon_Valley.pdf",
      "public": false,
      "size": 1149455,
      "universalid": "EZIGICMWG@facility-1-wellness-circle@8170",
      "upstream": false
    }];
*/
%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.meeting    = <%meetingInfo.write(out,2,4);%>;
    $scope.isNew      = <%=isNew%>;
    $scope.agendaItem = <%agendaInfo.write(out,2,4);%>;
    $scope.goalList = <%goalList.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.allPeople = <%allPeople.write(out,2,4);%>;
    $scope.allActions = [];
    $scope.newGoal = {};
    $scope.newAttachment = undefined;
    $scope.showInput = false;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.exception  = {};

    $scope.findActionItem = function(searchId) {
        for(var i=0; i<$scope.goalList.length; i++) {
            var oneItem = $scope.goalList[i];
            if (oneItem.universalid == searchId) {
                return oneItem;
            }
            if (oneItem.id == searchId) {
                //schema migration issue
                return oneItem;
            }
        }
        return {synopsys: "unknown item "+searchId};
    }
    $scope.calcAllActions = function() {
        var res = [];
        for(var j=0; j<$scope.agendaItem.actionItems.length; j++) {
            var searchId = $scope.agendaItem.actionItems[j];
            for(var i=0; i<$scope.goalList.length; i++) {
                var oneItem = $scope.goalList[i];
                if (oneItem.universalid == searchId) {
                    res.push(oneItem);
                }
                else if (oneItem.id == searchId) {
                    //schema migration issue
                    $scope.agendaItem.actionItems[j] = oneItem.universalid;
                    res.push(oneItem);
                }
            }
        }
        $scope.allActions = res;
    }

    $scope.reportError = function(serverErr) {
        alert(angular.toJson(serverErr));
        $scope.exception = serverErr.exception;
        $scope.showError=true;
        $scope.showTrace = false;
    };

    $scope.saveItem = function() {
        var postURL = "agendaUpdate.json?id="+$scope.meeting.id+"&aid="+$scope.agendaItem.id;
        var postdata = angular.toJson($scope.agendaItem);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.agendaItem = data;
            calcAllActions();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.changeItem = function(amount) {
        var offset = $scope.agendaItem.position + amount;
        if (offset < 1 || offset > $scope.meeting.agenda.length) {
            $scope.saveItem();
            return;
        }
        var newItemId = $scope.meeting.agenda[offset-1].id;
        var postURL = "agendaUpdate.json?id="+$scope.meeting.id+"&aid="+$scope.agendaItem.id;
        var postdata = angular.toJson($scope.agendaItem);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            window.location = "agendaItem.htm?id="+$scope.meeting.id+"&aid="+newItemId;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.createActionItem = function() {
        var postURL = "createActionItem.json?id="+$scope.meeting.id+"&aid="+$scope.agendaItem.id;
        var newSynop = $scope.newGoal.synopsis;
        if (newSynop == null || newSynop.length==0) {
            alert("must enter a description of the action item");
            return;
        }
        for(var i=0; i<$scope.goalList.length; i++) {
            var oneItem = $scope.goalList[i];
            if (oneItem.synposis == newSynop) {
                $scope.agendaItem.actionItems.push(oneItem.universalid);
                $scope.newGoal = {};
                $scope.calcAllActions();
                return;
            }
        }

        $scope.newGoal.state=2;
        $scope.newGoal.assignTo = [];
        var player = $scope.newAssignee;
        if (typeof player == "string") {
            var pos = player.lastIndexOf(" ");
            var name = player.substring(0,pos).trim();
            var uid = player.substring(pos).trim();
            player = {name: name, uid: uid};
        }

        $scope.newGoal.assignTo.push(player);

        var postdata = angular.toJson($scope.newGoal);
        alert(postdata);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.goalList.push(data);
            $scope.agendaItem.actionItems.push(data.universalid);
            $scope.newGoal = {};
            $scope.calcAllActions();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.meetingStateName = function() {
        if ($scope.meeting.state<=1) {
            return "Unstarted";
        }
        if ($scope.meeting.state==2) {
            return "Running";
        }
        return "Completed";
    }

    $scope.calcAllActions();

    $scope.findDoc = function(searchId) {
        for(var i=0; i<$scope.attachmentList.length; i++) {
            var oneDoc = $scope.attachmentList[i];
            if (oneDoc.universalid == searchId) {
                return oneDoc;
            }
        }
        return {name: "unknown doc "+searchId, description: "does not exist"};
    }
    $scope.findAllDocs = function() {
        var res = [];
        $scope.agendaItem.docList.map( function(docid) {
            res.push($scope.findDoc(docid));
        });
        return res;
    }
    $scope.addDocument = function() {
        $scope.agendaItem.docList.push($scope.newAttachment.universalid);
        $scope.newAttachment = undefined;
        $scope.saveItem();
    }
    $scope.iconName = function(rec) {
        var type = rec.attType;
        if ("FILE"==type) {
            return "iconFile.png";
        }
        if ("URL" == type) {
            return "iconUrl.png";
        }
        return "iconFileExtra.png";
    }
    $scope.filterAttachments = function(val) {
        var res = [];
        var limit = 12;
        if (val.length==0) {
            return res;
        }
        val = val.toLowerCase();
        for(var i=0; i<$scope.attachmentList.length; i++) {
            var oneDoc = $scope.attachmentList[i];
            if (oneDoc.name.toLowerCase().indexOf(val)>=0) {
                res.push(oneDoc);
                if (--limit <= 0) {
                    break;
                }
            }
            else if (oneDoc.description.toLowerCase().indexOf(val)>=0) {
                res.push(oneDoc);
                if (--limit <= 0) {
                    break;
                }
            }
        }
        return res;
    }
    $scope.getPeople = function(filter) {
        var lcfilter = filter.toLowerCase();
        var res = [];
        var last = $scope.allPeople.length;
        for (var i=0; i<last; i++) {
            var rec = $scope.allPeople[i];
            if (rec.name.toLowerCase().indexOf(lcfilter)>=0) {
                res.push(rec);
            }
        }
        return res;
    }

});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            <span ng-show="isNew">Create Agenda Item</span>
            <span ng-hide="isNew">Agenda Item {{agendaItem.position}}: {{agendaItem.subject}}</span>
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="saveItem()" >Save Changes</a></li>
              <% if (!meeting.isBacklogContainer()) { %>
                  <li role="presentation"><a role="menuitem" tabindex="-1"
                      href="#" ng-click="changeItem(-1)">Previous Agenda Item</a></li>
                  <li role="presentation"><a role="menuitem"
                      href="#" ng-click="changeItem(1)">Next Agenda Item</a></li>
              <% } %>
            </ul>
          </span>

        </div>
    </div>



    <div id="TheMeeting" style="">
        <div>
            <table>
            <% if (!meeting.isBacklogContainer()) { %>
                <tr>
                    <td class="gridTableColummHeader">Meeting:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2"><a href="meetingFull.htm?id={{meeting.id}}">{{meeting.name}}</a> @ {{meeting.startTime|date: "h:mma 'on' MM/dd/yyyy"}} ({{meetingStateName()}})</td>
                </tr>
                <tr><td style="height:10px"></td></tr>
            <%  } %>
                <tr>
                    <td class="gridTableColummHeader">Subject:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2" ng-show="meeting.state<=1"><input ng-model="agendaItem.subject"  class="form-control"/></td>
                    <td colspan="2" ng-show="meeting.state>=2">{{agendaItem.subject}}</td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader">Description:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2" ng-show="meeting.state<=1"><textarea ng-model="agendaItem.desc"  class="form-control" style="width:450px;"></textarea></td>
                    <td colspan="2" ng-show="meeting.state>=2">{{agendaItem.desc}}</td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader">Duration:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2" ng-show="meeting.state<=1"  class="form-inline form-group">
                        <input ng-model="agendaItem.duration" style="width:60px;" class="form-control"> &nbsp;
                        <span class="gridTableColummHeader"> &nbsp; Position: </span>
                        <input ng-model="agendaItem.position" style="width:60px;" class="form-control">
                    </td>
                    <td colspan="2" ng-show="meeting.state>=2"  class="form-inline form-group">
                        {{agendaItem.duration}} &nbsp;
                        <span class="gridTableColummHeader"> &nbsp; Position: </span>
                        {{agendaItem.position}}
                    </td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr id="trspath" ng-show="meeting.state>=2">
                    <td class="gridTableColummHeader">Notes:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2" ng-show="meeting.state==2">
                        <textarea ng-model="agendaItem.notes" class="form-control" style="width:450px;height:200px"
                         placeholder="Type notes here while running the meeting"></textarea>
                    </td>
                    <td colspan="2" ng-show="meeting.state>2">{{agendaItem.notes}}</td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr id="trspath" ng-show="meeting.state<=2">
                    <td class="gridTableColummHeader"></td>
                    <td style="width:20px;"></td>
                    <td colspan="2">
                        <button ng-click="saveItem()" class="btn btn-primary">Save Changes</button>
                        <button ng-click="changeItem(-1)" class="btn btn-primary">Previous Agenda Item</button>
                        <button ng-click="changeItem(1)" class="btn btn-primary">Next Agenda Item</button>
                    </td>
                </tr>
            </table>
        </div>
    <% if (!meeting.isBacklogContainer()) { %>
        <div class="generalSettings"   ng-show="meeting.state>=2">

            <table class="gridTable2" width="100%">
                <tr class="gridTableHeader">
                    <td width="300px">Action Item</td>
                    <td width="180px">Assignees</td>
                </tr>
                <tr ng-repeat="rec in allActions">
                    <td class="repositoryName"><a href="task{{rec.id}}.htm" target="_blank">
                        <img src="<%= ar.retPath %>/assets/goalstate/small{{rec.state}}.gif">
                        {{rec.synopsis}}</a>
                    </td>
                    <td><span ng-repeat="person in rec.assignTo">{{person.name}} </span></td>
                </tr>
            </table>
        </div>
        <div class="generalSettings"  ng-show="meeting.state==2">
            <table>
               <tr>
                    <td class="gridTableColummHeader">Action:</td>
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
                        <input type="text" ng-model="newAssignee" class="form-control" placeholder="Who should do it"
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
                    <td class="gridTableColummHeader"></td>
                    <td style="width:20px;"></td>
                    <td colspan="2">
                        <button class="btn btn-primary" ng-click="createActionItem()">Create New Action Item</button>
                    </td>
                </tr>
            </table>
        </div>
    <% } %>

        <div class="generalSettings">

            <table class="gridTable2" width="100%">
                <tr class="gridTableHeader">
                    <td width="200px">Attachment Name</td>
                    <td width="200px">Description</td>
                </tr>
                <tr ng-repeat="doc in findAllDocs()">
                    <td class="repositoryName">
                        <a href="docinfo{{doc.id}}.htm">
                           <img src="<%=ar.retPath%>assets/images/{{iconName(doc)}}"/>
                           {{doc.name}}
                        </a>
                    </td>
                    <td style="line-height: 1.3;">
                        {{doc.description}}
                    </td>
                </tr>
            </table>
        </div>

        <div class="generalSettings" ng-show="meeting.state<=2">
            <table>
               <tr>
                    <td class="gridTableColummHeader">Attachment:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2">
                        <input type="text" ng-model="newAttachment" class="form-control" placeholder="Type Document Name"
                        typeahead="attach as attach.name for attach in filterAttachments($viewValue)"
                        style="width:450px;">
                    </td>

               </tr>
               <tr><td style="height:10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader"></td>
                    <td style="width:20px;"></td>
                    <td colspan="2">
                        <button class="btn btn-primary" ng-click="addDocument()">Attach Document</button>
                    </td>
                </tr>
            </table>
        </div>

    </div>

</div>
