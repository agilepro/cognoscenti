<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.License"
%><%@page import="org.socialbiz.cog.LicenseForProcess"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.ReminderMgr"
%><%@page import="org.socialbiz.cog.ReminderRecord"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%><%@page import="org.socialbiz.cog.spring.ReminderEmailHelper"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameter:

    1. p   : This is the id of a Project and used to retrieve NGPage.
    2. rid : This is reminder id used here to get detail of reminder i.e. ReminderRecord.

*/
    ar.assertLoggedIn("In order to see this section of the project, you need to be"+
                       "logged in, and you need to be a member of the project.");
    String p = ar.reqParam("pageId");
    String rid  = ar.reqParam("rid");

%><%!String pageTitle="";%><%
    UserProfile uProf = null;

    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);

    pageTitle = "Send Email: "+ngp.getFullName();
    ar.assertMember("Can not send email reminder");

    ReminderMgr rMgr = ngp.getReminderMgr();
    ReminderRecord rRec= rMgr.findReminderByID(rid);
    if (rRec==null)
    {
        throw new NGException("nugen.exception.unable.to.find.reminder", new Object[]{rid});
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
                <!--<tr>
                    <td>&nbsp;</td>
                    <td>
                        <input type="submit" name="action"  class="btn btn-primary"  value="Send Mail"/>
                      </td>
                </tr>-->
                <tr><td colspan="2">&nbsp;</td></tr>
                <!--<tr>
                    <td>To:</td><td>
                        <input type="text" size="60" name="emailto" value="<%ar.writeHtml(rRec.getAssignee());%>"/>
                        <br> &nbsp;
                  </td>
                </tr>-->
                <tr>
                    <td>Subject:</td>
                    <td><b><%ar.writeHtml(subject);%></b></td>
                </tr>
                <tr>
                    <td colspan="2"><hr/></td>
                </tr>
                <tr>
                    <td></td>
                    <td><%ReminderEmailHelper.writeReminderEmailBody(ar, ngp, rRec);%></td>
                </tr>
            </table>
        </form>
    </div>

<%@ include file="functions.jsp"%>
