app.controller('EditLabelsCtrl', function($scope, $modalInstance, $http, siteInfo) {

    $scope.allLabels = [];
    $scope.selectedTab="Existing";
    $scope.siteInfo = siteInfo;
    $scope.newLabel = {name: "~new~"};
    
    $scope.colors = [];
    var testColor = {};
    $scope.siteInfo.labelColors.forEach( function(color) {
        if (!testColor[color]) {
            $scope.colors.push(color);
            testColor[color] = true;
        }
    });
    $scope.reportError = function(serverErr) {
        var exception = serverErr.exception;
        $scope.errorMsg = exception.join();
        $scope.errorTrace = exception.stack;
        $scope.showError=true;
        $scope.showTrace = false;
    };

    $scope.getAllLabels = function() {
        var postURL = "getLabels.json";
        $scope.showError=false;
        $http.post(postURL, "{}")
        .success( function(data) {
            console.log("All labels are gotten: ", data);
            $scope.allLabels = data.list;
            $scope.sortAllLabels();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    
    $scope.updateLabel = function(label) {
        var key = label.name;
        var postURL = "labelUpdate.json?op=Create";
        var postdata = angular.toJson(label);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            console.log("Updated Label: ", data);
            $scope.getAllLabels();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.deleteLabel = function(label) {
        var specialName = label.name;
        var postURL = "labelUpdate.json?op=Delete";
        var postdata = angular.toJson(label);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            console.log("Deleted Label: ", data);
            $scope.getAllLabels();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.createRandomLabel = function() {
        var newLabel = {name: "~new~", editedName: "", color: $scope.colors[0], isEdit:true};
        $scope.allLabels.push(newLabel);
    }
    $scope.sortAllLabels = function() {
        $scope.allLabels.sort( function(a, b){
              if (a.name.toLowerCase() < b.name.toLowerCase())
                return -1;
              if (a.name.toLowerCase() > b.name.toLowerCase())
                return 1;
              return 0;
        });
    };
    
    $scope.createLabel = function() {
        $scope.newLabel.name = "~new~";
        $scope.updateLabel($scope.newLabel);
        $scope.newLabel.editedName = "";
        $scope.selectedTab="Existing";
    }


    $scope.ok = function () {
        $scope.saveActions(true);
    };

    $scope.exitPopup = function() {
        $modalInstance.dismiss('cancel');
    };
    $scope.getAllLabels();

});