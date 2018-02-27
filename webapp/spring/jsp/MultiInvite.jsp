<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to edit roles");

    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    
    //page must work for both workspaces and for sites
    boolean isSite = ("$".equals(pageId));
    NGBook site;
    NGContainer ngc;
    if (isSite) {
        site = ar.getCogInstance().getSiteByKeyOrFail(siteId).getSite();
        ngc = site;
    }
    else {
        NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
        site = ngw.getSite();
        ngc = ngw;
    }
    ar.setPageAccessLevels(ngc);
    UserProfile uProf = ar.getUserProfile();
    
    JSONArray allRoles = new JSONArray();
    for (NGRole aRole : ngc.getAllRoles()) {
        allRoles.put(aRole.getName());
    }

%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {
    window.setMainPageTitle("Multi-Person Invite");
    $scope.allRoles  = <%allRoles.write(out,2,2);%>;
    $scope.targetRole = "Members";
    $scope.message = "Hello,\n\nYou have been asked by '<%ar.writeHtml(uProf.getName());%>' to"
                    +" participate in the workspace for '<%ar.writeHtml(ngc.getFullName());%>'."
                    +"\n\nThe links below will make registration quick and easy, and"
                    +" after that you will be able to"
                    +" participate directly with the others through the site.";
    $scope.emailList = "";
    $scope.results = [];
    $scope.retAddr = "<%=ar.baseURL%><%=ar.getResourceURL(ngc, "frontPage.htm")%>";

    
    $scope.blastIt = function() {
        list = parseList($scope.emailList);
        console.log("LIST", list);
        list.forEach( function(item) {
            console.log("inviting: ", item);
            var msg1 = {userId:item,msg:$scope.message,return:$scope.retAddr};
            SLAP.sendInvitationEmail(msg1, function(data) {
                $scope.results.push(item);
                $scope.$apply();
            });
        });
        $scope.emailList = "";
    }
});

function parseList(inText) {
    var outList = [];
    var oneAddress = "";
    for (var i=0; i<inText.length; i++) {
        var ch = inText.charAt(i);
        if (ch==";" || ch=="," || ch=="\n") {
            var trimmed = oneAddress.trim();
            if (trimmed.length>0) {
                outList.push(trimmed);
            }
            oneAddress = "";
        }
        else if (ch==" ") {
            //ignore char
        }
        else {
            oneAddress = oneAddress + ch;
        }
    }
    var trimmed = oneAddress.trim();
    if (trimmed.length>0) {
        outList.push(trimmed);
    }
    return outList;
}
</script>
<script src="../../../jscript/AllPeople.js"></script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="roleManagement.htm">Manage Roles</a></li>
        </ul>
      </span>
    </div>

    <style>
    .spacey tr td{
        padding: 8px;
    }
    .spacey tr:hover {
        background-color:lightgrey;
    }
    .spacey {
        width: 100%;
        max-width: 800px;
    }
    </style>
    
    <p><i>Add people to the project by clicking on selecting a role, entering a list of email addresses, and a message to send to each as an invitation.</i></p>


    <table class="spacey">
    
    <tr>
        <td>Role:</td>
        <td><select class="form-control" ng-model="targetRole" ng-options="value for value in allRoles"></select></td>
    </tr>
    <tr>
        <td>Addresses:</td>
        <td><textarea class="form-control" ng-model="emailList" style="height:150px;"
             placeholder="Enter list of email addresses on separate lines or separated by commas"></textarea></td>
    </tr>
    <tr>
        <td>Message:</td>
        <td><textarea class="form-control" ng-model="message" style="height:150px;"
            placeholder="Enter a message to send to all invited people"></textarea></td>
    </tr>
    <tr>
        <td></td>
        <td><button class="btn btn-primary btn-raised" ng-click="blastIt()">Send Invitations</button></td>
    </tr>
    <tr ng-show="results.length>0">
        <td></td>
        <td><div ng-repeat="res in results track by $index">Sent to: <b>{{res}}</b></div></td>
    </tr>
    <tr ng-show="results.length==0">
        <td></td>
        <td><div class="guideVocal"><i>No invitations sent yet.</i></div></td>
    </tr>
    </table>

</div>
<script src="<%=ar.retPath%>templates/RoleModalCtrl.js"></script>
<script src="<%=ar.retPath%>templates/InviteModal.js"></script>

