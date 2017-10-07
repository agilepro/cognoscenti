<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="java.io.StringWriter"
%><%@page import="org.socialbiz.cog.AuthDummy"
%><%@page import="org.socialbiz.cog.HTMLWriterLineFeed"
%><%@page import="org.socialbiz.cog.dms.RemoteLinkCombo"
%><%@ include file="/spring/jsp/functions.jsp"
%><%
/*
Required parameter:

    1. pageId   : This is the id of a Workspace and used to retrieve NGPage.
    2. aid      : This is attachment id to get detail of an attachment i.e. AttachmentRecord.

*/

    String p = ar.reqParam("pageId");
    String aid = ar.reqParam("id");

%><%!
        String pageTitle="";
%><%
    UserProfile uProf = ar.getUserProfile();
    UserPage up = ar.getUserPage();

    String errMsg      = "";
    Exception exp      = null;

    NGPage ngp = ar.getCogInstance().getWSByCombinedKeyOrFail(p).getWorkspace();

    AttachmentRecord attachment = ngp.findAttachmentByIDOrFail(aid);

    RemoteLinkCombo rlc = attachment.getRemoteCombo();
    ResourceEntity ent = rlc.getResourceOrNull();

    FolderAccessHelper fdh = new FolderAccessHelper(ar);
    String folderId = rlc.folderId;
    String connectionHealth = fdh.getConnectionHealth(folderId+"/");

    if(!connectionHealth.equals("Healthy")){
        errMsg = connectionHealth.substring(10,connectionHealth.length());
        connectionHealth = "Unhealthy";
    }else{
        exp = fdh.getRemoteAccessException(rlc);
        errMsg = exp.toString();
    }


    String connectionName = "";
    String ownerKey = rlc.userKey;
    AddressListEntry owner = new AddressListEntry(ownerKey);
    String url = "";

    ConnectionType cType = up.getConnectionOrNull(folderId);
    Boolean isDeleted = false;  //Used to check whether connection is deleted or not

    if (cType==null) {
        errMsg = "Connection not found for the id "+folderId;
        url = attachment.getRemoteFullPath();
        if(url.equals("")){
            url = attachment.getDisplayName();
        }
        connectionName = "unknown";
    }
    else {

        connectionName = cType.getDisplayName();
        url = cType.getFullPath(rlc.rpath);

        ConnectionSettings cSet = up.getConnectionSettingsOrNull(folderId);
        if(cSet != null && cType != null){
            isDeleted = cSet.isDeleted();
        }
    }

%>

<script type="text/javascript">
   function submitPageDiagnoseForm(actionName){
       document.getElementById("actionType").value = actionName;
       document.getElementById("problemDiagnose").submit();

   }
