<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Program Logic -- requiredName.jsp is useful only for logged in users and should only appear then.");
    UserProfile up = ar.getUserProfile();

    String fullName = up.getName();

%>
<style>
    .reRow {height:50px;padding:15px}
    .reHead {padding:15px;text-align:left;font-weight:bold;}
    .reElem {padding:15px;vertical-align:top;}
</style>
<div>
    <div class="pageHeading">Set Name</div>
    <div class="pageSubHeading">
        Please set your name in your profile
    </div>
    <br/>
    <table width="600">
    <tr class="reRow">
        <td class="linkWizardHeading">You Need A Name:</td>
    </tr>
    <tr class="reRow">
    <td class="reElem">Before going any further, please specify a display name
                             that will be used to identify you to others when you do or own things.
                             Please specify your <b>full name</b> because over time there may be
                             many people using this server.  You can change this later at any time.</td>
    </tr>
    <form action="<%= ar.retPath %>t/requiredName.form" method="post">
    <input type="hidden" name="go" value="<%= ar.getCompleteURL() %>">

    <tr class="reRow">
         <td class="reElem"><input type="text" name="dName" size="50"> &nbsp;
             <input type="submit" value="Set Display Name" class="btn btn-primary"></td>
    </tr>

    <tr class="reRow">
         <td class="reElem"></td>
    </tr>

    </form>
    </table>
</div>

