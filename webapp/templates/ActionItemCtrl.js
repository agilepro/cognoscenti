app.controller('ActionItemCtrl', function ($scope, $modalInstance, goal, taskAreaList, allLabels, startMode, $http, AllPeople) {

    $scope.goalId = goal.id;
    $scope.goal = {assignTo:[],state:2,startdate:0,enddate:0,duedate:0};
    $scope.taskAreaList = taskAreaList;
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
    
    $scope.onTimeSet = function (newDate, param) {
        $scope.goal[param] = newDate.getTime();
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
    
    $scope.getGoal = function(id) {
        var postURL = "fetchGoal.json?gid="+id;
        $scope.showError=false;
        $http.get(postURL)
        .success( function(data) {
            $scope.goal = data;
            $scope.goalId = data.id;
        })
        .error( function(data, status, headers, config) {
            alert("problem handling get: "+JSON.stringify(data));
        });
    };
    if ($scope.goalId != "~new~") {
        $scope.getGoal($scope.goalId);
    }
    $scope.cleanUpAssignees = function() {
        var newList = [];
        $scope.goal.assignTo.forEach( function(item) {
            var nix = {};
            if (item.uid) {
                nix.name = item.name; 
                nix.uid  = item.uid; 
                nix.key  = item.key;
            }
            else {
                nix.name = item.name; 
                nix.uid  = item.name;
            }    
            newList.push(nix);
        });
        $scope.goal.assignTo = newList;
    };
    $scope.saveAndClose = function() {
        $scope.cleanUpAssignees();
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
        return AllPeople.findMatchingPeople(query);
    }
    
});