console.log("loaded the ModalInstanceCtrl-0");

app.controller('DecisionModalCtrl', function ($scope, $modalInstance, decision, allLabels) {

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

});