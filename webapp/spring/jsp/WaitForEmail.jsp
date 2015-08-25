<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%
/*
Required parameter:

    1. email    : This is the new id which is need to be either added to existing profile or to create a new profile.
    2. go       : After adding or creating id to go to result url address.
    3. option   : This parameter is used which operation need to be performed.

Optional Parameter:

    1. msg              : This optional parameter is used show message.
    2. newProfileRequest: This parameter is used to check if request is for new profile.
    3. errorMsg         : This is session parameter which is used to show error message.
*/

    String email    = ar.reqParam("email");
    String go       = ar.reqParam("go");
    String option   = ar.reqParam("option");
    String msg      = ar.defParam("msg", null);
    String  newProfileRequest = ar.defParam("newProfileRequest", "yes");
    boolean suppressLogin = true;

    String err = ar.retPath+"t/waitForEmail.htm?email="+URLEncoder.encode(email, "UTF-8")
             +"&go="+URLEncoder.encode(go, "UTF-8")
             +"&option="+URLEncoder.encode(option, "UTF-8");

    //retrieve message if there is one, and clear it
    String errorMsg = (String) session.getAttribute("error-msg");
    session.setAttribute("error-msg", null);

%>

<%  if("no".equals(newProfileRequest)){%>
<script>
var postURL = "<%=ar.retPath %>t/addUserId.ajax?newid=<%ar.writeHtml(email);%>&go=<%ar.writeURLData(go);%>&isEmail=true";
    var transaction = YAHOO.util.Connect.asyncRequest('POST', postURL, resultAddEmail);
    var resultAddEmail =  {
        success: function(o) {
           var respText = o.responseText;
           var json = eval('(' + respText+')');
           if(json.msgType == "success"){
               alert("all ok");
           }else{
               showErrorMessage("Result", json.msg , "unable to send email." );
           }
       },
       failure: function(o) {
               alert("addUserId.ajax Error:" +o.responseText+" unable to send email.");
       }
    }
</script>

<%
    }

%>
    <div class="generalContent">
<% if (errorMsg!=null && errorMsg.length()>0) { %>
<p><b><font color="red"><% ar.writeHtmlWithLines(errorMsg); %></font></b></p>
<hr/>
<% } %>
<% if (msg!=null && msg.length()>0) { %>
<p><b><font color="red"><% ar.writeHtmlWithLines(msg); %></font></b></p>
<hr/>
<% } %>
</div>


<div class="generalHeading">Check your Email</div>
<div class="generalContent">
<p>An email message has been sent to <% ar.writeHtml(email); %>
   with a confirmation key in it.<br/>
   Find that email, and click on the link in that email,
   -or- copy the confirmation key into the following box.

</p>

<form action="<%=ar.baseURL%>t/waitForEmailAction.form" method="post" onsubmit="return isNullOrBlank('confkey','Confirmation Key');">
    <input type="hidden" name="go" value="<% ar.writeHtml(go); %>">
    <input type="hidden" name="err" value="<% ar.writeHtml(err); %>">
    <input type="hidden" name="email" value="<% ar.writeHtml(email); %>">
    <table class="generalPopupSettings">
        <tr>
            <td class="gridTableColummHeader_2" >Email:</td>
            <td style="width:20px;"></td>
            <td><% ar.writeHtml(email); %></td>
        </tr>
        <tr><td style="height:10px"></td></tr>
        <tr>
            <td class="gridTableColummHeader_2">Confirmation Key:</td>
            <td style="width:20px;"></td>
            <td><input type="text" id="confkey" name="mn" value="" size="50"></td>
        </tr>
        <tr><td style="height:10px"></td></tr>
        <tr>
            <td></td>
            <td style="width:20px;"></td>
            <td>

               <input type="submit" name="option" class="btn btn-primary"  value="<% ar.writeHtml(option); %>">

            </td>
        </tr>
    </table>
</form>

<p>With the correct confirmation key, pressing the button above will allow you to reset
the password of the specified email address.</p>

<hr/>
<p>If you are done waiting, use this link to <a href="<% ar.writeHtml(go); %>">return
to your original page</a>.</p>

</div>
<br/>

