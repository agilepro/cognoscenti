<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.NGSession"
%><%@page import="org.socialbiz.cog.ReminderMgr"
%><%@page import="org.socialbiz.cog.ReminderRecord"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="org.w3c.dom.Element"
%><%ar = AuthRequest.getOrCreate(request, response, out);
    ar.retPath="../../";

    String p = ar.reqParam("p");
    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    boolean isMember = ar.isMember();
    boolean isAdmin = ar.isAdmin();

    ngb = ngp.getSite();

    pageTitle = ngp.getFullName();
    specialTab = "Documents";
    newUIResource = "attachment.htm";%>

<%@ include file="Header.jsp"%>
<%
        headlinePath(ar, "Attachments Section");
        if (ar.isMember() && !ar.isStaticSite())
        {
%>
<table><tr>
<form action="<%=ar.retPath%>CreateAttachment.jsp" method="get">
<td align="left">
<input type="hidden" name="p"  value="<%ar.writeHtml(p);%>">
<input type="submit" name="action" value="Attachment Document">
</td>
</form>
<form action="<%=ar.retPath%>createRemoteAttachment.jsp" method="get">
<td align="left">
<input type="hidden" name="p"  value="<%ar.writeHtml(p);%>">
<input type="submit" name="action" value="Link From Repository">
</td>
</form>
<form action="<%=ar.retPath%>RefreshFolderAction.jsp" method="get">
<td align="left">
<input type="hidden" name="p"  value="<%ar.writeHtml(p);%>">
<input type="submit" name="action" value="Refresh Folder">
</td>
</form>
</tr></table>
<%
        }

        ar.write("\n <div class=\"section\"> ");

        ar.write("\n     <div class=\"section_title\"> ");
        ar.write("\n         <h1 class=\"left\"><b>Documents</b></h1> ");

        ar.write("\n         <div class=\"section_date right\">");
        ar.write("</div> ");

        ar.write("\n         <div class=\"clearer\">&nbsp;</div> ");
        ar.write("\n     </div> ");

        ar.write("\n     <div class=\"section_body\"> ");
        displayAttachments(ar, ngp);

        ar.write("\n     </div> ");
        ar.write("\n </div> ");

        ar.flush();
        out.flush();

%>

<%
    //-------------------------------------------------------
    if (ar.isMember() && !ar.isStaticSite())
    {
%>
<div class="section">
    <div class="section_title">
    <b>Reminders to Attach Documents</b>
    </div>
    <div class="section_body">
        <table cellpadding="3" cellspacing="1" width="650">
        <col width="20"/>
        <col width="380"/>
        <col width="80"/>
        <col width="170"/>
<%
        ReminderMgr rMgr = ngp.getReminderMgr();
        int reminderCount = 0;
        for (ReminderRecord rRec : rMgr.getOpenReminders()) {
            reminderCount++;
            String update = ar.retPath + "ReminderEdit.jsp?p="+URLEncoder.encode(ngp.getKey(), "UTF-8")
                    +"&rid="+URLEncoder.encode(rRec.getId(), "UTF-8");
            String dName = rRec.getSubject();
            if (dName==null || dName.length()==0)
            {
                dName = "Reminder"+rRec.getId();
            }
            %>
            <tr><td>
            <%=Integer.toString(reminderCount)%>
            </td><td>
            <%ar.writeHtml(dName);%>
            <br/>
            <%ar.writeHtml(rRec.getFileDesc());%>

            </td>
            <td>
            <a href="<%ar.writeHtml(update);%>" title="modify settings of this reminder">
               <img src="<%=ar.retPath%>update.gif" title="Update the Reminder">
            </a>

            </td>
            <td>
            To: <%ar.writeHtml(rRec.getAssignee());%><br/>
            <%SectionUtil.nicePrintTime(ar, rRec.getModifiedDate(), ar.nowTime);%>
            </td>
            </tr>
            <%
        }
%>
        </table>
    </div>
</div>
<%
    }
