<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%

    ar.assertLoggedIn("You need to Login to Upload a file.");
    String folderVal = ar.defParam("folder", null);
    List<String> folders = UtilityMethods.splitString(folderVal, '|');
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    if (ngp.isFrozen()) {
        throw new Exception("Program Logic Error: addDocument.jsp should never be invoked when the workspace is frozen.  "
           +"Please check the logic of the controller.");
    }
    
    NGBook site = ngp.getSite();
    String folderPart = "";
    if (folderVal!=null) {
        folderPart = "?folder="+URLEncoder.encode(folderVal, "UTF-8");
    }
    JSONObject folderMap = new JSONObject();
    for (String folder: folders) {
        folderMap.put( folder, true);
    }

    JSONArray allLabels = ngp.getJSONLabels();

%>

<script>
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Link URL");
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.folderMap = <%folderMap.write(out,2,4);%>;
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
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
            window.location = "DocsList.htm";

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
    

    initializeLabelPicker($scope, $http, $modal); 
    
});
</script>


<div ng-cloak>

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
                
            </td>
            <td>
                <a href="CleanAtt.htm?path={{newLink.url}}" target="_blank">
                    <button class="btn btn-prinary btn-raised">View as a Text Only page</button></a>
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
                <%@ include file="/spring/jsp/LabelPicker.jsp"%>
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

