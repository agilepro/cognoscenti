<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.HistoryRecord"
%><%@page import="org.socialbiz.cog.LicensedURL"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.SectionForNotes"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.DOMUtils"
%><%@page import="java.util.Properties"
%><%@page import="org.w3c.dom.Document"
%><%@page import="org.w3c.dom.Element"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.lang.StringBuffer"
%><%@page import="java.net.HttpURLConnection"
%><%@page import="java.net.URL"
%><%@page import="java.io.OutputStream"
%><%@page import="org.w3c.dom.NodeList"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't edit a work item.");
    boolean createNewSubPage = false;

    //here we are testing is TomCat is configured correctly.  If it is this value
    //will be received uncorrupted.  If not, we will attempt to correct things by
    //doing an additional decoding
    setTomcatKludge(request);

    String p = ar.reqParam("p");
    String go = ar.reqParam("go");
    String action = ar.reqParam("action");

    ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);

    ar.setPageAccessLevels(ngp);

    String comments = "";

    int eventType = HistoryRecord.EVENT_TYPE_MODIFIED;

    if (action.equals("Update Status"))
    {
        String newStatus = ar.defParam("status", null);
        HistoryRecord.createHistoryRecord(ngp,
                "0", HistoryRecord.CONTEXT_TYPE_PROCESS,
                eventType, ar, newStatus);

        ngp.saveFile(ar, "Edit Work Item");
    }
    else
    {
        throw new Exception("WorkItemAction page does not understand this action: "+action);
    }


    response.sendRedirect(go);%>
<%@ include file="functions.jsp"%>
