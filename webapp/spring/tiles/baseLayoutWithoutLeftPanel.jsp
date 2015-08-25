<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<%@ include file="/spring/jsp/include.jsp"
%><%@ taglib uri="http://tiles.apache.org/tags-tiles" prefix="tiles"
%><%
    String title=(String)request.getAttribute("title");
    request.setAttribute("headerType", "blank");
    String themePath = ar.getThemePath();
%>
<!-- Begin baseLayoutWithoutLeftPanel.jsp -->
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta http-equiv="Content-Language" content="en-us" />
        <meta http-equiv="Content-Style-Type" content="text/css" />
        <meta http-equiv="imagetoolbar" content="no" />

        <link href="<%=ar.baseURL%>css/body.css" rel="styleSheet" type="text/css" media="screen" />
        <link href="<%=ar.baseURL%>css/tables.css" rel="styleSheet" type="text/css" media="screen" />

        <!--[if IE 7]>
            <link href="<%=ar.baseURL%>css/ie7styles.css" rel="styleSheet" type="text/css" media="screen" />
        <![endif]-->

        <script type="text/javascript" src="<%=ar.baseURL%>jscript/tabs.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>jscript/nugen_utils.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>jscript/yahoo-dom-event.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>jscript/jquery.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>jscript/interface.js"></script>
        <script type="text/javascript" src="<%=ar.retPath%>jscript/TabbedPanels.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>jscript/common.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>jfunc.js"></script>

        <link rel="stylesheet" type="text/css" href="<%=ar.baseURL%>yui/build/fonts/fonts-min.css" />
        <link rel="stylesheet" type="text/css" href="<%=ar.baseURL%>yui/build/menu/assets/skins/sam/menu.css" />
        <link rel="stylesheet" type="text/css" href="<%=ar.baseURL%>yui/build/datatable/assets/skins/sam/datatable.css" />
        <link rel="stylesheet" type="text/css" href="<%=ar.baseURL%>yui/build/button/assets/skins/sam/button.css" />
        <link rel="stylesheet" type="text/css" href="<%=ar.baseURL%>yui/build/autocomplete/assets/skins/sam/autocomplete.css" />
        <link rel="stylesheet" type="text/css" href="<%=ar.baseURL%>yui/build/paginator/assets/skins/sam/paginator.css" />
        <link rel="stylesheet" type="text/css" href="<%=ar.baseURL%>yui/build/container/assets/skins/sam/container.css" />
        <link rel="stylesheet" type="text/css" href="<%=ar.baseURL%>yui/build/tabview/assets/skins/sam/tabview.css" />
        <link rel="stylesheet" type="text/css" href="<%=ar.retPath%>css/TabbedPanels.css" />

        <script type="text/javascript" src="<%=ar.baseURL%>yui/build/yahoo-dom-event/yahoo-dom-event.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>yui/build/connection/connection-min.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>yui/build/json/json-min.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>yui/build/element/element-beta-min.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>yui/build/paginator/paginator-min.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>yui/build/datasource/datasource-min.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>yui/build/dragdrop/dragdrop-min.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>yui/build/datatable/datatable-min.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>yui/build/button/button-min.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>yui/build/animation/animation-min.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>yui/build/autocomplete/autocomplete-min.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>yui/build/utilities/utilities.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>yui/build/tabview/tabview-min.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>yui/build/container/container-min.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>yui/build/container/container_core-min.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>yui/build/menu/menu-min.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>yui/build/cookie/cookie-min.js"></script>

        <!-- for calender -->
        <link rel="stylesheet" type="text/css" media="all" href="<%=ar.baseURL%>jscalendar/calendar-win2k-cold-1.css" title="win2k-cold-1" />
        <script type="text/javascript" src="<%=ar.baseURL%>jscalendar/calendar.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>jscalendar/lang/calendar-en.js"></script>
        <script type="text/javascript" src="<%=ar.baseURL%>jscalendar/calendar-setup.js"></script>
        <!-- for calender -->
        <link href="<%=ar.retPath%>css/reset.css" rel="styleSheet" type="text/css" media="screen" />
        <link href="<%=ar.retPath%>css/global.css" rel="styleSheet" type="text/css" media="screen" />
        <link href="<%=ar.retPath%><%=themePath%>theme.css" rel="styleSheet" type="text/css" media="screen" />
        <link href="<%=ar.retPath%>css/ddlevelsmenu-base.css" rel="styleSheet" type="text/css" media="screen" />

        <title><tiles:getAsString name="title"/><%
        if(title!=null) {
            ar.write(title);
        }
        %></title>

        <style type="text/css">
            #bodyWrapper {
                margin:0px 30px 45px 30px;
                min-width:935px;
                position:relative;
            }
        </style>
    </head>
    <body>

    <!-- Start body wrapper -->
    <div id="bodyWrapper">

        <!-- Begin Top Navigation Area -->
        <div id="topNav">
            <tiles:insertAttribute name="header" />
        </div>
        <!-- End Top Navigation Area -->

        <!-- Begin mainSiteContainer -->
        <div id="mainSiteContainerDetails">
            <div id="mainSiteContainerDetailsRight">
                <table align="center">
                    <tr>
                        <td valign="top">
                            <!-- Begin mainContent (Body area) -->
                                <div id="mainContent">
                                    <tiles:insertAttribute name="body" />
                                </div>
                            <!-- End mainContent (Body area) -->
                        </td>
                    </tr>
                </table>
            </div>
        </div>
        <!-- End mainSiteContainer -->

        <!-- Begin siteFooter -->
        <div id="siteFooter">
            <div id="siteFooterRight">
                <div id="siteFooterCenter"><tiles:insertAttribute name="footer" /></div>
            </div>
        </div>
        <!-- End siteFooter -->

    </div>
    <!-- End body wrapper -->
    </body>
</html>
<!-- end baseLayoutWithoutLeftPanel.jsp -->

