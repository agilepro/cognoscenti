<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.SharePortRecord"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of a workspace and here it is used to retrieve NGWorkspace.

*/

    String meetId      = ar.reqParam("id");
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    NGBook site = ngw.getSite();

    JSONArray allLabels = ngw.getJSONLabels();
        
%>

<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="Content-Language" content="en-us" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta http-equiv="imagetoolbar" content="no" />
    <meta name="viewport" content="user-scalable=no, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0" />

    <!-- INCLUDE the ANGULAR JS library -->
    <script src="<%=ar.baseURL%>jscript/angular.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/angular-translate.js"></script>
    <script src="<%=ar.baseURL%>jscript/ui-bootstrap-tpls.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/jquery.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/bootstrap.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/slap.js"></script>
    <link href="<%=ar.baseURL%>jscript/bootstrap.min.css" rel="stylesheet">
    <link href="<%=ar.baseURL%>jscript/ng-tags-input.css" rel="stylesheet">
    <script src="<%=ar.baseURL%>jscript/bootstrap-material-design/ripples.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/bootstrap-material-design/material.min.js"></script>
    <link rel="stylesheet" href="<%=ar.baseURL%>css/bootstrap-material-design/bootstrap-material-design.min.css" media="screen">
    <link rel="stylesheet" href="<%=ar.baseURL%>css/bootstrap-material-design/ripples.min.css" media="screen">

	<!-- INCLUDE web fonts -->
    <link href="<%=ar.retPath%>assets/font-awesome/css/font-awesome.min.css" rel="stylesheet"
          data-semver="4.3.0" data-require="font-awesome@*" />
	  <link href="<%=ar.retPath%>assets/google/css/PT_Sans-Web.css" rel="stylesheet"/>

    <link href="<%=ar.retPath%>bits/fixed-sidebar.min.css" rel="styleSheet" type="text/css" media="screen" />
    <!-- Weaver specific tweaks -->
    <link href="<%=ar.retPath%>bits/main.min.css" rel="styleSheet" type="text/css" media="screen" />
    <script src="<%=ar.baseURL%>jscript/TextMerger.js"></script>
    <script src='<%=ar.baseURL%>jscript/tinymce/tinymce.min.js'></script>
    <script src='<%=ar.baseURL%>jscript/tinymce/tinymce-ng.js'></script>
    <script src="<%=ar.baseURL%>jscript/textAngular-sanitize.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/MarkdownToHtml.js"></script>
    
    
    <script src="<%=ar.baseURL%>jscript/ng-tags-input.js"></script>
    <script src="<%=ar.baseURL%>jscript/common.js"></script>
    
	<!-- Date and Time Picker -->
    <link rel="stylesheet" href="<%=ar.retPath%>bits/angularjs-datetime-picker.css" />
    <script src="<%=ar.retPath%>bits/angularjs-datetime-picker.js"></script>
    <script src="<%=ar.retPath%>bits/moment.js"></script>
    <script>  moment().format(); </script>
    
    
    
