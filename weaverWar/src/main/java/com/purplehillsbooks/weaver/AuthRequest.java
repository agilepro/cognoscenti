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

package com.purplehillsbooks.weaver;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.Writer;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Enumeration;
import java.util.List;
import java.util.Locale;
import java.util.Properties;
import java.util.ResourceBundle;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletContext;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import com.purplehillsbooks.weaver.exception.ProgramLogicError;
import com.purplehillsbooks.weaver.exception.ServletExit;
import com.purplehillsbooks.weaver.exception.WeaverException;
import com.purplehillsbooks.streams.HTMLWriter;

/**
 * AuthRequest is the "Authorized Request and Response" class for the
 * NuGen way of responding to HTTP requests. This class wraps both the
 * HTTPRequest and the HTTPResponse objects, and carries them around to
 * whatever handler. It also provides some uniform services around such a
 * request. For example:
 *
 * Identifying the user: this class will automatically detect in the headers
 * or in the session who the user is (by universal id) and it will maintain
 * cookies that the user or session might use in the future
 *
 * Parsing the path: provide consistent mechanism for parsing and decoding
 * the request path. You get an array of decoded strings.
 *
 * Access level: provides convenience routines to detect access levels that
 * a user should have and carries that to all methods that might need it.
 * Access may depend upon multiple things, like you might be logged in
 * and have a license active at the same time.
 *
 * Access limiting: there is a feature to limit your access to a lower level
 * so you can see what another person might see. It simulates this
 * access level, but not permanently: user can return regular level.
 *
 * Output Stream and Writer: handles this appropriately, including a
 * copy constructor that allows you to substitute a different writer.
 *
 * HTTPRequest & HTTPResponse: still lets you have access to these when needed.
 *
 * The standard patterns for all servlets should be:
 *
 * public void doGet(HttpServletRequest req, HttpServletResponse resp)
 * {
 * AuthRequest ar = AuthRequest.getOrCreate(req, resp);
 * ....
 * ar.flush();
 * ar.logCompletedRequest();
 * }
 *
 * All subsequent code should use the "ar" object, you can get the request
 * or response objects from that if necessary, but more important the userid,
 * path parsing, and access control will all be handled through that
 * consistently.
 * If a handler is a subroutine, pass the "ar" object for convenience.
 */
public class AuthRequest {
    public HttpServletRequest req;
    public HttpServletResponseWithoutBug resp;
    public HttpSession session;
    public NGSession ngsession;
    protected Cognoscenti cog;

    protected UserProfile user;
    protected UserProfile possibleUser;
    public String licenseid;
    public int nestingCount = 0;

    public License license = null;

    // address of this page that this servlet was mapped to, will be
    // something like "/p" or "/b". Same as "req.getServletPath()"
    public String servletPath = "";

    // the relative path parsed and properly URLDecoded into an
    // array of string.
    // private List<String> parsedPath = null;

    /**
     * baseURL is the full external global URL path to the base of the application
     * either configured by baseURL setting, or from app server default.
     * Suitable for use as a global URL in email and when passing a URL
     * as a parameter to another page which might use it in a different context.
     * ALWAYS includes a slash on the end.
     * Generally, code that uses baseURL should be hidden from static site
     * generation.
     */
    public String baseURL = null;

    /**
     * retPath is an internal URL to the base of the application.
     * Might be the same as baseURL, or it might the right relative path.
     * Use retPath for normal page to page navigation URLs.
     * Do not use retPath when a URL is being constructed for use in a different
     * context.
     * ALWAYS includes a slash on the end.
     */
    public String retPath = null;

    public Writer w;

    // page is null until set with setPage
    public NGContainer ngp = null;

    /**
     * nowTime should be used whenever you need to know the current time
     * of the current request for recording in history or whatever.
     * A request may take a few millisecond. nowTime records the time that
     * the request STARTED. Use that for all timestamps. Within the
     * execution of this request, and updating of pages, you should NEVER
     * use currentTimeMillis, but use nowTime instead for all current
     * time uses. This way the time markings will always be consistent regardless
     * of how slow or busy the server is.
     */
    public long nowTime;
    public String nowTimeString;

    /**
     * tiles plays with the request URL in the request object, so that every
     * different
     * JSP loaded thinks it is coming froma different URL. No idea why it does this.
     * However, this variable, if set with preserveRealRequestURL(), will hold the
     * request
     * URL the way it is supposed to be.
     */
    public String realRequestURL;

    Properties props = null;

    private boolean generateStatic = false;

    /**
     * This is the PREFERRED way to create an AuthRequest object.
     * This will check to see if an AuthRequest object has been associated with this
     * request.
     * If so, it is returned.
     * If not, one will be created and associated with request, then returned
     */
    public static AuthRequest getOrCreate(HttpServletRequest areq, HttpServletResponse aresp) {
        return getOrCreateWithWriter(areq, aresp, null);
    }

    /**
     * Lame version for JSP files that use the normal JSP servlet directly
     * JSP's play with the out stream as well, and so you need to be able to
     * adopt that stream, and ignore the stream from the original request.
     */
    public static AuthRequest getOrCreateWithWriter(HttpServletRequest areq, HttpServletResponse aresp, Writer aw) {
        AuthRequest ar = (AuthRequest) areq.getAttribute("AuthRequest");
        if (ar == null) {
            ar = new AuthRequest(areq, aresp, aw);
            areq.setAttribute("AuthRequest", ar);
        } else if (aw != null) {
            ar.setWriter(aw);
        }
        // arbitrarily increment this so we can track what is happening.
        ar.nestingCount++;
        return ar;
    }

    /**
     * If as part of one web request, you want to fake another request to generate
     * a page, this can be done with a nested request. Pass the URL of the
     * request page, and the writer to write out to.
     */
    /*
     * public AuthRequest getNestedRequest(String relativeUrl, Writer nestedOut)
     * throws Exception
     * {
     * HttpNestedRequest nreq = new HttpNestedRequest(relativeUrl, "", req);
     * HttpNestedResponse nresp = new HttpNestedResponse(nestedOut);
     * AuthRequest nested = new AuthRequest(nreq, nresp, nestedOut);
     * nested.nestingCount = nestingCount+1;
     * nreq.setAttribute("AuthRequest", nested);
     * return nested;
     * }
     */

