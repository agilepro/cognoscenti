<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.AccessControl"
%><%@page import="com.purplehillsbooks.weaver.LeafletResponseRecord"
%><%

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    NGBook ngb = ngw.getSite();
    UserProfile user = ar.getUserProfile();

%>

<style>
.bigger {
    font-size: 20px;
    margin:20px;
}
</style>

<script type="text/javascript">


var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, $interval, AllPeople) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Limited Access");
    $scope.siteInfo = <%ngb.getConfigJSON().write(out,2,4);%>;
    $scope.workspaceInfo = <%ngw.getConfigJSON().write(out,2,4);%>;


});

</script>
<script src="../../../jscript/AllPeople.js"></script>

<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>


<div style="max-width:600px" class="well">

    <div class="bigger">
    You are logged in as <%=user.getName()%> ( <%=user.getUniversalId()%> ).
    </div>
    
    <div class="bigger">
    You actually <i>are</i> a member of this workspace.   
    Use the links on the left to navigate to other parts of the workspace.
    </div>
    
   
</div>


<%out.flush();%>
