<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%
/*
Required parameters:

    1. pageId : This is the id of a Workspace and here it is used to retrieve NGWorkspace.

*/

    ar.assertLoggedIn("Must be logged in to see a workspace");

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGPageIndex ngpi = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId);
    NGWorkspace ngw = ngpi.getWorkspace();
    ar.setPageAccessLevels(ngw);
    NGBook site = ngw.getSite();
    Cognoscenti cog = ar.getCogInstance();

    
    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }


    JSONArray topHistory = new JSONArray();
    JSONArray recentChanges = new JSONArray();

    JSONObject thisCircle = new JSONObject();
    thisCircle.put("name", ngw.getFullName());
    thisCircle.put("key",  ngw.getKey());
    thisCircle.put("site", ngw.getSiteKey());
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
    boolean isWatching = uProf.isWatch(siteId+"|"+pageId);
    
    List<TopicRecord> ltdTopics = new ArrayList<TopicRecord>();
    
    for (TopicRecord topicRec : ngw.getAllDiscussionTopics()) {
        NGRole subscribers = topicRec.getSubscriberRole();
        if (!subscribers.isExpandedPlayer(uProf, ngw)) {
            continue;
        }
        ltdTopics.add(topicRec);
    }
    
    List<MeetingRecord> ltdMeetings = new ArrayList<MeetingRecord>();
    for (MeetingRecord meet : ngw.getMeetings()) {
        boolean found = false;
        for (String participant : meet.getParticipants()) {
            if (uProf.hasAnyId(participant)) {
                found = true;
            }
        }
        if (found) {
            ltdMeetings.add(meet);
        }
    }
    

%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Workspace Front Page");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.workspaceConfig = <%ngw.getConfigJSON().write(out,2,4);%>;
    $scope.topHistory = <%topHistory.write(out,2,4);%>;
    $scope.recentChanges = <%recentChanges.write(out,2,4);%>;
    $scope.parent     = <%parent.write(out,2,4);%>;
    $scope.thisCircle = <%thisCircle.write(out,2,4);%>;
    $scope.children   = <%children.write(out,2,4);%>;
    $scope.yourRoles  = <%yourRoles.write(out,2,4);%>;
    $scope.otherMembers = <%otherMembers.write(out,2,4);%>;
    $scope.myMeetings = <%myMeetings.write(out,2,4);%>;
    $scope.myActions  = <%myActions.write(out,2,4);%>;
    $scope.purpose = "<%ar.writeJS(ngw.getProcess().getDescription());%>";
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
                    +" participate in the workspace for '<%ar.writeHtml(ngw.getFullName());%>'."
                    +"\n\nThe links below will make registration quick and easy, and after that you will be able to"
                    +" participate directly with the others through the site.";
    $scope.openInviteSender = function (player) {

        var proposedMessage = {}
        proposedMessage.msg = $scope.inviteMsg;
        proposedMessage.userId = player.uid;
        proposedMessage.name   = player.name;
        proposedMessage.return = "<%=ar.baseURL%><%=ar.getResourceURL(ngw, "FrontPage.htm")%>";
        
        var modalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>new_assets/templates/InviteModal.html<%=templateCacheDefeater%>',
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

        
    };
        
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

<!-- MAIN CONTENT SECTION START -->
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>
<div class="container-fluid override">
    <div class="row">
<!-- COLUMN 1 -->
    <div class="col-md-4 col-sm-12">
        <div class="card m-3">
            <div class="card-header">
                <div class="d-flex" title="Limited Access to this workspace"><h2 class="h5 card-title">Access</h2>
                    <div class="ms-auto"></div>
                </div>
            </div>

            <div class="card-body fs-6">
                You do not play any role in this workspace.
                <br/>
                You do have some limited access to some things.
            </div>
        </div>

<%
    if (ltdTopics.size()>0) {
%>
<div class="card m-3">
    <div class="card-header">
        <div class="d-flex" title="Discussions you can contribute to"><h2 class="h5 card-title">Discussions you subscribe to</h2>
            <div class="ms-auto"></div>
        </div>
    </div>
    <div class="card-body">

<%
    for (TopicRecord topicRec : ltdTopics) {
%>
            <div class="clipping">
              <a href="noteZoom<%=topicRec.getId()%>.htm">
                <i class="fa fa-lightbulb-o"></i> <%ar.writeHtml( topicRec.getSubject() );%>
                </a>
            </div>
<%
        }
%>
      </div>
    </div>
<%
    }
%>


<%
    if (ltdMeetings.size()>0) {
%>
<div class="card m-3">
    <div class="card-header">
        <div class="d-flex" title="Meetings you have access to"><h2 class="h5 card-title">Meetings you participate in</h2>
            <div class="ms-auto"></div>
        </div>
    </div>
    <div class="card-body">

<%
    for (MeetingRecord meet : ltdMeetings) {
%>
        <div class="clipping">
            <i class="fa fa-gavel"></i> <a href="MeetingHtml.htm?id=<%=meet.getId()%>"><%=meet.getName()%>, {{<%=meet.getStartTime()%>|date: "MMM dd, HH:mm"}}</a>
        </div>
<%
        }
%>
    </div>
</div>
<%
    }
