<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId : This is the id of a Workspace and here it is used to retrieve NGWorkspace.

*/

    ar.assertLoggedIn("Must be logged in to see a workspace");

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGPageIndex ngpi = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId);
    NGWorkspace ngp = ngpi.getWorkspace();
    ar.setPageAccessLevels(ngp);
    NGBook site = ngp.getSite();
    Cognoscenti cog = ar.getCogInstance();

    
    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }


    JSONArray topHistory = new JSONArray();
    JSONArray recentChanges = new JSONArray();

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

    UserProfile uProf = ar.getUserProfile();

    JSONArray yourRoles = new JSONArray();
    JSONArray otherMembers = new JSONArray();
    JSONArray myMeetings = new JSONArray();
    JSONArray myActions = new JSONArray();
    

    
    boolean isWatching = uProf.isWatch(siteId+"|"+pageId);

%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Workspace Front Page");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.workspaceConfig = <%ngp.getConfigJSON().write(out,2,4);%>;
    $scope.topHistory = <%topHistory.write(out,2,4);%>;
    $scope.recentChanges = <%recentChanges.write(out,2,4);%>;
    $scope.parent     = <%parent.write(out,2,4);%>;
    $scope.thisCircle = <%thisCircle.write(out,2,4);%>;
    $scope.children   = <%children.write(out,2,4);%>;
    $scope.yourRoles  = <%yourRoles.write(out,2,4);%>;
    $scope.otherMembers = <%otherMembers.write(out,2,4);%>;
    $scope.myMeetings = <%myMeetings.write(out,2,4);%>;
    $scope.myActions  = <%myActions.write(out,2,4);%>;
    $scope.purpose = "<%ar.writeJS(ngp.getProcess().getDescription());%>";
    $scope.isWatching = <%=isWatching%>;

    $scope.filter = "";
    
    function processHtml(value) {
        if (!value) {
            return "<i>no description</i>";
        }
        else if (value.length<200) {
            return convertMarkdownToHtml(value);
        }
        else {
            return convertMarkdownToHtml(value.substring(0,198)+" ...");
        }
    }
    function generateTheHtmlValues() {
        $scope.purposeHtml = processHtml($scope.workspaceConfig.purpose);
        $scope.visionHtml  = processHtml($scope.workspaceConfig.vision);
        $scope.missionHtml = processHtml($scope.workspaceConfig.mission);
        $scope.domainHtml  = processHtml($scope.workspaceConfig.domain);
    }
    generateTheHtmlValues();

    $scope.showInput = false;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.processTemplate = function(hist) {
        return hist.template;
    }

    $scope.layoutChildren = function() {
        var yPos = 265;
        var len = $scope.children.length;
        if (len==0) {
            return;
        }
        if (len==1) {
            $scope.children[0].x = 175;
            $scope.children[0].y = yPos;
            return;
        }

        var minx = 70;
        if (len<6) {
            var xwidth = 210;
            var disp = xwidth / ($scope.children.length-1);
            for (var i=0; i<len; i++) {
                $scope.children[i].x = minx + (disp*i);
                $scope.children[i].y = yPos + (i%2 * 10*len);
            }
            return;
        }

        var amtLeft = len;
        var pos = 0;
        while (len-pos >= 5) {
            $scope.children[pos].x = minx;
            $scope.children[pos].y = yPos;
            pos++;
            $scope.children[pos].x = minx+105;
            $scope.children[pos].y = yPos;
            pos++;
            $scope.children[pos].x = minx+210;
            $scope.children[pos].y = yPos;
            pos++;
            yPos += 50;
            $scope.children[pos].x = minx+52;
            $scope.children[pos].y = yPos;
            pos++;
            $scope.children[pos].x = minx+157;
            $scope.children[pos].y = yPos;
            pos++;
            yPos += 50;
        }
        if (len-pos >= 1) {
            $scope.children[pos].x = minx;
            $scope.children[pos].y = yPos;
            pos++;
        }
        if (len-pos >= 1) {
            $scope.children[pos].x = minx+105;
            $scope.children[pos].y = yPos;
            pos++;
        }
        if (len-pos >= 1) {
            $scope.children[pos].x = minx+210;
            $scope.children[pos].y = yPos;
            pos++;
        }
        yPos += 50;
        if (len-pos >= 1) {
            $scope.children[pos].x = minx+52;
            $scope.children[pos].y = yPos;
            pos++;
        }
    }
    $scope.layoutChildren();
    $scope.maxLength = 350;
    $scope.children.forEach( function(item) {
        if (item.y+50 > $scope.maxLength) {
            $scope.maxLength = item.y+50;
        }
    });


    $scope.getHistory = function() {
        if ($scope.filter.length==0) {
            return $scope.allHistory;
        }
        var filter = $scope.filter.toLowerCase();
        var res = [];
        $scope.allHistory.map(  function(hItem) {
            if (hItem.respName.toLowerCase().indexOf(filter)>=0) {
                res.push(hItem);
            }
            else if (hItem.contextName.toLowerCase().indexOf(filter)>=0) {
                res.push(hItem);
            }
            else if (hItem.comments.toLowerCase().indexOf(filter)>=0) {
                res.push(hItem);
            }
            else if (hItem.contextType.toLowerCase().indexOf(filter)>=0) {
                res.push(hItem);
            }
            else if (hItem.action.toLowerCase().indexOf(filter)>=0) {
                res.push(hItem);
            }
        });
        return res;
    }

    $scope.ellipse = function(workspace) {
        window.location = "<%=ar.retPath%>t/"+workspace.site+"/"+workspace.key+"/FrontPage.htm";
    }
    $scope.topLevel = function(workspace) {
        window.location = "<%=ar.retPath%>t/"+workspace.site+"/"+workspace.key+"/FrontTop.htm";
    }
    $scope.navigateToUser = function(player) {
        window.location="<%=ar.retPath%>v/FindPerson.htm?key="+encodeURIComponent(player.key);
    }
    $scope.inviteMsg = "Hello,\n\nYou have been asked by '<%ar.writeHtml(uProf.getName());%>' to"
                    +" participate in the workspace for '<%ar.writeHtml(ngp.getFullName());%>'."
                    +"\n\nThe links below will make registration quick and easy, and after that you will be able to"
                    +" participate directly with the others through the site.";
    $scope.openInviteSender = function (player) {

        var proposedMessage = {}
        proposedMessage.msg = $scope.inviteMsg;
        proposedMessage.userId = player.uid;
        proposedMessage.name   = player.name;
        proposedMessage.return = "<%=ar.baseURL%><%=ar.getResourceURL(ngp, "FrontPage.htm")%>";
        
        var modalInstance = $modal.open({
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/InviteModal.html<%=templateCacheDefeater%>',
            controller: 'InviteModalCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                email: function () {
                    return player.uid;
                },
                msg: function() {
                    return proposedMessage;
                }
            }
        });

        modalInstance.result.then(function (actualMessage) {
            $scope.inviteMsg = actualMessage.msg;
        }, function () {
            //cancel action - nothing really to do
        });
        
    $scope.sendEmailLoginRequest = function(message) {
        SLAP.sendInvitationEmail(message);
        var postURL = "<%=ar.getSystemProperty("identityProvider")%>?openid.mode=apiSendInvite";
        var postdata = JSON.stringify(message);
        $http.post(postURL ,postdata)
        .success( function(data) {
            console.log("message has been sent to "+message.userId);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }

        
    };


});
</script>
<style>
.clipping {
    overflow: hidden;
    text-overflow: clip; 
    border-bottom:1px solid #EEEEEE;
    white-space: nowrap
}
a {
    color:black;
}
.spacytable tr td {
    padding:2px;
}
</style>
<!-- MAIN CONTENT SECTION START -->
<div>

