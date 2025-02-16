<%@page errorPage="/spring/jsp/error.jsp"
%><%@include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.SectionUtil"
%><%@page import="com.purplehillsbooks.weaver.SuperAdminLogFile"
%><%@page import="com.purplehillsbooks.weaver.UserProfile"
%><%@page import="com.purplehillsbooks.weaver.UtilityMethods"
%><%@page import="com.purplehillsbooks.weaver.mail.DailyDigest"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.ArrayList"
%><%
    /*

Required Parameters:

    1. userProfile  : This parameter is used to retrieve UserProfile of a user.
    2. messages     : Its used to get ApplicationContext from request.

*/
    UserProfile uProf =(UserProfile)request.getAttribute("userProfile");

    JSONArray allAlerts = new JSONArray();

    //NEED TO FILL THE ARRAY HERE

    List<NGPageIndex> containers = new ArrayList<NGPageIndex>();
    long lastSendTime = uProf.getNotificationTime();

    //schema migration ... some users will not have this value set.
    //never go back more than twice the notification period.
    //This avoids getting a message with all possible history in it
    long earliestPossible = System.currentTimeMillis()-(uProf.getNotificationPeriod()*2*24*60*60*1000);
    if (lastSendTime<earliestPossible) {
        lastSendTime = earliestPossible;
    }



    List<String> notifications = uProf.getNotificationList();
    if(notifications.size()>0) {
        int count = 0;
        String rowStyleClass = "";
        for (String pageId : notifications) {
            NGPageIndex ngpi = ar.getCogInstance().getWSByCombinedKey(pageId);
            if (ngpi==null) {
                ngpi = ar.getCogInstance().lookForWSBySimpleKeyOnly(pageId);
            }
            if (ngpi==null) {
                continue;
                //this can happen if you have something to do in a project that is no longer 
                //in the project.  Right now we ignore them....
            }
            else {
                containers.add(ngpi);
            }
        }
    }
%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Alerts for <%ar.writeJS(uProf.getName());%>");
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
<div class="userPageContents override ">

<%@include file="../jsp/ErrorPanel.jsp"%>


<div class="generalHeading mx-5 fs-5">Workspace Notifications Since Last Digest
        <%SectionUtil.nicePrintDateAndTime(out, lastSendTime);%></div>
    <p class="fs-5 mx-5 my-3">These notifications, if any, will be included in your next daily digest email.
       Notification period: <%= uProf.getNotificationPeriod() %> days.
    </p>

    <%
     NGPageIndex.clearLocksHeldByThisThread();
     if (containers==null) {
         throw new Exception("How did containers get to be null?");
     }
     DailyDigest.constructDailyDigestEmail(ar,containers,lastSendTime,ar.nowTime);

    out.flush();

%>
</div>
