<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="include.jsp"
%><%@page import="org.socialbiz.cog.ConfigFile"
%><%@page import="org.socialbiz.cog.RoleRequestRecord"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%/*
Required parameter:

    1. requestId : This is the id of a role request & required only in case of request is generated from mail and
                   used to retrieve RoleRequestRecord.

Optional Parameter:

    1. isAccessThroughEmail : This parameter is used to check if request is generated from mail.

    NOTE: this page is accessible to people who are not logged in.  Thsi can happen if the link has a mnrolerequest token
    value that matches a saved token value.  This allows people who are not logged in, to go ahead and approve the
    request anyway.  The controller determines who has access to this page, so be careful not to required users
    to be logged in, nor to assume that anyone is logged in.
*/


    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    NGContainer ngc = null;
    if ("$".equals(pageId)) {
        ngc = ar.getCogInstance().getSiteByIdOrFail(siteId);
    }
    else {
        ngc = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId,pageId).getWorkspace();
        ar.setPageAccessLevels(ngc);
    }

    boolean isAccessThroughEmail = "yes".equals(ar.defParam("isAccessThroughEmail","no"));
    boolean canAccessPage = false;
    String requestId = null;
    if (isAccessThroughEmail){
        requestId = ar.reqParam("requestId");
        RoleRequestRecord roleRequestRecord = ngc.getRoleRequestRecordById(requestId);
        canAccessPage = AccessControl.canAccessRoleRequest(ar, ngc, roleRequestRecord);
    }
    String roleRequestId = null;
    String roleRequest_State = "";

    JSONArray allRoleRequests = new JSONArray();
    
    List<RoleRequestRecord> allRRs = ngc.getAllRoleRequest();
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
        nrrr.put("mn", AccessControl.getAccessRoleRequestParams(ngc, rrr));
        allRoleRequests.put(nrrr);
    }


%>
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
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
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <table class="gridTable2" width="100%">
        <tr class="gridTableHeader">
            <td ></td>
            <td >Role Name</td>
            <td >Date</td>
            <td >Requested by</td>
            <td >Description</td>
            <td >State</td>
        </tr>
        <tr ng-repeat="rec in allRoleRequests">
            <td>
              <div class="dropdown">
                <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                <span class="caret"></span></button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li role="presentation">
                      <a role="menuitem" href="#" ng-click="update('Approve', rec)">Approve Request</a></li>
                  <li role="presentation">
                      <a role="menuitem" href="#" ng-click="update('Reject', rec)">Reject Request</a></li>
                </ul>
              </div>
            </td>
            <td>{{rec.roleName}}</td>
            <td>{{rec.modified|cdate}}</td>
            <td><a href="<%=ar.retPath%>v/{{rec.requestKey}}/userSettings.htm">{{rec.requestName}}</a></td>
            <td>{{rec.description}}</td>
            <td>{{rec.state}} <img src="<%=ar.retPath%>assets/iconWarning.png" ng-hide="rec.completed"></td>
        </tr>
    </table>


</div>
