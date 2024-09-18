<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/spring2/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.mail.EmailSender"
%><%@page import="com.purplehillsbooks.weaver.mail.MailInst"
%><%

    String filter      = ar.defParam("f", "");
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    ar.assertAccessWorkspace("Must be a member to see meetings");
    NGBook ngb = ngw.getSite();


    
    JSONObject newQuery = new JSONObject();
    newQuery.put("offset", 0);
    newQuery.put("batch", 50);
    newQuery.put("includeBody", false);
    JSONObject mailQueryResult = EmailSender.queryWorkspaceEmail(ngw, newQuery);
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
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Email Sent");
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
        var postURL = "QueryEmail.json";
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
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>
<div class="container-fluid">
    <div class="row">
        <div class="col-md-auto fixed-width border-end border-1 border-secondary">
            <span class="btn btn-raised btn-comment btn-secondary m-3 pb-2 pt-0" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewTopic"><a class="nav-link " role="menuitem" href="EmailCreated.htm">
              Email Prepared</a>
            </span>
            <span class="btn btn-raised btn-comment btn-secondary m-3 pb-2 pt-0" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewTopic"><a class="nav-link" role="menuitem" href="EmailSent.htm">
              Email Sent</a>
            </span>
          <hr/>
          <span class="btn btn-raised btn-comment btn-secondary m-3 pb-2 pt-0" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewTopic"><a class="nav-link " role="menuitem" href="SendNote.htm">
              Create Email</a>
          </span>
    </div>


    <div class="d-flex col-9"><div class="contentColumn">
        <div class="col-12 well ms-3">Filter <input ng-model="filter">
<button ng-click="fetchEmailRecords(0)" class="btn btn-secondary btn-wide btn-raised">Refresh</button>
            <button ng-click="fetchEmailRecords(-20)" class="btn btn-secondary btn-wide btn-raised">Previous</button>
            <button ng-click="fetchEmailRecords(20)" class="btn btn-secondary btn-wide  btn-raised">Next</button>
            <span style="padding:5px">{{offset+1}} - {{offset+batch}}</span>
        </div>
        <div class="container-fluid col-12 ms-3">
            <div class="row d-flex border-bottom border-1 py-2">
                <div class="col-1 me-0 h6">#</div>
                <div class="col-2 ms-0 h6">From</div>
                <div class="col-4 h6">Subject</div>
                <div class="col-2 h6">Recipient</div>
                <div class="col-1 ms-2 h6">Status</div>
                <div class="col-1 h6 px-0">Send Date</div>
            </div>
            <div class="row d-flex border-bottom border-1 py-2" ng-repeat="rec in emailList">
                <div class="col-1 me-0">{{offset+$index+1}}</div>
                <div class="col-2 ms-0">{{namePart(rec.From)}}</div>
                <div class="col-4"><a href="EmailMsg.htm?msg={{rec.CreateDate}}&f={{filter}}">{{rec.Subject}}</a></div>
                <div class="col-2">{{rec.Addressee}}</div>
                <div class="col-1 ms-2">{{rec.Status}}</div>
                <div class="col-1 px-0">{{bestDate(rec) |cdate}}</div>
            </div>
        </div>

</div>



