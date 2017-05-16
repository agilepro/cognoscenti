app.controller('ActItemMainCtrl', function ($scope, $modalInstance, goal, allLabels, $http) {

    $scope.goal = goal;
    $scope.allLabels = allLabels;
    $scope.foofighters = ["fee","fie","foh", "fum"];
    console.log("goal state is: ", goal.state);
    $scope.getTaskAreas = function() {
        console.log("getting TaskAreas", $scope.goal)
        var getURL = "taskAreas.json";
        $http.get(getURL)
        .success( function(data) {
            console.log("received TaskAreas", data);
            $scope.allTaskAreas = data.taskAreas;
            $scope.loaded = true;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }   
    $scope.getTaskAreas();

    $scope.ok = function () {
        console.log("OK PRESSED", $scope.goal);
        $modalInstance.close($scope.goal);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

    $scope.goalStateStyle = function(goal) {
        if (goal.prospects=="good") {
            return "background-color:lightgreen";
        }
        if (goal.prospects=="ok") {
            return "background-color:yellow";
        }
        if (goal.prospects=="bad") {
            return "background-color:red";
        }
        return "background-color:lavender";
    }
    $scope.goalStateName = function(goal) {
        if (goal.prospects=="good") {
            return "Good";
        }
        if (goal.prospects=="ok") {
            return "Warnings";
        }
        return "Trouble";
    };
    $scope.changeGoalState = function(goal, newState) {
        goal.prospects = newState;
        $scope.saveGoal(goal);
    };
    $scope.onTimeSet = function (newDate, param) {
        $scope.goal[param] = newDate.getTime();
    }
    $scope.hasLabel = function(searchName) {
        return $scope.goal.labelMap[searchName];
    }
    $scope.toggleLabel = function(label) {
        $scope.goal.labelMap[label.name] = !$scope.goal.labelMap[label.name];
    }
    
});