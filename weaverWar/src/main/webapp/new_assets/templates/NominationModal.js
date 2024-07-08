
app.controller('NominationModal', function ($scope, $modalInstance, $interval, nomination, isNew, parentScope, $http) {

    // initial comment object
    $scope.nom = nomination;
    // parent scope with all the crud methods
    $scope.parentScope = parentScope;
    

    $scope.saveAndClose = function () {
        $scope.parentScope.updateNomination($scope.nom);
        $modalInstance.dismiss('cancel');
    };

    $scope.deleteAndClose = function () {
        $scope.parentScope.deleteNomination($scope.nom);
        $modalInstance.dismiss('cancel');
    };
    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };
    
        
});