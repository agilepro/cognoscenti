<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. folderId : This is connection id used to retrieve the connection details.
    2. path     : This represents the path of the current folder of repository which is displayed

Optional Parameters:

    1. p :  This is workspace key which should be null
*/

    String folderId = ar.reqParam("folderId");
    String path     = ar.reqParam("path");

%><%
    FolderAccessHelper fdh = new FolderAccessHelper(ar);

    ar.write("<!-- path is ");
    ar.writeHtml(path);
    ar.write("-->");

    ResourceEntity folderEntity = fdh.getRemoteResource(folderId, path, true);
    String symbol = folderEntity.getSymbol();

    String pageTitle  = "Display Folder "+folderEntity.getDecodedName();
    displayFolderForUser(ar,folderEntity);
%>
<script type="text/javascript">

    function openModalDialogue(popupId,headerContent,panelWidth){
        var   header = headerContent;
        var bodyText= document.getElementById(popupId).innerHTML;
        createPanel(header, bodyText, panelWidth);
        myPanel.beforeHideEvent.subscribe(function() {
            if(!isConfirmPopup){
                window.location = "folderDisplay.htm";
            }
        });
    }

     function cancelPanel(){
        myPanel.hide();
        return false;
    }

    function deleteFileorFolder(fid,msg){
       if(confirm(msg))
       {
           document.getElementById('fidValue').value=fid;
           document.getElementById("folderDisplay").submit();
           return true;
       }else{
           return false;
       }
    }

</script>

<body class="yui-skin-sam">
    <div id="AddFile" style="border:1px solid red;display: none;">
        <div class="generalSettings">
            <form name="folderForm" id="folderForm" action="addFileAction.form" method="post"
                        enctype="multipart/form-data">
                <input type="hidden" id="fid" name="fid" value="<%ar.writeHtml(symbol); %>">
                <input type="hidden" name="go" value="<%ar.writeHtml(ar.getCompleteURL());%>"/>
                <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
                <input type="hidden" name="action" value="Create New"/>
                <table border="0px solid red" class="popups">
                    <tr>
                        <td width="148" class="gridTableColummHeader">Local File Path:</td>
                        <td  style="width:20px;"></td>
                        <td colspan="2"><input type="file" name="fname" value="" id="fname" class="inputGeneral"/></td>
                    </tr>
                    <tr><td style="height:30px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                            <input type="submit" class="btn btn-primary btn-raised"
                                value="<fmt:message key="nugen.button.repository.addfile" />" >
                            <input type="hidden" name="action" value="Create New">
                            <input type="button" class="btn btn-primary btn-raised"
                                value="<fmt:message key="nugen.button.general.cancel" />"
                                onclick="return cancelPanel();">
                        </td>
                    </tr>
                </table>
            </form>
        </div>
    </div>
    <div id="AddFolder" style="border:1px solid red;display: none;">
        <div class="generalSettings">
            <form name="addFolderForm" id="addFolderForm" action="folderAction.form" method="POST">
                <input type="hidden" name="fid" value="<%ar.writeHtml( symbol );%>">
                <input type="hidden" name="go" value="<%ar.writeHtml(ar.getCompleteURL());%>"/>
                <input type="hidden" name="action" value="CreateSub"/>
                <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
                <table border="0px solid red" class="popups">
                    <tr>
                        <td width="148" class="gridTableColummHeader">Folder Name</td>
                        <td  style="width:20px;"></td>
                        <td colspan="2"><%ar.writeHtml(folderEntity.getDecodedName()); %></td>
                    </tr>
                    <tr><td style="height:5px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader">Sub Folder Name:</td>
                        <td  style="width:20px;"></td>
                        <td colspan="2"><input type="text" name="subFolderName" value="" id="subFolderName"/></td>
                    </tr>
                    <tr><td style="height:30px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                           <input type="submit" class="btn btn-primary btn-raised"
                                value="<fmt:message key="nugen.button.repository.addfolder" />" >
                            <input type="hidden" name="action" value="CreateSub">
                           <input type="button" class="btn btn-primary btn-raised"
                                value="<fmt:message key="nugen.button.general.cancel" />"
                                onclick="return cancelPanel();">
                        </td>
                    </tr>
                </table>
            </form>
        </div>
    </div>
