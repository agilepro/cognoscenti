<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.ConfigFile"
%><%@page import="org.socialbiz.cog.RoleRequestRecord"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%

    ar.assertLoggedIn("");
    String accountId = ar.reqParam("siteId");
    NGBook  ngb = ar.getCogInstance().getSiteByIdOrFail(accountId);
    String go = "t/"+URLEncoder.encode(accountId, "UTF-8")+"/$/roleManagement.htm";
    List<CustomRole> roles = ngb.getAllRoles();
    JSONObject siteInfo = new JSONObject();
    List<RoleRequestRecord> roleRequestRecordList = ngb.getAllRoleRequest();
    JSONArray allRequests = new JSONArray();
    for (RoleRequestRecord rrr : roleRequestRecordList) {
        JSONObject nrrr = new JSONObject();
        UserProfile uPro = UserManager.findUserByAnyId(rrr.getRequestedBy());
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
        nrrr.put("mn", AccessControl.getAccessRoleRequestParams(ngb, rrr));
        allRequests.put(nrrr);
    }

%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Account Role Request");
    $scope.allRequests = <%allRequests.write(out,2,4);%>;

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
    
});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>


    <div class="generalArea">
        <div id="container" >
            <div id="listofpagesdiv">
                <table class="table">
                    <thead>
                        <tr>
                            <th ></th>
                            <th >Role Name</th>
                            <th >Date</th>
                            <th >Requested by</th>
                            <th >Description</th>
                            <th >State</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr ng-repeat="rec in allRequests">
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
                            <td>{{rec.modified|date}}</td>
                            <td>{{rec.requestName}}</td>
                            <td>{{rec.description}}</td>
                            <td>{{rec.state}}</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>


</div>
