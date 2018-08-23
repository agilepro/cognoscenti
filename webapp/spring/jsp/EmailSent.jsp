<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.EmailRecord"
%><%@page import="org.socialbiz.cog.OptOutAddr"
%><%@page import="org.socialbiz.cog.mail.MailFile"
%><%@page import="org.socialbiz.cog.mail.MailInst"
%><%

    String filter      = ar.defParam("f", "");
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Must be a member to see meetings");
    NGBook ngb = ngp.getSite();

    File folder = ngp.getFilePath().getParentFile();
    File emailFilePath = new File(folder, "mailArchive.json");

    MailFile mailArchive = MailFile.readOrCreate(emailFilePath);
    JSONArray emailList = mailArchive.getAllJSON();
    JSONArray emailList2 = new JSONArray();
    for (int i=0; i<emailList.length(); i++) {
        JSONObject email = emailList.getJSONObject(i);
        JSONObject e2 = new JSONObject();
        e2.put("Addressee",email.get("Addressee"));
        e2.put("CreateDate",email.get("CreateDate"));
        e2.put("From",email.get("From"));
        e2.put("FromName",email.get("FromName"));
        e2.put("LastSentDate",email.get("LastSentDate"));
        e2.put("Status",email.get("Status"));
        e2.put("Subject",email.get("Subject"));
        emailList2.put(e2);
    }

/* PROTOTYPE EMAIL RECORD
      {
        "Addressee": "Bernd.Schroettle-Henning@ts.fujitsu.com",
        "AttachmentFiles": ["/opt/weaver_sites/fujitsu/fujitsu-distinguished-engineer/.cog/meet1923.ics"],
        "BodyText": "....\n",
        "CreateDate": 1534966224915,
        "From": "jonathan.schwartz@ca.fujitsu.com",
        "FromName": "JONATHAN SCHWARTZ",
        "LastSentDate": 1534966478516,
        "Status": "Sent",
        "Subject": "Reminder for meeting: Monthly FDE Meeting - August"
      }
*/


%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Email Sent");
    $scope.emailList = <%emailList2.write(out,2,4);%>;
    $scope.filter = "<%ar.writeJS(filter);%>";
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.sortInverseChron = function() {
        $scope.emailList.sort( function(a, b){
            return b.sendDate - a.sendDate;
        });
    };
    $scope.sortInverseChron();
    $scope.getFiltered = function() {
        var searchVal = $scope.filter.toLowerCase();
        var res = [];
        if ($scope.filter==null || $scope.filter.length==0) {
            res = $scope.emailList;
        }
        else {
            res = $scope.emailList.filter( function(oneEmail) {
                return (oneEmail.Subject.toLowerCase().indexOf(searchVal)>=0)
                    || (oneEmail.Addressee.toLowerCase().indexOf(searchVal)>=0);
            });
        }
        res = res.sort( function(a,b) {
            return $scope.bestDate(b)-$scope.bestDate(a);
        });
        return res;
    }
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
    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" href="listEmail.htm">
              Email Prepared</a>
          </li>
          <li role="presentation"><a role="menuitem" href="emailSent.htm">
              Email Sent</a>
          </li>
          <li role="presentation" class="divider"></li>
          <li role="presentation"><a role="menuitem" href="sendNote.htm">
              Create Email</a>
          </li>
        </ul>
      </span>
    </div>

        <div>
            Filter: <input ng-model="filter">
        </div>
        <div style="height:20px;"></div>
        <table class="table" width="100%">
            <tr>
                <td width="100px">From</td>
                <td width="300px">Subject</td>
                <td width="100px">Recipient</td>
                <td width="50px">Status</td>
                <td width="100px">Send Date</td>
            </tr>
            <tr ng-repeat="rec in getFiltered()|limitTo: 50">
                <td>{{namePart(rec.From)}}</td>
                <td><a href="emailMsg.htm?msg={{rec.CreateDate}}&f={{filter}}">{{rec.Subject}}</a></td>
                <td>{{rec.Addressee}}</td>
                <td>{{rec.Status}}</td>
                <td>{{bestDate(rec) |date:'M/d/yy H:mm'}}</td>
            </tr>
        </table>

</div>