</body>
<%@ include file="functions.jsp"%>
<%!

    public void displayFolderForUser(AuthRequest ar,ResourceEntity folderEntity) throws Exception
    {
        FolderAccessHelper fdh = new FolderAccessHelper(ar);
        List<ResourceEntity> entityList = folderEntity.getChidEntityList();
        ConnectionType cType = folderEntity.getConnection();

        ar.write("<div class=\"generalArea\">");
        ar.write("\n<div class=\"pageHeading\">");
        ar.writeHtml(cType.getDisplayName());
        ar.write("</div>");
        ar.write("\n<div class=\"rightDivContent\"><img src=\"");
        ar.write(ar.retPath);
        ar.write("assets/iconUploadFile.gif\" alt=\"\" /> <a href=\"#\" onclick=\"openModalDialogue('AddFile','Add File','500px');\">Upload Documents</a>&nbsp;&nbsp;<img src=\"");
        ar.write(ar.retPath);
        ar.write("assets/iconAddSubtask.gif\" alt=\"\" /> <a href=\"#\" onclick=\"openModalDialogue('AddFolder','Add Folder','500px');\">Add Folder</a></div>");
        displayHeader(ar, folderEntity, null);
        ar.write("\n<div class=\"generalSettings\">");
        ar.write("\n<form name=\"folderDisplay\" id=\"folderDisplay\" action=\"folderAction.form\" method=\"post\">");
        ar.write("\n<input type=\"hidden\" name=\"fid\" id=\"fidValue\" value=\"\">");
        ar.write("\n<input type=\"hidden\" name=\"action\" value=\"Delete\">");
        ar.write("\n<input type=\"hidden\" name=\"encodingGuard\" value=\"");
        ar.writeHtml("\u6771\u4eac");
        ar.write("\"/>");
        ar.write("\n<input type=\"hidden\" name=\"go\" value=\"");
        ar.writeHtml(ar.getCompleteURL());
        ar.write("\">");
        ar.write("\n<table class=\"gridTable2\" width=\"100%\">");
        ar.write("\n<tr class=\"gridTableHeader\">");
        ar.write("\n<td width=\"20px\">Type</td>");
        ar.write("\n<td width=\"350px\">Name</td>");
        ar.write("\n<td>Size</td>");
        ar.write("\n<td>Modified On</td>");
        ar.write("\n<td>Modified By</td>");
        ar.write("\n<td>Delete</td>");
        ar.write("\n</tr>");

        List<ResourceEntity> fileList = new ArrayList<ResourceEntity>();
        for (ResourceEntity entity : entityList)
        {
            if (entity.isFile())
            {
                fileList.add(entity);
                continue;
            }
            String sfdLink = ar.retPath+ "v/"+ ar.getUserProfile().getKey()+ "/folder"+entity.getFolderId()
                +".htm?path=" + URLEncoder.encode(entity.getPath()+"/", "UTF-8")
                +"&encodingGuard=%E6%9D%B1%E4%BA%AC";

            String cdname = getShortName(entity.getDecodedName(), 36);

            ar.write("\n<tr>");
            ar.write("\n<td width=\"20px\"><img src=\"");
            ar.write(ar.retPath);
            ar.write("assets/iconFolder.gif\" alt=\"\" /></td>");
            ar.write("\n<td class=\"repositoryName\"><a <a href=\"");
            ar.writeHtml(sfdLink);
            ar.write(" \"");
            writeTitleAttribute(ar, entity.getName(), 36);
            ar.write(">");
            ar.writeHtml(cdname);
            ar.write("</a></td>");
            ar.write("\n<td></td>");
            ar.write("\n<td>");
            SectionUtil.nicePrintTime(ar.w, entity.getLastModifed(), ar.nowTime);
            ar.write("</td>");
            ar.write("\n<td></td>");

            String symbol = entity.getSymbol();
            String fdmsg = "Are you sure you want to delete the folder: "
                    + entity.getDecodedName();
            ar.write("\n<td><input type=\"image\" src=\"");
            ar.write(ar.retPath);
            ar.write("assets/iconDelete.gif\" onclick=\"return deleteFileorFolder('");
            ar.writeHtml(symbol);
            ar.write("','");
            ar.writeHtml(fdmsg);
            ar.write("');\"></td>");
            ar.write("\n</tr>");

        }

        for (ResourceEntity fileEnt : fileList)
        {
            ar.write("\n<!--");
            ar.writeHtml(fileEnt.getPath());
            ar.write("-->");
            ar.write("\n<!--");
            ar.writeHtml(fileEnt.getDecodedName());
            ar.write("-->");
            ar.write("\n<!--");
            ar.writeHtml(fileEnt.getDisplayName());
            ar.write("-->");

            String contentLink = ar.retPath + "v/"+ar.getUserProfile().getKey()
                    +"/f"+fileEnt.getFolderId()
                    +"/remote.htm?path=" + URLEncoder.encode(fileEnt.getPath(), "UTF-8")
                    +"&encodingGuard=%E6%9D%B1%E4%BA%AC";
            String cfdname = getShortName(fileEnt.getDecodedName(), 36);

            String symbol = fileEnt.getSymbol();
            String dfdmsg = "Are you sure you want to delete the file: "
                    + fileEnt.getDecodedName();

            ar.write("\n<tr>");
            ar.write("\n<td width=\"20px\"><img src=\"");
            ar.write(ar.retPath);
            ar.write("assets/images/iconFile.png\" alt=\"\" /></td>");
            ar.write("\n<td class=\"repositoryName\"><a href=\"");
            ar.writeHtml(contentLink);
            ar.write("\"");
            writeTitleAttribute(ar, fileEnt.getName(), 36);
            ar.write(">");
            ar.writeHtml(cfdname);
            ar.write("</a></td>");
            ar.write("\n<td>");
            ar.write(Long.toString((long) (fileEnt.getSize() + 500) / 1000));
            ar.write(" KB</td>");
            ar.write("\n<td>");
            SectionUtil.nicePrintTime(ar.w, fileEnt.getLastModifed(), ar.nowTime);
            ar.write("</td>");
            ar.write("\n<td></td>");
            ar.write("\n<td><input type=\"image\" src=\"");
            ar.write(ar.retPath);
            ar.write("assets/iconDelete.gif\" onclick=\"return deleteFileorFolder('");
            ar.writeHtml(symbol);
            ar.write("','");
            ar.writeHtml(dfdmsg);
            ar.write("');\"></td>");
            ar.write("\n</tr>");

        }

        ar.write("\n</table>");
        ar.write("\n</form>");
        ar.write("\n</div>");
        ar.write("\n</div>");
    }
%>

<%!

    private void displayHeader(AuthRequest ar, ResourceEntity ent, NGWorkspace page)throws Exception {

        ConnectionType cType = ent.getConnection();
        String  cSetID = cType.getConnectionId();

        //first link is to the 'home' where you get a list of all your connections
        ar.write("\n<div class=\"pageSubHeading\">");
        if(page==null){
            ar.write("<a href=\"");
            String userHomePath = ar.retPath+"v/"+ar.getUserProfile().getKey()+"/userProfile.htm?active=3";
            ar.writeHtml(userHomePath);
            ar.write("\">Connections</a>&nbsp;&nbsp;&gt;&nbsp;&nbsp;");
        }

        //second link is to the connection you are looking at currently
        String dlink = ar.retPath + "v/"+ ar.getUserProfile().getKey() + "/folder"+cSetID
                +".htm?path=%2F&encodingGuard=%E6%9D%B1%E4%BA%AC";
        ar.write("  <a href=\"");
        ar.writeHtml(dlink);
        ar.write("\">");
        ar.writeHtml(cType.getDisplayName());
        ar.write("</a>");

        //Now make a chain of links to all folders containing this one
        createFolderLinks(ar, ent);
        ar.write("</div>");
    }

%>