
app.controller('TermModal', function ($scope, $modalInstance, $interval, term, isNew, parentScope, AllPeople, $http) {

    // initial comment object
    $scope.term = term;
    
    $scope.isCurrent = (parentScope.role.currentTerm == term.key);
    
    // parent scope with all the crud methods
    $scope.parentScope = parentScope;
    
    $scope.getDays = function(term) {
        if (term.termStart<100000) {
            return 0;
        }
        if (term.termEnd<100000) {
            return 0;
        }
        var diff = Math.floor((term.termEnd - term.termStart)/(1000*60*60*24));
        return diff;
    }

    $scope.saveAndClose = function () {
        if ($scope.isCurrent) {
            $scope.parentScope.selectCurrentTerm($scope.term);
        }
        $scope.parentScope.updateTerm($scope.term);
        $modalInstance.dismiss('cancel');
    };

    $scope.deleteAndClose = function () {
        $scope.parentScope.deleteTerm($scope.term);
        $modalInstance.dismiss('cancel');
    };
    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };
    
        
});