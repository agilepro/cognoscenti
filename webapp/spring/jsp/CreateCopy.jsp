<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%/*
Required parameter:

    1. pageId   : This is the id of a Project and used to retrieve NGPage.
    2. aid      : This parameter is attachment id used here to get the detail of an attachment.
*/

    String p = ar.reqParam("pageId");
    String aid = ar.reqParam("aid");%>
<%!String pageTitle="";%>
<%
    UserProfile uProf = ar.getUserProfile();

    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(p);

    UserPage uPage = ar.getUserPage();

    AttachmentRecord attachment = ngp.findAttachmentByID(aid);
    String name     = attachment.getDisplayName();
    ResourceEntity defaultRemoteFolder = ngp.getDefRemoteFolder();

    FolderAccessHelper fdh = new FolderAccessHelper(ar);
    String attLink = ar.baseURL+"t/"+ngp.getSite().getKey()+"/"+ngp.getKey()+"/a/"+name+"?version="+attachment.getVersion();
%>

<script type="text/javascript">
   function submitCreateCopyForm(actionName){
       document.getElementById("actionType").value = actionName;
       document.getElementById("CreateCopyForm").submit();
   }
</script>
    <div>
        <div class="pageHeading">
            <%ar.writeHtmlMessage("nugen.button.repository.pushdocument",null); %>
        </div>
        <div class="pageSubHeading">
            <%ar.writeHtmlMessage("nugen.button.repository.pushdocumenttext",null); %>
        </div>
        <div class="generalContent">
            <form name="CreateCopyForm" id="CreateCopyForm" action="CreateCopyForm.form" method="post">
                <input type="hidden" name="action" id="actionType" value=""/>
                <input type="hidden" name="encodingGuard" value="%E6%9D%B1%E4%BA%AC"/>
                <input type="hidden" name="aid" value="<%ar.writeHtml(aid);%>"/>
                <table border="0px solid red" class="linkWizard">
                    <tr><td style="height:40px"></td></tr>
                    <tr>
                        <td colspan="3" class="linkWizardHeading">To store the document:</td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td colspan="3" class="linkWizardContent"><a href="<% ar.writeHtml(attLink); %>"><% ar.writeHtml(name); %></a></td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td colspan="3" class="linkWizardHeading">Do you want to:</td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td class="linkWizardContent">1.</td>
                        <td style="width:20px;"></td>
                        <td class="linkWizardContentRight">Choose existing connection</td>
                    </tr>
                    <tr>
                        <td class="linkWizardContent"></td>
                        <td style="width:20px;"></td>
                        <td>
                            <select name="folderId">
                            <%
                            for (ConnectionSettings cSet : uPage.getAllConnectionSettings()) {
                                if(!cSet.isDeleted()){
                                    %>
                                    <option value="<% ar.writeHtml(cSet.getId());%>"><% ar.writeHtml(cSet.getDisplayName());%></option>
                                    <%
                                }
                            }
                            %>
                            </select>
                        </td>
                    </tr>
                    <tr>
                        <td class="linkWizardContent"></td>
                        <td style="width:20px;"></td>
                        <td>
                            <button class="btn btn-primary" value="Create Copy" onclick="submitCreateCopyForm('ChooseFolder')">
                            <%ar.writeHtmlMessage("nugen.button.repository.choosefolder",null); %></button>
                        </td>
                    </tr>
                    <tr><td style="height:20px"></td></tr>
                    <tr>
                        <td class="linkWizardContent">2.</td>
                        <td style="width:20px;"></td>
                        <td class="linkWizardContentRight">Create a new connection</td>
                    </tr>
                    <tr>
                        <td class="linkWizardContent"></td>
                        <td style="width:20px;"></td>
                        <td><button class="btn btn-primary" value="Create connection" onclick="submitCreateCopyForm('CreateNewConnection')">
                            <%ar.writeHtmlMessage("nugen.button.repository.createnewconnection",null); %></button>
                        </td>
                    </tr>
                    <tr><td style="height:20px"></td></tr>
                    <tr>
                        <td class="linkWizardContent">3.</td>
                        <td style="width:20px;"></td>
                        <%if(defaultRemoteFolder!=null){ %>
                        <td class="linkWizardContentRight">Use default location<br>"<% ar.writeHtml(defaultRemoteFolder.getFullPath()); %>"</td>
                    </tr>
                    <tr><td style="height:5px"></td></tr>
                    <tr>
                        <td class="linkWizardContent"></td>
                        <td style="width:20px;"></td>
                        <td><input type="button" class="btn btn-primary" value="Ok" onclick="submitCreateCopyForm('ChooseDefLocation')"/>
                        </td>
                    </tr>
                    <tr>
                        <td class="linkWizardContent"></td>
                        <td style="width:20px;"></td>
                        <%}else{ %>
                        <td class="linkWizardContentRight">No default location</td>
                    </tr>
                        <%} %>
                    <tr><td style="height:40px"></td></tr>
                </table>
            </form>
        </div>
    </div>
</div>
</div>
</div>

