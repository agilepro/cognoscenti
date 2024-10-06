<%@page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8"
%><%@page isErrorPage="true"
%><%@include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.ErrorLog"
%><%@page import="com.purplehillsbooks.weaver.ErrorLogDetails"
%><%

    /*
    The function of this page is simple enough: display an exception in a
    reasonably nice setting.  Can be used for exceptions that occur in the handler
    early and predictably enough.
    */

    Exception display_exception = (Exception) request.getAttribute("display_exception");
    long log_number = (long) request.getAttribute("log_number");
%>

<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="Content-Language" content="en-us" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta http-equiv="imagetoolbar" content="no" />
    <meta name="viewport" content="user-scalable=no, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0" />

    <!-- INCLUDE the ANGULAR JS library -->
    <script src="<%=ar.baseURL%>jscript/angular.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/ui-bootstrap-tpls.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/jquery.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/bootstrap.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/slap.js"></script>
    <link href="<%=ar.baseURL%>jscript/bootstrap.min.css" rel="stylesheet">
    <script src='<%=ar.baseURL%>jscript/tinymce/tinymce.min.js'></script>
    <script src='<%=ar.baseURL%>jscript/tinymce/tinymce-ng.js'></script>
    <script src="<%=ar.baseURL%>jscript/textAngular-sanitize.min.js"></script>
    <link href="<%=ar.baseURL%>jscript/ng-tags-input.css" rel="stylesheet">
    <script src="<%=ar.baseURL%>jscript/bootstrap-material-design/ripples.min.js"></script>
    <script src="<%=ar.baseURL%>jscript/bootstrap-material-design/material.min.js"></script>
    <link rel="stylesheet" href="<%=ar.baseURL%>css/bootstrap-material-design/bootstrap-material-design.min.css" media="screen">
    <link rel="stylesheet" href="<%=ar.baseURL%>css/bootstrap-material-design/ripples.min.css" media="screen">
    <script src="<%=ar.baseURL%>jscript/common.js"></script>

    <!-- INCLUDE web fonts -->
    <link href="<%=ar.retPath%>assets/font-awesome/css/font-awesome.min.css" rel="stylesheet"
          data-semver="4.3.0" data-require="font-awesome@*" />
      <link href="<%=ar.retPath%>assets/google/css/PT_Sans-Web.css" rel="stylesheet"/>

    <link href="<%=ar.retPath%>bits/fixed-sidebar.min.css" rel="styleSheet" type="text/css" media="screen" />
    <!-- Weaver specific tweaks -->
    <link href="<%=ar.retPath%>bits/main.min.css" rel="styleSheet" type="text/css" media="screen" />

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
console.log("RUN RUN");

app.controller('myCtrl', function($scope, $http) {
    $scope.log_number = <%=log_number%>;
    $scope.logDate = <%=ar.nowTime%>;
    $scope.comment = "";
    $scope.showThanks = false;
    console.log("starting");
    
    $scope.submitComment = function() {
        var errUp = {};
        errUp.errNo = $scope.log_number;
        errUp.logDate = $scope.logDate;
        errUp.comment = $scope.comment;
        var postdata = angular.toJson(errUp);
        console.log("sending this: ", errUp);
        $http.post("<%=ar.baseURL%>t/su/submitComment", postdata)
        .success( function(data) {
            console.log("got a response: ", data);
            $scope.showThanks = true;
        })
        .error( function(data) {
           console.log("got error: ", data);
        });        
    }
});
</script>

</head>


<style type="text/css">
td {
    padding:100;
    border:10;
    margin:10;
    vertical-align:top;
}
.spacey tr td {
    padding: 5px 10px;
}
</style>
<body>
  <div ng-app="myApp" ng-controller="myCtrl" style="margin:50px">

    <nav class="navbar navbar-default appbar">
      <div class="container-fluid">
        <!-- Logo Brand -->
        <a class="navbar-brand" href="<%=ar.retPath%>" title="Weaver Home Page">
          <img class="hidden-xs" alt="Weaver Icon" src="<%=ar.retPath%>bits/header-icon.png">
          <h1>Weaver</h1>
        </a>
      </div>
    </nav>
    
    <div>
        <div class="page-name">
            <h1 id="mainPageTitle"
                title="This is the title of the discussion topic that all these topics are attached to">
                Sorry, Weaver can't Handle that Request
            </h1>
        </div>
        
        <div class="guideVocal">
            For some reason, the system is not able to handle that request.
            Don't worry, there is probably a perfectly good reason, but the 
            program just can't figure it out.
            <br/>
            In this case, what we do is to display the information below 
            and somtimes this provides a clue to determine why the program can't
            figure out the request it was given.
            <br/>
            In some cases you can go back to the last page, change what you entered, and try again.
            In other cases the system may need the attention of an administrator.
        </div>
    
    <%
    if (display_exception==null) {
        %>
        <span style="color:red">Error.jsp must be passed an exception object in the 'display_exception' parameter</span>
        <%
    }
    %>
    <table class="table"><tr style="border-top:2px white solid">
        <td>
            <img src="<%=ar.retPath %>assets/iconAlertBig.gif" title="Alert">&nbsp;&nbsp;
        </td>
        <td>
            <table class="table">
            <col style="min-width:120px">
            <col style="max-width:500px">
            <tr>
              <td>Description:</td>
              <td>
                <%
                int count = 0;
                Throwable t = display_exception;
                while (t!=null) {
                    count++;
                    ar.write("\n<div> ");
                    String msg = t.toString();
                    if (msg.startsWith("java.lang.Exception: ")) {
                        msg = msg.substring(21);
                    }
                    ar.writeHtml(msg);
                    t = t.getCause();
                    ar.write("</div>");
                }
                %>
               </td>
            </tr><tr>
              <td>Incident ID:</td>
              <td><%=log_number%> </td>
            </tr><tr>
              <td>Logged in as:</td>
              <td><% ar.writeHtml(ar.getBestUserId()); %> </td>
            </tr><tr>
              <td>URL:</td>
              <td><% ar.writeHtml(ar.getCompleteURL()); %> </td>
            </tr><tr>
              <td>Date & Time:</td>
              <td><% SectionUtil.nicePrintDateAndTime(ar.w, ar.nowTime); %> </td>
            </tr></table>
        </td>
    </tr></table>
    </div>
    
    
    <div class="guideVocal" ng-show="showThanks">
        Thanks for sending additional information, this has been recorded with the 
        error record.  If you need to make a correction, you can change and send your comment again.
    </div>
    <p ng-hide="showThanks">
        If you would like to bring this to the attention of the system administrators, 
        please provide a little more information about how you encountered this problem,
        and press the Send button.
    </p>
    
    <div>
    <textarea class="form-control" ng-model="comment"></textarea>
    <button ng-click="submitComment()" class="btn btn-primary btn-raised">Send Comment</button>
    </div>
</body>
</html>






