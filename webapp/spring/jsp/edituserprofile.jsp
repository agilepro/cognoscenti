<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.ValueElement"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.UserManager"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.IDRecord"
%><%@ include file="functions.jsp"
%><%

/*

Optional Parameter:

    addthroughEmail : Its used to check whether request has come from mail if yes then it will show
                      confirmation popup.
*/

    String throughEmail = ar.defParam("addthroughEmail","");
    String openIdMsg = ar.defParam("openIdMsg","");

%><%!
    String pageTitle = "";
%><%

    ar.assertLoggedIn("Can't edit a user's profile.");
    UserProfile uProf = findSpecifiedUserOrDefault(ar);

    //the following should be impossible since above log-in is checked.
    if (uProf == null)
    {
        throw new NGException("nugen.exception.cant.find.user",null);
    }
    boolean selfEdit = uProf.getKey().equals(ar.getUserProfile().getKey());
    if (!selfEdit)
    {
        //there is one super user who is allowed to edit other user profiles
        //that user is specified in the system properties -- by KEY
        String superUser = ar.getSystemProperty("su");
        if (superUser==null || !superUser.equals(ar.getUserProfile().getKey()))
        {
            throw new NGException("nugen.exception.other.user", new Object[]{uProf.getName()});
        }
    }

    String go  = "editUserProfile.htm?u="+uProf.getKey();

    String openid = uProf.getUniversalId();

    String desc = uProf.getDescription();
    String name = uProf.getName();
    String preferredEmail = uProf.getPreferredEmail();
    pageTitle = "User: "+uProf.getName();
    String photoSource = ar.retPath+"assets/photoThumbnail.gif";
    if(uProf.getImage().length() > 0){
        photoSource = ar.retPath+"users/"+uProf.getImage();
    }
    Object errMsg = session.getAttribute("error-msg");

%>
<%@page import="org.socialbiz.cog.ProfileRequest"%>
<script type="text/javascript">

    function updateProfile(op){
        document.getElementById('action').value=op;
        document.getElementById('updateUserProfile').action ="EditUserProfileAction.form";
        document.getElementById('updateUserProfile').submit();
    }

    function removeId(op,modid){
        var reply = confirm("Do you want to remove ID?");
        if(reply){
            document.getElementById('delconf').value='yes';
            document.getElementById('modid').value=modid;
            document.getElementById('action').value=op;
            document.getElementById('updateUserProfile').action = "EditUserProfileAction.form";
            document.getElementById('updateUserProfile').submit();
        }
    }

    var isOpenid = false;
    function removeUserId(modid, openId){
        isOpenid = openId;

        var loginId = document.getElementById('modid').value;
        var idLength = loginId.length;
        if(loginId.charAt(idLength-1)=="/"){
            loginId = loginId.substring(0, idLength-1);
        }
        var modidLength = modid.length;
        if(modid.charAt(modidLength-1)=="/"){
            modid = modid.substring(0, modidLength-1);
        }
        var reply = confirm("Do you want to remove ID?");
        if(reply){
            if(modid != loginId){
                if(!isOpenid){
                    var postURL = "<%=ar.retPath %>t/deleteUserId.ajax?action=removeId&u=<%ar.writeURLData(uProf.getKey());%>&modid="+modid+"&delconf=yes";
                    var transaction = YAHOO.util.Connect.asyncRequest('POST', postURL,removeUserIdResult);

                }else{
                    var postURL = "<%=ar.retPath %>t/deleteUserId.ajax?action=removeId&u=<%ar.writeURLData(uProf.getKey());%>&modid="+escape(modid)+"&delconf=yes";
                    var transaction = YAHOO.util.Connect.asyncRequest('POST', postURL,removeUserIdResult);
                }
            }else {
                alert("You can not delete the ID that you used to log in with.");
            }
        }
    }

    var removeUserIdResult = {
        success: function(o) {
                        var respText = o.responseText;
                        var json = eval('(' + respText+')');
                        if(json.msgType == "success"){
                            //removeTD(json.modid);
                            if(isOpenid){
                                alert("Open Id has been deleted successfully.");
                            }else{
                                alert("Email Id has been deleted successfully.");
                            }
                            window.location.reload();
                        }else{
                            showErrorMessage("Result", json.msg , json.comments );
                        }
         },
         failure: function(o) {
                    alert("deleteUserId.ajax Error:" +o.responseText);
         }
     }

    function removeTD(removeVal)
    {
        var myTD=document.getElementById(removeVal);
        myTD.parentNode.removeChild(myTD);
    }

    function uploadUserPhoto(){
        if(document.getElementById('fname').value.length <1 ){
            alert('Please upload a photo');
        }else{
            document.getElementById('upload_user').submit();
        }
    }

