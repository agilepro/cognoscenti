<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.ProcessRecord"
%><%@page import="java.util.Vector"
%><%@page import="java.util.Enumeration"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't update Parent Processes list.");

    String p = ar.reqParam("p");
    String s = ar.reqParam("s");
    String go = ar.reqParam("go");
    String action = ar.reqParam("action");

    ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);


    Vector vect = new Vector();
    Enumeration en = request.getParameterNames();
    for (int i=0; en.hasMoreElements(); i++)
    {
        String key = (String)en.nextElement();
        if (key.startsWith("parentProcess")) {
            String value = request.getParameter(key);
            if (value != null && value.length() > 0) {
                vect.add(value);
            }
        }
    }

    NGSection ngs = ngp.getSectionOrFail(s);
    ar.assertMember("Unable to edit tasks on this page.");
    ProcessRecord process = ngp.getProcess(ngs);

    LicensedURL[] lps = new LicensedURL[vect.size()];
    Enumeration e = vect.elements();
    while(e.hasMoreElements())
    {
        lps[i] = new LicensedURL((String)e.nextElement());
    }
    process.setLicensedParents(lps);

    process.setParentProcesses(pp);
    ngs.setLastModify(ar);
    ngp.saveFile(ar, "Edit Task");

    response.sendRedirect(go);%>
<%@ include file="functions.jsp"%>
