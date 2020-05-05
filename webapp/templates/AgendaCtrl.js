app.controller('AgendaCtrl', function ($scope, $modalInstance, agendaItem, AllPeople, $http, siteId, displayMode) {

    $scope.siteId = siteId;
    $scope.agendaItem = agendaItem;
    $scope.descriptMode=false;
    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 250;
    
    $scope.agendaItem.previousElapsed = Math.floor($scope.agendaItem.timerElapsed / 60) / 1000;
    
    console.log("AgendaItem is: ", agendaItem);

    $scope.ok = function () {
        if ($scope.agendaItem.isSpacer) {
            //spacers (breaks) can not be proposed
            agendaItem.proposed = false;
        }
        if (!$scope.agendaItem.timerRunning) {
            $scope.agendaItem.timerElapsed = $scope.agendaItem.previousElapsed * 60000;
        }
        else {
            $scope.agendaItem.timerElapsed = $scope.agendaItem.timerElapsed 
                       + (new Date().getTime() - $scope.agendaItem.timerStart);
            $scope.agendaItem.timerStart = new Date().getTime();
        }
        $modalInstance.close($scope.agendaItem);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };
    $scope.getPeople = function(query) {
        return AllPeople.findMatchingPeople(query, $scope.siteId);
    }
    $scope.selectedTab = displayMode;
    $scope.tabStyle = function(which) {
        var sss = {
            "border":"2px solid #F0D7F7",
            "border-bottom":"2px solid gray",
            "margin":"0px",
            "padding":"8px 15px",
            "font-size":"16px",
            "font-weight":"bold"
        };
        if ( ($scope.selectedTab==which) ) {
            sss.border="2px solid gray";
            sss["border-bottom"]="2px solid white";
            sss["background-color"] = "white";
        };
        return sss;
    };
    
});