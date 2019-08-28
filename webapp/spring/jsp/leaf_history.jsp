<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId : This is the id of a Workspace and here it is used to retrieve NGWorkspace.

*/

    ar.assertLoggedIn("Must be logged in to see a list of meetings");

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();

    List<HistoryRecord> histRecs = ngp.getAllHistory();
    JSONArray allHistory = new JSONArray();
    for (HistoryRecord hist : histRecs) {
        AddressListEntry ale = new AddressListEntry(hist.getResponsible());
        UserProfile responsible = ale.getUserProfile();
        String imagePath = "assets/photoThumbnail.gif";
        if(responsible!=null) {
            String imgPath = responsible.getImage();
            if (imgPath!=null && imgPath.length() > 0) {
                imagePath = "users/"+imgPath;
            }
        }
        String objectKey = hist.getContext();
        int contextType = hist.getContextType();
        String key = hist.getCombinedKey();
        String url = hist.lookUpURL(ar, ngp);
        String objName = hist.lookUpObjectName(ngp);

/*
        if (contextType == HistoryRecord.CONTEXT_TYPE_PROCESS) {
            url = ar.getResourceURL(ngp, "projectAllTasks.htm");
            objName = "";
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_TASK) {
            url = ar.getResourceURL(ngp, "task"+objectKey+".htm");
            GoalRecord gr = ngp.getGoalOrNull(objectKey);
            if (gr!=null) {
                objName = gr.getSynopsis();
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_PERMISSIONS) {
            url = ar.getResourceURL(ngp, "findUser.htm?id=")+URLEncoder.encode(objectKey, "UTF-8");
            objName = objectKey;
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_DOCUMENT) {
            url = ar.getResourceURL(ngp, "docinfo"+objectKey+".htm");
            AttachmentRecord att = ngp.findAttachmentByID(objectKey);
            if (att!=null) {
                objName = att.getDisplayName();
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_LEAFLET) {
            url = ar.getResourceURL(ngp, "noteZoom"+objectKey+".htm");
            TopicRecord nr = ngp.getDiscussionTopic(objectKey);
            if (nr!=null) {
                objName = nr.getSubject();
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_ROLE) {
            url = ar.getResourceURL(ngp, "roleManagement.htm");
            NGRole role = ngp.getRole(objectKey);
            if (role!=null) {
                objName = role.getName();
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_MEETING) {
            url = ar.getResourceURL(ngp, "meetingFull.htm?id="+objectKey);
            MeetingRecord meet = ngp.findMeetingOrNull(objectKey);
            if (meet!=null) {
                objName = meet.getName() + " @ " + SectionUtil.getNicePrintDate( meet.getStartTime() );
            }
        }
        */

        JSONObject jObj = hist.getJSON(ngp,ar);
        jObj.put("responsible", ale.getJSON() );
        if (responsible!=null) {
            jObj.put("respUrl",     "v/"+responsible.getKey()+"/userSettings.htm" );
        }
        else {
            jObj.put("respUrl",     "findUser.htm?id="+URLEncoder.encode(ale.getUniversalId(),"UTF-8") );
        }
        jObj.put("respName",    ale.getName() );
        jObj.put("imagePath",   imagePath );
        jObj.put("contextUrl",  url );
        allHistory.put(jObj);
    }

%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Activity Stream");
    $scope.allHistory = <%allHistory.write(out,2,4);%>;
    $scope.filter = "";

    $scope.showInput = false;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.processTemplate = function(hist) {
        return hist.template;
    }

    $scope.getHistory = function() {
        var filterlist = parseLCList($scope.filter);
        if (filterlist.length==0) {
            return $scope.allHistory;
        }
        var res = [];
        $scope.allHistory.forEach(  function(hItem) {
            if (containsOne(hItem.responsible.name, filterlist)) {
                res.push(hItem);
            }
            else if (containsOne(hItem.ctxName, filterlist)) {
                res.push(hItem);
            }
            else if (containsOne(hItem.comments, filterlist)) {
                res.push(hItem);
            }
            else if (containsOne(hItem.ctxType, filterlist)) {
                res.push(hItem);
            }
            else if (containsOne(hItem.event, filterlist)) {
                res.push(hItem);
            }
        });
        return res;
    }
});
</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div style="margin-bottom:30px;">
        Filter <input ng-model="filter">
    </div>

    <table>

        <tr ng-repeat="hist in getHistory()"  >
            <td class="projectStreamIcons" style="padding-bottom:20px;">
                <img class="img-circle" src="<%=ar.retPath%>{{hist.imagePath}}" alt="" width="50" height="50" />
            </td>
            <td class="projectStreamText" style="padding-bottom:10px;">
                {{hist.time|date}} -
                <a href="<%=ar.retPath%>{{hist.respUrl}}"><span class="red">{{hist.respName}}</span></a>
                <br/>
                {{hist.ctxType}} "<a href="<%=ar.retPath%>{{hist.contextUrl}}">{{hist.ctxName}}</a>"
                was {{hist.event}}.
                <br/>
                <i>{{hist.comments}}</i>

            </td>
        </tr>

    </table>

</div>
