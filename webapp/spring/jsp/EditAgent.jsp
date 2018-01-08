<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="functions.jsp"
%><%@page import="org.socialbiz.cog.AgentRule"
%><%

    String go = ar.getCompleteURL();
    ar.assertLoggedIn("Must be logged in to see anything about a user");

    UserProfile uProf = (UserProfile)request.getAttribute("userProfile");
    if (uProf == null) {
        throw new NGException("nugen.exception.cant.find.user",null);
    }

    UserProfile  operatingUser =ar.getUserProfile();
    if (operatingUser==null) {
        //this should never happen, and if it does it is not the users fault
        throw new ProgramLogicError("user profile setting is null.  No one appears to be logged in.");
    }

    boolean viewingSelf = uProf.getKey().equals(operatingUser.getKey());

    UserPage uPage = uProf.getUserPage();
    String id = ar.reqParam("id");
    AgentRule theAgent = uPage.findAgentRule(id);
    if (theAgent==null) {
        throw new Exception("Unagle to find an agent with id="+id);
    }
    List<NGPageIndex> templates = uProf.getValidTemplates(ar.getCogInstance());
    List<NGBook> memberOfSites = uProf.findAllMemberSites();

%>
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Edit Agent");
    $scope.agent = <%theAgent.getJSON().write(out,2,4);%>;


    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.updateAgent = function() {
        var postURL = "AgentAction.json?aid="+$scope.agent.id;
        var postdata = angular.toJson($scope.agent);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.agent = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.manualRun = function() {
        alert("manualRun not implemented yet");
    }
    $scope.deleteAgent = function() {
        alert("deleteAgent not implemented yet");
    }
});
</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="Agents.htm" >Return to Assistant List</a></li>
        </ul>
      </span>
    </div>

    <div style="height:10px;"></div>



<div id="NewAgent">
    <div class="generalSettings">
        <table>
            <tr id="trspath">
                <td class="gridTableColummHeader">Name:</td>
                <td style="width:20px;"></td>
                <td colspan="2"><input ng-model="agent.title" class="form-control" size="69"/></td>
            </tr>
            <tr><td style="height:10px"></td></tr>
            <tr><td colspan="3" class="generalHeading">Conditions</td></tr>
            <tr><td style="height:10px"></td></tr>
            <tr id="trspath">
                <td class="gridTableColummHeader">Subj Contains:</td>
                <td style="width:20px;"></td>
                <td colspan="2"><input ng-model="agent.subjExpr" class="form-control" size="69"/></td>
            </tr>
            <tr id="trspath">
                <td class="gridTableColummHeader">Desc Contains:</td>
                <td style="width:20px;"></td>
                <td colspan="2"><input ng-model="agent.descExpr" class="form-control" size="69"/></td>
            </tr>
            <tr id="trspath">
                <td class="gridTableColummHeader">Rule 1:</td>
                <td style="width:20px;"></td>
                <td colspan="2"><input ng-model="agent.rule1" class="form-control" size="69"/></td>
            </tr>
            <tr id="trspath">
                <td class="gridTableColummHeader">Rule 2:</td>
                <td style="width:20px;"></td>
                <td colspan="2"><input ng-model="agent.rule2" class="form-control" size="69"/></td>
            </tr>
            <tr><td style="height:10px"></td></tr>
            <tr><td colspan="3" class="generalHeading">Actions</td></tr>
            <tr><td style="height:10px"></td></tr>
            <tr id="trspath">
                <td class="gridTableColummHeader">Action Item:</td>
                <td style="width:20px;"></td>
                <td colspan="2"><input type="checkbox" ng-model="agent.autoAccept"/> Auto-Accept</td>
            </tr>
            <tr id="trspath">
                <td class="gridTableColummHeader">Subproject:</td>
                <td style="width:20px;"></td>
                <td colspan="2"><input type="checkbox" ng-model="agent.autoClone"/> Auto-clone
                    <input type="checkbox" ng-model="agent.synchronize"/> Synchronize</td>
            </tr>
            <tr><td style="height:10px"></td></tr>
            <tr id="trspath">
                <td class="gridTableColummHeader">in Site:</td>
                <td style="width:20px;"></td>
                <td colspan="2">
                    <select name="site" style="width:320px;" class="form-control"/>
                    <option value="">- Select One -</option>
                    <%
                    for (NGBook site : memberOfSites) {
                          String key = site.getKey();

                          %><option value="<%
                          ar.writeHtml(key);
                          if (key.equals(theAgent.getSiteKey())) {
                              %>" selected="selected<%
                          }
                          %>"><%
                          ar.writeHtml(site.getFullName());
                          %></option><%
                    }
                    %>
                    </select>
                </td>
            </tr>
            <tr><td style="height:10px"></td></tr>
            <tr id="trspath">
                <td class="gridTableColummHeader">Template:</td>
                <td style="width:20px;"></td>
                <td colspan="2">
                    <select name="template" style="width:320px;" class="form-control"/>
                    <option value="">- Select One -</option>
                    <%
                    for (NGPageIndex ngpi : templates) {
                          String key = ngpi.containerKey;

                          %><option value="<%
                          ar.writeHtml(key);
                          if (key.equals(theAgent.getTemplate())) {
                              %>" selected="selected<%
                          }
                          %>"><%
                          ar.writeHtml(ngpi.containerName);
                          %></option><%
                    }
                    %>
                    </select>
                </td>
            </tr>
            <tr><td style="height:30px"></td></tr>
            <tr>
                <td class="gridTableColummHeader"></td>
                <td style="width:20px;"></td>
                <td colspan="2">
                    <button class="btn btn-primary btn-raised" ng-click="updateAgent()">Update</button>
                    <button class="btn btn-primary btn-raised" ng-click="cancel()">Cancel</button>
                </td>
            </tr>
        </table>
    </div>
</div>

