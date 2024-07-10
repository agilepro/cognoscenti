console.log("loaded the DocumentDetailsCtrl");

app.controller('DocumentDetailsCtrl', function ($scope, $modalInstance, $http, $interval, $modal, siteInfo, docId, AllPeople, wsUrl) {

    console.log("loaded the DocumentDetailsCtrl");

    $scope.docId     = docId;
    $scope.docInfo   = {};
    $scope.allLabels = [];
    $scope.siteInfo  = siteInfo;
    $scope.wsUrl     = wsUrl;
    $scope.reportError = function(data) {
        console.log("ERROR", data);
    }
    
    $scope.editMode = "details";
    
    $scope.ok = function () {
        $scope.saveDoc();
        $scope.readyToLeave = true;
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

    $scope.loadPersonList = function(query) {
        return AllPeople.findMatchingPeople(query, $scope.siteId);
    }

    $scope.setDocumentData = function(data) {
        $scope.timerCorrection = data.serverTime - new Date().getTime();
        $scope.docInfo = data;
    }
    $scope.hasLabel = function(searchName) {
        if ($scope.docInfo.labelMap) {
            return $scope.docInfo.labelMap[searchName];
        }
        return false;
    }
    $scope.toggleLabel = function(label) {
        $scope.docInfo.labelMap[label.name] = !$scope.docInfo.labelMap[label.name];
    }
    $scope.setPurge = function(days) {
        if (!days || days==0) {
            $scope.docInfo.purgeDate=0;
        }
        else {
            $scope.docInfo.purgeDate=new Date().getTime() + days*24*60*60*1000;
        }
    }
    
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
            templateUrl: '../../../templates/EditLabels.html',
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
    

    $scope.getDocument = function() {
        $scope.isUpdating = true;
        var postURL = "docsList.json";
        $http.get(postURL)
        .success( function(data) {
            data.docs.forEach( function(oneDoc) {
                if (oneDoc.id == $scope.docId) {
                    $scope.setDocumentData(oneDoc);
                }
            });
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
        
    }
    $scope.getDocument();
    $scope.saveDoc = function() {
        if ($scope.docInfo.attType == "FILE") {
            var dotPos = $scope.docInfo.name.indexOf(".");
            if (dotPos <= 0) {
                alert("Sorry, the document name has to include an 'extension'  such as '.pdf' or '.jpg' or something like that depending on the type of document");
                return;
            }
        }
        
        var postURL = "docsUpdate.json?did="+$scope.docInfo.id;
        var postdata = angular.toJson($scope.docInfo);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.setDocumentData(data);
            if ($scope.readyToLeave) {
                $modalInstance.dismiss();
            }
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
});