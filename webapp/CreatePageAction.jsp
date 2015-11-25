<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.IdGenerator"
%><%@page import="org.socialbiz.cog.LicensedURL"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.ProcessRecord"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.SectionWiki"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="org.w3c.dom.Element"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't create a page.");

    //here we are testing is TomCat is configured correctly.  If it is this value
    //will be received uncorrupted.  If not, we will attempt to correct things by
    //doing an additional decoding
    setTomcatKludge(request);

    String p = ar.reqParam("p");
    String pt = ar.reqParam("fullName");
    String fullName = ar.reqParam("fullName");
    String pp = ar.defParam("pp", null);
    String wflink = ar.defParam("wflink", "");
    String abbreviation = ar.defParam("abbreviation", null);
    String book = ar.defParam("book", null);
    String processSynopsis = ar.defParam("processSynopsis", "");
    String processDesc = ar.defParam("processDesc", "");
    String template = ar.defParam("template", null);

    if (p.equals("----------"))
    {
        p = findGoodFileName(pt);
    }

    if (wflink.equals("yes"))
    {
        //do the wfxml linking here
        throw new Exception("Sorry, the Wf-XML binding approach had not been implemented");
    }

    // if account is null you will get the default account
    NGBook ngb = ar.getCogInstance().getSiteByIdOrFail(book);
    if (!ngb.primaryOrSecondaryPermission(new AddressListEntry(ar.getUserProfile())))
    {
        throw new Exception("You must be a member of an account in order to create a project in it.  You are not a member of account "+ngb.getFullName());
    }

    String pageKey = SectionWiki.sanitize(p);
    NGPage ngp = ngb.createProjectByKey(ar, pageKey);

    if (template!=null && template.length()>0) {
        NGPage templatePage = ar.getCogInstance().getProjectByKeyOrFail(template);
        ngp.injectTemplate(ar, templatePage);
    }

    String[] nameSet = new String[1];
    if (abbreviation!=null)
    {
        nameSet = new String[2];
        nameSet[1]=abbreviation;
    }
    nameSet[0] = fullName;

    ngp.setPageNames(nameSet);


    ngp.setSite(ngb);

    ProcessRecord process = ngp.getProcess();
    process.setSynopsis(processSynopsis);
    process.setDescription(processDesc);

    LicensedURL parent = null;

    if (pp != null && pp.length()>0) {

        parent = LicensedURL.parseCombinedRepresentation(pp);
        process.addLicensedParent(parent);
    }

    ngp.saveFile(ar, "Creating a page");
    ar.setPageAccessLevels(ngp);

    //now, link up the page with the parent
    if (parent!=null)
    {
        if (wflink.equals("yes"))
        {
            //do the wfxml linking here
            throw new Exception("Sorry, the Wf-XML binding approach had not been implemented");
        }
        else if (wflink.equals("no"))
        {
            LicensedURL thisUrl = process.getWfxmlLink(ar);

            //return to the project page itself
            String returnUrl = ar.baseURL + ar.getResourceURL(ngp,"");

            //  url must have this form:  http://.../p/...
            int ppos = parent.url.indexOf("/p/");
            if (ppos<0)
            {
                throw new Exception("Hmmm, can't do the NuGen page redirect because parent process URL given was '"+pp+"' and this does not make sense (no p in it)");
            }
            StringBuffer goToUrl = new StringBuffer();

            goToUrl.append(parent.url.substring(0,ppos));
            goToUrl.append("/ForgeLinkCC.jsp");
            goToUrl.append("?wf=");
            goToUrl.append(URLEncoder.encode(pp, "UTF-8"));
            goToUrl.append("&ts=");
            goToUrl.append(URLEncoder.encode(processSynopsis, "UTF-8"));
            goToUrl.append("&td=");
            goToUrl.append(URLEncoder.encode(processDesc, "UTF-8"));
            goToUrl.append("&sp=");
            goToUrl.append(URLEncoder.encode(thisUrl.getCombinedRepresentation(), "UTF-8"));
            goToUrl.append("&go=");
            goToUrl.append(URLEncoder.encode(returnUrl, "UTF-8"));

            response.sendRedirect(goToUrl.toString());
            return;
        }
    }

    response.sendRedirect(ar.getResourceURL(ngp,""));%>
<%!//make search friendly urls
    public String sanitizeHyphenate(String p)
        throws Exception
    {
        String plc = p.toLowerCase();
        StringBuffer result = new StringBuffer();
        boolean wasPunctuation = false;
        for (int i=0; i<plc.length(); i++)
        {
            char ch = plc.charAt(i);
            boolean isAlphaNum = ((ch>='a')&&(ch<='z'))||((ch>='0')&&(ch<='9'));
            if (isAlphaNum)
            {
                if (wasPunctuation)
                {
                    result.append('-');
                    wasPunctuation = false;
                }
                result.append(ch);
            }
            else
            {
                wasPunctuation = true;
            }
        }
        return result.toString();
    }

    public String findGoodFileName(String pt)
        throws Exception
    {
        String p = sanitizeHyphenate(pt);
        if (p.length()==0)
        {
            p = IdGenerator.generateKey();
        }
        File theFile = NGPage.getPathInDataFolder(p+".sp");
        if (!theFile.exists())
        {
            return p;
        }
        while (true)
        {
            String extp = p + "-" + IdGenerator.generateKey();
            theFile = NGPage.getPathInDataFolder(extp+".sp");
            if (!theFile.exists())
            {
                return extp;
            }
        }
    }%><%@ include file="functions.jsp"%>
