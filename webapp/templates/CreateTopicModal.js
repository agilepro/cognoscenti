app.controller('CreateTopicModalCtrl', function ($scope, $modalInstance) {

    $scope.topic = {};
	$scope.topic.subject="";
	$scope.topic.html="";
	
    $scope.cmt = {};
	$scope.cmt.html="";
	$scope.cmt.time = -1;
	$scope.cmt.commentType = 1;
	$scope.cmt.state = 11;
	$scope.cmt.isNew = true;

	$scope.tinymceOptions = {
		handle_event_callback: function (e) {
		// put logic here for keypress 
		},
        inline: false,
        menubar: false,
        body_class: 'leafContent',
        statusbar: false,
        toolbar: "h1, bold, italic, formatselect, cut, copy, paste, bullist, outdent, indent, undo, redo"
	};    
    
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