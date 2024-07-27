      <span class="dropdown" ng-repeat="role in allLabels">
        <button class="dropdown-toggle labelButton"
           style="background-color:{{role.color}};"
           ng-show="hasLabel(role.name)">{{role.name}}</i></button>
      </span>



<script>
function initializeLabelPicker($scope, $http, $modal) {

    $scope.sortAllLabels = function() {
        $scope.allLabels.sort( function(a, b){
              if (a.name.toLowerCase() < b.name.toLowerCase())
                return -1;
              if (a.name.toLowerCase() > b.name.toLowerCase())
                return 1;
              return 0;
        });
    };
}
</script>

<script src="<%=ar.baseURL%>new_assets/templates/EditLabelsCtrl.js"></script>