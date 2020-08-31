<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
    ar.assertLoggedIn("You need to Login to Upload a file.");
    Cognoscenti cog = ar.getCogInstance();
    String pageId = ar.reqParam("pageId");
    String from = ar.reqParam("from");
    String folderVal = ar.defParam("folder", null);
    List<String> folders = UtilityMethods.splitString(folderVal, '|');
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    if (ngp.isFrozen()) {
        throw new Exception("Program Logic Error: WorkspaceMoveCopy1.jsp should never be invoked when the"
           +" workspace is frozen.   Please check the logic of the controller.");
    }

    NGPageIndex thisWS = null;
    NGPageIndex fromWS = null;
    for (NGPageIndex ngpis : cog.getAllProjectsInSite(siteId)) {
        if (ngpis.containerKey.equals(pageId)) {
            thisWS = ngpis;
            continue;
        }
        if (ngpis.containerKey.equals(from)) {
            fromWS = ngpis;
            continue;
        }
    }
    
    if (fromWS==null) {
        throw new Exception("Workspace Copy/Move page is not able to find a workspace with key="+from);
    }
    if (thisWS==null) {
        throw new Exception("Workspace Copy/Move page is not able to find a workspace with key="+pageId);
    }
    JSONObject thisWorkspace = thisWS.getJSON4List();
    JSONObject fromWorkspace = fromWS.getJSON4List();
    NGWorkspace fromWorkspaceObj = fromWS.getWorkspace();
    ar.setPageAccessLevels(fromWorkspaceObj);
    ar.assertMember("Must be a member of the workspace you want to copy or move from");

    JSONArray allLabels = ngp.getJSONLabels();
    
    JSONArray allAttachments = fromWorkspaceObj.getJSONAttachments(ar);
   
    
%>

<script>
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Transfer from Workspace");
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.fromWorkspace = <%fromWorkspace.write(out,2,4);%>;
    $scope.thisWorkspace = <%thisWorkspace.write(out,2,4);%>;
    $scope.allAttachments = <%allAttachments.write(out,2,4);%>;
    

    $scope.findLabels = function() {
        var res = [];
        $scope.allLabels.map( function(item) {
            if ($scope.folderMap[item.name]) {
                res.push(item);
            }
        });
        return res;
    }
    
    $scope.selectWorkspace = function(ws) {
        var url = "WorkspaceCopyMove2.htm?from="+encodeURIComponent(ws.pageKey);
        location.href=url;
    }
    
    $scope.copyDoc = function(doc) {
        if (!confirm("Are you sure you want to copy document \n'"+doc.name+"'\n into this workspace?")) {
            return;
        }
        let postURL = "copyDocument.json";
        var postObj = {
            "from": $scope.fromWorkspace.comboKey,
            "id": doc.id
        }
        var postdata = angular.toJson(postObj);
        $http.post(postURL, postdata)
        .success( function(data) {
            console.log("SUCCESS");
            doc.hideThis = true;
        })
        .error( function(data, status, headers, config) {
            console.log("FAILURE", data);
            $scope.reportError(data);
        });
    }
    $scope.moveDoc = function(doc) {
        if (!confirm("Are you sure you want to permanently move document \n'"
                     +doc.name+"'\n into this workspace?")) {
            return;
        }
        doc.hideThis = true;
    }
    $scope.rowStyle = function(doc) {
        if (doc.hideThis) {
            return {"background-color":"black","color":"grey"};
        }
        return {"background-color":"white"};
    }
});
</script>


<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Move/Copy Document/Topic/Action Item
        </div>
    </div>


    <h3>{{fromWorkspace.name}} <i class="fa fa-arrow-circle-o-right"></i> {{thisWorkspace.name}}</h3>
    <p>Select Artifacts to copy or move:</p>
    <table class="table">

    <tr>
       <th>Document Name</th>
       <th>Modified</th>
       <th>Size</th>
       <th></th>
    </tr>
    <tr ng-repeat="doc in allAttachments" ng-style="rowStyle(doc)">
       <td>{{doc.name}}</td>
       <td>{{doc.modifiedtime|date}}</td>
       <td>{{doc.size|number}} bytes</td>
       <td ng-hide="doc.hideThis">
           <button class="btn btn-sm btn-raised" ng-click="copyDoc(doc)">Copy</button>
           <!--button class="btn btn-sm btn-raised" ng-click="moveDoc(doc)">Move</button-->
       </td>
       <td ng-show="doc.hideThis">
           
       </td>
    </tr>
    <tr>
        <td colspan="3" class="linkWizardHeading"></td>
    </tr>
    </table>
</div>
<!-- end addDocument.jsp -->
