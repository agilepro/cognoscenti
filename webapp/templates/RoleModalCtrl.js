
app.controller('RoleModalCtrl', function ($scope, $modalInstance, $interval, roleInfo, isNew, parentScope, AllPeople, $http) {

    // initial comment object
    $scope.roleInfo = roleInfo;
    // parent scope with all the crud methods
    $scope.parentScope = parentScope;
    
    $scope.isNew=isNew;

    $scope.colors = ["salmon","khaki","beige","lightgreen","orange","bisque","tomato","aqua","orchid",
                     "peachpuff","powderblue","lightskyblue"];
    
    $scope.loadPersonList = function(query) {
        return AllPeople.findMatchingPeople(query);
    }
    $scope.saveAndClose = function () {
        $scope.parentScope.updateRole($scope.roleInfo);
        $modalInstance.dismiss('cancel');
    };
    $scope.createAndClose = function () {
        $scope.parentScope.saveCreatedRole($scope.roleInfo);
        $modalInstance.dismiss('cancel');
    };
    $scope.deleteAndClose = function () {
        $scope.parentScope.deleteRole($scope.roleInfo);
        $modalInstance.dismiss('cancel');
    };
    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

    $scope.refreshRole = function() {
        var postURL = "roleUpdate.json?op=Update";
        var postdata = angular.toJson({name:roleInfo.name});
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.parentScope.cleanDuplicates(data);
            $scope.roleInfo = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    if (!isNew) {
        $scope.refreshRole();
    }
        
});