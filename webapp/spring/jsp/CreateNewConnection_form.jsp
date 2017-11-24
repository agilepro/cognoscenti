<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.dms.CVSConfig"
%><%@page import="org.socialbiz.cog.dms.LocalFolderConfig"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%
/*
Required parameter:

    1. pageId   : This is the id of a Workspace and used to retrieve NGPage.
    2. rlink    : It is the path of the file for which you are creating new connection.

Optional Parameters:

    1. isNewUpload  : This parameter is used to check if page is upload type of form or not so on the
                      basis of this Sub Tabs are created.
    2. aid          : This is the attachment id which gives details about attachment in case that attachment
                      is already exsist butgives error while synchronising it.
    3.ConnectionURL : This is the URL for new connection. We get it from rlink by excluding the file name.
*/

    String p = ar.reqParam("pageId");
    String rlink = ar.reqParam("rlink");

    String ConnectionURL = "";
    String isNewUpload = ar.defParam("isNewUpload", "yes");
    String aid = ar.defParam("aid", null);

    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKey(siteId,pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);

    String pageTitle = "Add Remote Attachment to "+ngp.getFullName();
    ar.assertMember("Can not attach a document to this workspace.");

    if(ConnectionURL.length()== 0 && rlink.length() > 0){
        ConnectionURL = rlink.substring(0,rlink.lastIndexOf('/'));
    }

    UserProfile uProf = ar.getUserProfile();

    List<CVSConfig> cvsConnections =  FolderAccessHelper.getCVSConnections();
    List<LocalFolderConfig> lclConnections =  FolderAccessHelper.getLoclConnections();
%>
    <div>
        <div class="pageHeading">
            <fmt:message key="nugen.attachment.uploadattachment.LinkDocumentFromRepository" />
        </div>
        <div class="pageSubHeading">
            <fmt:message key="nugen.attachment.uploadattachment.LinkRepository"/>
        </div>
        <div class="generalSettings">
            <form name="createConnection" id="createConnection" action="createConnection.form" method="post">
                <input type="hidden" name="action" value="createConnection"/>
                <input type="hidden" name="rlink" value="<%ar.writeHtml(rlink);%>"/>
                <input type="hidden" name="p" value="<%ar.writeHtml(p);%>"/>
                <input type="hidden" name="fid" id="fid" value="CREATE">
                <input type="hidden" name="isNewUpload" value="<%ar.writeHtml(isNewUpload);%>"/>
                <input type="hidden" name="aid" value="<%ar.writeHtml(aid);%>">
                <input type="hidden" name="go" id="updateGo" value="<%ar.writeHtml(ar.getCompleteURL());%>">
                <input type="hidden" name="folderId" id="fid" value="CREATE">
                <table>
                    <tr><td style="height:40px"></td></tr>
                    <tr>
                        <td colspan="3" class="linkWizardHeading">To access the document at address:</td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td>
                            <span style="font-size:14px;"><%ar.writeHtml(rlink); %></span>
                        </td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader">Protocol:</td>
                        <td  style="width:20px;"></td>
                        <td colspan="2">
                            <input type="radio" name="ptc" id="ptc" value="CVS" onClick="changeForm(this)" /> CVS
                            <input type="radio" name="ptc" id="ptc" value="WEBDAV" checked="checked" onClick="changeForm(this)"/> SharePoint
                            <input type="radio" name="ptc" id="ptc" value="SMB" onClick="changeForm(this)"/> NetWorkShare
                            <input type="radio" name="ptc" id="ptc" value="LOCAL" onClick="changeForm(this)"/> Local
                        </td>
                    </tr>
                    <tr><td style="height:5px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader">Connection Name:</td>
                        <td  style="width:20px;"></td>
                        <td colspan="2"><input type="text" name="displayname" id="fname" class="inputGeneral" size="69" /></td>
                    </tr>
                    <tr><td style="height:5px"></td></tr>
                    <tr id="trspath">
                        <td class="gridTableColummHeader">URL:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2"><input type="text" name="serverpath" id="path" class="inputGeneral" size="69" /></td>
                    </tr>

                    <tr  id="trlclroots" style="display:none">

                        <td class="gridTableColummHeader">Local Root:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                            <div id="lclrootdiv">
                                <select name="lclroot" id="lclroot" onchange="lclRootChange(this)" style="WIDTH:95%;"/>
                                <%
                                String localKey = "";
                                String initlclfldr = "";
                                for(int i=0; i<lclConnections.size(); i++){
                                    localKey = lclConnections.get(i).getDisplayName();
                                    String val = lclConnections.get(i).getPath();
                                    if(initlclfldr.length() == 0){
                                        initlclfldr = val;
                                    }
                                %>
                                    <option value="<%ar.writeHtml(val); %>" /><%ar.writeHtml(localKey); %></option>
                                <%}%>
                                </select>
                                <input type="hidden" name="localRoot" id="localRoot" value="<%ar.writeHtml(localKey); %>" />
                            </div>
                        </td>
                    </tr>
                    <tr  id="trlclfolder" style="display:none">
                        <td class="gridTableColummHeader">Local Folder:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                            <div id="lclfolderdiv">
                                <input type="text" name="lclfldr" id="lclfldr" value="<%ar.writeHtml(initlclfldr); %>" style="WIDTH:95%" />
                            </div>
                        </td>
                    </tr>

                    <tr id="trcvsroots" style="display:none">
                        <td class="gridTableColummHeader">CVS Root:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                            <div id="cvsrootdiv">
                                <select name="cvsroot" id="cvsroot" onchange="cvsRootChange(this)" style="WIDTH:95%;"/>
                                <%
                                String initroot = "";
                                String initmodule = "";
                                for(int i=0; i<cvsConnections.size(); i++){
                                    String cvsKey = cvsConnections.get(i).getRoot();
                                    String val = cvsConnections.get(i).getRepository();
                                    if(initroot.length() == 0){
                                        initroot = cvsKey;
                                        initmodule = val;
                                    }
                                %>
                                <option value="<%ar.writeHtml(val); %>" /><%ar.writeHtml(cvsKey); %></option>
                                <%}%>
                                </select>
                                <input type="hidden" name="cvsserver" id="cvsserver" value="<%ar.writeHtml(initroot);%>" />
                            </div>
                        </td>
                    </tr>

                    <tr id="trcvsmodule" style="display:none">
                        <td class="gridTableColummHeader">CVS Module:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                            <div id="cvsmodulediv">
                                <input type="text" name="cvsmodule" id="cvsmodule" value="<%ar.writeHtml(initmodule);%>" style="WIDTH:95%;" />
                            </div>
                        </td>
                    </tr>

                    <tr><td style="height:5px"></td></tr>
                    <tr id="truid">
                        <td class="gridTableColummHeader">User Id:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2"><input type="text" name="uid" id="uid" class="inputGeneral" size="69" /></td>
                    </tr>
                    <tr><td style="height:5px"></td></tr>
                    <tr id="trpwd">
                        <td class="gridTableColummHeader">Password:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2"><input type="password" id="pwd" name="pwd" value="" size="30" class="inputGeneral" /></td>
                    </tr>
                    <tr><td style="height:30px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td>
                            <input type="submit" class="btn btn-primary btn-raised"
                                value="<fmt:message key="nugen.button.repository.createnewconnection" />">
                        </td>
                    </tr>
                </table>
            </form>
        </div>
    </div>
