app.controller('AttachTopicCtrl', function($scope, $modalInstance, selectedTopic, attachmentList) {

    $scope.attachmentList = attachmentList;
    $scope.selectedTopic = selectedTopic;
    $scope.realDocumentFilter = "";

    $scope.filterDocs = function() {
        var filterlc = $scope.realDocumentFilter.toLowerCase();
        var rez =  $scope.attachmentList.filter( function(oneDoc) {
            return (!oneDoc.deleted && (filterlc.length==0
                || oneDoc.subject.toLowerCase().indexOf(filterlc)>=0));
        });
        rez = rez.sort( function(a,b) {
            return b.modTime - a.modTime;
        });
        return rez;
    }
    $scope.itemHasDoc = function(oneTopic) {
        return $scope.selectedTopic == oneTopic.universalid;
    }
    $scope.itemDocs = function() {
        return $scope.attachmentList.filter( function(oneTopic) {
            return $scope.itemHasDoc(oneTopic);
        });
    }
    $scope.findSubject = function() {
        var foundSubj = "";
        $scope.attachmentList.forEach( function(oneTopic) {
            if ($scope.itemHasDoc(oneTopic)) {
                foundSubj = oneTopic.subject;
            }
        });
        return foundSubj;
    }
    $scope.addDocToItem = function(oneTopic) {
        $scope.selectedTopic = oneTopic.universalid;
    }
    $scope.removeDocFromItem = function(oneTopic) {
        $scope.selectedTopic = "";
    }

    $scope.ok = function () {
        $modalInstance.close($scope.selectedTopic);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };
    $scope.tabStyle = function(which) {
        var sss = {
            "border":"2px solid #F0D7F7",
            "border-bottom":"2px solid gray",
            "margin":"0px",
            "padding":"8px 15px",
            "font-size":"16px",
            "font-weight":"bold"
        };
        if ( ("Settings"==which) ) {
            sss.border="2px solid gray";
            sss["border-bottom"]="2px solid white";
            sss["background-color"] = "white";
        };
        return sss;
    };

});