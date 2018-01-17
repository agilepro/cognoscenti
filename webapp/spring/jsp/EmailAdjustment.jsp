<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.NGRole"
%><%
/*
Required parameters:

    1. pageId    : This is the id of a Workspace.
    2. siteId    : This is the id of a Site.
    3. role : the name of the role
    4. email: the email address that was sent the email, and received it.  This is the email address
              that the owner owns.
    5. mn   : magic number proving that this really came from an email message

Optional Parameters:

*/

    String role = ar.reqParam("role");
    String email = ar.reqParam("email");
    String mn = ar.reqParam("mn");

%><%!String pageTitle="";%>
<%
    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKey(siteId,pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    pageTitle  ="Adjust Email Subscriptions";
    UserProfile uProf = ar.getUserProfile();
    NGRole specRole = ngp.getRoleOrFail(role);

    String expectedMn = ngp.emailDependentMagicNumber(email);
    if (!expectedMn.equals(mn)) {
        throw new Exception("Something is wrong, improper request for email address "+email);
    }

    String loginUrl = ar.retPath+"";

%>

<!--  here is where the content goes -->
<body>
    <div class="generalArea">
        <div class="generalContent">
            <form name="emailForm" id="emailForm" action="<%=ar.retPath%>t/EmailAdjustmentAction.form" method="post">
                <input type="hidden" name="p"       value="<%ar.writeHtml(pageId);%>"/>
                <input type="hidden" name="role"    value="<%ar.writeHtml(role);%>"/>
                <input type="hidden" name="email"   value="<%ar.writeHtml(email);%>"/>
                <input type="hidden" name="mn"      value="<%ar.writeHtml(mn);%>"/>
                <table cellpadding="0" cellspacing="0" width="600">
                    <tr><td style="height:20px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td>An email message was sent to <%ar.writeHtml(email);%>.
                            This page will help you control how you receive such
                            messages in the future.</td>
                        </td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader">Reason:</td>
                        <td style="width:20px;"></td>
                        <td>You are a member of a role named
                            '<b><%ar.writeHtml(specRole.getName());%></b>'
                            in a workspace named '<b><%ar.writeHtml(ngp.getFullName());%></b>'.
                        </td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader" valign="top">Opt Out:</td>
                        <td style="width:20px;"></td>
                        <td><input type="submit" name="cmd" id="cmd" value="Remove Me"    class="btn btn-primary btn-raised" />
                        Removes you from the role, and you will no longer get email messages sent to
                            '<%ar.writeHtml(specRole.getName());%>' in a workspace '<%ar.writeHtml(ngp.getFullName());%>'.</td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
    <% if (!ar.isLoggedIn())  { %>
                    <tr>
                        <td class="gridTableColummHeader" valign="top"></td>
                        <td style="width:20px;"></td>
                        <td>Note: if you <a href="<%=ar.getSystemProperty("identityProvider")+"?openid.mode=quick&go="+URLEncoder.encode(ar.getCompleteURL(), "UTF-8")%>">
                        login </a> you will have more options.</td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
    <% } else { %>
                    <tr>
                        <td class="gridTableColummHeader" valign="top"></td>
                        <td style="width:20px;"></td>
                        <td><ul><li><a href="<%=ar.retPath%><%=ar.getResourceURL(ngp, "roleManagement.htm")%>" class="btn btn-default btn-raised">Add/Remove others from this role</a></li>
                            <li><a href="<%=ar.retPath%>v/<%=ar.getUserProfile().getKey()%>/notificationSettings.htm" class="btn btn-default btn-raised">Visit your subscriptions page.</a></li></ul></td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
    <% } %>
                    <tr>
                        <td class="gridTableColummHeader" valign="top">Role:</td>
                        <td style="width:20px;"></td>
                        <td valign="top"><b><%ar.writeHtml(specRole.getName());%></b> - <%ar.writeHtml(specRole.getDescription());%></td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader" valign="top">Workspace:</td>
                        <td style="width:20px;"></td>
                        <td valign="top"><%ngp.writeContainerLink(ar, 60);%></td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader" valign="top">Workspace Owners:</td>
                        <td style="width:20px;"></td>
                        <td valign="top"><% for (AddressListEntry owner : ngp.getSecondaryRole().getExpandedPlayers(ngp)){
                                owner.writeLink(ar);
                                ar.write("<br/>");
                            }
                            %></td>
                    </tr>
                </table>
            </form>
        </div>
