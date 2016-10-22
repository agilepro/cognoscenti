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
%>

<script>
var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.folderMap = <%folderMap.write(out,2,4);%>;

    $scope.findLabels = function() {
        var res = [];
        $scope.allLabels.map( function(item) {
            if ($scope.folderMap[item.name]) {
                res.push(item);
            }
        });
        return res;
    }
});
</script>


<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Add Document
        </div>
    </div>


    <table>
    <tr>
        <td colspan="3" class="linkWizardHeading">How do you want to attach the file?:</td>
    </tr>
    <tr style="height:50px;padding:15px">
        <td style="padding:15px">
            <button class="btn btn-primary btn-raised" onClick="location.href='docsUpload.htm<%=folderPart%>'">Upload Files</button>
        </td>
        <td style="padding:15px">
            <p>Take files from your local disk, and using your browser upload them to the workspace.</p>
        </td>
    </tr>
    <tr style="height:50px;padding:15px">
        <td style="padding:15px">
            <button type="button" class="btn btn-primary btn-raised"
                onClick="location.href='linkGoogleDoc.htm<%=folderPart%>'">Attach Google Doc</button>
        </td>
        <td style="padding:15px">
            <p>Weaver can access documents from Google Drive, also known as
            Google Docs.  In the current implementation you create or locate the document on
            Google Drive, open it for editing, and save the URL for that into your Weaver workspace.
            </p>
        </td>
    </tr>
    <tr style="height:50px;padding:15px">
        <td style="padding:15px">
            <button class="btn btn-primary btn-raised" onClick="location.href='linkToRepository.htm<%=folderPart%>'">Attach from Repository</button>
        </td>
        <td style="padding:15px"><p>Cognoscenti can access a document repository, using WebDAV or other protocols,
           to retrieve a document directly from there.   The advantage of this is that later, if the document is
           changed, the updated document can be synchronized with that document repository.  Either specify the
           address of that document, or browse the repository using your pre-configured connections.</p></td>
    </tr>
    <tr style="height:50px;padding:15px">
        <td style="padding:15px">
            <button type="button" class="btn btn-primary btn-raised"
                onClick="location.href='linkURLToProject.htm<%=folderPart%>'">Link URL</button>
        </td>
        <td style="padding:15px"><p>Link a web page to the workspace.   This will not download the web page as a attachment,
               but instead will provide an easy way for other users to access the web page in their browser.</p></td>
    </tr>
    </table>
</div>
<!-- end addDocument.jsp -->
