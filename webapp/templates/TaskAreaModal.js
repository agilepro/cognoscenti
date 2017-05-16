console.log("loaded the TaskAreaCtrl");

app.controller('TaskAreaCtrl', function ($scope, $modalInstance, $http, id) {

    console.log("loaded the TaskArea Model");

    $scope.taskArea = {"name":"", "id": id};
    
    $scope.geTaskArea = function() {
        console.log("getting share port "+id)
        var getURL = "taskArea"+$scope.taskArea.id+".json";
        $http.get(getURL)
        .success( function(data) {
            console.log("received TaskArea", data);
            if (!data.labels) {
                data.labels = [];
            }
            $scope.taskArea = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    if ("~new~" != id) {
        $scope.geTaskArea();
    }
    else {
        console.log("Creating new one!  "+$scope.taskArea.id);
    }
    $scope.saveTaskArea = function() {
        console.log("saving TaskArea "+id, $scope.taskArea);
        var postURL = "taskArea"+$scope.taskArea.id+".json";
        var postBody = JSON.stringify($scope.taskArea);
        $http.post(postURL, postBody)
        .success( function(data) {
            console.log("received share port", data);
            $scope.taskArea = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }

    $scope.changeProspect = function(newPros) {
        $scope.taskArea.prospects = newPros;
    };
    
    
    $scope.ok = function () {
        $scope.saveTaskArea();
        $modalInstance.close();
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };


});