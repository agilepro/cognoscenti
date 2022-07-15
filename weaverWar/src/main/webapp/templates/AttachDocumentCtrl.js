app.controller('AttachDocumentCtrl', function($scope, $http, $modalInstance, containingQueryParams, 
               docSpaceURL) {
    window.MY_SCOPE = $scope;
    $scope.docsList = [];
    $scope.docSpaceURL = docSpaceURL;
    $scope.containingQueryParams = containingQueryParams;
    $scope.attachedDocs = [];
    $scope.realDocumentFilter = "";
    $scope.uploadMode = false;
    $scope.fileProgress = [];

    $scope.retrieveDocumentList = function() {
        var getURL = "docsList.json";
        $scope.showError=false;
        $http.get(getURL)
        .success( function(data) {
            var undeleted = [];
            data.docs.forEach( function(item) {
                if (!item.deleted) {
                    undeleted.push(item);
                }
            });
            $scope.docsList = undeleted;
            console.log("DOCUMENT LIST", data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });

        var getURL = "attachedDocs.json?"+containingQueryParams;
        $http.get(getURL)
        .success( function(data) {
            $scope.attachedDocs = data.list;
            console.log("ATTACHED LIST", data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });

    }
    $scope.retrieveDocumentList();
    
    
    $scope.saveDocumentList = function(closeDialog) {
        var getURL = "attachedDocs.json?"+containingQueryParams;
        var newData = {list: $scope.attachedDocs};
        $http.post(getURL, JSON.stringify(newData))
        .success( function(data) {
            $scope.attachedDocs = data.list;
            if (closeDialog) {
                $modalInstance.close($scope.attachedDocs);
            }
            else {
                $scope.retrieveDocumentList();
            }
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });

    }
    
    
    
    $scope.filterDocs = function() {
        var filterlc = $scope.realDocumentFilter.toLowerCase();
        var rez =  $scope.docsList.filter( function(oneDoc) {
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
        var found = $scope.attachedDocs.forEach( function(docid) {
            if (docid == doc.universalid) {
                res = true;
            }
        });
        return res;
    }
    $scope.itemDocs = function() {
        return $scope.docsList.filter( function(oneDoc) {
            return $scope.itemHasDoc(oneDoc);
        });
    }
    $scope.addDocToItem = function(doc) {
        if (!$scope.itemHasDoc(doc)) {
            $scope.attachedDocs.push(doc.universalid);
        }
        $scope.saveDocumentList(false);
    }
    $scope.removeDocFromItem = function(doc) {
        $scope.attachedDocs = $scope.attachedDocs.filter( function(docid) {
            return (docid != doc.universalid);
        });
        $scope.saveDocumentList(false);
    }

    $scope.ok = function () {
        $scope.saveDocumentList(true);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };
    
    $scope.unfinishedUpload = function() {
        var res = false;
        $scope.fileProgress.forEach( function(fp) {
            if (!fp.done) {
                res = true;
            }
        });
        return res;
    }


    /// FILE UPLOAD ///

    $scope.isHover = false;
    $scope.dragIn = function(event) {
        event.preventDefault();
        $scope.isHover = true;
        $scope.$apply();
    }
    $scope.dragOut = function(event) {
        event.preventDefault();
        $scope.isHover = false;
        $scope.$apply();
    }
    $scope.dragDrop = function(event)  {
        event.preventDefault();
        $scope.isHover = false;
        $scope.uploadMode = true;
        var newFiles = event.dataTransfer.files;
        if (!newFiles) {
            alert("Oh.  It looks like you are using a browser that does not support the dropping of files.  Currently we have no other solution than using Mozilla or Chrome or the latest IE for uploading files.");
            return;
        }

        for (var i=0; i<newFiles.length; i++) {
            var newProgress = {};
            newProgress.file = newFiles[i];
            newProgress.status = "Preparing";
            newProgress.done = false;
            $scope.fileProgress.push(newProgress);
        }
        $scope.selectedTab='Upload';
        $scope.$apply();
    }
    $scope.greenOnDrag = function() {
        if ($scope.isHover) {
            return "lvl-over";
        }
        else {
            return "";
        }
    }
    $scope.reportError = function(serverErr) {
        console.log("ERROR", serverErr);
        alert(JSON.stringify(serverErr));
    };
    $scope.cancelUpload = function(oneProgress) {
        oneProgress.done = true;
        oneProgress.status = "Cancelled";
        $scope.switchBackIfDone();
    }
    $scope.startUpload = function(oneProgress) {
        oneProgress.status = "Starting";
        oneProgress.loaded = 0;
        oneProgress.percent = 0;
        oneProgress.labelMap = $scope.filterMap;
        var postURL = $scope.docSpaceURL;
        var postdata = '{"operation": "tempFile"}';
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            oneProgress.tempFileName = data.tempFileName;
            oneProgress.tempFileURL = data.tempFileURL;
            $scope.actualUpload(oneProgress);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.actualUpload = function(oneProgress) {
        oneProgress.status = "Uploading";
        var postURL = $scope.docSpaceURL;

        var xhr = new XMLHttpRequest();
        xhr.upload.addEventListener("progress", function(e){
          $scope.$apply( function(){
            if(e.lengthComputable){
              oneProgress.loaded = e.loaded;
              oneProgress.percent = Math.round(e.loaded * 100 / e.total);
            } else {
              oneProgress.percent = 50;
            }
          });
        }, false);
        xhr.upload.addEventListener("load", function(data) {
            $scope.nameUploadedFile(oneProgress);
        }, false);
        xhr.upload.addEventListener("error", $scope.reportError, false);
        xhr.upload.addEventListener("abort", $scope.reportError, false);
        xhr.open("PUT", oneProgress.tempFileURL);
        xhr.send(oneProgress.file);
    };
    $scope.nameUploadedFile = function(oneProgress) {
        oneProgress.status = "Finishing";
        var postURL = $scope.docSpaceURL;
        var op = {operation: "newDoc"};
        op.tempFileName = oneProgress.tempFileName;
        op.doc = {};
        op.doc.description = oneProgress.description;
        op.doc.name = oneProgress.file.name;
        op.doc.labelMap = oneProgress.labelMap;
        var postdata = JSON.stringify(op);
        $http.post(postURL, postdata)
        .success( function(data) {
            if (data.exception) {
                $scope.reportError(data);
                return;
            }
            oneProgress.status = "DONE";
            oneProgress.done = true;
            oneProgress.doc = data;
            $scope.attachedDocs.push(data.doc.universalid);
            $scope.docsList.push(data.doc);
            $scope.saveDocumentList(false);
            $scope.switchBackIfDone();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.switchBackIfDone = function() {
        var moreToUpload = false;
        $scope.fileProgress.forEach( function(item) {
            if (!item.done) {
                moreToUpload = true;
            }
        });
        $scope.uploadMode = moreToUpload;
    }
    $scope.selectedTab = "Settings";
    $scope.newLink = {
        id: "~new~",
        labelMap:{},
        attType:"URL"
    };
    $scope.createdLink = {}
    $scope.addLink = function() {
        console.log("NEWLINK", $scope.newLink);
        if (!$scope.newLink.name || !$scope.newLink.url) {
            alert("Enter both a URL and a name");
            return;
        }
        var postURL = "docsUpdate.json?did="+$scope.newLink.id;
        var postdata = angular.toJson($scope.newLink);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.createdLink = data;
            $scope.newLink = {
                id: "~new~",
                labelMap:{},
                attType:"URL"
            };
            $scope.attachedDocs.push(data.universalid);
            $scope.saveDocumentList(false);
            $scope.selectedTab='Settings';
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    
    $scope.nameMessage = function() {
        if (!$scope.newLink.name) {
            return "";
        }
        var newNameLC = $scope.newLink.name.toLowerCase();
        var found = false;
        $scope.docsList.forEach( function(item) {
            if (newNameLC == item.name.toLowerCase()) {
                found = true;
            }
        });
        if (found) {
            return "WARNING: there is already a document with that name in workspace";
        }
        return "";
    }
    
});