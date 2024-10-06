<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.AuthRequest"
%><%@page import="com.purplehillsbooks.weaver.License"
%><%@page import="com.purplehillsbooks.weaver.LicenseForProcess"
%><%@page import="com.purplehillsbooks.weaver.NGBook"
%><%@page import="com.purplehillsbooks.weaver.NGPageIndex"
%><%@page import="com.purplehillsbooks.weaver.ReminderMgr"
%><%@page import="com.purplehillsbooks.weaver.ReminderRecord"
%><%@page import="com.purplehillsbooks.weaver.UserProfile"
%><%@page import="com.purplehillsbooks.weaver.UtilityMethods"
%><%@page import="java.net.URLEncoder"
%><%@page import="org.w3c.dom.Element"
%><%@ include file="/include.jsp"
%><%
/*
Required parameter:

    1. p   : This is the id of a Workspace and used to retrieve NGWorkspace.
    2. rid : This is reminder id used here to get detail of reminder i.e. ReminderRecord.

*/
    ar.assertLoggedIn("In order to see this section of the workspace, you need to be"+
                       "logged in, and you need to be a member of the workspace.");
    String p = ar.reqParam("pageId");
    String rid  = ar.reqParam("rid");

%><%!String pageTitle="";%><%
    UserProfile uProf = null;

    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKey(siteId,pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);

    pageTitle = "Send Email: "+ngp.getFullName();
    ar.assertAccessWorkspace("Can not send email reminder");

    ReminderMgr rMgr = ngp.getReminderMgr();
    ReminderRecord rRec= rMgr.findReminderByID(rid);
    if (rRec==null)
    {
        throw new NGException("nugen.exception.attachment.not.found", new Object[]{rid});
    }
    String subject = "Please upload File ";
%>

<!--  here is where the content goes -->
    <div class="generalContent">
        <form action="resendemailReminder.htm" method="post">
            <table width="600">
                <col width="130">
                <col width="470">
                <input type="hidden" name="encodingGuard" value="%E6%9D%B1%E4%BA%AC"/>
                <input type="hidden" name="rid"     value="<%ar.writeHtml(rid);%>"/>
                <input type="hidden" name="go"      value="<%ar.writeHtml(ar.getResourceURL(ngp,"attach.htm"));%>"/>
                <tr>
                    <td>&nbsp;</td>
                    <td>
                        <input type="submit" name="action"  class="btn btn-primary btn-raised"  value="Send Mail"/>
                      </td>
                </tr>
                <tr><td colspan="2">&nbsp;</td></tr>
                <tr>
                    <td>To:</td><td>
                        <input type="text" size="60" name="emailto" value="<%ar.writeHtml(rRec.getAssignee());%>"/>
                        <br> &nbsp;
                  </td>
                </tr>
                <tr>
                    <td>Subject:</td>
                    <td><b><%ar.writeHtml(subject);%></b></td>
                </tr>
                <tr>
                    <td colspan="2"><hr/></td>
                </tr>
                <tr>
                    <td></td>
                    <td><%rRec.writeReminderEmailBody(ar, ngp);%></td>
                </tr>
            </table>
        </form>
    </div>

<%@ include file="functions.jsp"%>
