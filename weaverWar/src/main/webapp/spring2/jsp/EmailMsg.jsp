<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.CommentContainer"
%><%@page import="com.purplehillsbooks.weaver.AgendaItem"
%><%@page import="com.purplehillsbooks.weaver.mail.MailInst"
%><%

    String msgSentDate = ar.reqParam("msg");
    long msgId = DOMFace.safeConvertLong(msgSentDate);
    String filter      = ar.defParam("f", "");
    
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    ar.assertAccessWorkspace("Must be a member to see meetings");
    NGBook ngb = ngw.getSite();

    MailInst emailMsg = EmailSender.findEmailById(ngw, msgId);
    AddressListEntry fromAle = AddressListEntry.findOrCreate(emailMsg.getFromAddress());
    AddressListEntry toAle = AddressListEntry.findOrCreate(emailMsg.getAddressee());
    String containerKey = emailMsg.getCommentContainer();
    String containerUrl = null;
    String aboutName = null;
    String aboutType = null;
    if (containerKey != null && containerKey.length()>0) {
        CommentContainer cc = ngw.findContainerByKey(containerKey);
        if (cc!=null) {
            if (cc instanceof TopicRecord) {
                containerUrl = "NoteZoom"+((TopicRecord)cc).getId()+".htm";
                aboutName = ((TopicRecord)cc).getSubject();
                aboutType = "Topic";
            }
            else if (cc instanceof AgendaItem) {
                MeetingRecord meet = ((AgendaItem)cc).meeting;
                containerUrl = "MeetingHtml.htm?id="+meet.getId();
                aboutName = meet.getName();
                aboutType = "Meeting";
            }
        }
    }
    
    JSONObject mailObject = new JSONObject();
    String specialBody = "";
    boolean bodyIsDeleted = false;
    if (emailMsg != null) {
        mailObject = emailMsg.getJSON();
        specialBody = emailMsg.getBodyText();
        bodyIsDeleted = specialBody.startsWith("*deleted");
    }

/* PROTOTYPE EMAIL RECORD
      {
        "from": "Keith local Test <kswenson@example.com>",
        "sendDate": 1431876589439,
        "status": "Sent",
        "subject": "This is a new NOTE",
        "to": ["kswenson@example.com"]
      },
*/


%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Email Sent");
    $scope.emailMsg = <%mailObject.write(out,2,4);%>;
    $scope.filter = "<%ar.writeJS(filter);%>";
    $scope.bodyIsDeleted = <%=bodyIsDeleted%>;
    $scope.fromUser = <% fromAle.getJSON().write(out, 2, 4); %>;
    $scope.toUser = <% toAle.getJSON().write(out, 2, 4); %>;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.namePart = function(val) {
        var pos = val.indexOf('�');
        if (pos<0) {
            pos = val.indexOf('<');
        }
        if (pos<0) {
            return val;
        }
        return val.substring(0,pos);
    }

    $scope.bestDate = function(rec) {
        if (rec.Status == "Sent" || rec.Status == "Failed") {
            return rec.LastSentDate;
        }
        else {
            return rec.CreateDate;
        }
    }
});

</script>
<style>
.msgBody {
    padding:25px;
}
</style>
<!-- MAIN CONTENT SECTION START -->
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>


<table class="table" style="max-width:800px">
  <tr>
    <td>From</td>
    <td><a href="../../{{fromUser.key}}/PersonShow.htm">{{fromUser.name}}</a></td>
  </tr>
  <tr>
    <td>Subject</td>
    <td>{{emailMsg.Subject}}</td>
  </tr>
  <tr>
    <td>Addressee</td>
    <td><a href="../../{{toUser.key}}/PersonShow.htm">{{toUser.name}}</a></td>
  </tr>
  <tr>
    <td>Status</td>
    <td>{{emailMsg.Status}}</td>
  </tr>
  <% if (containerUrl!=null) { %>
  <tr>
    <td>About <%ar.writeHtml(aboutType);%></td>
    <td><a href="<%=containerUrl%>"><%ar.writeHtml(aboutName);%></a></td>
  </tr>
  <% } %>
  <tr ng-show="emailMsg.exception">
    <td>Error</td>
    <td><div>Failed {{emailMsg.FailCount}} times</div>
        <div>{{emailMsg.exception.error.context}}</div>
        <div ng-repeat="ee in emailMsg.exception.error.details">{{ee.message}}</div></td>
  </tr>
  <tr ng-hide="bodyIsDeleted">
    <td colspan="2"><div class="msgBody"><%= specialBody %></div></td>
  </tr>
  <tr ng-show="bodyIsDeleted">
    <td colspan="2">
      <div style="font-family:Arial,Helvetica Neue,Helvetica,sans-serif;border: 2px solid skyblue;padding:10px;border-radius:10px;text-align:center;font-style:italic">
      <p>Email bodies are deleted 3 months after sending</p>
      <p>This email body was deleted around {{emailMsg.LastSentDate+(91*24*60*60*1000) |date:"dd-MMM-yyyy"}}</p>
      </div>   
    </td>
  </tr>
  <tr ng-show="emailMsg.AttachmentFiles && emailMsg.AttachmentFiles.length>0">
    <td>Attachments</td>
    <td><div ng-repeat="att in emailMsg.AttachmentFiles">{{att}}</div></td>
  </tr>
  <tr>
    <td>Created</td>
    <td>{{emailMsg.CreateDate |date:"dd-MMM-yyyy 'at' HH:mm"}}</td>
  </tr>
  <tr>
    <td>Sent</td>
    <td>{{emailMsg.LastSentDate |date:"dd-MMM-yyyy 'at' HH:mm"}}</td>
  </tr>
  <tr>
    <td>Msg Id</td>
    <td>{{emailMsg.CreateDate}}</td>
  </tr>
  <tr>
    <td>Site</td>
    <td><a href="../$/SiteWorkspaces.htm">{{emailMsg.Site}}</a></td>
  </tr>
  <tr>
    <td>Workspace</td>
    <td><a href="Front.wmf">{{emailMsg.Workspace}}</a></td>
  </tr>
  <tr>
    <td>CommentContainer</td>
    <% if (containerUrl!=null) { %>
    <td><a href="<%=containerUrl%>">{{emailMsg.CommentContainer}}</a></td>
    <% } else { %>
    <td>{{emailMsg.CommentContainer}}</td>
    <% } %>
  </tr>
  <tr>
    <td>CommentId</td>
    <td>{{emailMsg.CommentId}}</td>
  </tr>

</table>

</div>


