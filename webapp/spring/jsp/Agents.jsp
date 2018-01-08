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
    List<AgentRule> agentRules = uPage.getAgentRules();
    JSONArray allAgents = new JSONArray();
    for (AgentRule oneRef : agentRules) {
        allAgents.put(oneRef.getJSON());
    }
    List<NGPageIndex> templates = uProf.getValidTemplates(ar.getCogInstance());

%>
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("All Agents");
    $scope.allAgents = <%allAgents.write(out,2,4);%>;

    $scope.editAgent=false;
    $scope.newAgent = {};

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.createAgent = function() {
        var postURL = "AgentAction.json?aid=~new~";
        var postdata = angular.toJson($scope.newAgent);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.allAgents.push(data);
            $scope.newAgent = {};
            $scope.editAgent=false;
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
              ng-click="editAgent=true" ><img src="<%= ar.retPath%>assets/iconBluePlus.gif" width="13" height="15"/>
                    Create Assistant</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1" ng-click="manualRun()" >
                    <img src="<%= ar.retPath%>assets/iconSync.gif" width="13" height="15"/>
                    Manually Run Now</a></li>
        </ul>
      </span>
    </div>

    <div style="height:10px;"></div>


    <div class="well" ng-show="editAgent">
        <div class="leafContent">
            <table>
                <tr id="trspath">
                    <td class="gridTableColummHeader">Name:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2"><input ng-model="newAgent.title" class="form-control" size="69" /></td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr id="trspath">
                    <td class="gridTableColummHeader">Subject Contains:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2"><input ng-model="newAgent.subjExpr" class="form-control" size="69" /></td>
                </tr>
                <tr id="trspath">
                    <td class="gridTableColummHeader">Description Contains:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2"><input ng-model="newAgent.descExpr" class="form-control" size="69" /></td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr id="trspath">
                    <td class="gridTableColummHeader">Option:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2"><input type="checkbox" name="accept"/> Auto-Accept
                        <input type="checkbox" ng-model="newAgent.transform"/> Schema Transform
                        <input type="checkbox" ng-model="newAgent.normalize"/> Normalize</td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr id="trspath">
                    <td class="gridTableColummHeader">Template:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2">
                        <select ng-model="newAgent.template" class="form-control"  style="width:320px;"/>
                        <option value="">- Select One -</option>
                        <%
                        for (NGPageIndex ngpi : templates) {
                              String key = ngpi.containerKey;

                              %><option value="<%ar.writeHtml(key);%>"><%
                              ar.writeHtml(ngpi.containerName);
                              %></option><%
                        }
                        %>
                        </select>
                </tr>
                <tr><td style="height:30px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader"></td>
                    <td style="width:20px;"></td>
                    <td colspan="2">
                        <button class="btn btn-primary btn-raised" ng-click="createAgent()">Save</button>
                        <button class="btn btn-primary btn-raised" ng-click="editAgent=false">Cancel</button>
                    </td>
                </tr>
            </table>
        </div>
    </div>


        <table class="gridTable2" width="100%">
            <tr class="gridTableHeader">
                <td width="300px">Name</td>
                <td>Last Used</td>
                <td>Delete</td>
            </tr>
                <tr ng-repeat="agent in allAgents">
                <td class="repositoryName">
                    <a href="EditAgent.htm?id={{agent.id}}">{{agent.title}}</a></td>
                <td></td>
                <td>
                <button ng-click="deleteAgent(agent)">
                     <img src="<%=ar.retPath%>assets/iconDelete.gif"/></button>
                </td>
                </tr>
        </table>
    </div>
    
    
    <div class="guideVocal" ng-show="noneFound">
        User <% uProf.writeLink(ar); %> has not created any Personal Assistants.<br/>
            <br/>
            A personal assistant is a kind of automated  agent that can take actions 
            for you automatically.  This is an experimental feature and not
            completely implemented at this time.
    </div>
    
</div>

