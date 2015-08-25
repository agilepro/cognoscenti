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
    ar.assertLoggedIn("Can't access to the FillProfile page.");

    String go     = ar.reqParam("go");
    String option = ar.reqParam("option");
    String username  = ar.reqParam("username");


    //find the user profile for this
    UserProfile up = ar.getUserProfile();

    //request the email if requested
    if ("Update".equals(option))
    {
        up.setName(username);
        up.setLastUpdated(ar.nowTime);
        UserManager.writeUserProfilesToFile();
    }
    else
    {
        throw new Exception("Don't understand the option '"+option+"'.");
    }

    response.sendRedirect(go);
%>
