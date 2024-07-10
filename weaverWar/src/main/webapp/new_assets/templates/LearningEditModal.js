
app.controller('LearningEditCtrl', function ($scope, $modalInstance, $modal, $interval, wrappedJSP, $http) {


    // initial comment object
    $scope.wrappedJSP = wrappedJSP;
    $scope.selectedTab='Update';
    
    // are there unsaved changes?
	$scope.unsaved = 0;
	// controls if comment can be saved
	$scope.saveDisabled = false;
    $scope.promiseAutosave = null;
    
    $scope.simDescript = new SimText("");
    
    getLearning();

    $scope.scratchHtml = "";
    $scope.scratchWiki = "";
    $scope.oldScratchWiki = "";

    function getLearning() {
        var getURL = "getLearning.json?jsp="+wrappedJSP;
        console.log("calling: ",getURL);
        $http.get(getURL)
        .success( setLearning )
        .error( handleHTTPError );
    }
    function setLearning(data) {
        var newLearningList = data.list;
        $scope.learning = {description: "Page for "+wrappedJSP,  mode:"standard"};
        // this is a list, and we need to select the 'standard' one
        newLearningList.forEach( function(item) {
            if (item.mode=="standard") {
                $scope.learning = item;
            }
        });
        $scope.simDescript = new SimText($scope.learning.description);
    }
    function handleHTTPError(data, status, headers, config) {
        console.log("ERROR in ResponseModel Dialog: ", data);
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

    $scope.saveAndClose = function() {
        saveLearning('Y');
    }
    
    function saveLearning(closeIt) {
		var newLearning = {};
        newLearning.description = $scope.simDescript.getLocal();
        newLearning.mode = $scope.learning.mode;
        newLearning.video = $scope.learning.video;
        
        var postdata = angular.toJson(newLearning);
        var postURL = "setLearning.json?jsp="+wrappedJSP;
        console.log(postURL,newLearning);
        $http.post(postURL, postdata)
        .success( function(data) {
            if ("Y"==closeIt) {
                $modalInstance.dismiss('cancel');
            }
            else {
                setComment(data);
            }
        })
        .error( handleHTTPError );
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

    //this fires every keystroke to maintain change flag
    function tinymceChangeTrigger(e, editor) {
        
    }

    
    $scope.loadPersonList = function(query) {
        return AllPeople.findMatchingPeople(query, $scope.siteId);
    }
    
});