<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.EmailRecord"
%><%@page import="com.purplehillsbooks.weaver.OptOutAddr"
%><%@page import="com.purplehillsbooks.weaver.mail.EmailSender"
%><%@page import="com.purplehillsbooks.weaver.mail.MailInst"
%><%

    String filter      = ar.defParam("f", "");
    UserProfile uProf =(UserProfile)request.getAttribute("userProfile");
    String userKey = ar.reqParam("userKey");
    UserProfile displayedUser = UserManager.getUserProfileByKey(userKey);
    
    JSONObject newQuery = new JSONObject();
    newQuery.put("userKey", displayedUser.getKey());
    newQuery.put("offset", 0);
    newQuery.put("batch", 50);
    newQuery.put("includeBody", false);
    JSONObject mailQueryResult = EmailSender.queryUserEmail(newQuery);
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
    window.setMainPageTitle("Email Sent to <%ar.writeJS(displayedUser.getName());%>");
    $scope.emailList = [];
    $scope.filter = "<%ar.writeJS(filter);%>";
    $scope.offset = 0;
    $scope.batch = 20;
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
        console.log("fetching records: "+diff);
        var postURL = "QueryUserEmail.json";
        var newPos = $scope.offset + diff;
        if (newPos<0) {
            newPos = 0;
        }
        console.log("FETCHING records from :"+newPos);
        
        var query = {
            offset: newPos,
            batch: $scope.batch,
            searchValue: $scope.filter
        };
        var postdata = angular.toJson(query);
        $http.post(postURL, postdata)
        .success( function(data) {
            console.log("received records");
            $scope.emailList = data.list;
            $scope.offset = newPos;
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
    $scope.fetchEmailRecords(0);
});

</script>

<!-- MAIN CONTENT SECTION START -->
<div>

<%@include file="../jsp/ErrorPanel.jsp"%>

        <div>
            Filter: <input ng-model="filter">
            <button ng-click="fetchEmailRecords(0)" class="btn btn-default btn-raised">Refresh</button>
            <button ng-click="fetchEmailRecords(-20)" class="btn btn-default btn-raised">Previous</button>
            <button ng-click="fetchEmailRecords(20)" class="btn btn-default btn-raised">Next</button>
            <span style="padding:5px">{{offset+1}} - {{offset+batch}}</span>
        </div>
        <div style="height:20px;"></div>
        <table class="table" width="100%">
            <tr>
                <td width="15px">#</td>
                <td width="100px">From</td>
                <td width="300px">Subject</td>
                <td width="50px">Site/Workspace</td>
                <td width="50px">Status</td>
                <td width="100px">Send Date</td>
            </tr>
            <tr ng-repeat="rec in emailList">
                <td>{{offset+$index+1}}</td>
                <td>{{namePart(rec.From)}}</td>
                <td><a href="EmailMsgU.htm?msg={{rec.CreateDate}}&f={{filter}}">{{rec.Subject}}</a></td>
                <td>{{rec.Site}}/{{rec.Workspace}}</td>
                <td>{{rec.Status}}</td>
                <td>{{bestDate(rec) |cdate}}</td>
            </tr>
        </table>

</div>