</script>
<div>
    <%
    if (ar.isMember())
    {
    %>
    <div class="generalArea">
        <div class="generalHeading">Link Problem Diagnosis</div>
        <div class="generalSettings">
            <form name="problemDiagnose" id="problemDiagnose" action="problemDiagnose.form" method="post">
                <input type="hidden" name="action" id="actionType" value=""/>
                <input type="hidden" name="aid" value="<%ar.writeHtml(aid);%>">
                <input type="hidden" name="atype" value="<%if (attachment.isPublic()) {ar.write("1");} else {ar.write("2");}%>">
                <input type="hidden" name="rlink" value="<%ar.writeHtml(url);%>"/>
                <input type="hidden" name="connectionHealth" value="<%ar.writeHtml(connectionHealth);%>">
                <table border="0px solid red" class="linkWizard">
                    <tr><td style="height:40px"></td></tr>
                    <tr>
                        <td colspan="3" class="linkWizardHeading">Trouble accessing the remote document:</td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td><span style="font-size:14px;"><a href="<%ar.writeHtml(url); %>"><%ar.writeHtml(url); %></a></span></td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <%
                    if(isDeleted)
                    {
                    %>
                    <tr>
                        <td width="148" class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td><span style="font-size:14px;">Connection is deleted</span></td>
                    </tr>
                    <%
                    }else
                    {
                    %>
                    <tr>
                        <td width="148" class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td><span style="font-size:14px;">Connection:&nbsp;<a href="#"><%ar.writeHtml(connectionName); %></a> owned by <% owner.writeLink(ar); %>
                        <br />Connection appears <%ar.writeHtml(connectionHealth); %></span></td>
                    </tr>
                    <%if(ar.getUserProfile().getKey().equals(ownerKey)){ %>
                    <tr><td style="height:15px"></td></tr>
                     <tr>
                        <td colspan="3" class="linkWizardHeading">Update connection password:</td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td>
                            <b>New Password:</b><br />
                            <input type="password" class="inputGeneral" id="pwd" name="pwd"/>
                        </td>
                    </tr>
                    <tr><td style="height:5px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td>
                            <input type="button" class="btn btn-primary btn-raised"
                                value="<%ar.writeHtmlMessage("nugen.button.repository.set",null); %>"
                                onclick="submitPageDiagnoseForm('ChangePassword')">
                        </td>
                    </tr>
                    <%}
                    }
                    %>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td colspan="3" class="linkWizardHeading">Choose an alternate connection:</td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader">1.</td>
                        <td style="width:20px;"></td>
                        <td>
                            <select name="folderId" class="selectGeneral">
                            <%
                            for(ConnectionSettings cSetA : fdh.getAvailableConnections(url)){
                                String selected = "";
                               // if(lfid.equals(folderId)) {
                               //     selected = "selected=\"selected\"";
                               // }
                                %>
                                <option value="<%ar.writeHtml(cSetA.getId());%>" <%ar.write(selected);%> ><%ar.writeHtml(cSetA.getDisplayName());%></option>
                                <%
                           }
                           %>
                           </select>
                       </td>
                    </tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td>
                            <input type="button" class="btn btn-primary btn-raised"
                                value="<%ar.writeHtmlMessage("nugen.button.repository.set",null); %>"
                                onclick="submitPageDiagnoseForm('UseExistingConnection')">
                        </td>
                    </tr>
                    <tr><td style="height:5px"></td></tr>
                    <tr>
                        <td colspan="3" class="linkWizardHeading">Or:</td>
                    </tr>
                    <tr><td style="height:5px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader">2.</td>
                        <td style="width:20px;"></td>
                        <td>
                            <input type="button" class="btn btn-primary btn-raised"
                                value="<%ar.writeHtmlMessage("nugen.button.repository.createnewconnection",null); %>"
                                onclick="submitPageDiagnoseForm('CreateNewConnection')">
                        </td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <%if(!isDeleted){ %>
                    <tr>
                        <td colspan="3" class="linkWizardHeading">Modify or Change Url:</td>
                    </tr>
                    <tr><td style="height:5px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td><input type="text" name="newPath" class="inputGeneralUrl" /></td>
                    </tr>
                    <tr><td style="height:5px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td>
                            <input type="button" class="btn btn-primary btn-raised"
                                value="<%ar.writeHtmlMessage("nugen.button.repository.changeurl",null); %>"
                                onclick="submitPageDiagnoseForm('ChangeURL')">
                        </td>
                    </tr>
                    <%} %>
                    <tr>
                        <td colspan="3" class="linkWizardHeading">Other Options:</td>
                    </tr>
                    <tr><td style="height:5px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td>
                        <%if(!isDeleted){ %>
                            <input type="button" class="btn btn-primary btn-raised"
                                value="<%ar.writeHtmlMessage("nugen.button.repository.createcopy",null); %>"
                                onclick="submitPageDiagnoseForm('CreateCopy')">
                        <%} %>
                            <input type="button" class="btn btn-primary btn-raised"
                                value="<%ar.writeHtmlMessage("nugen.button.repository.unlinkrepository",null); %>"
                                onclick="submitPageDiagnoseForm('UnlinkFromRepository')">
                        </td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                    <td colspan="3" class="linkWizardHeading">Problem Details:<br />
                    <span class="tipText"><%
                        if (exp!=null)
                        {
                            Throwable exprun = exp;
                            int count = 1;
                            while (exprun!=null)
                            {
                                ar.write(Integer.toString(count++));
                                ar.write(". ");
                                String msg = exprun.getMessage();
                                if (msg==null || msg.length()==0) {
                                    msg = exprun.toString();
                                }
                                ar.writeHtml(msg);
                                ar.write("\n<br/>\n");
                                exprun = exprun.getCause();
                            }
                            ar.write("\n<br/>\n<font size=\"-4\">");
                            exp.printStackTrace(new PrintWriter(new HTMLWriterLineFeed(out)));
                            ar.write("</font>\n");
                        }
                        else
                        {
                            ar.writeHtml(errMsg);
                        }
                    %></span>
                    </td>
                    </tr>
                    <tr><td style="height:40px"></td></tr>
                </table>
            </form>
        </div>
    </div>
    <%} %>
