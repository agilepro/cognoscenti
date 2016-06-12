<!DOCTYPE html>
<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ taglib uri="http://tiles.apache.org/tags-tiles" prefix="tiles"
%><%
    long renderStart = System.currentTimeMillis();
    UserProfile loggedUser = ar.getUserProfile();
    
    String loggedKey = "";
    if (ar.isLoggedIn()) {
        loggedKey = loggedUser.getKey();
    }
    

%>

<%@ include file="WrapLayout2.jsp" %>

<!-- END Wrapper.jsp Layout - - <%= (System.currentTimeMillis()-renderStart) %> ms -->
