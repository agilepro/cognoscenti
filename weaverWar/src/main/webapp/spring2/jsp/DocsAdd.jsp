<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
    ar.assertLoggedIn("You need to Login to Upload a file.");
    String pageId = ar.reqParam("pageId");
    String folderVal = ar.defParam("folder", null);
    List<String> folders = UtilityMethods.splitString(folderVal, '|');
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();

    String folderPart = "";
    if (folderVal!=null) {
        folderPart = "?folder="+URLEncoder.encode(folderVal, "UTF-8");
    }
    JSONObject folderMap = new JSONObject();
    for (String folder: folders) {
        folderMap.put( folder, true);
    }

    JSONArray allLabels = ngw.getJSONLabels();
    
    boolean userReadOnly = ar.isReadOnly(); 
%>

<script>
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Add Document Methods");
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


<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>
<div class="container-fluid">
    <div class="row">
<% if (userReadOnly) { %>

<div class="guideVocal" style="margin-top:80px">
    You are not allowed to add a document to the workspace, because
    you are an observer.  You can access documents, but you can 
    not add them or update them.
    
    If you wish to add a document, speak to the administrator of this 
    workspace / site and have your membership level changed to an
    active user.
</div>

<% } else if (ngw.isFrozen()) { %>

<div class="guideVocal" style="margin-top:80px">
    <p>You are not able to add a document to this workspace, because
    the workspace is frozen.
    Frozen workspaces can not be modified: nothing can be added
    or removed, including documents and links.</p>
    
    <p>If you wish to add or update documents, the workspace must be set into the 
    active (unfrozen) state in the workspace admin page.</p>
</div>

<% } else { %>


    <table>

    <tr>
        <td colspan="3" class=" p-3 h5 linkWizardHeading">How do you want to attach the file?:</td>
    </tr>
    <tr>
        <td class="px-5 py-1">
            <button class="btn btn-primary btn-raised" onClick="location.href='DocsUpload.htm<%=folderPart%>'">Upload Files</button>
        </td>
        <td class="py-1">
            <p>Take files from your local disk, and using your browser upload them to the workspace.</p>
        </td>
    </tr>
    <tr>
        <td class="px-5 py-1">
            <button type="button" class="btn btn-primary btn-raised"
                onClick="location.href='linkURLToProject.htm<%=folderPart%>'">Link URL</button>
        </td>
        <td class="py-1"><p>Link a web page to the workspace.   This will not download the web page as a attachment,
               but instead will provide an easy way for other users to access the web page in their browser.</p></td>
    </tr>
    <tr>
        <td class="px-5 py-1">
            <button type="button" class="btn btn-primary btn-raised"
                onClick="location.href='WorkspaceCopyMove1.htm'">Copy/Move from Workspace</button>
        </td>
        <td class="py-1">
            <p>You can either copy or move documents, topics, action items, or meetings from another workspace to this one.
            </p>
        </td>
    </tr>
    </table>
    
<% } %> 

</div>
<!-- end addDocument.jsp -->
