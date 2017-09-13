app.controller('DecisionModalCtrl', function ($scope, $modalInstance, decision, allLabels) {

    $scope.decision = decision;
    $scope.allLabels = allLabels;

    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 300;
    
    $scope.hasLabel = function(val) {
        return $scope.decision.labelMap[val];
    }
    $scope.toggleLabel = function(val) {
        $scope.decision.labelMap[val.name] = !$scope.decision.labelMap[val.name];
    }

    $scope.ok = function () {
        $modalInstance.close($scope.decision);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

});