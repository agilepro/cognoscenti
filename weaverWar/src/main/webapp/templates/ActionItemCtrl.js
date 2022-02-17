app.controller('ActionItemCtrl', function ($scope, $modalInstance, goal, taskAreaList, allLabels, startMode, $http, AllPeople, siteId) {
    $scope.nowTime = new Date().getTime();
    $scope.siteId = siteId;
    $scope.goalId = goal.id;
    $scope.goal = {assignTo:[],state:2,startdate:0,enddate:0,duedate:0,labelMap:{}};
    $scope.taskAreaList = [];
    taskAreaList.forEach( function(item) {
        if (item.name!="Unspecified") {
            $scope.taskAreaList.push(item);
        }
    });
    $scope.allLabels = allLabels;
    $scope.editMode = startMode;

    $scope.ok = function () {
        $scope.saveAndClose();
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

    $scope.datePickOptions = {
        formatYear: 'yyyy',
        startingDay: 1
    };
    $scope.changeRAG = function(goal, newRAG) {
        goal.prospects = newRAG;
    };
    $scope.setState = function(newState) {
        $scope.goal.state=newState;
    }
    
    $scope.hasLabel = function(searchName) {
        if ($scope.goal.labelMap) {
            return $scope.goal.labelMap[searchName];
        }
        return false;
    }
    $scope.toggleLabel = function(label) {
        $scope.goal.labelMap[label.name] = !$scope.goal.labelMap[label.name];
    }
    $scope.updatePlayers = function() {
        $scope.goal.assignTo = cleanUserList($scope.goal.assignTo);
    }
    $scope.getGoal = function(id) {
        var postURL = "fetchGoal.json?gid="+id;
        $scope.showError=false;
        $http.get(postURL)
        .success( function(data) {
            $scope.goalId = data.id;
            if (data.waitUntil<$scope.nowTime) {
                data.waitUntil=$scope.nowTime-100;
            }
            $scope.waitProxy = data.waitUntil;
            $scope.goal = data;
        })
        .error( function(data, status, headers, config) {
            alert("problem handling get: "+JSON.stringify(data));
        });
    };
    if ($scope.goalId != "~new~") {
        $scope.getGoal($scope.goalId);
    }
    $scope.saveAndClose = function() {
        $scope.goal.assignTo = cleanUserList($scope.goal.assignTo);
        $scope.goal.modifiedtime = new Date().getTime();
        $scope.goal.modifieduser = SLAP.loginInfo.userId;
        
        var postURL = "updateGoal.json?gid="+$scope.goalId;
        var postdata = angular.toJson($scope.goal);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.goal = data;
            $modalInstance.close($scope.goal);
        })
        .error( function(data, status, headers, config) {
            alert("problem handling get: "+JSON.stringify(data));
        });
    };
    $scope.loadPersonList = function(query) {
        let xxx = AllPeople.findMatchingPeople(query, $scope.siteId);
        return xxx;
    }
    $scope.setWaitUntil = function() {
        if ($scope.waitProxy<$scope.nowTime) {
            $scope.waitProxy += $scope.nowTime + 7*24*60*60*1000;
        }
        $scope.goal.waitUntil = $scope.waitProxy;
        $scope.goal.state = 4;
    }
    $scope.cancelWaitUntil = function() {
        $scope.goal.waitUntil = $scope.nowTime-100;;
        $scope.goal.state = 3;
    }
});