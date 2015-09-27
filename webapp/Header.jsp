<%@page import="org.socialbiz.cog.rest.NGLeafServlet"
%><%
    //check to assure that this is not a POST request
    //ar.assertNotPost();

    //note that this page requires a global variable set for the page name: pageTitle
    //note that this page requires a global variable set for the specialTab

    String deletedWarning = "";
    if (ngp!=null)
    {
        if (ngp.isDeleted())
        {
            deletedWarning = "<img src=\""+ar.retPath+"deletedLink.gif\"> (DELETED)";
        }
        else if (ngp.isFrozen())
        {
            deletedWarning = " ~ (Frozen)";
        }
    }

    String styleSheet = "PageViewer.css";
    if (ngb!=null)
    {
        String ss = ngb.getStyleSheet();
        if (ss!=null && ss.length()>0)
        {
            styleSheet = ss;
        }
    }
    String navImage = ar.retPath+"navigation.jpg";
    if (ngb!=null)
    {
        String logo = ngb.getLogo();
        if (logo!=null && logo.length()>0)
        {
            int ppos = logo.indexOf("/p/");
            if (ppos>0) {
                navImage = ar.retPath+logo.substring(ppos+1);
            }
        }
    }

%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" dir="ltr">

    <head>

    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">


    <link rel="stylesheet" type="text/css" media="screen" href="<%=ar.retPath%><%=styleSheet%>"  />
    <link rel="stylesheet" type="text/css" media="all" href="<%=ar.retPath%>css/datatable.css"/>

    <script type="text/javascript" src="<%=ar.retPath%>jscript/common.js"></script>
    <script type="text/javascript" src="<%=ar.retPath%>jfunc.js"></script>

    <!-- for calender -->
    <link rel="stylesheet" type="text/css" media="all" href="<%=ar.retPath%>jscalendar/calendar-win2k-cold-1.css" title="win2k-cold-1" />
    <script type="text/javascript" src="<%=ar.retPath%>jscalendar/calendar.js"></script>
    <script type="text/javascript" src="<%=ar.retPath%>jscalendar/lang/calendar-en.js"></script>
    <script type="text/javascript" src="<%=ar.retPath%>jscalendar/calendar-setup.js"></script>
    <!-- for calender -->

    <style type="text/css">
    #navigation {
        background: #739CBA url('<%ar.writeHtml(navImage);%>') no-repeat top center;
        padding: 82px 10px 0;
    }
    </style>

    <title><%ar.writeHtml(pageTitle);%></title>
    </head>

    <body>

        <a name="Top" href="#"></a>
        <div id="layout_wrapper">
        <div id="layout_edgetop"></div>

        <div id="layout_container">

            <div id="site_title">
                <span class="left page_title"><%ar.writeHtml(getTitle(ar));%><%=deletedWarning%></span>
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
                                        "Site Workspaces");
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
                                        "My Workspaces");
                            makeTab(ar, "UserProfile.jsp?u="+URLEncoder.encode(uProf.getKey(), "UTF-8"),
                                        "Settings");
                        }
                        else
                        {
                            //no tabs I guess
                        }
                         %>

                       </ul>
                    <div class="clearer">&nbsp;</div>
                </div>

            </div>

            <div class="spacer h5"></div>

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


