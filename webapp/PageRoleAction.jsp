<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" session="true"
%><%@page errorPage="error.jsp"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.HistoryRecord"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="java.net.URLEncoder"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to modify roles.");
    String p  = ar.reqParam("p");   //page id
    String r  = ar.reqParam("r");   //role name
    String op = ar.reqParam("op");  //operation: add or remove
    String go = ar.reqParam("go");  //where to go afterwards

    NGContainer ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Unable to modify roles.");

    NGRole role = ngp.getRole(r);
    if (role==null)
    {
        if (op.equals("Create Role"))
        {
            String desc = ar.reqParam("desc");
            ngp.createRole(r,desc);
            ngp.saveContent(ar, "create new role "+r);
            response.sendRedirect(go);
            return;
        }

        throw new Exception("Can't find a role named '"+r+"' on the page '"+ngp.getFullName()+"'.");
    }



    boolean isPlayer = role.isExpandedPlayer(ar.getUserProfile(), ngp);
    if (!isPlayer)
    {
        ar.assertAdmin("You must be a page administrator to change role '"+r+"' when you are not a player of the role.");
    }

    String id = ar.reqParam("id");  //user being added/removed
    AddressListEntry ale =null;
    if(op.equals("Add Member")){

        String parseId=pasreFullname(id);
        ale= AddressListEntry.newEntryFromStorage(parseId);

    }else{
        ale = AddressListEntry.newEntryFromStorage(id);
    }

    int eventType = 0;
    String pageSaveComment = null;

    if (op.equals("Add"))
    {
        if (id.length()<5)
        {
            throw new Exception("Please check your action, the id ("+id+") is too small to be useful on this site");
        }
        eventType = HistoryRecord.EVENT_PLAYER_ADDED;
        pageSaveComment = "added user "+id+" to role "+r;
        role.addPlayer(ale);
    }
    else if (op.equals("Remove"))
    {
        eventType = HistoryRecord.EVENT_PLAYER_REMOVED;
        pageSaveComment = "removed user "+id+" from role "+r;
        role.removePlayer(ale);
    }
    else if (op.equals("Add Role"))
    {
        eventType = HistoryRecord.EVENT_ROLE_ADDED;
        pageSaveComment = "added new role "+r;
        ale.setRoleRef(true);
        role.addPlayer(ale);
    }
    else if (op.equals("Update Details"))
    {
        eventType = HistoryRecord.EVENT_ROLE_MODIFIED;
        pageSaveComment = "modified details of role "+r;
        String desc = ar.reqParam("desc");
        String reqs = ar.reqParam("reqs");
        role.setDescription(desc);
        role.setRequirements(reqs);
    }else if(op.equals("Add Member")){

        if (id.length()<5)
        {
            throw new Exception("Please check your action, the id ("+id+") is too small to be useful on this site");
        }

        List<AddressListEntry> emailList = AddressListEntry.parseEmailList(id);
        for (AddressListEntry addressListEntry : emailList) {
            role.addPlayerIfNotPresent(addressListEntry);
        }
        eventType = HistoryRecord.EVENT_PLAYER_ADDED;
        pageSaveComment = "added user "+id+" to role "+r;
    }
    else
    {
        throw new Exception("Don't understand the operation '"+op+"' with respect to roles.");
    }

    //make sure that the options above set the variables with the right values.
    if (eventType == 0 || pageSaveComment == null)
    {
        throw new Exception("Program Logic Error: variables have not been maintained properly.");
    }

    HistoryRecord.createHistoryRecord(ngp,id, HistoryRecord.CONTEXT_TYPE_ROLE,0,eventType, ar, "");
    ngp.saveContent(ar, "added user "+id+" to role "+r);
    response.sendRedirect(go);%>
<%@ include file="functions.jsp"%>
