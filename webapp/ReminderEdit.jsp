<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page errorPage="error.jsp"
%><%@page import="org.socialbiz.cog.AttachmentRecord"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.BaseRecord"
%><%@page import="org.socialbiz.cog.HistoryRecord"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.ReminderMgr"
%><%@page import="org.socialbiz.cog.ReminderRecord"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't edit an attachment reminder.");

    String p        = ar.reqParam("p");
    String section  = "Attachments";
    String rid      = ar.reqParam("rid");

    ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Can not edit attachment reminder.");

    ReminderMgr rMgr = ngp.getReminderMgr();
    ReminderRecord rRec= rMgr.findReminderByID(rid);
    if (rRec==null)
    {
        throw new Exception("Can't find a reminder with id: "+rid);
    }


    String name     = rRec.getSubject();
    String assignee = rRec.getAssignee();
    String comment  = rRec.getFileDesc();
    String muser    = rRec.getModifiedBy();
    long   mdate    = rRec.getModifiedDate();
    String fname    = rRec.getFileName();

    String dfolder = rRec.getDestFolder();
    boolean isFolder = false;

    if(!dfolder.equals("*PUB*") && !dfolder.equals("*MEM*")){
         isFolder = true;
    }


    pageTitle = ngp.getFullName() + " / "+ name;
%>

<%@ include file="Header.jsp"%>

<h3>Edit Reminder</h3><br/>
<form name="attachmentForm" method="post" action="ReminderEditAction.jsp">
    <input type="hidden" name="p" value="<% ar.writeHtml( p); %>">
    <input type="hidden" name="rid" value="<% ar.writeHtml( rid); %>">
    <table width="90%" class="Design8">
        <col width="20%"/>
        <col width="80%"/>
        <tr>
            <td align="left">
                <label id="nameLbl">To</label>
            </td>
            <td class="Odd"><input type="text" name="assignee" value="<% ar.writeHtml( rRec.getAssignee()); %>" id="name" style="WIDTH:95%;"/>

            </td>
        </tr>
        <tr>
            <td align="left">
                <label id="nameLbl">Subject</label>
            </td>
            <td class="Odd">Please Upload File <input type="text" name="subject" value="<% ar.writeHtml( name); %>"/>

            </td>
        </tr>
        <tr>
            <td>Instructions</td>
            <td class="Odd">
                <textarea name="instructions" style="WIDTH:95%; HEIGHT:74px;"><% ar.writeHtml( rRec.getInstructions()); %></textarea>
            </td>
        </tr>
        <% if(!isFolder){ %>
        <tr>
            <td>Description</td>
            <td class="Odd">
                <textarea name="comment" style="WIDTH:95%; HEIGHT:74px;"><% ar.writeHtml( comment); %></textarea>
            </td>
        </tr>
        <% } %>
        <tr>
            <td>Last Modified</td>
            <td class="Odd">
                <% ar.writeHtml( SectionUtil.cleanName(muser)); %>,
                <% SectionUtil.nicePrintTime(ar, mdate, ar.nowTime); %>
            </td>
        </tr>
        <tr>
            <td>Folder</td>
            <td class="Odd">
                <% ar.writeHtml( dfolder); %>
            </td>
        </tr>
        <tr>
            <td>Status</td>
            <td class="Odd">
                <% if (rRec.isOpen()) { %>
                    Open
                <% } else { %>
                    Closed
                <% } %>
            </td>
        </tr>
    </table>
    <br/>
    <center>
        <input type="submit" name="action" value="Update">
        - - -
        <input type="submit" name="action" value="Delete Reminder">
        <input type="checkbox" name="confirmdel"/> Check to confirm delete

    </center>
    <br/>

</form>

<script>
    var actBtn1 = new YAHOO.widget.Button("actBtn1");
    var actBtn2 = new YAHOO.widget.Button("actBtn2");
    var actBtn3 = new YAHOO.widget.Button("actBtn3");
    var actBtn4 = new YAHOO.widget.Button("actBtn4");
    var actBtn5 = new YAHOO.widget.Button("actBtn5");
    var actBtn5 = new YAHOO.widget.Button("actBtn6");
</script>

<h3>History</h3>
<ul>
<%
    List<HistoryRecord> histRecs = ngp.getAllHistory();
    for (HistoryRecord hist : histRecs)
    {
        if (rid.equals(hist.getContext()))
        {
            String shortName = SectionUtil.cleanName(hist.getResponsible());
            %>
            <li><%
            ar.writeHtml(HistoryRecord.convertEventTypeToString(hist.getEventType()));
            ar.write(" by ");
            ar.writeHtml(shortName);
            ar.write(" ");
            SectionUtil.nicePrintTime(ar, hist.getTimeStamp(), ar.nowTime);
            ar.write(" - ");
            ar.writeHtml(hist.getComments());
            %></li><%
        }
    }
%>
</ul>

<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>

