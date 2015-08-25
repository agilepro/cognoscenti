<%@ page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@ page session="true"
%><%@ page import="org.socialbiz.cog.ProfileRequest"
%><%@ page import="org.socialbiz.cog.UserPage"
%><%@ page import="org.socialbiz.cog.UtilityMethods"
%><%@ page import="java.io.File"
%><%@ page import="java.io.FileInputStream"
%><%@ page import="java.io.InputStreamReader"
%><%@ page import="java.io.IOException"
%><%@ page import="java.io.StringWriter"
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
    ar.assertLoggedIn("Can't add a user id..");

    String go     = ar.reqParam("go");
    String u     = ar.reqParam("u");
    String isEmailStr = ar.reqParam("isEmail");
    boolean isEmail = "true".equals(isEmailStr);
    String newid  = ar.reqParam("newid");
    boolean isNewUI=Boolean.parseBoolean(ar.defParam("isNewUI", null));

    //if parameter for email is not set at all, go back to the login page.
    if (isEmail && newid.indexOf("@")<0)
    {
        throw new Exception("Please enter a complete valid email address.");
    }

    //find the user profile for this
    UserProfile up = UserManager.getUserProfileByKey(u);

    //request the email if requested
    /*
    if (isEmail)
    {
        UserPage anonPage = ar.getAnonymousUserPage();
        ProfileRequest newReq = anonPage.createProfileRequest(ProfileRequest.ADD_EMAIL, newid, ar.nowTime);
        newReq.setUserKey(up.getKey());
        newReq.sendEmail(ar, go);
        String gotowait = ar.retPath+"t/waitForEmail.htm?email="+URLEncoder.encode(newid, "UTF-8")
            +"&option="+URLEncoder.encode(ProfileRequest.getPromptString(ProfileRequest.ADD_EMAIL), "UTF-8")
            +"&go="+URLEncoder.encode(go, "UTF-8");

        anonPage.saveUserPage(ar, "requested to add email "+newid);
        response.sendRedirect(gotowait);
        return;
    }
    else
    {
        String registerAddr = ar.retPath+"t/openIdLogin.form?go="+URLEncoder.encode(go)
                +"&err="+URLEncoder.encode(ar.getCompleteURL())
                +"&openid="+URLEncoder.encode(newid)
                +"&key="+URLEncoder.encode(up.getKey());
        response.sendRedirect(registerAddr);
    }
    */
    up.addId(newid.trim());
    up.setLastUpdated(ar.nowTime);
    UserManager.writeUserProfilesToFile();
    
    response.sendRedirect(go);
%>
