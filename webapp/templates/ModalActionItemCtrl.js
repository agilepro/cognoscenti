app.controller('ModalActionItemCtrl', function ($scope, $modalInstance, item, goal) {

    $scope.item = item;
    $scope.goal = goal;
    $scope.goalDueDate = goal;

    $scope.ok = function () {
        $scope.goal.duedate = $scope.goalDueDate.getTime();
        $modalInstance.close($scope.goal);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

    $scope.datePickOptions = {
        formatYear: 'yyyy',
        startingDay: 1
    };
    $scope.datePickDisable = function(date, mode) {
        return false;
    };
    $scope.dummyDate1 = new Date();
    $scope.datePickOpen = false;
    $scope.openDatePicker = function($event) {
        $event.preventDefault();
        $event.stopPropagation();
        $scope.datePickOpen = true;
    };
    $scope.extractDateParts = function() {
        if ($scope.goal.duedate<=0) {
            $scope.goalDueDate = new Date();
        }
        else {
            $scope.goalDueDate = new Date($scope.goal.duedate);
        }
    };
    $scope.extractDateParts();
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
});