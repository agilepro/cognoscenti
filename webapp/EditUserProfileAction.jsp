<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.ValueElement"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.UserManager"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);

    String action = ar.reqParam("action");
    String u      = ar.reqParam("u");
    String go     = ar.reqParam("go");

    if (action.equalsIgnoreCase("CANCEL"))
    {
        response.sendRedirect(go);
        return;
    }

    ar.assertLoggedIn("Must be logged in to edit a user's profile.");

    UserProfile profile = UserManager.getUserProfileByKey(u);

    if (profile == null)
    {
        throw new Exception("Can not find a user with the key = '"+u+"'.");
    }

    if (action.equals("Remove ID"))
    {
        String delconf = ar.defParam("delconf", null);
        if (delconf==null)
        {
            throw new Exception("In order to remove an id from you profile, you must check "
            +"the 'confirm' box to confirm that you really want to do this.  This is required "
            +"to protect you from accidentally press the wrong button and losing you settings. "
            +"Press 'back' and check the box, and try again.");
        }
        String modid = ar.reqParam("modid");
        profile.removeId(modid);
        profile.setLastUpdated(ar.nowTime);
        UserManager.writeUserProfilesToFile();
        response.sendRedirect(go);
        return;
    }



    String name      = ar.defParam("name", "");
    if (name!=null)
    {
        profile.setName(name);
    }

    String desc      = ar.defParam("description", null);
    if (desc!=null)
    {
        profile.setDescription(desc);
    }

    String email     = ar.defParam("email", null);
    if (email!=null && email.length()>0)
    {
        profile.addId(email);
    }

    String reviewers = ar.defParam("reviewers", null);
    if (reviewers!=null)
    {
        profile.setReviewers(reviewers);
    }

    String homePage  = ar.defParam("homepage", null);
    if (homePage!=null)
    {
        profile.setHomePage(homePage);
    }

    String prefEmail  = ar.defParam("prefEmail", null);
    if (prefEmail!=null)
    {
        profile.setPreferredEmail(prefEmail);
    }

    String disable   = ar.defParam("disable", null);
    if (disable!=null)
    {
        profile.setDisabled("yes".equals(disable));
    }

    // count the number of favourities been sent in the request.
    Vector favVect = new Vector();
    Enumeration en = request.getParameterNames();
    int count=0;
    while (en.hasMoreElements())
    {
        String key = (String)en.nextElement();
        if (key.startsWith("fn_"))
        {
            // apparently, these come in in reverse order
            // 3 comes before 2 comes before 1
            // must swap the order

            String ith = key.substring(key.indexOf("_")+1);
            String fname = request.getParameter(key);
            if (fname == null) fname = "";
            String fvalue = request.getParameter("fa_"+ith);
            if (fvalue == null) fvalue = "";

            if (fname.length()  == 0 && fvalue.length() > 0) fname = fvalue;
            if (fvalue.length() == 0 && fname.length()  > 0) fvalue = fname;
            if (fvalue.length() == 0 && fname.length() == 0) continue;

            ValueElement favorite = new ValueElement(fname, fvalue);
            favVect.add(favorite);
        }
    }

    ValueElement[] favorites = new ValueElement[favVect.size()];

    // apparently, these come in in reverse order
    // 3 comes before 2 comes before 1
    // must swap the order
    int offset = favorites.length-1;
    for (int i=0; i<=offset; i++)
    {
        favorites[i] = (ValueElement)favVect.elementAt(offset-i);
    }
    profile.setFavorites(favorites);

    //Now Save the updates
    profile.setLastUpdated(ar.nowTime);
    UserManager.writeUserProfilesToFile();
    response.sendRedirect(go);

%>
<%@ include file="functions.jsp"%>
