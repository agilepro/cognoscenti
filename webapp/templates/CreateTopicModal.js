app.controller('CreateTopicModalCtrl', function ($scope, $modalInstance) {

    $scope.topic = {};
	$scope.topic.subject="";
	$scope.topic.html="";
	$scope.topic.phase="Freeform";
	
    $scope.cmt = {};
	$scope.cmt.html="";
	$scope.cmt.time = -1;
	$scope.cmt.commentType = 1;
	$scope.cmt.state = 11;
	$scope.cmt.isNew = true;

    $scope.tinymceOptions1 = standardTinyMCEOptions();
    $scope.tinymceOptions1.height = 150;
    $scope.tinymceOptions2 = standardTinyMCEOptions();
    $scope.tinymceOptions2.height = 250;
    
    $scope.ok = function (state) {
        $scope.cmt.state = state;
		$scope.topic.comments=[];
		$scope.topic.comments.push($scope.cmt);
        $modalInstance.close($scope.topic);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

});