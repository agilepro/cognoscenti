app.controller('AttachDocumentCtrl', function($scope, $modalInstance, docList, attachmentList) {

    $scope.attachmentList = attachmentList;
    $scope.docList = docList;
    $scope.realDocumentFilter = "";

    $scope.filterDocs = function() {
        var filterlc = $scope.realDocumentFilter.toLowerCase();
        var rez =  $scope.attachmentList.filter( function(oneDoc) {
            return (filterlc.length==0
                || oneDoc.name.toLowerCase().indexOf(filterlc)>=0
                || oneDoc.description.toLowerCase().indexOf(filterlc)>=0);
        });
        rez = rez.sort( function(a,b) {
            return b.modifiedtime - a.modifiedtime;
        });
        return rez;
    }
    $scope.itemHasDoc = function(doc) {
        var res = false;
        var found = $scope.docList.forEach( function(docid) {
            if (docid == doc.universalid) {
                res = true;
            }
        });
        return res;
    }
    $scope.itemDocs = function() {
        return $scope.attachmentList.filter( function(oneDoc) {
            return $scope.itemHasDoc(oneDoc);
        });
    }
    $scope.addDocToItem = function(doc) {
        if (!$scope.itemHasDoc(doc)) {
            $scope.docList.push(doc.universalid);
        }
    }
    $scope.removeDocFromItem = function(doc) {
        $scope.docList = $scope.docList.filter( function(docid) {
            return (docid != doc.universalid);
        });
    }

    $scope.ok = function () {
        $modalInstance.close($scope.docList);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

});