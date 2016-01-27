<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page errorPage="error.jsp"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Must be logged in to display the document repositories.");
    String symbol      = ar.defParam("symbol", null);
    String pageId = ar.defParam("p", "");
    pageTitle  = "Display Folder";
%>

<%@ include file="Header.jsp"%>

<%
    if (pageId != null && pageId.length()>0){
        if(symbol == null || symbol.length()==0){
            ar.write("\n<h3>Select a repository to browse within.</h3>");
            ar.write("\n<br/>");
            displayRepositoryList(ar, pageId);
        }else{
            ar.write("\n<h3>Browse to find the document in the repository.</h3>");
            ar.write("\n<br/>");
            displayRepositoryFolder(ar,symbol, pageId);
        }
    }else{
        displayFolderX(ar,symbol);
    }
%>


<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
<%!

     public void displayRepositoryFolder(AuthRequest ar,String combo, String pageId) throws Exception {
        try {
            Writer out = ar.w;
            String go = ar.getCompleteURL();
            FolderAccessHelper fdh = new FolderAccessHelper(ar);
            ResourceEntity ent = fdh.getResourceEntity(combo, true);
            List<ResourceEntity> entityList = ent.getChidEntityList();

            ar.write("<h3>");
            displayHeader(ar, ent, pageId);
            ar.write("</h3>");
            ar.write("<br/>");

            ar.write("<table cellpadding=\"3\" cellspacing=\"1\" width=\"650\">");
            ar.write("<col width=\"300\"/>");
            ar.write("<col width=\"200\"/>");
            ar.write("<col width=\"150\"/>");

            ar.write("\n<tr>");
            ar.write("\n   <td align=\"left\">");
            ar.write("<h3>");

            String fdLink = ar.retPath + "FolderDisplay.jsp?symbol="
                    + URLEncoder.encode(ent.getSymbol(), "UTF-8")
                    + "&p=" + URLEncoder.encode(pageId, "UTF-8")
                    + "&go=" +  URLEncoder.encode(go, "UTF-8");


            String dname = getShortName(ent.getName(), 38);

            ar.write("  <a href=\"");
            ar.writeHtml(fdLink);
            ar.write("\"");
            writeTitleAttribute(ar, ent.getName(), 38);
            ar.write("><img allign=\"absbottom\" src=\"");
            ar.write(ar.retPath);
            ar.write("ofolder.gif");
            ar.write("\">");
            ar.writeHtml(dname);
            ar.write("</a>");
            ar.write("\n   </td>");

            ar.write("\n   <td align=\"left\">");
            SectionUtil.nicePrintTime(out, ent.getLastModifed(), ar.nowTime);
            ar.write("| ");
            ar.write(Integer.toString(ent.getFileCount()));
            ar.write(" files");
            ar.write("\n   </td>");

            ar.write("\n   <td align=\"left\">");
            ar.write("\n   </td>");
            ar.write("\n</tr>");
            List<ResourceEntity> fileList = new Vector<ResourceEntity>();
            for (ResourceEntity entity : entityList) {
                if (entity.isFile()) {
                    fileList.add(entity);
                    continue;
                }
                ar.write("\n<tr>");

                ar.write("\n   <td align=\"left\">");
                ar.write("<h3>");

                String sfdLink = ar.retPath + "FolderDisplay.jsp?symbol="
                + URLEncoder.encode(entity.getSymbol(), "UTF-8")
                + "&p=" + URLEncoder.encode(pageId, "UTF-8")
                + "&go=" +  URLEncoder.encode(go, "UTF-8");


                String cdname = getShortName(
                    entity.getDecodedName(), 36);

                ar.write("&nbsp;&nbsp;&nbsp;&nbsp  <a href=\"");
                ar.writeHtml(sfdLink);
                ar.write("\"");
                writeTitleAttribute(ar, entity.getName(), 36);
                ar.write("><img allign=\"absbottom\" src=\"");
                ar.write(ar.retPath);
                ar.write("cfolder.gif");
                ar.write("\">" + cdname + "</a>");
                ar.write("\n   </td>");

                ar.write("\n   <td align=\"left\">");
                ar.write("\n   </td>");

                ar.write("\n   <td align=\"left\">");
                ar.write("\n   </td>");
                ar.write("\n</tr>");
            }

            for (ResourceEntity fileEnt : fileList) {
                ar.write("\n<tr>");

                ar.write("\n   <td align=\"left\">");
                ar.write("<h3>");

                String contentLink = ar.retPath + "v/"+ ar.getUserProfile().getKey() + "/f/remotefile.xml?fid=" + URLEncoder.encode(fileEnt.getSymbol(), "UTF-8");

                String cfdname = getShortName(fileEnt.getDecodedName(), 36);

                ar.write("&nbsp;&nbsp;&nbsp;&nbsp  <a href=\"");
                ar.writeHtml(contentLink);
                ar.write("\"");
                writeTitleAttribute(ar, fileEnt.getName(), 36);
                ar.write("><img allign=\"absbottom\" src=\"");
                ar.write(ar.retPath);
                ar.write("filenode.gif");
                ar.write("\">" + cfdname + "</a>");
                ar.write("\n   </td>");

                ar.write("\n   <td align=\"left\">");
                SectionUtil.nicePrintTime(ar.w, fileEnt.getLastModifed(), ar.nowTime);
                ar.write("&nbsp;&nbsp;&nbsp;Size: ");
                ar.write(Long.toString((long) (fileEnt.getSize() + 500) / 1000)
                        + "KB");
                ar.write("\n   </td>");

                ar.write("\n   <td align=\"left\">");

                ar.write("&nbsp;&nbsp;");

                ar.write("&nbsp;&nbsp;");

                boolean isAttached = isAttached(ar, fileEnt, pageId);

                if(! isAttached){
                    String attchLink = ar.retPath
                    + "createRemoteAttachment.jsp?p="
                    + URLEncoder.encode(pageId,"UTF-8")
                    + "&fid="
                    + URLEncoder.encode(fileEnt.getSymbol(), "UTF-8")
                    + "&action=" + URLEncoder.encode("Attach", "UTF-8")
                    + "&go=" + URLEncoder.encode(go, "UTF-8");



                    ar.write("  <a href=\"");
                    ar.writeHtml(attchLink);
                    ar.write("\"><img allign=\"absbottom\" src=\"");
                    ar.write(ar.retPath);
                    ar.write("ts_attachment.gif\" title=\"Attach\">");
                    ar.write("</a>");
                }else{
                    ar.write("Already Attached");
                }
            }
            ar.write("\n   </td>");
            ar.write("\n</tr>");

            ar.write("\n</table>");
            ar.write("<br/><br/>");

        } catch (Exception e) {
            throw new Exception("Unable to display repository folder '"+combo+"'", e);
        }
    }

    public boolean isAttached(AuthRequest ar, ResourceEntity fileEnt, String pageId)throws Exception{
        String fullPath = fileEnt.getFullPath();
        NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
        for (AttachmentRecord aRecord : ngp.getAllAttachments()){
            if(!aRecord.isDeleted()) {
                RemoteLinkCombo rlc = aRecord.getRemoteCombo();
                ResourceEntity attachedFile = rlc.getResource();
                String attachedFullPath = attachedFile.getFullPath();
                if (attachedFullPath.equals(fullPath)) {
                    return true;
                }
            }
        }
        return false;
    }

       public void displayFolderX(AuthRequest ar,String combo) throws Exception {
        try {
            Writer out = ar.w;
            String go = ar.getCompleteURL();
            FolderAccessHelper fdh = new FolderAccessHelper(ar);
            int slashPos = combo.indexOf("/");
            if (slashPos<0) {
                //not sure why this patch is needed
                combo = combo + "/";
            }
            ResourceEntity ent = fdh.getResourceEntity(combo, true);
            List<ResourceEntity> entityList = ent.getChidEntityList();

            ar.write("<h3>");
            displayHeader(ar, ent, null);
            ar.write("</h3>");
            ar.write("<br/>");

            ar.write("<table cellpadding=\"3\" cellspacing=\"1\" width=\"850\">");
            ar.write("<col width=\"500\"/>");
            ar.write("<col width=\"200\"/>");
            ar.write("<col width=\"150\"/>");

            ar.write("\n<tr><td><h2>Parent Folder</h2></td></tr>");

            ar.write("\n<tr>");
            ar.write("\n   <td align=\"left\">");

            String fdLink = ar.retPath + "FolderDisplay.jsp?symbol="
                    + URLEncoder.encode(ent.getSymbol(), "UTF-8");


            String dname = getShortName(ent.getDecodedName(), 58);

            ar.write("  <a href=\"");
            ar.writeHtml(fdLink);
            ar.write("\"");
            writeTitleAttribute(ar, ent.getName(), 38);
            ar.write("><img allign=\"absbottom\" src=\"");
            ar.write(ar.retPath);
            ar.write("ofolder.gif");
            ar.write("\">");
            ar.writeHtml(dname);
            ar.write("</a><br/>(");
            ar.writeHtml(ent.getName());
            ar.write(")\n   </td>");

            ar.write("\n   <td align=\"left\">");
            SectionUtil.nicePrintTime(out, ent.getLastModifed(), ar.nowTime);
            ar.write("| " + ent.getFileCount() + " files");
            ar.write("\n   </td>");

            ar.write("\n   <td align=\"left\">");

            String addLink = ar.retPath + "addFile.jsp?"
                    + "fid=" + URLEncoder.encode(ent.getSymbol(), "UTF-8")
                    + "&dname="
                    + URLEncoder.encode(ent.getDisplayName(), "UTF-8")
                    + "&go=" + URLEncoder.encode(go, "UTF-8");
            ar.write("  <a href=\"");
            ar.writeHtml(addLink);
            ar.write("\">ADD</a>");
            ar.write("&nbsp;&nbsp;");

            String deleteLink = ar.retPath + "folderAction.jsp?"
                + "fid=" + URLEncoder.encode(ent.getSymbol(), "UTF-8")
                + "&action=" + URLEncoder.encode("Delete", "UTF-8");
            ar.write("  <a href=\"");
            ar.writeHtml(deleteLink);
            String fdmsg = "Are you sure you want to delete the folder: "
                    + ent.getName();
            ar.write("\" onClick=\"return confirm('" + fdmsg + "');\">");
            ar.write("<img allign=\"absbottom\" src=\"");
            ar.write(ar.retPath);
            ar.write("delicon.gif\" title=\"Delete\">");
            ar.write("</a>");
            ar.write("&nbsp;&nbsp;");

            String csLink = ar.retPath + "addSubFolder.jsp?"
                    + "fid=" + URLEncoder.encode(ent.getSymbol(), "UTF-8")
                    + "&dname="
                    + URLEncoder.encode(ent.getDisplayName(), "UTF-8")
                    + "&go=" + URLEncoder.encode(go, "UTF-8");
            ar.write("  <a href=\"");
            ar.writeHtml(csLink);
            ar.write("\"><img allign=\"absbottom\" src=\"");
            ar.write(ar.retPath);
            ar.write("afolder.gif\" title=\"Create\">");
            ar.write("</a>");

            ar.write("\n   </td>");
            ar.write("\n</tr>");
            ar.write("\n<tr><td><h2>Folders</h2></td></tr>");
            List<ResourceEntity> fileList = new Vector<ResourceEntity>();
            for (ResourceEntity entity : entityList) {
                if (entity.isFile()) {
                    fileList.add(entity);
                    continue;
                }
                ar.write("\n<tr>");

                ar.write("\n   <td align=\"left\">");

                String sfdLink = ar.retPath + "FolderDisplay.jsp?symbol="
                + URLEncoder.encode(entity.getSymbol(), "UTF-8");

                String cdname = getShortName(entity.getDecodedName(), 36);

                ar.write("<a href=\"");
                ar.writeHtml(sfdLink);
                ar.write("\"");
                writeTitleAttribute(ar, entity.getName(), 38);
                ar.write(">");
                ar.writeHtml(cdname);
                ar.write("</a><br/>(");
                ar.writeHtml(entity.getName());
                ar.write(")\n<br/>");
                ar.writeHtml(entity.getDisplayName());
                ar.write("<br/>");
                ar.writeHtml(entity.getFullPath());
                ar.write("<br/>\n   </td>");

                ar.write("\n   <td align=\"left\">");
                ar.write("\n   </td>");

                ar.write("\n   <td align=\"left\">");
                ar.write("\n   </td>");
                ar.write("\n</tr>");
            }

            ar.write("\n<tr><td><h2>Files</h2></td></tr>");
            for (ResourceEntity fileEnt : fileList) {

                ar.write("\n<tr>");

                ar.write("\n   <td align=\"left\">");
                String contentLink = ar.retPath + "t/dummy/dummy/f/remotefile.xml?fid=" + URLEncoder.encode(fileEnt.getSymbol(), "UTF-8");


                String cfdname = getShortName(fileEnt.getDecodedName(), 56);

                ar.write("<a href=\"");
                ar.writeHtml(contentLink);
                ar.write("\"");
                writeTitleAttribute(ar, fileEnt.getName(), 38);
                ar.write(">");
                ar.writeHtml(cfdname);
                ar.write("</a><br/>(");
                ar.writeHtml(fileEnt.getName());
                ar.write(")\n<br/>");
                ar.writeHtml(fileEnt.getDisplayName());
                ar.write("<br/>");
                ar.writeHtml(fileEnt.getFullPath());
                ar.write("<br/>\n   </td>");

                ar.write("\n   <td align=\"left\">");
                SectionUtil.nicePrintTime(ar.w, fileEnt.getLastModifed(), ar.nowTime);
                ar.write("&nbsp;&nbsp;&nbsp;Size: ");
                ar.write(Long.toString((long) (fileEnt.getSize() + 500) / 1000)
                        + "KB");
                ar.write("\n   </td>");

                ar.write("\n   <td align=\"left\">");

                ar.write("&nbsp;&nbsp;");


                String deleteFileLink = ar.retPath
                        + "folderAction.jsp?"
                        +"fid=" + URLEncoder.encode(fileEnt.getSymbol(), "UTF-8")
                        + "&action=" + URLEncoder.encode("Delete", "UTF-8")
                        + "&go=" + URLEncoder.encode(go, "UTF-8");
                ar.write("  <a href=\"");
                ar.writeHtml(deleteFileLink);
                String dfdmsg = "Are you sure you want to delete the file: "
                        + fileEnt.getName();
                ar.write("\" onClick=\"return confirm('" + dfdmsg
                                + "');\">");
                ar.write("<img allign=\"absbottom\" src=\"");
                ar.write(ar.retPath);
                ar.write("delicon.gif\" title=\"Delete\">");
                ar.write("</a>");

                ar.write("&nbsp;&nbsp;");
            }
            ar.write("\n   </td>");
            ar.write("\n</tr>");

            ar.write("\n</table>");
            ar.write("<br/><br/>");

        } catch (Exception e) {
            e.printStackTrace();
            throw e;
        }
    }

%>
