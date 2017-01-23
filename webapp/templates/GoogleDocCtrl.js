app.controller('GoogleDocCtrl', function($scope, $http, $modalInstance, gfile, attachmentList, allLabels) {
    $scope.attachmentList = attachmentList;
    $scope.allLabels = allLabels;
    $scope.gfile = gfile;
    $scope.docInfo = {
        "name": gfile.title,
        "public":false, 
        labelMap:{},
        id: "~new~",
        url: gfile.embedLink,
        attType:"URL"
    };


    $scope.ok = function () {
        $scope.createLink();
        $modalInstance.close($scope.docList);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

    $scope.hasLabel = function(searchName) {
        return $scope.docInfo.labelMap[searchName];
    }
    $scope.toggleLabel = function(label) {
        $scope.docInfo.labelMap[label.name] = !$scope.docInfo.labelMap[label.name];
    }
    
    $scope.createLink = function() {
        var postURL = "docsUpdate.json?did="+$scope.docInfo.id;
        var postdata = angular.toJson($scope.docInfo);
        console.log("creating link to: ", $scope.docInfo);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.docInfo = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

});