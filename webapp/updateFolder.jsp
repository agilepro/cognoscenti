<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page errorPage="error.jsp"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.UserPage"
%><%@page import="org.socialbiz.cog.dms.ConnectionSettings"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to complete request. ");

    if (true) {throw new Exception("I don't think updateFolder.jsp is used any more");}

    String fid      = ar.reqParam("fid");
    String go       = ar.reqParam("go");
    UserPage upage = ar.getUserPage();
    ConnectionSettings cSet = upage.getConnectionSettingsOrFail(fid);
    pageTitle = "Update Repository Connection";
    String ptcl = cSet.getProtocol();

%>

<%@ include file="Header.jsp"%>


<form name="folderForm" method="get" action="folderAction.jsp" enctype="multipart/form-data" onSubmit="enableAllControls()">
    <input type="hidden" name="fid" value="<% ar.writeHtml( fid); %>">
    <input type="hidden" name="go" value="<% ar.writeHtml( go); %>">

    <h3>Update Connection  '<%ar.writeHtml(cSet.getDisplayName());%>'</h3><br/>
    <table width="90%" class="Design8">
        <col width="20%"/>
        <col width="80%"/>
        <tr>
            <td>
            <label id="protocol">Protocol</label></td>
            <td class="odd">
                <div id="ptcdiv">
                    <input type="radio" name="ptc" id="ptc" value="CVS" <%= getSelectedPtcl(ptcl, "CVS") %> />CVS
                    <input type="radio" name="ptc" id="ptc" value="WEBDAV" <%= getSelectedPtcl(ptcl, "WEBDAV") %> />SharePoint
                    <input type="radio" name="ptc" id="ptc" value="SMB" <%= getSelectedPtcl(ptcl, "SMB") %> />NetWorkShare</div>
            </td>
        </tr>
        <tr>
            <td>
            <label id="pathLbl">Display Name</label>
            </td>
            <td class="Odd">
                <div id="fnamediv"><input type="text" name="displayname" value="<%ar.writeHtml(cSet.getDisplayName());%>" id="fname" style="WIDTH:95%;"/></div>
            </td>
       </tr>
       <tr>
            <td>
            <label id="pathLbl">Server Path</label>
            </td>
            <td>
                <div id="fnamediv"><input type="text" name="serverpath" value="<%ar.writeHtml(cSet.getBaseAddress());%>" id="path" style="WIDTH:95%;"/></div>
            </td>
        </tr>
         <tr>
            <td>
            <label id="pathLbl">User ID</label>
            </td>
            <td>
                <div id="fnamediv"><input type="text" name="uid" value="<%ar.writeHtml(cSet.getFolderUserId());%>" id="uid" style="WIDTH:95%;"/></div>
            </td>
        </tr>
         <tr>
            <td>
            <label id="pathLbl">Password</label>
            </td>
            <td>
                <div id="fnamediv"><input type="password" name="pwd" id="pwd" style="WIDTH:95%;"/></div>
            </td>
        </tr>

    </table>
    <br/>
    <center>
        <button type="submit" id="actBtn1" name="action" value="Update">Update</button>&nbsp;
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


<%!
    public String getSelectedPtcl(String currentPtcl, String ptcType){
        if(currentPtcl.equalsIgnoreCase(ptcType)){
            return "checked=\"checked\"";
        }else{
            return "";
        }

    }
%>
