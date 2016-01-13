console.log("loaded the ModalResponseCtrl-0");

app.controller('InviteModalCtrl', function ($scope, $modalInstance, email, msg) {

    $scope.email = email;
    $scope.message = msg;

    $scope.ok = function () {
        var identityServerMsg = {};
        identityServerMsg.msg = $scope.message;
        $modalInstance.close(identityServerMsg);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

});