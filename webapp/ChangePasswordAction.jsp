<%@ page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@ page session="true"
%><%@ page errorPage="error.jsp"
%><%@ page import="org.socialbiz.cog.UtilityMethods"
%><%@ page import="java.io.File"
%><%@ page import="java.io.FileInputStream"
%><%@ page import="java.io.IOException"
%><%@ page import="java.io.InputStreamReader"
%><%@ page import="java.net.URLEncoder"
%><%@ page import="java.util.Iterator"
%><%@ page import="java.util.List"
%><%@ page import="java.util.Map"
%><%@ page import="java.util.Properties"
%><%@ page import="javax.servlet.http.Cookie"
%><%@ page import="javax.servlet.http.HttpServletRequest"
%><%@ page import="javax.servlet.http.HttpServletResponse"
%><%@ page import="javax.servlet.http.HttpSession"
%><%@ page import="org.openid4java.OpenIDException"
%><%@ page import="org.openid4java.consumer.ConsumerManager"
%><%@ page import="org.openid4java.consumer.InMemoryConsumerAssociationStore"
%><%@ page import="org.openid4java.consumer.InMemoryNonceVerifier"
%><%@ page import="org.openid4java.discovery.DiscoveryInformation"
%><%@ page import="org.openid4java.discovery.Identifier"
%><%@ page import="org.openid4java.message.*"
%><%@ page import="org.openid4java.message.ax.AxMessage"
%><%@ page import="org.openid4java.message.ax.FetchRequest"
%><%@ page import="org.openid4java.message.ax.FetchResponse"
%><%@ include file="functions.jsp"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Must be logged in to set your password");

    String go     = ar.reqParam("go");
    String option = ar.reqParam("option");

    UserProfile up = ar.getUserProfile();

    if ("Return".equals(option))
    {
        response.sendRedirect(go);
        return;
    }

    if ("Save Profile".equals(option))
    {
        String userName  = ar.reqParam("userName");
        String password  = ar.reqParam("password");
        String password2 = ar.reqParam("password2");
        if (password.length()==0 || password2.length()==0)
        {
            throw new Exception("RegisterAction.jsp requires non-empty password parameters");
        }

        if (!password.equals(password2))
        {
            throw new Exception("The two password values passed are not equal, and they need to be.  Please press back arrow, and specify your password again.");
        }

        up.setPassword(password);
        up.setName(userName);
        up.setLastUpdated(ar.nowTime);
        UserManager.writeUserProfilesToFile();
    }
    else
    {
        throw new Exception("Invalid option '"+option+"'.");
    }

    //all done, now lets go where we were going
    response.sendRedirect(go);
%>
