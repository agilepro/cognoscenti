<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.ErrorLog"
%><%@page import="org.socialbiz.cog.ErrorLogDetails"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%

/*

Required Parameters:

    1. errorId      : This parameter specifies the error id to look up and display.
    2. errorDate    : The date of the log file to find the error in.
    3. goURL        : This is the url of current page which is used when form is successfully processed bt controller.
*/


    long errorDate = Long.parseLong((String)request.getAttribute("errorDate"));
    String errorId =(String)request.getAttribute("errorId");
    String searchByDate=ar.reqParam("searchByDate");
    String goURL=ar.reqParam("goURL");

    Cognoscenti cog = Cognoscenti.getInstance(request);
    ErrorLog eLog = ErrorLog.getLogForDate(errorDate, cog);
    ErrorLogDetails eDetails = eLog.getDetails(errorId);

    SimpleDateFormat sdf = new SimpleDateFormat("MM/dd/yyyy");
    String searchDate = sdf.format(new Date(errorDate));
    String formattedDate = new SimpleDateFormat("yyyy/MM/dd hh:mm:ss.SSS").format(eDetails.getModTime());
    
    
    JSONObject errDetails = eDetails.getJSON();
    errDetails.put("logDate", errorDate);
    

%>
<script type="text/javascript">

function postMyComment(){
    document.forms["logUserComents"].submit();
}
var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.errDetails = <%errDetails.write(out,2,4);%>;
    $scope.searchDateStr = "<%ar.writeJS(searchDate);%>";
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.postMyComment = function() {
        var newErr = {};
        newErr.errNo = $scope.errDetails.errNo;
        newErr.logDate = $scope.errDetails.logDate;
        newErr.comment = $scope.errDetails.comment;
        var postdata = angular.toJson(newErr);
        console.log("sending this: ", newErr);
        $http.post("http://submitCommentxxxxx/nnmn" ,postdata)
        .success( function(data) {
            console.log("got a response: ", data);
            $scope.errDetails = data;
        })
        .error( function(data) {
           console.log("got error: ", data);
           $scope.reportError(data);
        });
    }
});

</script>

<!-- Begin mainContent (Body area) -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <a class="btn btn-default btn-raised" href="errorLog.htm?searchDate={{searchDateStr}}">
        Return to Error List </a>
      </span>
    </div>
    <div  class="h1">
        Details of Error: {{errDetails.errNo}}
    </div>
    <div>
         <form name="logUserComents" action="logUserComents.form" method="post">

          <input type="hidden" name="errorNo" id="errorNo" value="{{errDetails.errNo}}"/>
          <input type="hidden" name="searchByDate" id="searchByDate" value="<%ar.writeHtml(searchByDate); %>"/>
          <input type="hidden" name="goURL" id="goURL" value="<%ar.writeHtml(goURL); %>"/>

        <b>Error Message:</b> <span style="white-space:pre-wrap;"> {{errDetails.message}} </span>
        <br /><br />
        <b>Page:</b> <a href="{{errDetails.uri}}">{{errDetails.uri}}</a>
        <br /><br />
        <b>Date & Time:</b> {{errDetails.modTime|date: "yyyy-MM-dd HH:mm:ss"}}
        <br /><br />
        <b>User Detail: </b> {{errDetails.modUser}}
        <br /><br />
        <b>Comments: </b>
        <br />
        <textarea class="form-control" style="width:600px;height:150px" 
                  ng-model="errDetails.comment"></textarea>
        <br />
        <br />
        <button class="btn btn-primary btn-raised" ng-click="postMyComment()">Update Comments</button>
         </form>
         <hr/>
         <div>
            <button class="btn btn-default btn-raised" ng-hide="showTrace" ng-click="showTrace=!showTrace">
                Show Error Details 
             </button>
         </div>
        <div class="errorStyle" ng-show="showTrace">
        <pre style="overflow:auto;width:900px;" ng-click="showTrace=!showTrace">{{errDetails.stackTrace}}</pre>
        </div>
    </div>
 </div>