%>

<div class="card m-3">
    <div class="card-header">
        <div class="d-flex"><h2 class="h5 card-title">Request Membership</h2></div>
    </div>
        <div class="card-body">
        <div ng-hide="enterMode || alternateEmailMode" class="warningBox">
            <div ng-show="isRequested">
                 You requested membership on {{requestDate|cdate}} as {{oldRequestEmail}}.<br/>
                 The status of that request is: <b>{{requestState}}</b>.
            </div>
            <div ng-hide="isRequested">
                If you think you should be a member then please:  
            </div>
            <button class="my-2 btn btn-primary btn-wide btn-raised pull-right" ng-click="takeStep()">Request Membership</button>
        </div>
        <div ng-show="enterMode && !alternateEmailMode" class="warningBox well">
            <div>Enter a reason to join the workspace:</div>
            <textarea ng-model="enterRequest" class="form-control"></textarea>
            <button class="btn btn-danger btn-raised" ng-click="enterMode=false">Cancel</button>
            <button class="btn btn-primary btn-raised float-end" ng-click="roleChange()">Request Membership</button>
            
        </div>
</div>
    </div>

    </div>


<!-- COLUMN 2 -->
<div class="col-md-4 col-sm-12">
    <svg height="{{maxLength}}px" width="100%" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" viewBox="0 0">
        <g ng-show="parent.key">
            <ellipse cx="179" cy="69" rx="70" ry="35"
                    style="fill:gray;stroke:gray" ></ellipse>
            <line x1="177" y1="85" x2="177" y2="175" style="stroke:purple;stroke-width:2" ></line>
            <line x1="173" y1="85" x2="173" y2="175" style="stroke:purple;stroke-width:2" ></line>
            <ellipse cx="175" cy="65" rx="70" ry="35"  ng-click="ellipse(parent)" style="fill:{{parent.color}};stroke:purple;stroke-width:2;cursor:pointer" ></ellipse>
            <foreignObject  x="105" y="50" width="140" height="70">
                <div xmlns="http://www.w3.org/1999/xhtml" style="height:80px;vertical-align:middle;text-align:center;cursor:pointer;" ng-click="ellipse(parent)">{{parent.name}}</div>
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
<!--Workspace State-->
    <div class="row m-2">
        <span ng-click="setEdit('frozen')" class="col-1 bold fixed-width-sm labelColumn mt-2">Workspace State:</span>
        <span class="col-8 mt-3 bold" ng-hide="isEditing=='frozen'" ng-dblclick="setEdit('frozen')">
            <span ng-show="workspaceConfig.deleted">Workspace is marked to be DELETED the next time the Site Administrator performs a 'Garbage Collect'</span>
            <span ng-show="workspaceConfig.frozen && !workspaceConfig.deleted">This workspace is FROZEN, it is viewable but can not be changed.</span>
            <span ng-show="!workspaceConfig.frozen && !workspaceConfig.deleted">Active and available for use including updating contents.</span>
        </span>
        <span class="col-8" ng-show="isEditing=='frozen'">
            <div ng-hide="workspaceConfig.frozen">
            <button ng-click="workspaceConfig.frozen=true;saveOneField('frozen', true)"
                class="btn btn-primary btn-raised">
                Freeze Workspace</button><br/>
                Use this <b>Freeze</b> to change an active workspace into a frozen workspace where nothing can be changed.  Frozen workspaces do not count toward your quota of workspace in the site.
            </div>
            <div ng-show="workspaceConfig.frozen && !workspaceConfig.deleted">
            <button ng-click="workspaceConfig.frozen=false;saveOneField('frozen', true)"
                class="btn btn-primary btn-raised">
                Unfreeze Workspace</button><br/>
                Use <b>Unfreeze</b> to change workspace to be active so that things in the workspace can be changed.
                You are only allowed a certain number of active workspaces in a site depending upon 
                your playment plan.  
                <br/>
                If you already have the maximum number of active workspaces, you will not be able to 
                unfreeze this workspace, until you freeze or delete another active one.
            </div>
            <div ng-hide="workspaceConfig.deleted">
            <button ng-click="workspaceConfig.deleted=true;saveOneField('deleted', true)"
                class="btn btn-primary btn-raised" >
                Delete Workspace</button><br/>
                Use <b>Delete</b> option to delete a workspace.  
                The workspace will actually remain around until the 
                <b>Garbage Collect</b> operation is run at the site level.
                After garbage collection the workspace will be permanently gone,
                and no information can be retrieved.
            </div>
            <div ng-show="workspaceConfig.deleted">
            <button ng-click="undeleteWorkspace()"
                class="btn btn-primary btn-raised" >
                Undelete Workspace</button><br/>
                If you didn't really want to delete the workspace, 
                use this <b>Undelete</b> to cancel the delete, 
                and return the workspace to a frozen state.
            </div>
            <div>
                <button ng-click="isEditing=null" class="btn btn-warning btn-raised">
                Cancel</button><br/>
                Use <b>Cancel</b> to close this option without changing the workspace state.
            </div>
        </span>
        
    </div><!--END Workspace-->

