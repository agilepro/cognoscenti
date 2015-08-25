<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page errorPage="error.jsp"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.ProcessRecord"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to add a file. ");

    String fid      = ar.reqParam("fid");
    String dname    = ar.reqParam("dname");
      pageTitle  = "New Folder File";

    String go = request.getParameter("go");
    if (go == null || go.length()==0)
    {
        go = "UserHome.jsp?" + ar.getUserProfile().getKey();
    }

%>

<%@ include file="Header.jsp"%>


<form name="folderForm" method="post" action="addFileAction.jsp" enctype="multipart/form-data" onSubmit="enableAllControls()">
    <input type="hidden" name="fid" value="<% ar.writeHtml(fid); %>">
    <input type="hidden" name="go" value="<% ar.writeHtml(go); %>">

    <h3>Add File to Folder  '<%=dname%>'</h3><br/>
    <table width="90%" class="Design8">
        <col width="20%"/>
        <col width="80%"/>

        <tr>
            <td>
            <label id="pathLbl">Local File Path</label>
            </td>
            <td class="Odd">
                <div id="fnamediv"><input type="file" name="fname" value="" id="fname" style="WIDTH:95%;"/></div>
            </td>
        </tr>

    </table>
    <br/>
    <center>
        <button type="submit" id="actBtn1" name="action" value="Create New">Add File</button>&nbsp;
        <button type="submit" id="actBtn2" name="action" value="Cancel">Cancel</button>
    </center>
    <br/>
</form>

<br/>
<br/>

<script>
    var actBtn1 = new YAHOO.widget.Button("actBtn1");
    var actBtn2 = new YAHOO.widget.Button("actBtn2");
</script>


<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>

