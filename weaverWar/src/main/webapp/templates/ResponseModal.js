app.controller('ModalResponseCtrl', function ($scope, $modalInstance, cmtId, responseUser, $http) {

    $scope.responseUser = responseUser;
    $scope.cmtId = cmtId;
    $scope.cmtOriginal = {};
    $scope.cmt = {};
    $scope.response = {};
    getComment();
    
    function reportError(data) {
        console.log("ERROR in ResponseModel Dialog: ", data);
    }
    function getComment() {
        var getURL = "info/comment?cid="+$scope.cmtId;
        console.log("calling: ",getURL);
        $http.get(getURL)
        .success( function(data) {
            setComment(data);
        })
        .error( function(data, status, headers, config) {
            reportError(data);
        });
    }
    function saveComment(close) {
        var postURL = "info/comment?cid="+$scope.cmtId;
        var updateRec = {time:$scope.cmtId, responses:[]};
        $scope.response.body = HTML2Markdown($scope.response.html, {});
        updateRec.responses.push($scope.response);
        var postdata = angular.toJson(updateRec);
        console.log("saving new comment: ",updateRec);
        $http.post(postURL ,postdata)
        .success( function(data) {
            setComment(data);
            if ("Y"==close) {
                $modalInstance.close();
            }
        })
        .error( function(data, status, headers, config) {
            reportError(data);
        });
    }
    function setComment(newComment) {
        newComment.choices = ["Consent", "Objection"];
        $scope.displayText = convertMarkdownToHtml(newComment.body + "\n\n" + newComment.outcome);
        $scope.cmt = newComment;
        $scope.cmtOriginal = JSON.parse(JSON.stringify(newComment));
        $scope.response = {"user":$scope.responseUser};
        if (newComment.commentType == 2) {
            $scope.choices = newComment.choices;
        }
        else {
            $scope.choices = ["Save Response"];
        }
        newComment.responses.forEach( function(item) {
            if ($scope.responseUser == item.user) {
                $scope.response = item;
            }
        });
        if (!$scope.response.choice) {
            $scope.response.choice = newComment.choices[0];
        }
    }
        
    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 300;


    $scope.ok = function (choice) {
        $scope.response.choice = choice;
        saveComment("Y");
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

    $scope.commentTypeName = function() {
        if ($scope.cmt.commentType==2) {
            return "Proposal";
        }
        if ($scope.cmt.commentType==3) {
            return "Round";
        }
        return "Comment";
    }

});