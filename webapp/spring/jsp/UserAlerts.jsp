<%@page import="org.socialbiz.cog.NotificationRecord"%>
<%@page errorPage="/spring/jsp/error.jsp"
%><%@include file="/spring/jsp/include.jsp"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="java.util.ArrayList"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.DailyDigest"
%><%@page import="org.socialbiz.cog.EmailSender"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.SuperAdminLogFile"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.WatchRecord"
%><%@page import="org.socialbiz.cog.rest.TaskHelper"
%><%@page import="org.springframework.context.ApplicationContext"
%><%@page import="org.w3c.dom.Element"
%><%
    /*

Required Parameters:

    1. userProfile  : This parameter is used to retrieve UserProfile of a user.
    2. messages     : Its used to get ApplicationContext from request.

*/
    UserProfile uProf =(UserProfile)request.getAttribute("userProfile");
    Vector<NGPageIndex> ownedProjs = ar.getCogInstance().getAllContainers();
    boolean noneFound = ownedProjs.size()==0;

    ApplicationContext context = (ApplicationContext)request.getAttribute("messages");

    Vector<NotificationRecord> notifications = uProf.getNotificationList();
    JSONArray allAlerts = new JSONArray();

    //NEED TO FILL THE ARRAY HERE

    List<NGContainer> containers = new ArrayList<NGContainer>();
    long lastSendTime = ar.getSuperAdminLogFile().getLastNotificationSentTime();
    if(notifications.size()>0) {
        int count = 0;
        String rowStyleClass = "";
        for (NotificationRecord tr : notifications) {
            String pageId = tr.getPageKey();
            NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
            if (ngp==null) {
                continue;
            }
            containers.add(ngp);
            String linkAddr = ar.retPath + "t/" +ngp.getSite().getKey()+"/"+ngp.getKey() + "/history.htm";
            if(count%2 == 0){
                rowStyleClass = "tableBodyRow odd";
            }
            else{
                rowStyleClass = "tableBodyRow even";
            }
        }
    }
%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.allAlerts = <%allAlerts.write(out,2,4);%>;


    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
});
</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Watched Workspaces
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="">Do Nothing</a></li>
            </ul>
          </span>

        </div>
    </div>
<%
%>
<div class="generalHeading" style="padding-top:35px">Workspace Notifications Since Last Digest
        <%SectionUtil.nicePrintDateAndTime(out, lastSendTime);%></div>
    <p>These notifications, if any, will be included in your next daily digest email.</p>

    <%
    DailyDigest.constructDailyDigestEmail(ar,containers,lastSendTime,ar.nowTime);

    out.flush();

%>
</div>
