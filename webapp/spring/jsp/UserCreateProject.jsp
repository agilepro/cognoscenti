<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.SiteRequest"
%><%@page import="org.socialbiz.cog.SiteReqFile"
%><%
/*

Required Parameters:

*/
    ar.assertLoggedIn("You must be logged in to create a project");

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

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Watched Projects
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

<%
if(memberOfSites.size()>0) {
%>
        <div class="generalContent">
            <div id="accountPaging"></div>
            <div id="accountsContainer">
                A new project must be created inside a site.
                Choose from the list below the site you would like to create
                this new project in.
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
                    <input type="submit" value="<%ar.writeHtml(account.getFullName());%>" class="btn btn-primary">
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
            To create a project, you must have a space for that
            project in an account.  You have no sites at this time.
            Each project has to belong to a site, and you can only create a
            project in an site if you have been given access to do so.
            <br/>
            Create a Site in order to create a project<br/>.
            <form action="userAccounts.htm">
            <input type="submit" value="View Your Sites" class="btn btn-primary">
            </form>
        </div>
<%
}
%>

</div>