    /**
     * This constructor is ONLY for use by AuthDummy.
     * This is a special case, a subclass used by the server to
     * get special authentication for initialization and background tasks.
     * In that case, there is Request or Response object. The subclass is
     * designed to operate properly when the request and response object
     * are null.
     */
    protected AuthRequest(Writer aw, Cognoscenti _cog) {
        if (aw != null) {
            w = aw;
        }

        cog = _cog;

        nowTime = System.currentTimeMillis();
        baseURL = getSystemProperty("baseURL");
        retPath = baseURL;

        Calendar cal = Calendar.getInstance();
        cal.setTimeInMillis(nowTime);

        StringBuilder nts = new StringBuilder(20);

        // this becomes a kind of signature for the request
        nts.append(Integer.toString(cal.get(Calendar.YEAR)));
        nts.append(".");
        append2Digits(nts, cal.get(Calendar.MONTH) + 1);
        nts.append(".");
        append2Digits(nts, cal.get(Calendar.DAY_OF_MONTH));
        nts.append(".");
        append2Digits(nts, cal.get(Calendar.HOUR_OF_DAY));
        nts.append(".");
        append2Digits(nts, cal.get(Calendar.MINUTE));
        nts.append(".");
        append2Digits(nts, cal.get(Calendar.SECOND));
        nts.append(".");
        append3Digits(nts, cal.get(Calendar.MILLISECOND));

        nowTimeString = nts.toString();
    }

    /** appends to the string buffer the last two digits of this number */
    public static void append2Digits(StringBuilder sb, int value) {
        sb.append((char) ('0' + ((value / 10) % 10)));
        sb.append((char) ('0' + (value % 10)));
    }

    /** appends to the string buffer the last three digits of this number */
    public static void append3Digits(StringBuilder sb, int value) {
        sb.append((char) ('0' + ((value / 100) % 10)));
        sb.append((char) ('0' + ((value / 10) % 10)));
        sb.append((char) ('0' + (value % 10)));
    }

    /**
     * constructor: if this object is constructed in a servlet, then pass
     * a NULL to the newWriter paramter, and the output stream will be
     * retrieved from the response object in a safe way.
     * If object is constructed in a JSP page, then getWriter has already
     * been called on the request, and you must pass the writer in here
     * so that we can avoid calling this method twice
     */
    public AuthRequest(HttpServletRequest areq, HttpServletResponse aresp, Writer aw) {
        this(aw, Cognoscenti.getInstance(areq));

        // This is the AuthDummy case, these can be null, and the copy constructor is
        // being used. This is a little convoluted. Don't try to construct an
        // auth request with null parameters otherwise.
        if (areq == null && aresp == null) {
            return;
        }

        // HttpServletRequestWrapper which can be used to wrap the original request
        // object.
        req = new HttpServletRequestWrapper(areq);

        // wrapping the response so that the getOutputStream can be pre-fetched
        // and cached, and still call JSP Servlet which also gets the output stream.
        // normal servlet response allows this to be called only once.
        // Use this wrapped version for any further ServletResponse needs.
        resp = new HttpServletResponseWithoutBug(aresp);

        // we only support UTF-8, so set this here just in case the JSP forgot to
        try {
            areq.setCharacterEncoding("UTF-8");
            aresp.setContentType("text/html;charset=UTF-8");

            // the IF block below will avoid NPE - But
            // the code inside the if block should not get executed when using the
            // requestDispatcher's include/ forward method calls.
            if (w == null) {
                w = resp.getWriter();
            } else {
                if (w instanceof PrintWriter) {
                    resp.writer = (PrintWriter) w;
                } else {
                    // don't have one, create one. Probably not being used anyway.
                    resp.writer = new PrintWriter(w, true);
                }
            }

            session = req.getSession();

            // within the normal tomcat session, we track another session so we
            // can display all the pages that this user has visited in this session
            // and can store anything else that we want to track over time for this
            // particular access.
            ngsession = NGSession.getNGSession(session);

            resolveUser();

            servletPath = req.getServletPath();
            if (servletPath == null) {
                throw WeaverException.newBasic("Servlet path is missing.  That should be impossible.");
            }

            if (baseURL == null || baseURL.length() == 0) {
                baseURL = req.getContextPath() + "/";
            }

            if (!baseURL.endsWith("/")) {
                baseURL = baseURL + "/";
            }

            // initialize retPath to the global external path, but might change later
            retPath = baseURL;

            setTomcatKludge();

            if (defParam("static", null) != null) {
                generateStatic = true;
            }

            ServletContext sc = session.getServletContext();
            cog = Cognoscenti.getInstance(sc);

        } catch (Exception e) {
            throw new RuntimeException("AuthRequest object not able to be constructed", e);
        }
    }

    public void setWriter(Writer aw) {
        w = aw;
    }

    /**
     * this copy constructor allows you to access according to the access
     * rights of the original request, but substitute a different writer
     * so that you can, for example, create a file, or generate test output.
     * private AuthRequest(AuthRequest oldAr, Writer newWriter)
     * throws Exception
     * {
     * this(oldAr.req, oldAr.resp, newWriter);
     * nestingCount = oldAr.nestingCount+1;
     * }
     */

    public void flush()
            throws Exception {
        w.flush();
    }

    public NGSession getSession() {
        return ngsession;
    }

    /**
     * This returns the basic configuration parameters of the system
     * System properties are generally sensitive (not to be displayed)
     * but otherwise available to pages serving any user.
     */
    public String getSystemProperty(String name) {
        return cog.getConfig().getProperty(name);
    }

    private void resolveUser() throws Exception {
        // first, check if the session has a logged in user
        // that takes precidence
        user = ngsession.findLoginUserProfile();
        if (user != null) {
            return; // we are done
        }

        String userid = req.getHeader("Authorization");
        if (userid != null) {
            String lid = null;
            int indx1 = userid.indexOf("://");
            if (indx1 < 0) {
                indx1 = 0;
            } else {
                indx1 = indx1 + 3;
            }

            int indx2 = userid.indexOf(':', indx1);
            if (indx2 > 0) {
                lid = userid.substring(indx2 + 1);
                userid = userid.substring(0, indx2);
            }
            licenseid = lid;
        }
        if (userid != null) {
            UserManager.getStaticUserManager();
            user = UserManager.lookupUserByAnyId(userid);
        }
    }

    public void setPageAccessLevelsWithoutVisit(NGContainer newNgp)
            throws Exception {
        ngp = newNgp;
    }

    public void setPageAccessLevels(NGContainer newNgp) throws Exception {
        if (newNgp == null) {
            throw WeaverException
                    .newBasic("setPageAccessLevels was called with a null parameter.  That should not happen");
        }
        // record the fact that workspace was visited in this session
        if (newNgp instanceof NGWorkspace) {
            ngsession.addVisited((NGWorkspace) newNgp, nowTime);
            recordVisit(((NGWorkspace) newNgp).getSiteKey(), ((NGWorkspace) newNgp).getKey());
        }
        setPageAccessLevelsWithoutVisit(newNgp);
    }

    public NGWorkspace findAndSetWorkspace(String siteId, String pageId) throws Exception {
        NGWorkspace ngw = getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
        ngp = ngw;
        return ngw;
    }

    public NGBook findAndSetSite(String siteId) throws Exception {
        NGBook site = getCogInstance().getSiteByIdOrFail(siteId);
        ngp = site;
        return site;
    }

