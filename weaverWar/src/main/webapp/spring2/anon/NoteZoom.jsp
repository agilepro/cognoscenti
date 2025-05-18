<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.LeafletResponseRecord"
%><%@page import="com.purplehillsbooks.weaver.LicenseForUser"
%><%/*
Required parameter:

    1. pageId : This is the id of a Workspace and used to retrieve NGWorkspace.
    2. topicId: This is id of note (TopicRecord).

*/
    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }


    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    String mnnote = ar.defParam("mnnote", null);
    
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    JSONObject workspaceInfo = ngw.getConfigJSON();

    boolean isLoggedIn = ar.isLoggedIn();

    //there might be a better way to measure this that takes into account
    //magic numbers and tokens
    boolean canComment = ar.canUpdateWorkspace();

    NGBook ngb = ngw.getSite();
    UserProfile uProf = ar.getUserProfile();
    String currentUser = "NOBODY";
    String currentUserName = "NOBODY";
    String currentUserKey = "NOBODY";
    if (isLoggedIn) {
        //this page can be viewed when not logged in, possibly with special permissions.
        //so you can't assume that uProf is non-null
        currentUser = uProf.getUniversalId();
        currentUserName = uProf.getName();
        currentUserKey = uProf.getKey();
    }

    String topicId = ar.reqParam("topicId");
    TopicRecord note = ngw.getNoteOrFail(topicId);
    int topicNumericId = DOMFace.safeConvertInt(topicId);
    boolean canDisplay = AccessControl.canAccessTopic(ar, ngw, note);
    

    if (!canDisplay) {
        throw new Exception("Program Logic Error: this view should only display when user can actually access the note.");
    }

    JSONObject noteInfo = note.getJSONWithComments(ar, ngw);
    JSONArray attachmentList = ngw.getJSONAttachments(ar);
    JSONArray allLabels = ngw.getJSONLabels();

    JSONArray history = new JSONArray();
    for (HistoryRecord hist : note.getNoteHistory(ngw)) {
        history.put(hist.getJSON(ngw, ar));
    }

    JSONArray allGoals     = ngw.getJSONGoals();


    //to access the email-ready page, you need to get the license parameter
    //for this note.  This string saves this for use below on reply to comments
    String specialAccess =  AccessControl.getAccessTopicParams(ngw, note)
                + "&emailId=" + URLEncoder.encode(ar.getBestUserId(), "UTF-8");

%>
<!-- ******************************** anon/NoteZoom.jsp ******************************** -->


<script type="text/javascript">
document.title="<% ar.writeJS(note.getSubject());%>";

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, $interval, AllPeople) {
    window.setMainPageTitle("Discussion Topic");
    $scope.siteInfo = <%ngb.getConfigJSON().write(out,2,4);%>;
    $scope.workspaceInfo = <%workspaceInfo.write(out,2,4);%>;
    $scope.noteInfo = <%noteInfo.write(out,2,4);%>;
    $scope.mainTopicHtml = convertMarkdownToHtml($scope.noteInfo.wiki);
    $scope.topicId = "<%=topicId%>";
    $scope.mnnote = "<%=mnnote%>";
    
    $scope.allDocs = [];
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.canComment = <%=canComment%>;
    $scope.history = <%history.write(out,2,4);%>;
    $scope.allGoals = <%allGoals.write(out,2,4);%>;
    $scope.nonMembers = [];
    $scope.addressMode = false;

    $scope.currentTime = (new Date()).getTime();

    $scope.isEditing = false;
    $scope.item = {};

    $scope.autoRefresh = true;
    $scope.bgActiveLimit = 0;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        $scope.cancelBackgroundTime();
        errorPanelHandler($scope, serverErr);
    };
    
    $scope.shownComments = [];
    $scope.noteInfo.comments.forEach( function (cmt) {
        if (cmt.newPhase) {
            //ignore phase change comments of any kind
            return;
        }
        if (cmt.state==12 || cmt.state==13) {
            $scope.shownComments.push(cmt);
        }
    });

});

</script>
<script src="../../../jscript/AllPeople.js"></script>

<div style="max-width:1000px" ng-cloak>

<%@include file="ErrorPanel.jsp"%>

