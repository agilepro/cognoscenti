<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page errorPage="error.jsp"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
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
    ar.assertLoggedIn("Can't add subfolder to the Folder.");

    String combinedFolderIdAndPath      = ar.reqParam("fid");
    String dname    = ar.reqParam("dname");

    String go = request.getParameter("go");

    pageTitle = "Add Sub Folder";

%>

<%@ include file="Header.jsp"%>


<form name="folderForm" method="get" action="folderAction.jsp" enctype="multipart/form-data" onSubmit="enableAllControls()">
    <input type="hidden" name="fid" value="<% ar.writeHtml(combinedFolderIdAndPath); %>">
    <input type="hidden" name="go" value="<% ar.writeHtml(go); %>">


    <h3>Add Subfolder to Folder  '<%ar.writeHtml(dname);%>'</h3><br/>
    <table width="90%" class="Design8">
        <col width="20%"/>
        <col width="80%"/>

        <tr>
            <td>
            <label id="pathLbl">Sub Folder Name</label>
            </td>
            <td class="Odd">
                <div id="fnamediv"><input type="text" name="fname" value="" id="fname" style="WIDTH:95%;"/></div>
            </td>
        </tr>

    </table>
    <br/>
    <center>
        <button type="submit" id="actBtn1" name="action" value="CreateSub">Add Folder</button>&nbsp;
        <button type="submit" id="actBtn2" name="action" value="Cancel">Cancel</button>
    </center>
    <br/>

</form>

<script>
    var actBtn1 = new YAHOO.widget.Button("actBtn1");
    var actBtn2 = new YAHOO.widget.Button("actBtn2");
</script>


<script>



</script>

<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>

