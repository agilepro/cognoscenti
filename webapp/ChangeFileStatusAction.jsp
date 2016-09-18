<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page errorPage="error.jsp"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.HistoryRecord"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="java.io.File"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Properties"
%>
<%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to complete request .");

    Hashtable params = new Hashtable();
    Enumeration sElements = request.getParameterNames();
    while (sElements.hasMoreElements())
    {
        String key = (String) sElements.nextElement();
        String value = request.getParameter(key);
        params.put(key, value);
    }

    String p        = reqParamSpecial(params, "p");
    String action   = reqParamSpecial(params, "action");
    String rId      = reqParamSpecial(params, "rId");
    String ftime      = reqParamSpecial(params, "ftime");
    String fsize      = reqParamSpecial(params, "fsize");
    String fname      = reqParamSpecial(params, "fname");
    String go = (String)params.get("go");

    assureNoParameter(ar, "s");


    ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Can not edit file status");

    if (go == null || go.length()==0)
    {
       go = ar.getResourceURL(ngp,"attach.htm");
    }
    response.sendRedirect(go);

%>
<%@ include file="functions.jsp"%>

<%!
    public String
    reqParamSpecial(Hashtable params, String paramName)
        throws Exception
    {
        String val = (String) params.get(paramName);
        if (val == null || val.length()==0) {
            throw new Exception("Page ChangeFileStatusAction.jsp requires a parameter named '"+paramName+"'. ");
        }
        return val;
    }

%>
