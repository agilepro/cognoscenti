<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/remindAttachmentForm.jsp"
%><%

    String destFolder = rRec.getDestFolder();
    if ("*PUB*".equals(destFolder))
    {
        destFolder = "Public Attachments";
    }
    else if ("*MEM*".equals(destFolder))
    {
        destFolder = "Member Only Attachments";
    }
    boolean isFolder = false;
    String actionName = "Upload Attachment File";
    String dfolder = rRec.getDestFolder();
    if(!dfolder.equals("*PUB*") && !dfolder.equals("*MEM*")){
        actionName =  "Upload Folder File";
        destFolder = dfolder;
        isFolder = true;
    }
    String go = ar.getCompleteURL();

    pageTitle = "Add File to "+ngp.getFullName();

    List<CustomRole> roles = ngp.getAllRoles();
    if (roles==null) {
        throw new Exception("got a null role list object!");
    }


%>
    <div class="content tab01">
        <h1>Reminder to Upload: <%ar.writeHtml(rRec.getSubject());%></h1>

        <p>You are invited to upload a file so that it can be shared (in a controlled manner) with others
           on the project. Upload the file will complete and close the reminder. Enter a description that will help
           others know what the file contains, or on what occasion it was produced. Browse your local
           disk to locate and select the file.  Press "Upload Document" to send the file to the server.
        </p>

    <%
    if (!rRec.isOpen()) {
    %>
        <p><b>You have uploaded a file. </b>  Would you like to upload another?</p>
    <%
    }
    %>
        <br/>
        <form action="upload.form" method="post" enctype="multipart/form-data">
            <table width="600">
                <col width="150">
                <col width="450">
                <input type="hidden" name="go" value="<%ar.writeHtml(go);%>"/>
                <input type="hidden" name="encodingGuard" value="%E6%9D%B1%E4%BA%AC"/>
                <input type="hidden" name="pageId"       value="<%ar.writeHtml( pageId);%>"/>
                <input type="hidden" name="rid" value="<%ar.writeHtml( rid);%>"/>
                <input type="hidden"  name="ftype" value="FILE"/>
                <input type="hidden"  name="destFolder" value="<%ar.writeHtml( rRec.getDestFolder());%>"/>
    <%
    if(!isFolder) { %>
                <tr>
                    <td valign="top">Description of Attachment:</td>
                    <td>
                        <textarea name="comment" id="fname"
                              style="WIDTH:95%;"><%ar.writeHtml( !"".equals(rRec.getFileDesc())?rRec.getFileDesc():"Please upload document");%></textarea>
                    </td>
                </tr>
                <tr><td colspan="2">&nbsp;</td></tr>
    <%
    }%>
                <tr>
                    <td>Local File:</td>
                    <td><input type="file"   name="fname"   id="fname" size="60"/></td>
                </tr>
                <tr><td colspan="2">&nbsp;</td></tr>
                <tr>
                    <td>Requested by</td>
                    <td class="Odd"><% ar.writeHtml( SectionUtil.cleanName(rRec.getModifiedBy())); %>,
                                <% SectionUtil.nicePrintTime(out, rRec.getModifiedDate(), ar.nowTime); %>
                    </td>
                </tr>
                <tr><td colspan="2">&nbsp;</td></tr>
                <tr>
                    <td></td><td>
                        <input type="submit" name="action" class="btn btn-primary" value="Upload Document">
                        &nbsp;&nbsp;
                        <input type="button"  class="btn btn-primary"  name="action" value="All Done" onclick="cancel();"/>
                    </td>
                </tr>
                <tr>
                    <td></td>
                    <td>
                    <% for (NGRole r : roles) { %>
                        <input type="checkbox" name="role" value="<% ar.writeHtml(r.getName()); %>" > <% ar.writeHtml(r.getName()); %>
                    <% } %>
                    </td>
            </table>
        </form>
    </div>
