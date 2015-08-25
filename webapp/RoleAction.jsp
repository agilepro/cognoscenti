<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" session="true"
%><%@page errorPage="error.jsp"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.HistoryRecord"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="java.net.URLEncoder"
%><%//This can be used by people who are already a player of the role,
    //to allow others to become players as well, or to remove them from the role
    //This allows a person who is a player to remove themselves.

    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to modify roles.");
    String p  = ar.reqParam("p");   //container key
    String r  = ar.reqParam("r");   //role name
    String u  = ar.reqParam("u");   //user to manipulate
    String op = ar.reqParam("op");  //operation: 'add' or 'remove'
    String go = ar.reqParam("go");  //where to go afterwards

    NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKeyOrFail(p)
    NGContainer ngc = ngpi.getContainer();

    NGRole role = ngc.getRoleOrFail(r);
    NGRole adminRole = ngc.getRoleOrFail("Administrators");


    UserProfile loggedInUser = ar.getUserProfile();

    //In general, if you are not a player of the role, you can not add yourself
    //or anyone to the role.  The exception is for the role Notify
    //which everyone is allowed to add themselves to

    boolean isPlayer = role.isExpandedPlayer(ar.getUserProfile(), ngc);
    boolean isAdmin  = adminRole.isExpandedPlayer(ar.getUserProfile(), ngc);
    if (!isPlayer && !isAdmin && !"Notify".equals(r))
    {
        String rrurl = ar.retPath + "RoleRequest.jsp"
            + "?p="+ URLEncoder.encode(p, "UTF-8")
            + "&r="+ URLEncoder.encode(r, "UTF-8");
        response.sendRedirect(rrurl);
        return;
    }

    if (u.length()<5)
    {
        throw new Exception("Please check your action, the id ("+u+") is too small to be useful on this site");
    }
    AddressListEntry ale = AddressListEntry.newEntryFromStorage(u);
    String descript;
    int historyAction = HistoryRecord.EVENT_LEVEL_CHANGE;

    if (op.equals("add"))
    {
        if (role.isPlayer(ale))
        {
            //already a player, avoid adding duplicate entries, or synonyms, and avoid
            //unnecessary page update, so silently ignore the request, and go
            //back to wherever the page is directing.
            response.sendRedirect(go);
            return;
        }
        historyAction = HistoryRecord.EVENT_PLAYER_ADDED;
        role.addPlayer(ale);
        descript = "added user "+u+" to role "+r;
    }
    else if (op.equals("remove"))
    {
        if (!role.isPlayer(ale))
        {
            //not a player, avoid unnecessary page update,
            //so silently ignore the request, and go
            //back to wherever the page is directing.
            response.sendRedirect(go);
            return;
        }
        historyAction = HistoryRecord.EVENT_PLAYER_REMOVED;
        role.removePlayer(ale);
        descript = "removed user "+u+" from role "+r;
    }
    else
    {
        throw new Exception("Don't understand the operation '"+op+"' with respect to roles.");
    }

    if (ngc instanceof NGPage)
    {
        ngp = (NGPage)ngc;
        HistoryRecord.createHistoryRecord(ngp,
                u, HistoryRecord.CONTEXT_TYPE_ROLE,
                historyAction, ar, descript);
        ngp.saveFile(ar, descript);
    }
    else
    {
        throw new Exception("RoleAction needs to be taught how to save role changes on other containers");
    }
    response.sendRedirect(go);%>
<%@ include file="functions.jsp"%>
