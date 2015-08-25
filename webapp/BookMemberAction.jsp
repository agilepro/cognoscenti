<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" session="true"
%><%@page errorPage="error.jsp"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%>
<%
    //constructing the AuthRequest object should always be the first thing
    //that a page does, so that everything can be set up correctly.
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to modify account members.");

    UserProfile uProf = ar.getUserProfile();

    String b = ar.reqParam("b");
    String go = ar.defParam("go", null);
    String userid = ar.reqParam("userid");

    AddressListEntry userManipulated = new AddressListEntry(userid);
    boolean selfRegister = userManipulated.isSameAs(uProf);

    int level = defParamInt(ar, "level", -1);
    if (level<0 && level>4)
    {
        throw new Exception("RequestRoleAction requires a 'level' parameter with a value between 0 and 4");
    }


    NGBook ngb = ar.getCogInstance().getSiteByIdOrFail(b);
    int actorAccessLevel = 0;
    if (ngb.secondaryPermission(uProf))
    {
        actorAccessLevel = 4;
    }
    else if (ngb.primaryPermission(uProf))
    {
        actorAccessLevel = 2;
    }

    int userAccessLevel = 0;
    if (ngb.secondaryPermission(userManipulated))
    {
        userAccessLevel = 4;
    }
    else if (ngb.primaryPermission(userManipulated))
    {
        userAccessLevel = 2;
    }

    if (go==null)
    {
        go = "BookInfo.jsp?b="+URLEncoder.encode(b, "UTF-8");
    }

    List<AddressListEntry> book_members  = ngb.getPrimaryRole().getDirectPlayers();
    boolean noMembers = (book_members.size()==0);

    if (userAccessLevel == level)
    {
        // userManipulated is already at that level,
        // might be at that level because of the account, so
        response.sendRedirect(go);
        return;
    }

    if (selfRegister)
    {
        if (level < actorAccessLevel)
        {
    //you can always ask to go down in level
        }
        else if (level==1)
        {
    //you can always ask to be a prospective member
        }
        else if (level==2 && noMembers)
        {
    //you can become a member if there are no members in this book
        }
        else
        {
    throw new Exception("A user at level "+actorAccessLevel+" can not ask to become a level "+level);
        }
    }
    else
    {
        if (actorAccessLevel >= userAccessLevel && actorAccessLevel >= level)
        {
    //as long as your access level is higher than both the level you move
    //the user to, and the level that the use is now, then you are allowed
        }
        else if (actorAccessLevel < level)
        {
    throw new Exception("You can not move user "+userManipulated.getUniversalId()+"to level "+level+" because you are at level "+actorAccessLevel+" and that user is already at a higher level than that.");
        }
        else if (actorAccessLevel < userAccessLevel)
        {
    throw new Exception("You can not move user "+userManipulated.getUniversalId()+"to level "+level+" because you are at level "+actorAccessLevel+".  You must be at or above the level you are moving another user to.");
        }
        else
        {
    throw new Exception("You can not move user "+userManipulated.getUniversalId()+"to level "+level+" because you are at level "+actorAccessLevel);
        }
    }
    if (level==0)
    {
        ngb.getPrimaryRole().removePlayer(userManipulated);
    }
    else if (level==1)
    {
        throw new Exception("prospective memebers of book is not longer supported.");
    }
    else if (level==2)
    {
        ngb.getPrimaryRole().addPlayer(userManipulated);
    }
    else
    {
        throw new Exception("Can't set user to level "+level+" for an account because book only has level 0-2");
    }
    ngb.saveFile(ar, "Changing user "+userManipulated.getUniversalId()+" to "+level);
    response.sendRedirect(go);
%>
<%@ include file="functions.jsp"%>
