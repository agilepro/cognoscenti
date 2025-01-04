<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%
    ar.assertLoggedIn("You need to Login to add something to the workspace.");
    String pageId = ar.reqParam("pageId");
    String folderVal = ar.defParam("folder", null);
    String startMode = ar.defParam("start", "none");
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
    
    JSONArray allMeetings = new JSONArray();
    for (MeetingRecord meet : ngp.getMeetings()) {
        allMeetings.put(meet.getMinimalJSON());
    }
%>

<script>
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Add Something to Workspace");
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.folderMap = <%folderMap.write(out,2,4);%>;
    $scope.showSection = "<%ar.writeJS(startMode);%>";
    $scope.showMeeting = false;
    $scope.meetings = <%allMeetings.write(out,2,4);%>;
    $scope.meetingToClone = {};
    $scope.findLabels = function() {
        var res = [];
        $scope.allLabels.map( function(item) {
            if ($scope.folderMap[item.name]) {
                res.push(item);
            }
        });
        return res;
    }
    $scope.toggleShowSection = function(mode) {
        if ($scope.showSection == mode) {
            $scope.showSection = 'none';
        }
        else {
            $scope.showSection = mode;
        }
    }
    $scope.createDiscussion = function() {
        window.location = "NotesList.htm?start=create";
    }
    $scope.createGoal = function() {
        window.location = "GoalStatus.htm?start=create";
    }
    
    $scope.cloneMeeting = function() {
        window.location = "CloneMeeting.htm?id="+$scope.meetingToClone.id;
    }
    $scope.createEmptyMeeting = function() {
        window.location = "MeetingCreate.htm";
    }
    $scope.createDecision = function() {
        window.location = "DecisionList.htm?start=create";
    }
    $scope.createEmail = function() {
        window.location = "SendNote.htm";
    }
    
});
</script>
<style>
table tr td {
    padding:15px;
}
</style>

<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

<% if (userReadOnly) { %>

<div class="guideVocal" style="margin-top:80px">
    You are not allowed to add to the workspace, because
    you are a passive 'read-only' user.  You can access documents, but you can 
    not add them or update them.
    
    If you wish to add a document, speak to the administrator of this 
    workspace / site and have your membership level changed to an
    active user.
</div>

<% } else { %>

    <div class="generalHeading override" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Create
        </div>
    </div>

    <table>

    <tr>
        <td ng-click="toggleShowSection('meeting')">
            <button class="btn btn-default btn-raised" >Create Meeting</button>
        </td>
        <td>
            <div ng-show="showSection=='meeting'">
                Clone Meeting From 
                <select class="form-control" ng-model="meetingToClone" 
                        ng-options="x.name for x in meetings" 
                        style="width:300px"></select>
                <button class="btn btn-primary btn-raised" ng-click="cloneMeeting()"/>Clone Meeting</button><br/>
                <button class="btn btn-primary btn-raised" ng-click="createEmptyMeeting()"/>Create Empty Meeting</button>
            </div>
            <div ng-hide="showSection=='meeting'">
                Create a meeting record to prepare for and hold a meeting with people in this circle.
            <div>
        </td>
    </tr>
    <tr>
        <td ng-click="toggleShowSection('discussion')">
            <button class="btn btn-default btn-raised" >Create Discussion</button>
        </td>
        <td>
            <div ng-show="showSection=='discussion'">
                <button class="btn btn-primary btn-raised" ng-click="createDiscussion()"/>Create Discussion</button>
            </div>
            <div ng-hide="showSection=='discussion'">
                Create a topic for a discussion with others in the circle.
            <div>
        </td>
    </tr>
    <tr>
        <td ng-click="toggleShowSection('goal')">
            <button class="btn btn-default btn-raised" >Create Action Item</button>
        </td>
        <td>
            <div ng-show="showSection=='goal'">
                <button class="btn btn-primary btn-raised" ng-click="createGoal()"/>Create Action Item</button>
            </div>
            <div ng-hide="showSection=='goal'">
                Create a topic for a discussion with others in the circle.
            <div>
        </td>
    </tr>
    <tr>
        <td ng-click="toggleShowSection('docs')">
            <button class="btn btn-default btn-raised" >Attach Document</button>
        </td>
        <td>
            <div ng-show="showSection=='docs'">
                <p><button class="btn btn-primary btn-raised" 
                    onClick="location.href='DocsUpload.htm<%=folderPart%>'">Upload Files</button>
                    Take files from your local disk, and using your browser upload them to the workspace.</p>
                <p><button type="button" class="btn btn-primary btn-raised"
                    onClick="location.href='linkURLToProject.htm<%=folderPart%>'">Link URL</button>
                    Link a web page to the workspace.   This will not download the web page as a attachment,
                but instead will provide an easy way for other users to access the web page in their browser.</p>
                
                <p><button type="button" class="btn btn-primary btn-raised"
                    onClick="location.href='DocLinkGoogle.htm<%=folderPart%>'">Attach Google Doc</button>
                    Access documents from Google Drive </p>
                
                <p><button type="button" class="btn btn-primary btn-raised"
                    onClick="location.href='WorkspaceCopyMove1.htm'">Copy/Move from Workspace</button>
                    You can either copy or move documents, discussions, action items, or meetings from another workspace to this one.</p> 
                                
            </div>
            <div ng-hide="showSection=='docs'">
                You can either upload a file from your dist, attach a file using a URL, attached a document from Google Docs, or copy/move a document from another workspace.
            <div>
        </td>
    </tr>
    <tr>
        <td ng-click="toggleShowSection('decision')">
            <button class="btn btn-default btn-raised" >Create Decision</button>
        </td>
        <td>
            <div ng-show="showSection=='decision'">
                <button class="btn btn-primary btn-raised" ng-click="createDecision()"/>Create Decision</button>
            </div>
            <div ng-hide="showSection=='decision'">
                Create a decision for the workspace.
            <div>
        </td>
    </tr>
    <tr>
        <td ng-click="toggleShowSection('email')">
            <button class="btn btn-default btn-raised" >Create Email</button>
        </td>
        <td>
            <div ng-show="showSection=='email'">
                <button class="btn btn-primary btn-raised" ng-click="createEmail()"/>Create Email</button>
            </div>
            <div ng-hide="showSection=='email'">
                Create an email message.
            <div>
        </td>
    </tr>
    </table>
    
<% } %> 

    <div style="height:150px"></div>

</div>
<!-- end addDocument.jsp -->
