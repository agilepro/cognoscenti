app.controller('DecisionModalCtrl', function ($scope, $modalInstance, decision, allLabels) {

    $scope.decision = decision;
    
    $scope.allLabels = allLabels;
    $scope.editMode='decision';

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
    
    $scope.advanceReviewDate = function() {
        if ($scope.decision.reviewDate>$scope.decision.timestamp) {
            $scope.decision.reviewDate = $scope.decision.reviewDate + 365*24*3600000;
        }
        else {
            $scope.decision.reviewDate = $scope.decision.timestamp + 365*24*3600000;
        }
    }

});