<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap', 'ngSanitize','ngTagsInput','angularjs-datetime-picker','ui.tinymce']);
app.controller('myCtrl', function($scope, $http, $modal, $interval, AllPeople) {
    var templateCacheDefeater = "?"+new Date().getTime();
    $scope.loaded = false;
    $scope.meetId = "<%ar.writeJS(meetId);%>";
    $scope.visitors = [];
    $scope.allMinutes = [];
    $scope.allTitles = [];
    $scope.allHtml = [];
    $scope.isEditing = -1;
    $scope.selectedMinutes = {};
    $scope.enableClick = true;
    $scope.allLabels = <%allLabels.write(out,2,2);%>;
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,2);%>;
    
    //setting isUpdating to true prevents a second overlapping update
    $scope.isUpdating = false;
    //up an update was requested while updating, then mark here and 
    //immediately do another update when the current one finished.
    $scope.deferredUpdate = false;
    

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    function selectMinutes(name) {
        $scope.allMinutes.forEach( function(item) {
            if (name==item.title) {
                $scope.selectedMin = item;
            }
        });
    }
    $scope.changeTitle = function() {
        selectMinutes($scope.selectedTitle);
    }

    $scope.setMinutesData = function(data) {
        $scope.timerCorrection = data.serverTime - new Date().getTime();
        var newTitles = [];
        $scope.visitors = data.visitors;
        data.minutes.forEach( function(newItem) {
            existing = null;
            $scope.allMinutes.forEach( function(found) {
                if (found.id == newItem.id) {
                    existing = found;
                }
            });
            if (!existing) {
                $scope.allMinutes.push(newItem);
                existing = newItem;
                existing.old = newItem.new;
            }
            else if (newItem.new == existing.lastSave) {
                //if you get back what you sent to the server
                //then ignore it and don't update at all
                //whether user typing or not
                existing.old = existing.lastSave;
                existing.needsMerge = false;
            } 
            else if (newItem.new != existing.new) {
                //unfortunately, there are edits from someone else to 
                //merge in causing some loss from of current typing.
                console.log("merging new version from server.",newItem,existing);
                if (existing.isEditing) {
                    console.log("The item being edited has changed ... deferring merging");
                    existing.needsMerge = true;
                    existing.old = existing.lastSave;
                }
                else {
                    existing.new = Textmerger.get().merge(existing.lastSave, existing.new, newItem.new);
                    existing.old = newItem.new;
                    existing.needsMerge = false;
                }
            }
            else {
                existing.old = newItem.new;
                existing.needsMerge = false;
            }
            existing.lastSave = null;
            existing.timerRunning = newItem.timerRunning;
            existing.timerStart = newItem.timerStart;
            existing.timerElapsed = newItem.timerElapsed;
            existing.duration = newItem.duration;
            newTitles.push(newItem.title);
        });
        if ($scope.allTitles.length==0) {
            $scope.allTitles = newTitles;
            $scope.selectedTitle = newTitles[0];
        }
        selectMinutes($scope.selectedTitle);
        $scope.calcTimes();
        $scope.allMinutes.forEach( function(min) {
            min.html = convertMarkdownToHtml(min.new);
        });
        $scope.loaded = true;   
    }
    
    
    $scope.getMeetingNotes = function() {
        $scope.isUpdating = true;
        var postURL = "getMeetingNotes.json?id="+$scope.meetId;
        $http.get(postURL)
        .success( function(data) {
            $scope.setMinutesData(data);
            $scope.handleDeferred();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
        
    }
    $scope.getMeetingNotes();
    
    $scope.handleDeferred = function() {
        $scope.isUpdating = false;
        if ($scope.deferredUpdate) {
            $scope.deferredUpdate = false;
            $scope.autosave();
        }
    }
    
    $scope.saveMinutes = function(min) {
        if ($scope.isUpdating) {
            console.log("update was deferred because we are already updating");
            $scope.deferredUpdate = true;
            return;
        }
        $scope.autosave();
    }
    $scope.autosave = function() {
        if ($scope.showError) {
            console.log("Autosave is turned off when there is an error.")
            return;
        }
        if ($scope.isUpdating) {
            console.log("update was skipped because we are already updating");
            return;
        }
        $scope.isUpdating = true;
        var postURL = "updateMeetingNotes.json?id="+$scope.meetId;
        var postRecord = {minutes:[]};
        $scope.allMinutes.forEach( function(item) {
            if (item.new != item.old) {
                postRecord.minutes.push( JSON.parse( JSON.stringify( item )));
            }
            item.lastSave = item.new;
        });
        var postData = JSON.stringify(postRecord);
        $http.post(postURL, postData)
        .success( function(data) {
            $scope.setMinutesData(data);
            $scope.handleDeferred();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
            $scope.handleDeferred();
        });
    }
	$scope.promiseAutosave = $interval($scope.autosave, 3000);
    
    $scope.closeWindow = function() {
        $scope.autosave();
        window.close();
    }
    $scope.startAgendaRunning = function(agendaItem) {
        var saveRecord = {};
        saveRecord.startTimer = agendaItem.id;
        $scope.sendTimerChangeToServer(saveRecord);
    }
    $scope.stopAgendaRunning = function() {
        var saveRecord = {};
        saveRecord.stopTimer = "0";
        $scope.sendTimerChangeToServer(saveRecord);
    }    
    $scope.sendTimerChangeToServer = function(readyToSave) {
        var postURL = "meetingUpdate.json?id="+$scope.meetId;
        var postData = angular.toJson(readyToSave);
        $http.post(postURL, postData)
        .success( function(data) {
            data.agenda.forEach( function(receivedItem) {
                $scope.allMinutes.forEach( function(realItem) {
                    if (receivedItem.id == realItem.id) {
                        realItem.timerRunning = receivedItem.timerRunning;
                        realItem.timerStart = receivedItem.timerStart;
                        realItem.timerElapsed = receivedItem.timerElapsed;
                    }
                });
            });
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.timerStyle = function(item) {
        var style = {"background-color":"yellow", "color":"black", "padding":"5px"};
        if (item.timerRemaining<0) {
            style["background-color"] = "red";
        }
        return style;
    }
    $scope.calcTimes = function() {
        var totalTotal = 0;
        //get the time that it is on the server
        var nowTime = new Date().getTime() + $scope.timerCorrection;
        $scope.allMinutes.forEach( function(agendaItem) {
            if (agendaItem.timerRunning) {
                agendaItem.timerTotal = (agendaItem.timerElapsed + nowTime - agendaItem.timerStart)/60000;
            }
            else {
                agendaItem.timerTotal = (agendaItem.timerElapsed)/60000;
            }
            //the 500 is to round the time, instead of truncation
            agendaItem.timerRemaining = agendaItem.duration - agendaItem.timerTotal;
            totalTotal += agendaItem.timerTotal;
        });
        $scope.timerTotal = totalTotal;
    }
    function closeAllEditors() {
        $scope.autosave();
        $scope.allMinutes.forEach( function(min) {
            min.isEditing = false;
            min.needsMerge = false;
            min.html = convertMarkdownToHtml(min.new);
        });
    }
    
    $scope.editStyle = function(item) {
        if (item.needsMerge) {
            return {"background-color":"orange"};
        }
        else {
            return {"background-color":"lightyellow"};
        }
    }
    
    $scope.startEditing = function(min) {
        if (!$scope.enableClick) {
            return;
        }
        $scope.autosave();        
        closeAllEditors();
        min.isEditing = true;        
    }
    
    $scope.openAddDocument = function (item) {

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: "<%=ar.retPath%>templates/AttachDocument.html"+templateCacheDefeater,
            controller: 'AttachDocumentCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                containingQueryParams: function() {
                    return "meet="+$scope.meetId+"&ai="+item.id;
                },
                docSpaceURL: function() {
                    return "";
                }
            }
        });

        attachModalInstance.result
        .then(function (docList) {
            //nothing to do since this page does not display the document list
        }, function () {
            //cancel action - nothing really to do
        });
    };

    $scope.openAttachAction = function (item) {

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: "<%=ar.retPath%>templates/AttachAction.html"+templateCacheDefeater,
            controller: 'AttachActionCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                containingQueryParams: function() {
                    return "meet="+$scope.meetId+"&ai="+item.id;
                },
                siteId: function () {
                  return $scope.siteInfo.key;
                }
            }
        });

        attachModalInstance.result
        .then(function (selectedActionItems) {
            //no need to display anything here
        }, function () {
            //cancel action - nothing really to do
        });
    };
    $scope.closeEditor = function() {
        closeAllEditors();
    }
    $scope.editMode = function(mode) {
        closeAllEditors();
        if ('view'==mode) {
            $scope.enableClick = false;  
        }
        else {
            $scope.enableClick = true;  
        }    
    }

    $scope.openDecisionEditor = function (item) {

        var newDecision = {
            html: "",
            labelMap: {},
            sourceId: $scope.meetId,
            sourceType: 7
        };

        var decisionModalInstance = $modal.open({
            animation: false,
            templateUrl: "<%=ar.retPath%>templates/DecisionModal.html"+templateCacheDefeater,
            controller: 'DecisionModalCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                decision: function () {
                    return JSON.parse(JSON.stringify(newDecision));
                },
                allLabels: function() {
                    return $scope.allLabels;
                }
            }
        });

        decisionModalInstance.result
        .then(function (newDecision) {
            newDecision.num="~new~";
            newDecision.sourceType = 7;
            newDecision.universalid="~new~";
            var postURL = "updateDecision.json?did=~new~";
            var postData = angular.toJson(newDecision);
            $http.post(postURL, postData)
            .success( function(data) {
                
            })
            .error( function(data, status, headers, config) {
                $scope.reportError(data);
            });
        }, function () {
            //cancel action - nothing really to do
        });
    };    
    // Start the clock timer
    $interval($scope.calcTimes, 1000);
});
app.filter('minutes', function() {

  return function(input) {
    var neg = "";
    if (input<0) {
        neg = "-";
        input = 0-input;
    }
    var mins = Math.floor(input);
    var secs = Math.floor(((input-mins) * 60)+.5);
    if (secs<10) {
        return neg+mins+":0"+secs;
    }
    return neg+mins+":"+secs;

  }

});
function getInputSelection(el) {
    var start = 0, end = 0, normalizedValue, range,
        textInputRange, len, endRange;

    if (typeof el.selectionStart == "number" && typeof el.selectionEnd == "number") {
        start = el.selectionStart;
        end = el.selectionEnd;
    } else {
        range = document.selection.createRange();

        if (range && range.parentElement() == el) {
            len = el.value.length;
            normalizedValue = el.value.replace(/\r\n/g, "\n");

            // Create a working TextRange that lives only in the input
            textInputRange = el.createTextRange();
            textInputRange.moveToBookmark(range.getBookmark());

            // Check if the start and end of the selection are at the very end
            // of the input, since moveStart/moveEnd doesn't return what we want
            // in those cases
            endRange = el.createTextRange();
            endRange.collapse(false);

            if (textInputRange.compareEndPoints("StartToEnd", endRange) > -1) {
                start = end = len;
            } else {
                start = -textInputRange.moveStart("character", -len);
                start += normalizedValue.slice(0, start).split("\n").length - 1;

                if (textInputRange.compareEndPoints("EndToEnd", endRange) > -1) {
                    end = len;
                } else {
                    end = -textInputRange.moveEnd("character", -len);
                    end += normalizedValue.slice(0, end).split("\n").length - 1;
                }
            }
        }
    }

    return {
        start: start,
        end: end
    };
}

