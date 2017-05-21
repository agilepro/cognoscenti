console.log("loaded the SharePortCtrl");

app.controller('SharePortCtrl', function ($scope, $modalInstance, $http, id, allLabels) {

    console.log("loaded the Share Port Model");

    $scope.sharePort = {"name":"Shared Documents", "id": id, labels: [], days:365, isActive:true };
    $scope.allLabels = allLabels;
    
    $scope.getSharePort = function() {
        console.log("getting share port "+id)
        var getURL = "share/"+$scope.sharePort.id+".json";
        $http.get(getURL)
        .success( function(data) {
            console.log("received share port", data);
            if (!data.labels) {
                data.labels = [];
            }
            $scope.sharePort = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    if ("~new~" != id) {
        $scope.getSharePort();
    }
    else {
        console.log("Creating new one!  "+$scope.sharePort.id);
    }
    $scope.saveSharePort = function() {
        console.log("saving share port "+id, $scope.sharePort);
        var postURL = "share/"+$scope.sharePort.id+".json";
        var postBody = JSON.stringify($scope.sharePort);
        $http.post(postURL, postBody)
        .success( function(data) {
            console.log("received share port", data);
            $scope.sharePort = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.addLabel = function(role) {
        $scope.sharePort.labels.push(role.name);
    }
    $scope.removeLabel = function(role) {
        var newVal = [];
        $scope.sharePort.labels.forEach( function(item) {
            if (item != role.name) {
                newVal.push(item);
            }
        });
        $scope.sharePort.labels = newVal;
    }
    $scope.hasLabel = function(role) {
        var hasIt = false;
        $scope.sharePort.labels.forEach( function(item) {
            if (item == role.name) {
                hasIt = true;
            }
        });
        return hasIt;
    }

    $scope.ok = function () {
        $scope.saveSharePort();
        $modalInstance.close();
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };


});