app.controller('CreateTopicModalCtrl', function ($scope, $modalInstance) {

    $scope.topic = {};
	$scope.topic.subject="";
	$scope.topic.html="";
	$scope.topic.phase="Freeform";
	
    $scope.tinymceOptions1 = standardTinyMCEOptions();
    $scope.tinymceOptions1.height = 150;
    
    $scope.ok = function (state) {
        $modalInstance.close($scope.topic);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

});