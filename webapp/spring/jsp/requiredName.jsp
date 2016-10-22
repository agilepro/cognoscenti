<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Program Logic -- requiredName.jsp is useful only for logged in users and should only appear then.");
    UserProfile up = ar.getUserProfile();

    String fullName = up.getName();

%>
<style>
    .reRow td {padding:10px}
</style>
<div>

    <table width="600">
    <tr class="reRow">
        <td class="h2">You Need A Name!</td>
    </tr>
    <tr class="reRow">
        <td >Before going any further, please specify a display name
             that will be used to identify you to others when you do or own things.
             Please specify your <b>Full Name</b> (first and last and everything needed
             to clearly identify you) because over time there may be
             many people using this server.  You can change this later at any time.</td>
    </tr>
    <form action="<%= ar.retPath %>t/requiredName.form" method="post">
    <input type="hidden" name="go" value="<%= ar.getCompleteURL() %>">

    <tr class="reRow">
         <td><input type="text" name="dName" class="form-control" size="50"> </td>
    </tr>
    <tr class="reRow">
         <td><input type="submit" value="Set Display Name" class="btn btn-primary btn-raised"></td>
    </tr>

    </form>
    </table>
</div>

