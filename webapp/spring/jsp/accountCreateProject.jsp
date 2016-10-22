<%@ include file="/spring/jsp/include.jsp"
%><%@ include file="/spring/jsp/functions.jsp"
%><%!
    String pageTitle="";
%><%
/*
Required parameter:

    1. accountId : This is the id of a site and used to retrieve NGBook.

*/

    //this page should only be called when logged in and having access to the site
    ar.assertLoggedIn("Must be logged in to create a workspace");

    String accountKey = ar.reqParam("accountId");
    NGBook site = ar.getCogInstance().getSiteByIdOrFail(accountKey);

    UserProfile  uProf =ar.getUserProfile();
    List<NGPageIndex> templates = uProf.getValidTemplates(ar.getCogInstance());
    JSONArray templateList = new JSONArray();
    
    JSONObject defaultOption = new JSONObject();
    defaultOption.put("key", "");
    defaultOption.put("name", "- None -");
    //templateList.put(defaultOption);
    
    for (NGPageIndex ngpi : templates) {
        JSONObject jo = new JSONObject();
        jo.put("key", ngpi.containerKey);
        jo.put("name", ngpi.containerName);
        templateList.put(jo);
    }

    String upstream = ar.defParam("upstream", "");
    String desc = ar.defParam("desc", "");
    String pname = ar.defParam("pname", "");

%>

<script>

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.siteInfo = <% site.getConfigJSON().write(ar.w,2,4); %>;
    $scope.accountKey = "<%ar.writeJS(accountKey);%>";
    $scope.upstream = "<%ar.writeJS(upstream);%>";
    $scope.pname = "<%ar.writeJS(pname);%>";
    $scope.desc = "<%ar.writeJS(desc);%>";
    $scope.templateList = <% templateList.write(ar.w,2,4); %>;
    $scope.selectedTemplate = "";

});
</script>
    
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalSubHeading" style="height:40px">
            Create Workspace in Site '{{siteInfo.names[0]}}'
    </div>

<style>
.spacey td {
    padding:5px;
}
</style>
<div class="generalContent">
   <form name="projectform" action="createprojectFromTemplate.form" method="post" autocomplete="off">
        <table class="spacey">
           <tr>
                <td class="gridTableColummHeader_2">New Workspace Name:</td>
                <td>
                    <input type="text" class="form-control" name="projectname"
                                   ng-model="pname"/>
                </td>
            </tr>
            <tr>
                <td></td>
                <td>
                    <button type="submit" class="btn btn-primary btn-raised">Create Workspace</button>
                </td>
            </tr>
            <tr>
                <td class="gridTableColummHeader_2">Select Template:</td>
                <td><select class="form-control" ng-model="selectedTemplate"
                    ng-options="tmp.name for tmp in templateList">
                    <option value="">-- choose template --</option>
                </select>
                </td>
            </tr>
            <tr ng-show="siteInfo.showExperimental">
                <td class="gridTableColummHeader">Upstream Link:</td>
                <td><input type="text" class="form-control" style="width:368px" size="50" name="upstream"
                    ng-model="upstream"/>
                </td>
            </tr>
       </table>
   </form>
   

