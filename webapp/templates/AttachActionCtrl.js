app.controller('AttachActionCtrl', function($scope, $modalInstance, selectedActions, allActions) {

    $scope.allActions = allActions;
    if(selectedActions) {
        $scope.selectedActions = selectedActions;
    }
    else {
        $scope.selectedActions = [];
    }
    $scope.realFilter = "";

    $scope.filterActions = function() {
        var filterlc = $scope.realFilter.toLowerCase();
        var rez =  $scope.allActions.filter( function(oneAct) {
            return (filterlc.length==0
                || oneAct.synopsis.toLowerCase().indexOf(filterlc)>=0
                || oneAct.description.toLowerCase().indexOf(filterlc)>=0);
        });
        rez = rez.sort( function(a,b) {
            return a.rank - b.rank;
        });
        return rez;
    }
    $scope.itemHasAction = function(oneAct) {
        var res = false;
        var found = $scope.selectedActions.forEach( function(actionId) {
            if (actionId == oneAct.universalid) {
                res = true;
            }
        });
        return res;
    }
    $scope.itemActions = function() {
        return $scope.allActions.filter( function(oneAct) {
            return $scope.itemHasAction(oneAct);
        });
    }
    $scope.addActionToList = function(oneAct) {
        if (!$scope.itemHasAction(oneAct)) {
            $scope.selectedActions.push(oneAct.universalid);
        }
    }
    $scope.removeActionFromList = function(oneAct) {
        $scope.selectedActions = $scope.selectedActions.filter( function(actionId) {
            return (actionId != oneAct.universalid);
        });
    }

    $scope.ok = function () {
        $modalInstance.close($scope.selectedActions);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

});