<div class="container-fluid override mb-4 mx-3 d-inline-flex">
    <span class="dropdown mt-1">
        <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
            data-bs-toggle="dropdown" aria-expanded="false">
        </button>
        <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
            <li>
                <button class="dropdown-item" onclick="window.location.reload(true)">Refresh</button>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" tabindex="-1" ng-click="startEdit()"> Edit This Topic</a></span>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" tabindex="-1"
                        href="pdf/note{{noteInfo.id}}.pdf?publicNotes={{noteInfo.id}}&comments=true"> PDF with
                        Comments</a></span>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" tabindex="-1"
                        href="pdf/note{{noteInfo.id}}.pdf?publicNotes={{noteInfo.id}}"> PDF without Comments</a></span>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" tabindex="-1" ng-click="sendNoteByMail()"> Send Topic By
                        Email</a></span>
                <span class="dropdown-item" type="button" ng-hide="isSubscriber">
                    <a class="nav-link" role="menuitem" tabindex="-1" ng-click="changeSubscription(true)"> Subscribe to
                        this Topic</a></span>
                <span class="dropdown-item" type="button" ng-show="isSubscriber">
                    <a class="nav-link" role="menuitem" tabindex="-1" ng-click="changeSubscription(false)"> Unsubscribe
                        from this Topic</a></span>
                <span class="dropdown-item" type="button">
                    <a class="nav-link" role="menuitem" tabindex="-1" href="NotesList.htm"> List Topics</a></span>
            </li>
        </ul>
    </span>
    <span>
        <h1 class="d-inline page-name" id="mainPageTitle">Discussion Topic</h1>
    </span>
</div>

<div class="container-fluid override mx-2">
    <div class="d-flex col-12">
        <div class="contentColumn">
            <div class="container-fluid">
                <div class="generalContent">
                    <div class="h2" style="{{getPhaseStyle()}}"  ng-hide="isEditing" ng-click="startEdit()" >
                        <i class="fa fa-lightbulb-o" style="font-size:130%"></i>
                        {{noteInfo.subject}}
                    </div>

                    <div class="comment-outer comment-state-active p-2">
                    <div class="comment-inner p-2">
                        <div ng-bind-html="noteInfo.wiki|wiki"></div>
                    </div>
                    

                    <div ng-repeat="cmt in shownComments">
                        <div class="comment-outer p-2">
                        <div class="fs-5 mb-2"><b>{{cmt.time|date:'MMM dd, yyyy - HH:mm'}} - {{cmt.userName}}</b></div>
                        <div class="comment-inner p-2">
                            <div ng-bind-html="cmt.body|wiki"></div>
                        </div>
                        <table ng-show="cmt.responses" class="mt-3">
                            <tr ng-repeat="resp in cmt.responses" ng-show="resp.body">
                            <td class="p-2 ms-2"><i><b>{{resp.userName}}</b></i></td>
                            <td class="p-2">
                                <div ng-bind-html="resp.body|wiki" class="comment-inner p-2" style="min-width:100%">

                                </div>
                            </td> 
                            <td ng-show="cmt.commentType==2"><b>{{resp.choice}}</b></td>
                            </tr>
                        </table>
                        <div class="comment-inner p-2" ng-show="cmt.outcome" style="min-width: 100%">
                            <div ng-bind-html="cmt.outcome|wiki"></div>
                        </div>
                        </div>
                    </div>

                    <div class="m-3 float-end">
                    <a href="Reply.htm?topicId=<%=topicId%>&mnnote=<%=mnnote%>#QuickReply"><button class="btn btn-primary btn-raised btn-default">Make a Reply</button></a>
                    <br>
                    <i>Login to see all options.</i>
                    </div>

</div>


<script src="<%=ar.retPath%>new_assets/templates/ActionItemCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/AttachDocumentCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/AttachActionCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/Feedback.js"></script>
<script src="<%=ar.retPath%>new_assets/jscript/HtmlToMarkdown.js"></script>
<script src="<%=ar.retPath%>new_assets/jscript/HtmlParser.js"></script>
<script src="<%=ar.baseURL%>new_assets/jscript/TextMerger.js"></script>

<%out.flush();%>
