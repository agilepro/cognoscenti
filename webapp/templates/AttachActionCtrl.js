app.controller('AttachActionCtrl', function($scope, $modalInstance, $http, selectedActions, allActions, allPeople) {

    $scope.allActions = allActions;
    if(selectedActions) {
        $scope.selectedActions = selectedActions;
    }
    else {
        $scope.selectedActions = [];
    }
    $scope.newGoal = {};
    $scope.realFilter = "";
    $scope.createMode = false;
    $scope.allPeople = allPeople;
    $scope.dummyDate1 = new Date();
    
    

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
    
    $scope.getPeople = function(viewValue) {
        var viewValLC = viewValue.toLowerCase();
        var newVal = [];
        for( var i=0; i<$scope.allPeople.length; i++) {
            var onePeople = $scope.allPeople[i];
            if (onePeople.uid.toLowerCase().indexOf(viewValLC)>=0) {
                newVal.push(onePeople);
            }
            else if (onePeople.name.toLowerCase().indexOf(viewValLC)>=0) {
                newVal.push(onePeople);
            }
        }
        return newVal;
    }
    
    $scope.datePickOptions = {
        formatYear: 'yyyy',
        startingDay: 1
    };
    $scope.datePickOpen1 = false;
    $scope.openDatePicker1 = function($event) {
        $event.preventDefault();
        $event.stopPropagation();
        $scope.datePickOpen1 = true;
    };
    $scope.datePickDisable = function(date, mode) {
        return false;
    };
    
    $scope.createActionItem = function(item) {
        var postURL = "createActionItem.json";
        var newSynop = $scope.newGoal.synopsis;
        if (newSynop == null || newSynop.length==0) {
            alert("must enter a description of the action item");
            return;
        }
        $scope.newGoal.state=2;
        $scope.newGoal.assignTo = [];
        var player = $scope.newGoal.assignee;
        if (typeof player == "string") {
            var pos = player.lastIndexOf(" ");
            var name = player.substring(0,pos).trim();
            var uid = player.substring(pos).trim();
            player = {name: name, uid: uid};
        }

        $scope.newGoal.assignTo.push(player);
        $scope.newGoal.duedate = $scope.dummyDate1.getTime();

        var postdata = angular.toJson($scope.newGoal);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.allActions.push(data);
            $scope.selectedActions.push(data.universalid);
            $scope.newGoal = {};
            $scope.createMode = false;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.ok = function () {
        $modalInstance.close($scope.selectedActions);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

});