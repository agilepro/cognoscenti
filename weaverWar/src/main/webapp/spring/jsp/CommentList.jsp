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
    


/* NOTES RECORD PROTOTYPE
    $scope.notes = [
      {
        "comments": [
          {
            "content": "this is a comment",
            "time": 1435036060903,
            "user": "kswenson@us.fujitsu.com"
          },
          {
            "content": "another comment",
            "time": 1435036329093,
            "user": "kswenson@us.fujitsu.com"
          }
        ],
        "deleted": false,
        "docList": [],
        "draft": false,
        "html": "<h1>Minutes for Meeting: Status Update for May 19\n<\/h1><p>...\n<\/p>\n",
        "id": "6314",
        "labelMap": {},
        "modTime": 1434492969035,
        "modUser": {
          "name": "Keith Swenson",
          "uid": "kswenson@us.fujitsu.com"
        },
        "pin": 0,
        "public": false,
        "subject": "Minutes for Meeting: Status Update for May 19",
        "universalid": "MAPZIUHWG@test-for-john@6314"
      },
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
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.allComments = <%allComments.write(out,2,4);%>;
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
        return $scope.allComments;
    }
    $scope.openCommentEditor = function (itemNotUsed, cmt) {
        extendBackgroundTime();
        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\Comments can not be modified in a frozen workspace.");
            return;
        }
        var modalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>templates/CommentModal.html<%=templateCacheDefeater%>',
            controller: 'CommentModalCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                cmt: function () {
                    return cmt;
                },
                attachmentList: function() {
                    return $scope.attachmentList;
                },
                docSpaceURL: function() {
                    return $scope.docSpaceURL;
                },
                parentScope: function() { return $scope; },
                siteId: function() {return $scope.siteInfo.key}
            }
        });

        modalInstance.result.then(function (returnedCmt) {
            refreshCommentList();
        }, function () {
            //cancel action - nothing really to do
            refreshCommentList();
        });
    };
    
    function extendBackgroundTime() {
        //does not do anything now
    }
    $scope.allowCommentEmail = function() {
        return true;
    }
    function refreshCommentList() {
        var postURL = "getCommentList.json";
        console.log("GET:", postURL);
        $scope.showError=false;
        $http.get(postURL)
        .success( function(data, status, headers, config) {
            console.log("   GOT IT"+ status, data);
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
        <span style="vertical-align:middle;" ><input type="checkbox" ng-model="showVizDel">
            Deleted</span> &nbsp;
        <span class="dropdown" ng-repeat="role in allLabelFilters()">
            <button class="labelButton" type="button" id="menu2"
               data-toggle="dropdown" style="background-color:{{role.color}};"
               ng-show="hasLabel(role.name)">{{role.name}} <i class="fa fa-close"></i></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
               <li role="presentation"><a role="menuitem" title="{{add}}"
                  ng-click="toggleLabel(role)">Remove Filter:<br/>{{role.name}}</a></li>
            </ul>
        </span>
        <span>
             <span class="dropdown">
               <button class="btn btn-sm btn-primary btn-raised dropdown-toggle" type="button" id="menu2" data-toggle="dropdown"
                       title="Add Filter by Label"><i class="fa fa-filter"></i></button>
               <ul class="dropdown-menu" role="menu" aria-labelledby="menu1" 
                   style="width:320px;left:-130px">
                 <li role="presentation" ng-repeat="rolex in allLabels" style="float:left">
                     <button role="menuitem" tabindex="-1" ng-click="toggleLabel(rolex)" class="labelButton" 
                     ng-hide="hasLabel(rolex.name)" style="background-color:{{rolex.color}}">
                         {{rolex.name}}</button>
                 </li>
               </ul>
             </span>
        </span>
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

      <table>
        <tr ng-repeat="cmt in getComments()">
          <%@ include file="/spring/jsp/CommentView.jsp"%>          
        </tr>
      </table>
        
    
       
</div>





<script src="<%=ar.retPath%>templates/CommentModal.js"></script><script src="<%=ar.retPath%>jscript/HtmlToMarkdown.js"></script>
<script src="<%=ar.retPath%>jscript/HtmlParser.js"></script>
<script src="<%=ar.baseURL%>jscript/TextMerger.js"></script>