
app.controller('CommentModalCtrl', function ($scope, $modalInstance, cmt) {

    $scope.cmt = cmt;

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
        if ($scope.cmt.commentType==5) {
            return "Minutes";
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