</script>
<body class="yui-skin-sam">
    <div class="generalArea">
        <div class="pageHeading">Update Your Settings</div>
        <div class="pageSubHeading">From here you can modify your profile settings.</div>
        <div class="generalSettings">
            <form id="upload_user" action="uploadImage.form" method="post" enctype="multipart/form-data">
                <table>
                    <tr>
                        <td width="148" class="gridTableColummHeader_2">Profile Photo:</td>
                        <td style="width:20px;"><input type="hidden" name="action" id="actionUploadPhoto" value='' /></td>
                        <td style="width:50px;"><img src="<%ar.writeHtml(photoSource);%>" width="47" height="47" alt="" /></td>
                        <td valign="bottom"><input type="file" name="fname" id="fname" /></td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2"></td>
                        <td style="width:20px;"></td>
                        <td colspan="2"><input type="button" class="btn btn-primary" value="Upload Photo" onclick="javascript:uploadUserPhoto();"/></td>
                    </tr>
                </table>
            </form>
            <form id="updateUserProfile" name="updateUserProfile" action="EditUserProfileAction.form" method="post">
                <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
                <input type="hidden" name="openid" value="<% ar.writeHtml(openid); %>"/>
                <input type="hidden" id="modid" name="modid" value="<% ar.writeHtml(uProf.getLastLoginId()); %>"/>
                <input type="hidden" name="u" value="<% ar.writeHtml(uProf.getKey());%>" />
                <input type="hidden" name="go" id="goUpdate" value="<% ar.writeHtml(go);%>" />
                <input type="hidden" name="delconf" id="delconf" value='' />
                <input type="hidden" name="action" id="action" value='Save' />
                <table border="0px solid red" width="100%">
                    <tr><td style="height:30px"></td></tr>
                    <tr><td colspan="4" class="generalHeading">Personal Details</td></tr>
                    <tr><td style="height:30px"></td></tr>
                    <tr>
                        <td width="148" class="gridTableColummHeader_2"><fmt:message key="nugen.userprofile.Name"/>:</td>
                        <td width="39" style="width:20px;"></td>
                        <td colspan="2"><input type="text" class="inputGeneral" name="name" size="69" value="<% ar.writeHtml(name);%>" /></td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2" style="vertical-align:top"><fmt:message key="nugen.userprofile.Description"/>:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2"><textarea rows="4" name="description" class="textAreaGeneral"><% ar.writeHtml(desc);%></textarea></td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2"></td>
                        <td style="width:20px;"></td>
                        <td colspan="2"><input type="button" class="btn btn-primary" onclick="updateProfile('Save')" value="Update Personal Details"/></td>
                    </tr>
                    <tr><td style="height:30px"></td></tr>
                    <tr><td colspan="4" class="generalHeading">Email Details</td></tr>
                    <tr><td style="height:30px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2"><fmt:message key="nugen.userprofile.PreferredEmail"/>:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                            <%if(preferredEmail!=null){
                            %>
                            <input type="radio" checked="checked" name="preferredEmail" value="<% ar.write(preferredEmail); %>"/>&nbsp;<% ar.write(preferredEmail); %>
                            <%} %>
                        </td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2" valign="top">Email Id:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2" valign="top">
                            <table id="emailIdsList">
                            <%
                            String emailList = preferredEmail;
                            if(emailList==null){
                                emailList="";
                            }
                            Boolean haveEmail = false;
                            for (IDRecord anid : uProf.getIdList())
                            {
                                if ((anid.isEmail())&&(!anid.getLoginId().equals(uProf.getPreferredEmail())))
                                {
                                    emailList = emailList+"+"+anid.getLoginId();
                                    haveEmail = true;
                                %>
                                <tr>
                                    <td id="<%ar.writeHtml(anid.getLoginId());%>">
                                        <input type="radio" name="preferredEmail" value="<%ar.writeHtml(anid.getLoginId());%>"/>&nbsp;<%ar.writeHtml(anid.getLoginId());%>
                                        &nbsp;&nbsp;<a href="javascript:removeUserId(<%ar.writeQuote4JS(anid.getLoginId());%>,false);" title="Remove"><img src="<%=ar.retPath%>assets/iconDelete.gif" alt="Remove"/></a>
                                    </td>
                                </tr>
                                <tr><td style="height:5px"></td></tr>
                                <%
                                }
                            }
                            if(!haveEmail){
                                %>
                                    <tr>
                                        <td id="noAlternateEmail">No Alternate Email Id added</td>
                                    </tr>
                                <%
                                }
                            %>
                            </table>
                         </td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2"></td>
                        <td style="width:20px;"></td>
                        <td colspan="2"><input type="button" class="btn btn-primary" value="Change Preferred Email" onclick="updateProfile('UpdatePreferredEmail')"/></td>
                    </tr>
                    <tr><td style="height:20px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2"></td>
                        <td style="width:20px;"></td>
                        <td colspan="2"><b>New Email Id:</b><br /><input type="text" id="txtBoxEmailId" class="inputGeneral" /></td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2"></td>
                        <td style="width:20px;"></td>
                        <td colspan="2"><input type="button" class="btn btn-primary" onclick="return addEmailId(<%ar.writeQuote4JS(emailList);%>);" value="Add New Email"/></td>
                    </tr>
                    <tr><td style="height:30px"></td></tr>
                    <tr><td colspan="4" class="generalHeading">Other Id Details</td></tr>
                    <tr><td style="height:30px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2" valign="top">Ids:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2" valign="top">
                            <table id="openIdsList">
                                <%
                                Boolean haveOpenId = false;
                                String openIdList = "";
                                for (IDRecord anid : uProf.getIdList())
                                {
                                    if (!anid.isEmail())
                                    {
                                        haveOpenId = true;
                                        openIdList = openIdList+"+"+anid.getLoginId();
                                    %>
                                    <tr>
                                        <td id="<%ar.writeHtml(anid.getLoginId());%>">
                                            <%ar.writeHtml(anid.getLoginId());%>&nbsp;&nbsp;
                                            <a href="javascript:removeUserId(<%ar.writeQuote4JS(anid.getLoginId());%>,true);" title="Remove"><img src="<%=ar.retPath%>assets/iconDelete.gif" alt="Remove"/></a>
                                        </td>
                                        <tr><td style="height:5px"></td></tr>
                                    </tr>
                                    <%
                                    }
                                }
                                if(!haveOpenId){
                                %>
                                    <tr>
                                        <td>No OpenId added</td>
                                    </tr>
                                <%
                                }
                                %>
                             </table>
                         </td>
                    </tr>
                </table>
            </form>
            <form id="updateOpenIdForm" name="updateOpenIdForm" action="<%=ar.retPath%>t/openIdLogin.form" method="post">
                <input type="hidden" name="go" value="<%=ar.baseURL %>v/<%=uProf.getKey()%>/editUserProfile.htm?openIdMsg=yes" />
                <input type="hidden" name="option" value="Login" />
                <input type="hidden" name="key" value="<%ar.writeURLData(uProf.getKey());%>" />
                <input type="hidden" name="err" value="<%ar.writeURLData(ar.getCompleteURL());%>" />
                <input type="hidden" id="txtBoxOpenId" name="openid" class="inputGeneral" />
                <table width="100%">
                    <tr><td style="height:10px"></td></tr>
                    <tr><td colspan="4" class="horizontalSeperator"></td></tr>
                    <tr><td style="height:30px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2"></td>
                        <td style="width:20px;"></td>
                        <td colspan="2"><input type="button" class="btn btn-primary" onclick="updateProfile('Cancel')" value="Go Back To My Settings"/></td>
                    </tr>
                </table>
            </form>
        </div>
    </div>
