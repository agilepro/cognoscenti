app.controller('ModalResponseCtrl', function ($scope, $modalInstance, response, cmt) {

    $scope.response = response;
    $scope.cmt = cmt;

    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 300;

    if (!$scope.response.choice) {
        $scope.response.choice = cmt.choices[0];
    }

    $scope.ok = function () {
        $modalInstance.close($scope.response);
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