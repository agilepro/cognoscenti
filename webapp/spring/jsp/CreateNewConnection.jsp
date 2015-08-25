<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.dms.CVSConfig"
%><%@page import="org.socialbiz.cog.dms.LocalFolderConfig"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%
/*
Required parameter:


Optional Parameters:

    1. aid          : This is the attachment id which gives details about attachment in case that attachment
                      is already exsist butgives error while synchronising it.
*/

    String p = ar.reqParam("pageId");
    String aid = ar.defParam("aid", null);


    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(p);

    UserProfile uProf = ar.getUserProfile();
    AttachmentRecord attachment = ngp.findAttachmentByID(aid);
    String name     = attachment.getDisplayName();
    String pageTitle = "Create new connection for repository";

    Vector<CVSConfig> cvsConnections =  FolderAccessHelper.getCVSConnections();
    Vector<LocalFolderConfig> lclConnections =  FolderAccessHelper.getLoclConnections();
%>
    <div>
        <div class="pageHeading">
            Create New Connection
        </div>
        <div class="pageSubHeading">
            Use this form to create a new connection to store the project document in the repository.
        </div>
        <div class="generalContent">
            <form name="createConnection" id="createConnection" action="createConnectionToPushDoc.form" method="post">
                <input type="hidden" name="action" value="createConnection"/>
                <input type="hidden" name="fid" id="fid" value="CREATE">
                <input type="hidden" name="aid" value="<%ar.writeHtml(aid);%>">
                <table border="0px solid red" class="linkWizard">
                    <tr><td style="height:40px"></td></tr>
                    <tr>
                        <td colspan="3" class="linkWizardHeading">To attach the document </td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td colspan="3" class="linkWizardContent"><% ar.writeHtml(name); %></td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td colspan="3" class="linkWizardHeading">New WebDAV Connection Settings:</td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td class="linkWizardContent">Protocol:</td>
                        <td  style="width:20px;"></td>
                        <td colspan="2">
                            <input type="radio" name="ptc" id="ptc" value="CVS" onClick="changeForm(this)" /> CVS
                            <input type="radio" name="ptc" id="ptc" value="WEBDAV" checked="checked" onClick="changeForm(this)"/> SharePoint
                            <input type="radio" name="ptc" id="ptc" value="SMB" onClick="changeForm(this)"/> NetWorkShare
                            <input type="radio" name="ptc" id="ptc" value="LOCAL" onClick="changeForm(this)"/> Local
                        </td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td class="linkWizardContent">Connection Name:</td>
                        <td  style="width:20px;"></td>
                        <td colspan="2"><input type="text" name="displayname" id="fname" class="inputGeneral" size="69" /></td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr id="trspath">
                        <td class="linkWizardContent">URL:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2"><input type="text" name="serverpath" id="path" class="inputGeneral" size="69" /></td>
                    </tr>

                    <tr  id="trlclroots" style="display:none">

                        <td class="linkWizardContent">Local Root:</td>
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
                        <td class="linkWizardContent">Local Folder:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                            <div id="lclfolderdiv">
                                <input type="text" name="lclfldr" id="lclfldr" value="<%ar.writeHtml(initlclfldr); %>" style="WIDTH:95%" />
                            </div>
                        </td>
                    </tr>

                    <tr id="trcvsroots" style="display:none">
                        <td class="linkWizardContent">CVS Root:</td>
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
                        <td class="linkWizardContent">CVS Module:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                            <div id="cvsmodulediv">
                                <input type="text" name="cvsmodule" id="cvsmodule" value="<%ar.writeHtml(initmodule);%>" style="WIDTH:95%;" />
                            </div>
                        </td>
                    </tr>

                    <tr><td style="height:15px"></td></tr>
                    <tr id="truid">
                        <td class="linkWizardContent">User Id:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2"><input type="text" name="uid" id="uid" class="inputGeneral" size="69" /></td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr id="trpwd">
                        <td class="linkWizardContent">Password:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2"><input type="password" id="pwd" name="pwd" value="" size="30" class="inputGeneral" /></td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td class="linkWizardContent"></td>
                        <td style="width:20px;"></td>
                        <td>
                            <input type="submit" class="btn btn-primary"
                                value="<fmt:message key="nugen.button.repository.createnewconnection" />">
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
