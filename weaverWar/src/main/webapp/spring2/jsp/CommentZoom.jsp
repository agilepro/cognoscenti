<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/spring2/jsp/include.jsp"
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
    
    CommentRecord selectedComment = ngw.getCommentOrNull(cid);
    JSONObject comment = new JSONObject();
    if (selectedComment!=null) {
        comment = selectedComment.getJSONWithDocs(ngw);
    }
    
    JSONObject workspaceInfo = ngw.getConfigJSON();
    JSONArray attachmentList = ngw.getJSONAttachments(ar);

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
    boolean canComment = ar.canUpdateWorkspace();


/* NOTES RECORD PROTOTYPE

*/

%>

<script src="../../new_assets/jscript/AllPeople.js"></script>


<script type="text/javascript">


var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Comment Detail");
    $scope.siteProxy = getSiteProxy("<%ar.writeJS(ar.baseURL);%>", "<%ar.writeJS(siteId);%>");
    $scope.wsProxy = $scope.siteProxy.getWorkspaceProxy("<%ar.writeJS(pageId);%>", $scope);
    
    $scope.siteInfo = <%siteInfo.write(out,2,4);%>;
    $scope.workspaceInfo = <%workspaceInfo.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.comment = <%comment.write(out,2,4);%>;
    
    $scope.containerTypeName = "Discussion Topic";
    $scope.containerTypeNumber = 4;
    if ($scope.comment.containerType == "A") {
        $scope.containerTypeName = "Document";
        $scope.containerTypeNumber = 8;
    }
    if ($scope.comment.containerType == "M") {
        $scope.containerTypeName = "Meeting";
        $scope.containerTypeNumber = 7;
    }
        
    
    $scope.commentExists = <%=selectedComment!=null%>;
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
        if ($scope.comment) {
            return [$scope.comment];
        }
        else {
            return [];
        }
    }
    $scope.cancelBackgroundTime = function() {
        //does not do anything now
    }
    $scope.extendBackgroundTime = function() {
        //does not do anything now
    }
    $scope.defaultProposalAssignees = function() {
        return [];
    }
    
    $scope.tuneNewComment = function(newComment) {
        newComment.containerType = $scope.comment.containerType;
        newComment.containerID = $scope.comment.containerID;
    }
    $scope.tuneNewDecision = function(newDecision, cmt) {
        newDecision.sourceId = cmt.containerID;
        newDecision.sourceType = 4;
        if (cmt.containerType=="M") {
            newDecision.sourceType = 7;
        }
        if (cmt.containerType=="D") {
            newDecision.sourceType = 8;
        }
    }
    $scope.refreshCommentContainer = function() {
        refreshCommentList();
    }
    setUpCommentMethods($scope, $http, $modal);
    
    
    $scope.deleteComment = function(cmt) {
        var newCmt = {};
        newCmt.time = $scope.cid;
        newCmt.deleteMe = true;
        var postdata = angular.toJson(newCmt);
        var postURL = "updateComment.json?cid="+newCmt.time;
        console.log(postURL,newCmt);
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.commentExists = false;
        })
        .error( function(data) {
            $scope.reportError(data);
        });
    }
    
    $scope.allowCommentEmail = function() {
        return true;
    }
    $scope.refreshCommentList = function() {
        var postURL = "getComment.json?cid="+$scope.cid;
        $scope.showError=false;
        $http.get(postURL)
        .success( function(data, status, headers, config) {
            $scope.comment = data;
            $scope.generateCommentHtml($scope.comment);
        })
        .error( function(data, status, headers, config) {
            console.log("   FAILED"+ status, data);
            $scope.reportError(data);
        });
    }
    $scope.generateCommentHtml($scope.comment);
});

</script>
<script src="../../new_assets/jscript/AllPeople.js"></script>

<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

    
     
     
   

    <div style="height:20px;"></div>
    <div class="container mx-md-3">
      <div style="max-width:800px" ng-show="commentExists">
        <div class="row d-flex my-2 py-3 border-1 border-bottom border-top">
          <span class="col-3 ">{{containerTypeName}} Key</span>
          <span class="col-6">{{comment.containerType}}:{{comment.containerID}}</span>
        </div>
        <div class="row d-flex my-2 pt-1 pb-3 border-1 border-bottom ">
          <span class="col-3">{{containerTypeName}} Name</span>
          <span class="col-6"><a href="{{containerLink(comment)}}">{{comment.containerName}}</a></span>
        </div>
        <div class="row d-flex my-2 pt-1 pb-3 border-1 border-bottom" ng-show="comment.replyTo">
          <span class="col-3">Reply To</span>
          <span class="col-6"><a href="CommentZoom.htm?cid={{comment.replyTo}}">{{comment.replyTo|cdate}}</a></span>
        </div>
        <div class="row d-flex my-2 pt-1 pb-3 border-1 border-bottom" ng-repeat="reply in comment.replies">
          <span class="col-3">Reply</span>
          <span class="col-6"><a href="CommentZoom.htm?cid={{reply}}">{{reply|cdate}}</a></span>
        </div>
        <div class="row d-flex my-2 pt-1 pb-3 border-1 border-bottom ">
          <span class="col-3"></span>
          <span class="col-6"><a href="CmtView.wmf?cmtId={{cid}}"><i class="fa fa-bolt"></i> Experimental Mobile UI</a></span>
        </div>
      </div>
      <div class="well" ng-hide="commentExists">
        <div class="row d-flex my-2 pt-1 pb-3 border-1 border-bottom ">
          <span class="col-3">Status</span>
          <span class="col-6">A comment/round/proposal with id {{cid}} not found.  Probably it has been deleted.</span>
        </div>
      </div>
      <div ng-show="commentExists" style="max-width:800px">
        <div class="row d-flex" ng-repeat="cmt in getComments()">
          <%@ include file="CommentView.jsp"%>          
        </div>
      </div>


</div>
<div style="height:200px;"></div>

<script src="<%=ar.retPath%>new_assets/jscript/HtmlToMarkdown.js"></script>
<script src="<%=ar.retPath%>new_assets/jscript/HtmlParser.js"></script>
<script src="<%=ar.baseURL%>new_assets/jscript/TextMerger.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/CommentModal.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/ResponseModal.js"></script>  
<script src="<%=ar.retPath%>new_assets/templates/AttachDocumentCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/DecisionModal.js"></script>