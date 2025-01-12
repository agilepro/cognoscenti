<%@page errorPage="/spring2/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.mail.EmailListener"
%><%@page import="com.purplehillsbooks.json.JSONException"
%><%@page import="java.util.Set"
%><%@ include file="/include.jsp"
%><%

    Cognoscenti cog = Cognoscenti.getInstance(request);
    Set<String> activeUsers = cog.whoIsLoggedIn();
 

%>

<script type="text/javascript">
console.log("RUNNING");
var myApp = angular.module('myApp');
console.log("RUNNING",myApp);
myApp.controller('myCtrl', function($scope, $http) {

    $scope.lastSend = "<%=EmailSender.lastEmailProcessTime%>";
    $scope.lastFailure = "<%=EmailSender.lastEmailFailureTime%>";

});

</script>

<style>
.table {
    max-width:800px;
}
</style>

<div ng-app="myApp" ng-controller="myCtrl">
  <div class="content tab01" style="display:block;" >
    <div class="section_body">
        <div class="h1">Email Send Settings</div>



        <table class="table">
            <tr>
                <td>mail.transport.protocol</td>
                <td><%=EmailSender.getProperty("mail.transport.protocol")%></td>
            </tr>
            <tr>
                <td>mail.smtp.host</td>
                <td><%=EmailSender.getProperty("mail.smtp.host")%></td>
            </tr>
            <tr>
                <td>mail.smtp.port</td>
                <td><%=EmailSender.getProperty("mail.smtp.port")%></td>
            </tr>
            <tr>
                <td>mail.smtp.auth</td>
                <td><%=EmailSender.getProperty("mail.smtp.auth")%></td>
            </tr>
            <tr>
                <td>mail.smtp.user</td>
                <td><%=EmailSender.getProperty("mail.smtp.user")%></td>
            </tr>
            <tr>
                <td>automated.email.delay</td>
                <td><%=EmailSender.getProperty("automated.email.delay")%></td>
            </tr>
            <tr>
                <td>Last Email Send</td>
                <td>{{lastSend|date:"dd-MMM-yyyy HH:mm:ss"}}  
                    (server:<%=SectionUtil.getDateAndTime(EmailSender.lastEmailProcessTime)%>)</td>
            </tr>
            <tr>
                <td>Number of Email Sent</td>
                <td><%=EmailSender.emailSendCount%></td>
            </tr>
            <tr>
                <td>Last Email Error Time</td>
                <td>{{lastFailure|date:"dd-MMM-yyyy HH:mm:ss"}}  
                    (server:<%=SectionUtil.getDateAndTime(EmailSender.lastEmailFailureTime)%>)</td>
            </tr>
            <tr>
                <td>Last Email Error</td>
                <td><pre><% if (EmailSender.lastEmailSendFailure!=null) { 
                    JSONException.traceException(out,EmailSender.lastEmailSendFailure, "EMAIL FAILURE"); }
                %></pre></td>
            </tr>
        </table>

        <div style="height:10px;"></div>
        <div class="h1">Email Listener Settings</div>
        <%
             Properties emailProperties = EmailListener.getEmailProperties();
             if (emailProperties == null) {
                emailProperties = new Properties();
             }
             if(ar.getSuperAdminLogFile().getEmailListenerWorking()){
                 %><img src="<%=ar.retPath%>assets/images/greencircle.jpg" border="green" width="10px" height="10px" />
                  &nbsp;&nbsp; Settings for Email Listener are fine.<br/><%
            }
            else {
                 %><img src="<%=ar.retPath%>assets/images/redcircle.jpg" border="green" width="10px" height="10px" />
                  &nbsp;&nbsp; Email Listener is not working.<br/><%
            }
        %>
        <br/>
        <table class="table">
            <tr>
                <td>POP3 Host</td>
                <td><%=emailProperties.getProperty("mail.pop3.host")%></td>
            </tr>
            <tr>
                <td>POP3 Port</td>
                <td><%=emailProperties.getProperty("mail.pop3.port")%></td>
            </tr>
            <tr>
                <td>User Name</td>
                <td><%=emailProperties.getProperty("mail.pop3.user")%></td>
            </tr>
            <tr>
                <td>Password</td>
                <td>****************</td>
            </tr>
            <tr>
                <td>Last Inbox Read</td>
                <td><% SectionUtil.nicePrintDateAndTime(out, EmailListener.lastFolderRead);%></td>
            </tr>
        </table>

    </div>
  </div>


  <div>
    <div class="h1">Active Users</div>
    <table class="table">
      <tr>
        <th>User ID</th>
        <th>Name</th>
        <th>Last Access</th>
      </tr>
        <%
        for (String userid : activeUsers) {
            UserProfile user = UserManager.getUserProfileByKey(userid); %>
          <tr>
            <td><a href=\"../<%=userid%>/PersonShow.htm\"><%=userid%></a></td>
            <td><%=user.getName()%></td>
            <td>{{<%=cog.getVisitTime(userid)%>|cdate}}</td>
          </tr>
            <%
        }
        %>
    </table>
  </div>
  
  <div style="height:300px"></div>

</div>
