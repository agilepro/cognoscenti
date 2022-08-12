<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
    ar.assertLoggedIn("You need to Login to Upload a file.");
    String pageId = ar.reqParam("pageId");
    String folderVal = ar.defParam("folder", null);
    List<String> folders = UtilityMethods.splitString(folderVal, '|');
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
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
    
    boolean userReadOnly = ar.isReadOnly(); 
%>

<script>
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
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

<% if (userReadOnly) { %>

<div class="guideVocal" style="margin-top:80px">
    You are not allowed to add a document to the workspace, because
    you are a passive 'read-only' user.  You can access documents, but you can 
    not add them or update them.
    
    If you wish to add a document, speak to the administrator of this 
    workspace / site and have your membership level changed to an
    active user.
</div>

<% } else { %>

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
            <button class="btn btn-primary btn-raised" onClick="location.href='DocsUpload.htm<%=folderPart%>'">Upload Files</button>
        </td>
        <td style="padding:15px">
            <p>Take files from your local disk, and using your browser upload them to the workspace.</p>
        </td>
    </tr>
    <tr style="height:50px;padding:15px">
        <td style="padding:15px">
            <button type="button" class="btn btn-primary btn-raised"
                onClick="location.href='linkURLToProject.htm<%=folderPart%>'">Link URL</button>
        </td>
        <td style="padding:15px"><p>Link a web page to the workspace.   This will not download the web page as a attachment,
               but instead will provide an easy way for other users to access the web page in their browser.</p></td>
    </tr>
    <tr style="height:50px;padding:15px">
        <td style="padding:15px">
            <button type="button" class="btn btn-primary btn-raised"
                onClick="location.href='linkGoogleDoc.htm<%=folderPart%>'">Attach Google Doc</button>
        </td>
        <td style="padding:15px">
            <p>Weaver can access documents from Google Drive, also known as
            Google Docs.  You have to log in to Google Drive, and then this will
            help you locate the document, and save the link for that into your Weaver workspace.
            Note: others may not be able to access it!
            </p>
        </td>
    </tr>
    <tr style="height:50px;padding:15px">
        <td style="padding:15px">
            <button type="button" class="btn btn-primary btn-raised"
                onClick="location.href='WorkspaceCopyMove1.htm'">Copy/Move from Workspace</button>
        </td>
        <td style="padding:15px">
            <p>You can either copy or move documents, topics, action items, or meetings from another workspace to this one.
            </p>
        </td>
    </tr>
    </table>
    
<% } %> 

</div>
<!-- end addDocument.jsp -->
