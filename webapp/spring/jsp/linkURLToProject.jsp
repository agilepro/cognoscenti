<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    ar.assertLoggedIn("You need to Login to Upload a file.");
    String pageId = ar.reqParam("pageId");
    String folderVal = ar.defParam("folder", null);
    List<String> folders = UtilityMethods.splitString(folderVal, '|');
    NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    if (ngp.isFrozen()) {
        throw new Exception("Program Logic Error: addDocument.jsp should never be invoked when the workspace is frozen.  "
           +"Please check the logic of the controller.");
    }
    String folderPart = "";
    if (folderVal!=null) {
        folderPart = "?folder="+URLEncoder.encode(folderVal, "UTF-8");
    }
    JSONObject folderMap = new JSONObject();
    for (String folder: folders) {
        folderMap.put( folder, true);
    }

    JSONArray allLabels = ngp.getJSONLabels();
    //for (CustomRole role : ngp.getAllRoles()) {
    //    allLabels.put( role.getJSON() );
    //}

%>

<script>
var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Link URL");
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.folderMap = <%folderMap.write(out,2,4);%>;
    $scope.newLink = {
        id: "~new~",
        labelMap:{},
        attType:"URL"
    };

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.assignedLabels = function() {
        var res = [];
        $scope.allLabels.forEach( function(item) {
            if ($scope.newLink.labelMap[item.name]) {
                res.push(item);
            }
        });
        return res;
    }
    $scope.hasLabel = function(searchName) {
        return $scope.newLink.labelMap[searchName];
    }
    $scope.toggleLabel = function(label) {
        $scope.newLink.labelMap[label.name] = !$scope.newLink.labelMap[label.name];
    }

    $scope.createLink = function() {
        var postURL = "docsUpdate.json?did="+$scope.newLink.id;
        var postdata = angular.toJson($scope.newLink);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.newLink = data;
            window.location = "listAttachments.htm";

        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.suggestName = function() {
        var url = $scope.newLink.url;
        if (!url || url.length==0) {
            return;
        }
        if ($scope.newLink.name && $scope.newLink.name.length>0) {
            return;
        }
        var pos = url.lastIndexOf("/");
        if (pos>0) {
            url = url.substring(pos+1);
        }
        $scope.newLink.name = url;
    }
});
</script>


<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>


<style>
.spacey {
    width:100%;
}
.spacey tr td {
    padding:3px;
}
.firstcol {
    width:130px;
}
</style>
    
    <table class="spacey" >
        <tr>
            <td class="firstcol" >Type:</td>
            <td>
                <img src="<%=ar.retPath%>assets/images/iconUrl.png"> URL</span>
            </td>
        </tr>
        <tr>
            <td class="firstcol">
                URL:
            </td>
            <td>
                <input type="text" ng-model="newLink.url" ng-blur="suggestName()" class="form-control" />
            </td>
        </tr>
        <tr>
            <td class="firstcol">
                Name:
            </td>
            <td>
                <input type="text" ng-model="newLink.name" class="form-control" />
            </td>
        </tr>
        <tr>
            <td class="firstcol">
                Description:
            </td>
            <td>
                <textarea ng-model="newLink.description"  rows="4" class="form-control"></textarea>
            </td>
        </tr>
        <tr>
            <td class="firstcol">Labels: </td>
            <td>
                <span class="dropdown" ng-repeat="label in assignedLabels()" style="float:left">
                    <button class="labelButton" type="button" id="menu2"
                       data-toggle="dropdown" style="background-color:{{label.color}};"
                       ng-show="hasLabel(label.name)">{{label.name}} <i class="fa fa-close"></i></button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
                       <li role="presentation"><a role="menuitem" title="{{add}}"
                          ng-click="toggleLabel(label)" style="border:2px {{label.color}} solid;">Remove Label:<br/>{{label.name}}</a></li>
                    </ul>
                </span>
                <span>
                     <span class="dropdown" style="float:left">
                       <button class="btn btn-sm btn-primary btn-raised labelButton" 
                           type="button" 
                           id="menu1" 
                           data-toggle="dropdown"
                           title="Add Label"
                           style="padding:5px 10px">
                           <i class="fa fa-plus"></i></button>
                       <ul class="dropdown-menu" role="menu" aria-labelledby="menu1" 
                           style="width:320px;left:-130px">
                         <li role="presentation" ng-repeat="rolex in allLabels" style="float:left">
                             <button role="menuitem" tabindex="-1" ng-click="toggleLabel(rolex)" class="labelButton" 
                             ng-hide="hasLabel(rolex.name)" style="background-color:{{rolex.color}}">
                                 {{rolex.name}}</button>
                         </li>
                       </ul>
                     </span>
                </span>
            </td>
        </tr>
        <tr>
            <td></td>
            <td>
                <button class="btn btn-primary btn-raised" ng-click="createLink()">Attach Web URL</button>
            </td>
        </tr>
    </table>

</div>