console.log("loaded the ModalResponseCtrl-0");

app.controller('OutcomeModalCtrl', function ($scope, $modalInstance, cmt) {

    $scope.cmt = cmt;

    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 300;

    $scope.ok = function () {
        $modalInstance.close($scope.cmt);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

    $scope.commentTypeName = function() {
        if ($scope.cmt.commentType==2) {
            return "Proposal";
        }
        if ($scope.cmt.commentType==3) {
            return "Round";
        }
        return "Comment";
    }

});