function offsetToRangeCharacterMove(el, offset) {
    return offset - (el.value.slice(0, offset).split("\r\n").length - 1);
}

function setInputSelection(el, startOffset, endOffset) {
    if (typeof el.selectionStart == "number" && typeof el.selectionEnd == "number") {
        el.selectionStart = startOffset;
        el.selectionEnd = endOffset;
    } else {
        var range = el.createTextRange();
        var startCharMove = offsetToRangeCharacterMove(el, startOffset);
        range.collapse(true);
        if (startOffset == endOffset) {
            range.move("character", startCharMove);
        } else {
            range.moveEnd("character", offsetToRangeCharacterMove(el, endOffset));
            range.moveStart("character", startCharMove);
        }
        range.select();
    }
}
</script>



</head>

<style>
.tighten li a {
    padding: 0px 5px !important;
    background-color: white;
}
.tighten li {
    background-color: white;
}
.tighten {
    padding: 5px !important;
    border: 5px #F0D7F7 solid !important;
    max-width:300px;
    background-color: white !important;
}
</style>

<body ng-app="myApp" ng-controller="myCtrl">
  <div class="bodyWrapper"  style="margin:50px">
    <nav class="navbar navbar-default appbar">
      <div class="container-fluid">
        <!-- Logo Brand -->
        <a class="navbar-brand"  title="Weaver Home Page">
          <img class="hidden-xs" alt="Weaver Icon" src="<%=ar.retPath%>bits/header-icon.png">
          <h1 style="width:100%">Weaver - Meeting Notes  &nbsp;  &nbsp;
          </h1>
        </a>
      </div>
      <div class="upRightOptions rightDivContent" style="z-index: 1001;">
        <button class="btn btn-sm btn-warning btn-raised" ng-click="editMode('view')" ng-show="enableClick">
                Editing</button>
        <button class="btn btn-sm btn-default btn-raised" ng-click="editMode('edit')" ng-hide="enableClick">
                View Only</button>
        <span class="dropdown" style="float:right;">
            <button class="btn btn-default btn-raised btn-sm dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                Options: <span class="caret"></span></button>
            <ul class="dropdown-menu tighten" role="menu" aria-labelledby="menu1">
                <li role="presentation"><a role="menuitem"
                    title="clicking on the text will not edit it"
                    href="#" ng-click="editMode('view')" >View Only</a></li>
                <li role="presentation"><a role="menuitem"
                    title="Enable click to edit"
                    href="#" ng-click="editMode('edit')" >Edit</a></li>
                <!-- li role="presentation"><a role="menuitem"
                    title="Assure that you are the only one editing"
                    href="#" ng-click="editMode('exclusive')" >Exclusive Edit</a></li -->
             </ul>
        </span> 
      </div>          
    </nav>
    
    <div >
    <%@include file="ErrorPanel.jsp"%>

      <div class="guideVocal" ng-hide="loaded">
        Fetching the data from the server . . .
      </div>
      <div class="guideVocal" ng-show="showError">
        Note: if you are experiencing an error getting or saving data, then this page
        may be out of date from the server.  You should refresh the page to make sure
        you are up to date with the server.
      </div>
      <div style="margin:20px">
          <b>Current Visitors: </b>
          <span ng-repeat="vuser in visitors">{{vuser.name}}, </span>
      </div>

      <div ng-show="loaded && !showError">

        <div class="panel panel-default" ng-repeat="min in allMinutes">
            <div class="panel-heading" >{{min.pos}}. {{min.title}}
                <span style="font-size:70%" ng-hide="min.needsMerge">
                    <span ng-hide="min.timerRunning" style="padding:5px">
                        <button ng-click="startAgendaRunning(min)"><i class="fa fa-clock-o"></i> Start</button>
                        Elapsed: {{min.timerTotal| minutes}}
                        Remaining: {{min.timerRemaining| minutes}}
                    </span>
                    <span ng-show="min.timerRunning" ng-style="timerStyle(min)">
                        <span>Running</span>
                        Elapsed: {{min.timerTotal| minutes}}
                        Remaining: {{min.timerRemaining| minutes}}
                        <button ng-click="stopAgendaRunning()"><i class="fa fa-clock-o"></i> Stop</button>
                    </span>
                </span>
                <span style="font-size:70%" ng-show="min.needsMerge">
                    <button ng-click="closeEditor()" style="background-color:red;color:white">
                        <i class="fa fa-exclamation-triangle"></i> Merge Changes from Others</button>
                </span>
                <button ng-click="saveMinutes(min)" style="font-size:70%" ng-hide="min.new==min.old">Save</button>
            </div>
            <div class="panel-body" ng-show="min.isEditing"  ng-style="editStyle(min)">
                <textarea ng-model="min.new" class="form-control" style="width:100%;height:200px"></textarea>
                <button class="btn btn-default btn-raised" ng-click="openAttachAction(min)">Add Action Item</button>
                <button class="btn btn-default btn-raised" ng-click="openAddDocument(min)">Add Document</button>
                <button class="btn btn-default btn-raised" ng-click="openDecisionEditor(min)">Add Decision</button>
                
                <button class="btn btn-primary btn-raised" style="float:right" ng-click="closeEditor()">Close</button>
            </div>
            <div class="panel-body" ng-hide="min.isEditing" ng-click="startEditing(min)">
                <div ng-bind-html="min.html" ></div>
                <div>&nbsp;</div>
            </div>

        </div>
        
            <div>
            Meeting Duration: {{timerTotal|minutes}}  
            <button ng-click="stopAgendaRunning()"><i class="fa fa-clock-o"></i> Stop</button>
            </div>

        
        <div class="guideVocal" ng-hide="allMinutes.length > 0">
          No minutes to show . . .
        </div>
      </div>
        
    </div>
  </div>
</body>
</html>

<script src="../../../jscript/AllPeople.js"></script>
<script src="<%=ar.retPath%>templates/AttachActionCtrl.js"></script>
<script src="<%=ar.retPath%>templates/AttachDocumentCtrl.js"></script>
<script src="<%=ar.retPath%>templates/DecisionModal.js"></script>



