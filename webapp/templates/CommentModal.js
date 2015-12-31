console.log("loaded the ModalResponseCtrl-0");

app.controller('CommentModalCtrl', function ($scope, $modalInstance, cmt) {

    console.log("loaded the ModalResponseCtrl");

    $scope.cmt = cmt;

    console.log("CMT IS is  is: ",cmt);

    $scope.ok = function (state) {
        $scope.cmt.state = state;
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
            return "Question";
        }
        return "Comment";
    }

    $scope.getVerb = function() {
        if ($scope.cmt.isNew) {
            return "Create";
        }
        return "Save";
    }

});