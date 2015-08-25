<%@ page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@ page session="true"
%><%@ page errorPage="error.jsp"
%><%@ page import="org.socialbiz.cog.ConfigFile"
%><%@ page import="org.socialbiz.cog.NGSession"
%><%@ page import="org.socialbiz.cog.ProfileRequest"
%><%@ page import="org.socialbiz.cog.ProfileRequest"
%><%@ page import="org.socialbiz.cog.UserPage"
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

    if (true) {throw new Exception("EmailLoginAction.jsp is no longer needed");}

    //don't allow login or registration if the configuration is not right
    ar.getCogInstance().assertInitialized();

    String go     = ar.reqParam("go");      //place to go on success
    String option = ar.reqParam("option");
    String email  = ar.reqParam("email");   //email address being verified
    String err    = ar.reqParam("err");     //place to go on error, pass message in session


    try {
        if (email.indexOf("@")<0)
        {
            throw new Exception("Please enter a complete valid email address.");
        }

        //find the user profile for this
        UserProfile up = UserManager.findUserByAnyId(email);


        //request the email if requested
        if (option.equals("Request Email To Reset Password"))
        {
            if (up==null)
            {
                throw new Exception("Did you type the email correctly?  No profile exists for '"+email
                    +"' on this server.  Use the 'Create Profile' option if you want to make a new account.");
            }

            UserPage anonPage = ar.getAnonymousUserPage();
            ProfileRequest newReq = anonPage.createProfileRequest(ProfileRequest.RESET_PASSWORD, email, ar.nowTime);
            newReq.sendEmail(ar, go);

            String gotowait = ar.retPath+"t/waitForEmail.htm?email="+URLEncoder.encode(email, "UTF-8")
                    +"&option="+URLEncoder.encode("Reset Password", "UTF-8")
                    +"&go="+URLEncoder.encode(go, "UTF-8");
            anonPage.saveFile(ar, "requested to change password for "+email);
            response.sendRedirect(gotowait);
            return;
        }
        else if (option.equals("Request Email To Create Profile"))
        {
            if (up!=null)
            {
                throw new Exception("A profile already exists for '"+email
                    +"' on this server.  Choose an email address that does not already have a profile, "
                    +"or use the 'Reset Password' option if you change the existing password.");
            }

            UserPage anonPage = ar.getAnonymousUserPage();
            ProfileRequest newReq = anonPage.createProfileRequest(ProfileRequest.CREATE_PROFILE, email, ar.nowTime);
            newReq.sendEmail(ar, go);

            String gotowait = ar.retPath+"t/waitForEmail.htm?email="+URLEncoder.encode(email, "UTF-8")
                    +"&option="+URLEncoder.encode("Create New Profile", "UTF-8")
                    +"&go="+URLEncoder.encode(go, "UTF-8");
            anonPage.saveUserPage(ar, "requested to create profile for "+email);
            response.sendRedirect(gotowait);
            return;
        }
        else if (!option.startsWith("Login"))
        {
            throw new Exception("Don't understand the option '"+option+"'.");
        }

        if (up==null)
        {
            throw new Exception("No profile for '"+email+"' exists on this server.  If email address is correct, "
                +"please click to receive an email invitation to create a profile.");
        }

        String password = request.getParameter("password");
        if (password==null || password.length()==0)
        {
            throw new Exception("Please enter a password.");
        }

        String reqURL = request.getRequestURL().toString();
        String returnToUrl = reqURL.substring(0,reqURL.lastIndexOf("/")+1)+"FujitsuProcessLeaves.jsp";


        //compare the password
        String recordedPass = up.getPassword();
        if (recordedPass==null || recordedPass.length()==0 || !recordedPass.equals(password) )
        {
            throw new Exception("The password given for "+email
                +" is incorrect.  Either enter the correct password, or click to receive email to reset the password.");
        }

        ar.setLoggedInUser(up, email);
        response.sendRedirect(go);
    }
    catch (Exception e)
    {
        //delay to avoid a person trying to discover other people's passwords
        Thread.sleep(3000);
        //error message from one page to another page is passed as a session attribute
        //so that it does not become a permanent part of the URL that the user can see
        session.setAttribute("error-msg", "Unable to log in as "+email+".  "+e.toString());
        response.sendRedirect(err);
    }
%>
