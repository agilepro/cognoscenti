<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.LicensedURL"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.ProcessRecord"
%><%@page import="org.socialbiz.cog.SectionTask"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);

/*
* The purpose of this page is to provide a place to redirect the browser
* to for making a linkage.  Redirecting, and passing parameters to this
* page, create a task or links a subprocess to a task, and then redirect
* back to the starting place.  The user needs to be logged in with a
* session with this host, and if so everything should be transparent.
* If not, this might fail.
*/

    //This is the URL to the task (if linking) or process (if creating)
    String wf = ar.reqParam("wf");

    //this is the subprocess address to link to
    String sp = ar.reqParam("sp");

    //this is the address to return to
    String go = ar.reqParam("go");

    //Given the task/process link, find the page
    boolean willCreate;

    if (wf.endsWith("process.xml"))
    {
        willCreate = true;
    }
    else if (wf.endsWith("data.xml"))
    {
        willCreate = false;
    }
    else
    {
        throw new Exception("Sorry, do not understand the URL: "+wf);
    }

    // url must be of this form: .../p/{pagekey}/...
    int beginOfPageKey = wf.indexOf("/p/")+3;
    int endOfPageKey = wf.indexOf("/", beginOfPageKey);

    String pageKey = wf.substring(beginOfPageKey, endOfPageKey);

    ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(pageKey);
    ar.setPageAccessLevels(ngp);
    NGSection ngs = ngp.getSectionOrFail("Tasks");
    ar.assertMember("Unable to edit process on page "+pageKey);
    SectionTask taskSec = (SectionTask) ngs.getFormat();
    ProcessRecord process = ngp.getProcess();
    LicensedURL subURL = LicensedURL.parseCombinedRepresentation(sp);

    if (willCreate)
    {
        // url must be of this form: .../p/{pagekey}/process.xml
        GoalRecord tr = ngp.createGoal();
        tr.setLicensedSub(subURL);
        //this is the subject (synopsis) of task to create
        String ts = ar.reqParam("ts");

        //this is the description of task to create
        String td = ar.defParam("td", "");

        tr.setSynopsis(ts);
        tr.setDescription(td);
        tr.setState(BaseRecord.STATE_WAITING);
    }
    else
    {
        //need to find the specified task
        // url must be of this form: .../p/{pagekey}/s/Tasks/id/{taskid}/
        int beginOfId = endOfPageKey+12;
        int endOfId = wf.indexOf("/", beginOfId);
        String taskId = wf.substring(beginOfId, endOfId);
        GoalRecord tr = ngp.getGoalOrFail(taskId);
        tr.setLicensedSub(subURL);
        tr.setState(BaseRecord.STATE_WAITING);
    }

    ngs.setLastModify(ar);
    ngp.saveFile(ar, "Linked with Subprocess");

    response.sendRedirect(go);%>
<%@ include file="functions.jsp"%>

