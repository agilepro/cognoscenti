<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="administration.jsp"
%>
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Last Notification Sent Time: <span id="elapsed_time"></span>
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="createAgendaItem()" >Do Nothing</a></li>
            </ul>
          </span>

        </div>
    </div>

        <%
            long nextScheduleTime = EmailSender.getNextTime(lastSentTime);
                boolean overDue = (ar.nowTime > nextScheduleTime);
        %>
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
