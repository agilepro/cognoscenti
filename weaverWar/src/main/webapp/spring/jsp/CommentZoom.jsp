<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@page import="com.purplehillsbooks.weaver.CommentRecord"
%><%@page import="com.purplehillsbooks.xml.Mel"
%><%


    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    long cid = Mel.safeConvertLong(ar.reqParam("cid"));
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    ar.assertLoggedIn("Comment page designed for people logged in");
    
    NGBook ngb = ngw.getSite();
    
    JSONObject siteInfo = ngb.getConfigJSON();
    siteInfo.put("frozen", ngb.isFrozen());
    
    CommentRecord selectedComment = ngw.getCommentOrFail(cid);
    JSONObject comment = selectedComment.getHtmlJSON(ar);
    
    JSONObject workspaceInfo = ngw.getConfigJSON();
    JSONArray attachmentList = ngw.getJSONAttachments(ar);
    
    boolean isMember = ar.isMember();

    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }
    
    UserProfile up = ar.getUserProfile();
    String currentUser = up.getUniversalId();
    String currentUserName = up.getName();
    String currentUserKey = up.getKey();

    JSONArray allLabels = ngw.getJSONLabels();
    boolean canComment = ar.isMember();



/* NOTES RECORD PROTOTYPE

*/

%>

<style>
    .meeting-icon {
       cursor:pointer;
       color:LightSteelBlue;
    }

</style>
<script src="../../../jscript/AllPeople.js"></script>


<script type="text/javascript">


var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Comment Detail");
    $scope.siteProxy = getSiteProxy("<%ar.writeJS(ar.baseURL);%>", "<%ar.writeJS(siteId);%>");
    $scope.wsProxy = $scope.siteProxy.getWorkspaceProxy("<%ar.writeJS(pageId);%>", $scope);
    
    $scope.siteInfo = <%siteInfo.write(out,2,4);%>;
    $scope.workspaceInfo = <%workspaceInfo.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.comment = <%comment.write(out,2,4);%>;
    $scope.canComment = <%=canComment%>;
    $scope.cid = <%= cid %>;
    $scope.filter = "";
    $scope.showVizPub = true;
    $scope.showVizMem = true;
    $scope.showVizDel = false;
    $scope.filterMap = {};
    $scope.openMap = {};
    $scope.showFilter = <%=ar.isLoggedIn()%>;
    $scope.initialFetchDone = false;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.getComments = function() {
        return [$scope.comment];
    }
    $scope.extendBackgroundTime = function() {
        //does not do anything now
    }
    $scope.defaultProposalAssignees = function() {
        return [];
    }
    $scope.setContainerFields = function(newComment) {
        newComment.containerType = $scope.comment.containerType;
        newComment.containerID = $scope.comment.containerID;
    }
    
    setUpCommentMethods($scope, $http, $modal);
    $scope.deleteComment = function(cmt) {
        //single page cant handle this
        alert("In this mode comment delete is not allowed.  Instead, go to "
        +"the place where the comment is listed and delete there");
    }
    
    $scope.allowCommentEmail = function() {
        return true;
    }
    $scope.refreshCommentList = function() {
        console.log("REFRESHING single comment");
        var postURL = "getComment.json?cid="+$scope.cid;
        console.log("GET:", postURL);
        $scope.showError=false;
        $http.get(postURL)
        .success( function(data, status, headers, config) {
            $scope.comment = data;
        })
        .error( function(data, status, headers, config) {
            console.log("   FAILED"+ status, data);
            $scope.reportError(data);
        });
    }
});

</script>
<script src="../../../jscript/AllPeople.js"></script>

<div>

<%@include file="ErrorPanel.jsp"%>

    
     
     
    <style>
    .regularTopic {
        border: 1px solid lightgrey;
        border-radius:10px;
        margin-top:20px;
        padding:5px;
        background-color:#F8EEEE;
    }
    .draftTopic {
        border: 1px solid lightgrey;
        border-radius:10px;
        margin-top:20px;
        padding:5px;
        background-color:yellow;
    }
    .trashTopic {
        border: 1px solid lightgrey;
        border-radius:10px;
        margin-top:20px;
        padding:5px;
        background-color:pink;
    }
    .infoRow {
        min-height:35px;
        padding:5px;
    }
    .infoRow td {
        padding:5px 10px;
    }

    </style>

    <div style="height:20px;"></div>
    
      <table class="table" style="max-width:600px">
        <tr>
          <td>Container Key</td>
          <td>{{comment.containerType}}:{{comment.containerID}}</td>
        </tr>
        <tr>
          <td>Container Name</td>
          <td><a href="{{containerLink(comment)}}">{{comment.containerName}}</a></td>
        </tr>
        <tr ng-show="comment.replyTo">
          <td>Reply To</td>
          <td><a href="CommentZoom.htm?cid={{comment.replyTo}}">Comment {{comment.replyTo|date}}</a></td>
        </tr>
        <tr ng-repeat="reply in comment.replies">
          <td>Reply</td>
          <td><a href="CommentZoom.htm?cid={{reply}}">Comment {{reply|date}}</a></td>
        </tr>
      </table>

      <table>
        <tr ng-repeat="cmt in getComments()">
          <%@ include file="/spring/jsp/CommentView.jsp"%>          
        </tr>
      </table>
        
    
       
</div>

    <div style="height:200px;"></div>
    



<script src="<%=ar.retPath%>jscript/HtmlToMarkdown.js"></script>
<script src="<%=ar.retPath%>jscript/HtmlParser.js"></script>
<script src="<%=ar.baseURL%>jscript/TextMerger.js"></script>