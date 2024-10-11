<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.SharePortRecord"
%><%@page import="com.purplehillsbooks.weaver.SiteReqFile"
%><%@page import="com.purplehillsbooks.weaver.SiteRequest"
%><%@ include file="/include.jsp"
%><%


    Cognoscenti cog = ar.getCogInstance();
    if (ar.isLoggedIn()) {
        //should not have gotten here, this will force server to redirect
        response.sendRedirect("NewSiteApplication.htm?t="+System.currentTimeMillis());
        return;
    }


%>


<script type="text/javascript">

var app = angular.module('myApp');
var theOnlyScope = null;

app.controller('myCtrl', function($scope, $http, $modal) {
    theOnlyScope = $scope;
    $scope.newSite = {
        "preapprove": "",
        "purpose": "",
        "requester": "",
        "siteId": "",
        "siteName": ""
      };
    $scope.duplicateEmail = "";
    $scope.phase = 1;
    $scope.identityProvider = "<%ar.writeJS(ar.getSystemProperty("identityProvider"));%>";
    
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        console.log("Error: "+serverErr);
        errorPanelHandler($scope, serverErr);
    };

    $scope.getURLAddress = function(source) {
        var res = "";
        var str = source;
        var isInGap = false;
        for (i=0; i<str.length && res.length<8; i++) {
            var ch = str[i].toLowerCase();
            var isAddable = ( (ch>='a' && ch<='z') || (ch>='0' && ch<='9') );
            if (isAddable) {
                if (isInGap) {
                    //res = res + "-";
                    isInGap = false;
                }
                res = res + ch;
            }
            else {
                isInGap = res.length > 0;
            }
        }
        return res;
    }
    
    
    $scope.login = function() {
        window.location = "<%=ar.getSystemProperty("identityProvider")%>?openid.mode=quick&go=<%=URLEncoder.encode(ar.realRequestURL, "UTF-8")%>";
    }
    
    $scope.verifyEmail = function() {
        if ($scope.newSite.requester != $scope.duplicateEmail) {
            alert("Please enter the same email address in each box");
            return;
        }
        if (!validateEmail($scope.newSite.requester)) {
            alert("Please check your email, it does not appear to be a valid email address form: "
                  +$scope.newSite.requester);
            return;
        }
        var message = {};
        message.msg = "This message send by Weaver to verify your email.  If you have requested this, then click on the link below and set your password to continue.";
        message.userId = $scope.newSite.requester;
        message.return = "<%ar.writeJS(ar.realRequestURL);%>";
        message.subject="Confirm your email address";
        $scope.phase = 2;
        SLAP.sendInvitationEmail(message, function(data) {
            $scope.phase = 3;
            $scope.$apply();
        });        
    }
    
    console.log("SLAP", SLAP);
});

function reloadIfLoggedIn() {
    if (SLAP.loginInfo.verified) {
        //force the server to redirect the browser
        window.location = "NewSiteApplication.htm?t="+new Date().getTime();
    }
}
function validateEmail(email) {
    var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return re.test(String(email).toLowerCase());
}
</script>

<div class="bodyWrapper"  style="margin:50px">

<style>
.bigletters tr td {
    font-size: 20px;
}
</style>


<%@ include file="AnonNavBar.jsp" %>

<div style="max-width:500px" ng-app="myApp" ng-controller="myCtrl">

  <h1>Request a Weaver site.</h1>
  
  
  <table class="table bigletters">
  
    <tr ng-show="phase>1">
      <td>Requester:</td>
      <td>{{newSite.requester}}</td>
    </tr>
    <tr ng-show="phase>12">
      <td>Site Name:</td>
      <td ng-click="phase=12">{{newSite.siteName}}</td>
    </tr>
    <tr ng-show="phase>13">
      <td>URL Key:</td>
      <td ng-click="phase=13">{{newSite.siteId}}</td>
    </tr>
    <tr ng-show="phase>14">
      <td>Purpose:</td>
      <td ng-click="phase=14">{{newSite.purpose}}</td>
    </tr>
    <tr ng-show="phase>15">
      <td>Pre-approval:</td>
      <td ng-click="phase=15">{{newSite.preapprove}}</td>
    </tr>
    <tr>
      <td>&nbsp;</td>
      <td></td>
    </tr>
  </table>
  
  <div ng-show="phase==1" class="well">
    <p><b>Step 1: </b> Your Email Address.</p>
    
    <p>Do you have a Weaver account?  If you do, please log in now.</p>
       
    <button class="btn btn-primary btn-raised" 
            ng-click="login()">Login</button>
    <hr/>        
    <p>Otherwise we can set you up with a login account right away.
    Enter the email address that you will use to log into the site, 
    and to which we will send correspondence about the site. 
    We will send you an email to verify your email address, 
    and you can set your password right away.</p>

    <div class="form-group">
        <label>
            Owner Email
        </label>
        <input type="text" class="form-control" ng-model="newSite.requester"/>
    </div>

    <div class="form-group">
        <label>
            Enter it again
        </label>
        <input type="text" class="form-control" ng-model="duplicateEmail"/>
    </div>
    
    <button class="btn btn-primary btn-raised" 
            ng-click="verifyEmail()">Send Email Verification</button>

  </div>

  <div ng-show="phase==2" class="well">
    <p>Sending email to '{{newSite.requester}}.'</p>
  </div>
  <div ng-show="phase==3" class="well">
    <p>An email has been sent to <b>'{{newSite.requester}}.'</b>
    Please check your email inbox.  Use the link in that message
    to set a password for yourself, and to continue the process
    of creating a site.</p>
  </div>
  

    
  
</div>
</div>
