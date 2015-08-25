<%@page import="org.socialbiz.cog.RUElement"
%>


<div class="left" id="main_left">

    <div id="sidebar">

<% if (!ar.isStaticSite()) { %>


        <!-- SEARCH BOX -->
        <div class="box">
            <div class="box_title">Search</div>
            <div class="box_body">
                <div>
<%
    if (!ar.isLoggedIn()) {
%>
                    <p>Please <a href="<%=ar.retPath%>t/EmailLoginForm.htm?go=<%ar.writeURLData(ar.getCompleteURL());%>">log-in or
                       register</a> to search.</p>
<%
    } else if (ngb==null) {
%>
                    <p>Select an account to search.</p>
<%
    } else {
%>
                    <form method="get" id="searchform" action="<%=ar.retPath%>Search.jsp">
                        <input type="hidden" name="b"
                              value="<%ar.writeURLData(ngb.getKey());%>" />
                        <table class="search">
                            <tr>
                                <td><input type="text" name="qs" id="qs"/></td>
                                <td><input type="image" src="<%=ar.retPath%>button_go.gif" /></td>
                            </tr>
                        </table>
                    </form>
<%
    }
%>
                </div>
            </div>
            <div class="box_bottom"></div>
        </div>



        <div class="box">
            <div class="box_title">General Links</div>
            <div class="box_body">
                <ul>
                <%
                if (ar.isLoggedIn())
                {
                    UserProfile uProf = ar.getUserProfile();
                    uProf.writeLink(ar);
                    ar.write("<br/>- <a href=\"");
                    ar.write(ar.retPath);
                    ar.write("UserHome.jsp?u=");
                    ar.writeHtml(uProf.getKey());
                    ar.write("\" title=\"home for the logged in user\">My Home</a><br/>\n");
                    ar.write("- <a href=\"");
                    ar.write(ar.retPath);
                    ar.write("UserPages.jsp?u=");
                    ar.writeHtml(uProf.getKey());
                    ar.write("\" title=\"home for the logged in user\">My Projects</a><br/>\n");
                    ar.write("- <a href=\"");
                    ar.write(ar.retPath);
                    ar.write("UserProfile.jsp?u=");
                    ar.writeHtml(uProf.getKey());
                    ar.write("\" title=\"home for the logged in user\">My Settings</a><br/>\n");
                }
                if (ngb!=null)
                {
                    ar.write("<a href=\"");
                    ar.write(ar.retPath);
                    ar.write("BookPages.jsp?b=");
                    ar.writeURLData(ngb.getKey());
                    ar.write("\" title=\"view a list of projects in this site\">Site: ");
                    ar.writeHtml(ngb.getFullName());
                    ar.write("</a><br/>\n");

                }
                else
                {
                    ar.write("<a href=\"");
                    ar.write(ar.retPath);
                    ar.write("UserList.jsp\" title=\"view a list of all known users\">List All Users</a><br/>\n");
                }
                if (ngp != null)
                {
                    ar.write("<a href=\"");
                    ar.write(ar.retPath);
                    ar.write("HookLink.jsp?p=");
                    ar.writeURLData(ngp.getKey());
                    ar.write("&go=");
                    ar.writeURLData(ar.getCompleteURL());
                    ar.write("\" title=\"'REMEMBER' this page, and present it as the default in any link prompt\">Hook This Page</a><br/>\n");
                }
                else
                {
                    ar.write("<a href=\"");
                    ar.write(ar.retPath);
                    ar.write("list.jsp\" title=\"List all of the sites in this server\">List all Sites</a><br/>\n");
                }
                String newUISetting = ar.getSystemProperty("NewUI");
                boolean showNewUI = (newUISetting==null || !newUISetting.equals("hide"));
                if (showNewUI && ngb!=null && ngp!=null)
                {
                    ar.write("<a href=\"");
                    ar.write(ar.retPath);
                    ar.write("t/");
                    ar.writeURLData(ngb.getKey());
                    ar.write("/");
                    ar.writeURLData(ngp.getKey());
                    ar.write("/");
                    ar.write(newUIResource);
                    ar.write("\" title=\"Go to standard UI for ");
                    ar.write(newUIResource);
                    ar.write("\">New UI</a><br/>\n");
                }
                %>

                </ul>
            </div>
            <div class="box_bottom"></div>
        </div>


<% if (ngp != null) { %>
        <div class="box">
            <div class="box_title">Hooked Project <a href="<%
                    ar.write(ar.retPath);
                    ar.write("HookLink.jsp?p=");
                    ar.writeURLData(ngp.getKey());
                    ar.write("&go=");
                    ar.writeURLData(ar.getCompleteURL());
                    %>" title="'REMEMBER' this page, and present it as the default in any link prompt">(set)</a></div>
            <div class="box_body">
                <ul>
<%
        String hookedLink = (String) session.getAttribute("hook");
        if (hookedLink!=null)
        {
            NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(hookedLink);
            if (ngpi!=null)
            {
                ngpi.writeTruncatedLink(ar, 20);
                ar.write("<br/>\n");
            }
            else
            {
                ar.write("Can't find '"+hookedLink+"'");
            }
        }
%>
                </ul>
            </div>
            <div class="box_bottom"></div>
        </div>
<% } %>


        <div class="box">
            <div class="box_title">Recently Visited Leaves</div>
            <div class="box_body">
                <ul>
<%
NGSession ngsession = ar.ngsession;
if (ngsession!=null)
{
    Vector<RUElement> recent = ngsession.recentlyVisited;
    RUElement.sortByDisplayName(recent);
    for(RUElement rue : recent)
    {
        NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(rue.key);
        if (ngpi!=null)
        {
            ngpi.writeTruncatedLink(ar, 20);
            ar.write("<br/>\n");
        }
    }
}
%>
                </ul>
            </div>
            <div class="box_bottom"></div>
        </div>


        <div class="box">
            <div class="box_title">Favorites</div>
            <div class="box_body">
                <ul>
                <%
                    ar.write("<li>");
                    ar.write("<a href=\"");
                    ar.write(ar.retPath);
                    ar.write("\">Main</a>\n");
                    ar.write("</li>");

                    // write out all the user favourites.
                    org.socialbiz.cog.UserProfile up =  ar.getUserProfile();
                    if (up != null)
                    {
                        org.socialbiz.cog.ValueElement[] favorites = up.getFavorites();

                        for (int i=0; i<favorites.length; i++)
                        {
                            ar.write("<li>");
                            ar.write("<a href=\"");
                            if (favorites[i].value.toUpperCase().startsWith("HTTP://") == false)
                            {
                                ar.write(ar.retPath);
                            }
                            ar.writeHtml(favorites[i].value);
                            ar.write("\" title=\"Navigate to favorite\">");
                            ar.writeHtml(favorites[i].name);
                            ar.write("</a>\n");
                            ar.write("</li>");
                        }
                    }
                %>
                </ul>
            </div>
            <div class="box_bottom"></div>

        </div>
<% }  /*static site*/ %>

