<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%
/*
Required parameters:

    1. pageId : This is workspace id used to get Workspace Details.

Optional parameters:

    1. symbol      : Contains folderId and folders path containing the file to be attached
    2. atype       : Type of document.
    3. comment     : This parameter is used to get description of document if any
    6. isNewUpload : Used to check check if page is upload type of form or not so on the
                     basis of this Sub Tabs are created.
    7. aid         : This is attachment id to get Attachment details.
*/

    String symbol = ar.reqParam("symbol");
    String atype = ar.defParam("atype", "2");
    String comment = ar.defParam("comment", "");
    String isNewUpload = ar.defParam("isNewUpload", "yes");
    String aid = ar.defParam("aid", null);

%><%!
        String pageTitle="";
%><%

    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKey(siteId,pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Can not attach a document to this workspace.");
    String p = pageId;

    UserProfile uProf = ar.getUserProfile();
    UserPage uPage    = ar.getUserPage();

    String dname = ar.defParam("name", "");
    if (dname.length()>0) {
        throw new ProgramLogicError("why was a name passed into this page?");
    }

    ResourceEntity ent = uPage.getResourceFromSymbol(symbol);
    ConnectionType cType = uPage.getConnectionOrFail(ent.getFolderId());

    pageTitle = "Add Remote Attachment to "+ngp.getFullName();

%>

    <div>
        <div class="pageHeading">
            <%ar.writeHtmlMessage("nugen.attachment.uploadattachment.LinkDocumentFromRepository",null); %>
        </div>
        <div class="pageSubHeading">
            <%ar.writeHtmlMessage("nugen.attachment.uploadattachment.LinkRepository",null); %>
        </div>
        <div class="generalSettings">
            <form name="remoteAttachment" id="remoteAttachment" action="remoteAttachmentAction.form" method="post">
                <input type="hidden" name="action" value="Link Document"/>
                <input type="hidden" name="actionType" value="Update"/>
                <input type="hidden" name="symbol" value="<%ar.writeHtml(ent.getSymbol());%>"/>
                <input type="hidden" name="aid" value="<%ar.writeHtml(aid);%>">
                <input type="hidden" name="encodingGuard" value="%E6%9D%B1%E4%BA%AC"/>
                <input type="hidden" name="p" value="<%ar.writeHtml(p);%>"/>
                <input type="hidden" name="isNewUpload" value="<%ar.writeHtml(isNewUpload);%>"/>
                <table border="0px solid red" class="linkWizard">
                    <tr><td style="height:40px"></td></tr>
                    <tr>
                        <td colspan="3" class="linkWizardHeading">To link the document:</td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader">Address:</td>
                        <td style="width:20px;"></td>
                        <td>
                            <span style="font-size:14px;"><%ar.writeHtml(ent.getFullPath());%></span>
                        </td>
                    </tr>
                    <tr><td style="height:5px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader">Connection:</td>
                        <td style="width:20px;"></td>
                        <td><b><%ar.writeHtml(cType.getDisplayName());%></b></td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader" valign="top"><%ar.writeHtmlMessage("nugen.attachment.Comment",null); %>:</td>
                        <td style="width:20px;"></td>
                        <td><textarea name="comment" id="comment" value="<%ar.writeHtml(comment);%>" rows="4"
                                      class="form-control"></textarea><br />
                            <span class="tipText">what is the relationship between document and this workspace?</span>
                        </td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
            <tr>
                <td class="gridTableColummHeader"  valign="top">Role Access:</td>
                <td style="width:20px;"></td>
                <td  valign="top">
                <table>
                <tr>
                <%
                int count=0;
                for (NGRole role : ngp.getAllRoles()) {
                    count++;
                    String roleName = role.getName();
                    if ("Members".equals(roleName)) {
                        continue;
                    }
                    if ("Administrators".equals(roleName)) {
                        continue;
                    }
                    %><td width="150"><input type="checkbox" name="role" value="<%
                    ar.writeHtml(roleName);
                    %>"/>  <%
                    ar.writeHtml(roleName);
                    %> &nbsp; </td><%
                    if (count%3==2) {
                        %></tr><tr><%
                    }
                }
                %></tr></table>
                </td>
            </tr>                    <tr>
                    <tr><td style="height:10px"></td></tr>
                        <td width="148" class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td>
                            <input type="checkbox" name="readOnly" id="readOnly"/> Mark as read-only type
                        </td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader"><%ar.writeHtmlMessage("nugen.attachment.uploadattachment.AccessName",null); %></td>
                        <td style="width:20px;"></td>
                        <td><input type="text" name="name" class="form-control" value="<%ar.writeHtml(ent.getDecodedName());%>" /></td>
                    </tr>
                    <tr><td style="height:30px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td>
                            <input type="submit" class="btn btn-primary btn-raised"
                                value="<%ar.writeHtmlMessage("nugen.button.repository.linkdoctoproject",null); %>">
                        </td>
                    </tr>
                    <tr><td style="height:40px"></td></tr>
                </table>
            </form>
        </div>
    </div>
</div>
</div>
</div>

