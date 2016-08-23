<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.DOMFace"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionForNotes"
%><%@page import="org.socialbiz.cog.TopicRecord"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to modify comments.");

    String p = ar.reqParam("p");
    String section = ar.reqParam("section");
    String action = ar.reqParam("action");
    String choices = ar.defParam("choices", null);

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Must be a member of the project in order to create or modify topics.");

    //editor was popped up in a separate window, so this is a dead end.
    String go = ar.retPath+"closeWindow.htm";

    //cancel can be pressed without satisfying any other constraints
    //about editing.  Get them back to the page.
    if (action.startsWith("Close"))
    {
        response.sendRedirect(go);
        return;
    }

    String subject = ar.defParam("subj", "");
    String val     = ar.defParam("val",  "");
    int visibility = DOMFace.safeConvertInt(ar.reqParam("visibility"));

    String oid = ar.reqParam("oid");

    if ("Save and Continue Editing".equals(action))
    {
        TopicRecord cr = null;
        if ("Create".equals(oid))
        {
            cr = ngp.createNote();
        }
        else
        {
            cr = ngp.getNoteOrFail(oid);
        }
        cr.setSubject(subject);
        cr.setWiki(val);
        cr.setVisibility(visibility);
        cr.setEffectiveDate(SectionUtil.niceParseDate(ar.defParam("effDate", "")));
        cr.setPinOrder(DOMFace.safeConvertInt(ar.defParam("pin", "0")));
        cr.setChoices(choices);
        go = ar.retPath + "EditLeaflet.jsp?p="
            + SectionUtil.encodeURLData(ngp.getKey())
            + "&oid="
            + SectionUtil.encodeURLData(cr.getId())
            + "&action=Edit";
    }
    else if ("Remove".equals(action))
    {
        ngp.deleteNote(oid,ar);
    }
    else
    {
        throw new Exception("Don't understand that action: "+action);
    }

    ngp.saveFile(ar, "modified section "+section);

    response.sendRedirect(go);%>
<%@ include file="functions.jsp"%>
