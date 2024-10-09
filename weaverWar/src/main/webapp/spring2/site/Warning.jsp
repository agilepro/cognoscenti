<%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.RoleRequestRecord"
%><%
    UserProfile up = ar.getUserProfile();
    String userId = ar.getBestUserId();
    AddressListEntry ale = up.getAddressListEntry();
    String description = "";
    
    NGContainer ngc = ar.ngp;
    NGBook site;
    if (ngc instanceof NGBook) {
        site = (NGBook)ngc;
    }
    else {
        //this should never happen with this page.
        site = ((NGWorkspace)ngc).getSite();
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

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
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
            <% ale.writeLink(ar); %> ( <% ar.writeHtml(up.getPreferredEmail()); %> ) is not playing a role at the site level, and does not have permission to see this page.
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