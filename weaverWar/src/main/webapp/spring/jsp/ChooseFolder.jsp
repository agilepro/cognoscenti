<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%/*
Required parameter:

    1. p        : This is the id of a Workspace and used to retrieve NGWorkspace.
    2. folderId : This is connection id which is used to get Connection details.
    3. path     : This is folder path while browsing file inside repository through a connection
    4. aid      : This is the attachment id through which we get details about attachment


*/

    String p = ar.reqParam("pageId");
    String folderId = ar.reqParam("folderId");
    String path     = ar.reqParam("path");
    String aid     = ar.defParam("aid","");
    String fndDefLoctn    = ar.reqParam("fndDefLoctn");%>
    <div class="generalArea">
        <%
        NGPageIndex ngpi = ar.getCogInstance().getWSByCombinedKey(p);
        if (ngpi==null) {
            ngpi = ar.getCogInstance().lookForWSBySimpleKeyOnly(p);
        }
        if (ngpi==null) {
            throw new Exception("Old JSP unable to find page for "+p);
        }
        NGWorkspace page = ngpi.getWorkspace();
                FolderAccessHelper fdh = new FolderAccessHelper(ar);
                ResourceEntity ent = fdh.getRemoteResource(folderId, path, true);


                String projectLink = ar.retPath + "t/" + ngPage.getSite().getKey() + "/" +ngPage.getKey();

                String curntFolderLnk = "";

                if(fndDefLoctn.equals("true"))
                {
            curntFolderLnk = projectLink
                + "/AdminSettings.htm?selectedFolder="+URLEncoder.encode(ent.getSymbol(), "UTF-8")
                +"&encodingGuard=%E6%9D%B1%E4%BA%AC";

                }else
                {
            curntFolderLnk = projectLink
               + "/pushToRepository.htm?aid="+ aid
               +"&folderId="+folderId
               +"&path="+URLEncoder.encode(path, "UTF-8")
               +"&encodingGuard=%E6%9D%B1%E4%BA%AC";

                }
        %>
        <div class="pageHeading">Browse folders to store your document of
            <a href="<%ar.writeHtml(projectLink);%>/frontPage.htm"><%ar.writeHtml(ngPage.getFullName()); %></a>
        </div><br>
        <%
        showHeader(ar, ent, ngPage, folderId, aid, fndDefLoctn);
        %>
        <div class="generalSettings">
            <table class="gridTable2" width="100%">
                <tr class="gridTableHeader">
                    <td width="80px">Select Folder</td>
                    <td width="350px">Name</td>
                    <td>Modified On</td>
                </tr>
                <tr>
                    <td colspan="3" style="font-weight: bold;">
                        <a href="<%=curntFolderLnk %>">
                            <img allign="absbottom" src="<%=ar.retPath %>assets/selectFolder.jpg"
                                title="Select Folder">
                        </a> <%ar.writeHtml(ent.getDecodedName()); %>
                    </td>
                </tr>
        <%

        for (ResourceEntity entity : ent.getChidEntityList())
        {
            if (!entity.isFile())
            {
                String selectLink ="";
                String sfdLink = "";
                if(fndDefLoctn.equals("true"))
                {
                    selectLink = projectLink
                    + "/AdminSettings.htm?selectedFolder="+URLEncoder.encode(entity.getSymbol(), "UTF-8")
                    +"&encodingGuard=%E6%9D%B1%E4%BA%AC";

                    sfdLink = projectLink
                     + "/ChooseFolder.htm?path="
                     + URLEncoder.encode(entity.getPath(), "UTF-8")
                     +"&folderId="+folderId
                     +"&fndDefLoctn=true&encodingGuard=%E6%9D%B1%E4%BA%AC";

                }else
                {
                    selectLink = projectLink
                       + "/pushToRepository.htm?aid="+ aid
                       +"&folderId="+folderId
                       +"&path="+URLEncoder.encode(entity.getPath(), "UTF-8")
                       +"&encodingGuard=%E6%9D%B1%E4%BA%AC";

                    sfdLink = projectLink
                        + "/ChooseFolder.htm?path="
                        + URLEncoder.encode(entity.getPath(), "UTF-8")
                        +"&folderId="+folderId
                        +"&aid="+aid
                        +"&encodingGuard=%E6%9D%B1%E4%BA%AC";
                }

                String cdname = getShortName(entity.getDecodedName(), 36);
            %>
                <tr>
                    <td width="80px" align="center">
                        <a href="<%=selectLink %>">
                            <img allign="absbottom" src="<%=ar.retPath %>assets/selectFolder.jpg" title="Select Folder">
                        </a>
                    </td>
                    <td class="repositoryName"><a href="<%=sfdLink%>"><%=cdname%></a></td>
                    <td><%SectionUtil.nicePrintTime(ar.w, entity.getLastModifed(), ar.nowTime); %></td>
                </tr>
            <%}
        }%>
            </table>
        </div>
    </div>


<%@ include file="functions.jsp"%>
<%!private void showHeader(AuthRequest ar, ResourceEntity ent, NGWorkspace page, String folderId, String aid,String fndDefLoctn)
        throws Exception {

        ConnectionType cType = ent.getConnection();
        String cSetID = cType.getConnectionId();
        String projectLink = ar.retPath + "t/" + page.getSite().getKey() + "/" +page.getKey();

        String symbol = ent.getSymbol();
        String path = ent.getPath();

        //this page runs in two modes: one for default location, and another for attachment push
        //the only difference is this in the tail of the URL.
        String urlTail = "&fndDefLoctn=true&encodingGuard=%E6%9D%B1%E4%BA%AC";
        if (!fndDefLoctn.equals("true")){
            urlTail = "&encodingGuard=%E6%9D%B1%E4%BA%AC&aid="+aid;
        }

        ar.write("\n<div class=\"pageSubHeading\">");

        String connectionListPath = ar.retPath+"v/"+ar.getUserProfile().getKey()+"/ListConnections.htm?pageId="
            +page.getKey()
            +urlTail;

        ar.write("<a href=\"");
        ar.writeHtml(connectionListPath);
        ar.write("\">Connections List</a>&nbsp;&nbsp;&gt;&nbsp;&nbsp;");


        String vpath = "/";
        String dlink = projectLink+ "/ChooseFolder.htm?path="
                        + URLEncoder.encode("/", "UTF-8")
                        +"&folderId="+cSetID
                        +urlTail;

        ar.write("  <a href=\"");
        ar.writeHtml(dlink);
        ar.write("\">");
        ar.writeHtml(cType.getDisplayName());
        ar.write("</a>");

        createFolderLinksForChooser(ar, ent, projectLink+"/ChooseFolder.htm?path=", urlTail);
        ar.write("</div>");
    }

    //Recursive routine to handle variable number of parent folders
    private void createFolderLinksForChooser(AuthRequest ar, ResourceEntity ent, String urlStart, String urlTail) throws Exception
    {
        ResourceEntity parent = ent.getParent();
        if (parent!=null) {
            createFolderLinks(ar, parent);
            String dlink = urlStart + URLEncoder.encode(ent.getPath(), "UTF-8")
                    +"&folderId="+ent.getFolderId()
                    +urlTail;
            ar.write("&nbsp;&nbsp;&gt;&nbsp;&nbsp;<a href=\"");
            ar.writeHtml(dlink);
            ar.write("\">");
            ar.writeHtml(ent.getDecodedName());
            ar.write("</a>");
        }
    }%>