<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="org.w3c.dom.Element"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't  change the goal/purpose of this page.");

    String p = ar.reqParam("p");
    String action = ar.reqParam("action");

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertAdmin("Unable to change the goal, purpose, or beam link of this page.");

    String go = ar.reqParam("go");

    if (action.equals("Update Goal and Purpose"))
    {
        String goal = ar.defParam("goal","");
        String purpose = ar.defParam("purpose","");
        String beam = ar.defParam("beam","");
        ProcessRecord process = ngp.getProcess();
        process.setSynopsis(goal);
        process.setDescription(purpose);
        ngp.setUpstreamLink(beam);
        ngp.saveFile(ar, "Changed Goal and/or Purpose of Workspace");
    }
    else
    {
        throw new Exception("ChangeGoalAction page does not understand the action: "+action);
    }

    response.sendRedirect(go);%><%@ include file="functions.jsp"%>