    /**
     * If you want to throw away all the changes that might have been made to the
     * copy
     * of a workspace in memory, you need to NOT save the workspace, and you need to
     * call this to make sure that all cached copies of the workspace are removed
     * from
     * memory, forcing the next read to actually read from the file on the disk.
     *
     * After calling this, ngp member is cleared back to null, so make sure your
     * logic
     * is expecting that. After this is called, you really should not do any more
     * processing.
     */
    public void rollbackChanges() {
        if (ngp != null) {
            NGWorkspace.removeCachedPage(ngp.getFilePath());
            ngp = null;
        }
        NGPageIndex.clearLocksHeldByThisThread();
    }

    /**
     * Returns true if you have an actual logged in (authenticated) user
     * Returns false if current access is anonymous.
     *
     * Note: if handling a request that has been pre-approved for
     * anonymous use (like using a magic number of something) then use
     * setUserForOneRequest() with the pre-approving authority
     * to make it appear logged in.
     * 
     * @throws Exception
     */
    public boolean isLoggedIn() throws Exception {
        // logic is simple now, but might get more complex in future
        return (user != null);

    }

    public UserProfile getUserProfile() {
        return user;
    }

    public String getBestUserId() {
        if (user != null) {
            return user.getUniversalId();
        }
        return "";
    }

    public UserPage getUserPage() throws Exception {
        if (user == null) {
            throw WeaverException.newBasic("Unable to get user page, you don't appear to be logged in");
        }
        return cog.getUserManager().findOrCreateUserPage(user.getKey());
    }

    public UserPage getAnonymousUserPage() throws Exception {
        return cog.getUserManager().findOrCreateUserPage("ANONYMOUS_REQUESTS");
    }

    /**
     * Not an authenticated user, but a hint for a user from the
     * URL parameter or such can be specified here for use in
     * non-private situations.
     */
    public void setPossibleUser(UserProfile hintedUser) {
        possibleUser = hintedUser;
    }

    /**
     * Technically this user is not logged in (they have not
     * fully authenticated, however we have some idea who they
     * are from either a link parameter or a session attribute.
     * The pages that serve unauthenticated requests might use
     * this value to help make the UI easier to use for these
     * people without forcing login.
     * 
     * Returns logged in user if logged in.
     */
    public UserProfile getPossibleUser() {
        if (user != null) {
            return user;
        }
        return possibleUser;
    }

    /**
     * Sets this user profile as the current user of this object
     * and also makes appropriate settings into the session so that
     * the next request will remember this as well.
     */
    public void setLoggedInUser(UserProfile newUser, String loginId, String autoLogin, String openId)
            throws Exception {
        user = newUser;
        ngsession.setLoggedInUser(newUser, loginId);

        // set up a cookie with the id so it is easy to log in next time
        String cookieName = "lastOpenId";
        if (loginId.indexOf("@") > 0) {
            cookieName = "lastEmail";
        }

        Cookie previousId = new Cookie(cookieName, loginId);
        previousId.setMaxAge(30000000); // about 1 year from login
        resp.addCookie(previousId);

        Cookie currentId = new Cookie("loginId", loginId);
        currentId.setMaxAge(30000000); // about 1 year from login
        resp.addCookie(currentId);

        if (autoLogin != null) {
            Cookie autoLoginCookie = new Cookie("autoLoginCookie", autoLogin);
            autoLoginCookie.setMaxAge(30000000); // about 1 year from login
            autoLoginCookie.setPath(req.getContextPath());
            resp.addCookie(autoLoginCookie);
            Cookie openIdCookie = new Cookie("openIdCookie", openId);
            openIdCookie.setMaxAge(30000000); // about 1 year from login
            openIdCookie.setPath(req.getContextPath());
            resp.addCookie(openIdCookie);
        }
    }

    /**
     * clears all record of the current user
     */
    public void logOutUser() {
        ngsession.flushConfigCache();
        ngsession.deleteAllSpecialSessionAccess();
        user = null;

        clearCookie();
    }

    /**
     * takes the passed in universal id
     * and determine whether it is an ID for the current logged in user.
     */
    public boolean isMe(String testId) {
        if (user == null) {
            return false; // can't be me if I am not logged in
        }
        return user.hasAnyId(testId);
    }

    /**
     * assertLoggedIn will test if the user is logged in, and if so is a no-op,
     * but if not, will either produce a warning, or (if possible) will redirect
     * to a page that will allow log in.
     */
    public void assertLoggedIn(String opDescription)
            throws Exception {
        // if this is a post method, then the request URL does not contain all
        // the information needed. In that case, getting the user to back up
        // might be better. So redirect only on GET cases.
        boolean canRedirect = req.getMethod().equalsIgnoreCase("GET");

        // first test that the server is initialized, and if not redirect to the
        if (!cog.isInitialized()) {
            if (canRedirect) {
                String configDest = retPath + "init/config.htm?go="
                        + URLEncoder.encode(getRequestURL(), "UTF-8");
                resp.sendRedirect(configDest);
            }
            throw WeaverException.newWrap("Server is not initialized", cog.initializer.lastFailureMsg);
        }

        if (isLoggedIn()) {
            // yes logged in, everything is OK
            return;
        }

        if (canRedirect) {
            String go = getCompleteURL();
            String loginUrl = getSystemProperty("identityProvider") + "?openid.mode=quick&go="
                    + URLEncoder.encode(go, "UTF-8");
            resp.sendRedirect(loginUrl);
            throw new ServletExit();
        }

        // even in redirect case, we need to throw exception to stop the processing
        // of the calling code.
        throw WeaverException.newBasic("User is not logged in. %s", opDescription);
    }

    public void assertAdmin(String opDescription) throws Exception {
        if (ngp == null) {
            throw WeaverException.newBasic(
                    "'assertAuthor' is being called, but no page has been associated with the AuthRequest object");
        }
        assertLoggedIn(opDescription);
        if (isSuperAdmin()) {
            return;
        }
        if (!ngp.primaryOrSecondaryPermission(getUserProfile())) {
            throw WeaverException.newBasic("Admin privilege is required for %s", opDescription);
        }
    }

    public void assertUpdateWorkspace(String opDescription) throws Exception {
        if (isSuperAdmin()) {
            return;
        }
        // you have to access before you can update
        assertAccessWorkspace(opDescription);

        // check the container rules on who can update
        NGWorkspace ngw = (NGWorkspace) ngp;
        ngw.assertUpdateWorkspace(user, opDescription);
    }

    public void assertAccessWorkspace(String opDescription) throws Exception {
        if (ngp == null) {
            throw WeaverException.newBasic(
                    "'assertAccessWorkspace' is being called, but no page has been associated with the AuthRequest object");
        }
        if (!(ngp instanceof NGWorkspace)) {
            throw WeaverException
                    .newBasic("Program Logic Error: MEMBERSHIP applies only to workspaces and not to Sites.");
        }
        NGWorkspace ngw = (NGWorkspace) ngp;

        if (!isLoggedIn()) {
            throw WeaverException.newBasic("User is not logged in, not a role of workspace. %s", opDescription);
        }

        if (isSuperAdmin()) {
            return;
        }

        // it is possible that you are a honorary member, even if you are not logged in
        // so check that first
        if (ngsession.isHonoraryMember(ngp.getKey())) {
            return;
        }

        // check the container rules on who can be a member
        if (!ngw.canAccessWorkspace(user)) {
            throw WeaverException.newBasic("User is not a member of this workspace. %s", opDescription);
        }
    }

