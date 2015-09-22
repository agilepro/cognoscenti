<%@page import="org.socialbiz.cog.rest.NGLeafServlet"
%>
<!-- BEGINNING OF THE ngTop SECTION -->


        <a name="Top" href="#"></a>
        <div id="layout_wrapper">
        <div id="layout_edgetop"></div>

        <div id="layout_container">

            <div id="site_title">
                <span class="page_title left">{{pageTitle}}</span>
                <h2 class="right"><%
                    if (ngb!=null && ngp!=null && !ar.isStaticSite())
                    {
                        ar.write("<a href=\"");
                        ar.write(getNewURL(ar, newUIResource));
                        ar.write("\"><img src=\"");
                        ar.write(ar.retPath);
                        ar.write("newui.gif\"/></a>");
                    }
                    else if (uProf!=null) {
                        ar.write("<a href=\"");
                        ar.write(ar.retPath);
                        ar.write("v/");
                        ar.write(uProf.getKey());
                        ar.write("/userSettings.htm\"><img src=\"");
                        ar.write(ar.retPath);
                        ar.write("newui.gif\"/></a>");
                    }
                    %></h2>
                <div class="clearer">&nbsp;</div>
            </div>
            <div id="top_separator"></div>

            <div id="navigation">

                <div id="tabs">
                    <ul>
                        <%
                        boolean showLiveOnly = (!ar.isStaticSite());
                        if (ngp != null)
                        {
                            makeTab(ar, ar.getResourceURL(ngp,"history.htm"),    "Stream");
                            makeTab(ar, ar.getResourceURL(ngp,"public.htm"),     "Public Topics");
                            if (showLiveOnly) {
                                makeTab(ar, ar.getResourceURL(ngp,"member.htm"),     "Member Topics");
                                makeTab(ar, ar.getResourceURL(ngp,"admin.htm"),      "Admin");
                                makeTab(ar, ar.getResourceURL(ngp,"permission.htm"), "Permissions");
                            }
                            makeTab(ar, ar.getResourceURL(ngp,"attach.htm"),     "Documents");
                            makeTab(ar, ar.getResourceURL(ngp,"process.htm"),    "Process");
                            if (showLiveOnly) {
                                makeTab(ar, ar.getResourceURL(ngp,"status.htm"),     "Status");
                                makeTab(ar, ar.getResourceURL(ngp,"private.htm"),    "Subscriptions");
                                makeTab(ar, ar.getResourceURL(ngp,"move.htm"),       "Move");
                            }
                        }
                        else if (ngb!=null)
                        {
                            makeTab(ar, "BookPages.jsp?b="+URLEncoder.encode(ngb.getKey(), "UTF-8"),
                                        "Site Projects");
                            makeTab(ar, "BookInfo.jsp?b="+URLEncoder.encode(ngb.getKey(), "UTF-8"),
                                        "Site Info");
                        }
                        else if (uProf!=null)
                        {
                            makeTab(ar, "UserHome.jsp?u="+URLEncoder.encode(uProf.getKey(), "UTF-8"),
                                        "Home");
                            makeTab(ar, "UserAlerts.jsp?u="+URLEncoder.encode(uProf.getKey(), "UTF-8"),
                                        "Alerts");
                            makeTab(ar, "StatusReport.jsp?u="+URLEncoder.encode(uProf.getKey(), "UTF-8"),
                                        "Status Report");
                            makeTab(ar, "PStatus1.jsp?u="+URLEncoder.encode(uProf.getKey(), "UTF-8"),
                                        "Multi-Status");
                            makeTab(ar, "ManageTasks.jsp?u="+URLEncoder.encode(uProf.getKey(), "UTF-8"),
                                        "Manage Tasks");
                            makeTab(ar, "UserPages.jsp?u="+URLEncoder.encode(uProf.getKey(), "UTF-8"),
                                        "My Projects");
                            makeTab(ar, "UserProfile.jsp?u="+URLEncoder.encode(uProf.getKey(), "UTF-8"),
                                        "Settings");
                        }
                        else
                        {
                            //i guess no tabs then
                        }
                         %>

                       </ul>
                    <div class="clearer">&nbsp;</div>
                </div>

            </div>

            <div style="height: 5px;"></div>

            <div id="main">

                <div class="right" id="main_right">

                    <div id="main_right_content">

<%
    //if something is wrong with the server when it starts up, this will produce
    //a visible message on every page, warning of the problem
    if (NGLeafServlet.initializationException!=null)
    {
        String startupMsg = NGLeafServlet.initializationException.toString();
        %>
        <div class="pagenavigation">
            <div class="pagenav">
                <div class="left"><b>SERVER STARTUP PROBLEM: <% ar.writeHtml(startupMsg); %></b></div>
                <div class="right"></div>
                <div class="clearer">&nbsp;</div>
            </div>
            <div class="pagenav_bottom"></div>
        </div>
        <%
    }

%>

<%!

    private AuthRequest ar = null;
    private String goUrl = "";
    String pageTitle = null;
    String newUIResource = "public.htm";
    UserProfile uProf = null;
    String specialTab = "";

    private String getTitle(AuthRequest ar) throws Exception
    {
        if (pageTitle!=null)
        {
            return pageTitle;
        }

        //the rest of this should not be needed
        String title = pageTitle;
        if (ar == null)
        {
            return title;
        }

        String currentPageURL = ar.getRequestURL();

        if (currentPageURL.indexOf("EditUserProfile.jsp") != -1)
        {
            if (ar.getBestUserId() != null)
            {
                org.socialbiz.cog.UserProfile up = ar.getUserProfile();
                if (up==null)
                {
                    return "Not Logged In";
                }
                String userName = up.getName();
                if (userName == null || userName.length() == 0)
                {
                    userName = up.getKey();   //key should never be null
                }
                return "User: "+userName;
            }
        }
        if (ngp != null) return ngp.getFullName();
        if (ngb != null) return "Site: "+ngb.getFullName();

        return title;
    }

    private void makeTab(AuthRequest ar, String urlExt, String tabName)
        throws Exception
    {
        boolean special = tabName.equals(specialTab);
        // TAB: View Page
        ar.write("\n<li");
        if (special)
        {
            ar.write(" class=\"current_tab_item\"");
        }
        ar.write("><a href=\"");
        ar.write(ar.retPath);
        ar.write(urlExt);
        ar.write("\"><span>");
        if (special)
        {
            ar.write("&laquo; ");
            ar.writeHtml(tabName);
            ar.write(" &raquo;");
        }
        else
        {
            ar.writeHtml(tabName);
        }
        ar.write("</span></a>\n");
        ar.write("</li> ");
    }

%>

<!-- END OF THE ngTop SECTION -->