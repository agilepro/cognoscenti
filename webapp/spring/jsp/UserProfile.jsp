<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="functions.jsp"
%><%@page import="java.io.StringWriter"
%><%@page import="java.util.Collections"
%><%@page import="java.util.Iterator"
%><%@page import="java.util.List"
%><%@page import="java.util.ListIterator"
%><%@page import="org.socialbiz.cog.AuthDummy"
%><%@page import="org.socialbiz.cog.IDRecord"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.TemplateRecord"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.ValueElement"
%><%@page import="org.socialbiz.cog.WatchRecord"
%><%@page import="org.socialbiz.cog.dms.CVSConfig"
%><%@page import="org.socialbiz.cog.dms.LocalFolderConfig"
%>

    <!-- Display the search results here -->
    <script type="text/javascript">

        var isConfirmPopup = false;
        var go = "<%=ar.getCompleteURL()%>";
        function validate(){
            if (document.getElementById('option').value == "Return"){
                return false;
            }else if (document.getElementById('option').value == "Save Profile"){
                return isNullOrBlank('p1','Password') && isNullOrBlank('p2','Password') && matchPasswords();
            }else {
                return false;
            }
        }

        function matchPasswords(){
            var check = (document.getElementById("p1").value == document.getElementById("p2").value);
            if(!check)
                alert("Both passwords must be same.");
            return check;
        }
        function openModalDialogue(popupId,headerContent,panelWidth){
            var   header = headerContent;
            var bodyText= document.getElementById(popupId).innerHTML;
            createPanel(header, bodyText, panelWidth);
            myPanel.beforeHideEvent.subscribe(function() {
                if(!isConfirmPopup){
                    window.location = "<%=ar.getCompleteURL()%>";
                }
            });
        }

        function trim(s) {
            var temp = s;
            return temp.replace(/^s+/,'').replace(/s+$/,'');
        }

        function selectAll(checkboxObj, targetcheckboxs, formId){
            var elements = document.forms[formId].elements;
            var targetCheckboxObj = elements[targetcheckboxs];
            if(targetCheckboxObj != null){
                if(targetCheckboxObj.length == null){
                    if(checkboxObj.checked == true){
                        targetCheckboxObj.checked = true;
                    }else{
                        targetCheckboxObj.checked = false;
                    }
                }else if(targetCheckboxObj.length > 1){
                    for(i=0; i<targetCheckboxObj.length ; i++){
                        if(checkboxObj.checked == true){
                            targetCheckboxObj[i].checked = true;
                        }else{
                            targetCheckboxObj[i].checked = false;
                        }
                    }
                }
            }
        }

        function unSelect(targetCheckboxId,formId){
            var elements = document.forms[formId].elements;
            var targetCheckboxObj = elements[targetCheckboxId];
            targetCheckboxObj.checked = false;
        }



        function cancel(){
            window.location = "<%=ar.getCompleteURL()%>";
        }

        function cancelPanel(){
            myPanel.hide();
            return false;
        }

    </script>
