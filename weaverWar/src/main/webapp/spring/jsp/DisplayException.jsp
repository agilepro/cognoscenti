<%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.UserProfile"
%><%
    /*
    The function of this page is simple enough: display an exception in a
    reasonably nice setting.  Can be used for exceptions that occur in the handler
    early and predictably enough.
    */

    Exception display_exception = (Exception) request.getAttribute("display_exception");
    if (display_exception==null) {
        throw new Exception("Exception.jsp must be passed an exception object in the 'display_exception' parameter");
    }
%>
<style type="text/css">
    td{padding:100;border:10;margin:10;vertical-align:top;}
</style>
<body>
    <div class="generalArea"><br/>
    <table><tr>
        <td>
            <img src="<%=ar.retPath %>assets/iconAlertBig.gif" title="Alert">&nbsp;&nbsp;
        </td>
        <td>
            <ol>
            <%
            int count = 0;
            Throwable t = display_exception;
            while (t!=null) {
                count++;
                ar.write("\n<li>"+count+": ");
                ar.writeHtml(t.toString());
                t = t.getCause();
                ar.write("</li>");
            }
            %>
            </ol><br/>
            Logged in as: <% ar.writeHtml(ar.getBestUserId()); %> <br/><br/>
            URL: <% ar.writeHtml(ar.getCompleteURL()); %> <br/><br/>
            Date & Time: <% SectionUtil.nicePrintDateAndTime(ar.w, ar.nowTime); %>
            <br /><br />
        </td>
    </tr></table>
    </div>
</body>