%>
<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
<%!public static void displayAttachments(AuthRequest ar, NGContainer ngp)  throws Exception
    {
        UserProfile up = ar.getUserProfile();

        List<HistoryRecord> histRecs = ngp.getAllHistory();

        ar.write("<table cellpadding=\"3\" cellspacing=\"1\" width=\"650\">");
        ar.write("<col width=\"20\"/>");
        ar.write("<col width=\"380\"/>");
        ar.write("<col width=\"60\"/>");
        ar.write("<col width=\"100\"/>");
        ar.write("<col width=\"40\"/>");
        ar.write("<col width=\"50\"/>");
        ar.write("<col width=\"50\"/>");

        List<AttachmentRecord> attachmentList = ngp.getAllAttachments();
        SectionAttachments.sortByName(attachmentList);
        boolean isMember = ar.isMember();
        int i=0;
        for(AttachmentRecord attachment : attachmentList)
        {
            String id = attachment.getId();

            //if the attachment is not public, then display only if the user is a
            //member of the page
            if (attachment.getVisibility()>1) {
                if (!isMember) {
                    continue;
                }
            }


            int readStatus = 0;
            boolean matchesVersion = true;
            for (HistoryRecord hist : histRecs)
            {
                if (hist.getContextType() == HistoryRecord.CONTEXT_TYPE_DOCUMENT)
                {
                    if(id.equals(hist.getContext()))
                    {
                        readStatus = hist.getEventType();
                        matchesVersion = (attachment.getModifiedDate()==hist.getContextVersion());
                        break;
                    }
                }
            }

            // for FILE the file & displayName attribute will be the same.
            // for the URL the file & the displayName will be different.
            String fname = attachment.getStorageFileName();

            String accessName = attachment.getNiceName();
            String displayName = attachment.getNiceNameTruncated(48);
            String ftype = attachment.getType();

            boolean hasRLink = attachment.hasRemoteLink();

            String modifiedBy = attachment.getModifiedBy();
            if (modifiedBy.length() == 0)
            {
                modifiedBy = "unknown";
            }

            String editLink = ar.retPath + "EditAttachment.jsp"
                        + "?p=" + URLEncoder.encode(ngp.getKey(), "UTF-8")
                        + "&aid=" + URLEncoder.encode(id, "UTF-8");
            String accessLink = ar.retPath + "AccessAttachment.jsp"
                        + "?p=" + URLEncoder.encode(ngp.getKey(), "UTF-8")
                        + "&aid=" + URLEncoder.encode(id, "UTF-8");


            String contentLink = accessLink;
            if (ftype.equals("URL"))
            {
                contentLink = fname; // URL.
            }
            else
            {
                contentLink = "a/" + SectionUtil.encodeURLData(accessName);
            }
            if (ar.isStaticSite())
            {
                //in the case of static sites, only point to the content.
                accessLink = contentLink;
            }


            ar.write("\n<tr valign=\"top\">");
            ar.write("<td><a href=\"");
            ar.writeHtml(contentLink);
            ar.write("\" title=\"download this file immediately\"><img src=\"");
            ar.write(ar.retPath);
            ar.write("assets/iconDownload.png\"></a></td>");
            ar.write("\n  <td align=\"left\">");
            ar.write("<a href=\"");
            ar.writeHtml(accessLink);
            ar.write("\" title=\"Access the content of this attachment\">");
            ar.writeHtml(displayName);
            ar.write("</a>");
            ar.write("<br/>");
            ar.writeHtml(attachment.getDescription());
            ar.write(" &nbsp; ");
            ar.writeHtml(attachment.getUniversalId());
            ar.write("</td>");
            ar.write("\n<td>");
            if (!ar.isStaticSite())
            {
                ar.write("<a href=\"");
                ar.writeHtml(editLink);
                ar.write("\" title=\"Modify the settings for this attachment\">");
                ar.write("<img src=\"");
                ar.write(ar.retPath);
                ar.write("update.gif\" title=\"Update Attachment Settings\"></a>");
            }
            ar.write("</td>");

            ar.write("\n<td>");
            if(hasRLink && !ar.isStaticSite())
            {
                String rsyncLink = ar.retPath + "syncAttachment.jsp"
                    + "?p=" + URLEncoder.encode(ngp.getKey(), "UTF-8")
                    + "&aid=" + URLEncoder.encode(id, "UTF-8");
                ar.write("<a href=\"");
                ar.writeHtml(rsyncLink);
                ar.write("\" title=\"Synchronize This Document with Connected Repository.\">");
                ar.write("<img src=\"");
                ar.write(ar.retPath);
                ar.write("sync.gif\"></a>");
            }
            else if ("GONE".equals(ftype)) {
                String fixLink = ar.retPath + "fixAttachment.jsp"
                    + "?p=" + URLEncoder.encode(ngp.getKey(), "UTF-8")
                    + "&aid=" + URLEncoder.encode(id, "UTF-8");
                ar.write("<a href=\"");
                ar.writeHtml(fixLink);
                ar.write("\" title=\"Document is MISSING from the folder!\">");
                ar.write("<img src=\"");
                ar.write(ar.retPath);
                ar.write("assets/iconError.png\"></a>");
            }
            else if ("EXTRA".equals(ftype)) {
                String fixLink = ar.retPath + "fixAttachment.jsp"
                    + "?p=" + URLEncoder.encode(ngp.getKey(), "UTF-8")
                    + "&aid=" + URLEncoder.encode(id, "UTF-8");
                ar.write("<a href=\"");
                ar.writeHtml(fixLink);
                ar.write("\" title=\"Unknown document has appeared in the folder!\">");
                ar.write("<img src=\"");
                ar.write(ar.retPath);
                ar.write("assets/iconError.png\"></a>");
            }
            ar.write("</td>");


            ar.write("\n  <td>");
            SectionUtil.nicePrintTime(ar,attachment.getModifiedDate(), ar.nowTime);
            ar.write("</td>");
            ar.write("\n  <td>");
            if (!ar.isStaticSite())
            {
                ar.write("<a href=\"");
                ar.writeHtml(editLink);
                ar.write("\" title=\"Modify your settings for this attachment\"><img src=\"");
                ar.write(ar.retPath);
                if (readStatus==HistoryRecord.EVENT_DOC_APPROVED)
                {
                    ar.write("ts_completed.gif");
                }
                else if (readStatus==HistoryRecord.EVENT_DOC_REJECTED)
                {
                    ar.write("ts_waiting.gif");
                }
                else if (readStatus==HistoryRecord.EVENT_DOC_SKIPPED)
                {
                    ar.write("ts_skipped.gif");
                }
                else
                {
                    ar.write("ts_initial.gif");
                }
                ar.write("\">");
                if (!matchesVersion)
                {
                    ar.write("(previous)");
                }
                ar.write("</a>");
            }
            ar.write("</td>\n<td>");
            if (attachment.isDeleted()) {
                ar.write("DEL");
            }
            else if (attachment.getVisibility()<=1)
            {
                ar.write("PUB");
            }
            else
            {
                ar.write("MEM");
            }
            ar.write("</td>\n<td>");
            if (!attachment.isDeleted()) {
                ar.write("V");
                ar.write(Integer.toString(attachment.getVersion()));
            }
            ar.write("</td></tr>");
        }
        ar.write("</table>");
        ar.write("<br/>");
    }%>