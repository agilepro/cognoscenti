<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="include.jsp"
%><%

    ar.assertLoggedIn("Must be logged in to see anything about a meeting");

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();

%>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Roles of Project
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="EditRole.htm?roleName=~new~">Create New Role</a></li>
            </ul>
          </span>

        </div>
    </div>


        <div class="generalContent">
            <table width="100%">
                <%
                    writeAllRolesOnPage(ar, ngp);
                %>
            </table>
        </div>

        <div style="height:50px;"></div>

        <div class="generalSettings"><a name="inheritedRoles"></a>
            <table width="100%">
                <tr>
                    <td class="pageHeading">Roles inherited from Site '<%
                        ar.writeHtml(ngp.getSite().getFullName());
                    %>'</td>
                </tr>
                <tr><td style="height:5px;"></td></tr>
                <tr><td class="horizontalSeperatorBlue"></td></tr>
            </table>
            <table width="100%">
                <%
                   writeAllRolesFromAccount(ar, ngb,ngp);
                %>
            </table>
        </div>


</div>

<%!

    public void writeAllRolesOnPage(AuthRequest ar, NGPage ngp) throws Exception
    {
        for (NGRole aRole : ngp.getAllRoles())
        {
            List<AddressListEntry> allUsersRole = aRole.getDirectPlayers();

            ar.write("<tr>");
            ar.write("<td valign=\"top\" class=\"columnRole\" width=\"40%\">");

            ar.write("<br/><div ><a href=\"EditRole.htm?roleName=" );
            ar.writeURLData(aRole.getName());
            ar.write("\" title+\"click to edit\"><button class=\"btn btn-sm\" style=\"color:black;background-color:");
            ar.writeHtml(aRole.getColor());
            ar.write(";\">");
            ar.writeHtml(aRole.getName());
            ar.write("</button></a></div>\n<div><br/>");

            ar.writeHtml(aRole.getDescription());
            ar.write("</div><br/><div>");
            ar.writeHtml(aRole.getRequirements());
            ar.write("</div></td>");

            ar.write("<td valign=\"top\" width=\"60%\">");
            ar.write("<table class=\"gridTable3\" width=\"100%\">");
            ar.write("<tr><th colspan=\"3\">");
            ar.write("</th></tr>");

            for (AddressListEntry ale : allUsersRole)
            {
                if(!ale.isRoleRef())
                {
                    String nameToRemove = ale.getStorageRepresentation();
                    UserProfile uProf = ale.getUserProfile();
                    if (uProf!=null) {
                        nameToRemove = aRole.whichIDForUser(uProf);
                    }
                    ar.write("<tr><th width=\"40%\">");
                    ale.writeLink(ar);
                    ar.write("</th><td width=\"58%\">");
                    ar.writeHtml(ale.getEmail());
                    ar.write("</td></tr>");

                }
            }

            for (AddressListEntry ale : allUsersRole)
            {
                 if(ale.isRoleRef()){

                    ar.write("<tr><td colspan=\"3\" class=\"noBorder\"><table width=\"100%\"><tr><th colspan=\"3\">");
                    ar.write("<b>Role: <a href=\"#");
                    ar.writeHtml(ale.getInitialId());
                    ar.write("\">");
                    ar.writeHtml(ale.getInitialId());
                    ar.write("</a></b>");
                    ar.write("</th></tr></table></td></tr>");
                }
            }

            ar.write("<tr><td colspan=\"3\" class=\"noBorder\">");
            ar.write("</td></tr>");
            ar.write("</table>");
            ar.write("</tr>");
            ar.write("<tr><td colspan=\"2\" class=\"horizontalSeperatorBlue\"></td></tr>");
        }
    }


    public void writeAllRolesFromAccount(AuthRequest ar, NGBook ngb, NGPage ngp) throws Exception
    {
        for (NGRole aRole : ngb.getAllRoles())
        {
            ar.write("<tr>");
            ar.write("<td valign=\"top\" class=\"columnRole\" width=\"40%\">");


            ar.write("<br/><div ><button class=\"btn btn-sm\" style=\"background-color:");
            ar.writeHtml(aRole.getColor());
            ar.write(";\">");
            ar.writeHtml(aRole.getName());
            ar.write("</button>");
            ar.write("</div><br/>");

            ar.writeHtml(aRole.getDescription());
            ar.write("<br /><br />");
            ar.write("<b>Eligibility:</b><br />");
            ar.writeHtml(aRole.getRequirements());
            ar.write("<br /><br />");
            ar.write("</td>");
            ar.write("<td valign=\"top\" width=\"60%\">");
            ar.write("<table class=\"gridTable3\" width=\"100%\">");
            ar.write("<tr><th colspan=\"3\">");
            ar.write("</th></tr>");

            List <AddressListEntry> allUsers = aRole.getExpandedPlayers(ngp);
            for (AddressListEntry ale : allUsers)
            {
                ar.write("<tr><th width=\"40%\">");
                ale.writeLink(ar);
                ar.write("</th><td width=\"58%\">");
                ar.writeHtml(ale.getEmail());
                ar.write("</td></tr>");
            }
            ar.write("<tr><td colspan=\"3\" class=\"noBorder\">");
            ar.write("</td></tr>");
            ar.write("</table>");
            ar.write("</tr>");
            ar.write("<tr><td colspan=\"2\" class=\"horizontalSeperatorBlue\"></td></tr>");
        }
    }
%>
