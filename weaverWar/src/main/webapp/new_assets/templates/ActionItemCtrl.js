app.controller('ActionItemCtrl', function ($scope, $modalInstance, goal, taskAreaList, allLabels, startMode, $http, AllPeople, siteInfo, $modal) {
    $scope.nowTime = new Date().getTime();
    $scope.siteInfo = siteInfo;
    $scope.siteId = siteInfo.key;
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
    function reportError(errData) {
        $scope.error = JSON.stringify(errData);
        $scope.editMode = "error";
    }

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
            reportError(data);
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
            reportError(data);
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
    $scope.getAllLabels = function() {
        var postURL = "getLabels.json";
        $scope.showError=false;
        $http.post(postURL, "{}")
        .success( function(data) {
            console.log("All labels are gotten: ", data);
            $scope.allLabels = data.list;
            $scope.sortAllLabels();
        })
        .error( function(data, status, headers, config) {
            reportError(data);
        });
    };
    $scope.sortAllLabels = function() {
        $scope.allLabels.sort( function(a, b){
              if (a.name.toLowerCase() < b.name.toLowerCase())
                return -1;
              if (a.name.toLowerCase() > b.name.toLowerCase())
                return 1;
              return 0;
        });
    };
    $scope.getAllLabels();
    $scope.openEditLabelsModal = function (item) {
        
        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '../../../templates/EditLabels.html',
            controller: 'EditLabelsCtrl',
            size: 'lg',
            resolve: {
                siteInfo: function () {
                  return $scope.siteInfo;
                },
            }
        });

        attachModalInstance.result
        .then(function (selectedActionItems) {
            $scope.getAllLabels();
        }, function () {
            $scope.getAllLabels();
        });
    };
    
});