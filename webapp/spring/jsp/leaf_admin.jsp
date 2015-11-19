<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="include.jsp"
%><%@page import="org.socialbiz.cog.TemplateRecord"
%><%@page import="org.socialbiz.cog.EmailGenerator"
%><%@page import="org.socialbiz.cog.CommentRecord"
%><%@page import="org.socialbiz.cog.mail.ScheduledNotification"
%><%@page import="java.util.ArrayList"
%>
<%
    ar.assertLoggedIn("Must be logged in to see admin options");
    ar.assertMember("This VIEW only for members in use cases");

    String pageId      = ar.reqParam("pageId");
    NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(pageId);
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();
    Cognoscenti cog = ar.getCogInstance();

    UserProfile up = ar.getUserProfile();
    String userKey = up.getKey();

    Vector<NGPageIndex> templates = new Vector<NGPageIndex>();
    for(TemplateRecord tr : up.getTemplateList()){
        NGPageIndex ngpirr = ar.getCogInstance().getContainerIndexByKey(tr.getPageKey());
        if (ngpirr!=null) {
            //silently ignore templates that no longer exist
            templates.add(ngpirr);
        }
    }
    NGPageIndex.sortInverseChronological(templates);

    String thisPage = ar.getResourceURL(ngp,"admin.htm");
    String allTasksPage = ar.getResourceURL(ngp,"projectAllTasks.htm");

    String upstreamLink = ngp.getUpstreamLink();

    String[] names = ngp.getPageNames();
    String thisPageAddress = ar.getResourceURL(ngp,"admin.htm");

    ProcessRecord process = ngp.getProcess();
    String parentKey = ngp.getParentKey();
    NGPageIndex parentIndex = cog.getContainerIndexByKey(parentKey);
    String parentName = "";
    if (parentIndex!=null) {
        parentName = parentIndex.containerName;
    }

    JSONObject projectInfo = ngp.getConfigJSON();
    projectInfo.put("parentName", parentName);



    JSONArray oldNameArray = new JSONArray();
    for (int i = 1; i < names.length; i++) {
        //skip the first name since that is the current name
        oldNameArray.put(names[i]);
    }

    JSONArray allProjects = new JSONArray();
    for (NGPageIndex ngpis : cog.getAllProjectsInSite(ngb.getKey())) {
        if (ngpis.isDeleted) {
            continue;
        }
        JSONObject pInfo = new JSONObject();
        pInfo.put("name", ngpi.containerName);
        pInfo.put("key", ngpi.containerKey);
        allProjects.put(pInfo);
    }


%>


<script type="text/javascript" language="JavaScript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.oldNameArray = <%oldNameArray.write(out,2,4);%>;
    $scope.projectInfo = <%projectInfo.write(out,2,4);%>;
    $scope.allProjects = <%allProjects.write(out,2,4);%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.lookUpName = function(prjKey) {
        for (var i=0; i<$scope.allProjects.length; i++) {
            if ($scope.allProjects[i].key==prjKey) {
                return $scope.allProjects[i].name;
            }
        }
        return "(unknown)";
    }
    $scope.projectMode = function() {
        if ($scope.projectInfo.deleted) {
            return "deletedMode";
        }
        if ($scope.projectInfo.frozen) {
            return "freezedMode";
        }
        return "normalMode";
    }
    $scope.saveProjectConfig = function() {
        var postURL = "updateProjectInfo.json";
        var postdata = angular.toJson($scope.projectInfo);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.projectInfo = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };


});
app.filter('escape', function() {
  return window.encodeURIComponent;
});
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

