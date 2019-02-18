
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
        var updateRec = {};
        updateRec.to = userInfo.uid;
        updateRec.subject = $scope.subject;
        updateRec.message = $scope.message;
        var postdata = angular.toJson(updateRec);
        var postURL = "sendEmail";
        $http.post(postURL ,postdata)
        .success( function(data) {
            $modalInstance.dismiss('cancel');
        })
        .error( function(data) {
            console.log("ERROR:", data);
        });
    }
});