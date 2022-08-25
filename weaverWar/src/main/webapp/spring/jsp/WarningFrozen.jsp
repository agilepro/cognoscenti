<%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.RoleRequestRecord"
%><%
    UserProfile up = ar.getUserProfile();
    String userId = ar.getBestUserId();
    AddressListEntry ale = up.getAddressListEntry();
    String description = "";
    
    if (!(ar.ngp instanceof NGWorkspace)) {
        throw new Exception("SITE request was directed to a JSP folder page inappropriately");
    }
    NGWorkspace ngw = (NGWorkspace) ar.ngp;
    NGBook site = ngw.getSite();
    
    
    String purpose = ngw.getProcess().getDescription();
    boolean isDeleted = ngw.isDeleted();
    boolean isFrozen = ngw.isFrozen();
    
    String mainMessage = "This workspace has been frozen to prevent change.";
    if (isDeleted) {
        mainMessage = "This workspace is marked as deleted.  A deleted workspace is frozen to prevent change.";
    }
    
%>
<style>
.warningBox {
    margin:30px;
    font-size:20px;
    font-weight:300;
    width:500px;
}
</style>
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Frozen Workspace");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    
    
});

</script>

<!--WarningNotMember.jsp-->
<div>

<%@include file="ErrorPanel.jsp"%>

  
    <div class="generalArea">
      <table><tr><td>
        <img src="<%=ar.retPath %>assets/iconAlertBig.gif" title="Alert">
      </td><td>
        <div class="generalContent warningBox">
            Sorry, we can't do that operation.
        </div>
      </td></tr>
      <tr><td>
      </td><td>
        <div class="generalContent warningBox">
            <%=mainMessage %>
        </div>
            
        <div class="generalContent warningBox">
            Frozen workspaces can not be altered or updated in any way.
            A frozen workspace can be unfrozen by the administrator.
        </div>
      </td></tr>
      <tr><td>
      </td><td>
        <div class="generalContent warningBox">
            <table class="table">
              <tr>
                <td>
                  Workspace:
                </td>
                <td>
                    <b><% ar.writeHtml(ar.ngp.getFullName()); %></b>
                </td>
              </tr>
              <tr>
                <td>
                    Admins: 
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
                <td>
                    Purpose: 
                </td>
                <td>
                   <% ar.writeHtml(purpose); %>
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