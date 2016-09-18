<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.HistoryRecord"
%><%@page import="org.socialbiz.cog.ProcessRecord"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to edit processes.");

    //here we are testing is TomCat is configured correctly.  If it is this value
    //will be received uncorrupted.  If not, we will attempt to correct things by
    //doing an additional decoding
    setTomcatKludge(request);
    String p = ar.reqParam("p");
    String go = ar.reqParam("go");
    String action = ar.reqParam("action");
    String id = ar.defParam("id", null);

    ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertAdmin("Unable to edit process on this page.");

    String synopsis = ar.defParam("synopsis", null);
    String desc = ar.defParam("desc", null);
    String dueDate = ar.defParam("dueDate", null);
    String startDate = ar.defParam("startDate", null);
    String endDate = ar.defParam("endDate", null);
    int state = defParamInt(ar, "state", -1);
    int priority = defParamInt(ar, "priority", 0);

    if (action.equals("Save Changes"))
    {
        //nothing to do
    }

    ProcessRecord process = ngp.getProcess();
    if (process == null) {
        throw new Exception("This page does not have a process: "+ngp.getKey());
    }
    // create MODIFIED history event.
    HistoryRecord.createHistoryRecord(ngp,
            process.getId(), HistoryRecord.CONTEXT_TYPE_PROCESS,
            HistoryRecord.EVENT_TYPE_MODIFIED, ar, "");

    if (synopsis!=null)
    {
        process.setSynopsis(synopsis);
    }
    if (desc!=null)
    {
        process.setDescription(desc);
    }
    if (state>=0)
    {
        process.setState(state );
    }
    if (dueDate!=null)
    {
        process.setDueDate(SectionUtil.niceParseDate(dueDate));
    }
    if (startDate!=null)
    {
        process.setStartDate(SectionUtil.niceParseDate(startDate));
    }
    if (endDate!=null)
    {
        process.setEndDate(SectionUtil.niceParseDate(endDate));
    }
    if (priority>=0)
    {
        process.setPriority(priority);
    }

    ngp.saveFile(ar, "Edit Gaol");

    response.sendRedirect(go);%>
<%@ include file="functions.jsp"%>
