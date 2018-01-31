console.log("loaded the ModalResponseCtrl-0");

app.controller('InviteModalCtrl', function ($scope, $modalInstance, msg) {

    $scope.message = msg;
    $scope.editingMsg = true;

    $scope.ok = function () {
        $scope.editingMsg = false;
        SLAP.sendInvitationEmail($scope.message, function(data) {
            $modalInstance.close($scope.message);
        });
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

   
    
});