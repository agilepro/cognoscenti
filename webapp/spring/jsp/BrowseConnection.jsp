<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameter:

    1. p        : This is the id of a Workspace and used to retrieve NGPage.
    2. folderId : This is connection id which is used to get Connection details.
    3. path     : This is folder path while browsing file inside repository through a connection


*/

    String p = ar.reqParam("p");
    String folderId = ar.reqParam("folderId");
    String path     = ar.reqParam("path");

    FolderAccessHelper fdh = new FolderAccessHelper(ar);
    String pageTitle  = "Display Folder";
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


</script>
<%
    String dname = null;
    dname = displayRepositoryFolderQ(ar,folderId, path, p);
    session.setAttribute("lastPath", path);
    session.setAttribute("connectionId",folderId);
%>
<%@ include file="functions.jsp"%>
<%!public String displayRepositoryFolderQ(AuthRequest ar,String folderId, String path, String p) throws Exception
    {
        NGPageIndex ngpi = ar.getCogInstance().getWSByCombinedKey(p);
        if (ngpi==null) {
            ngpi = ar.getCogInstance().lookForWSBySimpleKeyOnly(p);
        }
        if (ngpi==null) {
            throw new Exception("Old JSP unable to find page for "+p);
        }
        NGPage page = ngpi.getWorkspace();
        String go = ar.getCompleteURL();
        FolderAccessHelper fdh = new FolderAccessHelper(ar);
        ResourceEntity ent = fdh.getRemoteResource(folderId, path, true);
        if (!ent.isFilled()) {
            throw new ProgramLogicError("Something went wrong, resource entity is not initialized");
        }
        String dname = ent.getDisplayName();
        List<ResourceEntity> entityList = ent.getChidEntityList();

        String fdname = ent.getDisplayName();
        int indx2 = fdname.indexOf('/');
        if (indx2 > 0)
        {
            fdname = fdname.substring(0, indx2);
        }
        String projectLink = ar.retPath + "t/" + page.getSite().getKey() + "/" +page.getKey() + "/frontPage.htm";

        ar.write("<div class=\"generalArea\">");
        ar.write("\n<div class=\"pageHeading\">");
        ar.write("\n Browse repository to find document to attach to <a href=\"");
        ar.writeHtml(projectLink);
        ar.write("\">");
        ar.writeHtml(page.getFullName());
        ar.write("</a>");
        ar.write("</div>");
        showHeader(ar, ent, page);
        ar.write("\n<div class=\"generalSettings\">");
        ar.write("\n<table class=\"gridTable2\" width=\"100%\">");
        ar.write("\n<tr class=\"gridTableHeader\">");
        ar.write("\n<td width=\"20px\">Type</td>");
        ar.write("\n<td>Attach File</td>");
        ar.write("\n<td width=\"350px\">Name</td>");
        ar.write("\n<td>Size</td>");
        ar.write("\n<td>Modified On</td>");
        ar.write("\n</tr>");

        List<ResourceEntity> fileList = new ArrayList();
        for (ResourceEntity entity : entityList)
        {
            ar.write("\n<!-- Time1: "+(new Date()).toString()+"-->");
            if (entity.isFile())
            {
                fileList.add(entity);
                continue;
            }

            String sfdLink = ar.retPath + "v/" + ar.getUserProfile().getKey()
                    + "/BrowseConnection" + folderId + ".htm?path="
                    + URLEncoder.encode(entity.getPath(), "UTF-8")
                    + "&p=" + URLEncoder.encode(p, "UTF-8")
                    +"&encodingGuard=%E6%9D%B1%E4%BA%AC";

            String cdname = getShortName(entity.getDecodedName(), 36);

            ar.write("\n<tr>");
            ar.write("\n<td width=\"20px\"><img src=\"");
            ar.write(ar.retPath);
            ar.write("assets/iconFolder.gif\" alt=\"\" /></td>");
            ar.write("\n<td></td>");
            ar.write("\n<td class=\"repositoryName\"><a href=\"");
            ar.writeHtml(sfdLink);
            ar.write(" \"");
            writeTitleAttribute(ar, entity.getDecodedName(), 36);
            ar.write(">");
            ar.writeHtml(cdname);
            ar.write("</a></td>");
            ar.write("\n<td></td>");
            ar.write("\n<td>");
            SectionUtil.nicePrintTime(ar.w, entity.getLastModifed(), ar.nowTime);
            ar.write("</td>");
            ar.write("\n</tr>");
        }

        UserPage up = ar.getUserPage();

        for (ResourceEntity fileEnt : fileList)
        {
            ar.write("\n<!-- Time2: "+(new Date()).toString()+"-->");
            boolean isAttached = checkAttachedFiles(ar, up, fileEnt, page);

            String contentLink = ar.retPath + "v/"+ar.getUserProfile().getKey()
                    +"/f"+fileEnt.getFolderId()
                    +"/remote.htm?path=" + URLEncoder.encode(fileEnt.getPath(), "UTF-8");

            String cfdname = getShortName(fileEnt.getDecodedName(), 36);

            ar.write("\n<tr>");
            ar.write("\n<td width=\"20px\"><img src=\"");
            ar.write(ar.retPath);
            ar.write("assets/images/iconFile.png\" alt=\"\" /></td>");
            if(! isAttached)
            {
                String attchLink = ar.retPath+"t/"+page.getSite().getKey()+"/"+page.getKey()
                        + "/linkRepository.htm?p="
                        + URLEncoder.encode(p,"UTF-8")
                        + "&symbol=" + URLEncoder.encode(fileEnt.getSymbol(), "UTF-8")
                        + "&action=" + URLEncoder.encode("Attach", "UTF-8");

                ar.write("\n<td><a href=\"");
                ar.writeHtml(attchLink);
                ar.write("\"><img src=\"");
                ar.write(ar.retPath);
                ar.write("assets/images/updateAttachmentIcon.gif\" title=\"Attach File\">Attach File");
                ar.write("</a></td>");
            }
            else
            {
                ar.write("<td>Already</td>");
            }
            ar.write("\n<td class=\"repositoryName\"><a href=\"");
            ar.writeHtml(contentLink);
            ar.write("\"");
            writeTitleAttribute(ar, fileEnt.getDecodedName(), 36);
            ar.write(">");
            ar.writeHtml(cfdname);
            ar.write("</a></td>");
            ar.write("\n<td>");
            ar.write(Long.toString((long) (fileEnt.getSize() + 500) / 1000));
            ar.write(" KB</td>");
            ar.write("\n<td>");
            SectionUtil.nicePrintTime(ar.w, fileEnt.getLastModifed(), ar.nowTime);
            ar.write("</td>");

            ar.write("\n</tr>");
        }

        ar.write("\n</table>");
        ar.write("\n</div>");
        ar.write("\n</div>");

        return dname;
    }

    public boolean checkAttachedFiles(AuthRequest ar, UserPage up, ResourceEntity remoteFile, NGPage ngp)throws Exception{
        String userPKey = ar.getUserProfile().getKey();
        String rlink = userPKey + "@" + remoteFile.getSymbol();
        String fileFullPath = remoteFile.getFullPath();
        for(AttachmentRecord aRecord : ngp.getAllAttachments()){
            if (!aRecord.hasRemoteLink()) {
                continue;
            }
            if (aRecord.isDeleted()) {
                continue;
            }
            //Not sure what this was about or what arLink represented
            //commented out here becausae JSP does not compile with it in.
            //if(rlink.equals(arLink)) {
            //    return true;
            //}
            if (fileFullPath.equals(aRecord.getRemoteFullPath())) {
                return true;
            }
        }
        return false;
    }


    private void showHeader(AuthRequest ar, ResourceEntity ent, NGPage page)throws Exception {

        String symbol = ent.getSymbol();
        String path = ent.getPath();

        String fdname = ent.getDisplayName();
        int indx2 = fdname.indexOf('/');
        if (indx2 > 0) {
            fdname = fdname.substring(0, indx2);
        }


        ar.write("\n<div class=\"pageSubHeading\">");

        ar.write("<a href=\"");
        String connectionListPath = ar.retPath+"v/"+ar.getUserProfile().getKey()+"/ListConnections.htm?pageId="+page.getKey();
        ar.writeHtml(connectionListPath);
        ar.write("\">Connections List</a>&nbsp;&nbsp;&gt;&nbsp;&nbsp;");


        String dname = fdname;
        String vpath = "/";
        String dlink = ar.retPath + "v/"+ ar.getUserProfile().getKey() + "/BrowseConnection"+ent.getFolderId()+".htm?path="
                            + URLEncoder.encode(vpath, "UTF-8")
                            +"&p="+page.getKey();
        ar.write("  <a href=\"");
        ar.writeHtml(dlink);
        ar.write("\">");
        ar.writeHtml(dname);
        ar.write("</a>");

        if (symbol != null) {
            StringTokenizer st = new StringTokenizer(path, "/");
            while (st.hasMoreTokens()) {
                String tok = st.nextToken();
                vpath = vpath + tok + "/";
                dlink = ar.retPath + "v/"+ ar.getUserProfile().getKey() + "/BrowseConnection"+ent.getFolderId()+".htm?path="
                            + URLEncoder.encode(vpath, "UTF-8")
                            +"&p="+page.getKey();
                ar.write("&nbsp;&nbsp;&gt;&nbsp;&nbsp;<a href=\"");
                ar.writeHtml(dlink);
                ar.write("\">");
                ar.writeHtml(tok);
                ar.write("</a>");
            }
        }
        ar.write("</div>");
    }%>