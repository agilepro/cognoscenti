<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.CommentRecord"
%><%


    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    ar.assertLoggedIn("Comment page designed for people logged in");
    
    NGBook ngb = ngw.getSite();
    
    JSONObject siteInfo = ngb.getConfigJSON();
    siteInfo.put("frozen", ngb.isFrozen());
    
    JSONArray allComments = new JSONArray();
    for (CommentRecord comm : ngw.getAllComments()) {
        allComments.put(comm.getJSONWithDocs(ngw));
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

%>

<style>
    .meeting-icon {
       cursor:pointer;
       color:LightSteelBlue;
    }

</style>
<script src="../../new_assets/jscript/AllPeople.js"></script>


<script type="text/javascript">


var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Comments");
    $scope.siteProxy = getSiteProxy("<%ar.writeJS(ar.baseURL);%>", "<%ar.writeJS(siteId);%>");
    $scope.wsProxy = $scope.siteProxy.getWorkspaceProxy("<%ar.writeJS(pageId);%>", $scope);
    
    $scope.siteInfo = <%siteInfo.write(out,2,4);%>;
    $scope.workspaceInfo = <%workspaceInfo.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.allComments = <%allComments.write(out,2,4);%>;
    $scope.canComment = <%=canComment%>;
    $scope.filter = "";
    $scope.showVizPub = true;
    $scope.showVizMem = true;
    $scope.showVizDel = false;
    $scope.filterMap = {};
    $scope.openMap = {};
    $scope.showFilter = <%=ar.isLoggedIn()%>;
    $scope.filterOpen = true;
    $scope.filterClosed = true;
    $scope.filterDraft = true;
    $scope.initialFetchDone = false;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.getComments = function() {
        var retSet = [];
        var filterlist = parseLCList($scope.filter);
        $scope.allComments.forEach( function(aCmt) {
            if (aCmt.state==13) {
                if (!$scope.filterClosed) {
                    return;
                }
            }
            else if (aCmt.state==12) {
                if (!$scope.filterOpen) {
                    return;
                }
            }
            else if (aCmt.state==11) {
                if (!$scope.filterDraft) {
                    return;
                }
            }
            if (containsOne(aCmt.body, filterlist)) {
                retSet.push(aCmt);
            }
        });
        return retSet;
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
        //can't reallly do anything here
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
    setUpCommentMethods($scope, $http, $modal);

    
    $scope.allowCommentEmail = function() {
        return true;
    }
    $scope.refreshCommentList = function() {
        var postURL = "getCommentList.json";
        $scope.showError=false;
        $http.get(postURL)
        .success( function(data, status, headers, config) {
            $scope.allComments = data.list;
            generateAllHtml();
        })
        .error( function(data, status, headers, config) {
            console.log("   FAILED"+ status, data);
            $scope.reportError(data);
        });
    }
    
    function generateAllHtml() {
        $scope.allComments.forEach( function(cmt) {
            $scope.generateCommentHtml(cmt);
        });
    }
    generateAllHtml();
    
});

</script>

<div class="container-fluid override mb-4 mx-3 d-inline-flex">
    <span class="dropdown mt-1">
        <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
            data-bs-toggle="dropdown" aria-expanded="false">
        </button>
        <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
            <li>
                <button class="dropdown-item" onclick="window.location.reload(true)">Refresh</button>
            </li>
        </ul>
    </span>
    <span>
        <h1 class="d-inline page-name" id="mainPageTitle">All Comments List</h1>
    </span>
</div>
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

<div class="container-fluid override">
    <div class="well">
        Filter <input ng-model="filter"> &nbsp;
        <input type="checkbox" ng-model="filterDraft"> Draft &nbsp;
        <input type="checkbox" ng-model="filterOpen"> Open &nbsp;
        <input type="checkbox" ng-model="filterClosed"> Closed &nbsp;
    </div>
    <div style="height:20px;"></div>
      <div class="table col-8">
        <div class="row my-3 ms-3" ng-repeat="cmt in getComments()">
          <%@ include file="/spring2/jsp/CommentView.jsp" %>          
        </div>
    </div>
        
    
       
</div>





<script src="<%=ar.retPath%>new_assets/jscript/HtmlToMarkdown.js"></script>
<script src="<%=ar.retPath%>new_assets/jscript/HtmlParser.js"></script>
<script src="<%=ar.baseURL%>new_assets/jscript/TextMerger.js"></script>