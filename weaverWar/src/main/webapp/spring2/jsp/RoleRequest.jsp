<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.ConfigFile"
%><%@page import="com.purplehillsbooks.weaver.RoleRequestRecord"
%><%/*
Required parameter:

    1. requestId : This is the id of a role request & required only in case of request is generated from mail and
                   used to retrieve RoleRequestRecord.

Optional Parameter:

    1. isAccessThroughEmail : This parameter is used to check if request is generated from mail.

    NOTE: this page is accessible to people who are not logged in.  This can happen if the link has a mnrolerequest token
    value that matches a saved token value.  This allows people who are not logged in, to go ahead and approve the
    request anyway.  The controller determines who has access to this page, so be careful not to required users
    to be logged in, nor to assume that anyone is logged in.
*/


    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId,pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);

    boolean isAccessThroughEmail = "yes".equals(ar.defParam("isAccessThroughEmail","no"));
    boolean canAccessPage = false;
    String requestId = null;
    if (isAccessThroughEmail){
        requestId = ar.reqParam("requestId");
        RoleRequestRecord roleRequestRecord = ngw.getRoleRequestRecordById(requestId);
        canAccessPage = AccessControl.canAccessRoleRequest(ar, ngw, roleRequestRecord);
    }
    String roleRequestId = null;
    String roleRequest_State = "";

    JSONArray allRoleRequests = new JSONArray();
    
    List<RoleRequestRecord> allRRs = ngw.getAllRoleRequest();
    for (RoleRequestRecord rrr : allRRs) {
        JSONObject nrrr = new JSONObject();
        String reqBy = rrr.getRequestedBy();
        UserProfile uPro = UserManager.getStaticUserManager().lookupUserByAnyId(reqBy);
        if (uPro==null) {
            //this should never happen in normal circumstances, that a role request comes from 
            //a user that does not have a profile.  But it can happen if
            //a workspace is moved from server to server, such that the request exists
            //but the user had never been there.   
            //Ignore requests that have no user.
            System.out.println("ROLE REQUEST: came from a user that does not have a profile! ("+reqBy+")");
            continue;
        }
        nrrr.put("id", rrr.getRequestId());
        nrrr.put("state", rrr.getState());
        nrrr.put("requestKey", uPro.getKey());
        nrrr.put("requestName", uPro.getName());
        nrrr.put("roleName", rrr.getRoleName());
        nrrr.put("modified", rrr.getModifiedDate());
        nrrr.put("modBy", rrr.getModifiedBy());
        nrrr.put("completed", rrr.isCompleted());
        nrrr.put("description", rrr.getRequestDescription());
        nrrr.put("response", rrr.getResponseDescription());
        nrrr.put("mn", AccessControl.getAccessRoleRequestParams(ngw, rrr));
        allRoleRequests.put(nrrr);
    }


%>
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Role Requests");
    $scope.allRoleRequests = <%allRoleRequests.write(out,2,4);%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.update = function(op, rec) {
        var msg = {};
        msg.op = op;
        msg.rrId = rec.id;
        var postURL = "roleRequestResolution.json?"+rec.mn;
        var postdata = angular.toJson(msg);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            rec.state=data.state;
            rec.completed=data.completed;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.removeRec = function(recid) {
        var res = [];
        $scope.allRoleRequests.map( function(item) {
            if (recid != item.id) {
                res.push(item);
            }
        });
        $scope.allRoleRequests = res;
    };

    $scope.sortData = function() {
        $scope.allRoleRequests.sort( function(a,b) {
            return b.modified-a.modified;
        });
    }
    $scope.sortData();
});
</script>
<!-- MAIN CONTENT SECTION START -->
<div class="container-fluid override mb-4 mx-3 d-inline-flex">
    <span class="dropdown mt-1">
        <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
            data-bs-toggle="dropdown" aria-expanded="false">
        </button>
        <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
            <li>
                <button class="dropdown-item" onclick="window.location.reload(true)">Refresh</button>
                <span class="dropdown-item" type="button" ng-click="openTopicCreator()"
                    aria-labelledby="createNewTopic"><a role="menuitem" class="nav-link" href="AdminSettings.htm"> Admin Settings</a>
                </span>
                <span class="dropdown-item" type="button" ng-click="openTopicCreator()"
                    aria-labelledby="createNewTopic"><a class="nav-link" role="menuitem" href="LabelList.htm"> Labels &amp; Folders</a>
                </span>
                <span class="dropdown-item" type="button" ng-click="openTopicCreator()"
                    aria-labelledby="createNewTopic"><a class="nav-link" role="menuitem" href="EmailCreated.htm"> Email Prepared</a>
                </span>
                <span class="dropdown-item" type="button" ng-click="openTopicCreator()"
                    aria-labelledby="createNewTopic"><a class="nav-link" role="menuitem" href="EmailSent.htm"> Email Sent</a>
                </span>
                <span class="dropdown-item" type="button" ng-click="openTopicCreator()"
                    aria-labelledby="createNewTopic"><a class="nav-link" role="menuitem" href="AdminStats.htm"> Workspace Statistics</a>
                </span>
                <span class="dropdown-item" type="button" ng-click="openTopicCreator()"
                    aria-labelledby="createNewTopic"><a class="nav-link" role="menuitem"
                        href="../$/SiteCreateWorkspace.htm?parent={{workspaceConfig.key}}"> Create Child Workspace</a>
                </span>
                <span class="dropdown-item" type="button" ng-click="openTopicCreator()"
                    aria-labelledby="createNewTopic"><a class="nav-link" role="menuitem"
                        href="../$/SiteCreateWorkspace.htm?parent={{workspaceConfig.parentKey}}"> Create Sibling Workspace</a>
                </span>
            </li>
        </ul>
    </span>
    <span>
        <h1 class="d-inline page-name" id="mainPageTitle"></h1>
    </span>
</div>

<%@include file="ErrorPanel.jsp"%>

    <div class="container-fluid override mx-3">
        <div class="d-flex col-12">
            <span class="col-1 h6" ></span>
            <span class="col-2 h6" >Role Name</span>
            <span class="col-2 h6" >Date</span>
            <span class="col-2 h6" >Requested by</span>
            <span class="col-4 h6" >Description</span>
            <span class="col-1 h6" >State</span>
        </div>
        <div class="d-flex col-12 my-3" ng-repeat="rec in allRoleRequests">
            <span class="col-1">
              <span class="dropdown nav-item mb-0">
                <button class="specCaretBtn dropdown" type="button" id="menu1" data-toggle="dropdown">
                    <i class="fa fa-caret-down"></i>
                </button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li class="dropdown-item" role="presentation">
                    <a role="menuitem" href="#" ng-click="update('Approve', rec)">Approve Request</a>
                  </li>
                  <li class="dropdown-item" role="presentation">
                      <a role="menuitem" href="#" ng-click="update('Reject', rec)">Reject Request</a>
                  </li>
                </ul>
              </span>
            </span>
            <span class="col-2">{{rec.roleName}}</span>
            <span class="col-2">{{rec.modified|cdate}}</span>
            <span class="col-2"><a href="<%=ar.retPath%>v/{{rec.requestKey}}/UserSettings.htm">{{rec.requestName}}</a></span>
            <span class="col-4 text-wrap">{{rec.description}}</span>
            <span class="col-1">{{rec.state}} <img src="<%=ar.retPath%>new_assets/assets/iconWarning.png" ng-hide="rec.completed"></span>
        </div>
    </div>


</div>
