
app.controller('OutcomeModalCtrl', function ($scope, $modalInstance, cmt, $http) {

    $scope.cmt = cmt;

    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 300;

    $scope.ok = function () {
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
    function getComment() {
        if ($scope.cmt.time>0) {
            var getURL = "info/comment?cid="+$scope.cmt.time;
            console.log("calling: ",getURL);
            $http.get(getURL)
            .success( setComment )
            .error( handleHTTPError );
        }
    }
    function handleHTTPError(data, status, headers, config) {
        console.log("ERROR in ResponseModel Dialog: ", data);
    }
    function setComment(newComment) {
        console.log("SET COMMENT", newComment);
        if (!newComment.responses) {
            newComment.responses = [];
        }
        newComment.suppressEmail = (newComment.suppressEmail==true);
        newComment.choices = ["Consent", "Objection"];
        if (!newComment.docList) {
            newComment.docList = [];
        }
        if (!newComment.notify) {
            newComment.notify = [];
        }
        newComment.state = 13;
        $scope.cmt = newComment;
    }

    function saveComment(closeIt) {
        console.log("SAVE COMMENT");
        var updateRec = {};
        updateRec.time = $scope.cmt.time;
        updateRec.outcomeHtml = $scope.cmt.outcomeHtml;
        updateRec.outcome = HTML2Markdown(updateRec.outcomeHtml, {});
        updateRec.state = 13;
        var postdata = angular.toJson(updateRec);
        var postURL = "info/comment?cid="+$scope.cmt.time;
        console.log(postURL,updateRec);
        $http.post(postURL ,postdata)
        .success( function(data) {
            if ("Y"==closeIt) {
                $modalInstance.dismiss('ok')
            }
            else {
                setComment(data);
            }
        })
        .error( handleHTTPError );
    }
});