</div>

<!-- COLUMN 3 -->
<div class="col-md-4 col-sm-12">
    <div class="accordion m-3" ng-show="workspaceConfig.wsSettings.showVisionOnFrontPage">
        <div class="accordion-item">
            <h2 class="accordion-header" id="headingVision">
                <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseVision" aria-expanded="false" aria-controls="collapseVision">Vision of Workspace &nbsp;&nbsp;
                    <div title="Edit vision in this workspace">
                        <a href="AdminSettings.htm">
                            <i class="fa fa-info-circle"></i></a></div>
                </button>
            </h2>
            <div id="collapseVision" class="accordion-collapse collapse" aria-labelledby="headingVision" data-bs-parent="#accordion">
                <div class="accordion-body">
                    <a href="AdminSettings.htm">
                    <div ng-bind-html="visionHtml">
                    </div>
                    </a>
                </div>
            </div>
        </div>
    </div>
    <div class="accordion m-3" ng-show="workspaceConfig.wsSettings.showMissionOnFrontPage">
        <div class="accordion-item">
            <h2 class="accordion-header" id="headingMission">
                <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseMission" aria-expanded="false" aria-controls="collapseMission">Mission of Workspace &nbsp;&nbsp;
                    <div title="Edit mission in this workspace">
                        <a href="AdminSettings.htm">
                        <i class="fa fa-info-circle"></i></a>
                    </div>
                </button>
            </h2>
            <div id="collapseMission" class="accordion-collapse collapse" aria-labelledby="headingMission" data-bs-parent="#accordion" >
                <div class="accordion-body">
                    <a href="AdminSettings.htm">
                        <div ng-bind-html="missionHtml">
                        </div>
                    </a>
                </div>
            </div>
        </div>
    </div>
    <div class="accordion m-3" ng-show="workspaceConfig.wsSettings.showAimOnFrontPage">
        <div class="accordion-item">
            <h2 class="accordion-header" id="headingAim">
                <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseAim" aria-expanded="false" aria-controls="collapseAim">Aim of Workspace &nbsp;&nbsp;
                    <div title="Edit aim in this workspace">
                        <a href="AdminSettings.htm">
                        <i class="fa fa-info-circle"></i></a>
                    </div>
                </button>
            </h2>
            <div id="collapseAim" class="accordion-collapse collapse" aria-labelledby="headingAim" data-bs-parent="#accordion" >
                <div class="accordion-body">
                    <a href="AdminSettings.htm">
                        <div ng-bind-html="aimHtml">
                        </div>
                    </a>
                </div>
            </div>
        </div>
    </div>
    <div class="accordion m-3" ng-show="workspaceConfig.wsSettings.showDomainOnFrontPage">
            <div class="accordion-item">
                <h2 class="accordion-header" id="headingDomain">
                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseDomain" aria-expanded="false" aria-controls="collapseDomain">Domain of Workspace&nbsp;&nbsp;
                        <div title="Edit domain in this workspace">
                            <a href="AdminSettings.htm">
                            <i class="fa fa-info-circle"></i></a>
                        </div>
                    </button>
                </h2>
                <div id="collapseDomain" class="accordion-collapse collapse" aria-labelledby="headingDomain" data-bs-parent="#accordion" >
                    <div class="accordion-body">
                        <a href="AdminSettings.htm">
                            <div ng-bind-html="domainHtml">
                            </div>
                        </a>
                    </div>
                </div>
            </div>
    </div>

    <div class="accordion m-3">
        <div class="accordion-item">
            <h2 class="accordion-header">
                <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseParent" aria-expanded="false" aria-controls="collapseParent">Parent Circle</button></h2>
            <div id="collapseParent" class="accordion-collapse collapse" aria-labelledby="headingParent" data-bs-parent="#accordionExample">
                <a href="<%=ar.retPath%>t/{{parent.site}}/{{parent.key}}/FrontPage.htm">{{parent.name}}</a>
            </div>
        </div>
    </div>
    <div class="accordion m-3">
        <div class="accordion-item">
            <h2 class="accordion-header">
                <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseChildren" aria-expanded="false" aria-controls="collapseFour">Children Circles</button></h2>
            <div id="collapseChildren" class="accordion-collapse collapse" aria-labelledby="headingChildren" data-bs-parent="#accordionExample">
                <div ng-repeat="child in children">
                    <a href="<%=ar.retPath%>t/{{child.site}}/{{child.key}}/FrontPage.htm">{{child.name}}</a>
                </div>
            </div>
        </div>
    </div>

  </div>
    </div>
</div>
<script src="<%=ar.retPath%>new_assets/templates/InviteModal.js"></script>
