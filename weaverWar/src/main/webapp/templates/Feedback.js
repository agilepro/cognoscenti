console.log("loaded the FEEDER BACK");

app.controller('FeedbackCtrl', function ($scope, $modalInstance, $http) {

    $scope.message = "";
    $scope.userId = SLAP.loginInfo.userId;
    $scope.uri = window.location.href;
    $scope.nowTime = (new Date()).getTime();
    console.log("User is: ", SLAP.loginInfo);

    $scope.ok = function () {
        $scope.submitComment();
        $modalInstance.close();
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

    $scope.submitComment = function() {
        var errUp = {};
        errUp.errNo = -1;
        errUp.logDate = $scope.nowTime;
        errUp.modTime = $scope.nowTime;
        errUp.message  = "Feedback Suggestion";
        errUp.comment = $scope.message;
        errUp.uri = $scope.uri;
        var postdata = angular.toJson(errUp);
        console.log("sending this: ", errUp);
        $http.post("../../../t/su/submitComment", postdata)
        .success( function(data) {
            console.log("got a response: ", data);
            alert("Thanks, your feedback suggestion has been recorded.");
        })
        .error( function(data) {
           console.log("got error: ", data);
        });        
    }
    
});