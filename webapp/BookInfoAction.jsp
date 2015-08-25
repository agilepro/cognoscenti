<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Must be logged in to change account info.");

    String b          = ar.reqParam("b");
    String styleSheet = ar.reqParam("styleSheet");
    String logo       = ar.reqParam("logo");
    String desc       = ar.defParam("desc", "");
    String bookname   = ar.reqParam("bookname");
    String go         = ar.reqParam("go");

    NGBook ngb = ar.getCogInstance().getSiteByIdOrFail(b);

    if (!ngb.primaryOrSecondaryPermission(new AddressListEntry(ar.getUserProfile())))
    {
        throw new Exception("Sorry, you need to be a member of an account, in order to change its settings");
    }
    ngb.setStyleSheet(styleSheet);
    ngb.setLogo(logo);
    ngb.setDescription(desc);
    ngb.saveFile(ar, "Site Info Action");
    response.sendRedirect(go);%>

<%@ include file="functions.jsp"%>
