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
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    ar.assertMember("Must be a member to see meetings");
    NGBook ngb = ngw.getSite();


    
    JSONObject newQuery = new JSONObject();
    newQuery.put("offset", 0);
    newQuery.put("batch", 50);
    newQuery.put("includeBody", false);
    JSONObject mailQueryResult = MailFile.queryEmail(ngw, newQuery);
    JSONArray mailList = mailQueryResult.getJSONArray("list");

/* PROTOTYPE EMAIL RECORD
      {
        "Addressee": "Bernd.Schroettle@xx.fujitsu.com",
        "AttachmentFiles": ["/opt/weaver_sites/fujitsu/fujitsu-distinguished-engineer/.cog/meet1923.ics"],
        "BodyText": "....\n",
        "CreateDate": 1534966224915,
        "From": "john.schwartz@xx.fujitsu.com",
        "FromName": "JOHN SCHWARTZ",
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
    $scope.emailList = [];
    $scope.filter = "<%ar.writeJS(filter);%>";
    $scope.offset = 0;
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
    $scope.fetchEmailRecords = function(diff) {
        console.log("fetching records");
        var postURL = "QueryEmail.json";
        var newPos = $scope.offset + diff;
        if (newPos<0) {
            newPos = 0;
        }
        var query = {
            offset: newPos,
            batch: 20,
            searchValue: $scope.filter
        };
        var postdata = angular.toJson(query);
        $http.post(postURL, postdata)
        .success( function(data) {
            console.log("received records");
            $scope.emailList = data.list;
            $scope.offset = data.query.offset;
            $scope.sortInverseChron();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
        console.log("fetching records 2");
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
    $scope.fetchEmailRecords();
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
            <button ng-click="fetchEmailRecords(0)" class="btn btn-default btn-raised">Refresh</button>
            <button ng-click="fetchEmailRecords(-20)" class="btn btn-default btn-raised">Previous</button>
            <button ng-click="fetchEmailRecords(20)" class="btn btn-default btn-raised">Next</button>
        </div>
        <div style="height:20px;"></div>
        <table class="table" width="100%">
            <tr>
                <td width="15px">#</td>
                <td width="100px">From</td>
                <td width="300px">Subject</td>
                <td width="100px">Recipient</td>
                <td width="50px">Status</td>
                <td width="100px">Send Date</td>
            </tr>
            <tr ng-repeat="rec in emailList">
                <td>{{offset+$index}}</td>
                <td>{{namePart(rec.From)}}</td>
                <td><a href="emailMsg.htm?msg={{rec.CreateDate}}&f={{filter}}">{{rec.Subject}}</a></td>
                <td>{{rec.Addressee}}</td>
                <td>{{rec.Status}}</td>
                <td>{{bestDate(rec) |date:'M/d/yy H:mm'}}</td>
            </tr>
        </table>

</div>



