<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page isErrorPage="true"
%><%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"
%><%@include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.exception.NGException"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%@page import="org.socialbiz.cog.ErrorLog"
%><%@page import="org.socialbiz.cog.ErrorLogDetails"
%><%@page import="java.io.PrintWriter"
%><%@page import="java.util.Locale"
%><%String pageTitle = (String) request.getAttribute("pageTitle");
    String userName = "User not logged in";
    if (ar.isLoggedIn()) {
        userName = ar.getUserProfile().getName();
    }

    if (pageTitle == null) {
        pageTitle = "Error Page";
    }

    String exceptionNO = ar.defParam("exceptionNO", null);

    //this code was allowing a display to be made of an unlogged exception, logging
    //it here is a little sloppy.  Should assure that all errors are logged before this page.
    if (exceptionNO == null) {
        exceptionNO=String.valueOf(ar.logException("", exception));
    }

    Cognoscenti cog = Cognoscenti.getInstance(request);
    ErrorLog eLog = ErrorLog.getLogForDate(ar.nowTime, cog);
    ErrorLogDetails eDetails = eLog.getDetails(exceptionNO);

    String msg = eDetails.getErrorDetails();

    //get rid of pointless name of exception class that appears in 99% of cases
    if (msg.startsWith("java.lang.Exception: ")) {
        msg = msg.substring(21);
    }
    pageTitle = "-- Problem Resolution Message --";
    long searchDate=new Date().getTime();

    if (msg.indexOf("TilesJspException")>0) {
        //in this case, we have an error within the Tiles, which means this was
        //thrown from within a page, nested who knows how many levels deep.
        //This attempts to close all the containing structures if possible.
        ar.write("</li></ul></div></td></tr></table></li></ul></div></td></tr></table></div></td></tr></table></li></ul></div></td></tr></table>");
    }%>
<link href="<%=ar.baseURL%>css/body.css" rel="styleSheet" type="text/css" media="screen" />
<script type="text/javascript" src="<%=ar.baseURL%>jscript/nugen_utils.js"></script>
<script type="text/javascript" src="<%=ar.baseURL%>jscript/yahoo-dom-event.js"></script>

<link href="<%=ar.retPath%>css/tabs.css" rel="styleSheet" type="text/css" media="screen" />
<link href="<%=ar.retPath%>css/reset.css" rel="styleSheet" type="text/css" media="screen" />
<link href="<%=ar.retPath%>css/global.css" rel="styleSheet" type="text/css" media="screen" />



    <div class="generalArea">
        <div class="generalHeading"><fmt:message key="nugen.common.errorHeader" /></div>
        <ul>

        <li><fmt:message key="nugen.common.error" /></li>

        </ul>
        <%
            Throwable runner = exception;
            int counter=0;
            while (runner!=null)
            {
                String msg1 = runner.toString();
                if (msg.startsWith("java.lang.Exception: "))
                {
                    msg1 = msg.substring(21);
                }
                ar.write("\n<br/>");
                ar.write("\n<li><span style=\"color:#5377ac\"><b>");
                ar.write(Integer.toString(++counter));
                ar.write(".  ");
                ar.writeHtmlWithLines(msg1);
                ar.write("</b></span></li>");
                runner = runner.getCause();
            }
        %>

        <br/>
        <li><b>Reference No:</b> <% ar.writeHtml(exceptionNO);%></li>
        <br/>
        <li><b>User:</b> <% ar.writeHtml(userName);%></li>
        <br/>
        <li><b>Date & Time: </b><% ar.writeHtml(ar.nowTimeString);%></li>
        </ul>
        <br/>
        <br/>
        <img src="<%= ar.retPath %>but_process_view.gif" title="Show Error details" onclick="showHideCommnets('stackTrace')">
        <div id="stackTrace" class="errorStyle" style="display:none">
            <span style="overflow:auto;width:900px;"><%ar.writeHtmlWithLines(eDetails.getErrorDetails()); %></span>
        </div>
    </div>

<script>

    function showHideCommnets(divid)
    {
        var id = document.getElementById(divid);
        if(id.style.display == "block")
        {
            id.style.display = "none";
        }
        else
        {
            id.style.display = "block";
        }
    }

</script>
