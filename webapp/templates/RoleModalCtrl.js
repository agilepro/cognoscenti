
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
    $scope.getCurrentTerm = function() {
        $scope.currentTerm = null;
        if (!$scope.roleInfo.currentTerm) {
            return null;
        }
        if (!$scope.roleInfo.terms) {
            return null;
        }
        var curTerm = null;
        $scope.roleInfo.terms.forEach( function(item) {
            console.log("Considering", $scope.roleInfo.currentTerm, item);
            if (item.key == $scope.roleInfo.currentTerm) {
                $scope.currentTerm = item;
            }
        });
    }
    $scope.getCurrentTerm();


    $scope.updatePlayers = function() {
        var role = {};
        role.name = $scope.roleInfo.name;
        role.color = $scope.roleInfo.color;
        role.players = $scope.roleInfo.players;
        console.log("UPDATING ROLE: ",role);
        $scope.parentScope.updateRole(role);
        $scope.getCurrentTerm();
    }
    
    $scope.createAndClose = function () {
        $scope.parentScope.saveCreatedRole($scope.roleInfo);
        $modalInstance.dismiss('cancel');
    };
    $scope.saveAndClose = function () {
        $scope.parentScope.updateRole($scope.roleInfo);
        $modalInstance.dismiss('cancel');
    };
    $scope.defineRole = function () {
        $scope.parentScope.saveCreatedRole($scope.roleInfo);
        window.location = "roleDefine.htm?role="+$scope.roleInfo.name;
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
            $scope.getCurrentTerm();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    if (!isNew) {
        $scope.refreshRole();
    }
    
        
});