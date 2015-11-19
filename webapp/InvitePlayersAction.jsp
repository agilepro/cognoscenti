<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AddressListEntry"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.HistoryRecord"
%><%@page import="org.socialbiz.cog.NoteRecord"
%><%@page import="org.socialbiz.cog.LeafletResponseRecord"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.SectionForNotes"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UserManager"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.io.StringWriter"
%><%@page import="java.util.ArrayList"
%><%@page import="java.util.List"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't send email.");

    String go = ar.reqParam("go");
    String action = ar.reqParam("action");
    String p = ar.reqParam("p");

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Can not send email.");
    uProf = ar.getUserProfile();

    String r = ar.reqParam("r");
    NGRole ngr = ngp.getRole(r);
    if (ngr==null)
    {
        throw new Exception("Can not invite people, because the role '"+r+"' does not exist on the page '"+ngp.getFullName()+"'");
    }
    if (!ngr.isExpandedPlayer(uProf, ngp))
    {
        throw new Exception("Can not invite people to role '"+r+"', because you are not a member of that role");
    }


    if (action.equals("Send Mail"))
    {
        Vector sendTo = new Vector();

        //OK, done, so write history about it
//        HistoryRecord.createHistoryRecord(ngp,
//                leaflet.getId(), HistoryRecord.CONTEXT_TYPE_LEAFLET,
//                HistoryRecord.EVENT_EMAIL_SENT, ar, "sent an invite");
    }

    response.sendRedirect(go);

%>
<%!private String composeFromAddress(NGPage ngp, EmailSender es)
{
    StringBuffer sb = new StringBuffer();
    String baseName = ngp.getFullName();
    int last = baseName.length();
    for (int i=0; i<last; i++)
    {
        char ch = baseName.charAt(i);
        if ( (ch>='0' && ch<='9') || (ch>='A' && ch<='Z') || (ch>='a' && ch<='z') || (ch==' '))
        {
            sb.append(ch);
        }
    }
    String baseEmail = es.getProperty("mail.smtp.from", "xyz@example.com");

    //if there is angle brackets, take the quantity within the angle brackets
    int anglePos = baseEmail.indexOf("<");
    if (anglePos>=0)
    {
        baseEmail = baseEmail.substring(anglePos+1);
    }
    anglePos = baseEmail.indexOf(">");
    if (anglePos>=0)
    {
        baseEmail = baseEmail.substring(0, anglePos);
    }

    //now add email address in angle brackets
    sb.append(" <");
    sb.append(baseEmail);
    sb.append(">");
    return sb.toString();
}



public void appendUsersGGG(List<AddressListEntry> members, Vector collector)
    throws Exception
{
    for (AddressListEntry ale : members)
    {
        Enumeration e2 = collector.elements();
        boolean found = false;
        while (e2.hasMoreElements())
        {
            AddressListEntry coll = (AddressListEntry)e2.nextElement();
            if (coll.hasAnyId(ale.getUniversalId()))
            {
                found = true;
                break;
            }
        }
        if (!found)
        {
            collector.add(ale);
        }
    }
}%>
<%@ include file="functions.jsp"%>
