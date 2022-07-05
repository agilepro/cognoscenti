
app.controller('EmailModalCtrl', function ($scope, $modalInstance, $modal, $interval, userInfo, $http) {

    $scope.userInfo = userInfo;
    $scope.selectedTab = 'Email';
    $scope.message = "";
    $scope.subject = "";
    $scope.tinymceOptions = standardTinyMCEOptions();

    
    $scope.cancel = function() {
        $modalInstance.dismiss('cancel');
    }
    $scope.sendEmail = function() {
        if (!$scope.subject) {
            alert("please enter a subject for the email");
            return;
        }
        if (!$scope.message) {
            alert("please enter a message for the body of the email");
            return;
        }
        var updateRec = {};
        updateRec.subject = $scope.subject;
        updateRec.message = $scope.message;
        var postdata = angular.toJson(updateRec);
        var postURL = "sendEmail";
        console.log("EMAIL SEND:", updateRec);
        $http.post(postURL ,postdata)
        .success( function(data) {
            $modalInstance.dismiss('cancel');
        })
        .error( function(data) {
            console.log("ERROR:", data);
        });
    }
});