<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NoteRecord"
%><%@page import="org.socialbiz.cog.LeafletResponseRecord"
%><%@page import="org.socialbiz.cog.HistoryRecord"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.SectionForNotes"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UserManager"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.io.StringWriter"
%><%AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to modify topics");

    String go = ar.reqParam("go");
    String action = ar.reqParam("action");
    String p = ar.reqParam("p");
    String lid = ar.reqParam("lid");
    String data = ar.defParam("data", null);
    String choice = ar.defParam("choice", null);
    String uid = ar.reqParam("uid");
    UserProfile designatedUser = UserManager.findUserByAnyId(uid);
    if (designatedUser==null)
    {
        //create a user profile for this user at this point because you have to have
        //a user profile in order to access the response record.
        designatedUser = UserManager.createUserWithId(uid);
        designatedUser.setLastUpdated(ar.nowTime);
        UserManager.writeUserProfilesToFile();
    }

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);

    NoteRecord leaflet = ngp.getNoteOrFail(lid);

    LeafletResponseRecord llr = leaflet.getOrCreateUserResponse(designatedUser);

    if (action.startsWith("Update"))
    {
        llr.setData(data);
        llr.setChoice(choice);
        llr.setLastEdited(ar.nowTime);
        ngp.saveFile(ar, "Updated response to topic");
    }

    response.sendRedirect(go);%>

<%@ include file="functions.jsp"%>
