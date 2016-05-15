<!DOCTYPE html>
<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ taglib uri="http://tiles.apache.org/tags-tiles" prefix="tiles"
%><%
    long renderStart = System.currentTimeMillis();
    UserProfile loggedUser = ar.getUserProfile();
    
    boolean weaverMenus = false;
    String loggedKey = "";
    if (ar.isLoggedIn()) {
        weaverMenus = loggedUser.getWeaverMenu();
        loggedKey = loggedUser.getKey();
    }
    

%>

<% if (weaverMenus) { %>
<%@ include file="WrapLayout2.jsp" %>
<% } else { %>
<%@ include file="WrapLayout1.jsp" %>
<% } %>

<!-- END Wrapper.jsp Layout - - <%= (System.currentTimeMillis()-renderStart) %> ms -->
