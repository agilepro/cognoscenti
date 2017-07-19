app.controller('AgendaCtrl', function ($scope, $modalInstance, agendaItem, AllPeople, $http) {

    $scope.agendaItem = agendaItem;
    $scope.descriptMode=false;
    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 300;
    
    console.log("AgendaItem is: ", agendaItem);

    $scope.ok = function () {
        console.log("OK PRESSED", $scope.goal);
        $modalInstance.close($scope.agendaItem);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };
    $scope.getPeople = function(query) {
        return AllPeople.findMatchingPeople(query);
    }
    
});