<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UserManager"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.WatchRecord"
%><%@page import="org.socialbiz.cog.IDRecord"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Must be logged in to display diagnostic information.");
    if (!ar.isSuperAdmin())
    {
        throw new Exception("Must be system administrator in to display diagnostic information.");
    }

    String id = ar.defParam("id", "");

%>

<%@ include file="Header.jsp"%>

    <form action="MagicNumber.jsp">
    Email: <input type="text" name="id" value=<%ar.writeHtml(id);%>><br>
    <input type="submit" value="Test">
    </form>
    <hr/>
    <ul>
<%

    try
    {
        if (id.length()>0)
        {
            for (NGPageIndex ngpi : ar.getCogInstance().getAllContainers())
            {
                if (!ngpi.isProject()) {
                    continue;
                }
                NGContainer ngc = (NGContainer) ngpi.getContainer();
                if (!(ngc instanceof NGPage))
                {
                    continue;
                }
                NGPage ngp = (NGPage) ngc;
                String mn = ngp.emailDependentMagicNumber(id);

                ar.write("<li>");
                ar.writeHtml(mn);
                ar.write(" for ");
                ar.writeHtml(ngp.getFullName());
                ar.write("</li>");
            }
        }
    }
    catch (Exception e)
    {
        ar.writeHtml(e.toString());
    }

%>
    </ul>
<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>

