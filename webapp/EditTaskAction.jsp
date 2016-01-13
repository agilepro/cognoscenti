<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.DOMFace"
%><%@page import="org.socialbiz.cog.HistoryRecord"
%><%@page import="org.socialbiz.cog.IdGenerator"
%><%@page import="org.socialbiz.cog.LicensedURL"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't edit a action item.");
    boolean createNewSubPage = false;

    //here we are testing is TomCat is configured correctly.  If it is this value
    //will be received uncorrupted.  If not, we will attempt to correct things by
    //doing an additional decoding
    setTomcatKludge(request);

    String p = ar.reqParam("p");
    String go = ar.reqParam("go");
    String action = ar.reqParam("action");

    String id = ar.defParam("id", null);
    String ptid = ar.defParam("ptid", null);
    boolean isSubTask =  (ptid !=null && ptid.length()>0);

    assureNoParameter(ar, "s");


    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Can not create a new action item.");

    String synopsis = ar.reqParam("synopsis");
    String description = ar.defParam("description", "");
    String assignee = ar.defParam("assignee", "");
    String reviewers = ar.defParam("reviewers", "");
    assignee = pasreFullname(assignee);
    String status = ar.defParam("status", "");
    String ascripts = ar.defParam("ascripts", "");
    String dueDate = ar.defParam("dueDate", null);
    String startDate = ar.defParam("startDate", null);
    String endDate = ar.defParam("endDate", null);
    String sub = ar.defParam("sub", "");
    int state = defParamInt(ar, "state", -1);
    String rank = ar.defParam("rank", null);
    String accomp = ar.defParam("accomp", "");
    long duration = defParamLong(ar, "duration", 1);
    int priority = defParamInt(ar, "priority", 0);

    int eventType = HistoryRecord.EVENT_TYPE_MODIFIED;

    GoalRecord task = null;
    GoalRecord parentTask = null;

    if (isSubTask) {
        parentTask = ngp.getGoalOrFail(ptid);
    }

    if (action.equals("Create New Task"))
    {
        // addTask creates history event internally.
        if (isSubTask) {
            task = addSubTask(ar, ngp, ptid);
        }
        else {
            task = addTask(ar, ngp);
        }
        go="Edit.jsp?p="+SectionUtil.encodeURLData(p)
                     + "&s=Tasks";
        eventType = HistoryRecord.EVENT_TYPE_CREATED;
    }
    else if (action.equals("Create Sub Action Item"))
    {
        task = ngp.getGoalOrFail(id);
        StringBuffer goStr = new StringBuffer("CreateTask.jsp?p=");
        goStr.append(SectionUtil.encodeURLData(p));
        goStr.append("&ptid=");
        goStr.append(SectionUtil.encodeURLData(task.getId()));
        go = goStr.toString();
        eventType = HistoryRecord.EVENT_TYPE_SUBTASK_CREATED;
    }
    else if (action.equals("Renumber Ranks"))
    {
        task = ngp.getGoalOrFail(id);
        eventType = HistoryRecord.EVENT_TYPE_REORDERED;
    }
    else if (action.equals("Save Changes"))
    {
        task = ngp.getGoalOrFail(id);
    }
    else if (action.equals("Approve"))
    {
        task = ngp.getGoalOrFail(id);
        eventType = HistoryRecord.EVENT_TYPE_APPROVED;
    }
    else if (action.equals("Reject"))
    {
        task = ngp.getGoalOrFail(id);
        eventType = HistoryRecord.EVENT_TYPE_REJECTED;
    }
    else
    {
        throw new Exception("EditTaskAction page does not understand this action: "+action);
    }


    if (task==null)
    {
        throw new Exception("Not able to find an action item with id = '"+id+"' on this project.");
    }

    if (synopsis!=null) {
        task.setSynopsis(synopsis );
    }
    if (description!=null)
    {
        task.setDescription(description );
    }
    // keep reviewers first and then the assignees.
    if (reviewers!=null)
    {
        task.setReviewers(reviewers );
    }
    if (assignee!=null)
    {
        task.setAssigneeCommaSeparatedList(assignee );
    }
    if (status!=null)
    {
        task.setStatus(status );
    }
    if (ascripts!=null)
    {
        task.setActionScripts(ascripts );
    }
    if (dueDate!=null)
    {
        task.setDueDate(SectionUtil.niceParseDate(dueDate));
    }
    else {
        if (isSubTask) {
            // set the subtask's due date.
            task.setDueDate(parentTask.getDueDate());
        }
    }
    if (startDate!=null)
    {
        task.setStartDate(SectionUtil.niceParseDate(startDate));
    }
    if (endDate!=null)
    {
        task.setEndDate(SectionUtil.niceParseDate(endDate));
    }
    if (sub!=null)
    {
        task.setSub(sub);
    }
    if (rank!=null)
    {
        task.setRank(DOMFace.safeConvertInt(rank));
    }
    if (duration>=0)
    {
        task.setDuration(duration);
    }
    if (priority>=0)
    {
        task.setPriority(priority);
    }
    // keep the set state final.
    if (state>=0)
    {
        task.setState(state );
    }

    if (action.equals("Renumber Ranks"))
    {
        ngp.renumberGoalRanks();
    }
    if (action.equals("Approve"))
    {
        task.approve(ar.getBestUserId());
    }
    if (action.equals("Reject"))
    {
        task.reject(ar.getBestUserId());
    }


    task.setModifiedDate(ar.nowTime);
    task.setModifiedBy(ar.getBestUserId());
    HistoryRecord.createHistoryRecord(ngp,
            task.getId(), HistoryRecord.CONTEXT_TYPE_TASK,
            eventType, ar, accomp);

    ngp.saveFile(ar, "Edit Task");
    response.sendRedirect(go);%>
<%@ include file="functions.jsp"%>
<%!
    public GoalRecord addSubTask(AuthRequest ar, NGPage ngp, String ptid)
        throws Exception
    {
        GoalRecord task = ngp.createSubGoal(ngp.getGoalOrFail(ptid));
        task.setModifiedBy(ar.getBestUserId());
        task.setModifiedDate(ar.nowTime);
        return task;
    }
    public GoalRecord addTask(AuthRequest ar, NGPage ngp)
        throws Exception
    {
        GoalRecord task = ngp.createGoal();
        task.setModifiedBy(ar.getBestUserId());
        task.setModifiedDate(ar.nowTime);
        return task;
    }
 %>
