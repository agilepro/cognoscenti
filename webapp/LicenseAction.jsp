<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.DOMFace"
%><%@page import="org.socialbiz.cog.IdGenerator"
%><%@page import="org.socialbiz.cog.License"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to create a licenses.");
    boolean createNewSubPage = false;

    String p = ar.reqParam("p");
    String duration = ar.defParam("duration", "60");   //days
    String go = ar.reqParam("go");
    String action = ar.reqParam("action");
    boolean readOnly = "yes".equals(ar.defParam("readOnly", "no"));

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Unable to create a license for this page.");

    long timeout = (DOMFace.safeConvertLong(duration)*24000*3600) + ar.nowTime;

    if (action.equals("Create License") || action.equals("Create New Streaming Link")) {
        License lr = ngp.createLicense(ar.getBestUserId(), ar.reqParam("role"), timeout, readOnly);
        ngp.saveFile(ar, action);
    }

    response.sendRedirect(go);%>
<%@ include file="functions.jsp"%>
