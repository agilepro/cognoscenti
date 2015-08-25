<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="include.jsp"
%><%@page import="org.socialbiz.cog.TemplateRecord"
%>
<%
    ar.assertLoggedIn("Must be logged in to see admin options");
    ar.assertMember("This VIEW only for members in use cases");

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();

    UserProfile up = ar.getUserProfile();
    String userKey = up.getKey();

    Vector<NGPageIndex> templates = new Vector<NGPageIndex>();
    for(TemplateRecord tr : up.getTemplateList()){
        NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(tr.getPageKey());
        if (ngpi!=null) {
            //silently ignore templates that no longer exist
            templates.add(ngpi);
        }
    }
    NGPageIndex.sortInverseChronological(templates);

    String thisPage = ar.getResourceURL(ngp,"admin.htm");
    String allTasksPage = ar.getResourceURL(ngp,"projectAllTasks.htm");

    String upstreamLink = ngp.getUpstreamLink();

    String[] names = ngp.getPageNames();
    String thisPageAddress = ar.getResourceURL(ngp,"admin.htm");
%>


<script type="text/javascript" language="JavaScript">
    var isfreezed = '<%=ngp.isFrozen()%>';

    function updateProjectSettings(obj){
        if(confirm("Are you sure you want to change Project Settings?")){
            var allowPublic = "no";
            if(obj.checked){
                allowPublic = "yes";
            }
            var transaction = YAHOO.util.Connect.asyncRequest('POST',"updateProjectSettings.ajax?allowPublic="
                              +allowPublic+"&operation=publicPermission", updateResponse);
        }else{
            unChangedCheckBox(obj);
        }
    }
    var updateResponse ={
        success: function(o) {
            var respText = o.responseText;
            var json = eval('(' + respText+')');
            if(json.msgType == "success"){
                alert("Operation has been performed successfully.");
            }
            else{
                showErrorMessage("Result", json.msg, json.comments);
            }
        },
        failure: function(o) {
            alert("projectValidationResponse Error:" +o.responseText);
        }
    }

    function browse(){
        window.location = "<%=ar.retPath%>v/<%ar.writeHtml(userKey);%>/ListConnections.htm?pageId=<%ar.writeHtml(ngp.getKey());%>&fndDefLoctn=true";
    }

    function freezeOrUnfreezeProject(obj){
        var freezeUnfreezeProject = "unfreezeProject";
        var confirmation_msg = "This operation will unfreeze the project and user can modify the project. Are you sure you want to unfreeze this Project?";
        if(obj.checked){
            freezeUnfreezeProject = "freezeProject";
            confirmation_msg = "This operation will freeze the project and user can only view the project but can not modify. Are you sure you want to freeze this Project?";
        }
        if(confirm(confirmation_msg)){
            var transaction = YAHOO.util.Connect.asyncRequest('POST',"updateProjectSettings.ajax?operation="+freezeUnfreezeProject, updateResponse);
        }else{
            unChangedCheckBox(obj);
        }
    }

    function unChangedCheckBox(obj){
        if(obj.checked){
            obj.checked = false;
        }else{
            obj.checked = true;
        }
    }
    function checkFreezed(){
        if(isfreezed == 'false'){
            return true;
        }else{
            return openFreezeMessagePopup();
        }
    }
</script>



