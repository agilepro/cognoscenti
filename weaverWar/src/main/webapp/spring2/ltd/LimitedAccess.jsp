<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.LeafletResponseRecord"
%><%@page import="com.purplehillsbooks.weaver.RoleRequestRecord"
%><%

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    NGBook ngb = ngw.getSite();
    UserProfile user = ar.getUserProfile();

    boolean isRequested = false;
    String requestState = "";
    String requestMsg = "";
    long latestDate = 0;
    String oldRequestEmail = "";
    for (RoleRequestRecord rrr : ngw.getAllRoleRequest()) {
        if (user.hasAnyId(rrr.getRequestedBy())) {
            if (rrr.getModifiedDate()>latestDate) {
                isRequested = true;
                requestMsg = rrr.getRequestDescription();
                requestState = rrr.getState();
                latestDate = rrr.getModifiedDate();
                oldRequestEmail = rrr.getRequestedBy();
            }
        }
    }

%>
<!-- *************************** ltd / LimitedAccess.jsp.jsp *************************** -->

<script type="text/javascript">


var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, $interval, AllPeople) {
    window.setMainPageTitle("Limited Access");
    $scope.siteInfo = <%ngb.getConfigJSON().write(out,2,4);%>;
    $scope.workspaceInfo = <%ngw.getConfigJSON().write(out,2,4);%>;
    $scope.enterRequest = "<% ar.writeJS(requestMsg); %>";
    $scope.requestState = "<% ar.writeJS(requestState); %>";
    $scope.oldRequestEmail = "<% ar.writeJS(oldRequestEmail); %>";
    $scope.isRequested = <%=isRequested%>;
    $scope.requestDate = <%=latestDate%>;


    $scope.takeStep = function() {
        $scope.enterMode = true;
        $scope.alternateEmailMode = false;
    }
    $scope.roleChange = function() {
        var data = {};
        data.op = 'Join';
        data.roleId = "Members";
        data.desc = $scope.enterRequest;
        console.log("Requesting to ",data);
        var postURL = "rolePlayerUpdate.json";
        var postdata = angular.toJson(data);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            alert("OK, you have requested membership");
            $scope.enterMode = false;
        })
        .error( function(data, status, headers, config) {
            console.log("GOT ERROR ",data);
            $scope.reportError(data);
        });
    };
});

</script>
<script src="../../../jscript/AllPeople.js"></script>

<div>

<%@include file="ErrorPanel.jsp"%>


<div class="container-fluid">
    <div class="row col-7 ms-4 d-flex">
        <span class="h5">
    You are logged in as <%=user.getName()%> ( <%=user.getUniversalId()%> ).
            <br/><br/>
    You have only limited access to the workspace <b><%=ngw.getFullName()%></b>.
    You have access to items listed below, if any.
    </span>


<%
    for (TopicRecord topicRec : ngw.getAllDiscussionTopics()) {
        NGRole subscribers = topicRec.getSubscriberRole();
        if (!subscribers.isExpandedPlayer(user, ngw)) {
            continue;
        }
%>

        <span class="h5 my-3" >
            <span ><i class="fa fa-arrow-circle-right"></i> <a href="noteZoom<%=topicRec.getId()%>.htm">
        <%ar.writeHtml( topicRec.getSubject() );%>
        </a></span>
        </span>


<%
    }
%>

<%
    for (String accessId : ar.ngsession.honararyAccessList()) {
        int colonPos = accessId.indexOf(":");
        int secondColon = accessId.indexOf(":", colonPos+2);
        if (secondColon < 0) {
            System.out.println(String.format("Unknown resource(%s) on LimitedAccess page with only one colon", accessId));
            continue;
        }
        String resourceType = accessId.substring(0, colonPos);
        String actualId = accessId.substring(colonPos+1, secondColon);

        if ("doc".equals(resourceType)) {
%>
    <span ><i class="fa  fa-bullseye"></i> <a href="DocDetail.htm?aid=<%=actualId%>">
        Document <%ar.writeHtml( accessId );%>
        </a></span>

</div>
<%
        }
    }
%>




        <div ng-hide="enterMode || alternateEmailMode" class="well col-6">
            <div ng-show="isRequested">
                 You requested membership on {{requestDate|cdate}} as {{oldRequestEmail}}.<br/>
                 The status of that request is: <b>{{requestState}}</b>.
            </div>
            <div class="h6 my-3 " ng-hide="isRequested">
                If you think you should be a member then please:
            </div>
            <button class="btn btn-primary btn-comment btn-wide btn-sm btn-raised pull-right" ng-click="takeStep()">Request Membership</button>
        </div>
        <div ng-show="enterMode && !alternateEmailMode" class="warningBox well">
            <div>Enter a reason to join the workspace:</div>
            <textarea ng-model="enterRequest" class="form-control"></textarea>
            <button class="btn btn-primary btn-raised" ng-click="roleChange()">Request Membership</button>
            <button class="btn btn-warning btn-raised" ng-click="enterMode=false">Cancel</button>
        </div>
</div>

<%out.flush();%>
