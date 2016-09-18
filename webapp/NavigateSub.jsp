<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't navigate to sub folder.");

    String p = ar.reqParam("p");
    String id = ar.reqParam("id");

    ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);

    GoalRecord task = null;
    for (GoalRecord tr : ngp.getAllGoals())
    {
        if (id.equals(tr.getId()))
        {
            task = tr;
        }
    }
    if (task==null)
    {
        throw new Exception("Can not find an action item with the id = "+id);
    }

    //this retrieves the process.xml url
    String sub = getFullyQualifiedUrl(task.getSub(), request.getContextPath());

    String dummy = null;

    //fetch the process xml file, and pull the display url from it
    //dummy out for now
    if (sub.endsWith("process.xml"))
    {
        dummy = sub.substring(0, sub.length()-11)+"public.htm";
    }
    else if (sub.endsWith(".wfxml"))
    {
        dummy = sub.substring(0, sub.length()-13)+"public.htm";
    }
    else if (sub.length()==0)
    {
        throw new Exception("Unable to navigate to the subprocess because there is no subprocess URL associated with task '"+task.getSynopsis()+"'");
    }
    else
    {
        throw new Exception("Unable to navigate to the subprocess of task '"+task.getSynopsis()+"' because I can't understand that subprocess URL: "+sub);
    }

    response.sendRedirect(dummy);%>
<%@ include file="functions.jsp"%>
<%!

    //IS THIS NEEDED?
    public static String getFullyQualifiedUrl(String urlFragment,
            String contextPath) {

        if (urlFragment != null) {
            // incase of a relative URL name append the context root to the URL.
            if ((urlFragment.toUpperCase().indexOf("HTTP://") == -1)
                    && (urlFragment.toUpperCase().indexOf("WWW.") == -1)) {
                if (!urlFragment.startsWith("/")) {
                    urlFragment = "/" + urlFragment;
                }
                urlFragment = contextPath + urlFragment;
            }
        }
        return urlFragment;
    }

%>
