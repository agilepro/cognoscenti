console.log("loaded the ModalResponseCtrl-0");

app.controller('ModalResponseCtrl', function ($scope, $modalInstance, response, cmt) {

    console.log("loaded the ModalResponseCtrl");

    $scope.response = response;
    $scope.cmt = cmt;

    console.log("RESPONSE IS: ",response);
    console.log("CMT IS is  is: ",cmt);

    if (!$scope.response.choice) {
        $scope.response.choice = cmt.choices[0];
    }

    $scope.ok = function () {
        $modalInstance.close($scope.response);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

});