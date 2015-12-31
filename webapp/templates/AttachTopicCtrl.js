app.controller('AttachTopicCtrl', function($scope, $modalInstance, selectedTopic, attachmentList) {

    $scope.attachmentList = attachmentList;
    $scope.selectedTopic = selectedTopic;
    $scope.realDocumentFilter = "";

    $scope.filterDocs = function() {
        var filterlc = $scope.realDocumentFilter.toLowerCase();
        var rez =  $scope.attachmentList.filter( function(oneDoc) {
            return (filterlc.length==0
                || oneDoc.subject.toLowerCase().indexOf(filterlc)>=0);
        });
        rez = rez.sort( function(a,b) {
            return b.modTime - a.modTime;
        });
        return rez;
    }
    $scope.itemHasDoc = function(doc) {
        return $scope.selectedTopic == doc.id;
    }
    $scope.itemDocs = function() {
        return $scope.attachmentList.filter( function(oneDoc) {
            return $scope.itemHasDoc(oneDoc);
        });
    }
    $scope.addDocToItem = function(doc) {
        $scope.selectedTopic = doc.id;
    }
    $scope.removeDocFromItem = function(doc) {
        $scope.selectedTopic = "";
    }

    $scope.ok = function () {
        $modalInstance.close($scope.selectedTopic);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

});