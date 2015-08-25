<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<%@ include file="/spring/jsp/include.jsp"
%><%@ taglib uri="http://tiles.apache.org/tags-tiles" prefix="tiles"
%><%
    String title=(String)request.getAttribute("title");
    String themePath = ar.getThemePath();
%>
<!-- Begin baseLayoutSimple.jsp -->
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta http-equiv="Content-Language" content="en-us" />
        <meta http-equiv="Content-Style-Type" content="text/css" />
        <meta http-equiv="imagetoolbar" content="no" />

        <script type="text/javascript" src="jscript/angular.min.js"></script>

        <link href="<%=ar.baseURL%>css/global.css" rel="styleSheet" type="text/css" media="screen" />
        <link href="<%=ar.baseURL%>css/body.css" rel="styleSheet" type="text/css" media="screen" />
        <link href="<%=ar.retPath%>css/ddlevelsmenu-base.css" rel="styleSheet" type="text/css" media="screen" />

        <title><tiles:getAsString name="title"/><%
        if(title!=null) {
            ar.write(title);
        }
        %></title>
    </head>
    <body>

    <!-- Start body wrapper -->
    <div id="bodyWrapper">
        <div id="mainContent">
            <tiles:insertAttribute name="body" />
        </div>
    </div>
    <!-- End body wrapper -->
    </body>
</html>
<!-- end baseLayoutSimple.jsp -->
