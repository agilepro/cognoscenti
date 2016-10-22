<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    String pageId = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);

    List<CustomRole> roles = ngp.getAllRoles();
    if (roles==null) {
        throw new Exception("got a null role list object!");
    }

%>
<script>
    function validate(){
        var field = document.reminderForm.assignee;
        if(validateDelimEmails(field)){
            return checkVal('email');
        }else{
            return false;
        }
    }
</script>
<div>
    <div class="pageHeading">
       <fmt:message key="nugen.attachment.uploadattachment.SendEmailReminder" />
   </div>

   <%if(ngp.isFrozen()){ %>
           <div id="loginArea">
               <span class="black">
                    <fmt:message key="nugen.project.freezed.msg" />
               </span>
           </div>
   <%}else{ %>

   <div class="pageSubHeading">
       <fmt:message key="nugen.attachment.uploadattachment.information.text" />
   </div>
    <div class="generalSettings">
        <form name="reminderForm" id="reminderForm" action="emailReminder.form" method="post" onsubmit="return validate();">
            <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
            <table border="0px solid red" class="popups" width="100%">
                <tr>
                    <td class="gridTableColummHeader_2">
                        <fmt:message key="nugen.attachment.uploadattachment.To" />
                    </td>
                    <td  style="width:20px;"></td>
                      <td>
                        <!--<input type="text" id="assignee" name="assignee" class="inputGeneral" />-->
                        <input type="text" class="wickEnabled" name="assignee" id="assignee" size="69"   autocomplete="off" onkeyup="autoComplete(event,this);" onfocus="initsmartInputWindowVlaue('smartInputFloater','smartInputFloaterContent');"  /><fmt:message key="nugen.attachment.uploadattachment.Email" />
                        <div style="position:relative;text-align:left">
                            <table  class="floater" style="position:absolute;top:0;left:0;background-color:#cecece;display:none;visibility:hidden"  id="smartInputFloater"  rules="none" cellpadding="0" cellspacing="0">
                            <tr><td id="smartInputFloaterContent"  nowrap="nowrap" width="100%"></td></tr>
                            </table>
                        </div>



                      </td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr>
                      <td class="gridTableColummHeader_2">
                        <fmt:message key="nugen.attachment.uploadattachment.Subject" />
                      </td>
                      <td  style="width:20px;"></td>
                      <td>
                        <fmt:message key="nugen.attachment.uploadattachment.PleaseUploadFile" /><br> <input type="text" id="subj" name="subj" class="inputGeneral" />
                      </td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader_2">
                        <fmt:message key="nugen.attachment.uploadattachment.Instructions" />
                    </td>
                    <td  style="width:20px;"></td>
                    <td>
                        <textarea name="instruct" id="instruct" rows="4" class="textAreaGeneral"><fmt:message key="nugen.attachment.uploadattachment.PleaseUploadFile.text" /></textarea>
                    </td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader_2">
                        <fmt:message key="nugen.attachment.uploadattachment.DescriptionAttachFile" />
                    </td>
                    <td  style="width:20px;"></td>
                    <td>
                        <textarea name="comment" id="email_comment" rows="4" class="textAreaGeneral"></textarea>
                    </td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader_2"><fmt:message key="nugen.attachment.uploadattachment.Accessibility" /></td>
                    <td  style="width:20px;"></td>
                    <!--<td>
                        <input type="radio" name="visibility" value="*PUB*"/> <fmt:message key="nugen.attachment.uploadattachment.Public" />
                        <input type="radio" name="visibility" value="*MEM*" checked="checked"/><fmt:message key="nugen.attachment.uploadattachment.Member" />
                    </td>-->
                    <%
                    if (ar.isMember())
                    {
                    %>
                    <td>
                        <%
                            String publicMsg = "";
                            if("yes".equals(ngp.getAllowPublic())){
                        %>
                                <input type="radio" name="visibility" id="pubchoice" value="*PUB*"/> <fmt:message key="nugen.attachment.uploadattachment.Public" />
                        <%

                            }else{
                                publicMsg = ar.getMessageFromPropertyFile("public.attachments.not.allowed", null);
                            }
                        %>

                        <input type="radio" name="visibility" id="memchoice"  checked="checked"/>
                        <fmt:message key="nugen.attachment.uploadattachment.Member" />
                        <div style="color: gray;padding-top: 5px;" ><%ar.writeHtml(publicMsg); %></div>
                    </td>
                    <%
                    }else{
                    %>
                    <td>
                        <fmt:message key="nugen.attachment.uploadattachment.Public" />
                        <input type="hidden" id="visibility" name="visibility" value="*PUB*"/>
                    </td>
                    <%
                    }
                    %>
                </tr>
                </tr><tr><td style="height:20px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader_2">Notify:</td><td></td>
                    <td>
                    <% for (NGRole r : roles) {
                        String rName = r.getName();
                        %>
                        <input type="checkbox" name="role" value="<% ar.writeHtml(rName); %>">
                            <% ar.writeHtml(rName); %> &nbsp;
                    <% } %>
                    </td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader_2">
                        <fmt:message key="nugen.attachment.uploadattachment.ProposedName" />
                    </td>
                    <td  style="width:20px;"></td>
                    <td>
                        <input type="text" id="pname" name="pname" class="inputGeneral" />
                    </td>
                </tr>
                <tr>
                    <td class="gridTableColummHeader_2"></td>
                    <td  style="width:20px;"></td>
                    <td>
                        <span class="tipText"><fmt:message key="nugen.attachment.uploadattachment.EnterProposedName.text" /></span>
                    </td>
                </tr>
                </tr><tr><td style="height:20px"></td></tr>
                <tr>
                    <td></td>
                    <td style="width:20px;"></td>
                    <td>
                        <input type="submit" name="action" class="btn btn-primary btn-raised" value="<fmt:message key='nugen.attachment.uploadattachment.button.CreateEmailReminder'/>">
                        <input type="button"  class="btn btn-primary btn-raised"  name="action" value="<fmt:message key='nugen.button.general.cancel'/>" onclick="cancel();"/>
                    </td>
                </tr>
            </table>
        </form>
    </div>
        <%}
    %>
</div></div></div></div>
