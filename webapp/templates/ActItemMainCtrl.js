app.controller('ActItemMainCtrl', function ($scope, $modalInstance, goal, allLabels) {

    $scope.goal = goal;
    $scope.allLabels = allLabels;
    console.log("goal state is: ", goal.state);

    $scope.ok = function () {
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