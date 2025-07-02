<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%
    String pageId    = ar.reqParam("pageId");
    String siteId    = ar.reqParam("siteId");
    String taskId    = ar.reqParam("taskId");
    NGWorkspace ngw  = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
   

%>

<!-- ************************ wmf/{PickMeetomg/jsp ************************ -->
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    
    $scope.workspaceName = "<% ar.writeJS(ngw.getFullName()); %>";
    $scope.taskId = "<% ar.writeJS(taskId); %>";
    $scope.task = {};

    
    $scope.reportError = function(data) {
        console.log("ERROR: ", data);
    }

    $scope.getTaskInfo = function() {
        var postURL = "fetchGoal.json?gid="+$scope.taskId;
        $http.get(postURL)
        .success( function(data) {
            $scope.task = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.getTaskInfo();
    
});

</script>


<div>

    
    <div class="topper">
    {{workspaceName}}
    </div>
    
    <div class="instruction">
    Synopsis:
    </div>
    <div ng-bind-html="task.synopsis | wiki" class="richTextBox"></div> 
    <div class="instruction">
    Description:
    </div>
    <div ng-bind-html="task.description | wiki" class="richTextBox"></div> 
    <div class="instruction">
    State:
    </div>
    <div ng-show="task.state<=0 || task.state>9" style="background-color:magenta">Error {{task.state}}</div> 
    <div ng-show="task.state==1" style="background-color:tan">Unstarted</div> 
    <div ng-show="task.state==2" style="background-color:lightskyblue">Offered</div> 
    <div ng-show="task.state==3" style="background-color:springgreen">Accepted</div> 
    <div ng-show="task.state==4" style="background-color:yellow">Waiting</div> 
    <div ng-show="task.state==5" style="background-color:red">Complete</div> 
    <div ng-show="task.state==6" style="background-color:plum">Skipped</div> 
    <div ng-show="task.state==7" style="background-color:magenta">Error 7</div> 
    <div ng-show="task.state==8" style="background-color:lightblue">Frozen</div> 
    <div ng-show="task.state==9" style="background-color:gray">Deleted</div> 
    
    <div class="instruction">
    Status:
    </div>
    <div ng-bind-html="task.status | wiki" class="richTextBox"></div> 
    <div class="instruction">
    Assignees:
    </div>
    <div ng-repeat="person in task.assignTo">
    <i class="fa fa-user"></i> {{person.name}}
    </div> 
    <div ng-show="task.duedate>0">
        <span class="instruction">Due Date:</span>{{task.duedate | cdate}}
    </div>
    <div ng-show="task.startdate>0">
        <span class="instruction">Start Date:</span>{{task.startdate | cdate}}
    </div>
    <div ng-show="task.enddate>0">
        <span class="instruction">End Date:</span>{{task.enddate | cdate}}
    </div>
    


    




