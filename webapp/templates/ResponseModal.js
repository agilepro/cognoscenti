app.controller('ModalResponseCtrl', function ($scope, $modalInstance, response, cmt) {

    $scope.response = response;
    $scope.cmt = cmt;

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