    public void assertExecutive(String opDescription) throws Exception {
        if (ngp == null) {
            throw WeaverException.newBasic(
                    "'assertExecutive' is being called, but no page has been associated with the AuthRequest object");
        }
        if (!(ngp instanceof NGBook)) {
            throw WeaverException
                    .newBasic("Program Logic Error: EXECUTIVE applies only to sites and not to workspaces.");
        }
        if (!isLoggedIn()) {
            throw WeaverException.newBasic("User is not logged in, not an executive of site. %s", opDescription);
        }
        NGBook ngb = (NGBook) ngp;

        if (isSuperAdmin()) {
            return;
        }

        if (!ngb.isSiteExecutive(user)) {
            throw WeaverException.newBasic("User is not executive of this site. %s", opDescription);
        }
    }

    public void assertSuperAdmin(String opDescription) throws Exception {
        assertLoggedIn(opDescription);
        if (!isSuperAdmin()) {
            throw WeaverException.newBasic("User is not a a super-admin. %s", opDescription);
        }
    }

    /**
     * Identifies if the current logged in user is a basic (unpaid)
     * user in the current workspace. If anything is wrong, like
     * the user is not logged in or the workspace not set then
     * it presumes the most restrictive: true.
     * 
     * The logic in the site is that unknown users are
     * not read only, so that users added by workspace admin
     * are usable at least until review at site level. This
     * logic may change in the future.
     * 
     * If you are restricting update to a workspace, you still
     * need to check isMember, because read only depends only on logic
     * at the site level, and does not consider workspace membership.
     */
    public boolean isReadOnly() throws Exception {
        if (!isLoggedIn()) {
            return true;
        }
        if (isSuperAdmin()) {
            return false;
        }
        if (ngp == null) {
            return true;
        }
        if (ngp instanceof NGBook) {
            NGBook site = ((NGBook) ngp);
            return site.isUnpaidUser(user);
        } else if (ngp instanceof NGWorkspace) {
            NGWorkspace workspace = ((NGWorkspace) ngp);
            return !workspace.canUpdateWorkspace(user);
        }
        return true;
    }

    public void assertNotReadOnly(String opDescription) throws Exception {
        if (!isLoggedIn()) {
            throw WeaverException.newBasic("You are not logged in and can not update information. %s", opDescription);
        }
        if (isSuperAdmin()) {
            return;
        }
        if (ngp == null) {
            throw WeaverException.newBasic("Program logic error workspace not set. %s", opDescription);
        }
        if (ngp instanceof NGBook) {
            NGBook site = ((NGBook) ngp);
            if (site.isUnpaidUser(user)) {
                throw WeaverException.newBasic("As a basic user you can not update site. %s", opDescription);
            }
        } else if (ngp instanceof NGWorkspace) {
            NGWorkspace ngw = ((NGWorkspace) ngp);
            ngw.assertUpdateWorkspace(user, opDescription);
        }
        if (isReadOnly()) {
            throw WeaverException.newBasic("With read only access you can not update workspace. %s", opDescription);
        }
    }

    public boolean canAccessSite() throws Exception {
        if (!isLoggedIn()) {
            return false;
        }
        if (ngp == null) {
            return false;
        }
        if (isSuperAdmin()) {
            return true;
        }
        if (!(ngp instanceof NGBook)) {
            throw WeaverException
                    .newBasic("Program Logic Error: canAccessSite is called when not manipulating a site.");
        }
        return (ngp.primaryOrSecondaryPermission(user));
    }

    public boolean canAccessWorkspace() throws Exception {
        if (!isLoggedIn()) {
            return false;
        }
        if (ngp == null) {
            return false;
        }
        if (isSuperAdmin()) {
            return true;
        }
        if (ngp instanceof NGWorkspace) {
            NGWorkspace ngw = (NGWorkspace) ngp;
            return ngw.canAccessWorkspace(user);
        }
        return (ngp.primaryOrSecondaryPermission(user));
    }

    public boolean canUpdateWorkspace() throws Exception {
        if (!isLoggedIn()) {
            return false;
        }
        if (ngp == null) {
            return false;
        }
        if (isSuperAdmin()) {
            return true;
        }
        if (ngp instanceof NGWorkspace) {
            NGWorkspace ngw = (NGWorkspace) ngp;
            return ngw.canUpdateWorkspace(user);
        }
        return (ngp.primaryOrSecondaryPermission(user));
    }

    public boolean isAdmin()
            throws Exception {
        if (!isLoggedIn()) {
            return false;
        }
        if (ngp == null) {
            return false;
        }
        if (isSuperAdmin()) {
            return true;
        }
        return (ngp.secondaryPermission(user));
    }

    /**
     * Calling this gives the current session a special ability to
     * access a particular "mode" AS IF the user was a member.
     *
     * The mode is a unique identifier which must include the key of what
     * container is being accessed along with a mode indicator.
     * e.g. "Notifications:SUYAHSGUF" might be the mode indicator of the
     * Navigation page of a particular user. The controller/view code
     * determines how it wants to create a unique ID for that mode
     * which enables access to a collection of views.
     *
     * This will only last for the session and is lost when session times out.
     *
     * This privilege is extended even to requests that are not authenticated.
     * Here is how it works:
     *
     * (0) A resource is associated with a unique key
     * (1) a URL is constructed that is designed to give special access, such
     * as a URL to be embedded into an email message that is sent to people
     * who need to access a particular page. Receipt of the email message
     * is enough to be assured that the right person has the link (even though
     * that person could forward the mail, giving others the same privilege.
     * That URL has a "magic number" in it which unlocks the capability.
     * (2) When the user accesses the page with the magic number, the controller
     * looks for the magic number, and identifies whether the number is valid
     * for the resource, and also determines the unique key
     * (3) If the magic number is valid, then the session is marked with the unique
     * key of the resource in question. Further URLs do not need to carry
     * the magic number.
     * (4) The controller then determines if the current request has enough access
     * (4a) is the user logged in and whether user has sufficient rights
     * (4b) whether hasSpecialSessionAccess(unique key) is true
     */
    public void setSpecialSessionAccess(String uniqueAccessMode) {
        ngsession.addHonoraryMember(uniqueAccessMode);
    }

    /**
     * This is for testing if a particular session has a special access.
     * see #setSpecialMemberAccess
     */
    public boolean hasSpecialSessionAccess(String uniqueAccessMode) {
        return ngsession.isHonoraryMember(uniqueAccessMode);
    }

