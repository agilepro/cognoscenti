<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/spring2/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId : This is the id of a Workspace and here it is used to retrieve NGWorkspace.

*/

    Cognoscenti cog = ar.getCogInstance();
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGPageIndex ngpi = cog.getWSBySiteAndKeyOrFail(siteId, pageId);
    NGWorkspace ngp = ngpi.getWorkspace();
    ar.setPageAccessLevels(ngp);
    NGBook site = ngp.getSite();

    
    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }



    JSONObject thisCircle = new JSONObject();
    thisCircle.put("name", ngp.getFullName());
    thisCircle.put("key",  ngp.getKey());
    thisCircle.put("site", ngp.getSiteKey());

    JSONObject parent = new JSONObject();
    NGPageIndex parentIndex = cog.getParentWorkspace(ngpi);
    if (parentIndex==null) {
        parent.put("name", "");
        parent.put("site", "");
        parent.put("key",  "");
    }
    else {
        parent.put("name", parentIndex.containerName);
        parent.put("key",  parentIndex.containerKey);
        parent.put("site", parentIndex.wsSiteKey);
    }

    JSONArray children = new JSONArray();
    for (NGPageIndex child : cog.getChildWorkspaces(ngpi)) {
        if (!child.isWorkspace()) {
            continue;
        }
        JSONObject jo = new JSONObject();
        jo.put("name", child.containerName);
        jo.put("key",  child.containerKey);
        jo.put("site", child.wsSiteKey);
        children.put(jo);
    }


%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Weaver Workspace");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.workspaceConfig = <%ngp.getConfigJSON().write(out,2,4);%>;
    $scope.parent     = <%parent.write(out,2,4);%>;
    $scope.thisCircle = <%thisCircle.write(out,2,4);%>;
    $scope.purpose = "<%ar.writeJS(ngp.getProcess().getDescription());%>";
    $scope.filter = "";

    $scope.showInput = false;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

  
    $scope.login = function() {
        SLAP.loginUserRedirect();
    }


});
</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

  <div style="margin:25px">
    <h2>{{siteInfo.names[0]}} - {{workspaceConfig.allNames[0]}}</h2>
    
    <p>This is a Weaver workspace where people come to agrement.</p>
    
    <div>
        Please
        <button class="btn btn-primary btn-raised" onClick="SLAP.loginUserRedirect()">
            Login
        </button>
        to find out more.
    </div>
  </div>

<!-- COLUMN 3 -->
  <div class="col-lg-4 col-md-6 col-sm-12" ng-show="workspaceConfig.wsSettings.showVisionOnFrontPage">

    <div class="panel panel-default" >
      <div class="panel-heading headingfont">
          <div style="float:left">Vision of Workspace</div>
          <div style="float:right" title="Edit vision in this workspace">
              <a href="AdminSettings.htm">
                  <i class="fa fa-info-circle"></i></a></div>
          <div style="clear:both"></div>
      </div>
      <div class="panel-body" >
          <a href="AdminSettings.htm">
          <div ng-bind-html="workspaceConfig.vision|wiki"></div>
          </a>
      </div>
    </div>
  </div>
  <div class="col-lg-4 col-md-6 col-sm-12" ng-show="workspaceConfig.wsSettings.showMissionOnFrontPage">
    <div class="panel panel-default">
      <div class="panel-heading headingfont">
          <div style="float:left">Mission of Workspace</div>
          <div style="float:right" title="Edit mission in this workspace">
              <a href="AdminSettings.htm">
                  <i class="fa fa-info-circle"></i></a></div>
          <div style="clear:both"></div>
      </div>
      <div class="panel-body" >
          <a href="AdminSettings.htm">
          <div ng-bind-html="workspaceConfig.mission|wiki"></div>
          </a>
      </div>
    </div>
  </div>
  <div class="col-lg-4 col-md-6 col-sm-12" ng-show="workspaceConfig.wsSettings.showAimOnFrontPage">
    <div class="panel panel-default">
      <div class="panel-heading headingfont">
          <div style="float:left">Aim of Workspace</div>
          <div style="float:right" title="Edit aim in this workspace">
              <a href="AdminSettings.htm">
                  <i class="fa fa-info-circle"></i></a></div>
          <div style="clear:both"></div>
      </div>
      <div class="panel-body" >
          <a href="AdminSettings.htm">
          <div ng-bind-html="workspaceConfig.purpose|wiki"></div>
          </a>
      </div>
    </div>
  </div>
  <div class="col-lg-4 col-md-6 col-sm-12" ng-show="workspaceConfig.wsSettings.showDomainOnFrontPage">
    <div class="panel panel-default">
      <div class="panel-heading headingfont">
          <div style="float:left">Domain of Workspace</div>
          <div style="float:right" title="Edit domain in this workspace">
              <a href="AdminSettings.htm">
                  <i class="fa fa-info-circle"></i></a></div>
          <div style="clear:both"></div>
      </div>
      <div class="panel-body" >
          <a href="AdminSettings.htm">
          <div ng-bind-html="workspaceConfig.domain|wiki"></div>
          </a>
      </div>
    </div>
  </div>
    
    




</div>

<script src="<%=ar.retPath%>new_assets/templates/InviteModal.js"></script>
