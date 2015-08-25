<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%/*
Required parameter:

    1. pageId : This is the id of a Project and used to retrieve NGPage.

*/

    String pageId = ar.reqParam("pageId");
    
    %><%
    
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();

    UserProfile uProf = ar.getUserProfile();

    int COUNT_OF_PUBLIC_NOTES = NGWebUtils.getNotesCount(ngp,ar,SectionDef.PUBLIC_ACCESS);
    int COUNT_OF_MEMBER_NOTES = NGWebUtils.getNotesCount(ngp,ar,SectionDef.MEMBER_ACCESS);
    int COUNT_OF_DELETED_NOTES = NGWebUtils.getDeletedNotesCount(ngp,ar);
    int COUNT_OF_DRAFT_NOTES = NGWebUtils.getDraftNotesCount(ngp,ar);

    /* if the parameter is not found in the parameters list, then find it out in the attributes list */
   // String go = ar.defParam("go", ar.getCompleteURL());%>
<head>

    <style type="text/css">
        #mycontextmenu ul li {
            list-style:none;
        }

        .yuimenubaritemlabel,
        .yuimenuitemlabel {
            outline: none;
         }

    </style>


    <!--[if IE 7]>
        <link href="<%=ar.baseURL%>css/ie7styles.css" rel="styleSheet" type="text/css" media="screen" />
    <![endif]-->


    <script>
        var specialSubTab = '<fmt:message key="${requestScope.subTabId}"/>';

        var tab0_home = '<fmt:message key="nugen.projecthome.subtab.public"/>';
        var tab1_home = '<fmt:message key="nugen.projecthome.subtab.deletedNotes"/>';
        var tab2_home = '<fmt:message key="nugen.projecthome.subtab.member"/>';
        var tab3_home = '<fmt:message key="nugen.projecthome.subtab.projectbulletin"/>';
        var tab5_home = '<fmt:message key="nugen.projecthome.subtab.draftNotes"/>';
        var public_notes_count = '<%=COUNT_OF_PUBLIC_NOTES%>';
        var member_notes_count = '<%=COUNT_OF_MEMBER_NOTES%>';
        var deleted_notes_count = '<%=COUNT_OF_DELETED_NOTES%>';
        var draft_notes_count = '<%=COUNT_OF_DRAFT_NOTES%>';
        var retPath ='<%=ar.retPath%>';
    </script>