<% if (!ar.isAdmin()) { %>

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

<% }else { %>

            <div>
                <table>
                    <form action="changeProjectName.form" method="post" >
                        <tr>
                            <td class="gridTableColummHeader_2"><fmt:message key="nugen.generatInfo.PageNameCaption"/>:</td>
                            <td style="width:20px;"></td>
                            <td><input type="hidden" name="p" value="<%ar.writeHtml(pageId);%>">
                                <input type="hidden" name="encodingGuard" value="%E6%9D%B1%E4%BA%AC"/>
                                <input type="hidden" name="go" value="<%ar.writeHtml(ar.getCompleteURL());%>">
                                <input type="text" class="form-control" style="width:300px" name="newName" value="<%ar.writeHtml(ngp.getFullName());%>">
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

                <tr ng-repeat="name in oldNameArray">
                    <td></td>
                    <td></td>
                    <td>
                        <a href="deletePreviousProjectName.htm?action=delName&p=<%=URLEncoder.encode(pageId, "UTF-8")%>&oldName={{name|escape}}"
                           title="delete this name from workspace">
                           {{name}}
                           <img src="<%=ar.retPath%>/assets/iconDelete.gif">
                        </a>
                    </td>
                </tr>
                </table>
            </div>
            <div class="generalContent">
                <div class="generalHeading paddingTop">Workspace Settings</div>
                <table width="720px">
                    <tr><td style="height:5px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2">Goal:</td>
                        <td style="width:20px;"></td>
                        <td>
                            <input type="text" name="goal" class="form-control" ng-model="projectInfo.goal">
                        </td>
                    </tr>
                    <tr><td style="height:5px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2" valign="top">Purpose:</td>
                        <td style="width:20px;"></td>
                        <td><textarea name="purpose" class="form-control" ng-model="projectInfo.purpose"
                              rows="4"></textarea></td>
                    </tr>
                    <tr><td style="height:8px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2" valign="top">Workspace Mode:</td>
                        <td style="width:20px;"></td>
                        <td  valign="top">

                            <input type="checkbox" name="allowPublic" value="yes"
                                ng-model="projectInfo.frozen"/> Frozen  &nbsp;&nbsp;
                            <input type="checkbox" name="allowPublic" value="yes"
                                ng-model="projectInfo.deleted"/> Deleted

                            <input type="hidden" name="projectMode" value="{{projectMode()}}"/>
                        </td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader_2">Allow Public:</td>
                        <td style="width:20px;"></td>
                        <td>
                            <input type="checkbox" name="allowPublic" value="yes"
                                ng-model="projectInfo.allowPublic"/> {{projectInfo.allowPublic}}
                        </td>
                    </tr>
                    <tr><td style="height:5px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2">Workspace Email id:</td>
                        <td style="width:20px;"></td>
                        <td>
                            <input type="text" class="form-control"
                                   name="projectMailId" ng-model="projectInfo.projectMail" />
                        </td>
                    </tr>
                    <tr><td style="height:5px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2">Upstream Clone:</td>
                        <td style="width:20px;"></td>
                        <td>
                            <input type="text" class="form-control" style="width:450px" id="upstream"
                                   name="upstream" ng-model="projectInfo.upstream" />
                        </td>
                    </tr>
                    <tr><td style="height:5px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2">Parent Circle:</td>
                        <td style="width:20px;"></td>
                        <td>
                            <input type="text" ng-model="projectInfo.parentKey" class="form-control" style="width:100px"/>
                            {{lookUpName(projectInfo.parentKey)}}
                        </td>
                    </tr>


                    <!--tr><td style="height:5px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2">Default Location:</td>
                        <td  style="width:20px;"></td>
                        <td>
                            <input type="button" class="btn btn-primary" name="action"
                                value="Browse" onclick="browse()">
                        </td>
                    </tr-->

                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2"></td>
                        <td style="width:20px;"></td>
                        <td>
                            <button ng-click="saveProjectConfig();" class="btn btn-primary" >Update</button>
                        </td>
                    </tr>
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

<% } %>

            <div class="generalContent">
                <div class="generalHeading paddingTop">Future Scheduled Actions</div>
                <div>
                   Next Action due: {{<%=ngp.nextActionDue()%>|date:'M/d/yy H:mm'}}
                </div>
                <div>
                   Index says: {{<%=ngpi.nextScheduledAction%>|date:'M/d/yy H:mm'}}
                </div>
                <div>
                    OVERDUE:
                    <ul>
                    <%findOverdueContainer(ar);%>
                    </ul>
                    ALL UNSENT NOTIFICATIONS:
                    <ol>
                    <%

                    ArrayList<ScheduledNotification> allUnsent = new ArrayList<ScheduledNotification>();

                    //Now scan all the comments on all the topics
                    int ii = 0;
                    ngp.gatherUnsentScheduledNotification(allUnsent);
                    for (ScheduledNotification sn : allUnsent) {
                        if (sn!=null) {
                            long timeToAct = sn.timeToSend();
                            ar.write("<li>"+ (++ii)+": ");
                            ar.writeHtml( (new Date(timeToAct)).toString() );
                            ar.write(", ");
                            ar.writeHtml( sn.selfDescription() );
                            if (timeToAct < ar.nowTime) {
                                ar.write("  <b>OVERDUE!</b>");
                            }
                            ar.write("</li>");
                        }
                    }



                    %>
                    </ol>
                </div>
            </div>

    </div>
</div>

<%!

    private NGPageIndex findOverdueContainer(AuthRequest ar) throws Exception  {
        for (NGPageIndex ngpi : ar.getCogInstance().getAllContainers()) {
            if (ngpi.nextScheduledAction>0 && ngpi.nextScheduledAction<ar.nowTime) {
                ar.write("<li>");
                ar.writeHtml(ngpi.containerName);
                ar.write(": ");
                ar.write( (new Date(ngpi.nextScheduledAction)).toString() );
                ar.write("</li>");
            }
        }
        return null;
    }


%>
