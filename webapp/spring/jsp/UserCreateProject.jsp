<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.SiteRequest"
%><%@page import="org.socialbiz.cog.SiteReqFile"
%><%
/*

Required Parameters:

*/
    ar.assertLoggedIn("You must be logged in to create a workspace");

    //note, this page only displays info for the current logged in user, regardless of URL
    UserProfile  userProfile =ar.getUserProfile();
    if (userProfile==null) {
        //this should never happen, and if it does it is not the users fault
        throw new ProgramLogicError("user profile setting is null.");
    }

    List<NGBook> memberOfSites = userProfile.findAllMemberSites();

    String upstream = ar.defParam("upstream", null);
    String desc = ar.defParam("desc", null);
    String pname = ar.defParam("pname", null);


%>
<script>


</script>


<style>
    table {}
    .acctListHead {padding:15px;text-align:left;font-weight:bold;}
    .acctListElem {padding:15px;vertical-align:top;}
</style>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

<%
if(memberOfSites.size()>0) {
%>
        <div class="generalContent">
            <div id="accountPaging"></div>
            <div id="accountsContainer">
                A new workspace must be created inside a site.
                Choose from the list below the site you would like to create
                this new workspace in.
                <br/><br/>
                <table class="acctList">
                <tr>
                <th class="acctListHead">Site Name</th>
                <th></th>
                <th class="acctListHead">Site Description</th>
                </tr>

                <%
                for (NGBook account : memberOfSites) {
                    String accountLink =ar.baseURL+"t/"+account.getKey()+"/$/accountCreateProject.htm";
                    %>
                    <tr>
                    <td class="acctListElem">
                    <form action="<%ar.writeHtml(accountLink);%>" method="get">
                    <%if (upstream!=null) {%><input type="hidden" value="<%ar.writeHtml(upstream);%>" name="upstream"><%}%>
                    <%if (desc!=null) {%><input type="hidden" value="<%ar.writeHtml(desc);%>" name="desc"><%}%>
                    <%if (pname!=null) {%><input type="hidden" value="<%ar.writeHtml(pname);%>" name="pname"><%}%>
                    <input type="submit" value="<%ar.writeHtml(account.getFullName());%>" class="btn btn-primary btn-raised">
                    </form></td>
                    <td class="acctListElem">
                    </td>
                    <td class="acctListElem"><%ar.writeHtml(account.getDescription());%>
                    </td>
                    </tr>
                <%
                }
                %>
                </table>
            </div>
        </div>
<%
}else{
%>
        <div class="generalContent">
            To create a workspace, you must have a space for that
            workspace in an account.  You have no sites at this time.
            Each workspace has to belong to a site, and you can only create a
            workspace in a site if you have been given access to do so.
            <br/>
            Create a Site in order to create a workspace<br/>.
            <form action="userAccounts.htm">
            <input type="submit" value="View Your Sites" class="btn btn-primary btn-raised">
            </form>
        </div>
<%
}
%>

</div>
