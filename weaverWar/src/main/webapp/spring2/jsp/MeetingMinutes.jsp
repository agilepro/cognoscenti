<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.SharePortRecord"
%><%@ include file="/include.jsp"
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
    <script src="<%=ar.baseURL%>jscript/angular.js"></script>
    <script src="<%=ar.baseURL%>jscript/angular-translate.js"></script>
    <script src="<%=ar.baseURL%>jscript/ui-bootstrap-tpls.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/jquery.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/bootstrap.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/slap.js"></script>
    <link href="<%=ar.baseURL%>jscript/bootstrap.min.css" rel="stylesheet">
    
    <script src='<%=ar.baseURL%>jscript/tinymce/tinymce.min.js'></script>
    <script src='<%=ar.baseURL%>jscript/tinymce/tinymce-ng.js'></script>
    <script src="<%=ar.baseURL%>jscript/textAngular-sanitize.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/ng-tags-input.js"></script>
    <script src="<%=ar.baseURL%>jscript/MarkdownToHtml.js"></script>

    <script src="<%=ar.baseURL%>jscript/common.js"></script>
    <link href="<%=ar.baseURL%>jscript/ng-tags-input.css" rel="stylesheet">
    
    <!-- Bootstrap Material Design -->    
    <script src="<%=ar.baseURL%>jscript/bootstrap-material-design/ripples.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/bootstrap-material-design/material.min.js"></script>
    <link rel="stylesheet" href="<%=ar.baseURL%>css/bootstrap-material-design/bootstrap-material-design.min.css" media="screen">
    <link rel="stylesheet" href="<%=ar.baseURL%>css/bootstrap-material-design/ripples.min.css" media="screen">

	<!-- INCLUDE web fonts -->
    <link href="<%=ar.retPath%>assets/font-awesome/css/font-awesome.min.css" rel="stylesheet"
          data-semver="4.3.0" data-require="font-awesome@*" />
	  <link href="<%=ar.retPath%>assets/google/css/PT_Sans-Web.css" rel="stylesheet"/>

    <link href="<%=ar.retPath%>bits/fixed-sidebar.min.css" rel="styleSheet" type="text/css" media="screen" />
    
 	<!-- Date and Time Picker -->
    <link rel="stylesheet" href="<%=ar.retPath%>bits/angularjs-datetime-picker.css" />
    <script src="<%=ar.retPath%>bits/angularjs-datetime-picker.js"></script>
    <script src="<%=ar.retPath%>bits/moment.js"></script>
    <script>  moment().format(); </script>
    
    <!-- Weaver specific tweaks -->
    <link href="<%=ar.retPath%>bits/main.min.css" rel="styleSheet" type="text/css" media="screen" />
    <!--script src="<%=ar.baseURL%>jscript/TextMerger.js"></script-->
    
    
    

    
