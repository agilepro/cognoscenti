<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.DOMFace"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't edit this section.");

    //here we are testing is TomCat is configured correctly.  If it is this value
    //will be received uncorrupted.  If not, we will attempt to correct things by
    //doing an additional decoding
    setTomcatKludge(request);

    String p = ar.reqParam("p");
    String section = ar.reqParam("section");
    String action = ar.reqParam("action");
    String timestamp = ar.reqParam("timestamp");


    long longTimestamp = DOMFace.safeConvertLong(timestamp);

    ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    NGSection ngs = ngp.getSection(section);

    if ("Save".equals(action) || "Save and Continue Edit".equals(action))
    {
        ar.assertMember("Unable to edit this page.");
        long lastModifyTime = ngs.getLastModifyTime();

        String val = ar.defParam("val", "");

        if (longTimestamp != lastModifyTime)
        {
            generateCollisionPage(out, ngs, val, p, longTimestamp, ar);
            return;
        }
        ngs.setText(val, ar);
        ngp.saveFile(ar, "Edit Action");
    }
    String returnToAddress = redirectToViewLevel(ar, ngp, ngs.def.viewAccess);

    if ("Save and Continue Edit".equals(action))
    {
        returnToAddress = "Edit.jsp?s="+SectionUtil.encodeURLData(section)
                         +"&p="+SectionUtil.encodeURLData(p);
    }
    response.sendRedirect(returnToAddress);%>
<%@ include file="functions.jsp"%>

<%!


/**
 * The method below generates a visible output for this page, an "Action page".
 * Normally, this is not allowed.  Action pages should never produce output, and
 * should only redirect to pages that do produce output.  This exceptions is
 * allowed int his case because it is an "emergency"  This means that the
 * Action page is NOT ABLE to produce its action, but the user has submitted
 * data, potentially a lot of it, and we don't want to lose that either.
 * Special Situation 1: The Action page has not actually modified anything in
 * this situation, and so if you hit refresh, or fetch the page multiple times,
 * you will get the same result.
 * Special Situation 2: We can't redirect safely because the user data may be larger
 * than can be held in a GET URL (5K to 10K is the max).
 *
 * With all those considerations, we generate UI in the action page, to submit
 * a modified response back to the action page, and hopefully with the corrected
 * data the Action will be able to work.
 */

public void generateCollisionPage(Writer out, NGSection ngs, String val,
            String p, long startTime, AuthRequest ar)
    throws Exception
{
    String shortName = SectionUtil.cleanName(ngs.getLastModifyUser());
    SectionFormat justChecking = ngs.getFormat();
    if (!justChecking.getName().equals("Wiki Format"))
    {
        throw new Exception("Mid AirCollision display only works with wiki format, and it seems that we have hit this with some other format: "
            +justChecking.getName());
    }


    ar.write("<html>\n");
    ar.write("<body>\n");
    ar.write("<h1>Mid Air Edit Collision!</h1>");
    ar.write("<p>Some other user has edited and saved this section since you started editing. ");
    ar.write("Saving your changes might cause a loss of those edits. ");
    ar.write("Below is a edit box where you can merge your changes into the ");
    ar.write("current section value after the other person edits.");
    ar.write("Clicking (SAVE) below will cause the contents of the upper window, ");
    ar.write("including any modifications you make here, to be saved into the section of the page.");
    ar.write("Clicking (CANCEL) will leave the page as it currently is, ");
    ar.write("without any of your edits included.");
    ar.write("</p>\n");
    ar.write("<form action=\"EditAction.jsp\" method=\"post\">");
    ar.write("<input type=\"hidden\" name=\"p\" value=\"");
    ar.writeHtml(p);
    ar.write("\"/>\n");
    ar.write("<input type=\"submit\" name=\"action\" value=\"Save\"/>\n");
    ar.write("<input type=\"submit\" name=\"action\" value=\"Cancel\"/>\n");
    ar.write("<input type=\"hidden\" name=\"section\" value=\"");
    ar.writeHtml(ngs.getName());
    ar.write("\"/>\n");
    ar.write("<input type=\"hidden\" name=\"timestamp\" value=\"");
    ar.write(Long.toString(ngs.getLastModifyTime()));
    ar.write("\"/>\n");
    ar.write("<br/>\n");
    ar.write("<textarea name=\"val\" cols=\"80\" rows=\"20\">");
    ar.writeHtml(ngs.asText());
    ar.write("</textarea>\n");
    ar.write("<br/>\n");
    ar.write("</form>");
    ar.write("<p>Below you will find the edits that you just attempted to make");
    ar.write("to the section value.  Copy your changes from below, and merge ");
    ar.write("into the edit box above.  Whether you click (SAVE) or (CANCEL)");
    ar.write("the contents of the box below will be discarded.</p>\n");
    ar.write("<textarea name=\"valedited\" cols=\"80\" rows=\"20\">");
    ar.writeHtml(val);
    ar.write("</textarea>\n");
    ar.write("<p>Workspace: ");
    ar.writeHtml(p);
    ar.write("</p>\n<p>Section: ");
    ar.writeHtml(ngs.getName());
    ar.write("</p>\n<p>The version you edited had been previously saved ");
    SectionUtil.nicePrintTime(ar, startTime, ar.nowTime);
    ar.write("</p>\n<p>Recently saved by ");
    ar.writeHtml(shortName);
    ar.write(" ");
    SectionUtil.nicePrintTime(ar, ngs.getLastModifyTime(), ar.nowTime);
    ar.write("</p>\n");
    ar.write("</body>\n");
    ar.write("</html>\n");
}

%>
