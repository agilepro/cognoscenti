app.controller('AgendaCtrl', function ($scope, $modalInstance, agendaItem, AllPeople, $http) {

    $scope.agendaItem = agendaItem;
    $scope.descriptMode=false;
    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 250;
    
    console.log("AgendaItem is: ", agendaItem);

    $scope.ok = function () {
        if ($scope.agendaItem.isSpacer) {
            //spacers (breaks) can not be proposed
            agendaItem.proposed = false;
        }
        $modalInstance.close($scope.agendaItem);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };
    $scope.getPeople = function(query) {
        return AllPeople.findMatchingPeople(query);
    }
    $scope.selectedTab = "Settings";
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