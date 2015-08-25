<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.ErrorLog"
%><%@page import="org.socialbiz.cog.ErrorLogDetails"
%><%@page import="java.text.ParsePosition"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    SimpleDateFormat sdf = new SimpleDateFormat("MM/dd/yyyy");
    String searchDate = ar.defParam("searchDate", null);
    if (searchDate==null) {
        //put today in if no date given
        searchDate = sdf.format(new Date());
    }
    long errorDate = sdf.parse(searchDate, new ParsePosition(0)).getTime();

    Cognoscenti cog = Cognoscenti.getInstance(request);
    ErrorLog eLog = ErrorLog.getLogForDate(errorDate, cog);
    JSONArray allDetails = new JSONArray();
    for (ErrorLogDetails eld  : eLog.getAllDetails()) {
        JSONObject jo = new JSONObject();
        jo.put("errNo", eld.getErrorNo());
        jo.put("errorMessage", eld.getErrorMessage());
        jo.put("errorDetails", eld.getErrorDetails());
        jo.put("modTime", eld.getModTime());
        allDetails.put(jo);
    }


%>
<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.allDetails = <%allDetails.write(out,2,4);%>;

    $scope.logFilePath = "<% ar.writeJS(eLog.getFilePath().toString()); %>";
    $scope.newDate = "<%=searchDate%>";

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.newSearch = function() {
        window.location = "errorLog.htm?searchDate="+$scope.newDate;
    }

});

</script>


<div ng-app="myApp" ng-controller="myCtrl">


    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Error Log for <%=searchDate%>
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="">Do Nothing</a></li>
            </ul>
          </span>

        </div>
    </div>

    Search date: <input ng-model="newDate"> <button ng-click="newSearch()">search</button>

   <table class="table">
      <tr ng-repeat="row in allDetails">
         <td><a href="errorDetails{{row.errNo}}.htm?searchByDate=<%=errorDate%>">{{row.errNo}}</a></td>
         <td>{{row.errorMessage}}</td>
         <td>{{row.modTime | date}}</td>
      </tr>
   </table>

</div>


