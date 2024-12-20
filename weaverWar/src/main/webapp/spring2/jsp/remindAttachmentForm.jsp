<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@ include file="/functions.jsp"
%><%/*
Required parameter:

    1. pageId   : This is the id of a Workspace and used to retrieve NGWorkspace.
    2. rid      : This is reminder id used here to get detail of reminder i.e. ReminderRecord.

Optional Parameter:

    1. s : This parameter is used to get section if not found set to 'Attachments'.
*/

    String rid  = ar.reqParam("rid");

    String s  = ar.defParam("s", "Attachments");%><%!String pageTitle="";
    ReminderRecord rRec = null;%>
<script>
    var specialSubTab = '<fmt:message key="${requestScope.subTabId}"/>';
    var tab0_remind_attachments = '<fmt:message key="nugen.projecthome.subtab.upload.document"/>';

</script>
<%
    UserProfile uProf = ar.getUserProfile();

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);

    NGBook ngb = ngp.getSite();

    ReminderMgr rMgr = ngp.getReminderMgr();
    rRec = rMgr.findReminderByIDOrFail(rid);
    String sendemailReminder = ar.baseURL+"t/"+ngb.getKey()+"/"+ngp.getKey()+"/DocsList.htm";
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