<%@include file="ErrorPanel.jsp"%>

<!-- COLUMN 1 -->
<div class="col-md-4 col-sm-12">
        

    <div class="panel panel-default">
      <div class="panel-heading headingfont">
          <div style="float:left">Access</div>
          <div style="clear:both"></div>
      </div>
      <div class="panel-body">
        You do not play any role in this workspace.
      </div>
    </div>

</div>


<!-- COLUMN 2 -->
  <div class="col-md-4 col-sm-12">
       <svg height="{{maxLength}}px" width="350px">
           <g ng-show="parent.key">
               <ellipse cx="179" cy="69" rx="70" ry="35"
                    style="fill:gray;stroke:gray" ></ellipse>
               <line x1="177" y1="85" x2="177" y2="175" style="stroke:purple;stroke-width:2" ></line>
               <line x1="173" y1="85" x2="173" y2="175" style="stroke:purple;stroke-width:2" ></line>
               <ellipse cx="175" cy="65" rx="70" ry="35"  ng-click="ellipse(parent)"
                    style="fill:white;stroke:purple;stroke-width:2;cursor:pointer" ></ellipse>
               <foreignObject  x="105" y="50" width="140" height="70">
                  <div xmlns="http://www.w3.org/1999/xhtml" style="height:80px;vertical-align:middle;text-align:center;cursor:pointer;"
                       ng-click="ellipse(parent)">{{parent.name}}</div>
               </foreignObject>
           </g>
           <g ng-hide="parent.key">
               <ellipse cx="179" cy="69" rx="19" ry="18"
                    style="fill:gray;stroke:gray" ></ellipse>
               <line x1="177" y1="85" x2="177" y2="175" style="stroke:purple;stroke-width:2" ></line>
               <line x1="173" y1="85" x2="173" y2="175" style="stroke:purple;stroke-width:2" ></line>
               <ellipse cx="175" cy="65" rx="19" ry="18"  ng-click="topLevel(thisCircle)"
                    style="fill:white;stroke:purple;stroke-width:2;cursor:pointer" ></ellipse>
           </g>
           <ellipse cx="179" cy="179" rx="80" ry="40" ng-click="ellipse(thisCircle)"
                style="fill:gray;stroke:gray" ></ellipse>
           <g ng-repeat="child in children">
               <ellipse ng-attr-cx="{{child.x+4}}" ng-attr-cy="{{child.y+4}}"  ng-click="ellipse(child)"
                   rx="60" ry="30" style="fill:gray;stroke:gray" ></ellipse>
               <line ng-attr-x1="{{child.x+2}}" ng-attr-y1="{{child.y}}" x2="177" y2="175" style="stroke:purple;stroke-width:2" ></line>
               <line ng-attr-x1="{{child.x-2}}" ng-attr-y1="{{child.y}}" x2="173" y2="175" style="stroke:purple;stroke-width:2" ></line>
           </g>
           <ellipse cx="175" cy="175" rx="80" ry="40" ng-click="ellipse(thisCircle)"
                style="fill:#F0D7F7;stroke:purple;stroke-width:2;cursor:pointer" ></ellipse>
            <foreignObject  x="95" y="160" width="160" height="80">
               <div xmlns="http://www.w3.org/1999/xhtml" style="height:80px;vertical-align:middle;text-align:center;cursor:pointer;"
                       ng-click="ellipse(thisCircle)">{{thisCircle.name}}</div>
            </foreignObject>
           <g ng-repeat="child in children">
               <ellipse ng-attr-cx="{{child.x}}" ng-attr-cy="{{child.y}}"  ng-click="ellipse(child)"
                   rx="60" ry="30" style="fill:white;stroke:purple;stroke-width:2;cursor:pointer;" ></ellipse>
               <foreignObject ng-attr-x="{{child.x-55}}" ng-attr-y="{{child.y-15}}" width="110" height="60">
                   <div xmlns="http://www.w3.org/1999/xhtml" style="height:60px;vertical-align:middle;text-align:center;cursor:pointer;"
                       ng-click="ellipse(child)">{{child.name}}</div>
               </foreignObject>
           </g>
       </svg>
   </div>


