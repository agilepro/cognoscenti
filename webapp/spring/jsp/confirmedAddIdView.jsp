<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%
/*
Required parameter:

    1. addedEmailId     : This is email id being added to user's profile.
*/

    String addedEmailId = ar.reqParam("addedEmailId");
%>
<%!
    String pageTitle="";
%>
<%
    UserProfile uProf = ar.getUserProfile();
%>

<div>
    <div class="pageHeading">
        <fmt:message key="nugen.userprofile.confirmation.of.added.email.id" />
    </div>
    <div class="pageSubHeading">
    </div>
    <div class="generalSettings">
            <table width="80%" class="gridTable">
                <tr>
                    <td style="height:20px; font-size: 13px">
                        <%ar.writeHtmlMessage("nugen.userprofile.email.id.added.msg", new Object[]{addedEmailId} ); %>
                    </td>
                </tr>
            </table>
    </div>
</div>
