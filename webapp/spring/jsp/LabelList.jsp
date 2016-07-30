<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%@page import="org.socialbiz.cog.AgendaItem"
%><%@page import="org.socialbiz.cog.NGLabel"
%><%@page import="org.socialbiz.cog.LabelRecord"
%><%


    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Must be a member to see meetings");

    JSONArray labelList = new JSONArray();
    for (NGLabel label : ngp.getAllLabels()) {
        if (label instanceof LabelRecord) {
            labelList.put(label.getJSON());
        }
    }

%>


<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.labelList = <%labelList.write(out,2,4);%>;
    $scope.colors = ["Gold","Yellow","CornSilk","PaleGreen","Orange","Bisque","Coral","LightSteelBlue","Aqua","Thistle","Pink"];
    $scope.newLabel = {name: "", color: $scope.colors[0]};

    $scope.showInput = false;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        var exception = serverErr.exception;
        $scope.errorMsg = exception.join();
        $scope.errorTrace = exception.stack;
        $scope.showError=true;
        $scope.showTrace = false;
    };

    $scope.sortItems = function() {
        $scope.labelList.sort( function(a, b){
              if (a.name < b.name)
                return -1;
              if (a.name > b.name)
                return 1;
              return 0;
        });
        return $scope.labelList;
    };

    $scope.updateLabel = function(label) {
        var key = label.name;
        var postURL = "labelUpdate.json?op=Create";
        var postdata = angular.toJson(label);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.labelList = $scope.removeItem($scope.labelList,"name",key);
            data.editedName = data.name;
            data.isNew = false;
            data.isEdit = false;
            $scope.labelList.push(data);
            $scope.sortItems();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.deleteLabel = function(label) {
        var specialName = label.name;
        var postURL = "labelUpdate.json?op=Delete";
        var postdata = angular.toJson(label);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.labelList = $scope.removeItem($scope.labelList,"name",specialName);
            $scope.sortItems();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.createFromNew = function() {
        var label=$scope.newLabel;
        if (!label.name || label.name.length==0) {
            alert("Enter a label name");
            return;
        }
        var newOne = {name:label.name,editedName:label.name,color:label.color};
        $scope.newLabel.name="";
        $scope.labelList.push(newOne);
        $scope.updateLabel(newOne);
        $scope.sortItems();
    };

    $scope.removeItem = function(array, key, val) {
        var res = [];
        for (var i=0; i<array.length; i++) {
            if (array[i].name!=val) {
                res.push(array[i]);
            }
        }
        return res;
    }
    $scope.removeItemGen = function(array, key, val) {
        var res = [];
        for (var i=0; i<array.length; i++) {
            if (array[i][key]!=val) {
                res.push(array[i]);
            }
        }
        return res;
    }
    $scope.setEditNameValues = function() {
        for (var i=0; i<array.length; i++) {
            array[i].editedName = array[i].name;
        }
    }
    $scope.sortItems();

    $scope.notImpl = function() {
        alert("Not implemented yet");
    }
});

</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Labels
        </div>
    </div>
    <div>
        <div class="well">
            <table><tr>
                <td>New Label:</td>
                <td style="padding:10px"><input type="text" ng-model="newLabel.name" style="width:200px;"
                            placeholder="Enter New Label Name" class="form-control"></td>
                <td style="padding:10px"><div class="dropdown">
                    <button class="form-control dropdown-toggle" id="menu2" data-toggle="dropdown"
                            style="background-color:{{newLabel.color}};">
                            {{newLabel.color}} <span class="caret"></span></button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
                        <li role="presentation" ng-repeat="color in colors">
                            <a role="menuitem" style="background-color:{{color}};"
                            href="#"  ng-click="newLabel.color=color">{{color}}</a></li>
                    </ul>
                </div></td>
                <td style="padding:10px"><button class="btn btn-primary" ng-click="createFromNew(newLabel)">Create New</button></td>
            </tr></table>
        </div>

        <table class="gridTable2" width="600px;">
            <tr class="gridTableHeader">
                <td style="width:200px;">Label</td>
                <td style="width:80px;">Color</td>
                <td style="width:100px;"></td>
            </tr>
            <tr ng-repeat="label in labelList">
                <td ng-show="label.isEdit || label.isNew">
                    <input type="text" ng-model="label.editedName" style="width:200px;"
                        placeholder="Enter Label Name" class="form-control">
                </td>
                <td ng-hide="label.isEdit || label.isNew">
                    <button style="background-color:{{label.color}};" class="btn btn-sm"
                        placeholder="Enter Label Name">{{label.name}}</button>
                </td>
                <td>
                    <div class="dropdown" ng-show="label.isEdit || label.isNew">
                        <button class="btn btn-default dropdown-toggle" type="button" id="menu2" data-toggle="dropdown" style="background-color:{{label.color}};">
                        {{label.color}} <span class="caret"></span></button>
                        <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
                            <li role="presentation" ng-repeat="color in colors">
                                <a role="menuitem" style="background-color:{{color}};"
                                href="#"  ng-click="label.color=color">{{color}}</a></li>
                        </ul>
                    </div>
                    <div class="dropdown" ng-hide="label.isEdit || label.isNew">
                        {{label.color}}
                    </div>
                </td>
                <td  style="padding:5px;" ng-hide="label.isEdit || label.isNew">
                    <button class="btn" ng-click="label.isEdit=true;label.editedName=label.name">Edit</button>
                </td>
                <td  style="padding:5px;" ng-show="label.isEdit">
                    <button class="btn" ng-click="updateLabel(label)">Save</button>
                    <button class="btn" ng-click="deleteLabel(label)">Delete</button>
                </td>
                <td  style="padding:5px;" ng-show="label.isNew">
                    <button class="btn" ng-click="updateLabel(label)">Create</button>
                </td>
            </tr>
        </table>
    </div>
</div>
