console.log("loaded the ModalInstanceCtrl-0");

app.controller('DecisionModalCtrl', function ($scope, $modalInstance, decision, allLabels) {

    console.log("loaded the DecisionModalCtrl");

    $scope.decision = decision;
    $scope.allLabels = allLabels;
    $scope.dummyDate = "";

    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 300;
    
    $scope.hasLabel = function(val) {
        return $scope.decision.labelMap[val];
    }
    $scope.toggleLabel = function(val) {
        console.log("toggling label for: "+val.name);
        $scope.decision.labelMap[val.name] = !$scope.decision.labelMap[val.name];
    }

    $scope.ok = function () {
        $scope.decision.timestamp = $scope.dummyDate.getTime();
        $modalInstance.close($scope.decision);
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
        if ($scope.decision.timestamp<=0) {
            $scope.dummyDate = new Date();
        }
        else {
            $scope.dummyDate = new Date($scope.decision.timestamp);
        }
    };
    $scope.extractDateParts();
});