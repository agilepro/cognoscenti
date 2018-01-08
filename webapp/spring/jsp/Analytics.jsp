<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.CustomRole"
%><%


    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    NGBook ngb = ngw.getSite();
    
    JSONObject siteInfo = ngb.getConfigJSON();
    
    String processUrl = ar.getSystemProperty("processUrl");
    

%>


<script>

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Analytics Links");
    $scope.siteInfo = <%siteInfo.write(out,2,4);%>;
    $scope.caseId = "<% ar.writeJS(siteId+"|"+pageId); %>";
    $scope.processUrl = "<% ar.writeJS(processUrl); %>";

   
});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

<style>
.bigbutton {
    margin:20px;
    padding:20px;
    border:solid gray 1px;
    border-radius: 5px;
    cursor: pointer;
}
</style>



    <a href="http://interstagedemo:5601/">
    <div class="bigbutton h2">Kibana</div>
    </a>

    <a href="http://interstagedemo:9100/">
    <div class="bigbutton h2">Elastic Search</div>
    </a>

       
</div>

<script src="<%=ar.retPath%>templates/CreateTopicModal.js"></script>
