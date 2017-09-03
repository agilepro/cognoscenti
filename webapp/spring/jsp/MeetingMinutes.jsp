<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.SharePortRecord"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of a workspace and here it is used to retrieve NGPage.

*/

    String pageId      = ar.reqParam("pageId");
    String meetId      = ar.reqParam("id");
    NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
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

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http, $modal, $interval) {
    $scope.loaded = false;
    $scope.meetId = "<%ar.writeJS(meetId);%>";
    $scope.allMinutes = [];
    $scope.allTitles = [];
    $scope.selectedMinutes = {};
    

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
        if ($scope.allMinutes.length==0) {
            $scope.allMinutes = data.minutes;
        }
        data.minutes.forEach( function(newItem) {
            $scope.allMinutes.forEach( function(found) {
                if (found.id == newItem.id) {
                    if (newItem.new != found.new) {
                        found.new = newItem.new;
                    }
                    found.old = newItem.new;
                    found.timerRunning = newItem.timerRunning;
                    found.timerStart = newItem.timerStart;
                    found.timerElapsed = newItem.timerElapsed;
                    found.duration = newItem.duration;
                }
            });
            newTitles.push(newItem.title);
        });
        if ($scope.allTitles.length==0) {
            $scope.allTitles = newTitles;
            $scope.selectedTitle = newTitles[0];
        }
        selectMinutes($scope.selectedTitle);
        $scope.loaded = true;   
    }
    
    
    $scope.getMinutes = function() {
        var postURL = "getMinutes.json?id="+$scope.meetId;
        $http.get(postURL)
        .success( function(data) {
            $scope.setMinutesData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
        
    }
    $scope.getMinutes();
    
    $scope.saveMinutes = function(min) {
        var saveRec = {minutes:[]};
        saveRec.minutes.push(min);
        var postURL = "updateMinutes.json?id="+$scope.meetId;
        var postDate = JSON.stringify(saveRec);
        console.log("About to save", postURL, saveRec);
        $http.post(postURL, postDate)
        .success( function(data) {
            $scope.setMinutesData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.autosave = function() {
        var postURL = "updateMinutes.json?id="+$scope.meetId;
        var postRecord = {};
        postRecord.minutes = $scope.allMinutes;
        var postData = JSON.stringify(postRecord);
        console.log("About to AUTO save", postURL, postRecord);
        $http.post(postURL, postData)
        .success( function(data) {
            $scope.setMinutesData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
	$scope.promiseAutosave = $interval($scope.autosave, 5000);
    
    $scope.closeWindow = function() {
        $scope.autosave();
        window.close();
    }
    $scope.startAgendaRunning = function(agendaItem) {
        var saveRecord = {};
        saveRecord.startTimer = agendaItem.id;
        $scope.putGetMeetingInfo(saveRecord);
    }
    $scope.stopAgendaRunning = function() {
        var saveRecord = {};
        saveRecord.stopTimer = "0";
        $scope.putGetMeetingInfo(saveRecord);
    }    
    $scope.putGetMeetingInfo = function(readyToSave) {
        var postURL = "meetingUpdate.json?id="+$scope.meetId;
        console.log("Saving meeting: ", readyToSave);
        var postData = angular.toJson(readyToSave);
        $http.post(postURL, postData)
        .success( function(data) {
            $scope.getMinutes();
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
            agendaItem.timerRemaining = agendaItem.duration - agendaItem.timerTotal;
            totalTotal += agendaItem.timerTotal;
        });
        $scope.timerTotal = totalTotal;
    }
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
    var secs = Math.floor((input-mins) * 60);
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
          <h1 style="width:100%">Weaver - Minutes Editor  &nbsp;  &nbsp;
          <button ng-click="closeWindow()" style="font-size:70%;float:right;color:black" ng-hide="min.new==min.old">Close</button>
          </h1>
        </a>
      </div>
    </nav>
  
    <div ng-app="myApp" ng-controller="myCtrl">
    <%@include file="ErrorPanel.jsp"%>

      <div class="guideVocal" ng-hide="loaded">
        Fetching the data from the server . . .
      </div>

      <div ng-show="loaded">

        <div class="panel panel-default" ng-repeat="min in allMinutes">
        <div class="panel-heading">{{min.pos}}. {{min.title}}
            <span style="font-size:70%">
                <span ng-hide="min.timerRunning" style="padding:5px">
                    <button ng-click="startAgendaRunning(min)"><i class="fa fa-clock-o"></i> Start</button>
                    Elapsed: {{min.timerTotal| minutes}}
                    Remaining: {{min.duration - min.timerTotal| minutes}}
                </span>
                <span ng-show="min.timerRunning" ng-style="timerStyle(min)">
                    <span>Running</span>
                    Elapsed: {{min.timerTotal| minutes}}
                    Remaining: {{min.duration - min.timerTotal| minutes}}
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