<%

// To This Project & From This Project should be displayed only when displaying the page.
if (ngp != null)
{
%>
    <div class="box">
        <div class="box_title">To This Project</div>
        <div class="box_body">
            <ul>
<%
    NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(ngp.getKey());

    if (ngpi!=null)
    {
        Enumeration en = ngpi.getInLinkPages().elements();
        while (en.hasMoreElements())
        {
            NGPageIndex refB = (NGPageIndex) en.nextElement();
            refB.writeTruncatedLink(ar, 20);
            ar.write("\n<br/>\n");
        }
    }
%>
            </ul>
        </div>
        <div class="box_bottom"></div>
    </div>

    <div class="box">
        <div class="box_title">From This Project</div>
        <div class="box_body">
            <ul>
<%
    if (ngpi!=null)
    {
        Enumeration en = ngpi.getOutLinkPages().elements();
        while (en.hasMoreElements())
        {
            NGPageIndex refB = (NGPageIndex) en.nextElement();
            refB.writeTruncatedLink(ar, 20);
            ar.write("\n<br/>\n");
        }
    }
%>
            </ul>
        </div>
        <div class="box_bottom"></div>
    </div>
<%
} // To This Page & From This Page should be displayed only when displaying the page.
%>


<%

// tatic site gets a special box explaining that it is frozen
if (ar.isStaticSite())
{
%>
    <div class="box">
        <div class="box_title">Static Site</div>
        <div class="box_body">
            <ul>
            You are viewing a static copy of
            a project that was originally a wiki.
            These pages can not be modified
            at this location even though the page
            may appear incomplete.
            This copy was generated on
            <% SectionUtil.nicePrintDate(ar.w, System.currentTimeMillis()); %>
            and this project information has not been
            changed since <% SectionUtil.nicePrintDate(ar.w, ngp.getLastModifyTime()); %>.
            </ul>
        </div>
        <div class="box_bottom"></div>
    </div>
<%
} // Static Site notice
%>


        </div>
    </div>


