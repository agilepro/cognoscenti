
app.controller('InviteModalCtrl', function ($scope, $modalInstance, msg) {

    $scope.message = msg;
    $scope.dialogMode = 1;

    $scope.ok = function () {
        $scope.dialogMode = 2;
        SLAP.sendInvitationEmail($scope.message, function(data) {
            $scope.dialogMode = 3;
            $scope.$apply();
        });
    };
    
    $scope.done = function () {
        $scope.dialogMode = 4;
        $modalInstance.close($scope.message);
    };
            

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

   
    
});