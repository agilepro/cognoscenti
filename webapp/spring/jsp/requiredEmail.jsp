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
    <div class="pageHeading">Set Email Address</div>
    <div class="pageSubHeading">
        Please set or confirm your email address in your profile
    </div>
    <br/>
    <table width="600">
    <tr class="reRow">
        <td class="linkWizardHeading">You Need an EMail Address:</td>
    </tr>
    <tr class="reRow">
    <td class="reElem">Before going any further, you need to specify your email address,
        and confirm it.    Email address is required to send notifications and messages.
        You email address will not be set until you confirm it with the confirmation key.</td>
    </tr>
    <form action="<%= ar.retPath %>t/requiredEmail.form" method="post">
    <input type="hidden" name="go" value="<%= ar.getCompleteURL() %>">

    <tr class="reRow">
         <td class="reElem"><input type="text" name="email" size="50"> &nbsp;
             <input type="submit" name="cmd" value="Send Email" class="btn btn-primary"></td>
    </tr>

    <tr class="reRow">
         <td class="reElem">Enter your email address above and click 'Send Email'
         in order to have a message with a confirmation key sent to you.
         It should arrive within a couple minutes, and if it doesn't you can request
         another to be sent.</td>
    </tr>

    <tr class="reRow">
         <td class="reElem"><hr/></td>
    </tr>

    <tr class="reRow">
         <td class="reElem">Check your email inbox. When the message arrives, copy the confirmation key below and click 'Confirmation Key'
         in order to actually add this email address to your profile.</td>
    </tr>

    <tr class="reRow">
         <td class="reElem"><input type="text" name="cKey" size="50"> &nbsp;
             <input type="submit" name="cmd" value="Confirmation Key"  class="btn btn-primary"></td>
    </tr>

    <tr class="reRow">
         <td class="reElem"></td>
    </tr>

    <tr class="reRow">
         <td class="reElem"></td>
    </tr>

    </form>
    </table>
</div>

