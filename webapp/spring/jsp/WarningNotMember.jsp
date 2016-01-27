<%@page import="org.socialbiz.cog.NGRole"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.RoleRequestRecord"
%><%
    UserProfile up = ar.getUserProfile();
    AddressListEntry ale = up.getAddressListEntry();
    
%>
<style>
.warningBox {
    margin:30px;
    font-size:14px;
    width:500px;
}
</style>
    <div class="generalArea">
      <table><tr><td>
        <img src="<%=ar.retPath %>assets/iconAlertBig.gif" title="Alert">
      </td><td>
        <div class="generalContent warningBox">
            <% ale.writeLink(ar); %> is not a "<b class="red">Member</b>" of this workspace.
        </div>
      </td></tr>
      <tr><td>
      </td><td>
        <div class="generalContent warningBox">
            You are currently logged in as <% ale.writeLink(ar); %>.  If this is not 
            correct then choose logout and log in as the correct user.
            In order to see this section, you need to be a member of the workspace.  
        </div>
        <div class="generalContent warningBox">
            This workspace (<b><% ar.writeHtml(ar.ngp.getFullName()); %></b>) has been set up by 
            <%
             
               NGRole admins = ar.ngp.getSecondaryRole(); 
               for (AddressListEntry player : admins.getExpandedPlayers(ar.ngp)) {
                   ar.write("<span>");
                   player.writeLink(ar);
                   ar.write(", </span>");
               }
            %>
            for the following purpose:<br/>
            <i><% ar.writeHtml(((NGPage)ar.ngp).getProcess().getDescription()); %></i>
        </div>
        <div class="generalContent warningBox">
            If you think you should be a member 
            then please:  <br/>
            <button class="btn btn-primary">Request Membership</button>
        </div>
      </td></tr></table>
    </div>