    /**
     * This method should be called in any JSP that produces HTML output to the
     * request.
     * The point being that output should never be produced as the result of a POST
     * request.
     * This method will produce an error message if this ever happens.
     */
    public void assertNotPost()
            throws Exception {
        String method = req.getMethod();
        if ("post".equalsIgnoreCase(method)) {
            throw WeaverException.newBasic("this page is being displayed as the result of a POST request, "
                    + "and internal guidelines are that pages should be displayed only in response to GET methods.");
        }
    }

    /**
     * Returns the value of a named cookie if there is one,
     * returns null if there is not
     */
    public String findCookieValue(String cookieName) {
        Cookie[] cookies = req.getCookies();
        if (cookies != null) {
            for (Cookie oneCookie : cookies) {
                if (oneCookie != null) {
                    String cName = oneCookie.getName();
                    if (cName != null && cookieName.equals(cName)) {
                        return oneCookie.getValue();
                    }
                }
            }
        }
        return null;
    }

    /**
     * There are two sources of former id.
     *
     * 1) If the URL has a 'login' parameter which is set to the ID of a user
     * 2) If a cookie has the ID of a user.
     *
     * In either case, the user profile record for that ID is looked up, and if
     * it exists, it looks to see what the user used to login last time.
     * This is probably what they want to log in with this time.
     * If no user profile record is found for any reason, a zero length string is
     * returned.
     */
    public String getFormerId()
            throws Exception {
        // first look to see if there is a 'login' parameter
        String possibleKey = defParam("login", null);
        if (possibleKey == null) {
            // if not, let's try the cookies for openid
            possibleKey = getFormerOpenId();
        }
        if (possibleKey == null) {
            // then lets try the cookies for email id
            possibleKey = getFormerEmail();
        }
        if (possibleKey == null) {
            // give up, nothing else to try
            return "";
        }

        // clean up the id, if possible by looking up last login id
        UserProfile up = UserManager.getUserProfileByKey(possibleKey);
        if (up != null) {
            String id = up.getLastLoginId();
            if (id != null && id.length() > 0) {
                return id;
            }
        }
        return possibleKey;
    }

    /**
     * if the user logged in with an OpenID (in the past) then
     * this will return the cookie value that saved that.
     */
    public String getFormerOpenId() throws Exception {
        String foid = findCookieValue("lastOpenId");
        return foid;
    }

    /**
     * if the user logged in with an Email address (in the past) then
     * this will return the cookie value that saved that.
     */
    public String getFormerEmail() throws Exception {
        String fe = findCookieValue("lastEmail");
        return fe;
    }

    /**
     * This is a tricky routine. The purpose is to find the best default values to
     * go
     * is a login form. If you are are returning to a web page which you logged in
     * before, you want to, if possible, use the cookies to remember what you logged
     * in as last time. But, there are some cases where the URL will specify the
     * user to log in as (hint), and in that case it overrides the cookies.
     *
     * Returns a two element array of strings:
     * value[0]: the best guess OpenID
     * value[1]: the best guess Email address
     */
    public String[] getBestGuessId(String hint) throws Exception {
        String possibleOpenId = null;
        String possibleEmailId = null;
        if (hint == null) {
            possibleOpenId = getFormerOpenId();
            possibleEmailId = getFormerEmail();
        } else if (hint.indexOf('@') > 0) {
            possibleOpenId = getFormerOpenId();
            possibleEmailId = hint;
        } else {
            possibleOpenId = hint;
            possibleEmailId = getFormerEmail();
        }
        if (possibleOpenId == null) {
            possibleOpenId = "";
        }
        if (possibleEmailId == null) {
            possibleEmailId = "";
        }
        return new String[] { possibleOpenId, possibleEmailId };
    }

    /**
     * grab the request URL at this moment in time,a nd store it in the
     * real request variable to preserve that value.
     */
    public void preserveRealRequestURL() {
        realRequestURL = req.getRequestURL().toString();
    }

    /**
     * Return the URL that got us here without query parameters.
     * FULL: This is the full URL, starting with http including machine name and
     * the full path provided by the client up to the query parameters, not
     * relative.
     * GLOBAL: It is the externally valid URL defined by baseURL configuration
     * It does NOT include query parameters.
     */
    public String getRequestURL() {
        if (req == null) {
            throw new RuntimeException("request object should never be null");
        }

        // if this has not been set with preserveRealRequestURL() call, then do it now
        // this request attribute set outside of Tiles so you know what the browser
        // requested
        if (realRequestURL == null) {
            realRequestURL = (String) req.getAttribute("realRequestURL");
        }

        if (realRequestURL == null) {
            realRequestURL = req.getRequestURL().toString();
        }

        // now, if we are running behind a front server (e.g. an apache doing https)
        // the we may need to change the baseURL to work universally
        if (!realRequestURL.startsWith(baseURL)) {
            String localContext = req.getContextPath();
            int contextPos = realRequestURL.indexOf(localContext);
            if (contextPos < 0) {
                throw new RuntimeException(
                        "Unknown problem, request URL does not contain the local context path,  RequestURL is ["
                                + realRequestURL + "] and the getContextPath is ["
                                + localContext + "]");
            }
            realRequestURL = baseURL + realRequestURL.substring(contextPos + localContext.length() + 1);
        }
        return realRequestURL;
    }

    /**
     * Return the complete URL that got us here, including query parameters
     * so we can redirect back as necessary.
     *
     * Made so it does not throw exceptions so that this can be used in
     * exception handlers easily.
     */
    public String getCompleteURL() {
        StringBuilder qs = new StringBuilder(getRequestURL());
        Enumeration<String> en = req.getParameterNames();
        boolean firstTime = true;
        while (en.hasMoreElements()) {
            String key = en.nextElement();
            String value = req.getParameter(key);
            if (value == null) {
                value = "";
            }
            if (firstTime) {
                qs.append("?");
            } else {
                qs.append("&");
            }
            firstTime = false;
            qs.append(key);
            qs.append("=");
            qs.append(SectionUtil.encodeURLData(value));
        }
        return qs.toString();
    }

    /**
     * Returns the URL up to the base address of the entire application.
     * for example: http://server:port/nugen/
     * Returns a path with a slash on the end.
     */
    public String getServerPath() {
        if (baseURL == null) {
            throw new RuntimeException("Initialization problem, baseURL has not been configured.");
        }
        return baseURL;
    }

    /**
     * Convenience method. If you want to write to the output stream of a
     * request, this will alow you to write without having to get the
     * output stream and call write on it.
     */
    public void write(String t) throws Exception {
        w.write(t);
    }

    /**
     * Convenience method. If you want to write to the output stream of a
     * request, this will alow you to write without having to get the
     * output stream and call write on it.
     */
    public void write(char ch) throws Exception {
        w.write(ch);
    }

    public void writeHtml(String t) throws Exception {
        HTMLWriter.writeHtml(w, t);
    }

    public void writeHtmlWithLines(String t) throws Exception {
        HTMLWriter.writeHtmlWithLines(w, t);
    }

