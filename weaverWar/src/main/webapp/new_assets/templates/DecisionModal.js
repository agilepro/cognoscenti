app.controller('DecisionModalCtrl', function ($scope, $modalInstance, decision, allLabels, siteInfo, $modal, $http) {

    $scope.decision = decision;
    $scope.siteInfo = siteInfo;
    $scope.htmlEditing = convertMarkdownToHtml(decision.decision);

    $scope.allLabels = allLabels;
    $scope.editMode = 'decision';

    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 300;

    $scope.hasLabel = function (val) {
        return $scope.decision.labelMap[val];
    }
    $scope.toggleLabel = function (val) {
        $scope.decision.labelMap[val.name] = !$scope.decision.labelMap[val.name];
    }
    $scope.deleteDecision = function (val) {
        $scope.decision.deleteMe = "deleteMe";
    }
    $scope.deleteCancel = function (val) {
        $scope.decision.deleteMe = null;
    }

    $scope.ok = function () {
        var newMarkdown = HTML2Markdown($scope.htmlEditing, {});
        if ($scope.decision.decision != newMarkdown) {
            $scope.decision.decisionMerge = { old: $scope.decision.decision, new: newMarkdown };
            delete $scope.decision.decision;
        }
        $modalInstance.close($scope.decision);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

    $scope.advanceReviewDate = function () {
        if ($scope.decision.reviewDate > $scope.decision.timestamp) {
            $scope.decision.reviewDate = $scope.decision.reviewDate + 365 * 24 * 3600000;
        }
        else {
            $scope.decision.reviewDate = $scope.decision.timestamp + 365 * 24 * 3600000;
        }
    }

    $scope.getAllLabels = function () {
        var postURL = "getLabels.json";
        $scope.showError = false;
        $http.post(postURL, "{}")
            .success(function (data) {
                console.log("All labels are gotten: ", data);
                $scope.allLabels = data.list;
                $scope.sortAllLabels();
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    };
    $scope.sortAllLabels = function () {
        $scope.allLabels.sort(function (a, b) {
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
            templateUrl: '../../../new_assets/templates/EditLabels.html',
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

    $scope.getContrastColor = function (color) {

        const tempEl = document.createElement("div");
        tempEl.style.color = color;
        document.body.appendChild(tempEl);
        const computedColor = window.getComputedStyle(tempEl).color;
        document.body.removeChild(tempEl);

        const match = computedColor.match(/\d+/g);

        if (!match) {
            console.error("Failed to parse color: ", computedColor);
            return "#39134C";
        }
        const [r, g, b] = match.map(Number);

        var yiq = ((r * 299) + (g * 587) + (b * 114)) / 1000;

        return (yiq >= 128) ? '#39134C' : '#ebe7ed';
    };

});