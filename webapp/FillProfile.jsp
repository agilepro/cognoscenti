<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.PrintWriter"
%><%@page import="java.util.Properties"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't access to the FillProfile page.");

    String go     = ar.defParam("go", "main.jsp");

    uProf = ar.getUserProfile();
    String email = uProf.getPreferredEmail();


    pageTitle = "Fill In User Details";
%>
<%@ include file="Header.jsp"%>


<hr/>
<h3>Please Fill in Missing Details</h3>
<br/>
<% if (email==null || email.length()==0) { %>
<p>NOTE: your profile does not have an email address.
   Please edit you profile and add an email address so you can receive
   notifications from this server.</p>
<% } %>
<br/>
<table>
<form action="FillProfileAction.jsp" method="post" name="loginForm">
<input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
<input type="hidden" name="go" value="<% ar.writeHtml(go); %>"/>
<tr><td>Your Full Name:</td>
    <td><input type="text" name="username" value="<% ar.writeHtml(uProf.getName()); %>" size="50"/></td>
</tr>
<tr><td></td>
    <td><input name="option" type="submit" value="Update"/></td>
</tr>
</form>
</table>

<br/>
<hr/>


<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
