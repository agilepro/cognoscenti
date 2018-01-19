<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.SharePortRecord"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of a workspace and here it is used to retrieve NGPage.

*/

    String meetId      = ar.reqParam("id");
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);

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

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http, $modal, $interval) {
    $scope.loaded = false;
    $scope.meetId = "<%ar.writeJS(meetId);%>";
    $scope.allMinutes = [];
    $scope.allTitles = [];
    $scope.selectedMinutes = {};
    
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
            }
            else if (newItem.new == existing.lastSave) {
                //if you get back what you sent to the server
                //then ignore it and don't update what the user is typing.
                //because nothing new from server
                console.log("avoided disturbing user.");
            } 
            else if (newItem.new != existing.new) {
                //unfortunately, there are edits from someone else to 
                //merge in causing some loss from of current typing.
                console.log("merging new version from server.",newItem,existing);
                existing.new = Textmerger.get().merge(existing.lastSave, existing.new,                 newItem.new);
            }
            existing.lastSave = null;
            existing.old = newItem.new;
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
        /*
        $scope.isUpdating = true;
        var saveRec = {minutes:[]};
        saveRec.minutes.push(min);
        var postURL = "updateMeetingNotes.json?id="+$scope.meetId;
        console.log("Saving Current State: ", saveRec);
        var postData = JSON.stringify(saveRec);
        min.lastSave = min.new;
        $http.post(postURL, postData)
        .success( function(data) {
            $scope.setMinutesData(data);
            $scope.handleDeferred();
            console.log("Got Back: ", data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
            $scope.handleDeferred();
        });
        */
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
        console.log("Autosave Init: ", postRecord);
        var postData = JSON.stringify(postRecord);
        $http.post(postURL, postData)
        .success( function(data) {
            $scope.setMinutesData(data);
            $scope.handleDeferred();
            console.log("Autosave Got Back: ", data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
            $scope.handleDeferred();
        });
    }
	$scope.promiseAutosave = $interval($scope.autosave, 6000);
    
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
    // Start the clock timer
    $interval($scope.calcTimes, 1000);
    console.log("All loaded");
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

<body>
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
    </nav>
  
    <div ng-app="myApp" ng-controller="myCtrl">
    <%@include file="ErrorPanel.jsp"%>

      <div class="guideVocal" ng-hide="loaded">
        Fetching the data from the server . . .
      </div>
      <div class="guideVocal" ng-show="showError">
        Note: if you are experiencing an error getting or saving data, then this page
        may be out of date from the server.  You should refresh the page to make sure
        you are up to date with the server.
      </div>

      <div ng-show="loaded && !showError">

        <div class="panel panel-default" ng-repeat="min in allMinutes">
        <div class="panel-heading">{{min.pos}}. {{min.title}}
            <span style="font-size:70%">
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
            <button ng-click="saveMinutes(min)" style="font-size:70%" ng-hide="min.new==min.old">Save</button>
        </div>
        <div class="panel-body">
            <textarea ng-model="min.new" class="form-control" style="width:100%;height:200px"></textarea>
            
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





