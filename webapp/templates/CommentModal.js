
app.controller('CommentModalCtrl', function ($scope, $modalInstance, cmt, parentScope) {

    // initial comment object
    $scope.cmt = cmt;
    // parent scope with all the crud methods
    $scope.parentScope = parentScope;
    // are there unsaved changes?
	$scope.unsaved = false;
	

	// return a readable status message
	$scope.getStatusMassage = function() {
		if ($scope.unsaved) return "Unsaved changes";
        else return "No changes";
	};
	
    $scope.dummyDate1 = new Date();
    if (cmt.dueDate>0) {
        $scope.dummyDate1 = new Date(cmt.dueDate);
    }

    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 300;
	$scope.tinymceOptions.init_instance_callback = function(editor) {
        $scope.initialContent = editor.getContent();
	    editor.on('Change', tinymceChangeTrigger);
        editor.on('KeyUp', tinymceChangeTrigger);
        editor.on('Paste', tinymceChangeTrigger);
        editor.on('Remove', tinymceChangeTrigger);
        editor.on('Format', tinymceChangeTrigger);

    }
    function tinymceInitTrigger(e) {

    }
    function tinymceChangeTrigger(e, editor) {
        if (tinyMCE.activeEditor.getContent() != $scope.initialContent)
            $scope.unsaved = true;
        else $scope.unsaved = false;
    }

    $scope.ok = function () {
        if ($scope.cmt.state == 11) $scope.cmt.state = 12;
        $scope.cmt.dueDate = $scope.dummyDate1.getTime();
        if ($scope.cmt.state==12) {
            if ($scope.cmt.commentType==1 || $scope.cmt.commentType==5) {
                $scope.cmt.state=13;
            }
        }
        $scope.unsaved = false;
        $modalInstance.close($scope.cmt);
    };

    $scope.saveDraft = function() {
        $scope.cmt.dueDate = $scope.dummyDate1.getTime();
        $scope.parentScope.updateComment($scope.cmt);
        $scope.unsaved = false;
        $scope.cmt.isNew = false;
    }

    $scope.cancel = function () {
        var r = true;
        if ($scope.unsaved) r = confirm('There are unsaved changes. Do you really want to cancel?');
        if (r) $modalInstance.dismiss('cancel');
    };

    $scope.commentTypeName = function() {
        if ($scope.cmt.commentType==2) {
            return "Proposal";
        }
        if ($scope.cmt.commentType==3) {
            return "Round";
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
        return "Update";
    }
    
    $scope.datePickOptions = {
        formatYear: 'yyyy',
        startingDay: 1
    };
    $scope.datePickOpen1 = false;
    $scope.openDatePicker1 = function($event) {
        $event.preventDefault();
        $event.stopPropagation();
        $scope.datePickOpen1 = true;
    };
    $scope.datePickDisable = function(date, mode) {
        return false;
    };

});