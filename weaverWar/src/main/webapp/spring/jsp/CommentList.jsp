<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.NGRole"
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
        allComments.put(comm.getHtmlJSON(ar));
    }
    
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
    $scope.comment = {
      "choices": [],
      "commentType": 1,
      "containerID": "8505",
      "containerName": "DSC03885.jpg",
      "containerType": "A",
      "decision": "",
      "docList": [],
      "dueDate": 1639946254880,
      "emailPending": false,
      "excludeSelf": false,
      "html": "<p>\nThis is a comment on a document called  <b>DSC03885.jpg<\/b>\n<\/p>\n<p>\nThis is a picture of Devil's Postpile!\n<\/p>\n<p>\n \n<\/p>\n<p>\n \n<\/p>\n",
      "includeInMinutes": false,
      "newPhase": "",
      "notify": [],
      "outcome": "",
      "poll": false,
      "postTime": 1639341514618,
      "replies": [],
      "replyTo": 0,
      "responses": [],
      "state": 13,
      "suppressEmail": false,
      "time": 1639341464671,
      "user": "kswenson@pobox.com",
      "userKey": "j9iyux0nhu6mh9n2",
      "userName": "Keith ॐ Swenson"
    };

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
    window.setMainPageTitle("All Comments List");
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
    $scope.initialFetchDone = false;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.getComments = function() {
        if (!$scope.filter) {
            return $scope.allComments;
        }
        var retSet = [];
        var filterlist = parseLCList($scope.filter);
        $scope.allComments.forEach( function(aCmt) {
            console.log("looking at "+aCmt.time);
            if (containsOne(aCmt.html, filterlist)) {
                retSet.push(aCmt);
            }
        });
        return retSet;
    }
    $scope.extendBackgroundTime = function() {
        //does not do anything now
    }
    $scope.defaultProposalAssignees = function() {
        return [];
    }
    
    setUpCommentMethods($scope, $http, $modal);

    
    $scope.allowCommentEmail = function() {
        return true;
    }
    $scope.refreshCommentList = function() {
        var postURL = "getCommentList.json";
        console.log("GET:", postURL);
        $scope.showError=false;
        $http.get(postURL)
        .success( function(data, status, headers, config) {
            $scope.allComments = data.list;
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

    
    <div class="well">
        Filter <input ng-model="filter"> &nbsp;
    </div>
     
     
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

      <table style="max-width:800px">
        <tr ng-repeat="cmt in getComments()">
          <%@ include file="/spring/jsp/CommentView.jsp"%>          
        </tr>
      </table>
        
    
       
</div>





<script src="<%=ar.retPath%>templates/CommentModal.js"></script>
<script src="<%=ar.retPath%>templates/ResponseModal.js"></script>
<script src="<%=ar.retPath%>jscript/HtmlToMarkdown.js"></script>
<script src="<%=ar.retPath%>jscript/HtmlParser.js"></script>
<script src="<%=ar.baseURL%>jscript/TextMerger.js"></script>