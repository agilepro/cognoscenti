<%@page errorPage="/spring/jsp/error.jsp"
%><%@ page session="true"
%><%@ page import="java.util.Iterator"
%><%@ page import="java.util.Map"
%><%@ page import="org.openid4java.message.*"
%><%

    org.socialbiz.cog.AuthRequest ar = org.socialbiz.cog.AuthRequest.getOrCreate(request, response, out);
    //AuthRequest authReq  = (AuthRequest)request.getAttribute("authReq");
    AuthRequest authReq  = (AuthRequest)application.getAttribute("authReq");

%>
<html xmlns="http://www.w3.org/1999/xhtml">
    <body onload="document.forms['openid-form-redirection'].submit();">
        <form name="openid-form-redirection" action="<%= authReq.getOPEndpoint() %>" method="post" accept-charset="utf-8">
    <%
        Map pm=authReq.getParameterMap();
        Iterator keyit=pm.keySet().iterator();

        while (keyit.hasNext())
        {
            String key=(String)keyit.next();
            String value=(String)pm.get(key);
            %><input type="hidden" name="<%
            ar.writeHtml(key);
            %>" value="<%
            ar.writeHtml(value);
            %>"/><%
        }
            
    %>
        </form>
    </body>
</html>