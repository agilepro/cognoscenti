<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="administration.jsp"
%><%

    long nextScheduleTime = EmailSender.getNextTime(lastSentTime);
    boolean overDue = (ar.nowTime > nextScheduleTime);




%>

<script>

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
});
</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="h1">
            Latest Notification
    </div>

        <ul>
            <li>Last Notification Sent Time: <%
                SectionUtil.nicePrintDateAndTime(out, lastSentTime);
            %></li>
            <li>Next Schedule Time: <%
                SectionUtil.nicePrintDateAndTime(out, nextScheduleTime);
            %></li>
            <li>Last Check Time: <%
                SectionUtil.nicePrintDateAndTime(out, EmailSender.threadLastCheckTime);
            %></li>
            <%
                String protocol = EmailSender.getProperty("mail.transport.protocol");
                if (!"smtp".equals(protocol)) {
            %>
            <li>Protocol: <%ar.writeHtml(protocol);%> -- <b>Will not actually send SMTP email!</b> see 'mail.transport.protocol'</li>
            <%
                }
                if (overDue) {
            %>
            <li><b>Email sending is OverDue!</b></li>
            <%
                }
            %>
            <%
                if (EmailSender.threadLastCheckException!=null) {
                       ar.writeHtml( EmailSender.threadLastCheckException.toString() );
                       ar.write("</ul>\n<pre>\n");
                       EmailSender.threadLastCheckException.printStackTrace(new PrintWriter(new HTMLWriter(out)));
                       ar.write("\n</pre>\n<ul>\n");
                   }
            %>
            <%
                if (EmailSender.threadLastMsgException!=null) {
                       ar.writeHtml( EmailSender.threadLastMsgException.toString() );
                       ar.write("</ul>\n<pre>\n");
                       EmailSender.threadLastMsgException.printStackTrace(new PrintWriter(new HTMLWriter(out)));
                       ar.write("\n</pre>\n<ul>\n");
                   }
            %>
            <li><hr/></li>
            <%
                ar.write(ar.getSuperAdminLogFile().getSendLog());
            %>
        </ul>
    </div>
