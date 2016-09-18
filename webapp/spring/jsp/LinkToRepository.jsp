<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%
/*
Required parameter:

    1. pageId : This is the id of a Workspace and used to retrieve NGPage.

*/

    String p = ar.reqParam("pageId");

%><%!
        String pageTitle="";
%>
<%
    UserProfile uProf = ar.getUserProfile();
    ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);

    String lastPath = (String) session.getAttribute("lastPath");
    String connectionId = (String) session.getAttribute("connectionId");

    String isUserFolderBlank = "true";
    UserPage uPage = ar.getUserPage();
    if(connectionId != null){
        ConnectionSettings cSet = uPage.getConnectionSettingsOrNull(connectionId);
        if(cSet!=null && !cSet.isDeleted())
        {
            isUserFolderBlank = "false";
        }
    }


%>
<script type="text/javascript">
   function browseConnection(connectionId,lastPath, isEmpty){
       if(connectionId!='null' && lastPath!='null' && isEmpty == 'false')
       {
           window.location = "<%=ar.retPath%>v/<%ar.writeHtml(ar.getUserProfile().getKey());%>/BrowseConnection<%ar.writeHtml(connectionId);%>.htm?path=<%ar.writeHtml(lastPath);%>&p=<%ar.writeHtml(ngp.getKey());%>";
       }else{
           window.location = "<%=ar.retPath%>v/<%ar.writeHtml(ar.getUserProfile().getKey());%>/ListConnections.htm?pageId=<%ar.writeHtml(ngp.getKey());%>";
       }
   }
</script>
<div>
    <div class="pageHeading">
        <fmt:message key="nugen.attachment.uploadattachment.LinkDocumentFromRepository" />
    </div>
    <%if(ngp.isFrozen()){ %>
           <div id="loginArea">
               <span class="black">
                    <fmt:message key="nugen.project.freezed.msg" />
               </span>
           </div>
   <%}else{ %>
    <div class="pageSubHeading">
        <fmt:message key="nugen.attachment.uploadattachment.LinkRepository"/>
    </div>
    <div class="generalContent">
        <table border="0px solid red" class="linkWizard">
            <tr><td style="height:40px"></td></tr>
            <tr>
                <td colspan="3" class="linkWizardHeading">Do you want to:</td>
            </tr>
            <tr><td style="height:15px"></td></tr>
            <tr>
                <td class="linkWizardContent">1.</td>
                <td style="width:20px;"></td>
                <td>
                    <input type="button" class="btn btn-primary"
                                value="<fmt:message key="nugen.button.repository.browseconnection" />"
                                onclick="browseConnection('<%= connectionId %>','<%= lastPath %>','<%= isUserFolderBlank %>')">
                </td>
            </tr>
            <tr><td style="height:15px"></td></tr>
            <tr>
                <td colspan="3" class="linkWizardHeading">or use a WebDav URL:</td>
            </tr>
            <tr><td style="height:15px"></td></tr>
            <form id="submitWebDevURL" name="submitWebDevURL" action="submitWebDevURL.form" method="post">
                <tr>
                    <td class="linkWizardContent">2.</td>
                    <td style="width:20px;"></td>
                    <td>
                        <input type="text" name="rLink" class="form-control" value="" style="min-width:500px;"/></td>
                </tr>
                <tr><td style="height:5px"></td></tr>
                <tr>
                    <td class="linkWizardContent"></td>
                    <td style="width:20px;"></td>
                    <td>
                        <input type="submit" class="btn btn-primary"
                            value="<fmt:message key="nugen.button.repository.submiturl" />">
                    </td>
                </tr>
            </form>
            <tr><td style="height:40px"></td></tr>
        </table>
    <%} %>
    </div>
</div>
</div>
</div>
</div>

