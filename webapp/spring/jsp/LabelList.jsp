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
    $scope.newLabel = {name: "", color: ""};
    $scope.colors = ["Pink","yellow","CornSilk","PaleGreen","Orange","Bisque","Coral","LightSteelBlue","Aqua","Thistle","Gold"];

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

    $scope.createLabel = function(label) {
        $scope.labelList.push({name:"",color:"white",isNew:true});
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
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation">
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation">
xxxx
                      </li>
                      <li role="presentation">
yyy
                      </li>
                    </ul>

              </li>
            </ul>
          </span>

        </div>
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
        <button class="btn" ng-click="createLabel(label)">Create New</button>
    </div>
</div>
