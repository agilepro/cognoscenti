<%@page import="org.socialbiz.cog.NGRole"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.RoleRequestRecord"
%><%
    String property_msg_key = ar.reqParam("property_msg_key");

%>
    <div class="generalArea">
        <div class="generalContent">
            <img src="<%=ar.retPath %>assets/iconAlertBig.gif" title="Alert">&nbsp;&nbsp;
            <fmt:message key="<%=property_msg_key %>">
                <%if((ar.getBestUserId()!=null) && (ar.getBestUserId().length()>0)){ %>
                <fmt:param value='<%=ar.getBestUserId()%>' />
                <%} %>
            </fmt:message>
        </div>
    </div>
