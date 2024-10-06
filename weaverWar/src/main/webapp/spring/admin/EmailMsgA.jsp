<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.mail.MailInst"
%><%

    String msgSentDate = ar.reqParam("msg");
    long msgId = DOMFace.safeConvertLong(msgSentDate);
    String filter      = ar.defParam("f", "");
    
    ar.assertSuperAdmin("Must be a member to see meetings");


    MailInst emailMsg = EmailSender.findEmailById(msgId);
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
app.controller('myCtrl', function($scope, $http) {
    $scope.emailMsg = <%mailObject.write(out,2,4);%>;
    $scope.filter = "<%ar.writeJS(filter);%>";
    $scope.bodyIsDeleted = <%=bodyIsDeleted%>;
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

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>


<table class="table" style="max-width:800px">
  <tr>
    <td>From</td>
    <td>{{emailMsg.From}}</td>
  </tr>
  <tr>
    <td>Subject</td>
    <td>{{emailMsg.Subject}}</td>
  </tr>
  <tr>
    <td>Addressee</td>
    <td>{{emailMsg.Addressee}}</td>
  </tr>
  <tr>
    <td>Status</td>
    <td>{{emailMsg.Status}}</td>
  </tr>
  <tr ng-show="emailMsg.exception">
    <td>Error</td>
    <td><div>Failed {{emailMsg.FailCount}} times</div>
        <div>{{emailMsg.exception.error.context}}</div>
        <div ng-repeat="ee in emailMsg.exception.error.details">{{ee.message}}</div></td>
  </tr>
  <tr>
    <td>Created</td>
    <td>{{emailMsg.CreateDate |date:"dd-MMM-yyyy 'at' HH:mm"}}</td>
  </tr>
  <tr>
    <td>Sent</td>
    <td>{{emailMsg.LastSentDate |date:"dd-MMM-yyyy 'at' HH:mm"}}</td>
  </tr>
  <tr ng-show="emailMsg.AttachmentFiles && emailMsg.AttachmentFiles.length>0">
    <td>Attachments</td>
    <td><div ng-repeat="att in emailMsg.AttachmentFiles">{{att}}</div></td>
  </tr>
  <tr>
    <td colspan="2"><%= specialBody %></td>
  </tr>
</table>

</div>


