<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%/*
Required parameters:

    1. p    : This is the id of a Workspace and used to retrieve NGPage.
    2. oid  : This is Leaflet id which is used to retieve Leaflet information which is being send
              by email (TopicRecord object).

Optional Parameters:

    1. note         : This is the introductory comment in email.
    2. toRole       : These are the list of role selected to send email to them.
    3. exclude      : This is used to check if responders are excluded or not.
    4. tempmem      : Used to provide temprary membership.
    5. emailto      : Extra list of email id other than members who are not in roles.
    6. subject      : Get subject of email if any.
    7. attach{docid}: This optional parameter is used to get list of earlier selected document.
*/

    String p = ar.reqParam("p");
    String oid = ar.reqParam("oid");
    String encodingGuard  = ar.reqParam("encodingGuard");
    //if (!"\u6771\u4eac".equals(encodingGuard)) {
    //    throw new Exception("values are corrupted");
    //}

    String note = ar.defParam("note", "Sending this note to let you know about a recent update to this web page has information that is relevant to you.  Follow the link to see the most recent version.");
    String selectedRoles = ar.defParam("toRole", null);
    boolean exclude = (ar.defParam("exclude", null)!=null);
    boolean self    = (ar.defParam("self", null)!=null);
    boolean tempmem = (ar.defParam("tempmem", null)!=null);
    String emailto  = ar.defParam("emailto", null);
    String subject  = ar.defParam("subject", null);
    //getting the value of attach{docid} i.e. ar.defParam(paramId, null) on the basis of dynamic docid.%><%!String pageTitle="";%>
<%
    pageTitle  ="Send Topic By Mail";

    List selectedRoleList = null;
    if(selectedRoles!=null){
         selectedRoleList = Arrays.asList(selectedRoles.split(","));
    }
    ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Can not send email.");
    UserProfile uProf = ar.getUserProfile();
    String userFromAddress = uProf.getEmailWithName();

    String body = "";
    String noteSubject = "";

    if (!oid.equals("x"))
    {
        TopicRecord noteRec = ngp.getNoteOrFail(oid);
        noteSubject = noteRec.getSubject();
        if (noteSubject.length()>20) {
            noteSubject = noteSubject.substring(0,19)+"...";
        }
        if(subject == null){
            subject = noteRec.getSubject();
        }
        if(subject==null || subject.trim().length()==0){
            subject = "Topic from Workspace "+ngp.getFullName();
        }
        body = noteRec.getWiki();
    }
    if(subject == null){
        subject = "Message from Workspace "+ngp.getFullName();
    }

    List<CustomRole> roles = ngp.getAllRoles();

%>
<head>
<script type="text/javascript">
    function validateDelimEmails(field) {
      var count = 1;
      var result = "";
      var spiltedEmails;
      var value = trimme(field.value);
      if(value != ""){
          if(value.indexOf(";") != -1){
              spiltedEmails = value.split(";");
          }else if(value.indexOf(",") != -1){
              spiltedEmails = value.split(",");
          }else if(value.indexOf("\n") != -1){
              spiltedEmails = value.split("\n");
          }else{
              value = value+";";
              spiltedEmails = value.split(";");
          }
          for(var i = 0;i < spiltedEmails.length;i++){
              var email_id = trimme(spiltedEmails[i]);
              if(email_id != ""){
                  if(!validateEmail(email_id)){
                      result += "  "+count+".    "+email_id+" \n";
                      count++;
                  }
              }
          }
      }
      if(result != ""){
          alert("Below is the list of id(s) which does not look like an email. Please enter an email id(s).\n\n"+result);
          field.focus();
          return false;
      }

      return true;
    }    
    function validate(form) {
        var field = document.emailForm.emailto;
        if(validateDelimEmails(field)){
            var total=""
            for(var i=0;i<document.emailForm.checkboxRole.length;i++){
                if(document.emailForm.checkboxRole[i].checked){
                    total +=document.emailForm.checkboxRole[i].value+"," ;
                }
            }
            document.emailForm.toRole.value = total;
            return true;

        }else{
            return false;
        }
    }
</script>
</head>