<!-- COLUMN 3 -->
  <div class="col-md-4 col-sm-12">

    <div class="panel panel-default" ng-show="workspaceConfig.wsSettings.showVisionOnFrontPage">
      <div class="panel-heading headingfont">
          <div style="float:left">Vision of Workspace</div>
          <div style="float:right" title="Edit vision in this workspace">
              <i class="fa fa-info-circle"></i></div>
          <div style="clear:both"></div>
      </div>
      <div class="panel-body" >
          <div ng-bind-html="visionHtml"></div>
      </div>
    </div>
    <div class="panel panel-default" ng-show="workspaceConfig.wsSettings.showMissionOnFrontPage">
      <div class="panel-heading headingfont">
          <div style="float:left">Mission of Workspace</div>
          <div style="float:right" title="Edit mission in this workspace">
              <i class="fa fa-info-circle"></i></div>
          <div style="clear:both"></div>
      </div>
      <div class="panel-body" >
          <div ng-bind-html="missionHtml"></div>
      </div>
    </div>
    <div class="panel panel-default" ng-show="workspaceConfig.wsSettings.showAimOnFrontPage">
      <div class="panel-heading headingfont">
          <div style="float:left">Aim of Workspace</div>
          <div style="float:right" title="Edit aim in this workspace">
              <i class="fa fa-info-circle"></i></div>
          <div style="clear:both"></div>
      </div>
      <div class="panel-body" >
          <div ng-bind-html="purposeHtml"></div>
      </div>
    </div>
    <div class="panel panel-default" ng-show="workspaceConfig.wsSettings.showDomainOnFrontPage">
      <div class="panel-heading headingfont">
          <div style="float:left">Domain of Workspace</div>
          <div style="float:right" title="Edit domain in this workspace">
              <i class="fa fa-info-circle"></i></div>
          <div style="clear:both"></div>
      </div>
      <div class="panel-body" >
          <div ng-bind-html="domainHtml"></div>
      </div>
    </div>

    <div class="panel panel-default">
      <div class="panel-heading headingfont">Parent Circle</div>
      <div class="panel-body">
        <div >
          <a href="<%=ar.retPath%>t/{{parent.site}}/{{parent.key}}/FrontPage.htm">{{parent.name}}</a>
        </div>
      </div>
    </div>

    <div class="panel panel-default">
      <div class="panel-heading headingfont">Children Circles</div>
      <div class="panel-body">
        <div ng-repeat="child in children">
          <a href="<%=ar.retPath%>t/{{child.site}}/{{child.key}}/FrontPage.htm">{{child.name}}</a>
        </div>
      </div>
    </div>

  </div>

</div>
<script src="<%=ar.retPath%>templates/InviteModal.js"></script>