    public void writeURLData(String data)
            throws Exception {
        // avoid NPE.
        if (data == null || data.length() == 0) {
            return;
        }

        String encoded = URLEncoder.encode(data, "UTF-8");

        // here is the problem: URL encoding says that spaces can be encoded using
        // a plus (+) character. But, strangely, sometimes this does not work, either
        // in certain combinations of browser / tomcat version, using the plus as a
        // space character does not WORK because the plus is not removed by Tomcat
        // on the other side.
        //
        // Strangely, %20 will work, so we replace all occurrences of plus with %20.
        //
        // I am not sure where the problem is, but if you see a URL with plus symbols
        // in mozilla, and the same URL with %20, they look different. The %20 is
        // replaced with spaces in the status bar, but the plus is not.
        //
        int plusPos = encoded.indexOf("+");
        int startPos = 0;
        while (plusPos >= startPos) {
            if (plusPos > startPos) {
                // third parameter is length of span, not end character
                w.write(encoded, startPos, plusPos - startPos);
            }
            write("%20");
            startPos = plusPos + 1;
            plusPos = encoded.indexOf("+", startPos);
        }
        int last = encoded.length();
        if (startPos < last) {
            // third parameter is length of span, not end character
            w.write(encoded, startPos, last - startPos);
        }
    }

    /**
     * writeJS makes sure that no quote characters are in the output
     * and properly escaping backslash character, and converting high
     * characters to a code-point expression.
     */
    public void writeJS(String val) throws Exception {
        com.purplehillsbooks.streams.JavaScriptWriter.encode(w, val);
    }

    /**
     * sometimes TomCat will fail to decode the parameters as UTF-8
     * because the indication that the parameters are in UTF-8 come
     * in TOO LATE for the parsing. So, instead of re-parsing the parameters
     * according to the desired character set, it leaves them in ISO-8859-1
     * which is the default as defined by the servlet spec.
     * This flag indicates that we have detected this situation, and if it
     * is set to true, it will do an extra decoding of the parameter from
     * 8859-1 to UTF-8.
     */
    static boolean needTomcatKludge = false;

    /**
     * This method should be called once, before fetching any of the parameters
     * It looks for a parameter called "encodingGuard" which it expects to see
     * with the Kanji characters for "Tokyo" in it. If it sees the parameter,
     * and it sees that it is distorted, then it turns on the TomCat kludge.
     */
    public void setTomcatKludge() {
        // here we are testing is TomCat is configured correctly. If it is this value
        // will be received uncorrupted. If not, we will attempt to correct things by
        // doing an additional decoding
        String encodingGuard = req.getParameter("encodingGuard");
        needTomcatKludge = !(encodingGuard == null || "\u6771\u4eac".equals(encodingGuard));
    }

    /**
     * Get a paramter value from the request stream. If that parameter
     * is not in the request, then look and see if it is an attribute of the
     * reuqest that was put there by code doing a server side redirect to the
     * JSP file. If that is not there either, then return the default instead.
     */
    public String defParam(String paramName, String defaultValue)
            throws Exception {
        String val = req.getParameter(paramName);
        if (val != null) {
            // this next line should not be needed, but I have seen this hack recommended
            // in many forums. See setTomcatKludge() above.
            if (needTomcatKludge) {
                val = new String(val.getBytes("iso-8859-1"), "UTF-8");
            }
            return val;
        }

        // try and see if it a request attribute
        val = (String) req.getAttribute(paramName);
        if (val != null) {
            return val;
        }

        return defaultValue;
    }

    /**
     * Get a required parameter. If the parameter is not found, generate an error
     * message for that. When a page contains a link to another page, it should
     * have all of the require parameters in it. If a parameter is missing, then
     * it is a basic programming error that should be caught and fixed before
     * release. This routine is to make it easy to find and fix missing parameters.
     *
     * The exception that is thrown will not be seen by users. Once all of the pages
     * have proper URLs constricted for redirecting to other pages, this error will
     * not occur. Therefor, there is no need to localize this exception.
     */
    public String reqParam(String paramName) throws Exception {
        String val = defParam(paramName, null);
        if (val == null || val.length() == 0) {
            throw WeaverException.newBasic("A parameter named '%s' is required for page '%s'.", paramName,
                    getRequestURL());
        }
        return val;
    }

    public long reqParamLong(String paramName) throws Exception {
        String val = defParam(paramName, null);
        if (val == null || val.length() == 0) {
            throw WeaverException.newBasic("A parameter named '%s' is required for page '%s'.", paramName,
                    getRequestURL());
        }
        return DOMFace.safeConvertLong(val);
    }

    /**
     * set parameter on the request object, if there is one.
     * AuthDummy does this a little differently
     */
    public void setParam(String paramName, String paramValue) throws Exception {
        if (req == null) {
            throw WeaverException.newBasic("Calling setParam on an AuthRequest, but the "
                    + "request object is null!?!?!?");
        }
        req.setAttribute(paramName, paramValue);
    }

    public void setParam(String paramName, long paramValue) throws Exception {
        if (req == null) {
            throw WeaverException.newBasic("Calling setParam on an AuthRequest, but the "
                    + "request object is null!?!?!?");
        }
        req.setAttribute(paramName, Long.toString(paramValue));
    }

    /**
     * Get a parameter with multiple values. Returns an array of strings.
     * if there are no values it returns an empty array of strings.
     */
    public String[] multiParam(String paramName)
            throws Exception {
        String[] val = req.getParameterValues(paramName);
        if (val == null) {
            return new String[0];
        }
        return val;
    }

    /**
     * makeHonoraryMember causes this users session to be marked as a
     * member of the current page. This will be remembered for the
     * duration of the session in the NGSession object.
     */
    public void makeHonoraryMember() {
        if (ngp == null) {
            throw new RuntimeException("makeHonoraryMember can not be called "
                    + "until after the NGWorkspace is set");
        }
        ngsession.addHonoraryMember(ngp.getKey());
    }

    public boolean isSuperAdmin()
            throws Exception {
        if (user == null) {
            // not logged in, so of course you are not super admin
            return false;
        }
        return isSuperAdmin(user.getKey());
    }

    public boolean isSuperAdmin(String key)
            throws Exception {
        if (key == null) {
            return false;
        }
        String superAdmin = getSystemProperty("superAdmin");
        if (superAdmin == null) {
            // if the superAdmin not defined, then NOBODY is super admin
            return false;
        }
        return superAdmin.contains(key);
    }

    // ADDRESSES

    public String getWorkspaceBaseURL(NGContainer ngc) throws Exception {
        if (ngc instanceof NGWorkspace) {
            return "t/" + URLEncoder.encode(((NGWorkspace) ngc).getSiteKey(), "UTF-8")
                    + "/" + ngc.getKey() + "/";
        }

        // for site go to the workspace list
        return "t/" + URLEncoder.encode(ngc.getKey(), "UTF-8") + "/$/";
    }

