<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.AccessControl"
%><%@page import="com.purplehillsbooks.weaver.LeafletResponseRecord"
%><%@page import="com.purplehillsbooks.weaver.LicenseForUser"
%><%@page import="com.purplehillsbooks.weaver.MicroProfileMgr"
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
    min-width:  50px;
    vertical-align: text-top;
}
</style>

<script type="text/javascript">


var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, $interval, AllPeople) {
    window.setMainPageTitle("Limited Access");
    $scope.siteInfo = <%ngb.getConfigJSON().write(out,2,4);%>;
    $scope.workspaceInfo = <%ngw.getConfigJSON().write(out,2,4);%>;


});

</script>
<script src="../../../jscript/AllPeople.js"></script>

<div>

<%@include file="ErrorPanel.jsp"%>


<div style="max-width:600px">

    <div class="bigger">
    You are logged in as <%=user.getName()%> ( <%=user.getUniversalId()%> ).
    </div>
    
    <div class="bigger">
    You have only limited access to this workspace.
    Below is a list of all the items that you have access to in this workspace.
    </div>
    
    <table class="bigger">
<%
    for (TopicRecord topicRec : ngw.getAllDiscussionTopics()) {
        NGRole subscribers = topicRec.getSubscriberRole();
        if (!subscribers.isExpandedPlayer(user, ngw)) {
            continue;
        }
%>
    <tr>
      <td class="bigger"><i class="fa  fa-arrow-circle-right"></i> </td>
        
      <td class="bigger"><a href="noteZoom<%=topicRec.getId()%>.htm">
        <%ar.writeHtml( topicRec.getSubject() );%>
        </a></td>
    </tr>
<%
    }
%>

<%
    for (String accessId : ar.ngsession.honararyAccessList()) {
        int colonPos = accessId.indexOf(":");
        int secondColon = accessId.indexOf(":", colonPos+2);
        String resourceType = accessId.substring(0, colonPos);
        String actualId = accessId.substring(colonPos+1, secondColon);
        
        if ("doc".equals(resourceType)) {
%>
    <tr>
      <td class="bigger"><i class="fa  fa-bullseye"></i> </td>
      <td class="bigger"><a href="DocDetail.htm?aid=<%=actualId%>">
        Document <%ar.writeHtml( accessId );%>
        </a></td>
    </tr>
<%
        }
    }
%>
    </table>
</div>


<%out.flush();%>
