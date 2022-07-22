<%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.RoleRequestRecord"
%><%
    UserProfile up = ar.getUserProfile();
    String userId = ar.getBestUserId();
    AddressListEntry ale = up.getAddressListEntry();
    String description = "";
    
    NGContainer ngc = ar.ngp;
    boolean isRequested = false;
    String requestState = "";
    String requestMsg = "";
    long latestDate = 0;
    NGBook site;
    if (!(ngc instanceof NGWorkspace)) {
        site = (NGBook)ngc;
    }
    else {
        site = ((NGWorkspace)ngc).getSite();
    }
    
    String purpose = "";
    if (ngc instanceof NGWorkspace) {
        purpose = ((NGWorkspace)ngc).getProcess().getDescription();
    }
    NGRole primRole = ngc.getPrimaryRole();
    String primRoleName = primRole.getName();
    String oldRequestEmail = "";
    
    for (RoleRequestRecord rrr : ngc.getAllRoleRequest()) {
        if (up.hasAnyId(rrr.getRequestedBy())) {
            if (rrr.getModifiedDate()>latestDate) {
                isRequested = true;
                requestMsg = rrr.getRequestDescription();
                requestState = rrr.getState();
                latestDate = rrr.getModifiedDate();
                oldRequestEmail = rrr.getRequestedBy();
            }
        }
    }
    
%>
<!-- *************************** site / Warning.jsp *************************** -->
<style>
.warningBox {
    margin:30px;
    font-size:14px;
    width:500px;
}
</style>
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Not Executive");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.atts = "ss";
    $scope.enterMode = false;
    $scope.alternateEmailMode = false;
    $scope.enterRequest = "<% ar.writeJS(requestMsg); %>";
    $scope.requestState = "<% ar.writeJS(requestState); %>";
    $scope.oldRequestEmail = "<% ar.writeJS(oldRequestEmail); %>";
    $scope.isRequested = <%=isRequested%>;
    $scope.requestDate = <%=latestDate%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    
    $scope.takeStep = function() {
        $scope.enterMode = true;
        $scope.alternateEmailMode = false;
    }
    $scope.anotherAddress = function() {
        $scope.enterMode = false;
        $scope.alternateEmailMode = true;
    }
    
    $scope.roleChange = function() {
        var data = {};
        data.op = 'Join';
        data.roleId = '<%ar.writeJS(primRoleName);%>';
        data.desc = $scope.enterRequest;
        console.log("Requesting to ",data);
        var postURL = "rolePlayerUpdate.json";
        var postdata = angular.toJson(data);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            alert("OK, you have requested membership")
        })
        .error( function(data, status, headers, config) {
            console.log("GOT ERROR ",data);
            $scope.reportError(data);
        });
    };

});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

  
    <div class="generalArea">
      <table><tr><td>
        <img src="<%=ar.retPath %>assets/iconAlertBig.gif" title="Alert">
      </td><td>
        <div class="warningBox">
            <% ale.writeLink(ar); %> ( <% ar.writeHtml(up.getPreferredEmail()); %> ) is not in "<b class="red"><%ar.writeHtml(primRoleName);%></b>" role of this workspace.
        </div>
      </td></tr>
      <tr><td>
      </td><td>
        <div class="warningBox">
            You are currently logged in as <% ale.writeLink(ar); %>.  If this is not 
            correct then choose logout and log in as the correct user.
            In order to see this section, you need to be a owner or an executive 
            of the site in order to access this page.  
        </div>
        <div class="warningBox">
            <table class="table">
              <tr>
                <td>
                  Site:
                </td>
                <td>
                    <b><% ar.writeHtml(ar.ngp.getFullName()); %></b>
                </td>
              </tr>
              <tr>
                <td>
                    Run By: 
                </td>
                <td>
                <%         
                   NGRole admins = ar.ngp.getSecondaryRole(); 
                   boolean needsComma = false;
                   for (AddressListEntry player : admins.getExpandedPlayers(ar.ngp)) {
                       if (needsComma) {
                           ar.write(", ");
                       }
                       ar.write("<span>");
                       player.writeLink(ar);
                       ar.write("</span>");
                       needsComma = true;
                   }
                %>
                </td>
              </tr>
              <tr>
                <td></td><td></td>
              </tr>
            </table> 
        </div>
            </td></tr></table>
      

      
      {{errorMsg}}
      
    </div>

</div>