</head>
<body class="yui-skin-sam" onclick="if(oContextMenu!='')oContextMenu.hide();" >
    <div>
        <!-- Content Area Starts Here -->
        <div class="generalArea">
            <div class="generalContent">
                <!-- Tab Structure Starts Here -->
                <div id="container">
                    <div>
                        <ul id="subTabs" class="menu">

                        </ul>
                    </div>

    <script>
        var oContextMenu="";
        var idForEditing="";
        var note_id = "";
        var addedInContextMenu=false;
        var operation = "";
        var opUrl = "";
        function checkDeletedAndSubmit(noteId, url){
            opUrl =url;
            YAHOO.util.Connect.asyncRequest('POST', "<%=ar.baseURL%>t/isNoteDeleted.ajax?oid="+noteId+"&p=<%ar.writeURLData(pageId);%>",checkDeletedAndSubmitResponse);
            return false;
        }
        var checkDeletedAndSubmitResponse = {
            success: function(o) {
                var respText = o.responseText;
                var json = eval('(' + respText+')');
                if(json.msgType == "yes"){
                    showErrorMessage("Unable to Perform Action", "Note has already been deleted." , json.comments);
                }
                else if(json.msgType == "no"){
                    openWin(opUrl);
                }else{
                    showErrorMessage("Unable to Perform Action", json.msg , json.comments);
                }
            },
            failure: function(o) {
                alert("checkDeletedAndSubmitResponse Error:" +o.responseText);
                 return false;
            }
        }

        function onNoteEditMenu(p_sType, p_aArgs, p_oValue) {
            operation = "hreflink_";
            YAHOO.util.Connect.asyncRequest('POST', "<%=ar.baseURL%>t/isNoteDeleted.ajax?oid="+note_id+"&p=<%ar.writeHtml(pageId);%>",checkNoteDeleteResponse);
        }

        function sendNodeByEmail(p_sType, p_aArgs, p_oValue) {
            operation = "emaillink_";
            YAHOO.util.Connect.asyncRequest('POST', "<%=ar.baseURL%>t/isNoteDeleted.ajax?oid="+note_id+"&p=<%ar.writeHtml(pageId);%>",checkNoteDeleteResponse);
        }

        function createLeafletMenuItem(p_sType, p_aArgs, p_oValue) {
            openWin(document.getElementById("create_leaflet").href);
        }

        function onMenuItemDelete(p_sType, p_aArgs, p_oValue) {
            YAHOO.util.Connect.asyncRequest('POST', document.getElementById(idForEditing+"_remove_link").value,deleteSubmitResponse);
        }

        function onMenuItemMakeMember(p_sType, p_aArgs, p_oValue) {
            YAHOO.util.Connect.asyncRequest('POST', document.getElementById(idForEditing+"_visibility_link").value+"&visibility=2",visibilitySubmitResponse);
        }

        function onMenuItemMakePublic(p_sType, p_aArgs, p_oValue) {
            YAHOO.util.Connect.asyncRequest('POST', document.getElementById(idForEditing+"_visibility_link").value+"&visibility=1",visibilitySubmitResponse);
        }

        function onMenuItemMakePrivate(p_sType, p_aArgs, p_oValue) {
            YAHOO.util.Connect.asyncRequest('POST', document.getElementById(idForEditing+"_visibility_link").value+"&visibility=4",visibilitySubmitResponse);
        }

        function onMenuItemSendEmail(p_sType, p_aArgs, p_oValue) {
            YAHOO.util.Connect.asyncRequest('POST', document.getElementById(idForEditing+"_visibility_link").value+"&visibility=4",visibilitySubmitResponse);
        }

        function onMenuItemUnDelete(p_sType, p_aArgs, p_oValue){
            YAHOO.util.Connect.asyncRequest('POST', document.getElementById(idForEditing+"_undelete_link").value+"&visibility=4",visibilitySubmitResponse);
        }
        var checkNoteDeleteResponse = {
            success: function(o) {
                var respText = o.responseText;
                var json = eval('(' + respText+')');
                if(json.msgType == "yes"){
                    showErrorMessage("Unable to Perform Action", "Note has already been deleted." , json.comments);
                }
                else if(json.msgType == "no"){
                    openWin(document.getElementById(operation+idForEditing).href);
                }else{
                    showErrorMessage("Unable to Perform Action", json.msg , json.comments);
                }
            },
            failure: function(o) {
                alert("checkNoteDeleteResponse Error:" +o.responseText);
            }
        }
        var deleteSubmitResponse ={
                success: function(o) {
                    var respText = o.responseText;
                    var json = eval('(' + respText+')');
                    if(json.msgType == "success"){
                        window.location.reload();
                    }
                    else{
                         showErrorMessage("Unable to Perform Action", json.msg , json.comments);
                    }
                },
                failure: function(o) {
                    alert("deleteSubmitResponse Error:" +o.responseText);
                }
        }

        var visibilitySubmitResponse ={
            success: function(o) {
                var respText = o.responseText;
                var json = eval('(' + respText+')');
                if(json.msgType == "success"){
                    window.location.reload();
                }
                else{
                    showErrorMessage("Unable to Perform Action", json.msg , json.comments);
                }
            },
            failure: function(o) {
                alert("deleteSubmitResponse Error:" +o.responseText);
            }
        }

        function onRightClick(mainId,id, noteId){
            idForEditing =  id;
            note_id = noteId
            oContextMenu = new YAHOO.widget.ContextMenu("mycontextmenu", {
                trigger: document.getElementById(mainId)
            });
            var member = false;
            var public_tab = false;
            var private_tab = false;
            var delete_tab = false;
            var not_a_delete_tab = true;
            if(specialSubTab==tab0_home){
                public_tab = true;
            }
            else if(specialSubTab==tab1_home){
                private_tab = true;
                delete_tab = true;
                not_a_delete_tab = false;
                public_tab = true;
                member = true;
            }
            else if(specialSubTab==tab2_home){
                member = true;
            }

            if(!addedInContextMenu){
                oContextMenu.addItems([
                                    <% if(ngp.isFrozen()){%>
                                      [{ text: "Create Note", onclick: { fn: openFreezeMessagePopup },disabled: delete_tab}],
                                     [{ text: "Edit Note", onclick: { fn: openFreezeMessagePopup },disabled: delete_tab}],
                                     [{ text: "Delete Note", onclick: { fn: openFreezeMessagePopup },disabled: delete_tab}],
                                     [{ text: "UnDelete Note", onclick: { fn: openFreezeMessagePopup },disabled: not_a_delete_tab}],
                                     [{ text: "Send Note By Email", onclick: { fn: openFreezeMessagePopup },disabled: delete_tab}],
                                     [{ text: "Make Public", onclick: { fn: openFreezeMessagePopup },disabled: public_tab}],
                                     [{ text: "Make Member Only", onclick: { fn: openFreezeMessagePopup }, disabled: member}]

                                    <% }else{%>
                                   [{ text: "Create Note", onclick: { fn: createLeafletMenuItem },disabled: delete_tab}],
                                   [{ text: "Edit Note", onclick: { fn: onNoteEditMenu },disabled: delete_tab}],
                                   [{ text: "Delete Note", onclick: { fn: onMenuItemDelete },disabled: delete_tab}],
                                   [{ text: "UnDelete Note", onclick: { fn: onMenuItemUnDelete },disabled: not_a_delete_tab}],
                                   [{ text: "Send Note By Email", onclick: { fn: sendNodeByEmail },disabled: delete_tab}],
                                   [{ text: "Make Public", onclick: { fn: onMenuItemMakePublic },disabled: public_tab}],
                                   [{ text: "Make Member Only", onclick: { fn: onMenuItemMakeMember }, disabled: member}]
                                   <%}%>
                ]);

            }

            //  Subscribe to the "render" event and set the "hideFocus" attribute
            //  of each <a> element to "true."

            oContextMenu.subscribe("render", function () {
                var aItems = this.getItems(),
                    nItems = aItems.length,
                    i;
                if (nItems > 0) {
                    i = nItems - 1;
                    do {
                        aItems[i].element.firstChild.hideFocus = true;
                    }
                    while(i--);
                }
            });
            oContextMenu.render(document.getElementById(mainId));
            addedInContextMenu=true;
        }

        function brokenLink(isImage,link_name,project_name){
            if(isImage){
                link_name = link_name.substring(4);
            }
            return alert("System could not find the project with name '"+project_name+"' associated with '"+link_name+"'.");
        }
    </script>
</body>
</html>