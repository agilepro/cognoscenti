<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.EmailListener"
%><%@page import="com.purplehillsbooks.json.JSONException"
%><%@ include file="/spring/jsp/include.jsp"
%>
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
                <td><%=SectionUtil.getDateAndTime(EmailSender.lastEmailProcessTime)%></td>
            </tr>
            <tr>
                <td>Number of Email Sent</td>
                <td><%=EmailSender.emailSendCount%></td>
            </tr>
            <tr>
                <td>Last Email Error Time</td>
                <td><%=SectionUtil.getDateAndTime(EmailSender.lastEmailFailureTime)%></td>
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
        </table>
        <p>
            Last Inbox Read: <% SectionUtil.nicePrintDateAndTime(out, EmailListener.lastFolderRead);%>
        </p>

    </div>
</div>
