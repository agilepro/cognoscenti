
app.controller('RoleModalCtrl', function ($scope, $modalInstance, $interval, roleInfo, isNew, parentScope, AllPeople, $http, siteId) {

    $scope.siteId = siteId;

    // initial comment object
    $scope.roleInfo = roleInfo;
    console.log("RoleModalCtrl ROLE:", roleInfo);

    // parent scope with all the crud methods
    $scope.parentScope = parentScope;
    $scope.allRoles = [];
    $scope.roleDefinitions = [];
    $scope.roleToCopy = "";


    $scope.reportError = function (data) {
        console.log("ERROR in RoleModel Dialog: ", data);
    }

    $scope.isNew = isNew;
    $scope.editMode = "main";

    $scope.colors = ["salmon", "khaki", "beige", "lightgreen", "orange", "bisque", "tomato", "aqua", "orchid",
        "peachpuff", "powderblue", "lightskyblue", "white"];

    $scope.loadPersonList = function (query) {
        var ret = AllPeople.findMatchingPeople(query, $scope.siteId);
        return ret;
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
            if (item.key == $scope.roleInfo.currentTerm) {
                $scope.currentTerm = item;
            }
        });
    }
    $scope.getCurrentTerm();

    $scope.getAllRoles = function () {
        const postdata = "{}";
        const postURL = "roleUpdate.json?op=GetAll";
        $http.post(postURL, postdata)
            .success(function (data) {
                $scope.allRoles = data.roles;
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
            
        const getURL = "roleDefinitions.json";
        $http.get(getURL)
            .success(function (data) {
                $scope.roleDefinitions = data.defs;
                console.log("Got definitions: ", $scope.roleDefinitions);
            })
            .error(function (data, status, headers, config) {
                $scope.reportError(data);
            });
    }
    $scope.getAllRoles();

    $scope.updatePlayers = function () {
        console.log("UPDATING ROLE: ", role);
        var role = {};
        role.symbol = $scope.roleInfo.symbol;
        role.color = $scope.roleInfo.color;
        role.linkedRole = $scope.roleInfo.linkedRole;
        role.players = cleanUserList($scope.roleInfo.players);
        $scope.updateRole(role);
        $scope.getCurrentTerm();
    }

    $scope.updateRole = function (role) {
        var postURL = "roleUpdate.json?op=Update";
        var postdata = angular.toJson(role);
        $scope.showError = false;
        $http.post(postURL, postdata)
            .success(function (data) {
                $scope.roleInfo = data;
                $scope.parentScope.updateRoleList(data);
                AllPeople.clearCache($scope.siteId);
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
        if (!$scope.newSymbol) {
            alert("Please pick a role to create");
            return;
        }
        var postdata = angular.toJson({symbol:$scope.newSymbol} );
        postURL = "roleUpdate.json?op=Create";
        $http.post(postURL, postdata)
            .success(function (data) {
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
        window.location = "RoleDefine.htm?role=" + $scope.roleInfo.symbol;
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
        var postdata = angular.toJson({ symbol: roleInfo.symbol });
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
        $scope.refreshRole();
    }

    $scope.makeLink = function () {
        if (!$scope.newLinkName) {
            alert("Enter a name to link to");
            return;
        }
        $scope.roleInfo.linkedRole = $scope.newLinkName;
        var role = {};
        role.symbol = $scope.roleInfo.symbol;
        role.linkedRole = $scope.roleInfo.linkedRole;
        $scope.updateRole(role);
        $scope.getCurrentTerm();
    }

    $scope.unLink = function () {
        $scope.roleInfo.linkedRole = "";
        var role = {};
        role.symbol = $scope.roleInfo.symbol;
        role.linkedRole = $scope.roleInfo.linkedRole;
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