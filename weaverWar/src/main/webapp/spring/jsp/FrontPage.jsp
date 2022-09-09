<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId : This is the id of a Workspace and here it is used to retrieve NGWorkspace.

*/

    ar.assertAccessWorkspace("Must be a member for this version of the page");

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


    JSONArray topHistory = new JSONArray();
    JSONArray recentChanges = new JSONArray();

    JSONObject thisCircle = new JSONObject();
    thisCircle.put("name", ngp.getFullName());
    thisCircle.put("key",  ngp.getKey());
    thisCircle.put("site", ngp.getSiteKey());
    if (ngpi.isDeleted()) {
        thisCircle.put("color", "#FFE3DB");
    }
    else if (ngpi.isFrozen()) {
        thisCircle.put("color", "#E2EFFF");
    }
    else {
        thisCircle.put("color", "#F0D7F7");
    }

    JSONObject parent = new JSONObject();
    NGPageIndex parentIndex = cog.getParentWorkspace(ngpi);
    if (parentIndex==null) {
        parent.put("name", "");
        parent.put("site", "");
        parent.put("key",  "");
        parent.put("color", "#F0D7F7");
    }
    else {
        parent.put("name", parentIndex.containerName);
        parent.put("key",  parentIndex.containerKey);
        parent.put("site", parentIndex.wsSiteKey);
        if (parentIndex.isDeleted()) {
            parent.put("color", "#FFE3DB");
        }
        else if (parentIndex.isFrozen()) {
            parent.put("color", "#E2EFFF");
        }
        else {
            parent.put("color", "white");
        }
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
        if (child.isDeleted()) {
            jo.put("color", "#FFE3DB");
        }
        else if (child.isFrozen()) {
            jo.put("color", "#E2EFFF");
        }
        else {
            jo.put("color", "white");
        }
        children.put(jo);
    }

    UserProfile uProf = ar.getUserProfile();

    JSONArray yourRoles = new JSONArray();
    JSONArray otherMembers = new JSONArray();
    JSONArray myMeetings = new JSONArray();
    JSONArray myActions = new JSONArray();
    

    List<HistoryRecord> histRecs = ngp.getAllHistory();
    int limit=10;
    Hashtable<String,String> seenBefore = new Hashtable<String,String>();

    for (HistoryRecord hist : histRecs) {
        AddressListEntry ale = new AddressListEntry(hist.getResponsible());
        UserProfile responsible = ale.getUserProfile();
        String imagePath = "assets/photoThumbnail.gif";
        if(responsible!=null) {
            String personImage = responsible.getImage();
            if (personImage!=null && personImage.length() > 0) {
                imagePath = "icon/"+personImage;
            }
        }
        String objectKey = hist.getContext();
        int contextType = hist.getContextType();
        String key = hist.getCombinedKey();
        String url = "";
        String cType = HistoryRecord.getContextTypeName(contextType);
        String objName = "Unidentified";
        if (contextType == HistoryRecord.CONTEXT_TYPE_PROCESS) {
            url = ar.getResourceURL(ngp, "projectAllTasks.htm");
            objName = "";
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_TASK) {
            url = ar.getResourceURL(ngp, "task"+objectKey+".htm");
            GoalRecord gr = ngp.getGoalOrNull(objectKey);
            if (gr!=null) {
                objName = gr.getSynopsis();
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_PERMISSIONS) {
            url = ar.getResourceURL(ngp, "findUser.htm?id=")+URLEncoder.encode(objectKey, "UTF-8");
            objName = objectKey;
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_DOCUMENT) {
            url = ar.getResourceURL(ngp, "DocDetail.htm?aid="+objectKey);
            AttachmentRecord att = ngp.findAttachmentByID(objectKey);
            if (att!=null) {
                objName = att.getDisplayName();
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_LEAFLET) {
            url = ar.getResourceURL(ngp, "noteZoom"+objectKey+".htm");
            TopicRecord nr = ngp.getDiscussionTopic(objectKey);
            if (nr!=null) {
                objName = nr.getSubject();
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_ROLE) {
            url = ar.getResourceURL(ngp, "RoleManagement.htm");
            NGRole role = ngp.getRole(objectKey);
            if (role!=null) {
                objName = role.getName();
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_MEETING) {
            url = ar.getResourceURL(ngp, "MeetingHtml.htm?id="+objectKey);
            MeetingRecord meet = ngp.findMeetingOrNull(objectKey);
            if (meet!=null) {
                objName = meet.getName() + " @ " + SectionUtil.getNicePrintDate( meet.getStartTime() );
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_DECISION) {
            url = ar.getResourceURL(ngp, "DecisionList.htm?id="+objectKey);
            MeetingRecord meet = ngp.findMeetingOrNull(objectKey);
        }
        JSONObject jObj = hist.getJSON(ngp,ar);
        jObj.put("contextUrl", url );

        //elliminate duplicate objects
        boolean seen = seenBefore.containsKey(objectKey);
        if (!seen && contextType!=HistoryRecord.CONTEXT_TYPE_PERMISSIONS) {
            seenBefore.put(objectKey,objectKey);
            recentChanges.put(jObj);
            if (limit-- < 0) {
                break;
            }
        }
        topHistory.put(jObj);
    }
    for (NGRole ngr : ngp.getAllRoles()) {
        JSONObject jo = new JSONObject();
        jo.put("name", ngr.getName());
        jo.put("player", ngr.isPlayer(uProf));
        yourRoles.put(jo);
    }

    for (AddressListEntry ale : ngp.getPrimaryRole().getExpandedPlayers(ngp)) {
        //used to remove the current user here, but feedback suggests
        //that we should include the current user in this list.
        otherMembers.put(ale.getJSON());
    }

    for (MeetingRecord meet : ngp.getMeetings()) {
        if (meet.getState() > 1) {
            continue;
        }
        myMeetings.put(meet.getListableJSON(ar));
    }

    for (GoalRecord action : ngp.getAllGoals()) {
        NGRole assignees = action.getAssigneeRole();
        if (!assignees.isExpandedPlayer(uProf, ngp)) {
            continue;
        }
        int state = action.getState();
        if (state==BaseRecord.STATE_OFFERED || state==BaseRecord.STATE_ACCEPTED) {
            myActions.put(action.getJSON4Goal(ngp));
        }
    }

    
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
        window.location="<%=ar.retPath%>v/"+encodeURIComponent(player.key)+"/PersonShow.htm";
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
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

<!-- COLUMN 1 -->
      <div class="col-md-4 col-sm-12">
        <div class="panel panel-default">
          <div class="panel-heading headingfont">
              <div style="float:left">Recent Updates</div>
              <div style="float:right" title="Access the detailed history of events in this workspace">
                  <a href="History.htm">
                      <i class="fa fa-list"></i></a></div>
              <div style="clear:both"></div>
          </div>
          <div class="panel-body">
            <div ng-repeat="hist in recentChanges" class="clipping">
              <a href="<%=ar.retPath%>{{hist.contextUrl}}">{{hist.ctxName}}</a>
            </div>
          </div>
        </div>

        <div class="panel panel-default">
          <div class="panel-heading headingfont">
              <div style="float:left">Planned Meetings</div>
              <div style="float:right" title="Go to a list of all meetings in the workspace">
                  <a href="MeetingList.htm">
                      <i class="fa fa-gavel"></i></a></div>
              <div style="clear:both"></div>
          </div>
          <div class="panel-body">
            <div ng-repeat="meet in myMeetings"  class="clipping">
              <a href="MeetingHtml.htm?id={{meet.id}}">{{meet.name}}, {{meet.startTime|date: "MMM dd, HH:mm"}}</a>
            </div>
          </div>
        </div>




        <div class="panel panel-default">
          <div class="panel-heading headingfont">
              <div style="float:left">Your Action Items</div>
              <div style="float:right" title="Access the list of all action items">
                  <a href="goalList.htm">
                      <i class="fa fa-list"></i></a></div>
              <div style="clear:both"></div>
          </div>
          <div class="panel-body">
            <div ng-repeat="act in myActions"  class="clipping">
              <a href="task{{act.id}}.htm">{{act.synopsis}}</a>
            </div>
          </div>
        </div>



        <div class="panel panel-default">
          <div class="panel-heading headingfont">
              <div style="float:left">Recent History</div>
              <div style="float:right" title="Access the detailed history of events in this workspace">
                  <a href="History.htm">
                      <i class="fa fa-list"></i></a></div>
              <div style="clear:both"></div>
          </div>
          <div class="panel-body clipping">
            <div ng-repeat="hist in topHistory"  class="clipping">
              {{hist.time|cdate}} -
             <a href="<%=ar.retPath%>{{hist.respUrl}}"><span class="red">{{hist.respName}}</span></a>

             {{hist.ctxType}} <a href="<%=ar.retPath%>{{hist.contextUrl}}">{{hist.ctxName}}</a>
             was {{hist.event}}.
             <br/>
             <i>{{hist.comments}}</i>
            </div>
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
                        style="fill:{{parent.color}};stroke:purple;stroke-width:2;cursor:pointer" ></ellipse>
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
                    style="fill:{{thisCircle.color}};stroke:purple;stroke-width:2;cursor:pointer" ></ellipse>
                <foreignObject  x="95" y="160" width="160" height="80">
                   <div xmlns="http://www.w3.org/1999/xhtml" style="height:80px;vertical-align:middle;text-align:center;cursor:pointer;"
                           ng-click="ellipse(thisCircle)">{{thisCircle.name}}</div>
                </foreignObject>
               <g ng-repeat="child in children">
                   <ellipse ng-attr-cx="{{child.x}}" ng-attr-cy="{{child.y}}"  ng-click="ellipse(child)"
                       rx="60" ry="30" style="fill:{{child.color}};stroke:purple;stroke-width:2;cursor:pointer;" ></ellipse>
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
                  <a href="AdminSettings.htm">
                      <i class="fa fa-info-circle"></i></a></div>
              <div style="clear:both"></div>
          </div>
          <div class="panel-body" >
              <a href="AdminSettings.htm">
              <div ng-bind-html="visionHtml"></div>
              </a>
          </div>
        </div>
        <div class="panel panel-default" ng-show="workspaceConfig.wsSettings.showMissionOnFrontPage">
          <div class="panel-heading headingfont">
              <div style="float:left">Mission of Workspace</div>
              <div style="float:right" title="Edit mission in this workspace">
                  <a href="AdminSettings.htm">
                      <i class="fa fa-info-circle"></i></a></div>
              <div style="clear:both"></div>
          </div>
          <div class="panel-body" >
              <a href="AdminSettings.htm">
              <div ng-bind-html="missionHtml"></div>
              </a>
          </div>
        </div>
        <div class="panel panel-default" ng-show="workspaceConfig.wsSettings.showAimOnFrontPage">
          <div class="panel-heading headingfont">
              <div style="float:left">Aim of Workspace</div>
              <div style="float:right" title="Edit aim in this workspace">
                  <a href="AdminSettings.htm">
                      <i class="fa fa-info-circle"></i></a></div>
              <div style="clear:both"></div>
          </div>
          <div class="panel-body" >
              <a href="AdminSettings.htm">
              <div ng-bind-html="purposeHtml"></div>
              </a>
          </div>
        </div>
        <div class="panel panel-default" ng-show="workspaceConfig.wsSettings.showDomainOnFrontPage">
          <div class="panel-heading headingfont">
              <div style="float:left">Domain of Workspace</div>
              <div style="float:right" title="Edit domain in this workspace">
                  <a href="AdminSettings.htm">
                      <i class="fa fa-info-circle"></i></a></div>
              <div style="clear:both"></div>
          </div>
          <div class="panel-body" >
              <a href="AdminSettings.htm">
              <div ng-bind-html="domainHtml"></div>
              </a>
          </div>
        </div>
        
        
        <div class="panel panel-default">
          <div class="panel-heading headingfont">
              <div style="float:left">Your Roles</div>
              <div style="float:right" title="View and manage the roles in this workspace">
                  <a href="RoleManagement.htm">
                      <i class="fa fa-users"></i></a></div>
              <div style="clear:both"></div>
          </div>
          <div class="panel-body">
            <div ng-repeat="role in yourRoles">
              <a href="RoleManagement.htm">
                  <span ng-show="role.player"><i class="fa fa-check-circle-o"></i></span>
                  <span ng-hide="role.player"><i class="fa fa-circle-o"></i></span>
                  {{role.name}}
                  </a>
            </div>
            <div>
                <span ng-show="isWatching">
                    You <span class="fa fa-eye"></span> watch this workspace
                </span>
            </div>
          </div>
        </div>

        <div class="panel panel-default">
          <div class="panel-heading headingfont">
              <div style="float:left">Members</div>
              <div style="float:right" title="View and manage the roles in this workspace">
                  <a href="RoleManagement.htm">
                      <i class="fa fa-users"></i></a></div>
              <div style="clear:both"></div>
          </div>
          <div class="panel-body">
            <table class="spacytable">
            <tr ng-repeat="person in otherMembers">
              <td>
                  <span class="dropdown">
                    <span id="menu1" data-toggle="dropdown">
                    <img class="img-circle" src="<%=ar.retPath%>icon/{{person.key}}.jpg" 
                         style="width:32px;height:32px" title="{{person.name}} - {{person.uid}}">
                    </span>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                          tabindex="-1" ng-click="" style="text-decoration: none;text-align:center">
                          {{person.name}}<br/>{{person.uid}}</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="navigateToUser(person)">
                          <span class="fa fa-user"></span> Visit Profile</a></li>
                      <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                          ng-click="openInviteSender(person)">
                          <span class="fa fa-envelope-o"></span> Send Invitation</a></li>
                    </ul>
                  </span>
              </td>
              <td> {{person.name}} </td>
            </tr>
            </table>
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
