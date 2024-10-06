<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.SharePortRecord"
%><%@ include file="/include.jsp"
%><%

    String taskId      = ar.reqParam("taskId");
    String pageId  = ar.reqParam("pageId");
    String siteId  = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);

    JSONArray allLabels = ngw.getJSONLabels();
    GoalRecord actionItem = ngw.getGoalOrFail(taskId);
    JSONObject actionItemObj = actionItem.getJSON4Goal(ngw);

    JSONObject stateName = new JSONObject();
    stateName.put("0", BaseRecord.stateName(0));
    stateName.put("1", BaseRecord.stateName(1));
    stateName.put("2", BaseRecord.stateName(2));
    stateName.put("3", BaseRecord.stateName(3));
    stateName.put("4", BaseRecord.stateName(4));
    stateName.put("5", BaseRecord.stateName(5));
    stateName.put("6", BaseRecord.stateName(6));
    stateName.put("7", BaseRecord.stateName(7));
    stateName.put("8", BaseRecord.stateName(8));
    stateName.put("9", BaseRecord.stateName(9));
    
    JSONObject cUser = new JSONObject();
    if (ar.isLoggedIn()) {
        cUser = ar.getUserProfile().getJSON();
    }
   
%>



<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Action Item");
    $scope.actionItem = <%actionItemObj.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.nowTime = new Date().getTime();
    $scope.stateName = <%stateName.write(out,2,4);%>;
    $scope.cUser = <%cUser.write(out,2,4);%>;
    
    $scope.acessDocument = function (doc) {
        if (doc.attType=="URL") {
            window.open(doc.url,'_blank');
        }
        else {
            window.location = "../a/"+encodeURI(doc.name)+"?"+doc.access;
        }
    }
    
});

function reloadIfLoggedIn() {
    if (SLAP.loginInfo.verified) {
        window.location = "<%= ar.getCompleteURL() %>";
    }
}
</script>




<style>
.fieldName {
    max-width:150px;
}
.border30 {
    padding:30px;
}
</style>  

<div class="border30" ng-cloak  >

<%@ include file="AnonNavBar.jsp" %>
  
    <div ng-app="myApp" ng-controller="myCtrl">

        <table class="table">
        <tr><td class="fieldName">Synopsis</td><td>{{actionItem.synopsis}}</td></tr>
        <tr><td class="fieldName">Description</td><td>{{actionItem.description}}</td></tr>
        <tr><td class="fieldName">State</td><td><img src="<%=ar.retPath%>assets/goalstate/small{{actionItem.state}}.gif">
            {{stateName[actionItem.state]}}</td></tr>
        <tr><td class="fieldName">Assigned</td><td>
            <div ng-repeat="person in actionItem.assignTo"><a href="<%= ar.retPath%>v/{{person.key}}/PersonShow.htm">{{person.name}}</a></div></td></tr>
        <tr ng-show="actionItem.duedate>100000">
            <td class="fieldName">Due Date</td><td>{{actionItem.duedate|date}}</td></tr>
        <tr ng-show="actionItem.startdate>100000">
            <td class="fieldName">Start Date</td><td>{{actionItem.startdate|date}}</td></tr>
        <tr ng-show="actionItem.enddate>100000">
            <td class="fieldName">End Date</td><td>{{actionItem.enddate|date}}</td></tr>
        <tr><td class="fieldName">Workspace</td><td>{{actionItem.sitename}} / 
            <a href="FrontPage.htm">{{actionItem.projectname}}</a></td></tr>
        <tr ng-show="actionItem.duedate>100000">
            <td class="fieldName">Last Updated</td><td>{{actionItem.modifiedtime|date}}</td></tr>
        <tr><td class="fieldName">You</td><td>{{cUser.name}}</td></tr>
        </table>

    </div>
    
    <div>
        Please  
        <button class="btn btn-primary btn-raised" onClick="SLAP.loginUserRedirect()">
            Login
        </button>
        to find out more.
    </div>
    
  </div>





