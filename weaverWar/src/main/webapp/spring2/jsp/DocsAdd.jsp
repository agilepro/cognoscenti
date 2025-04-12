<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
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
<div class="container-fluid override mb-4 mx-3 d-inline-flex">
    <span class="dropdown mt-1">
        <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
            data-bs-toggle="dropdown" aria-expanded="false">
        </button>
        <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
            <li>
                <button class="dropdown-item" onclick="window.location.reload(true)">
                    Refresh</button>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" href="DocsList.htm">
                        List View</a></span>
            </li>
        </ul>
    </span>
    <span>
        <h1 class="d-inline page-name" id="mainPageTitle">Add Document Methods</h1>
    </span>
</div>

<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>
<div class="container-fluid override">
    <div class="row">
<% if (userReadOnly) { %>

<div class="guideVocal" style="margin-top:80px">
    You are not allowed to add a document to the workspace, because
    you are not in a role that allows update.  
    You can access documents, but you can not add them or update them.
    
    If you wish to add a document, speak to the owner of this 
    workspace / site and have your membership level changed to a
    paid user in a role that allows update.
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

    <div class="container-fluid override mx-3">
    <table>

    <tr>
        <td colspan="3" class="ms-3 p-3 h5">How do you want to attach the file?</td>
    </tr>
    <tr>
        <td class="px-5 py-1">
            <button class="btn btn-primary btn-default btn-raised" onClick="location.href='DocsUpload.htm<%=folderPart%>'">Upload Files</button>
        </td>
        <td class="py-1 h6">Take files from your local disk, and using your browser upload them to the workspace.</p>
        </td>
    </tr>
    <tr>
        <td class="px-5 py-1">
            <button type="button" class="btn btn-primary btn-raised btn-default"
                onClick="location.href='linkURLToProject.htm<%=folderPart%>'">Link URL</button>
        </td>
        <td class="py-1 h6">Link a web page to the workspace.   This will not download the web page as a attachment,
               but instead will provide an easy way for other users to access the web page in their browser.</td>
    </tr>
    <tr>
        <td class="px-5 py-1">
            <button type="button" class="btn btn-primary btn-raised btn-default"
                onClick="location.href='WorkspaceCopyMove1.htm'">Copy/Move from Workspace</button>
        </td>
        <td class="py-1 h6">You can either copy or move documents, discussions, action items, or meetings from another workspace to this one.
            </p>
        </td>
    </tr>
    </table>
    </div>
    
<% } %> 

</div>
<!-- end addDocument.jsp -->
