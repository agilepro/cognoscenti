        <span class="nav-item dropdown d-inline">
           <button class="btn-tiny btn-comment p-2" 
               type="button" 
               id="menu1" 
               data-toggle="dropdown"
               title="Add Filter"
            >
               <i class="fa fa-plus"></i></button>         
           <ul class="dropdown-menu mb-0 p-2" role="menu" aria-labelledby="menu1" 
               style="width:320px;left:-130px">
             <li role="presentation" ng-repeat="rolex in allLabels" style="float:left">
                 <button role="menuitem" tabindex="0" ng-click="toggleLabel(rolex)" class="labelButton" 
                 ng-hide="hasLabel(rolex.name)" style="background-color:{{rolex.color}}">
                     {{rolex.name}}</button>
             </li>
             <div class="dropdown-divider" style="float:clear"></div>               
             <li role="presentation" style="float:right">
               <button role="menuitem" ng-click="openEditLabelsModal()" class="labelButtonAdd btn-comment h6">
                   Add/Remove Labels</button>
             </li>
           </ul>
         </span>

      <span class="dropdown" ng-repeat="role in allLabels">
        <button class="dropdown-toggle labelButton" ng-click="toggleLabel(role)"
           style="background-color:{{role.color}};"
           ng-show="hasLabel(role.name)">{{role.name}} <i class="fa fa-close"></i></button>
      </span>

<script>
function initializeLabelPicker($scope, $http, $modal) {
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
    $scope.sortAllLabels = function() {
        $scope.allLabels.sort( function(a, b){
              if (a.name.toLowerCase() < b.name.toLowerCase())
                return -1;
              if (a.name.toLowerCase() > b.name.toLowerCase())
                return 1;
              return 0;
        });
    };
    $scope.getAllLabels();
    $scope.openEditLabelsModal = function (item) {
        
        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '../../new_assets/templates/EditLabels.html',
            controller: 'EditLabelsCtrl',
            size: 'lg',
            resolve: {
                siteInfo: function () {
                  return $scope.siteInfo;
                },
            }
        });

        attachModalInstance.result
        .then(function (selectedActionItems) {
            $scope.getAllLabels();
        }, function () {
            $scope.getAllLabels();
        });
    };
}
</script>

<script src="<%=ar.baseURL%>new_assets/templates/EditLabelsCtrl.js"></script>