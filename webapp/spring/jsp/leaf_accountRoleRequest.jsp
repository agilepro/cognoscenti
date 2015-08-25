<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.ConfigFile"
%><%@page import="org.socialbiz.cog.RoleRequestRecord"
%><%

    ar.assertLoggedIn("");
    String accountId = ar.reqParam("accountId");
    NGBook  ngb = ar.getCogInstance().getSiteByIdOrFail(accountId);
    String go = "t/"+URLEncoder.encode(accountId, "UTF-8")+"/$/permission.htm";
    List<CustomRole> roles = ngb.getAllRoles();
    JSONObject siteInfo = new JSONObject();
    List<RoleRequestRecord> roleRequestRecordList = ngb.getAllRoleRequest();
    JSONArray allRequests = new JSONArray();
    for (RoleRequestRecord rrr : roleRequestRecordList) {
        JSONObject jo = new JSONObject();
        jo.put("requestId", rrr.getRequestId());
        jo.put("roleName", rrr.getRoleName());
        jo.put("modifiedDate", rrr.getModifiedDate());
        jo.put("description", rrr.getRequestDescription());
        jo.put("state", rrr.getState());
        jo.put("response", rrr.getResponseDescription());
        jo.put("requestedBy", rrr.getRequestedBy());
        allRequests.put(jo);
    }

%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.allRequests = <%allRequests.write(out,2,4);%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

});

</script>

<div ng-app="myApp" ng-controller="myCtrl">


    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Role Requests
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="">do Nothing</a></li>
            </ul>
          </span>

        </div>
    </div>



    <div class="generalArea">
        <div id="container" >
            <div id="listofpagesdiv">
                <table class="table">
                    <thead>
                        <tr>
                            <th >Request Id</th>
                            <th >Role Name</th>
                            <th >Date</th>
                            <th >Requested by</th>
                            <th >Description</th>
                            <th >State</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr ng-repeat="rec in allRequests">
                            <td>{{rec.requestId}}</td>
                            <td>{{rec.roleName}}</td>
                            <td>{{rec.modifiedDate|date}}</td>
                            <td>{{rec.requestedBy}}</td>
                            <td>{{rec.description}}</td>
                            <td>{{rec.state}}</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>


</div>
