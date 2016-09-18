<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.rest.DataFeedServlet"
%><%@page import="org.socialbiz.cog.DOMFace"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.RemoteGoal"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.rest.TaskHelper"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%AuthRequest ar = null;
    String goUrl = "";
    String pageTitle = null;
    String newUIResource = "public.htm";
    UserProfile uProf = null;
    String specialTab = "";


    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't manage Task list.");

    uProf = findSpecifiedUserOrDefault(ar);
    UserPage uPage = UserManager.findOrCreateUserPage(uProf.getKey());

    String filter = ar.defParam(DataFeedServlet.OPERATION_GETTASKLIST, DataFeedServlet.MYACTIVETASKS);

    pageTitle = "Manage Action Items: "+uProf.getName();
    specialTab = "Manage Action Items";

    TaskHelper th = new TaskHelper(uProf.getUniversalId(), "");
    th.scanAllTask(ar.getCogInstance());

    String taskid = ar.reqParam("taskid");
    String projid = ar.reqParam("projid");
    String op = ar.reqParam("op");
    String go = ar.reqParam("go");

    RemoteGoal ref = uPage.findOrCreateTask(projid, taskid);

    if ("Update Status".equals(op)) {

        String status = ar.reqParam("status");
        String accomp = ar.defParam("accomp", null);
        int rank = DOMFace.safeConvertInt(ar.reqParam("rank"));

        ref.setStatus(status);
        if (rank>0) {
            ref.setRank(rank);
        }
        uPage.cleanUpTaskRanks();

        NGPage ngpx = ar.getCogInstance().getWorkspaceByKeyOrFail(projid);
        GoalRecord tr = ngpx.getGoalOrFail(taskid);

        tr.setStatus(status);
        if (accomp!=null) {
            HistoryRecord.createHistoryRecord(ngpx,
                taskid, HistoryRecord.CONTEXT_TYPE_TASK,
                HistoryRecord.EVENT_TYPE_MODIFIED, ar, accomp);
        }
        ngpx.saveFile(ar, "User updating their status");
        uPage.saveFile(ar,"User updating their status");

        response.sendRedirect(go+"#"+taskid);
        return;
    }
    else if ("Move Up".equals(op)) {
        int myRank = ref.getRank();
        if (myRank<=0) {
            throw new Exception("something wrong, rank values are never supposed to be less than one");
        }
        int highestPreceedingRank = 0;
        RemoteGoal found = null;
        for (RemoteGoal refx : uPage.getRemoteGoals()) {
            int rankx = refx.getRank();
            if (rankx<myRank && rankx>highestPreceedingRank) {
                highestPreceedingRank = rankx;
                found = refx;
            }
        }

        if (found!=null) {
            found.setRank(myRank);
            ref.setRank(highestPreceedingRank);
            uPage.saveUserPage(ar,"User updating their status");
        }
    }
    else if ("Move Down".equals(op)) {
        int myRank = ref.getRank();
        if (myRank<=0) {
            throw new Exception("something wrong, rank values are never supposed to be less than one");
        }
        int lowestFollowingRank = 99999;
        RemoteGoal found = null;
        for (RemoteGoal refx : uPage.getRemoteGoals()) {
            int rankx = refx.getRank();
            if (rankx>myRank && rankx<lowestFollowingRank) {
                lowestFollowingRank = rankx;
                found = refx;
            }
        }

        if (found!=null) {
            found.setRank(myRank);
            ref.setRank(lowestFollowingRank);
            uPage.saveUserPage(ar,"User updating their status");
        }
    }
    response.sendRedirect(go);%>
<%@ include file="functions.jsp"%>
