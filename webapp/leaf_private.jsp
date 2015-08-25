<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.NGSession"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UserPage"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%><%ar = AuthRequest.getOrCreate(request, response, out);
    ar.retPath="../../";

    /* if the parameter is not found in the parameters list, then find it out in the attributes list */
    String p = ar.reqParam("p");

    uProf = ar.getUserProfile();
    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    boolean isMember = ar.isMember();
    boolean isAdmin = ar.isAdmin();

    ngb = ngp.getSite();
    pageTitle = ngp.getFullName();
    specialTab = "Subscriptions";
    newUIResource = "personal.htm";%>

<%@ include file="Header.jsp"%>
<%
    headlinePath(ar, "Private Section");
    if (!ar.isLoggedIn())
    {
        mustBeLoggedInMessage(ar);
    }
    else
    {
        %><div class="pagenavigation">
            <div class="pagenav">
                <div class="left">
                The settings on this page are exclusively for
                the user '<% uProf.writeLink(ar); %>'.
                <br/>
         <%
            String pageKey = ngp.getKey();
            long pageChangeTime = ngp.getLastModifyTime();
            UserProfile up = ar.getUserProfile();

            long subTime = uProf.watchTime(pageKey);
            boolean found = subTime!=0;
            String thisPage = ar.getResourceURL(ngp,"private.htm");

            NGRole memberRole = ngp.getRoleOrFail("Members");
            NGRole adminRole = ngp.getRoleOrFail("Administrators");
            NGRole execRole = ngb.getRoleOrFail("Executives");

            %><br/><h3>Membership</h3><%
            if (memberRole.isExpandedPlayer(up, ngp))
            {
                %>You are listed as a member of this project.
                <form action="<%=ar.retPath%>RoleAction.jsp" method="post">
                <input type="hidden" name="p" value="<%ar.writeHtml(pageKey);%>">
                <input type="hidden" name="go" value="<%ar.writeHtml(thisPage);%>">
                <input type="hidden" name="r" value="Members">
                <input type="hidden" name="u" value="<%ar.writeHtml(uProf.getUniversalId());%>">
                <input type="hidden" name="op" value="remove">
                <input type="Submit" name="action" value="Stop Membership">
                </form><%
            }
            else
            {
                %>You are not listed as a member of this project. <%
                if (adminRole.isExpandedPlayer(up, ngp))
                {
                    %>However, you can do everything a member can do because you are an Administrator of the project<%
                    if (execRole.isExpandedPlayer(up, ngp))
                    {
                        %> and you are an Executive for all projects in the account<%
                    }
                    %>.<%
                }
                else if (execRole.isExpandedPlayer(up, ngp))
                {
                    %>However, you can do everything a member can do because you are an Executive for all projects in this account.<%
                }
                %>
                <form action="<%=ar.retPath%>RoleAction.jsp" method="post">
                <input type="hidden" name="p" value="<%ar.writeHtml(pageKey);%>">
                <input type="hidden" name="go" value="<%ar.writeHtml(thisPage);%>">
                <input type="hidden" name="r" value="Members">
                <input type="hidden" name="u" value="<%ar.writeHtml(uProf.getUniversalId());%>">
                <input type="hidden" name="op" value="add">
                <input type="Submit" name="action" value="Request Membership">
                </form><%
            }


            NGRole notifyRole = ngp.getRole("Notify");
            if (notifyRole==null)
            {
                throw new Exception("Program logic error: Notify role was not initialized by NGPage object");
            }


            %><br/><h3>Notifications</h3><%
            if (notifyRole.isExpandedPlayer(up, ngp))
            {
                %>You will receive notifications when this project is changed in any way.
                <form action="<%=ar.retPath%>RoleAction.jsp" method="post">
                <input type="hidden" name="p" value="<%ar.writeHtml(pageKey);%>">
                <input type="hidden" name="go" value="<%ar.writeHtml(thisPage);%>">
                <input type="hidden" name="r" value="Notify">
                <input type="hidden" name="u" value="<%ar.writeHtml(uProf.getUniversalId());%>">
                <input type="hidden" name="op" value="remove">
                <input type="Submit" name="action" value="Stop Receiving Notifications">
                </form><%
            }
            else
            {
                %>You are not receiving change notifications for this project.
                <form action="<%=ar.retPath%>RoleAction.jsp" method="post">
                <input type="hidden" name="p" value="<%ar.writeHtml(pageKey);%>">
                <input type="hidden" name="go" value="<%ar.writeHtml(thisPage);%>">
                <input type="hidden" name="r" value="Notify">
                <input type="hidden" name="u" value="<%ar.writeHtml(uProf.getUniversalId());%>">
                <input type="hidden" name="op" value="add">
                <input type="Submit" name="action" value="Start Receiving Notifications">
                </form><%
            }


            %><br/><br/><h3>Watching this Project</h3><%


            if (subTime>pageChangeTime)
            {
         %>
                You are watching this page, and it has not changed since you saw it
                <%SectionUtil.nicePrintTime(ar, subTime, ar.nowTime);%>
                Would you like to
                <form action="<%=ar.retPath%>WatchAction.jsp" method="post">
                <input type="hidden" name="p" value="<%ar.writeHtml(pageKey);%>">
                <input type="hidden" name="go" value="<%ar.writeHtml(thisPage);%>">
                <input type="Submit" name="action" value="Stop Watching">
                </form>
         <%  } else if (subTime>0){ %>
                You are watching this page, and it has changed since you saw it
                <%SectionUtil.nicePrintTime(ar, subTime, ar.nowTime);%>
                Would you like to
                <form action="<%=ar.retPath%>WatchAction.jsp" method="post">
                <input type="hidden" name="p" value="<%ar.writeHtml(pageKey);%>">
                <input type="hidden" name="go" value="<%ar.writeHtml(thisPage);%>">
                <input type="Submit" name="action" value="Reset Watch Time">
                <input type="Submit" name="action" value="Stop Watching">
                </form>
         <%  } else { %>
                You are not watching this page. Would you like to
                <form action="<%=ar.retPath%>WatchAction.jsp" method="post">
                <input type="hidden" name="p" value="<%ar.writeHtml(pageKey);%>">
                <input type="hidden" name="go" value="<%ar.writeHtml(thisPage);%>">
                <input type="Submit" name="action" value="Start Watching">
                </form>
         <%  }


            UserPage uPage = ar.getUserPage();
            boolean isAlreadyTemplate = uPage.inProjectTemplates(pageKey);
            %><br/><br/><h3>Templates</h3><%

            if (isAlreadyTemplate)
            {
                %>
                This project is one of your templates.
                <form action="<%=ar.retPath%>TemplateAction.jsp" method="post">
                <input type="hidden" name="p" value="<%ar.writeHtml(pageKey);%>">
                <input type="hidden" name="go" value="<%ar.writeHtml(thisPage);%>">
                <input type="Submit" name="action" value="Remove from Templates">
                </form>
                <%
            }
            else
            {
                %>
                This Project is not one of your templates.
                <form action="<%=ar.retPath%>TemplateAction.jsp" method="post">
                <input type="hidden" name="p" value="<%ar.writeHtml(pageKey);%>">
                <input type="hidden" name="go" value="<%ar.writeHtml(thisPage);%>">
                <input type="Submit" name="action" value="Add to Templates">
                </form>
                <%
            }

        %>
                </div>
                <div class="right"></div>
                <div class="clearer">&nbsp;</div>
            </div>
            <div class="pagenav_bottom"></div>
        </div>
        <%

        if (!ar.isStaticSite())
        {
        %>
          <form action="<%= ar.retPath %>EditLeaflet.jsp" method="get" target="_blank">
          <input type="hidden" name="p" value="<% ar.writeHtml(p); %>">
          <input type="hidden" name="viz" value="4">
          <input type="hidden" name="go" value="<% ar.writeHtml(ar.getCompleteURL()); %>">
          <input type="submit" value="Create New Private Note">
          </form>
        <%
        }
        writeLeaflets(ngp, ar, 4);
    }

    out.flush();

%>


<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
