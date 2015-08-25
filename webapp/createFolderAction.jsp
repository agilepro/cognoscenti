<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page errorPage="error.jsp"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.dms.FolderAccessHelper"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to create a folder.  ");

    // Return address required to return the page
    String goPage = request.getParameter("go");
    if (goPage == null || goPage.length()==0)
    {
       goPage = "UserHome.jsp?" + ar.getUserProfile().getKey();
    }
    String action = request.getParameter("action");

    //first, handle cancel operation.
    if ("Cancel".equalsIgnoreCase(action))
    {
        response.sendRedirect(goPage);
        return;
    }else{
        FolderAccessHelper.updateConnection(ar);
    }

    response.sendRedirect(goPage);


%>

