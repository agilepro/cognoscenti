app.controller('ErrorCtrl', function ($scope, $modalInstance) {

    $scope.topic = {};
    $scope.topic.subject = "";
    $scope.topic.wiki = "";
    $scope.topic.html = "";
    $scope.topic.phase = "Draft";

    $scope.tinymceOptions1 = standardTinyMCEOptions();
    $scope.tinymceOptions1.height = 150;

    $scope.ok = function () {
        $scope.topic.wiki = HTML2Markdown($scope.topic.html);
        $modalInstance.close($scope.topic);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

});