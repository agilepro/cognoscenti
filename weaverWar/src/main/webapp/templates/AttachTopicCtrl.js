app.controller('AttachTopicCtrl', function($scope, $modalInstance, selectedTopics, attachmentList) {

    $scope.attachmentList = attachmentList;
    $scope.topics = selectedTopics;
    $scope.fullTopics = [];
    $scope.realDocumentFilter = "";
    
    function generateList() {
        console.log("Topic BEFORE: ", $scope.fullTopics);
        var res = [];
        $scope.attachmentList.forEach( function(oneTopic) {
            if ($scope.itemHasDoc(oneTopic.universalid)) {
                res.push(oneTopic);
            }
        });
        console.log("Topic gotten: ", res);
        $scope.fullTopics = res;
    }

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
        var found = false;
        $scope.topics.forEach( function(item) {
            if (item == oneTopic) {
                found = true;
            }
        });
        return found;
    }
    generateList();
    
    $scope.topicsOnItem = function() {
        var res = [];
        return $scope.attachmentList.forEach( function(oneTopic) {
            if ($scope.itemHasDoc(oneTopic.universalid)) {
                res.push(oneTopic);
            }
        });
        console.log("Topic gotten: ", res);
        return res;
    }

    $scope.addDocToItem = function(oneTopic) {
        if (!$scope.itemHasDoc(oneTopic.universalid)) {
            $scope.topics.push(oneTopic.universalid);
        }
        console.log("Topic list: ", $scope.topics);
        generateList();
    }
    $scope.removeDocFromItem = function(oneTopic) {
        var newList = [];
        $scope.topics.forEach( function(item) {
            if (item != oneTopic.universalid) {
                newList.push(item);
            }
        });
        $scope.topics = newList;
        console.log("Topic list: ", $scope.topics);
        generateList();
    }

    $scope.ok = function () {
        $modalInstance.close($scope.topics);
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