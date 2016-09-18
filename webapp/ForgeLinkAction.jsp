<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.License"
%><%@page import="org.socialbiz.cog.rest.TaskLinkHelper"
%><%@page import="org.socialbiz.cog.LicensedURL"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.ProcessRecord"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="java.net.HttpURLConnection"
%><%@page import="java.net.URL"
%><%@page import="java.io.InputStream"
%><%@page import="java.io.BufferedReader"
%><%@page import="java.io.InputStreamReader"
%><%@page import="org.w3c.dom.Document"
%><%@page import="org.w3c.dom.Element"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to edit parent process links.");

    String p = ar.reqParam("p");
    ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    String go = ar.defParam("go", ar.getResourceURL(ngp,""));
    NGSection ngs = ngp.getSectionOrFail("Tasks");
    ar.assertMember("Unable to edit parent process links on this page.");
    ProcessRecord process = ngp.getProcess(ngs);

    String createTask = ar.reqParam("createTask");
    String linkwf = ar.reqParam("linkwf");

    LicensedURL destUrl;
    String ts = "no_subject";
    String td = "no_description";

    LicensedURL thisUrl = process.getWfxmlLink(ar);

    if ("no".equals(createTask))
    {
        destUrl = LicensedURL.parseCombinedRepresentation(
                    ar.reqParam("taskUrl"));
    }
    else
    {
        destUrl = LicensedURL.parseCombinedRepresentation(
                    ar.reqParam("procUrl"));
        ts = ar.reqParam("taskSub");
        td = ar.defParam("taskDes", "");
    }

    if (linkwf.equals("no"))
    {
        //this is just a case of getting the parameters and redirecting
        //return to the project itself
        String returnUrl = ar.baseURL + ar.getResourceURL(ngp,"");

        //  url must have this form:  http://.../p/...
        int ppos = destUrl.url.indexOf("/p/");
        StringBuffer goToUrl = new StringBuffer();

        goToUrl.append(destUrl.url.substring(0,ppos));
        goToUrl.append("/ForgeLinkCC.jsp");
        goToUrl.append("?wf=");
        goToUrl.append(URLEncoder.encode(destUrl.getCombinedRepresentation(), "UTF-8"));
        goToUrl.append("&ts=");
        goToUrl.append(URLEncoder.encode(ts, "UTF-8"));
        goToUrl.append("&td=");
        goToUrl.append(URLEncoder.encode(td, "UTF-8"));
        goToUrl.append("&sp=");
        goToUrl.append(URLEncoder.encode(thisUrl.getCombinedRepresentation(), "UTF-8"));
        goToUrl.append("&go=");
        goToUrl.append(URLEncoder.encode(returnUrl, "UTF-8"));

        process.addLicensedParent(destUrl);
        ngs.setLastModify(ar);
        ngp.saveFile(ar, "Edit Task");

        response.sendRedirect(goToUrl.toString());
        return;
    }
    if (linkwf.equals("yes")){

        String combinedURL = destUrl.getCombinedRepresentation();
        TaskLinkHelper th = new TaskLinkHelper(ar, ngp, combinedURL);
        if ("no".equals(createTask)){
            th.setTaskLink();
        }else if ("yes".equals(createTask)){
            th.creatTaskWithLink(ts,td);
        }

        process.addLicensedParent(destUrl);
        ngs.setLastModify(ar);
        ngp.saveFile(ar, "Edit Task");

        response.sendRedirect(go);
        return;
    }%>
<%@ include file="functions.jsp"%>

