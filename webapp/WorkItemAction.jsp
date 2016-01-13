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
%><%@page import="org.socialbiz.cog.IdGenerator"
%><%@page import="org.socialbiz.cog.DOMUtils"
%><%@page import="java.util.Properties"
%><%@page import="org.w3c.dom.Document"
%><%@page import="org.w3c.dom.Element"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.util.StringTokenizer"
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
    String id = ar.reqParam("id");
    String go = ar.reqParam("go");
    String action = ar.reqParam("action");

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);

    String comments = "";

    GoalRecord task = ngp.getGoalOrFail(id);

    //handle the claim id case first
    String claim = ar.defParam("claim", null);
    if (claim != null && claim.equals("yes"))
    {
        task.setAssigneeCommaSeparatedList(ar.getBestUserId());
    }
    int eventType = HistoryRecord.EVENT_TYPE_MODIFIED;

    if (action.equals("Create SubTask"))
    {
        StringBuffer goStr = new StringBuffer("CreateTask.jsp?p=");
        goStr.append(SectionUtil.encodeURLData(p));
        goStr.append("&ptid=");
        goStr.append(SectionUtil.encodeURLData(task.getId()));
        go = goStr.toString();
        eventType = HistoryRecord.EVENT_TYPE_SUBTASK_CREATED;
    }
    else if (action.equals("Create Subleaf"))
    {
        createNewSubPage = true;
        // This will always create a new page.
        // use a random key for the page name instread of constructing it from the synopsis.
        String newPageKey = IdGenerator.generateKey();
        String pageBook = ngp.getSite().getKey();
        LicensedURL thisUrl =task.getWfxmlLink(ar);

        StringBuffer goStr = new StringBuffer("CreatePage.jsp?pt=");
        String synopsis = task.getSynopsis();
        goStr.append(SectionUtil.encodeURLData(synopsis + " for " + ngp.getFullName()));
        if (pageBook!=null)
        {
            goStr.append("&b=");
            goStr.append(SectionUtil.encodeURLData(pageBook));
        }
        goStr.append("&pp=");
        goStr.append(SectionUtil.encodeURLData(thisUrl.getCombinedRepresentation()));
        goStr.append("&gs=");
        goStr.append(SectionUtil.encodeURLData(synopsis));
        goStr.append("&gd=");
        goStr.append(SectionUtil.encodeURLData(task.getDescription()));
        go = goStr.toString();
        eventType = HistoryRecord.EVENT_TYPE_SUBLEAF_CREATED;
    }
    else if (action.equals("Start Activity"))
    {
        eventType = HistoryRecord.EVENT_TYPE_STATE_CHANGE_STARTED;
        String appRoot = application.getRealPath("/").trim();
        task.setState(BaseRecord.STATE_OFFERED);
    }
    else if (action.equals("Mark Accepted") || action.equals("Accept Activity"))
    {
        long beginTime = task.getStartDate();
        if (beginTime==0)
        {
            task.setStartDate(ar.nowTime);
        }
        task.setState(BaseRecord.STATE_ACCEPTED);
        eventType = HistoryRecord.EVENT_TYPE_STATE_CHANGE_ACCEPTED;
    }
    else if (action.equals("Complete Activity"))
    {
        task.setEndDate(ar.nowTime);
        task.setState(BaseRecord.STATE_COMPLETE);
        eventType = HistoryRecord.EVENT_TYPE_STATE_CHANGE_COMPLETE;
    }
    else if (action.equals("Update Status"))
    {
        String newStatus = ar.defParam("status", null);
        task.setStatus(newStatus);
        String accomp = ar.defParam("accomp", null);
        if (accomp!=null)
        {
            comments = accomp;
        }
    }
    else if (action.equals("Approve"))
    {
        eventType = HistoryRecord.EVENT_TYPE_APPROVED;
        task.approve(ar.getBestUserId());
        comments = ar.defParam("reason", "");
    }
    else if (action.equals("Reject"))
    {
        eventType = HistoryRecord.EVENT_TYPE_REJECTED;
        task.reject(ar.getBestUserId());
        comments = ar.defParam("reason", "");
    }
    else
    {
        throw new Exception("WorkItemAction page does not understand this action: "+action);
    }


    task.setModifiedDate(ar.nowTime);
    task.setModifiedBy(ar.getBestUserId());
    HistoryRecord.createHistoryRecord(ngp,
            task.getId(), HistoryRecord.CONTEXT_TYPE_TASK,
            eventType, ar, comments);

    ngp.saveFile(ar, action);
    response.sendRedirect(go);%>
<%@ include file="functions.jsp"%>
