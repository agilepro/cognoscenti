<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%
/*
Required parameter:

    1. p        : This is the id of a Project and used to retrieve NGPage.
    2. aid      : This parameter is attachment id used here to get the detail of an attachment.
    3. path     : This is the path of the selected folder in the repository
    4. folderId : This is connection id which is used to get Connection details.
*/

    String p = ar.reqParam("pageId");
    String aid = ar.reqParam("aid");
    String folderId = ar.reqParam("folderId");
    String path = ar.reqParam("path");
%>
<%!
        String pageTitle="";
%>
<%
    UserProfile uProf = ar.getUserProfile();
    UserPage uPage = ar.getUserPage();

    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(p);

    AttachmentRecord attachment = ngp.findAttachmentByID(aid);
    String name     = attachment.getDisplayName();
    ResourceEntity ent = uPage.getResource(folderId, path);
    String fullPath = ent.getFullPath();
%>

    <div>
        <div class="pageHeading">
            <%ar.writeHtmlMessage("nugen.button.repository.pushdocument",null); %>
        </div>
        <div class="pageSubHeading">
            <%ar.writeHtmlMessage("nugen.button.repository.pushdocumenttext",null); %>
        </div>
        <div class="generalContent">
            <form name="PushToRepository" id="PushToRepository" action="PushToRepository.form" method="post">
                <input type="hidden" name="aid" value="<%ar.writeHtml(aid);%>"/>
                <input type="hidden" name="symbol" value="<%ar.writeHtml(ent.getSymbol());%>"/>
                <table border="0px solid red" class="linkWizard">
                    <tr><td style="height:40px"></td></tr>
                    <tr>
                        <td class="linkWizardHeading">Storing the document:</td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td class="linkWizardContent"><% ar.writeHtml(name); %></td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td class="linkWizardHeading">at folder location:</td>
                    </tr>
                    <tr><td style="height:20px"></td></tr>
                    <tr>
                        <td class="linkWizardContent"><%ar.writeHtml(fullPath);%></td>
                    </tr>
                    <tr><td style="height:20px"></td></tr>
                    <tr>
                        <td class="linkWizardContent"><input type="submit" class="btn btn-primary"
                            value="<%ar.writeHtmlMessage("nugen.button.repository.pushdocument",null); %>"/></td>
                    </tr>
                    <tr><td style="height:40px"></td></tr>
                </table>
            </form>
        </div>
    </div>
</div>
</div>
</div>

