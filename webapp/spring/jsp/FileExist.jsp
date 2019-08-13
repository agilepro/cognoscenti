<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%
/*
Required parameter:

    1. path     : This is the path of selected folder of repository.
    2. pageId   : This is the id of a Workspace and used to retrieve NGWorkspace.
    3. aid      : This is the attachment document id throgh which we get the
                  details about the document to be stored in repository.
    4. folderId : This is the connection id through which we get details about connection.



*/

    String path = ar.reqParam("path");
    String aid = ar.reqParam("aid");
    String p = ar.reqParam("pageId");
    String folderId = ar.reqParam("folderId");

    UserProfile uProf = ar.getUserProfile();
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    AttachmentRecord attachment = ngp.findAttachmentByID(aid);
    String name     = attachment.getDisplayName();


%>
<script type="text/javascript">
    function submitFormFileExistPage(){
       document.getElementById("actionVal").value="Cancel";
       document.getElementById("fileExist").submit();
    }

    function displayOption(){
        if(document.getElementById("storeOtherName").checked == true)
        {
            document.getElementById("newNameTR").style.display = 'block';
        }else
        {
            document.getElementById("newNameTR").style.display = 'none';
        }



    }
</script>
    <div>
        <div class="pageHeading">
            <fmt:message key="nugen.attachment.fileexsists.heading" />
        </div>
        <div class="pageSubHeading">
            <fmt:message key="nugen.attachment.fileexsists.description"/>
        </div>
        <div class="generalSettings">
            <form name="fileExist" id="fileExist" action="fileExists.form" method="post">
                <input type="hidden" name="aid" value="<%ar.writeHtml(aid);%>"/>
                <input type="hidden" name="encodingGuard" value="<%writeHtml(out,"\u6771\u4eac");%>"/>
                <input type="hidden" name="path" value="<%ar.writeHtml(path);%>"/>
                <input type="hidden" name="actionVal" id="actionVal" value="actionVal"/>
                <input type="hidden" name="folderId" value="<%ar.writeHtml(folderId); %>"/>
                <table border="0px solid red" class="linkWizard">
                    <tr><td style="height:40px"></td></tr>
                    <tr>
                        <td colspan="3" class="linkWizardHeading"><fmt:message key="nugen.attachment.fileexsists.heading" />:</td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td><span style="font-size:14px;">"<%= name %>" already existing in "<%=path %>"</span></td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td colspan="3" class="linkWizardHeading">Would you like to:</td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td><input type="radio" name="action" value="link to existing document" onclick="displayOption()"/> link to existing document</td>
                    </tr>
                    <tr><td style="height:5px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td><input type="radio" name="action" value="overwrite the existing document" onclick="displayOption()"/> overwrite the existing document</td>
                    </tr>
                    <tr><td style="height:5px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td><input type="radio" name="action" id="storeOtherName" value="store using different name" onclick="displayOption()"/> store using different name
                            <div id="newNameTR" style="padding-top: 10px; display: none;">New Name:&nbsp;&nbsp;<input type="text" name="newName" /></div>
                        </td>
                    </tr>
                    <tr><td style="height:5px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td><input type="radio" name="action" value="try again" onclick="displayOption()"/> try again</td>
                    </tr>
                    <tr><td style="height:30px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td>
                            <input type="submit" value="Ok" title="Ok" class="btn btn-primary btn-raised"/>
                            <input type="button" value="Cancel" title="Cancel" class="btn btn-primary btn-raised" onclick="submitFormFileExistPage()"/>
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

