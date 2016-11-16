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
    for (CustomRole role : ngp.getAllRoles()) {
        allLabels.put( role.getJSON() );
    }

%>

<script>
var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.folderMap = <%folderMap.write(out,2,4);%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.findLabels = function() {
        var res = [];
        $scope.allLabels.map( function(item) {
            if ($scope.folderMap[item.name]) {
                res.push(item);
            }
        });
        return res;
    }

    $scope.newLink = {
        id: "~new~",
        labelMap:$scope.folderMap,
        attType:"URL"
    };
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

});
</script>


<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Link Google Doc to Workspace
        </div>
        <!--div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="" ng-click="" >Do Nothing</a></li>
            </ul>
          </span>

        </div-->
    </div>


    <table class="popups" width="100%">
        <tr>
            <td class="gridTableColummHeader" >Type:</td>
            <td style="width:20px;"></td>
            <td>
                <img src="<%=ar.retPath%>assets/images/iconUrl.png"> URL</span>
            </td>
        </tr>
        <tr><td style="height:10px"></td></tr>
        <tr>
            <td class="gridTableColummHeader"></td>
            <td  style="width:20px;"></td>
            <td>
                Go to googled drive, and find the document you want to attach.<br/>
                Edit the document.<br/>
                Take the URL from the address bar (or from the 'share link' command) and put that here.
            </td>
        </tr>
        <tr>
            <td class="gridTableColummHeader">
                URL:
            </td>
            <td  style="width:20px;"></td>
            <td>
                <input type="text" ng-model="newLink.url" class="form-control"
                    placeholder="Paste URL from editing the document"/>
            </td>
        </tr>
        <tr><td style="height:20px"></td></tr>
        <tr>
            <td class="gridTableColummHeader">
                Name:
            </td>
            <td  style="width:20px;"></td>
            <td>
                <input type="text" ng-model="newLink.name" class="form-control"
                    placeholder="Enter the name to refer to"/>
            </td>
        </tr>
        <tr><td style="height:20px"></td></tr>
        <tr>
            <td class="gridTableColummHeader">
                Description:
            </td>
            <td  style="width:20px;"></td>
            <td>
                <textarea ng-model="newLink.description"  rows="4" class="form-control"
                    placeholder="Explain how this document relates to this workspace"/></textarea>
            </td>
        </tr>
        <tr><td style="height:10px"></td></tr>
        <tr>
            <td class="gridTableColummHeader_2">Accessibility: </td>
            <td  style="width:20px;"></td>
            <td>
                <input type="checkbox" ng-model="newLink.public"> Public &nbsp; &nbsp;
                <input type="checkbox" checked="checked" disabled="disabled"> Member
            </td>
        </tr>
        <tr><td style="height:10px"></td></tr>
        <tr>
            <td class="gridTableColummHeader_2">Labels: </td>
            <td  style="width:20px;"></td>
            <td>
                <span ng-repeat="label in findLabels()"><button class="btn labelButton"
                    style="background-color:{{label.color}};">{{label.name}}
                    </button>
                </span>
            </td>
        </tr>
        <tr><td style="height:10px"></td></tr>
        <tr>
            <td></td>
            <td  style="width:20px;"></td>
            <td>
                <button class="btn btn-primary btn-raised" ng-click="createLink()">Attach Google Doc</button>
            </td>
        </tr>
    </table>

</div>