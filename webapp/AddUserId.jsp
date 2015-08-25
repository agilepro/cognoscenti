<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.PrintWriter"
%><%@page import="java.util.Properties"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to add a user id.");

    uProf = ar.getUserProfile();

    String go     = ar.defParam("go", "main.jsp");
    String u     = ar.defParam("u", "main.jsp");

    if (uProf==null)
    {
        throw new Exception("Program logic error, user profile is null, but user is logged in");
    }

    pageTitle = "Add User ID";
%>
<%@ include file="Header.jsp"%>


<hr/>
<h3>Add an OpenID</h3>

<table>
<col width="100">
<col width="500">
<form action="AddUserIdAction.jsp" method="post">
<input type="hidden" name="encodingGuard" value="%E6%9D%B1%E4%BA%AC"/>
<input type="hidden" name="u" value="<% ar.writeHtml(u); %>"/>
<input type="hidden" name="go" value="<% ar.writeHtml(go); %>"/>
<input type="hidden" name="isEmail" value="false"/>
<tr><td>OpenID:</td>
    <td><input type="text" name="newid" value="" size="50"/></td>
</tr>
<tr><td></td>
    <td><input name="option" type="submit" value="Add"/></td>
</tr>
<tr><td></td>
    <td>Note: when adding an OpenID, the system will attempt to authenticate
        the OpenID that you specify.  If you succeed in being authenticated
        then that OpenID will be added to the profile that you are currently
        logged into, and it will be removed from all other user profiles
        that contain that OpenID.
        When removing an ID, any profile that ends up without any ID at all
        will be entirely removed from the system.
    </td>
</tr>
</form>
</table>

<br/>
<hr/>
<h3>Add an Email Address</h3>

<table>
<col width="100">
<col width="500">
<form action="AddUserIdAction.jsp" method="post">
<input type="hidden" name="encodingGuard" value="%E6%9D%B1%E4%BA%AC"/>
<input type="hidden" name="u" value="<% ar.writeHtml(u); %>"/>
<input type="hidden" name="go" value="<% ar.writeHtml(go); %>"/>
<input type="hidden" name="isEmail" value="true"/>
<tr><td>Email Address:</td>
    <td><input type="text" name="newid" value="" size="50"/></td>
</tr>
<tr><td></td>
    <td><input name="option" type="submit" value="Add"/></td>
</tr>
<tr><td></td>
    <td>Note: when adding an Email address, the system will send you an email
        to confirm that you have that Email address.
        Clicking on the link that is sent in that email message will
        cause that Email address to be added to the profile that you are currently
        logged into, and it will be removed from all other user profiles
        that contain that Email address.
        When removing an ID, any profile that ends up without any ID at all
        will be entirely removed from the system.
    </td>
</tr>
</form>
</table>
<br/>
<hr/>


<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
