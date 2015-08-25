<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%/*
Required parameter:

    1. pageId   : This is the id of a Project and used to retrieve NGPage.
    2. rid      : This is reminder id used here to get detail of reminder i.e. ReminderRecord.

Optional Parameter:

    1. s : This parameter is used to get section if not found set to 'Attachments'.
*/

    String pageId = ar.reqParam("pageId");
    String rid  = ar.reqParam("rid");

    String s  = ar.defParam("s", "Attachments");%><%!String pageTitle="";
    ReminderRecord rRec = null;%>
<%@page import="org.socialbiz.cog.AccessControl"%>
<script>
    var specialSubTab = '<fmt:message key="${requestScope.subTabId}"/>';
    var tab0_remind_attachments = '<fmt:message key="nugen.projecthome.subtab.upload.document"/>';

</script>
<%
    UserProfile uProf = ar.getUserProfile();

    NGPage ngp =ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);

    NGBook ngb = ngp.getSite();
    String specialTab = "Project Document Section";

    ReminderMgr rMgr = ngp.getReminderMgr();
    rRec = rMgr.findReminderByID(rid);
    if (rRec == null){
        throw new NGException("nugen.exception.attachment.not.found", new Object[]{rid});
    }
    String sendemailReminder = ar.baseURL+"t/"+ngb.getKey()+"/"+ngp.getKey()+"/listAttachments.htm";
%>
<script>
var rid = '<%=rid%>';
function cancel(){
    location.href = "<%=sendemailReminder%>";
}
</script>
<body>

<div id="mainContent">
    <!-- Content Area Starts Here -->
    <div class="generalArea">
        <div class="generalContent">
            <!-- Tab Structure Starts Here -->
            <div id="container">
                     <ul id="subTabs" class="menu">
                     </ul>
    <!-- Content Area Ends Here -->
</body>