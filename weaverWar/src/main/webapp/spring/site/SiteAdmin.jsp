<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.NGRole"
%><%@page import="com.purplehillsbooks.weaver.License"
%><%@page import="com.purplehillsbooks.weaver.WorkspaceStats"
%><%@page import="com.purplehillsbooks.weaver.util.NameCounter"
%><%@ include file="/spring/jsp/include.jsp"
%><% 

    ar.assertLoggedIn("");
    String siteId = ar.reqParam("siteId");
    NGBook  ngb = ar.getCogInstance().getSiteByIdOrFail(siteId);
    JSONObject siteInfo = ngb.getConfigJSON();

    WorkspaceStats wStats = ngb.getRecentStats();

 
%> 

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Site Administration");
    $scope.siteInfo = <%siteInfo.write(out,2,4);%>;
    $scope.newName = $scope.siteInfo.names[0];
    $scope.colorList = $scope.siteInfo.labelColors.join(",");

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    
    $scope.removeName = function(oldName) {
        $scope.siteInfo.names = $scope.siteInfo.names.filter( function(item) {
            return (item!=oldName);
        });
    }
    $scope.addName = function(newName) {
        $scope.removeName(newName);
        $scope.siteInfo.names.splice(0, 0, newName);
    }
    
    $scope.saveSiteInfo = function() {
        if ($scope.siteInfo.names.length===0) {
            alert("Site must have at least one name at all times.  Please add a name.");
            return;
        }
        var rawList = $scope.colorList.split(",");
        if (rawList.length>2) {
            var newList = [];
            rawList.forEach( function(item) {
                newList.push(item.trim());
            });
            $scope.siteInfo.labelColors = newList;
        }
        var postURL = "updateSiteInfo.json";
        var postdata = angular.toJson($scope.siteInfo);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.siteInfo = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    


});

</script>


<style>
.spaceyTable tr td {
    padding:8px;
}
</style>


<div>

<%@include file="../jsp/ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" 
              href="SiteAdmin.htm">Site Admin</a></li>
          <li role="presentation"><a role="menuitem" 
              href="SiteUsers.htm">User List</a></li>
          <li role="presentation"><a role="menuitem" 
              href="SiteStats.htm">Site Statistics</a></li>
          <li role="presentation"><a role="menuitem" 
              href="TemplateEdit.htm">Template Edit</a></li>
        </ul>
      </span>
    </div>


    <div class="generalContent">
         <table class="spaceyTable">
            <tr>
                <td class="gridTableColummHeader_2">New Name:</td>
                <td class="form-inline">
                    <input type="text" class="form-control" ng-model="newName">
                    <button ng-click="addName(newName)" class="btn btn-primary btn-raised">Change Name</button>
                </td>
            </tr>
            <tr>
                <td class="gridTableColummHeader_2" valign="top">Current Names:</td>
                 
                <td>
                    <div ng-repeat="name in siteInfo.names">
                        {{name}}
                        <img src="<%=ar.retPath%>/assets/iconDelete.gif" ng-click="removeName(name)">
                    </div>
                </td>
            </tr>
            <tr>
                <td>Site Description:</td>
                <td>
                    <textarea  class="form-control markDownEditor" rows="4" ng-model="siteInfo.description"
                    title="The description appears in places where the user needs to know a little more about the purpose and background of the site itself."></textarea>
                </td>
            </tr>
            <tr>
                <td >Site Message:</td>
                <td>
                    <textarea  class="form-control" rows="2" ng-model="siteInfo.siteMsg"
                    title="This message appears on every page of every workspace.  Use for urgent updates and changes in site status."></textarea>
                </td>
            </tr>
            <tr>
                <td >Label Colors:</td>
                <td>
                    <textarea  class="form-control" rows="2" ng-model="colorList"
                    title="A comma separated list of standard color names."></textarea>
                </td>
            </tr>
        <% if (ar.isSuperAdmin()) { %>
            <tr>
                <td class="gridTableColummHeader_2">Flags:</td>
                <td>
                    <input type="checkbox" ng-model="siteInfo.showExperimental"> Show Experimental &nbsp; &nbsp; 
                    <input type="checkbox" ng-model="siteInfo.frozen"> Frozen &nbsp; &nbsp; 
                    <input type="checkbox" ng-model="siteInfo.isDeleted"> isDeleted &nbsp; &nbsp; 
                    <input type="checkbox" ng-model="siteInfo.offLine"> offLine
            </tr>
        <% } %>
            <tr>
                <td class="gridTableColummHeader_2"></td>
                 
                <td><button class="btn btn-primary btn-raised" ng-click="saveSiteInfo()">Save Changes</button></td>
            </tr>
            <tr>
                <td class="gridTableColummHeader_2">Site Key:</td>
                <td>{{siteInfo.key}}</td>
            </tr>
        </table>
    </div>
</div>
