/*
 * Copyright 2013 Keith D Swenson
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Contributors Include: Shamim Quader, Sameer Pradhan, Kumar Raja, Jim Farris,
 * Sandia Yang, CY Chen, Rajiv Onat, Neal Wang, Dennis Tam, Shikha Srivastava,
 * Anamika Chaudhari, Ajay Kakkar, Rajeev Rastogi
 */

package org.socialbiz.cog.spring;

import java.net.URLEncoder;
import java.util.List;
import java.util.Vector;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.openid4java.consumer.ConsumerManager;
import org.openid4java.discovery.DiscoveryInformation;
import org.socialbiz.cog.AdminEvent;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.MicroProfileMgr;
import org.socialbiz.cog.ProfileRequest;
import org.socialbiz.cog.UserManager;
import org.socialbiz.cog.UserPage;
import org.socialbiz.cog.UserProfile;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.socialbiz.cog.util.SSLPatch;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.servlet.ModelAndView;
import org.workcast.json.JSONObject;
import org.workcast.ssoficlient.service.LoginServlet;

@Controller
public class LoginController extends BaseController {

    private ApplicationContext context;

    @RequestMapping(value = "/LogoutAction.htm", method = RequestMethod.GET)
    public void LogOutAction(HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        AuthRequest ar = null;
        String url = "";
        try
        {
            ar = AuthRequest.getOrCreate( request, response );
            url = ar.defParam( "go", ar.baseURL );
            ar.logOutUser();

            //if you actually log out, then you need to clear the cookies that control
            //automatic login.
            LoginServlet.clearAutoLoginCookies(response);
        }
        catch (Exception ex)
        {
            throw new NGException("nugen.operation.fail.logout", null , ex);
        }
        response.sendRedirect( url );
    }

    //this is the main point of redirection in order to log into the application
    @RequestMapping(value = "/EmailLoginForm.htm")
    public ModelAndView EmailIdLogInForm(HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        AuthRequest ar = null;
        try
        {
            ar = AuthRequest.getOrCreate( request, response );

            String go = ar.defParam( "go", ar.baseURL );
            if (ar.isLoggedIn()) {
                //this ADDS an id to the given profile
                String ssofiLogin = LoginServlet.getAddIdURL(go, go, "only_tenant");
                response.sendRedirect(ssofiLogin);
                return null;
            }
            else {
                //this logs you in to the given profile
                String ssofiLogin = LoginServlet.getLoginURL(go, go, "only_tenant");
                response.sendRedirect(ssofiLogin);
                return null;
            }
        }
        catch (Exception ex) {
            throw new NGException("nugen.operation.fail.redirecting.to.login.view", null , ex);
        }
    }

    @RequestMapping(value = "/isProfileExists.ajax")
    public void isProfileExists( HttpServletRequest request, HttpServletResponse response)throws Exception {
        AuthRequest ar = null;
        try{
            ar = AuthRequest.getOrCreate(request, response);
            boolean isNewUser=false;

            String email  = ar.reqParam("email");
            UserProfile up = UserManager.findUserByAnyId(email);
            JSONObject jo = new JSONObject();
            if( up == null ){
                isNewUser=true;
                jo.put(Constant.MSG_TYPE, Constant.No);
                jo.put("isNewUser" , String.valueOf(isNewUser));
                jo.put(Constant.MESSAGE , context.getMessage("noprofileexists.error",new Object[]{email}, ar.getLocale()));
            }
            else{
                jo.put(Constant.MSG_TYPE, Constant.YES);
                jo.put(Constant.MESSAGE , context.getMessage("profilealreadyexists.error",new Object[]{email}, ar.getLocale()));
            }

            NGWebUtils.sendResponse(ar, jo.toString());
            ar.logCompletedRequest();
        }catch(Exception ex){
            String message = NGWebUtils.getExceptionMessageForAjaxRequest(ex, ar.getLocale());
            NGWebUtils.sendResponse(ar, message);
            ar.logException(message, ex);
        }
    }

