<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%@page import="org.socialbiz.cog.AgendaItem"
%><%


    String pageId = ar.reqParam("pageId");
    NGWorkspace ngw = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngw);
    ar.assertMember("Must be a member to see meetings");
    NGBook ngb = ngw.getSite();
    String meetId          = ar.reqParam("id");
    MeetingRecord oneRef   = ngw.findMeeting(meetId);
    JSONObject meetingInfo = oneRef.getFullJSON(ar, ngw);
    JSONArray attachmentList = ngw.getJSONAttachments(ar);

    String minutesId = oneRef.getMinutesId();
    if (minutesId!=null) {
        NoteRecord  nr = ngw.getNoteByUidOrNull(minutesId);
        if (nr==null) {
            //schema migration to move to universal id
            nr = ngw.getNote(minutesId);
        }
        if (nr!=null) {
            meetingInfo.put("minutesLocalId", nr.getId());
        }
    }

    JSONObject backlogInfo = ngw.getAgendaItemBacklog().getFullJSON(ar, ngw);
    JSONArray goalList = ngw.getJSONGoals();

%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.meeting = <%meetingInfo.write(out,2,4);%>;
    $scope.backlog = <%backlogInfo.write(out,2,4);%>;
    $scope.goalList = <%goalList.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.newAgendaItem = {subject:"",duration:10,desc:"",id:""};
    $scope.showInput = false;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        var exception = serverErr.exception;
        $scope.errorMsg = exception.join();
        $scope.errorTrace = exception.stack;
        $scope.showError=true;
        $scope.showTrace = false;
    };

    $scope.sortItems = function() {
        $scope.meeting.agenda.sort( function(a, b){
            return a.position - b.position;
        } );
        var runTime = $scope.meetingTime;
        for (var i=0; i<$scope.meeting.agenda.length; i++) {
            var item = $scope.meeting.agenda[i];
            item.position = i+1;
            item.schedule = runTime;
            runTime = new Date( runTime.getTime() + (item.duration*60000) );
        }
        $scope.meeting.endTime = runTime;
        return $scope.meeting.agenda;
    };
    $scope.extractDateParts = function() {
        $scope.meetingTime = new Date($scope.meeting.startTime);
        $scope.meetingHour = $scope.meetingTime.getHours();
        $scope.meetingMinutes = $scope.meetingTime.getMinutes();
        $scope.sortItems();
    };
    $scope.extractDateParts();

    $scope.datePickOptions = {
        formatYear: 'yyyy',
        startingDay: 1
    };
    $scope.datePickDisable = function(date, mode) {
        return false;
    };
    $scope.datePickOpen = false;
    $scope.openDatePicker = function($event) {
        $event.preventDefault();
        $event.stopPropagation();
        $scope.datePickOpen = true;
    };


    $scope.deleteRow = function(row) {
        var delId = row.id;
        var postURL = "agendaMove.json?src="+$scope.meeting.id+"&dest="+$scope.backlog.id;
        var postdata = angular.toJson(row);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            var newSet = [];
            for( var i =0; i<$scope.meeting.agenda.length; i++) {
                var irow = $scope.meeting.agenda[i];
                if (delId != irow.id) {
                    newSet.push(irow);
                }
            }
            $scope.meeting.agenda = newSet;
            $scope.backlog.agenda.push(row);
            $scope.extractDateParts();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.acquire = function(row) {
        var delId = row.id;
        var postURL = "agendaMove.json?src="+$scope.backlog.id+"&dest="+$scope.meeting.id;
        var postdata = angular.toJson(row);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(newAgendaItem) {
            var newSet = [];
            for( var i =0; i<$scope.backlog.agenda.length; i++) {
                var irow = $scope.backlog.agenda[i];
                if (delId != irow.id) {
                    newSet.push(irow);
                }
            }
            $scope.backlog.agenda = newSet;
            $scope.meeting.agenda.push(newAgendaItem);
            $scope.extractDateParts();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };


    $scope.createRow = function() {
        var postURL = "agendaAdd.json?id="+$scope.meeting.id;
        var postdata = angular.toJson($scope.newAgendaItem);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {

            $scope.meeting.agenda.push(data);
            $scope.newAgendaItem = {subject:"",duration:10,desc:"",id:""};
            $scope.showInput=false;
            $scope.extractDateParts();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.createMinutes = function() {
        var postURL = "createMinutes.json?id="+$scope.meeting.id;
        var postdata = angular.toJson("");
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.meeting = data;
            $scope.showInput=false;
            $scope.extractDateParts();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.getAllocated = function() {
        var total = 0;
        for( var i =0; i<$scope.meeting.agenda.length; i++) {
            var irow = $scope.meeting.agenda[i];
            total = total + irow.duration;
        }
        return total;
    };


    $scope.changeMeetingState = function(newState) {
        $scope.meeting.state = newState;
        $scope.saveMeeting();
    };
    $scope.stateName = function() {
        if ($scope.meeting.state<=1) {
            return "Planning";
        }
        if ($scope.meeting.state==2) {
            return "Running";
        }
        return "Completed";
    };

    $scope.saveMeeting = function() {
        $scope.meetingTime.setHours($scope.meetingHour);
        $scope.meetingTime.setMinutes($scope.meetingMinutes);
        $scope.meeting.startTime = $scope.meetingTime.getTime();

        $scope.sortItems();
        var postURL = "meetingUpdate.json?id="+$scope.meeting.id;
        var postdata = angular.toJson($scope.meeting);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.meeting = data;
            $scope.extractDateParts();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.allActionItems = function() {
        var list = [];
        $scope.meeting.agenda.map( function(ai) {
            ai.actionItems.map( function(item) {
                $scope.goalList.map( function(goal) {
                    if (goal.universalid == item) {
                        list.push(goal);
                    }
                    else if (goal.id == item) {
                        list.push(goal);
                    };
                });
            });
        });
        return list;
    };

    $scope.moveItem = function(rec, offset) {
        var pos = rec.position-1;
        var size = $scope.meeting.agenda.length;
        var other = pos + offset;
        if (other >= 0 && other < size) {
            var buf = $scope.meeting.agenda[pos].position;
            $scope.meeting.agenda[pos].position = $scope.meeting.agenda[other].position;
            $scope.meeting.agenda[other].position = buf;
            $scope.saveMeeting();
        };
    };

    $scope.getItemIndex = function(rec) {
        var last = $scope.meeting.agenda.length;
        for (var i=0; i<last; i++) {
            var item = $scope.meeting.agenda[i];
            if (item.id == rec.id) {
                return i;
            }
        }
        return -1;
    };

    $scope.allDocuments = function() {
        var coll = [];
        var eliminateDups = {};
        $scope.meeting.agenda.map( function(agendaItem) {
            agendaItem.docList.map( function(docid) {
                console.log("Considering "+docid);
                if (!eliminateDups[docid]) {
                    $scope.attachmentList.map( function(att) {
                        if (att.universalid == docid) {
                            coll.push(att);
                        }
                    });
                }
                eliminateDups[docid] = true;
            });
        });
        return coll;
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
    $scope.meetingStateStyle = function(val) {
        if (val<=1) {
            return "background-color:white";
        }
        if (val==2) {
            return "background-color:lightgreen";
        }
        if (val>2) {
            return "background-color:gray";
        }
        return "Unknown";
    }

});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Meeting: <a href="meetingFull.htm?id={{meeting.id}}">{{meeting.name}}</a>
            @ {{meeting.startTime|date: "HH:mm 'on' dd-MMM-yyyy"}}
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#"  ng-click="showInput=!showInput">Create New Agenda Item</a></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#"  ng-click="showBacklog=!showBacklog">Get Agenda Item from Backlog</a></li>
              <li role="presentation" class="divider"></li>
              <li role="presentation"><a role="menuitem"
                  href="meetingFull.htm?id={{meeting.id}}">View Full Meeting</a></li>
              <li role="presentation"><a role="menuitem"
                  href="sendNote.htm?meet={{meeting.id}}">Send Email about Meeting</a></li>
              <li role="presentation"><a role="menuitem"
                  href="cloneMeeting.htm?id={{meeting.id}}">Clone This Meeting</a></li>
              <li role="presentation" class="divider"></li>
              <li role="presentation"><a role="menuitem"
                  href="#" ng-click="createMinutes()">Generate Minutes</a></li>
              <li role="presentation" ng-show="meeting.minutesId"><a role="menuitem"
                  href="noteZoom{{meeting.minutesLocalId}}.htm">View Minutes</a></li>
              <li role="presentation" class="divider"></li>
              <li role="presentation"><a role="menuitem"
                  href="meetingList.htm">List All Meetings</a></li>
            </ul>
          </span>

        </div>
    </div>



    <div id="NewAgenda" class="well" ng-show="showInput" ng-cloak>
        <div class="rightDivContent">
            <a href="#" ng-click="showInput=false"><img src="<%= ar.retPath%>assets/iconBlackDelete.gif"/></a>
        </div>
        <table>
            <tr id="trspath">
                <td class="gridTableColummHeader">Subject:</td>
                <td style="width:20px;"></td>
                <td colspan="2"><input type="text" ng-model="newAgendaItem.subject" class="form-control" size="69" /></td>
            </tr>
            <tr><td style="height:10px"></td></tr>
            <tr id="trspath">
                <td class="gridTableColummHeader">Description:</td>
                <td style="width:20px;"></td>
                <td colspan="2"><textarea  class="form-control" ng-model="newAgendaItem.desc" rows="5" cols="69"/></textarea></td>
            </tr>
            <tr><td style="height:10px"></td></tr>
            <tr id="trspath">
                <td class="gridTableColummHeader">Duration:</td>
                <td style="width:20px;"></td>
                <td colspan="2"><input type="text" ng-model="newAgendaItem.duration" class="form-control" /></td>
            </tr>
            <tr><td style="height:10px"></td></tr>
            <tr>
                <td class="gridTableColummHeader"></td>
                <td style="width:20px;"></td>
                <td colspan="2">
                    <input type="submit" class="btn btn-primary" value="Create Agenda Item" ng-click="createRow()">
                    <input type="button" class="btn btn-primary" value="Cancel" ng-click="showInput=false">
                </td>
            </tr>
        </table>
    </div>

    <div class="well"  ng-show="showBacklog" ng-cloak>
        <div class="rightDivContent">
            <a href="#" ng-click="showBacklog=!showBacklog"><img src="<%= ar.retPath%>assets/iconBlackDelete.gif"/></a>
        </div>
        <div class="generalSettings">
            <table class="gridTable2" width="100%">
                <tr class="gridTableHeader">
                    <td width="50px">Action</td>
                    <td width="200px">Backlog Agenda Item</td>
                    <td width="200px">Description</td>
                    <td width="50px">Duration</td>
                </tr>
                <tr ng-repeat="bi in backlog.agenda">
                    <td><button class="btn btn-sm btn-primary" ng-click="acquire(bi)" title="Move this item to the meeting">Move</button></td>
                    <td>{{bi.subject}}</td>
                    <td>{{bi.desc|limitTo:50}}</td>
                    <td>{{bi.duration}}</td>
                </tr>
            </table>
        </div>
    </div>


    <table class="gridTable2" width="100%">
        <tr class="gridTableHeader">
            <td width="50px"></td>
            <td width="30px">Time</td>
            <td width="200px">Agenda Item</td>
            <td width="200px">Description</td>
            <td width="50px">Duration</td>
        </tr>
        <tr ng-repeat="rec in sortItems()">
            <td>
              <div class="dropdown">
                <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                <span class="caret"></span></button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li role="presentation"><a role="menuitem" tabindex="-1"
                      href="#"  ng-click="moveItem(rec, -1)">Move Up</a></li>
                  <li role="presentation"><a role="menuitem" tabindex="-1"
                      href="#"  ng-click="moveItem(rec, 1)">Move Down</a></li>
                  <li role="presentation" class="divider"></li>
                  <li role="presentation"><a role="menuitem" tabindex="-1"
                      href="#"  ng-click="deleteRow(rec)">Move to Backlog</a></li>
                </ul>
              </div>
            </td>
            <td >
                {{rec.schedule | date: 'HH:mm'}}</td>
            <td><b>{{rec.position}}. {{rec.subject}}</b>
                </td>
            <td style="line-height: 1.3;">{{rec.desc|limitTo:200}}</td>
            <td>{{rec.duration}}</td>
        </tr>
        <tr>
            <td>
              <div class="dropdown">
                <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                <span class="caret"></span></button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li role="presentation"><a role="menuitem" tabindex="-1"
                      href="#"  ng-click="showInput=!showInput">Create New Agenda Item</a></li>
                  <li role="presentation"><a role="menuitem" tabindex="-1"
                      href="#"  ng-click="showBacklog=!showBacklog">Get Agenda Item from Backlog</a></li>
                </ul>
              </div>
            </td>
            <td >
                {{meeting.endTime | date: 'HH:mm'}}
            </td>
            <td>~end~</td>
            <td></td>
            <td></td>
        </tr>
    </table>

    <div style="height:30px;"></div>

    <table class="gridTable2" width="100%">
        <tr class="gridTableHeader">
            <td width="200px">Action Item ~ Description</td>
            <td width="50px">Assignees</td>
        </tr>
        <tr ng-repeat="rec in allActionItems()">
            <td >
                <img src="<%= ar.retPath %>assets/goalstate/small{{rec.state}}.gif">
                <a href="task{{rec.id}}.htm">{{rec.synopsis}}</a>
                ~
                {{rec.description}}
            </td>
            <td>
                <span ng-repeat="person in rec.assignTo"> {{person.name}} </span>
            </td>

        </tr>
    </table>

    <div class="generalSettings">

        <table class="gridTable2" width="100%">
            <tr class="gridTableHeader">
                <td width="200px">Attachment Name</td>
                <td width="200px">Description</td>
            </tr>
            <tr ng-repeat="doc in allDocuments()">
                <td class="repositoryName">
                    <a href="docinfo{{doc.id}}.htm">
                       <img src="<%=ar.retPath%>assets/images/{{iconName(doc)}}"/>
                       {{doc.name}}
                    </a>
                </td>
                <td style="line-height: 1.3;">{{doc.description}}</span></td>
            </tr>
        </table>
    </div>

</div>