<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Admin Settings
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="">Do Nothing</a></li>
            </ul>
          </span>

        </div>
    </div>



    <div>
        <%
            if (!ar.isAdmin()) {
        %>
            <div class="generalContent">
                <fmt:message key="nugen.generatInfo.Admin.administration">
                    <fmt:param value='<%=ar.getBestUserId()%>'/>
                </fmt:message><br/>
            </div>
            <div class="generalHeading"><fmt:message key="nugen.generatInfo.PageNameCaption"/> </div>
            <div class="generalContent">
                <ul class="bulletLinks">
                <%
                    for (int i = 0; i < names.length; i++) {
                            ar.write("<li>");
                            ar.writeHtml( names[i]);
                            ar.write("</li>\n");
                        }
                %>
                </ul>
            </div>
        <%
            }else
                {
        %>

            <div>
                <table>
                    <form action="changeProjectName.form" method="post" onsubmit="return checkFreezed();">
                        <tr>
                            <td class="gridTableColummHeader_2"><fmt:message key="nugen.generatInfo.PageNameCaption"/>:</td>
                            <td style="width:20px;"></td>
                            <td><input type="hidden" name="p" value="<%ar.writeHtml(pageId);%>">
                                <input type="hidden" name="encodingGuard" value="%E6%9D%B1%E4%BA%AC"/>
                                <input type="hidden" name="go" value="<%ar.writeHtml(ar.getCompleteURL());%>">
                                <input type="text" class="inputGeneral" name="newName" value="<%ar.writeHtml(ngp.getFullName());%>">
                            </td>
                        </tr>
                        <tr><td style="height:5px" colspan="3"></td></tr>
                        <tr>

                            <td class="gridTableColummHeader_2"></td>
                            <td style="width:20px;"></td>
                            <td>
                                <input type="submit" value='<fmt:message key="nugen.generatInfo.Button.Caption.Admin.ChangePage"/>'
                                       name="action" class="btn btn-primary">
                            </td>
                        </tr>
                    </form>
                    <tr>
                        <td class="gridTableColummHeader_2"><fmt:message key="nugen.generatInfo.Admin.Page.PreviousDelete"/></td>
                        <td style="width:20px;"></td>
                        <td></td>
                    </tr>
                    <input type="hidden" name="p"
                            value="<%ar.writeHtml(ngp.getFullName());%>">
                    <input type="hidden" name="go"
                            value="<%ar.writeHtml(thisPage);%>">
                    <input type="hidden" name="encodingGuard"
                            value="%E6%9D%B1%E4%BA%AC" />
        <%
            for (int i = 1; i < names.length; i++) {
                String delLink = ar.retPath+"t/"+ngp.getSite().getKey()+"/"+ngp.getKey()
                    + "/deletePreviousProjectName.htm?action=delName&p="
                    + URLEncoder.encode(pageId, "UTF-8")
                    + "&oldName="
                    + URLEncoder.encode(names[i], "UTF-8");
                out.write("<tr><td></td><td></td><td>");
                ar.writeHtml( names[i]);
                out.write(" &nbsp; <a href=\"");
                if(ngp.isFrozen()){
                    out.write("#\" onclick=\"javascript:openFreezeMessagePopup();\" ");
                }else{
                    ar.writeHtml( delLink);
                }
                out.write("\" title=\"delete this name from project\"><img src=\"");
                out.write(ar.retPath);
                out.write("/assets/iconDelete.gif\"></a></td></tr>\n");
                out.write("</td></tr>\n");
            }
        %>
                </table>
            </div>
            <div class="generalContent">
                <div class="generalHeading paddingTop">Project Settings</div>
                <table width="720px">
            <%
            ProcessRecord process = ngp.getProcess();

            String goal = process.getSynopsis();
            String purpose = process.getDescription();
            %>
                    <form action="changeProjectSettings.form" method="post" >
                        <input type="hidden" name="p" value="<%ar.writeHtml(pageId);%>">
                        <input type="hidden" name="go" value="<%ar.writeHtml(thisPageAddress);%>">
                        <input type="hidden" name="encodingGuard" value="%E6%9D%B1%E4%BA%AC"/>
                        <tr><td style="height:5px"></td></tr>
                        <tr>
                            <td class="gridTableColummHeader_2">Goal:</td>
                            <td style="width:20px;"></td>
                            <td><input type="text" name="goal" id="txtGoal" class="inputGeneral"
                                value="<%ar.writeHtml(goal);%>"></td>
                        </tr>
                        <tr><td style="height:5px"></td></tr>
                        <tr>
                            <td class="gridTableColummHeader_2" valign="top">Purpose:</td>
                            <td style="width:20px;"></td>
                            <td><textarea name="purpose" id="txtPurpose" class="textAreaGeneral"
                                  rows="4"><%ar.writeHtml(purpose);%></textarea></td>
                        </tr>
                        <tr><td style="height:8px"></td></tr>
                        <tr>
                            <td class="gridTableColummHeader_2" valign="top">Project Mode:</td>
                            <td style="width:20px;"></td>
                            <td  valign="top">

                                <input type="radio" id="normalMode" name="projectMode" value="normalMode"
                                <% if(!ngp.isDeleted() && !ngp.isFrozen()){ %>
                                    checked="checked"
                                 <%} %>
                                 /> Normal &nbsp;&nbsp;<br/>

                                <input type="radio" id="freezedMode" name="projectMode" value="freezedMode"
                                <% if(ngp.isFrozen()){ %>
                                    checked="checked"
                                 <%} %>
                                 /> Frozen &nbsp;&nbsp;<br/>

                                <input type="radio" id="deletedMode" name="projectMode" value="deletedMode"
                                <% if(ngp.isDeleted()){ %>
                                    checked="checked"
                                 <%} %>
                                 /> Deleted &nbsp;&nbsp;
                            </td>
                        </tr>
                        <tr>
                            <td class="gridTableColummHeader_2">Allow Public:</td>
                            <td style="width:20px;"></td>
                            <td>
                                <%
                                    String checkedStr = "" ;
                                    if (ngp.getAllowPublic().equals("yes")) {
                                        checkedStr = "checked=\"checked\"" ;
                                    }
                                %>
                                <input type="checkbox" name="allowPublic" id="allowPublic" value="yes"
                                <%ar.writeHtml(checkedStr);%>  />
                            </td>
                        </tr>
                        <tr><td style="height:5px"></td></tr>
                        <tr>
                            <td class="gridTableColummHeader_2">Project Email id:</td>
                            <td style="width:20px;"></td>
                            <td>
                                <input type="text" class="inputGeneral" style="width: 250px" id="projectMailId"
                                       name="projectMailId" value="<% ar.writeHtml(ngp.getProjectMailId()); %>" />
                            </td>
                        </tr>
                        <tr><td style="height:5px"></td></tr>
                        <tr>
                            <td class="gridTableColummHeader_2">Upstream Link:</td>
                            <td style="width:20px;"></td>
                            <td>
                                <input type="text" class="inputGeneral" style="width: 250px" id="upstream"
                                       name="upstream" value="<% ar.writeHtml(ngp.getUpstreamLink()); %>" />
                            </td>
                        </tr>
                        <tr><td style="height:5px"></td></tr>
                        <tr>
                            <td class="gridTableColummHeader_2">Default Location:</td>
                            <td  style="width:20px;"></td>
                            <td>
                                <input type="button" class="btn btn-primary" name="action" value="Browse" onclick="browse()">
                            </td>
                        </tr>

                        <tr><td style="height:5px"></td></tr>
                        <tr>
                            <td class="gridTableColummHeader_2"></td>
                            <td style="width:20px;"></td>
                            <td>
                                <input type="submit" value="Update" class="btn btn-primary" />
                            </td>
                        </tr>
                        <tr><td style="height:10px" colspan="3"></td></tr>
                    </form>
                </table>
            </div>


            <div class="generalContent">
                <div class="generalHeading paddingTop">Copy From Template</div>
                <table width="720px">
                  <form action="<%=ar.retPath%>CopyFromTemplate.jsp" method="post">
                  <input type="hidden" name="go" value="<%ar.writeHtml(allTasksPage);%>">
                  <input type="hidden" name="p" value="<%ar.writeHtml(pageId);%>">
                    <tr>
                        <td class="gridTableColummHeader_2">Template:</td>
                        <td style="width:20px;"></td>
                        <td><select name="template">
                        <%
                            for (NGPageIndex temp : templates) {
                            %>
                            <option name="template" value="<%ar.writeHtml(temp.containerKey);%>"><%
                            ar.writeHtml(temp.containerName);
                            %></option>
                            <%
                            }
                        %>
                        </select></td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader_2"></td>
                        <td style="width:20px;"></td>
                        <td> <input type="submit" value="Copy From Template" class="btn btn-primary"> </td>
                    </tr>
                  </form>
                </table>
            </div>

            <%
        }
        %>
    </div>
</div>
