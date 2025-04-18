<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
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
        "Addressee": "Bernd.Schroettle@example.com",
        "AttachmentFiles": ["/opt/weaver_sites/example/example-distinguished-engineer/.cog/meet1923.ics"],
        "BodyText": "....\n",
        "CreateDate": 1534966224915,
        "From": "john.schwartz@example.com",
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
<div class="container-fluid override m-2">
<div class="d-flex col-12"><div class="contentColumn">
        <div class="well">
            Filter: <input ng-model="filter">
            <button ng-click="fetchEmailRecords(0)" class="btn btn-comment btn-default btn-raised py-0">Refresh</button>
            <button ng-click="fetchEmailRecords(-20)" class="btn btn-comment btn-default btn-raised py-0">Previous</button>
            <button ng-click="fetchEmailRecords(20)" class="btn btn-comment btn-default btn-raised py-0">Next</button>
            <span class="h6" style="padding:5px">{{offset+1}} - {{offset+batch}}</span>
        </div>
        <table class="table ms-2" width="100%">
            <tr class="gridTableHeader">
            
                <td width="10px">#</td>
                <td width="20px">From</td>
                <td width="300px">Subject</td>
                <td width="50px">Site/Workspace</td>
                <td width="50px">Status</td>
                <td width="50px">Send Date</td>
            </tr>
            <tr ng-repeat="rec in emailList">
                <td width="10px">{{offset+$index+1}}</td>
                <td width="20px">{{namePart(rec.From)}}</td>
                <td width="300px"><a href="EmailMsg.htm?msg={{rec.CreateDate}}&f={{filter}}">{{rec.Subject}}</a></td>
                <td width="50px">{{rec.Site}}/{{rec.Workspace}}</td>
                <td width="50px">{{rec.Status}}</td>
                <td width="50px">{{bestDate(rec) |cdate}}</td>
            </tr>
        </table>
</div></div>
</div>
</div>


