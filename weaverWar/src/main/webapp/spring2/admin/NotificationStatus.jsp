<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%

    long lastSentTime = ar.getSuperAdminLogFile().getLastNotificationSentTime();
    long nextScheduleTime = EmailSender.getNextTime(lastSentTime);
    boolean overDue = (ar.nowTime > nextScheduleTime);
    long serverTime = System.currentTimeMillis();

%>

<script>

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    $scope.serverTime = <%=serverTime%>;
    $scope.browserTime = new Date().getTime();
    $scope.overDue = <%=overDue%>;
    $scope.protocol = "<%=EmailSender.getProperty("mail.transport.protocol")%>";
    
    $scope.reportError = function(serverErr) {
        console.log("ERROR", serverErr);
        alert("error occurred check browser console");
    };
        
    $scope.findUser = function(email) {
        window.open("../FindPerson.htm?uid="+email, '_blank');
    }
    
});
</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="h1">
            Latest Notification
    </div>

        <table class="table">
            <tr><td>Last Notification Sent Time:</td><td> <%
                SectionUtil.nicePrintDateAndTime(out, lastSentTime);
            %></td></tr>
            <tr><td>Next Schedule Time:</td><td><%
                SectionUtil.nicePrintDateAndTime(out, nextScheduleTime);
            %></td></tr>
            <tr><td>Last Check Time:</td><td><%
                SectionUtil.nicePrintDateAndTime(out, EmailSender.threadLastCheckTime);
            %></td></tr>
            <tr><td>Server Time:</td><td>{{serverTime}},  {{serverTime|date:'yyyy MMM dd, HH:mm:ss'}}</td></tr>
            <tr><td>Browser Time:</td><td>{{browserTime}},  {{browserTime|date:'yyyy MMM dd, HH:mm:ss'}}</td></tr>
            <tr><td>Difference:</td><td>{{(serverTime-browserTime)/1000}} seconds apart.</td></tr>
            <tr><td>Protocol:</td><td>{{protocol}} <b ng-hide="protocol='smtp'">-- Will not actually send SMTP email!</b></td></tr>
            <tr ng-show="overDue"><td></td><td><b>Email sending is OverDue!</b></td></tr>
            <%
                if (EmailSender.threadLastCheckException!=null) {
                       ar.writeHtml( EmailSender.threadLastCheckException.toString() );
                       ar.write("<tr><td></td><td>\n<pre>\n");
                       EmailSender.threadLastCheckException.printStackTrace(new PrintWriter(new HTMLWriter(out)));
                       ar.write("\n</pre>\n</td></tr>\n");
                   }
            %>
            <%
                if (EmailSender.threadLastMsgException!=null) {
                       ar.writeHtml( EmailSender.threadLastMsgException.toString() );
                       ar.write("<tr><td></td><td>\n<pre>\n");
                       EmailSender.threadLastMsgException.printStackTrace(new PrintWriter(new HTMLWriter(out)));
                       ar.write("\n</pre>\n</td></tr>\n");
                   }
            %>
        </td></tr>
    </table>
        
        <hr/><ul>
            <%ar.write(ar.getSuperAdminLogFile().getSendLog());%>
        </ul>



    
    <div style="margin:50px"></div>
    
    
</div>    