</body>
<%
if(errMsg != null){
%>
<script>
createPanel("Error", "<div class='generalPopupSettings' ><font color='red'><%=errMsg.toString()%></font><br/><br/><table width='100%'><tr><td align='center'><input name='ok_btn' type='image' src='<%=ar.retPath%>assets/btnOK.gif' onclick='cancelPanel()'/></td></tr></table></div>", "500px");
</script>
<%
session.setAttribute("error-msg", null);
}else if("yes".equalsIgnoreCase(throughEmail)){
%>
<script>
createPanel("Confirmation", "<div class='generalPopupDiv' align='center' >New Email Id has been added successfully. <br/><br/><table width='100%'><tr><td align='center'><input name='ok_btn' type='image' src='<%=ar.retPath%>assets/btnOK.gif' onclick='clickOk()'/></td></tr></table></div>", "500px");
</script>
<%
}else if("yes".equalsIgnoreCase(openIdMsg)){
    %>
    <script>
    createPanel("Confirmation", "<div class='generalPopupDiv' align='center' >New Id has been added successfully. <br/><br/><table width='100%'><tr><td align='center'><input name='ok_btn' type='image' src='<%=ar.retPath%>assets/btnOK.gif' onclick='clickOk()'/></td></tr></table></div>", "500px");
    </script>
    <%
    }