<!--  here is where the content goes -->

    <div class="generalArea">
        <div class="generalContent">
            <form name="emailForm" id="emailForm" action="<%=ar.retPath%>t/CommentEmailAction.form"
                    method="post" onsubmit="return validate(this)"  enctype="application/x-www-form-urlencoded; charset=utf-8">
                <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
                <input type="hidden" name="p"       value="<%ar.writeHtml(p);%>"/>
                <input type="hidden" name="oid"     value="<%ar.writeHtml(oid);%>"/>
                <input type="hidden" name="go"      value="<%=ar.retPath%>t/closeWindow.htm"/>
                <input type="hidden" name="toRole"/>
                <!--<input type="hidden" name="anyErrors"     value=""/>-->
                <div style="float:right">
                     <input type="submit" name="action" id="action" class="btn btn-primary btn-raised" value="Send Mail"  />
                     <input type="submit" name="action" id="action" class="btn btn-primary btn-raised" value="Preview Mail" />
                </div>
                <table cellpadding="0" cellspacing="0" width="600">
                    <tr><td style="height:20px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader">From:</td>
                        <td style="width:20px;"></td>
                        <td>
                            <select name="emailFrom" STYLE="width: 380px">
                              <option value="person"><% ar.writeHtml(userFromAddress); %></option>
                              <option value="project"><% ar.writeHtml(composeFromAddress(ngp)); %></option>
                            </select>
                        </td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader">To:</td>
                        <td style="width:20px;"></td>
                        <td>
                        <%
                          for (NGRole ngRole: roles){
                              String roleNme=ngRole.getName();
                          %>
                            <input type="checkbox" name="checkboxRole" <%if (selectedRoleList!=null && selectedRoleList.contains(roleNme)) {out.write("checked=\"checked\"");}%> value="<%ar.writeHtml(roleNme); %>"> <%ar.writeHtml(roleNme); %>
                        <%}%>
                        </td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader">Other Settings:</td>
                        <td style="width:20px;"></td>
                        <td>
                            <input type="checkbox" name="exclude" value="exclude" <%if (exclude) {out.write("checked=\"checked\"");}%>>
                            Exclude Responders, &nbsp;
                            <input type="checkbox" name="self" value="self" <%if (self) {out.write("checked=\"checked\"");}%>>
                            Include Yourself
                        </td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader" valign="top">Also To:</td>
                        <td style="width:20px;"></td>
                        <td><textarea class="textAreaGeneral" rows="2" id="emailto" name="emailto"><% if (emailto!=null) {ar.writeHtml(emailto);}%></textarea>
                        <br/><input type="checkbox" name="makeMember" value="makeMember"> Make above people members. </td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader" valign="top">Introduction:</td>
                        <td style="width:20px;"></td>
                        <td>
                            <textarea class="textAreaGeneral" rows="6" name="note"><%ar.writeHtml(note);%></textarea>
                        </td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader">Subject:</td>
                        <td style="width:20px;"></td>
                        <td>
                            <input type="text" class="inputGeneral" id="subject" name="subject" value="<%ar.writeHtml(subject); %>" size="80%"/>
                            <!--<b><%ar.writeHtml(subject);%></b>-->
                        </td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>

                    <% if (!oid.equals("x")) { %>
                    <tr>
                        <td class="gridTableColummHeader">Content:</td>
                        <td style="width:20px;"></td>
                        <td><input id="includeBodyCheckBox" type="checkbox" name="includeBody"> Include topic '<%ar.writeHtml(noteSubject);%>' into email</td>
                    </tr>
                    <% } %>
                    <tr>
                        <td class="gridTableColummHeader" valign="top" nowrap="nowrap">Include these Attachments:</td>
                        <td style="width:20px;"></td>
                        <td>
                        <%
                        for (AttachmentRecord att : ngp.getAllAttachments())
                        {
                            if (att.isDeleted())
                            {
                                //skip and don't allow attachment of deleted documents
                                continue;
                            }
                            String paramId = "attach"+att.getId();
                            boolean attSelected = (ar.defParam(paramId, null)!=null);
                            String niceName = att.getNiceName();
                        %>
                                <input type="checkbox" name="<%ar.writeHtml(paramId); %>" value="true" <%if(attSelected) { ar.write("checked=\"checked\"");}%>>
                        <%
                            ar.writeHtml(niceName);
                        %><br/>
                        <%
                        }
                        %>
                        </td>
                    </tr>
                    <tr><td style="height:30px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader">Send Files:</td>
                        <td style="width:20px;"></td>
                        <td><input id="includeFilesCheckBox" type="checkbox" name="includeFiles"> Actually send files as attachments to the email (unprotected)</td>
                    </tr>

<%
    String overrideAddress = EmailSender.getProperty("overrideAddress");
    if (overrideAddress!=null && overrideAddress.length()>0) {
%>
                    <tr><td style="height:30px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader" valign="top">Override Address Active:</td>
                        <td style="width:20px;"></td>
                        <td>Note: this server is configured in email test mode.  Messages will be composed to
                            users and participants having different email addresses, but the messages will
                            not actually be sent there!  Instead, all email from this server will actually
                            be sent to the override address (<b><% ar.writeHtml(overrideAddress); %></b>).
                            This is configured in the WEB-INF/EmailNotification.properties file by
                            giving a value to the 'overrideAddress' property.   Leave this property
                            empty in order to take the server out of test mode, into production mode,
                            where it actually sends email to the actual addresses.</td>
                    </tr>
<%
    }
%>


                    <tr><td style="height:30px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader" valign="top">Unsubscribe:</td>
                        <td style="width:20px;"></td>
                        <td>
                            People who receive email messages because they are a member of a role,
                            will have the option to remove themselves from the role.
                            These links take you to a sample message for a fictional user
                            email address "sample@example.com" that such a person would see
                            (for each of the <%=roles.size()%> roles):
                            <%
                               for (NGRole ngRole: roles){
                                   String url = ar.retPath+"t/EmailAdjustment.htm?pageId="+URLEncoder.encode(p,"UTF-8")
                                        +"&siteId="+URLEncoder.encode(p.getSiteKey(),"UTF-8")
                                        +"&st=role&role="+URLEncoder.encode(ngRole.getName(),"UTF-8")
                                        +"&email="+URLEncoder.encode("sample@example.com","UTF-8")
                                        +"&mn="+URLEncoder.encode(ngp.emailDependentMagicNumber("sample@example.com"),"UTF-8");
                                   ar.write("&nbsp; <a href=\""+url+"\">");
                                   ar.writeHtml(ngRole.getName());
                                   ar.write("</a>, &nbsp; ");
                               }
                            %>
                        </td>
                    </tr>
                </table>
            </form>
        </div>
        <%@ include file="/spring/jsp/functions.jsp"%>
<%!private static String composeFromAddress(NGContainer ngc) throws Exception
    {
        StringBuilder sb = new StringBuilder("^");
        String baseName = ngc.getFullName();
        int last = baseName.length();
        for (int i=0; i<last; i++)
        {
            char ch = baseName.charAt(i);
            if ( (ch>='0' && ch<='9') || (ch>='A' && ch<='Z') || (ch>='a' && ch<='z') || (ch==' '))
            {
                sb.append(ch);
            }
        }

        //now add email address in angle brackets
        sb.append(" <");
        sb.append("server@example.com");
        sb.append(">");
        return sb.toString();
    }%>
