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
    int notePeriod = uProf.getNotificationPeriod();
    String preferredEmail = uProf.getPreferredEmail();
    pageTitle = "User: "+uProf.getName();
    String photoSource = ar.retPath+"assets/photoThumbnail.gif";
    if(uProf.getImage().length() > 0){
        photoSource = ar.retPath+"users/"+uProf.getImage();
    }
    Object errMsg = session.getAttribute("error-msg");

%>
<fmt:setBundle basename="messages"/>
<script>

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
                        <td colspan="2"><input type="button" class="btn btn-primary" value="Upload Photo"
                            onclick="javascript:uploadUserPhoto();"/></td>
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
                        <td class="gridTableColummHeader_2" style="vertical-align:top">Notification Period:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                            <input type="radio" name="notificationPeriod" value="1"  <% if(notePeriod<=3) {ar.write("checked=\"checked\" ");} %>> Daily
                            <input type="radio" name="notificationPeriod" value="7"  <% if(notePeriod<=20 && notePeriod>3) {ar.write("checked=\"checked\" ");} %>> Weekly
                            <input type="radio" name="notificationPeriod" value="30" <% if(notePeriod>20) {ar.write("checked=\"checked\" ");} %>> Monthly
                        </td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2"></td>
                        <td style="width:20px;"></td>
                        <td colspan="2"><input type="button" class="btn btn-primary" onclick="updateProfile('Save')" value="Update Personal Details"/></td>
                    </tr>
                    <tr><td style="height:60px"></td></tr>

                    <tr>
                        <td class="gridTableColummHeader_2"></td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                            <input type="button" class="btn btn-primary" onclick="updateProfile('Cancel')" value="Go Back To My Settings"/>
                        </td>
                    </tr>
                </table>
            </form>
        </div>
    </div>



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