    @RequestMapping(value = "/waitForEmail.htm")
    public ModelAndView waitForEmailForm(HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try {
            AuthRequest.getOrCreate(request, response);
        }
        catch (Exception ex) {
            throw new NGException("nugen.operation.fail.wait.for.mail.page", null, ex);
        }
        return new ModelAndView("WaitForEmail");
    }


    @RequestMapping(value = "/{userId}/editUserProfile.htm")
    public ModelAndView changeUserProfile(HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        try
        {
            AuthRequest ar = AuthRequest.getOrCreate( request, response );
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }
            request.setAttribute( "realRequestURL", ar.getRequestURL() );
        } catch (Exception ex)
        {
            throw new NGException("nugen.operation.fail.edit.userprofile.page", null , ex);
        }
        return new ModelAndView( "editUserProfile" );

    }

    @Autowired
    public void setContext(ApplicationContext context) {
        this.context = context;
    }


    @RequestMapping(value = "/confirmThroughMail.htm", method = RequestMethod.GET)
    public void confirmThroughMail(
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);

            manageUserProfile(response, ar);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.confirm.email", null , ex);
        }
    }

    @RequestMapping(value = "/waitForEmailAction.form", method = RequestMethod.POST)
    public void waitForEmailAction(HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            manageUserProfile(response, ar);
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.confirmation", null , ex);
        }
    }

//TODO: figure out whether this is really needed or not
    private static void manageUserProfile(HttpServletResponse response, org.socialbiz.cog.AuthRequest ar) throws Exception {

        //don't allow login or registration if the configuration is not right
        ar.getCogInstance().assertInitialized();

        String go       = ar.defParam("go", null);   //where to go on success
        String option   = ar.reqParam("option");
        String email    = ar.reqParam("email").trim();
        String mn       = ar.reqParam("mn");         //the security token


        if (go==null) {
            go = ar.baseURL;
        }

        UserPage anonPage = ar.getAnonymousUserPage();
        ProfileRequest chosen=null;

        Vector<ProfileRequest> requests = anonPage.getProfileRequests();
        for (ProfileRequest pr : requests) {
            if (mn.equals(pr.getSecurityToken())) {
                chosen = pr;
            }
        }

        if (chosen == null) {
            throw new NGException("nugen.exception.request.with.matching.key.not.found",null);
        }

        //at this point, we have found a request, just need to check a few things
        email    = chosen.getEmail();

        int requestType = chosen.getReqType();
        if (option.equals("Create New Profile"))
        {
            if (requestType!=ProfileRequest.CREATE_PROFILE)
            {
                throw new NGException("nugen.exception.create.new.profile",null);
            }
            //this is the create profile option, at this point log them in and create profile
            if (ar.isLoggedIn())
            {
                UserProfile up = ar.getUserProfile();
                if (up.hasAnyId(email))
                {
                    //the user already (somehow) created and logged in for this
                    //profile, so ignore it.
                    //Always present the option to change the password.
                    String changepass =ar.retPath+"t/changePassword.htm?go="
                            +URLEncoder.encode(go,"UTF-8")
                            +"&key="+up.getKey();
                    response.sendRedirect(changepass);
                }

                throw new NGException("nugen.exception.user.login.conflict.for.create.profile",new Object[]{email});
            }

            if (UserManager.findUserByAnyId(email)!=null) {
                throw new NGException("nugen.exception.cant.create.new.profile", new Object[]{email});
            }

            //at this point log them in and create profile
            UserProfile up = UserManager.createUserWithId(null, email);
            anonPage.removeProfileRequest(chosen.getId());
            anonPage.saveFile(ar, "requested to create profile for "+email);
            ar.setLoggedInUser(up, email,null,null);
            UserManager.writeUserProfilesToFile();

            //remove micro profile if exists.
            MicroProfileMgr.removeMicroProfileRecord(email);
            MicroProfileMgr.save();


            ar.getSuperAdminLogFile().createAdminEvent(up.getKey(), ar.nowTime,up.getPreferredEmail(), AdminEvent.NEW_USER_REGISTRATION);
            String changepass =ar.retPath+"t/changePassword.htm?go="+URLEncoder.encode(go,"UTF-8")
                 +"&key="+up.getKey();
            response.sendRedirect(changepass);
        }
        else if (option.equals("Reset Password"))
        {
            if (requestType!=ProfileRequest.RESET_PASSWORD)
            {
                throw new NGException("nugen.exception.request.password.not.possible",null);
            }

            //this is the create profile option, at this point log them in and create profile
            UserProfile up;
            if (ar.isLoggedIn())
            {
                up = ar.getUserProfile();
                if (!up.hasAnyId(email))
                {
                    throw new NGException("nugen.exception.user.login.conflict.for.change.pwd",new Object[]{email});
                }
            }
            else
            {
                up = UserManager.findUserByAnyId(email);
                if (up==null)
                {
                    throw new NGException("nugen.exception.cant.change.password",new Object[]{email});
                }

                //at this point log them in and create profile
                Thread.sleep(3000);
                ar.setLoggedInUser(up, email,null,null);
            }
            anonPage.removeProfileRequest(chosen.getId());
            anonPage.saveUserPage(ar, "requested to change password for "+email);
            UserManager.writeUserProfilesToFile();

            String changepass = ar.retPath+"t/changePassword.htm?go="+URLEncoder.encode(go,"UTF-8")
                 +"&key="+up.getKey();
            response.sendRedirect(changepass);
        }
        else if (option.equals("Add Email"))
        {
            if (requestType!=ProfileRequest.ADD_EMAIL)
            {
                throw new NGException("nugen.exceptionhandling.request.not.completed",new Object[]{requestType});
            }

            UserProfile up = ar.getUserProfile();
            if (!ar.isLoggedIn())
            {
                throw new NGException("nugen.exception.login.to.add.email",null);
            }

            if (!up.getKey().equals(chosen.getUserKey()))
            {
                throw new NGException("nugen.exception.login.with.correct.email", new Object[]{chosen.getUserKey()});
            }

            anonPage.removeProfileRequest(chosen.getId());
            anonPage.saveUserPage(ar, "requested to change password for "+email);
            up.addId(email);
            up.setLastUpdated(ar.nowTime);
            UserManager.writeUserProfilesToFile();

            //remove micro profile if exists.
            MicroProfileMgr.removeMicroProfileRecord(email);
            MicroProfileMgr.save();

            response.sendRedirect(go);
        }
        else {
            throw new ProgramLogicError("sorry, implementation for request type '"+option+"' not yet implemented.");
        }
    }