    public String getResourceURL(NGPageIndex ngpi, String resource) throws Exception {
        if (!ngpi.isWorkspace()) {
            return "t/" + ngpi.containerKey + "/$/" + resource;
        }
        return "t/" + URLEncoder.encode(ngpi.wsSiteKey, "UTF-8") + "/"
                + ngpi.containerKey + "/" + resource;
    }

    public String getResourceURL(NGContainer ngc, String resource) throws Exception {
        return getWorkspaceBaseURL(ngc) + resource;
    }

    public String getDefaultURL(NGContainer ngc) throws Exception {
        if (ngc instanceof NGWorkspace) {
            return "t/" + URLEncoder.encode(((NGWorkspace) ngc).getSiteKey(), "UTF-8") + "/"
                    + ngc.getKey() + "/FrontPage.htm";
        }

        // for site go to the workspace list
        return "t/" + URLEncoder.encode(ngc.getKey(), "UTF-8") + "/$/SiteWorkspaces.htm";
    }

    public String getDefaultURL(NGPageIndex ngpi) throws Exception {
        if (ngpi.isWorkspace()) {
            return "t/" + URLEncoder.encode(ngpi.wsSiteKey, "UTF-8") + "/"
                    + ngpi.containerKey + "/FrontPage.htm";
        }
        // for site go to the workspace list
        return "t/" + URLEncoder.encode(ngpi.containerKey, "UTF-8") + "/$/SiteWorkspaces.htm";
    }

    public String getResourceURL(NGContainer ngp, TopicRecord note) throws Exception {
        return getResourceURL(ngp, "noteZoom" + note.getId() + ".htm");
    }

    /**
     * Given the name of a JSP file, this will call it, and the
     * output will appear in the place of the call.
     */
    public void invokeJSP(String JSPName) throws Exception {
        try {
            if (!JSPName.startsWith("/spring")) {
                throw WeaverException.newBasic("invokeJSP has been called with something OTHER than spring!!!");
            }
            JSPName = "/spring2" + JSPName.substring(7);
            nestingCount++;
            if (nestingCount > 10) {
                throw WeaverException.newBasic("Nesting count for JSP has exceeded limit of 10 for %s", JSPName);
            }
            String relPath = getRelPathFromCtx();
            resp.setContentType("text/html;charset=UTF-8");

            RequestDispatcher rd = req.getRequestDispatcher(relPath + JSPName);
            if (rd == null) {
                // at one point we needed a retPath in here, but now we
                // don't need it, and I am not sure why....
                throw WeaverException.newBasic("Unable to construct a RequestDispatcher for JSP %s", JSPName);
            }
            Writer saveWriter = w;
            rd.include(req, resp);

            // the JSP file may change the writer to be a writer for only the JSP
            // but that writer is invalidated when we get back to here
            // so replace the writer that we had before.
            w = saveWriter;
            flush();
        } catch (Exception e) {
            throw WeaverException.newWrap("Unable to invoke JSP '%s'", e, JSPName);
        } finally {
            nestingCount--;
        }
    }

    public void invokeRootJSP(String JSPName) throws Exception {
        try {
            nestingCount++;
            if (nestingCount > 10) {
                throw WeaverException.newBasic("Nesting count for JSP has exceeded limit of 10 for %s", JSPName);
            }
            String relPath = getRelPathFromCtx();
            resp.setContentType("text/html;charset=UTF-8");

            RequestDispatcher rd = req.getRequestDispatcher(relPath + JSPName);
            if (rd == null) {
                // at one point we needed a retPath in here, but now we
                // don't need it, and I am not sure why....
                throw WeaverException.newBasic("Unable to construct a RequestDispatcher for JSP %s", JSPName);
            }
            Writer saveWriter = w;
            rd.include(req, resp);

            // the JSP file may change the writer to be a writer for only the JSP
            // but that writer is invalidated when we get back to here
            // so replace the writer that we had before.
            w = saveWriter;
            flush();
        } catch (Exception e) {
            throw WeaverException.newWrap("Unable to invoke RAW JSP '%s'", e, JSPName);
        } finally {
            nestingCount--;
        }
    }

    /**
     * returns the relative path to the base of the application
     */
    public String getRelPathFromCtx() throws Exception {
        if (req == null) {
            return "";
        }

        String pageUrl = req.getRequestURL().toString();
        String context = req.getContextPath() + "/";
        int contextPos = pageUrl.indexOf(context);
        if (contextPos == -1) {
            return "";
        }

        String relPath = "";
        String strOfIntrest = pageUrl.substring(contextPos + context.length());
        for (int i = 0; i < strOfIntrest.length(); i++) {
            char c = strOfIntrest.charAt(i);
            if (c == '/') {
                relPath = relPath + "../";
            }
        }
        return relPath;
    }

    /**
     * To support the generation of static web sites.
     * Set the parameter "static" to anything other than null
     * This will be detected, and this method will return true;
     * Otherwise it returns false;
     * Use this to eliminate parts of the page that should not be
     * on static sites.
     */
    public boolean isStaticSite() {
        return generateStatic;
    }

    /**
     * Sets the 'static site' flag to the value passed in.
     * Set to 'true' in order to get all the features of a static site.
     */
    public boolean setStaticSite(boolean isStatic) {
        return generateStatic = isStatic;
    }

    public Locale getLocale() {
        return req.getLocale();
    }

    /**
     * Given an input stream to read from, this will read all the
     * bytes, and write them to the output stream as bytes (not characters);
     */
    public void streamBytesOut(InputStream is) throws Exception {
        byte[] buf = new byte[2048];
        int amtRead = is.read(buf);
        OutputStream out = resp.getOutputStream();
        while (amtRead > 0) {
            // these are bytes to write directly to the byte stream
            out.write(buf, 0, amtRead);
            amtRead = is.read(buf);
        }
        out.flush();
    }

    /**
     * Creates the log file and starts new log files
     * in a way that guarantees that only one thread
     * at a time does this.
     */
    public void manageLogFile()
            throws Exception {
        if (logFile != null) {
            // OK, not that great to call System time here, but it does not
            // really matter when it switches over to the new log file.
            if (System.currentTimeMillis() < logRestartTime) {
                return; // all OK, keep logging to existing file
            }

            // this is the case that the current log is full, and needs recycle
            logFile = null;
        }

        // create a log file name based on the current time.
        File logFolder = new File(cog.getConfig().getUserFolderOrFail(), "logs");
        if (!logFolder.exists()) {
            logFolder.mkdirs();
        }
        logFile = new File(logFolder, "Reqs_" + nowTimeString + ".log");
        logFile.createNewFile();

        // set to re-create in one day time if necessary
        logRestartTime = nowTime + 86000000;
    }

    /**
     * log the output to a log file at the END of the request
     * Should normally only be called by servlet classes
     */
    private static File logFile = null;
    private static long logRestartTime = 0;
    private static String synchObject = "goofy string";

