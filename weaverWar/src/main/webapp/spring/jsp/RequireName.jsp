<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%
    ar = AuthRequest.getOrCreateWithWriter(request, response, out);
    ar.assertLoggedIn("Program Logic -- RequireName.jsp is useful only for logged in users and should only appear then.");
    UserProfile up = ar.getUserProfile();

    String fullName = up.getName();

%>
<style>
    .reRow {
        padding:10px;
        max-width:500px;
    }
</style>
<div>

    <div class="reRow">
        Before going any further, please specify a display name
        that will be used to identify you to others when you do or own things.
    </div>
    <div class="reRow">
        Please specify your <b>Full Name</b> (first and last and everything needed
        to clearly identify you) because over time there may be
        many people using this server.  You can change this name later at any time.</td>
    </div>
    
    <form action="<%= ar.retPath %>t/RequiredName.form" method="post">
    <div class="reRow">
         <input type="hidden" name="go" value="<%= ar.getCompleteURL() %>">
         <input type="text" name="dName" class="form-control" size="50"> 
    </div>
    <div class="reRow">
         <input type="submit" value="Set Full Name" class="btn btn-primary btn-raised">
    </div>
    </form>
    
</div>

