
app.controller('Responsibility', function ($scope, $modalInstance, $interval, responsibility, isNew, parentScope, $http) {

    // initial comment object
    $scope.resp = responsibility;
    // parent scope with all the crud methods
    $scope.parentScope = parentScope;
    

    $scope.saveAndClose = function () {
        $scope.parentScope.updateResponsibility($scope.resp);
        $modalInstance.dismiss('cancel');
    };

    $scope.deleteAndClose = function () {
        $scope.parentScope.deleteRole($scope.resp);
        $modalInstance.dismiss('cancel');
    };
    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };
    
        
});