<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap', 'ngSanitize','ngTagsInput','angularjs-datetime-picker','pascalprecht.translate','ui.tinymce']);
app.controller('myCtrl', function($scope, $http, $modal, $interval, AllPeople) {
    setUpLearningMethods($scope, $modal, $http);
    var templateCacheDefeater = "?"+new Date().getTime();
    $scope.loaded = false;
    $scope.meetId = "<%ar.writeJS(meetId);%>";
    $scope.visitors = [];
    $scope.allTitles = [];
    $scope.allHtml = [];
    $scope.agendaList = [];
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

    function setMinutesData(data, lastUpdateId, lastUpdateValue) {
        console.log("NEW DATA", lastUpdateId, lastUpdateValue, data);
        $scope.visitors = data.visitors;
        $scope.timerCorrection = data.serverTime - new Date().getTime();
        
        var oldAgendaList = $scope.agendaList;
        var newAgendaList = [];
        data.minutes.forEach( function(newItem) {
            
            var itemEntry = null;
            oldAgendaList.forEach( function(found) {
                if (found.data.id == newItem.id) {
                    itemEntry = found;
                }
            });
            if (!itemEntry) {
                itemEntry = {};
                itemEntry.sim = new SimText(newItem.new);
            }
            else if (itemEntry.data.id == lastUpdateId) {
                itemEntry.sim.updateFromServer(lastUpdateValue, newItem.new);
            }
            else {
                if (itemEntry.sim.isEditing) {
                    //should never find one of these, but if so, ignore
                    console.log("     ERROR "+newItem.id+" and editing is improperly TRUE!!!");
                }
                else {
                    console.log("attempt to set value on NON editing one");
                    itemEntry.sim.init(newItem.new);
                }
            }
            itemEntry.data = newItem;
            newAgendaList.push(itemEntry);
        });
        $scope.agendaList = newAgendaList;
        $scope.calcTimes();
        $scope.loaded = true;   
    }
    
    
    $scope.getMeetingNotes = function() {
        $scope.isUpdating = true;
        var postURL = "getMeetingNotes.json?id="+$scope.meetId;
        $http.get(postURL)
        .success( function(data) {
            setMinutesData(data);
            $scope.isUpdating = false;
            $scope.handleDeferred();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
            $scope.isUpdating = false;
            $scope.handleDeferred();
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
        var postURL = "updateMeetingNotes.json?id="+$scope.meetId;
        var postRecord = {minutes:[]};
        var itemNeedingSave;
        $scope.agendaList.forEach( function(agendaItem) {
            if (agendaItem.sim.isEditing) {
                itemNeedingSave = agendaItem;
            }
        });
        
        if (itemNeedingSave) {
            saveSim(itemNeedingSave);
        }
        else {
            $scope.getMeetingNotes();
        }
    }
	$scope.promiseAutosave = $interval($scope.autosave, 3000);
    
    
    function saveSim(agendaItem) {
        if ($scope.isUpdating) {
            return;
        }
        $scope.isUpdating = true;
        var thisId = agendaItem.data.id;
        agendaItem.saving = true;
        var postURL = "updateMeetingNotes.json?id="+$scope.meetId;
        var postRecord = {minutes:[]};
        var lastSave = agendaItem.sim.getLocal();
        var itemData = {};
        itemData.id = thisId;
        itemData.new = lastSave;
        itemData.old = agendaItem.sim.vServer;
        postRecord.minutes.push(itemData);
        var postData = JSON.stringify(postRecord);
        $http.post(postURL, postData)
        .success( function(data) {
            setMinutesData(data, thisId, lastSave)
            $scope.isUpdating = false;
            $scope.handleDeferred();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
            $scope.isUpdating = false;
            $scope.handleDeferred();
        });
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
                $scope.agendaList.forEach( function(realItem) {
                    if (receivedItem.id == realItem.data.id) {
                        realItem.data.timerRunning = receivedItem.timerRunning;
                        realItem.data.timerStart = receivedItem.timerStart;
                        realItem.data.timerElapsed = receivedItem.timerElapsed;
                    }
                });
            });
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.timerStyleComplete = function(item) {
        if (!item) {
            return {};
        }
        if (!item.timerRunning) {
            if (item.proposed) {
                return {"background-color":"#222222", "color":"white"};
            }            
            if (item.isSpacer) {
                return {"background-color":"#bbbbbb"}
            }
            return {};
        }
        if (item.duration - item.timerTotal<0) {
            return {"background-color":"red", "color":"black"};
        }
        return {"background-color":"lightgreen", "color":"black"};
    }
    $scope.calcTimes = function() {
        var totalTotal = 0;
        //get the time that it is on the server
        var nowTime = new Date().getTime() + $scope.timerCorrection;
        $scope.agendaList.forEach( function(agendaItem) {
            if (agendaItem.timerRunning) {
                agendaItem.data.timerTotal = (agendaItem.data.timerElapsed + nowTime - agendaItem.data.timerStart)/60000;
            }
            else {
                agendaItem.data.timerTotal = (agendaItem.data.timerElapsed)/60000;
            }
            //the 500 is to round the time, instead of truncation
            agendaItem.data.timerRemaining = agendaItem.data.duration - agendaItem.data.timerTotal;
            totalTotal += agendaItem.data.timerTotal;
        });
        $scope.timerTotal = totalTotal;
    }
    function closeAllEditors() {
        $scope.autosave();
        $scope.agendaList.forEach( function(aItem) {
            aItem.sim.isEditing = false;
        });
    }
    
    $scope.editStyle = function(item) {
        if (item.sim.needMerge) {
            return {"background-color":"orange"};
        }
        else {
            return {"background-color":"lightyellow"};
        }
    }
    
    $scope.startEditing = function(aItem) {      
        closeAllEditors();
        aItem.sim.isEditing = true;
        console.log("Set the isEditing to true for "+aItem.data.id);
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
            size: 'xl',
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
            animation: true,
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
                },
                siteInfo: function() {
                    return $scope.siteInfo;
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
    
    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 400;
    $scope.tinymceOptions.init_instance_callback = function(editor) {
        $scope.initialContent = editor.getContent();
        editor.on('Change', tinymceChangeTrigger);
        editor.on('KeyUp', tinymceChangeTrigger);
        editor.on('Paste', tinymceChangeTrigger);
        editor.on('Remove', tinymceChangeTrigger);
        editor.on('Format', tinymceChangeTrigger);
    }
    function tinymceChangeTrigger(e, editor) {
        //this runs every keystroke in the editor
        $scope.lastKeyTimestamp = new Date().getTime();
        $scope.wikiEditing = HTML2Markdown($scope.htmlEditing, {});
        $scope.changesToSave = ($scope.wikiEditing != $scope.wikiLastSave);
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
    var secs = Math.floor(((input-mins) * 60)+.5);
    if (secs<10) {
        return neg+mins+":0"+secs;
    }
    return neg+mins+":"+secs;

  }

});




</script>



</head>
<body ng-app="myApp" ng-controller="myCtrl">



<div>
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

        <div class="panel panel-default" ng-repeat="aItem in agendaList">
            <div class="panel-heading" >{{aItem.data.pos}}. {{aItem.data.title}}
                <span style="font-size:70%" ng-hide="aItem.data.needMerge">
                    <span ng-hide="aItem.data.timerRunning" style="padding:5px">
                        <button ng-click="startAgendaRunning(aItem.data)"><i class="fa fa-clock-o"></i> Start</button>
                        Elapsed: {{aItem.data.timerTotal| minutes}}
                        Remaining: {{aItem.data.timerRemaining| minutes}}
                    </span>
                    <span ng-show="aItem.data.timerRunning" ng-style="timerStyleComplete(aItem.data)">
                        <span>Running</span>
                        Elapsed: {{aItem.data.timerTotal| minutes}}
                        Remaining: {{aItem.data.timerRemaining| minutes}}
                        <button ng-click="stopAgendaRunning()"><i class="fa fa-clock-o"></i> Stop</button>
                    </span>
                </span>
                <span style="font-size:70%" ng-show="aItem.sim.needMerge">
                    <button ng-click="closeEditor()" style="background-color:red;color:white">
                        <i class="fa fa-exclamation-triangle"></i> Merge Changes from Others</button>
                </span>
            </div>
            <div class="panel-body" ng-show="aItem.sim.isEditing"  ng-style="editStyle(aItem)">
                <div ui-tinymce="tinymceOptions" ng-model="aItem.sim.vHtml" 
                     class="leafContent" style="min-height:250px;" ></div>
                <button class="btn btn-default btn-raised" ng-click="openAttachAction(aItem.data)">Add Action Item</button>
                <button class="btn btn-default btn-raised" ng-click="openAddDocument(aItem.data)">Add Document</button>
                <button class="btn btn-default btn-raised" ng-click="openDecisionEditor(aItem.data)">Add Decision</button>
                <input type="checkbox" ng-model="aItem.sim.autoMerge"/> AutoMerge
                
                <button class="btn btn-primary btn-raised" style="float:right" ng-click="closeEditor()">Close</button>
            </div>
            <div class="panel-body" ng-hide="aItem.sim.isEditing" ng-dblclick="startEditing(aItem)">
                <div ng-bind-html="aItem.sim.vHtml"></div>
                <div ng-hide="aItem.sim.vHtml" style="color:#bbb">Double click to start editing</div>
                <div>&nbsp;</div>
            </div>

        </div>
        
            <div>
            Meeting Duration: {{timerTotal|minutes}}  
            <button ng-click="stopAgendaRunning()"><i class="fa fa-clock-o"></i> Stop</button>
            </div>

        
        <div class="guideVocal" ng-hide="agendaList.length > 0">
          No minutes to show . . .
        </div>
      </div>
        
    </div>
  </div>
</body>
</html>




