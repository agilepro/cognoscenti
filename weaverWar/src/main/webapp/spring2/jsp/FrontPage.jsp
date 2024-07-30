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
        //if (contextType == HistoryRecord.CONTEXT_TYPE_PROCESS) {
        //    url = ar.getResourceURL(ngp, "projectAllTasks.htm");
        //    objName = "";
        //}
        //else 
        if (contextType == HistoryRecord.CONTEXT_TYPE_TASK) {
            url = ar.getResourceURL(ngp, "task"+objectKey+".htm");
            GoalRecord gr = ngp.getGoalOrNull(objectKey);
            if (gr!=null) {
                objName = gr.getSynopsis();
            }
        }
        //else if (contextType == HistoryRecord.CONTEXT_TYPE_PERMISSIONS) {
        //    url = ar.getResourceURL(ngp, "findUser.htm?id=")+URLEncoder.encode(objectKey, "UTF-8");
        //    objName = objectKey;
        //}
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
        //else if (contextType == HistoryRecord.CONTEXT_TYPE_ROLE) {
        //    url = ar.getResourceURL(ngp, "RoleManagement.htm");
        //    NGRole role = ngp.getRole(objectKey);
        //    if (role!=null) {
        //        objName = role.getName();
        //    }
        //}
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
        if (!seen) {
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
    setUpLearningMethods($scope, $modal, $http);
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
    $scope.projectMode = function() {
        if ($scope.workspaceConfig.deleted) {
            return "deletedMode";
        }
        if ($scope.workspaceConfig.frozen) {
            return "freezedMode";
        }
        return "normalMode";
    }

});
</script>


<!-- MAIN CONTENT SECTION START -->
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>
<div class="container-fluid">
    <div class="row">
<!-- COLUMN 1 -->
    <div class="col-md-4 col-sm-12">
        <div class="card m-3">
            <div class="card-header">
                <div class="d-flex" title="Access the detailed history of events in this workspace"><h2 class="h5 card-title">Recent Updates</h2>
                    <div class="ms-auto">
                        <a href="History.htm">
                            <i class="fa fa-list"></i>
                        </a>
                    </div>
                </div>
            </div>
            <div class="card-body">
                <div ng-repeat="hist in recentChanges" class="clipping">
                <a href="<%=ar.retPath%>{{hist.contextUrl}}">{{hist.ctxName}}</a>
                </div>
            </div>
        </div>
        <div class="card m-3">
            <div class="card-header">
                <div class="d-flex" title="Go to a list of all meetings in the workspace"><h2 class="h5 card-title">Upcoming Meetings</h2>
                    <div class="ms-auto">
                        <a href="MeetingList.htm">
                            <i class="fa fa-gavel"></i>
                        </a>
                    </div>
                </div>
            </div>
            <div class="card-body">
                <div ng-repeat="meet in myMeetings"  class="clipping">
                <a href="MeetingHtml.htm?id={{meet.id}}">{{meet.name}}, {{meet.startTime|date: "MMM dd, HH:mm"}}</a>
                </div>
            </div>
        </div>
        <div class="card m-3">
            <div class="card-header">
                <div class="d-flex" title="Go to a list of all action items in the workspace"><h2 class="h5 card-title" >Upcoming Action Items</h2>
                    <div class="ms-auto">
                        <a href="GoalList.htm">
                            <i class="fa fa-list"></i>
                        </a>
                    </div>
                </div>
            </div>
            <div class="card-body">
                <div ng-repeat="act in myActions"  class="clipping">
                    <a href="task{{act.id}}.htm">{{act.synopsis}}</a>
                </div>
            </div>
        </div>
        <div class="accordion m-3">
            <div class="accordion-item">
                <h2 class="h5 accordion-header" id="headingOne">
                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseOne" title="Access the detailed history of events in this workspace" aria-expanded="false" aria-controls="collapseOne">
                        Recent Changes &nbsp; &nbsp; <a href="CommentList.htm">
                            <i class="fa fa-comments"></i>
                        </a></button>
                </h2>
                        
            </div>
            <div id="collapseOne" class="accordion-collapse collapse" aria-labelledby="headingOne" data-bs-parent="#accordionExample">
                <div class="accordion-body">
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
    </div>


<!-- COLUMN 2 -->
    <div class="col-md-4 col-sm-12">
        <svg height="{{maxLength}}px" width="{{maxWidth}}px" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" viewBox="0 0">
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
        <div class="card m-3">
            <div class="card-header">
                <h2 class="h5 card-title" title="View and manage the roles in this workspace">Your Roles
                <span style="float:right" >
                    <a href="RoleManagement.htm">
                        <i class="fa fa-users"></i>
                    </a>
                </span></h2>
            </div>
            <div class="card-body">
                <div ng-repeat="role in yourRoles">
                <a href="RoleManagement.htm">
                    <span ng-show="role.player"><i class="fa fa-check-circle-o"></i></span>
                    <span ng-hide="role.player"><i class="fa fa-circle-o"></i></span>
                    {{role.name}}
                </a>
                </div>
                <div class="my-2 ms-auto">
                <span ng-show="isWatching">
                    You <span class="fa fa-eye"></span> watch this workspace
                </span>
                </div>
            </div>
        </div>
        <div class="card m-3">
            <div class="card-header">
                <h2 class="h5 card-title" title="View and manage the roles in this workspace">Members
                    <div style="float:right" >
                        <a href="RoleManagement.htm">
                        <i class="fa fa-users"></i></a>
                    </div>
                </h2>
            </div>
            <div class="card-body">
                <div class="spacytable">
                    <div class="row" ng-repeat="person in otherMembers">
                        <ul class="navbar-btn">
                            <li class="nav-item dropdown" id="members" data-toggle="dropdown">
                                <img class="rounded-5" src="<%=ar.retPath%>icon/{{person.key}}.jpg" style="width:32px;height:32px" title="{{person.name}} - {{person.uid}}">&nbsp; &nbsp;{{person.name}} 
                                <ul class="dropdown-menu" role="menu" aria-labelledby="members">
                                    <li style="background-color:lightgrey">
                                        <a class="dropdown-item" role="menuitem" tabindex="-1" ng-click="" style="text-decoration: none;text-align:center">{{person.name}}<br/>{{person.uid}}</a></li>
                                <li role="presentation" style="cursor:pointer"><a class="dropdown-item" role="menuitem" tabindex="-1" ng-click="navigateToUser(person)">
                                    <span class="fa fa-user"></span> Visit Profile</a>
                                </li>
                                <li role="presentation" style="cursor:pointer"><a  class="dropdown-item" role="menuitem" tabindex="-1" ng-click="openInviteSender(person)">
                                    <span class="fa fa-envelope-o"></span> Send Invitation</a>
                                </li>
                            </ul>
                        </li>
                        </ul>
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

<script src="<%=ar.retPath%>templates/InviteModal.js"></script>
