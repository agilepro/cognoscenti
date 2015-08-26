<!-- BEGIN slimFooter.jsp -->
<%@page import="org.socialbiz.cog.AuthRequest"%>
<%@page import="org.socialbiz.cog.NGPageIndex"%>
<%
/*

Optional Parameter:

    3. pageId           : This is used to go to Old-UI page.
*/

    AuthRequest far = AuthRequest.getOrCreate(request, response, out);
    String pageId = (String)request.getAttribute("pageId");
%>

    <div id="footer">
        <table width="100%">
            <tr>
                <td>
                    <% if (far.isLoggedIn()) {
                       %><a href="<%
                        far.write(far.retPath);
                        if(pageId!=null&&pageId.length()>0){
                            far.write("p/");
                            far.writeURLData(pageId);
                            far.write("/history.htm");
                        }else{
                            far.write("UserHome.jsp");
                        }
                        %>" title="View the old UI for this page">Old UI</a><%
                    } %>
                </td>
                <td align="right">
                    Originally designed by Fujitsu North America, Advanced Software Design Lab
                </td>
            </tr>
        </table>
    </div>
<% out.flush(); %>
<!-- END slimFooter.jsp -->