/*
    @RequestMapping(value = "/EmailLoginAction.form", method = RequestMethod.POST)
     public void EmailIdLogInAction(HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        AuthRequest ar = AuthRequest.getOrCreate( request, response );
        String go  = ar.retPath;
        try
        {

            go     = ar.reqParam("go");      //place to go on success
            String option = ar.reqParam("option");
            String email  = ar.reqParam("email");   //email address being verified
            if (email.indexOf("@")<0)
            {
                redirectToLoginPage(ar, go, new NGException("nugen.exception.enter.valid.email",new Object[]{email}));
                return;
            }

            //find the user profile for this
            UserProfile up = UserManager.findUserByAnyId(email);


            //request the email if requested
            if (option.equals("Request Email To Reset Password"))
            {
                if (up==null)
                {
                    throw new NGException("nugen.exception.incorrect.email", new Object[]{email});
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
                    throw new NGException("nugen.exception.profile.already.exist", new Object[]{email});
                }

                UserPage anonPage = ar.getAnonymousUserPage();
                ProfileRequest newReq = anonPage.createProfileRequest(ProfileRequest.CREATE_PROFILE, email, ar.nowTime);
                newReq.sendEmail(ar, go);

                String gotowait = ar.retPath+"t/waitForEmail.htm?email="+URLEncoder.encode(email, "UTF-8")
                        +"&option="+URLEncoder.encode("Create New Profile", "UTF-8")
                        +"&go="+URLEncoder.encode(go, "UTF-8");
                anonPage.saveFile(ar, "requested to create profile for "+email);
                response.sendRedirect(gotowait);
                return;
            }
            else if (!option.startsWith("Login"))
            {
                throw new ProgramLogicError("Don't understand the option '"+option+"'.");
            }

            if (up==null)
            {
                redirectToLoginPage(ar, go, new NGException("nugen.exception.no.profile.for.given.email", new Object[]{email}));
                return;
            }

            String password = request.getParameter("password");
            if (password==null || password.length()==0)
            {
                redirectToLoginPage(ar, go, new NGException("nugen.exception.enter.password",null));
                return;
            }

            //compare the password
            String recordedPass = up.getPassword();
            if (recordedPass==null || recordedPass.length()==0 || !recordedPass.equals(password) )
            {
                redirectToLoginPage(ar, go, new NGException("nugen.exception.incorrect.password", new Object[]{email}));
                return;
            }

            ar.setLoggedInUser(up, email,null,null);
            response.sendRedirect(go);
        }
        catch(Exception ex){
            redirectToLoginPage(ar, go, new NGException("nugen.operation.fail.to.login", null , ex));
        }
    }
*/


    // Login is complicated and must be done exactly right, and there are many factors

    // 1. this JSP must be located at the root of the application so that when cookies
    //    are set, they are set for the entire application.
    //
    // 2. This page is the first step in the OpenID protocol dance.  This page redirects
    //    to the OpenId provider, and then that will reirect to second step page.
    //
    // 3. Second step page = FujitsuProcessLeaves.jsp
    //    Name of second step page is visible to user, and must be name of application.
    //
    // 4. Parameters to this page are as follows:
    //    go = the page to return to when successful
    //    error = the page to redirect to when something fails
    //    openid = the id that user have provided for authentication
    //
    // 5. Values passed to the second step are passed in the session object, which
    //    unfortunately means that there is a small danger clash when a single user
    //    on  single machine attempts to log in with two browser windows at the same time.
    //    This is unlikely to be a serious problem.
    //
    // 6. Remember that the user may or may not be logged in.  For normal login they are
    //    not logged in, but there is also the case that they are adding an OpenId
    //    to an existing account, and in that case they are logged in to a user profile,
    //    and then separately are logging into a new OpenID.  Don't assume logged out.
    //
    // 7. When there is a failure, the error message will go in session attribute "error-msg"
    //    Receiving page must read this, and clear it.

    @RequestMapping(value = "/openIdLogin.form", method = RequestMethod.POST)
    public ModelAndView openIdLoginForm(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        request.setCharacterEncoding("UTF-8");
        AuthRequest ar = AuthRequest.getOrCreate(request, response);

        String uopenid = ar.reqParam("openid");    //id user trying to log in as
        String go      = ar.reqParam("go");        //when to go when successful
        String err     = ar.reqParam("err");       //where to go if it fails, adding a msg parameter
        String upKey   = ar.defParam("key", null); //optional: user profile this openid is being added to
        String option  = ar.reqParam("option");    //which operation are we doing here?
        HttpSession session = request.getSession();


        String autoLogin   = ar.defParam("autoLogin",null);
        if(autoLogin!= null){
            session.setAttribute("autoLogin",  autoLogin); // autoLogin flag
            session.setAttribute("openid",  uopenid);  // This is the openid provided by user.
        }



        uopenid = uopenid.trim();
        try
        {
            //handle special case of template login by converting the simple ID
            //into an open id with a template.
            if ("Login2".equals(option))
            {
                String template = ar.reqParam("template");
                int idPos = template.indexOf("{id}");
                if (idPos>0)
                {
                    String prePart = template.substring(0,idPos);
                    String postPart = template.substring(idPos+4);
                    uopenid = prePart + uopenid + postPart;
                }
            }

            if (uopenid.indexOf('@')>=0)
            {
                throw new NGException("nugen.exception.incorrect.openid",null);
            }

            ConsumerManager manager = getConsumerManager(session);

            String returnToUrl = ar.baseURL + "t/Cognoscenti.htm";

            // I don't like this hack, but I don't see any other way.  We need to redirect the user
            // back to the page they were on when they were logging in.  If we pass this as a parameter
            // in the returnToUrl, then they have to log into each page, since the OpenID site
            // asks for a verification for each return-to URL.
            // Solution here is store in the "session" the page that you were logging in to, and
            // retrieve that from the session after authentication.  This is a problem only if
            // one person logging in to two pages at once -- seems relatively unlikely and safe.
            session.setAttribute("login-page", go);
            session.setAttribute("login-err",  err);

            // there may be a different profile with the openid, if this user is trying to
            // move the openid from the old profile to the current profile.  To be sure to update the
            // and confirm the right user profile, the key is stored here for use later.
            if (upKey!=null)
            {
                session.setAttribute("user-profile-key", upKey);
            }

            // perform discovery on the user-supplied identifier
            List<?> discoveries = manager.discover(uopenid);
            if (discoveries==null) {
                throw new NGException("nugen.exception.client.manager.discover.null",null);
            }

            // attempt to associate with an OpenID provider
            // and retrieve one service endpoint for authentication
            DiscoveryInformation discovered = manager.associate(discoveries);
            if (discovered==null) {
                throw new NGException("nugen.exception.client.manager.associate.null",null);
            }

            // store the discovery information in the user's session
            session.setAttribute("openid-disco", discovered);

            // obtain a AuthRequest message to be sent to the OpenID provider
            org.openid4java.message.AuthRequest authReq = manager.authenticate(discovered, returnToUrl);

            response.sendRedirect(authReq.getDestinationUrl(true));
        }
        catch (Exception e)
        {
            String msg = "Unable to verify the supplied OpenID ("+uopenid
            +").  This could be for a number of reasons.  It might be that "
            +"network connectivity to the open id provider is down, the server is off line "
            +"temporarily, or the OpenId was not entered correctly.Additional detail: "+e.toString();

            //error message from one page to another page is passed as a session attribute
            //so that it does not become a permanent part of the URL that the user can see
            session.setAttribute("error-msg", msg);
            response.sendRedirect(err);
        }
        return null;
    }


    public ConsumerManager getConsumerManager(HttpSession session) throws Exception
    {
        ConsumerManager cm = (ConsumerManager) session.getServletContext().getAttribute("consumermanager");
        if (cm == null)
        {
            cm = SSLPatch.newConsumerManager();
            session.getServletContext().setAttribute("consumermanager", cm);
        }
        return cm;
    }

    @RequestMapping(value = "/openIdLogin.htm", method = RequestMethod.GET)
    public ModelAndView openIdLogin(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        request.setCharacterEncoding("UTF-8");
        AuthRequest ar = AuthRequest.getOrCreate(request, response);

        String uopenid = ar.reqParam("openid");    //id user trying to log in as
        String go      = ar.reqParam("go");        //when to go when successful
        String err     = ar.reqParam("err");       //where to go if it fails, adding a msg parameter
        String upKey   = ar.defParam("key", null); //optional: user profile this openid is being added to
        HttpSession session = request.getSession();

        uopenid = uopenid.trim();
        try
        {
            ConsumerManager manager = getConsumerManager(session);

            String returnToUrl = ar.baseURL + "t/Cognoscenti.htm";

            session.setAttribute("login-page", go);
            session.setAttribute("login-err",  err);


            if (upKey!=null)
            {
                session.setAttribute("user-profile-key", upKey);
            }

            List<?> discoveries = manager.discover(uopenid);
            if (discoveries==null) {
                throw new NGException("nugen.exception.client.manager.discover.null",null);
            }

            DiscoveryInformation discovered = manager.associate(discoveries);
            if (discovered==null) {
                throw new NGException("nugen.exception.client.manager.associate.null",null);
            }

            session.setAttribute("openid-disco", discovered);

            org.openid4java.message.AuthRequest authReq = manager.authenticate(discovered, returnToUrl);

            response.sendRedirect(authReq.getDestinationUrl(true));
        }
        catch (Exception e)
        {
            String msg = "Unable to verify the supplied OpenID ("+uopenid
            +").  This could be for a number of reasons.  It might be that "
            +"network connectivity to the open id provider is down, the server is off line "
            +"temporarily, or the OpenId was not entered correctly.Additional detail: "+e.toString();

            //error message from one page to another page is passed as a session attribute
            //so that it does not become a permanent part of the URL that the user can see
            session.setAttribute("error-msg", msg);
            response.sendRedirect(err);
        }
        return null;
    }

}
