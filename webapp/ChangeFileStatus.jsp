<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page errorPage="error.jsp"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.HistoryRecord"
%><%@page import="org.socialbiz.cog.FileRecord"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Properties"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to complete request. ");

    Hashtable params = new Hashtable();
    Enumeration sElements = request.getParameterNames();
    while (sElements.hasMoreElements())
    {
        String key = (String) sElements.nextElement();
        String value = request.getParameter(key);
        params.put(key, value);
    }

    String p        = reqParamSpecial(params, "p");
    String rId      = reqParamSpecial(params, "rId");
    String ftime      = reqParamSpecial(params, "ftime");
    String fsize      = reqParamSpecial(params, "fsize");
    String fname      = reqParamSpecial(params, "fname");
    String go = (String)params.get("go");

    assureNoParameter(ar, "s");

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Can not edit file status");

    ngb = ngp.getSite();
    pageTitle = ngp.getFullName();

    if (go == null || go.length()==0)
    {
        go = ar.getResourceURL(ngp,"attach.htm");
    }%>

<%@ include file="Header.jsp"%>



<form name="fileForm" method="get" action="ChangeFileStatusAction.jsp" enctype="multipart/form-data" onSubmit="enableAllControls()">
    <input type="hidden" name="p" value="<% ar.writeHtml(p); %>">
    <input type="hidden" name="rId" value="<% ar.writeHtml(rId); %>">
    <input type="hidden" name="ftime" value="<% ar.writeHtml(ftime); %>">
    <input type="hidden" name="fsize" value="<% ar.writeHtml(fsize); %>">
    <input type="hidden" name="fname" value="<% ar.writeHtml(fname); %>">
    <input type="hidden" name="go" value="<% ar.writeHtml(go); %>">


    <center>
        <button type="submit" id="actBtn2" name="action" value="Cancel">Cancel</button>
        Mark Document as:
        <button type="submit" id="actBtn3" name="action" value="Accept">Read</button>
        <button type="submit" id="actBtn4" name="action" value="Reject">Needs Improvement</button>
        <button type="submit" id="actBtn5" name="action" value="Skipped">Skipped</button>
    </center>
    <br/>

</form>

<script>
    var actBtn2 = new YAHOO.widget.Button("actBtn2");
    var actBtn3 = new YAHOO.widget.Button("actBtn3");
    var actBtn4 = new YAHOO.widget.Button("actBtn4");
    var actBtn5 = new YAHOO.widget.Button("actBtn5");
</script>


<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>

<%!
    public String
    reqParamSpecial(Hashtable params, String paramName)
        throws Exception
    {
        String val = (String) params.get(paramName);
        if (val == null || val.length()==0) {
            throw new Exception("Page ChangeFileStatus.jsp requires a parameter named '"+paramName+"'. ");
        }
        return val;
    }

%>

