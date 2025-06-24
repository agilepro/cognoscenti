<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%
    String pageId    = ar.reqParam("pageId");
    String siteId    = ar.reqParam("siteId");
    NGWorkspace ngw  = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
   

%>

<!-- ************************ wmf/{PickMeetomg/jsp ************************ -->
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    
    $scope.taskFilter = "";
    $scope.allActions = [];
    
    $scope.reportError = function(data) {
        console.log("ERROR: ", data);
    }

    $scope.retrieveActionList = function() {
        var getURL = "allActionsList.json";
        $scope.showError=false;
        $http.get(getURL)
        .success( function(data) {
            $scope.allActions = data.list;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.retrieveActionList();

    $scope.filteredTasks = function() {
        let res = [];
        $scope.allActions.forEach( function(item) {
            if (item.synopsis.indexOf($scope.taskFilter) >= 0 || item.description.indexOf($scope.taskFilter) >= 0) {
                res.push(item);
            }
        } );
        return res;
    }
});

</script>


<div>

    
    <div class="topper">
    <%=ngw.getFullName()%>
    </div>
    
    <div class="instruction ms-3">
    Filter Tasks: <input ng-model="taskFilter"></input>
    </div>
    
    <div ng-repeat="item in filteredTasks()" class="my-3 border border-1 border-dark rounded btn-raised">
      <div class="listItemStyle">
        <a class="fs-6 bold text-wrap text-decoration-none ms-2" href="TaskView.wmf?taskId={{item.id}}">
            <span class="fa fa-check-circle"></span> {{item.synopsis}}
        </a>
      </div>
    </div>
    



