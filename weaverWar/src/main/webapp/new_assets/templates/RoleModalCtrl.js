
app.controller('RoleModalCtrl', function ($scope, $modalInstance, $interval, roleInfo, isNew, parentScope, AllPeople, $http, siteId) {

    $scope.siteId = siteId;

    // initial comment object
    $scope.roleInfo = roleInfo;
    console.log("ROLE", roleInfo);

    // parent scope with all the crud methods
    $scope.parentScope = parentScope;
    $scope.allRoles = [];
    $scope.roleToCopy = "";


    $scope.reportError = function (data) {
        console.log("ERROR in RoleModel Dialog: ", data);
    }

    $scope.isNew = isNew;
    $scope.editMode = "main";

    $scope.colors = ["salmon", "khaki", "beige", "lightgreen", "orange", "bisque", "tomato", "aqua", "orchid",
        "peachpuff", "powderblue", "lightskyblue", "white"];

    $scope.loadPersonList = function (query) {
        return AllPeople.findMatchingPeople(query, $scope.siteId);
    }
    $scope.getCurrentTerm = function () {
        $scope.currentTerm = null;
        if (!$scope.roleInfo.currentTerm) {
            return null;
        }
        if (!$scope.roleInfo.terms) {
            return null;
        }
        var curTerm = null;
        $scope.roleInfo.terms.forEach(function (item) {
            console.log("Considering", $scope.roleInfo.currentTerm, item);
            if (item.key == $scope.roleInfo.currentTerm) {
                $scope.currentTerm = item;
            }
        });
    }
    $scope.getCurrentTerm();

    $scope.getAllRoles = function () {
        var postdata = "{}";
        postURL = "roleUpdate.json?op=GetAll";
        $http.post(postURL, postdata)
            .success(function (data) {
                $scope.allRoles = data.roles;
                console.log("AllRoles is: ", data);
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    }
    $scope.getAllRoles();

    $scope.updatePlayers = function () {
        var role = {};
        role.name = $scope.roleInfo.name;
        role.color = $scope.roleInfo.color;
        role.linkedRole = $scope.roleInfo.linkedRole;
        role.players = cleanUserList($scope.roleInfo.players);
        console.log("UPDATING ROLE: ", role);
        $scope.updateRole(role);
        $scope.getCurrentTerm();
    }

    $scope.updateRole = function (role) {
        var postURL = "roleUpdate.json?op=Update";
        var postdata = angular.toJson(role);
        $scope.showError = false;
        $http.post(postURL, postdata)
            .success(function (data) {
                console.log("SETTING ROLE TO: ", data);
                $scope.roleInfo = data;
                $scope.parentScope.updateRoleList(data);
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    };
    $scope.cleanDuplicates = function (rolePlayers) {
        var cleanList = [];
        rolePlayers.forEach(function (item) {
            var newOne = true;
            var uidlc = item.uid;
            if (!uidlc) {
                uidlc = item.name;
                item.uid = uidlc;
            }
            uidlc = uidlc.toLowerCase();
            cleanList.forEach(function (inner) {
                if (uidlc == inner.uid.toLowerCase()) {
                    newOne = false;
                }
            });
            if (newOne) {
                cleanList.push(item);
            }
        });
        return cleanList;
    }



    $scope.createAndClose = function () {
        if (!$scope.roleInfo.name) {
            alert("Please enter a name for the new role");
            return;
        }
        if ($scope.roleToCopy) {
            var roleName = $scope.roleInfo.name;
            $scope.roleInfo = JSON.parse(JSON.stringify($scope.roleToCopy));
            $scope.roleInfo.name = roleName;
        }
        console.log("COPY FROM", $scope.roleInfo);
        var postdata = angular.toJson($scope.roleInfo);
        postURL = "roleUpdate.json?op=Create";
        $http.post(postURL, postdata)
            .success(function (data) {
                console.log("RESULT OF COPY", data);
                $scope.parentScope.cleanDuplicates(data);
                $scope.parentScope.updateRoleList(data);
                $modalInstance.dismiss('cancel');
            })
            .error(function (data, status, headers, config) {
                $scope.parentScope.reportError(data);
            });
    };
    $scope.saveAndClose = function () {
        $scope.parentScope.updateRole($scope.roleInfo);
        $modalInstance.dismiss('cancel');
    };
    $scope.defineRole = function () {
        $scope.parentScope.saveCreatedRole($scope.roleInfo);
        window.location = "RoleDefine.htm?role=" + $scope.roleInfo.name;
    };
    $scope.deleteAndClose = function () {
        $scope.parentScope.deleteRole($scope.roleInfo);
        $modalInstance.dismiss('cancel');
    };
    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };

    $scope.refreshRole = function () {
        var postURL = "roleUpdate.json?op=Update";
        var postdata = angular.toJson({ name: roleInfo.name });
        console.log("calling: ", postURL);
        $http.post(postURL, postdata)
            .success(function (data) {
                $scope.parentScope.cleanDuplicates(data);
                $scope.roleInfo = data;
                $scope.getCurrentTerm();
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    }
    if (!isNew) {
        console.log("refreshing role: ", roleInfo);
        $scope.refreshRole();
    }

    $scope.makeLink = function () {
        if (!$scope.newLinkName) {
            alert("Enter a name to link to");
            return;
        }
        $scope.roleInfo.linkedRole = $scope.newLinkName;
        var role = {};
        role.name = $scope.roleInfo.name;
        role.linkedRole = $scope.roleInfo.linkedRole;
        console.log("UPDATING LINKED ROLE: ", role);
        $scope.updateRole(role);
        $scope.getCurrentTerm();
    }

    $scope.unLink = function () {
        $scope.roleInfo.linkedRole = "";
        var role = {};
        role.name = $scope.roleInfo.name;
        role.linkedRole = $scope.roleInfo.linkedRole;
        console.log("UPDATING LINKED ROLE: ", role);
        $scope.updateRole(role);
        $scope.getCurrentTerm();
    }
    $scope.accessType = function () {
        if ($scope.roleInfo.canUpdateWorkspace) {
            return "WRITEABLE";
        }
        else {
            return "OBSERVER";
        }
    }
});