    public void logCompletedRequest() {
        try {
            long endTime = System.currentTimeMillis();
            long duration = endTime - nowTime;
            String durationStr = Long.toString(duration);
            String requrl = getRequestURL();

            String userName = "GUEST";
            UserProfile up = getUserProfile();
            if (up != null) {
                userName = up.getKey();
            }

            // only one thread writing to the file at a time .... please
            synchronized (synchObject) {
                manageLogFile();

                FileOutputStream fos = new FileOutputStream(logFile, true); // append
                OutputStreamWriter osw = new OutputStreamWriter(fos, "UTF-8");
                osw.write("\n");
                osw.write(nowTimeString);
                osw.write(",");
                for (int i = durationStr.length(); i < 7; i++) {
                    osw.write(" ");
                }
                osw.write(Long.toString(duration));
                osw.write(",");
                osw.write(userName);
                for (int i = userName.length(); i < 10; i++) {
                    osw.write(" ");
                }
                osw.write(",");
                osw.write(requrl);
                osw.flush();
                fos.close();
            }
        } catch (Exception e) {
            // what else to do? ... crash the server. If your log file
            // is not working there is very little else to be done.
            throw new RuntimeException("Can not write to log file", e);
        }
    }

    public long logException(String msg, Throwable ex) {
        long exceptionNO = 0;
        try {
            ErrorLog el = ErrorLog.getLogForDate(nowTime, cog);
            exceptionNO = el.logException(msg, ex, nowTime,
                    getUserProfile(), getCompleteURL(), cog);
        } catch (Exception e) {
            // what else to do? ... crash the server. If your log file
            // is not working there is very little else to be done.
            // Might as well try throwing the exception...
            throw new RuntimeException("Can not log the exception to log file", e);
        }
        return exceptionNO;
    }

    public void writeHtmlMessage(String key, Object[] argumentArray) throws Exception {
        writeHtml(getMessageFromPropertyFile(key, argumentArray));
    }

    public void writeQuote4JS(String val) throws Exception {
        writeHtml(UtilityMethods.quote4JS(val));
    }

    public String getMessageFromPropertyFile(String key, Object[] argumentArray) throws Exception {
        ResourceBundle labels = ResourceBundle.getBundle("messages", getLocale());
        return labels.getString(key);
    }

    public String getQuote4JS(String val) throws Exception {
        return getHtml(UtilityMethods.quote4JS(val));
    }

    public String getHtml(String t)
            throws Exception {
        String result = "";
        if (t == null) {
            return result; // treat it like an empty string
        }
        for (int i = 0; i < t.length(); i++) {
            char c = t.charAt(i);
            switch (c) {
                case '&':
                    result += "&amp;";
                    continue;
                case '<':
                    result += "&lt;";
                    continue;
                case '>':
                    result += "&gt;";
                    continue;
                case '"':
                    result += "&quot;";
                    continue;
                default:
                    result += c;
                    continue;
            }
        }
        return result;
    }

    public void assertNotFrozen(NGContainer ngc) throws Exception {
        if (ngc == null) {
            throw WeaverException.newBasic(
                    "'assertAuthor' is being called, but no page has been associated with the AuthRequest object");
        }
        if (ngc.isFrozen()) {
            throw WeaverException.newBasic("Workspace is frozen");
        }
    }

    public List<AddressListEntry> getMatchedFragment(String frag) throws Exception {
        List<AddressListEntry> matchedContacts = null;
        UserPage up = getUserPage();
        NGRole aRole = up.getRole("Contacts");
        if (aRole != null) {
            matchedContacts = aRole.getMatchedFragment(frag);
        }

        if (matchedContacts == null) {
            matchedContacts = new ArrayList<AddressListEntry>();
        }
        matchedContacts.addAll(up.getPeopleYouMayKnowList());
        return matchedContacts;
    }

    // it removes whitespace from string and filters extended ASCII letters (above
    // 127) too.
    public static String removeWhiteSpace(String str) {

        StringBuilder stringBuff = new StringBuilder();
        char aChar;
        if (str == null) {
            throw new ProgramLogicError("Can not remove whitespaces from a null string");
        }
        for (int i = 0; i < str.length(); i++) {
            aChar = str.charAt(i);
            if (Character.isLetter(aChar)) {
                stringBuff.append(aChar);
            }
        }
        return stringBuff.toString();
    }

    /**
     * clears "autoLogin" flag and "openId" (used for re-authentication)
     */
    public void clearCookie() {

        Cookie autoLoginCookie = new Cookie("autoLoginCookie", "");
        autoLoginCookie.setPath(req.getContextPath());
        autoLoginCookie.setMaxAge(0);
        resp.addCookie(autoLoginCookie);
        Cookie openIdCookie = new Cookie("openIdCookie", "");
        openIdCookie.setPath(req.getContextPath());
        openIdCookie.setMaxAge(0);
        resp.addCookie(openIdCookie);
    }

    public Cognoscenti getCogInstance() {
        return cog;
    }

    public SuperAdminLogFile getSuperAdminLogFile() throws Exception {
        return SuperAdminLogFile.getInstance(cog);
    }

    public ErrorLog getLogForDate(long date) throws Exception {
        return ErrorLog.getLogForDate(date, cog);
    }

    public void recordVisit(String site, String workspace) {
        if (this.user != null) {
            cog.recordVisit(user.getKey(), site, workspace, nowTime);
        }
    }

    public List<String> whoIsVisiting(String site, String workspace) {
        return cog.whoIsVisiting(site, workspace);
    }

    public File findChunkTemplate(String templateName) throws Exception {

        // first look to see if there is a custom one
        if (ngp != null) {
            NGBook site;
            if (ngp instanceof NGWorkspace) {
                site = ((NGWorkspace) ngp).getSite();
            } else if (ngp instanceof NGBook) {
                site = (NGBook) ngp;
            } else {
                throw WeaverException.newBasic("No idea what ngp is at this attempt to findChunkTemplate");
            }

            File cogFolder = new File(site.getSiteRootFolder(), ".cog");
            File customTemplate = new File(cogFolder, templateName);
            if (customTemplate.exists()) {
                return customTemplate;
            }
        }

        // get the default one from the email folder
        File templateFolder = getCogInstance().getConfig().getFileFromRoot("email");
        File stdTemplate = new File(templateFolder, templateName);
        if (stdTemplate.exists()) {
            return stdTemplate;
        }

        // or maybe the meets folder
        templateFolder = getCogInstance().getConfig().getFileFromRoot("meets");
        stdTemplate = new File(templateFolder, templateName);
        if (stdTemplate.exists()) {
            return stdTemplate;
        }

        // or maybe the meets folder
        templateFolder = getCogInstance().getConfig().getFileFromRoot("siteLayouts");
        stdTemplate = new File(templateFolder, templateName);
        if (stdTemplate.exists()) {
            return stdTemplate;
        }

        throw WeaverException.newBasic("The standard chunk template '%s' does not exist!", templateName);
    }

}
