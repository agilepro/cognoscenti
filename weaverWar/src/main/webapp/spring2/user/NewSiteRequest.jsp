<%@page errorPage="/spring2/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.SharePortRecord"
%><%@page import="com.purplehillsbooks.weaver.SiteReqFile"
%><%@page import="com.purplehillsbooks.weaver.SiteRequest"
%><%@ include file="/include.jsp"
%><%


    Cognoscenti cog = ar.getCogInstance();
    UserProfile thisUser = ar.getUserProfile();
    if (thisUser==null) {
        throw new Exception("Thie page can only be accessed when logged in");
    }

    JSONObject newSite = new JSONObject();
    SiteRequest foundIt = null;
    JSONArray prevReqs = new JSONArray();

    SiteReqFile siteReqFile = new SiteReqFile(cog);
    List<SiteRequest> superRequests = siteReqFile.getAllSiteReqs();
    for (SiteRequest item : superRequests) {
        if (thisUser.hasAnyId(item.getRequester())) {
            JSONObject jo = new JSONObject();
            jo.put("siteName", item.getSiteName());
            jo.put("status", item.getStatus());
            jo.put("modTime", item.getModTime());
            prevReqs.put(jo);
            if ("requested".equals(item.getStatus())) {
                foundIt = item;
            }
        }
    }
    if (foundIt!=null) {
        newSite.put("siteName", foundIt.getSiteName());
        newSite.put("siteId", foundIt.getSiteId());
        newSite.put("purpose", foundIt.getDescription());
        newSite.put("requester", thisUser.getUniversalId());
        newSite.put("preapprove", "");
    }

    if (foundIt==null) {
        newSite.put("siteName", "");
        newSite.put("siteId", "");
        newSite.put("purpose", "");
        newSite.put("requester", thisUser.getUniversalId());
        newSite.put("preapprove", "");
    }



%>


<script type="text/javascript">

var app = angular.module('myApp');
var theOnlyScope = null;

app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Request a Weaver site");
    theOnlyScope = $scope;
    $scope.newSite = <%newSite.write(out, 2,2); %>;
    $scope.duplicateEmail = "";
    $scope.phase = 12;
    $scope.identityProvider = "<%ar.writeJS(ar.getSystemProperty("identityProvider"));%>";
    $scope.prevReqs = <% prevReqs.write(out,2,2); %>;

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

    $scope.next = function() {
        if ($scope.phase==12) {
            if (!$scope.newSite.siteName || $scope.newSite.siteName.length<5) {
                return;
            }
            $scope.newSite.siteId = $scope.getURLAddress($scope.newSite.siteName);
            $scope.phase=13;
        }
        else if ($scope.phase==13) {
            if (!$scope.newSite.siteId || $scope.newSite.siteId.length<4) {
                return;
            }
            $scope.newSite.siteId = $scope.getURLAddress($scope.newSite.siteId);
            $scope.phase=14;
        }
        else if ($scope.phase==14) {
            if (!$scope.newSite.purpose || $scope.newSite.purpose.length < 15) {
                alert("Please enter a longer purpose for the site.");
                return;
            }
            $scope.phase=15;
        }
        else if ($scope.phase==15) {
            $scope.phase=16;
        }
        else if ($scope.phase==16) {
            $scope.phase=17;
        }
    }
    $scope.prev = function() {
        if ($scope.phase>12) {
            $scope.phase = $scope.phase - 1;
        }
        else {
            $scope.phase = 1;
        }
    }

    $scope.submitItAll = function() {
        var postURL = "siteRequest.json";
        var postObj = $scope.newSite;
        var postData = angular.toJson(postObj);
        console.log("DOING IT:", postURL, postData)
        $http.post(postURL, postData)
        .success( function(data) {
            $scope.phase = 19;
        })
        .error( function(data, status, headers, config) {
            console.log("FAILURE: ",data);
            $scope.error = data;
            $scope.phase = 20;
        });
        $scope.phase = 18;
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

    $scope.alert = function(str) {
        alert(str);
    }

});

function reloadIfLoggedIn() {
    if (SLAP.loginInfo.verified) {
        theOnlyScope.loggedEmail = SLAP.loginInfo.userId;
        theOnlyScope.newSite.requester = SLAP.loginInfo.userId;
        theOnlyScope.phase = 12;
        theOnlyScope.$apply();
    }
}
function validateEmail(email) {
    var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return re.test(String(email).toLowerCase());
}
</script>




<style>
.spacey tr td {
    padding: 5px 10px;
}
.bigletters tr td {
    font-size: 20px;
}
</style>


<%@include file="../jsp/ErrorPanel.jsp"%>