%>

<script>

    function clickOk(){
        window.location = "<%=ar.baseURL%>v/<%ar.write(uProf.getKey());%>/editUserProfile.htm";
    }

    function addUserId(openIdList){
        if(document.getElementById("openIdRadio").checked == true){
            document.getElementById("txtBoxOpenId").value = document.getElementById("openIdTxtBx").value;
        }else{
            var chkBox = document.getElementsByName("openIdRadioGp");
            for (var i = 0; i <= chkBox.length - 1; i++)
                if(chkBox[i].checked){
                    var txtBxId = "openIdTxtBx"+(i-1);
                    document.getElementById("txtBoxOpenId").value = document.getElementById(txtBxId).value;
                }
        }

        var newid = document.getElementById("txtBoxOpenId").value;
        var newidLength = newid.length;
        var status = true;
        var newidValue = newid;
        if(newid.charAt(newidLength-1)=="/"){
            newidValue = newid.substring(0, newidLength-1);
        }
        var openIds = openIdList.split("+");
        var openIdsCount = openIdList.split("+").length;
        for(var i=0; i< openIdsCount;i++){
            var openId = openIds[i];
            var idLength = openId.length;
            if(openId.charAt(idLength-1)=="/"){
                openId = openId.substring(0, idLength-1);
            }
            if(openId.toLowerCase()==newidValue.toLowerCase()){
                alert("Id already exist.");
                status = false;
                break;
            }
        }

        if(status == true){
            document.getElementById("updateOpenIdForm").submit();
           //var postURL = "<%=ar.retPath %>t/addUserId.ajax?newid="+newid+"&go=<%ar.writeURLData(go);%>&isEmail=false";
           //var transaction = YAHOO.util.Connect.asyncRequest('POST', postURL, addUserIdResult);
        }
        return false;
    }

    function addEmailId(emailList){
        var newid = document.getElementById("txtBoxEmailId").value;
        var newidLength = newid.length;
        var status = true;
        var newidValue = newid;
        if(newid.charAt(newidLength-1)=="/"){
            newidValue = newid.substring(0, newidLength-1);
        }
        var emailIds = emailList.split("+");
        var emailIdsCount = emailList.split("+").length;
        for(var i=0; i< emailIdsCount;i++){
            var emailId = emailIds[i];
            var idLength = emailId.length;
            if(emailId.charAt(idLength-1)=="/"){
                emailId = emailId.substring(0, idLength-1);
            }
            if(emailId==newidValue){
                alert("Id already exist.");
                status = false;
                break;
            }
        }

        var go = "<%=ar.baseURL %>v/<%=uProf.getKey()%>/confirmedAddIdView.htm?addedEmailId="+newid;
        if(status == true){
            var postURL = "<%=ar.baseURL %>t/addUserId.ajax?newid="+encodeURI(newid)+"&isEmail=true&go="+encodeURI(go);
            var transaction = YAHOO.util.Connect.asyncRequest('POST', postURL, addEmailIdResult);
        }
        return false;
    }
    var  addEmailIdResult = {
           success: function(o) {
           var respText = o.responseText;
           var json = eval('(' + respText+')');
           if(json.msgType == "success"){
               var gotoPage  = "<%=ar.getCompleteURL()%>";
               var option = '<%=ProfileRequest.getPromptString(ProfileRequest.ADD_EMAIL)%>';
               openSubPanel('Confirmation',json.newId , option ,'550px');
           }else{
               showErrorMessage("Result", json.msg , json.comments );
           }

       },
       failure: function(o) {
               alert("addUserId.ajax Error:" +o.responseText);
       }
    }

    function openSubPanel(header,email,option,panelWidth){
        var onclick = "goForConfirmation('"+option+"','"+email+"')";
        var bodyText =  '<div id="errorDiv" style="color:red; font-style:italic; font-size:11px;">'+
            '</div>'+
            '<div class="generalPopupSettings">'+
                '<form action="<%=ar.baseURL%>t/waitForEmailAction.form" method="post">'+
                '<table> '+
                    '<tr><td style="height:10px"></td></tr>'+
                    '<tr>'+
                        '<td colspan="3">An email message has been sent to <b>'+email+'</b> <br/>'+
                        'with a confirmation key in it. Check your mail box and click on the link provided or copy the confirmation key into the following box.'+
                        '</td>'+
                    '</tr>'+
                    '<tr><td style="height:20px"></td></tr>'+
                    '<tr>'+
                        '<td class="gridTableColummHeader_2">Email:</td>'+
                        '<td style="width:20px;"></td>'+
                        '<td><b>'+email+'</b></td>'+
                    '</tr>'+
                    '<tr><td style="height:10px"></td></tr>'+
                    '<tr>'+
                        '<td class="gridTableColummHeader_2">Confirmation Key:</td>'+
                        '<td style="width:20px;"></td>'+
                        '<td><input type="text" id="mn" name="mn" value="" size="50"></td>'+
                    '</tr>'+
                    '<tr><td style="height:10px"></td></tr>'+
                    '<tr>'+
                        '<td class="gridTableColummHeader_2"></td>'+
                        '<td style="width:20px;"></td>'+
                        '<td>'+
                        '<input type="submit" class="btn btn-primary" value="Add Email">'+
                        '</td>'+
                    '</tr>'+
                    '<tr><td style="height:20px"></td></tr>'+
                    '<tr>'+
                        '<td colspan="3">After putting the correct confirmation key & pressing the "Add Email" button will allow you to reset'+
                        ' the password of the specified email address.'+
                        '<hr/>'+
                        'If you are done waiting, use this link to <a href="#" onclick="subPanel.hide();">return</a>.'+
                        '</td>'+
                    '</tr>'+
                '</table>'+
                '<input type="hidden" id="go" name="go" value="<%ar.write(ar.getRequestURL()+"?addthroughEmail=yes");%>">'+
                '<input type="hidden" id="email" name="email" value="'+email+'">'+
                '<input type="hidden" id="option" name="option" value="'+option+'">'+
                '</form>'+
            '</div>';
        isConfirmPopup = true;
        subPanel = new YAHOO.widget.Panel("win", {
                                                width: panelWidth ,
                                                fixedcenter: true,
                                                constraintoviewport: true,
                                                underlay: "shadow",
                                                close: true,
                                                visible: false,
                                                draggable: true,
                                                modal: true
                                            });
        subPanel.setHeader(header);
        subPanel.setBody(bodyText);
        subPanel.render(document.body);
        subPanel.show();
    }

    function goForConfirmation(option, email,confkeyObj){
        if(confkeyObj != null && trimme(confkeyObj.value) != ""){
            var postURL = "<%=ar.retPath %>t/confirmEmail.ajax?email="+email+"&go=<%ar.writeURLData(go);%>&option="+option+"&mn="+confkeyObj.value;
            var transaction = YAHOO.util.Connect.asyncRequest('POST', postURL,confirmationResult);
        }else{
            alert("Please enter confirmation key.");
            return false;
        }

    }

    var confirmationResult = {
        success: function(o) {
                        var respText = o.responseText;
                        var json = eval('(' + respText+')');
                        if(json.msgType == "success"){
                            appendEmailIdList("emailIdsList",json.email);
                            if(document.getElementById("noAlternateEmail")!=null)
                                removeTD("noAlternateEmail");
                            isConfirmPopup = false;
                            alert("Email id has been added successfully.");
                            subPanel.hide();
                        }else{
                             document.getElementById("errorDiv").innerHTML = responseTxt[1];
                             document.getElementById("confkey").value="";
                             document.getElementById("confkey").focus();
                             return false;
                        }
         },
         failure: function(o) {
                    alert("confirmEmail.ajax Error:" +o.responseText);
         }
     }

    function appendEmailIdList(tableId,email)
    {
        var table = document.getElementById(tableId);
        var row = document.createElement("tr");
        var td = document.createElement("td");
        var htmlStr = "<input type='radio' name='preferredEmail' value='"+email+"'/>"+email+"&nbsp;&nbsp;<a href='javascript:removeUserId(\'"+email+"\',false);' title='Remove'><img src='<%=ar.retPath%>assets/iconDelete.gif' alt='Remove'/></a>";

        td.innerHTML = htmlStr;
        row.appendChild(td);
        table.appendChild(row);
    }

    function appendOpenIdList(tableId,email)
    {
        var table = document.getElementById(tableId);
        var row = document.createElement("tr");
        var td = document.createElement("td");
        td.appendChild(document.createTextNode(email));
        row.appendChild(td);
        table.appendChild(row);
    }

    function displayDiv(show,openIdDiv,openIdCount){
        if(document.getElementById("openIdRadio").checked == true){
            document.getElementById("openIdDiv").style.display = 'block';
        }else{
            document.getElementById("openIdDiv").style.display = 'none';
        }
        for(var i=0; i< openIdCount;i++){
            var divId = "openIdDiv"+i;
            if((show == 'yes')&&(divId == openIdDiv)){
                document.getElementById(divId).style.display = 'block';
            }else{
                document.getElementById(divId).style.display = 'none';
            }
        }
    }

    function fillIdThroughTemplate(uNameTxtBox,myTemlateId,myTemp){
        var username = uNameTxtBox.value;
        var finalLoginId = myTemp;
        finalLoginId = finalLoginId.replace("{id}", username);
        document.getElementById(myTemlateId).value = finalLoginId;

    }

</script>

<%!

    public UserProfile findSpecifiedUserOrDefault(AuthRequest ar)
        throws Exception
    {
        String u = ar.defParam("u", null);
        UserProfile up = null;
        if (u!=null)
        {
            up = UserManager.getUserProfileByKey(u);
            if (up==null)
            {
                Thread.sleep(3000);
                throw new NGException("nugen.exception.user.not.found.invalid.key",new Object[]{u});
            }
        }
        else
        {
            if (!ar.isLoggedIn())
            {
                return null;
            }
            up = ar.getUserProfile();

            //every logged in user should have a profile, so should never hit this
            if (up == null)
            {
                throw new ProgramLogicError("every logged in user should have a profile, why is it missing in this case?");
            }
        }
        return up;
    }

%>