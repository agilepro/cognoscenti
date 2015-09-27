<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%/*
Required parameter:

    1. container    : This is the id of a container and used to retrieve NGPage.
    2. mn           : This is magic number which is send to the controller to ensure that is request is come
                      from the user who recieved the email.
    3. emailId      : This parameter is the email-id that need to be either used to create a new profile or just
                      added to the existing user's profile.

*/
    String containerId = ar.reqParam("container");
    String mn = ar.reqParam("mn");
    String emailId  = ar.reqParam("emailId");

    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(containerId);
    String go = ar.baseURL+"t/"+ngp.getSite().getKey()+"/"+ngp.getKey()+"/history.htm";%>

<style type="text/css">
    #bodyWrapper {
        margin:0px auto 45px auto;
        width:935px;
        position:relative;
    }
</style>
<script>

    function submit(formId){
        document.getElementById(formId).submit();
    }

    function gotoproject(){
        window.location = "<%=ar.baseURL%><%=ar.getDefaultURL(ngp)%>";
    }
    function gotoAdd(){
        window.location = "<%=ar.baseURL%>t/EmailLoginForm.htm?go=<%ar.writeURLData(ar.getCompleteURL());%>";
    }
</script>

<div class="generalContent" >
    <table cellpadding="0" cellspacing="0" width="100%" >
        <tr>
            <td colspan="3">
            <%
                if (ar.isLoggedIn())
                {
                    UserProfile uProf = ar.getUserProfile();
            %>
                You are already logged in as <%
                uProf.writeLink(ar);
            %>. Please choose any option
                from the following :
            </td>
        </tr>
        <tr>
            <td colspan="3">&nbsp;</td>
        </tr>
        <tr height="25px">
            <td width="5%">&nbsp;</td>
            <td colspan="2">
                1). &nbsp;Click on <a href="<%=ar.baseURL%>t/LogoutAction.htm?go=<%ar.writeURLData(ar.getCompleteURL());%>" >
                Log Out</a> to create a New profile for &nbsp;<b>'<%
                ar.writeHtml(emailId);
            %>'</b>&nbsp; Email id.
            </td>
        </tr>
        <tr height="25px">
            <td width="5%">&nbsp;</td>
            <td colspan="2">
                <form action="addEmailToProfile.form" method="post">
                    <input type="hidden" name="emailId" value="<%ar.writeHtml(emailId);%>"/>
                    <input type="hidden" name="mn" value="<%ar.writeHtml(mn);%>"/>
                    <input type="hidden" name="containerId" value="<%ar.writeHtml(containerId);%>"/>
                    2).&nbsp; <input type="submit" class="btn btn-primary" value="Claim this email to existing profile" />
                </form>
            </td>
        </tr>
        <tr height="25px">
            <td width="5%">&nbsp;</td>
            <td colspan="2">
                3). &nbsp;No not claim the Email id, <a href="<%=ar.baseURL%><%=ar.getDefaultURL(ngp)%>" >
                Just go on to the workspace page.</a>
            </td>
        </tr>

        <%
            }else{
        %>
        <tr>
            <td valign="top" style="width:370px">
                <div class="generalHeading">Claim This Email Address</div>
                <div class="loginBox">
                    <table>
                        <tr>
                            <td style="padding:20px;" >
                                <form action="invitedUserRegitsrationSubmit.form" method="post" id="newRegisterForm">
                                    <input type="hidden" name="go" value="<%ar.writeHtml(go);%>"/>
                                    <input type="hidden" name="email" value="<%ar.writeHtml(emailId);%>"/>
                                    <input type="hidden" name="mn" value="<%ar.writeHtml(mn);%>"/>
                                    <input type="hidden" name="containerId" value="<%ar.writeHtml(containerId);%>"/>

                                    <table>
                                        <tr><td><b>Email Address:</b></td></tr>
                                        <tr>
                                            <td><%
                                                ar.writeHtml(emailId);
                                            %></td>
                                            <td>&nbsp;</td>
                                            <td></td>
                                        </tr>

                                        <tr>
                                            <td style="height:10px;"></td>
                                        </tr>
                                        <tr>
                                            <td><b>Full Name (for display):</b></td>
                                        </tr>
                                        <tr>
                                            <td><input type="text" class="loginInput" name="userName" value="" /></td>
                                            <td>&nbsp;</td>
                                            <td></td>
                                        </tr>
                                        <tr>
                                            <td style="height:10px;"></td>
                                        </tr>
                                        <tr>
                                            <td><b>Password:</b></td>
                                        </tr>
                                        <tr>
                                            <td><input type="password" name="password" value="" class="loginInput" /></td>
                                        </tr>
                                        <tr>
                                            <td style="height:10px;"></td>
                                        </tr>
                                        <tr>
                                            <td><b>Re-Enter Password:</b></td>
                                        </tr>
                                        <tr>
                                            <td><input type="password" name="re-password" value="" class="loginInput" /></td>
                                        </tr>
                                        <tr>
                                            <td>&nbsp;</td>
                                        </tr>
                                        <tr>
                                            <td align="center">
                                                <a href="#" onclick="document.getElementById('newRegisterForm').submit();">
                                                <img src="<%=ar.retPath%>assets/btnRegisterNewProfile.gif" border="0"></a>
                                            </td>
                                        </tr>
                                        <tr>
                                    </table>
                                </form>
                            </td>
                        </tr>
                    </table>
                </div>
            </td>
            <td style="width:10px;">&nbsp;</td>
            <td valign="bottom" style="width:300px" align="center">
                <br/><br/>
                <div class="loginBox">
                    <table>
                        <tr>
                            <td style="padding:20px;">
                               <input type="button" class="btn btn-primary" value="Add this email to existing profile" onclick="gotoAdd();"/>
                            </td>
                        </tr>
                        <tr>
                            <td style="padding:20px;">
                                <input type="button" class="btn btn-primary" value="Don't claim the address, Just go to workspace page" onclick="gotoproject();"/>
                            </td>
                        </tr>
                    </table>
                </div>
            </td>
        </tr>
        <tr><td style="height:10px;"></td></tr>
        <tr>
            <td colspan="3">
                <i>
                    *After you have registered, you will have complete access to documents and other materials
                    collected for the <b><a href="<%=ar.retPath%><%=ar.getDefaultURL(ngp)%>">
                    <% ar.writeHtml(ngp.getFullName()); %></a></b>  workspace. You will be able to comment and contribute
                    as well.
                    </i>
            </td>
        </tr>
        <%} %>
    </table>
</div>
<%@ include file="functions.jsp"%>