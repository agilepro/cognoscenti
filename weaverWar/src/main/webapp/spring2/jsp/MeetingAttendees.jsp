<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to see a list of meetings");

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    String localId = ar.baseURL + "t/"+siteId+"/"+pageId+"/";
    String siteInfoURL = ar.baseURL + "t/"+siteId+"/$/siteInfo.json";
    
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    NGBook site = ngp.getSite();
    
    JSONObject attendeeMatrix = MeetingRecord.findAttendeeMatrix(ngp);

%>

<script src="../../../jscript/AllPeople.js"></script>

<script type="text/javascript">
WCACHE.putObj("<%ar.writeJS(siteInfoURL);%>", <%site.getConfigJSON().write(out,2,4);%>, <%=System.currentTimeMillis()%>);

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, AllPeople, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Meeting Attendee Matrix");
    $scope.siteProxy = getSiteProxy("<%ar.writeJS(ar.baseURL);%>", "<%ar.writeJS(siteId);%>");
    $scope.wsProxy = $scope.siteProxy.getWorkspaceProxy("<%ar.writeJS(pageId);%>", $scope);
    $scope.siteInfo = WCACHE.getObj("<%ar.writeJS(siteInfoURL);%>");
    $scope.meetings = [];
    $scope.wsProxy.getMeetingList(data => {$scope.meetings = data.meetings});
    $scope.attendeeMatrix = <%attendeeMatrix.write(out, 2, 4);%>;
    $scope.browserZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    
    
    console.log("SITE OBJ: ", AllPeople.getSiteObject($scope.siteInfo.key));
    console.log("NOW TIME: ", new Date().getTime());
    console.log("MATRIX: ", $scope.attendeeMatrix);
    console.log("ALL USERS: ", AllPeople.getSiteObject($scope.siteInfo.key));
    
    $scope.foundUsers = [];
    Object.keys($scope.attendeeMatrix).forEach( function(att) {
        
        let person = AllPeople.findPerson(att, $scope.siteInfo.key);
        if (person) {
            if (person.key==att) {
                $scope.foundUsers.push(person);
            }
            else {
                console.log("Searched for "+att+" but found "+person.uid);
            }
            console.log("Found: ", att, $scope.attendeeMatrix[att]);
        }
        else {
            console.log("Did not find "+att);
        }
    });
    console.log("FOUND USERS: ", $scope.foundUsers);
    
    $scope.isInAttendance = false;
    
    var n = new Date().getTimezoneOffset();
    var tzNeg = n<0;
    if (tzNeg) {
        n = -n;
    }
    var tzHours = Math.floor(n/60);
    var tzMinutes = n - (tzHours*60);
    var tzFiddle = (100 + tzHours)*100 + tzMinutes;
    var txFmt = tzFiddle.toString().substring(1);
    if (tzNeg) {
        txFmt = "+".concat(txFmt);
    }
    else {
        txFmt = "-".concat(txFmt);
    }
    $scope.tzIndicator = txFmt;

    $scope.currentPage = 0;



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

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.wsProxy.failure = $scope.reportError;



    $scope.deleteRow = function(row) {
        if (row.state > 0) {
            if (!confirm("Are you sure you want to delete meeting?\n"+row.name+"\n"+new Date(row.startTime))) {
                return;
            }
        }
        var delId = row.id;
        var postURL = "meetingDelete.json";
        var postdata = angular.toJson(row);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            var newSet = [];
            for( var i =0; i<$scope.meetings.length; i++) {
                var irow = $scope.meetings[i];
                if (delId != irow.id) {
                    newSet.push(irow);
                }
            }
            $scope.meetings = newSet;
            WCACHE.putObj(localKey+"meetingList.json", newSet, new Date().getTime());
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };



    $scope.meetingStateName = function(val) {
        if (val<=0) {
            return "Draft";
        }
        if (val==1) {
            return "Planning";
        }
        if (val==2) {
            return "Running";
        }
        if (val>2) {
            return "Completed";
        }
        return "Unknown";
    }

    $scope.meetingStateStyle = function(val) {
        if (val<=0) {
            return "background-color:#f0c85a";
        }
        if (val<=1) {
            return "background-color:#7dc7ff";
        }
        if (val==2) {
            return "background-color:#c3b9c9";
        }
        if (val>2) {
            return "background-color:#6c666e";
        }
        return "Unknown";
    }
    
});
</script>

<!-- MAIN CONTENT SECTION START -->
<div class="container-fluid override mb-4 mx-3 d-inline-flex">
    <span class="dropdown mt-1">
        <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
            data-bs-toggle="dropdown" aria-expanded="false">
        </button>
        <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
            <li>
                <button class="dropdown-item" onclick="window.location.reload(true)">Refresh</button>
                <span class="dropdown-item" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewTopic">
                    <a class="nav-link" role="menuitem" tabindex="-1" title="Create a new meeting record" href="MeetingCreate.htm">
                        <i class="fa fa-plus"></i> Create Meeting
                    </a>
                </span>
            </li>
        </ul>
    </span>
    <span>
        <h1 class="d-inline page-name" id="mainPageTitle">Meeting Attendee Matrix</h1>
    </span>
</div>

<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>




<div class="container-fluid override">({{browserZone}})
        <div class="row d-flex my-2 border-bottom border-1 border-secondary border-opacity-50">   
            <span class="col-1 h6 text-wrap text-center mt-auto">User</span>
            <span class="col-1 h6" ng-repeat="rec in meetings | limitTo:11 : currentPage * 11">
                <div class="text-center text-wrap">
                    <span ng-show="rec.startTime>0">{{rec.startTime|date: "dd-MMM-yyyy 'at' HH:mm"}}</span>
                    <span ng-show="rec.startTime<=0"><i>( To Be Determined )</i></span>
                </div>
                <div class="text-truncate"><b><a title="Meeting Agenda" href="MeetingHtml.htm?id={{rec.id}}&mode=Items">
                            {{rec.name}}</a></b>
                </div>
            </span>
        </div>
        <div class="row d-flex my-2" ng-repeat="user in foundUsers" title="{{user.name}} - {{user.uid}}">
            <span class="col-1 text-center" >
                <img class="rounded-5 centered" ng-src="<%=ar.retPath%>icon/{{user.key}}.jpg" style="width:32px;height:32px"
                title="{{user.name}} - {{user.uid}}">
            </span>
            <span class="col-1 text-center" ng-repeat="rec in meetings | limitTo:11 : currentPage * 11">
                
                    <span ng-show="attendeeMatrix[user.key][rec.id]" style="color:green;"><i class="fa fa-check"></i></span>
                    <span ng-hide="attendeeMatrix[user.key][rec.id]" style="color:grey">.</span>
                </span>

        </div>
<!-- Pagination Controls -->
<div class="my-3">
    <button class="btn btn-secondary me-2" ng-click="currentPage = currentPage - 1" ng-disabled="currentPage === 0">
        Previous </button>
    <button class="btn btn-primary" ng-click="currentPage = currentPage + 1"
        ng-disabled="(currentPage + 1) * 10 >= meetings.length"> Next </button>
</div>
            

        </div>
        


    <div class="guideVocal" ng-show="meetings.length==0" style="margin-top:80px">
    There are no meetings in this workspace.
    </div>
    
    
</div>
