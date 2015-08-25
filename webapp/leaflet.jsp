<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.net.URLEncoder"

%><%//This is a legacy forwarding page in case people have old links
    //the old pattern is
    //   p/{projectid}/leaf{noteid}.htm
    //the servlet parses and passes, the project as "p" and the note id as "lid"

    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);

    /* if the parameter is not found in the parameters list, then find it out in the attributes list */
    String p = ar.reqParam("p");
    //note that lid could be anything passed in, including malicious scripting, so must URLEncode
    String lid = ar.reqParam("lid");

    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();

//redirect to the new UI implementation of a zoomed leaf
    String redirectURL = ar.retPath + "t/" + ngb.getKey() + "/" + ngp.getKey() + "/noteZoom" + URLEncoder.encode(lid, "UTF-8") + ".htm";
    response.sendRedirect(redirectURL);%>
<p>This resource has a new location, update the source link if possible.</p>
<p>Access the <a href="<%=redirectURL%>">resource with this link</a></p>