</div>
</div>
</div>

<script type="text/javascript">
    function cvsRootChange(obj){
        document.getElementById("cvsmodule").value = obj.value;
        document.getElementById("cvsserver").value = obj.name;
    }


    function changeForm(obj)
    {
        var checkboxVal = obj.value
        if(checkboxVal == 'WEBDAV' || checkboxVal == 'SMB'){
            document.getElementById("createConnection").serverpath.value='';
            document.getElementById("trspath").style.display='';
            document.getElementById("truid").style.display='';
            document.getElementById("trpwd").style.display='';
            document.getElementById("trlclroots").style.display='none';
            document.getElementById("trlclfolder").style.display='none';
            document.getElementById("trcvsroots").style.display='none';
            document.getElementById("trcvsmodule").style.display='none';
        }else if(checkboxVal == 'CVS'){
            document.getElementById("trcvsroots").style.display='';
            document.getElementById("trcvsmodule").style.display='';
            document.getElementById("truid").style.display='';
            document.getElementById("trpwd").style.display='';
            document.getElementById("trspath").style.display='none';
            document.getElementById("trlclroots").style.display='none';
            document.getElementById("trlclfolder").style.display='none';
            document.getElementById("createConnection").serverpath.value='cvs';
        }
        else{
            document.getElementById("trlclroots").style.display='';
            document.getElementById("trlclfolder").style.display='';
            document.getElementById("trspath").style.display='none';
            document.getElementById("truid").style.display='none';
            document.getElementById("trpwd").style.display='none';
            document.getElementById("trcvsroots").style.display='none';
            document.getElementById("trcvsmodule").style.display='none';
            document.getElementById("createConnection").serverpath.value='local';
        }
    }
    function lclRootChange(obj){
        document.getElementById("lclfldr").value = obj.value;
        var lclrootObj = document.getElementById("lclroot");
        var index = document.getElementById("lclroot").selectedIndex;
        document.getElementById("localRoot").value =  lclrootObj.options[index].text;
    }
</script>
