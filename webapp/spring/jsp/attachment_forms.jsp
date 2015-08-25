<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%!
    String pageTitle="";
%><%
/*

//*************************************************************
TODO: Clean up this file!  It appears to be only included in

spring\jsp\emailReminderForm.jsp(2):
spring\jsp\reminders.jsp(2):

This is likely to be leftover functionality from an earlier implementation, and may not be needed at all.
//*************************************************************


Required parameter:

    1. pageId : This is the id of a Project and used to retrieve NGPage.

Optional Parameter:

    1. isNewUpload : This parameter is used to check if page is upload type of form or not so on the
                      basis of this Sub Tabs are created.
*/

    String pageId = ar.reqParam("pageId");
    String isNewUpload = ar.defParam("isNewUpload", "");
%><%
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);

    pageTitle = ngp.getFullName();
    int documentCounts = NGWebUtils.getDocumentCount(ngp, SectionDef.PUBLIC_ACCESS);
    int memberDocCount = NGWebUtils.getDocumentCount(ngp, SectionDef.MEMBER_ACCESS);
    documentCounts += memberDocCount;

    int deletedAttachmentsCount = NGWebUtils.getDeletedDocumentCount(ngp);
    ReminderMgr reminderMgr = ngp.getReminderMgr();
    Vector openReminders = reminderMgr.getOpenReminders();
    int reminderCounts = 0;
    if(openReminders != null){
        reminderCounts = openReminders.size();
    }

    UserProfile uProf = ar.getUserProfile();
    NGBook ngb = ngp.getSite();
%>
<script>
    var retPath ='<%=ar.retPath%>';
    function trim(s) {
        var temp = s;
        return temp.replace(/^s+/,'').replace(/s+$/,'');
    }

    function check(id, label){
        var val = "";
        if(document.getElementById(id) != null){
            val = trim(document.getElementById(id).value);
            if(val == ""){
                alert(label+" field is empty.");
                return false;
            }else{
                return true;
            }
        }
        return false;
    }

    function writeAccessName(filepath){
        var upload_type = getValue(document.getElementsByName('uploadtype'));
        if(filepath != "" && upload_type != "existingDoc"){
            var accessName = filepath.match(/[^\/\\]+$/);
            document.getElementById("name").value = accessName;
        }
    }

    function cancel(){
        location.href = "listAttachments.htm";
    }

    var specialSubTab = '<fmt:message key="${requestScope.subTabId}"/>';

    var tab0_upload_attachments = '<fmt:message key="nugen.projecthome.subtab.upload.document"/>';
    var tab1_upload_attachments = '<fmt:message key="nugen.projecthome.subtab.link.url.to.project"/>';
    var tab2_upload_attachments = '<fmt:message key="nugen.projecthome.subtab.emailreminder"/>';
    var tab3_upload_attachments = '<fmt:message key="nugen.projecthome.subtab.link.from.repository"/>';
    var tab4_upload_attachments = '<fmt:message key="nugen.projecthome.subtab.documents"/> (<%=documentCounts  %>)';
    var tab5_upload_attachments = '<fmt:message key="nugen.projecthome.subtab.reminders"/> (<%=reminderCounts%>)';
    var tab6_upload_attachments = '<fmt:message key="nugen.projecthome.subtab.deleted"/> (<%=deletedAttachmentsCount%>)';
</script>
<script type="text/javascript" src="<%=ar.retPath%>jscript/attachment.js"></script>
<body>

        <div class="generalArea">
            <div class="generalContent">
                <div id="container">

                       <%if(!isNewUpload.equals("yes")){ %>
                           <ul id="subTabs" class="menu">
                           </ul>
                        <%} %>
</body>
<script>
    <%
    String isFreezed = (String)session.getAttribute("isFreezed");
    if(isFreezed != null){
        session.removeAttribute("isFreezed");
    %>
        openFreezeMessagePopup();
    <% }%>
</script>