<div style="max-width:500px;margin:20px" ng-app="myApp" ng-controller="myCtrl">


  <div ng-repeat="prev in prevReqs" class="guideVocal">
  Your site '{{prev.siteName}}' has been in status '{{prev.status}}' since {{prev.modTime|date}}.
  </div>

  <table class="table bigletters">

    <tr>
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



  <div ng-show="phase==12" class="well override" style="overflow: hidden">

    <p>A <i>site</i> is a place where you can create workspaces.
    You can have as many workspaces as you would like, one for each
    team you want to coordinate, and maybe a few more for shared use.
    All of this can be done in one site.</p>

    <p>A site can be accessed by any number of people, and you can
    control who has access to the site, and to each workspace.</p>

    <p><b>Step 2: </b> Please provide a full name for your site.</p>

    <p> Pick a short clear name that would be useful to people that don't already know
    about the group using the site.  You can change the name at any time.
    Just a few words, maybe 20 to 50 characters total.</p>

    <div class="form-group override">
        <label class="h6">
            Site Name
        </label>
        <input type="text" class="form-control" ng-model="newSite.siteName"/>
    </div>

    <button class="override btn btn-primary btn-raised float-end my-3" ng-click="next()"
            ng-show="newSite.siteName.length>5">Next</button>
    <button class="btn btn-primary btn-raised float-end  my-3" ng-click="alert('enter 6 or more letters into the name')" 
            ng-show="newSite.siteName.length<=5">Next</button>

  </div>

  <div ng-show="phase==13" class="well override">

    <p><b>Step 3: </b> Please provide a key for the URL.</p>

    <p>This will be part of your web address.
    Please specify a short key with only 4 to 8 characters.
    You are allowed to use simple letters and numbers or a hyphen.</p>

    <div class="form-group">
        <label class="h6">
            Site URL Key
        </label>
        <input type="text" class="form-control" ng-model="newSite.siteId"/>
    </div>

    <button class="btn btn-secondary btn-raised my-3" ng-click="prev()">Back</button>
    <button class="btn btn-primary btn-raised float-end  my-3" 
            ng-click="next()" ng-show="newSite.siteId.length>3">Next</button>

  </div>

  <div ng-show="phase==14" class="well override">

    <p><b>Step 4: </b> Describe the purpose of the site.</p>

    <p>Describe in a sentence or two the <b>purpose</b> of the site in a way that people who are not (yet) part of it will understand, and to help them know whether they should or should not be a member. <br/>
        This description will be available to the public if the site ever appears in a public list of sites.</p>

    <div class="form-group">
        <label class="h6">
            Site Purpose
        </label>
        <textarea class="form-control" ng-model="newSite.purpose"></textarea>
    </div>

    <button class="btn btn-secondary btn-raised my-3" ng-click="prev()">Back</button>
    <button class="btn btn-primary btn-raised my-3 float-end" 
            ng-click="next()"  ng-show="newSite.purpose.length>10">Next</button>
    <button class="btn btn-primary btn-raised my-3 float-end" ng-click="alert('enter 9 or more letters into the description')" 
            ng-show="newSite.purpose.length<=9">Next</button>

  </div>


  <div ng-show="phase==15" class="well override">

    <p><b>Step 5: </b> Enter 'Pre-approval Code' if you have one.</p>

    <p>If you have been given a pre-approval code, enter it here in order to
    expedite the creation of a site.
    </p>

    <p>If you do not have one, don't worry, you can still apply here and we
    will review your application shortly.
    </p>

    <div class="form-group">
        <label class="h6">
            Pre-approval Code
        </label>
        <input type="text" class="form-control" ng-model="newSite.preapprove"/>
    </div>

    <button class="btn btn-secondary btn-raised my-3" ng-click="prev()">Back</button>
    <button class="btn btn-primary btn-raised my-3 float-end" 
            ng-click="next()">Next</button>

  </div>

  <div ng-show="phase==16" class="well override">

    <p><b>Step 6: </b> Are you a robot?</p>

    <p>To protect the site from malicious attacks,
       please enter the smaller of 512 and 307 in the
       box below.
    </p>

    <div class="form-group">
        <label class="h6">
            Your Response
        </label>
        <input type="text" class="form-control" ng-model="newSite.capcha"/>
    </div>

    <button class="btn btn-secondary btn-raised my-3" ng-click="prev()">Back</button>
    <button class="bbtn btn-primary btn-raised my-3 float-end" 
            ng-click="next()"
            ng-show="newSite.capcha==='307'">Next</button>
 

  </div>

  <div ng-show="phase==17" class="well override"  style="overflow: hidden">
    <p><b>Step 7: </b> Submit</p>

    <p>Review all the information above, and confirm correct.
       If you want to change a value click on it.
    </p>
    <div class="form-group">
        <button class="btn btn-primary btn-raised my-3 float-end" 
            ng-click="submitItAll()">
            Request Site</button>
    </div>

  </div>

  <div ng-show="phase==18" class="well override">
    <p>Requesting site.</p>
  </div>
  <div ng-show="phase==19" class="well override">
    <p>The site has been requested, and an email sent to the
    administrator.  You will receive an email letting you know
    when it has been approved for use.</p>
  </div>
  <div ng-show="phase==20" class="well override">
    <p>Something went wrong with the request.
    Perhaps the information below will be helpful.</p>

    <ul>
    <li ng-repeat="msg in error.error.details">
      {{msg.message}}
    </li>
    </ul>

    <p>You might be able click on the value and correct the
    request to submit again, or you might need to contact
    the system administrator.  This piece of software
    can't tell you which at this point.</p>
  </div>

</div>
