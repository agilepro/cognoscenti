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

    
    /*
    Data to the server is the workspace command structure
    {
        newName:"",
        template:""
    }
    Data from the server is the workspace config structure
    {
      "accessState": "Live",
      "allNames": ["Darwin2"],
      "deleted": false,
      "frozen": false,
      "goal": "",
      "key": "darwin2",
      "parentKey": "",
      "parentName": "",
      "projectMail": "",
      "purpose": "",
      "showExperimental": false,
      "site": "goofoof",
      "upstream": ""
    }
    */
%>

<script>

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Create New Workspace");
    $scope.siteInfo = <% site.getConfigJSON().write(ar.w,2,4); %>;
    $scope.accountKey = "<%ar.writeJS(accountKey);%>";
    $scope.upstream = "<%ar.writeJS(upstream);%>";
    $scope.pname = "<%ar.writeJS(pname);%>";
    $scope.desc = "<%ar.writeJS(desc);%>";
    $scope.templateList = <% templateList.write(ar.w,2,4); %>;
    $scope.selectedTemplate = "";
    $scope.newWorkspace = {newName:"",template:""};

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        console.log("Error: "+serverErr);
        errorPanelHandler($scope, serverErr);
    };
    
    $scope.createNewWorkspace = function() {
        if (!$scope.newWorkspace.newName) {
            alert("Please enter a name for this new workspace.");
            return;
        }
        var postURL = "createWorkspace.json";
        var postdata = angular.toJson($scope.newWorkspace);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            alert("You new workspace has been created!   Now set the description so that people"
                  + " know what it is for, and so that people can find it by searching on key words.");
            var newws = "../"+data.key+"/admin.htm";
            console.log("CREATED WORKSPACE: ", data);
            window.location = newws;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    
});
</script>
    
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>


<style>
.spacey td {
    padding:5px;
}
</style>
<div style="max-width:500px">

    <div class="form-group">
        <label >New Workspace Name</label>
        <input type="text" class="form-control" ng-model="newWorkspace.newName"/>
    </div>
    
    <div class="form-group">
        <button class="btn btn-primary btn-raised" ng-click="createNewWorkspace()">
            Create Workspace</button>
    </div>
    <div class="form-group" ng-show="templateList && templateList.length>0">
        <label >Select Template (optional)</label>
        <select class="form-control" ng-model="newWorkspace.template"
                ng-options="tmp.name for tmp in templateList">
                <option value="">-- no template --</option>
        </select>
    </div>
    <div class="form-group" ng-show="siteInfo.showExperimental">
        <label >Upstream Link</label>
        <input class="form-control" style="width:368px" ng-model="newWorkspace.upstream"/>
    </div>
       
</div>

</div>