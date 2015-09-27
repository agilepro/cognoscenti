<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId : This is the id of a Workspace and here it is used to retrieve NGPage.

*/

    ar.assertLoggedIn("Must be logged in to see a list of meetings");

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();
    Cognoscenti cog = ar.getCogInstance();


    List<HistoryRecord> histRecs = ngp.getAllHistory();
    JSONArray topHistory = new JSONArray();
    JSONArray recentChanges = new JSONArray();
    int limit=10;
    Hashtable<String,String> seenBefore = new Hashtable<String,String>();

    for (HistoryRecord hist : histRecs) {
        if (limit-- < 0) {
            break;
        }
        AddressListEntry ale = new AddressListEntry(hist.getResponsible());
        UserProfile responsible = ale.getUserProfile();
        String imagePath = "assets/photoThumbnail.gif";
        if(responsible!=null) {
            String imgPath = responsible.getImage();
            if (imgPath.length() > 0) {
                imagePath = "users/"+imgPath;
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
            url = ar.getResourceURL(ngp, "docinfo"+objectKey+".htm");
            AttachmentRecord att = ngp.findAttachmentByID(objectKey);
            if (att!=null) {
                objName = att.getDisplayName();
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_LEAFLET) {
            url = ar.getResourceURL(ngp, "noteZoom"+objectKey+".htm");
            NoteRecord nr = ngp.getNote(objectKey);
            if (nr!=null) {
                objName = nr.getSubject();
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_ROLE) {
            url = ar.getResourceURL(ngp, "permission.htm");
            NGRole role = ngp.getRole(objectKey);
            if (role!=null) {
                objName = role.getName();
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_MEETING) {
            url = ar.getResourceURL(ngp, "meetingFull.htm?id="+objectKey);
            MeetingRecord meet = ngp.findMeetingOrNull(objectKey);
            if (meet!=null) {
                objName = meet.getName() + " @ " + SectionUtil.getNicePrintDate( meet.getStartTime() );
            }
        }
        JSONObject jObj = hist.getJSON(ngp,ar);
        jObj.put("contextUrl", url );
        /*
        jObj.put("contextName", objName );
        */

        //elliminate duplicate objects
        boolean seen = seenBefore.containsKey(objectKey);
        if (!seen) {
            seenBefore.put(objectKey,objectKey);
            recentChanges.put(jObj);
        }
        topHistory.put(jObj);
    }

    JSONObject thisCircle = new JSONObject();
    thisCircle.put("name", ngp.getFullName());
    thisCircle.put("site", ngp.getKey());
    thisCircle.put("key",  ngp.getSiteKey());

    JSONObject parent = new JSONObject();
    NGPageIndex parentIndex = cog.getContainerIndexByKey(ngp.getParentKey());
    if (parentIndex==null) {
        parent.put("name", "");
        parent.put("site", "");
        parent.put("key",  "");
    }
    else {
        parent.put("name", parentIndex.containerName);
        parent.put("site", parentIndex.pageBookKey);
        parent.put("key",  parentIndex.containerKey);
    }

    JSONArray children = new JSONArray();
    for (NGPageIndex ngpi : cog.getAllContainers()) {
        if (!ngpi.isProject()) {
            continue;
        }
        if (pageId.equals(ngpi.parentKey)) {
            JSONObject jo = new JSONObject();
            jo.put("name", ngpi.containerName);
            jo.put("site", ngpi.pageBookKey);
            jo.put("key",  ngpi.containerKey);
            children.put(jo);
        }
    }

    UserProfile uProf = ar.getUserProfile();

    JSONArray yourRoles = new JSONArray();
    for (NGRole ngr : ngp.findRolesOfPlayer(uProf)) {
        yourRoles.put(ngr.getName());
    }

    JSONArray otherMembers = new JSONArray();
    for (AddressListEntry ale : ngp.getPrimaryRole().getExpandedPlayers(ngp)) {
        if (uProf.hasAnyId(ale.getUniversalId())) {
            continue;
        }
        otherMembers.put(ale.getJSON());
    }

    JSONArray myMeetings = new JSONArray();
    for (MeetingRecord meet : ngp.getMeetings()) {
        if (meet.getState() == 99) {
            continue;
        }
        myMeetings.put(meet.getListableJSON(ar));
    }

    JSONArray myActions = new JSONArray();
    for (GoalRecord action : ngp.getAllGoals()) {
        NGRole assignees = action.getAssigneeRole();
        if (!assignees.isExpandedPlayer(uProf, ngp)) {
            continue;
        }
        myActions.put(action.getJSON4Goal(ngp));
    }

%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.topHistory = <%topHistory.write(out,2,4);%>;
    $scope.recentChanges = <%recentChanges.write(out,2,4);%>;
    $scope.parent     = <%parent.write(out,2,4);%>;
    $scope.thisCircle = <%thisCircle.write(out,2,4);%>;
    $scope.children   = <%children.write(out,2,4);%>;
    $scope.yourRoles  = <%yourRoles.write(out,2,4);%>;
    $scope.otherMembers = <%otherMembers.write(out,2,4);%>;
    $scope.myMeetings = <%myMeetings.write(out,2,4);%>;
    $scope.myActions  = <%myActions.write(out,2,4);%>;
    $scope.filter = "";

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
        var xwidth = 210;
        var disp = xwidth / ($scope.children.length-1);
        for (var i=0; i<len; i++) {
            $scope.children[i].x = minx + (disp*i);
            $scope.children[i].y = yPos + (i%2 * 10*len);
        }
    }
    $scope.layoutChildren();

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

    $scope.makePath = function() {
        return "<%=ar.retPath%>t/geojungl/executiveteam/frontPage.htm";
    }
});
</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Front Page
        </div>
        <!--div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="">Do Nothing</a></li>
            </ul>
          </span>

        </div-->
    </div>

    <style>
      .tripleColumn {
          border: 1px solid lightgrey;
          border-radius:5px;
          padding:5px;
          background-color:#EEEEEE;
          margin:6px
      }
    </style>

    <table><tr style="vertical-align:top;">
    <td style="width:350px;vertial-align:top;">
       <div class="tripleColumn leafContent">
          <h1>Recent Updates</h1>
          <div ng-repeat="hist in recentChanges">
             <ul>
               <li>
                 <a href="<%=ar.retPath%>{{hist.contextUrl}}">{{hist.ctxName}}</a>
               </li>
             </ul>
          </div>
          <h1>Upcoming Meetings</h1>
          <ul>
            <li ng-repeat="meet in myMeetings">
              <a href="meetingFull.htm?id={{meet.id}}">{{meet.name}}</a>
            </li>
          </ul>
          <h1>Your Action Items</h1>
          <ul>
            <li ng-repeat="act in myActions">
              <a href="task{{act.id}}.htm">{{act.synopsis}}</a>
            </li>
          </ul>
          <h1>Recent History</h1>
          <div ng-repeat="hist in topHistory">
             {{hist.time|date}} -
             <a href="<%=ar.retPath%>{{hist.respUrl}}"><span class="red">{{hist.respName}}</span></a>

             {{hist.ctxType}} <a href="<%=ar.retPath%>{{hist.contextUrl}}">{{hist.ctxName}}</a>
             was {{hist.event}}.
             <br/>
             <i>{{hist.comments}}</i>
          </div>
       </div>
    </td>
    <td style="width:350px;vertial-align:top;">
       <div class="tripleColumn leafContent">
           <svg height="350px" width="350px">
               <g ng-show="parent.key">
                   <line x1="177" y1="85" x2="177" y2="175" style="stroke:rgb(120,0,0);stroke-width:2" />
                   <line x1="173" y1="85" x2="173" y2="175" style="stroke:rgb(120,0,0);stroke-width:2" />
                   <a ng-attr-xlink:href="{{makePath()}}">
                       <ellipse cx="175" cy="65" rx="70" ry="35"
                        style="fill:yellow;stroke:rgb(120,0,0);stroke-width:2" />
                        <text x="175" y="65" text-anchor="middle" fill="black">{{parent.name}}</text>
                   </a>
               </g>
               <g ng-repeat="child in children">
                   <line ng-attr-x1="{{child.x+2}}" ng-attr-y1="{{child.y}}" x2="177" y2="175" style="stroke:rgb(120,0,0);stroke-width:2" />
                   <line ng-attr-x1="{{child.x-2}}" ng-attr-y1="{{child.y}}" x2="173" y2="175" style="stroke:rgb(120,0,0);stroke-width:2" />
               </g>
               <ellipse cx="175" cy="175" rx="80" ry="40"
                    style="fill:yellow;stroke:rgb(120,0,0);stroke-width:2" />
               <a xlink:href="<%=ar.retPath%>t/xxx/frontPage.htm">
               </a>
               <a xlink:href="frontPage.htm">
                   <text x="175" y="175" text-anchor="middle" fill="black">{{thisCircle.name}}</text>
               </a>

               <g ng-repeat="child in children">
                   <ellipse ng-attr-cx="{{child.x}}" ng-attr-cy="{{child.y}}" rx="60" ry="30" style="fill:yellow;stroke:rgb(120,0,0);stroke-width:2" />
                   <text ng-attr-x="{{child.x}}" ng-attr-y="{{child.y}}" text-anchor="middle" fill="black">{{child.name}}</text>
               </g>
           </svg>
       </div>
    </td>
    <td style="width:350px;vertial-align:top;">
       <div class="tripleColumn leafContent">
           <div style="margin:5px;">
               <h1>Your Roles</h1>
               <ul>
               <li ng-repeat="role in yourRoles">{{role}}</li>
               </ul>
           </div>
           <div style="margin:5px;">
               <h1>Other Members</h1>
               <ul>
               <li ng-repeat="person in otherMembers">{{person.name}}</li>
               </ul>
           </div>
           <div style="margin:5px;">
               <h1>Parent Circle</h1>
               <ul>
               <li><a href="<%=ar.retPath%>t/{{parent.site}}/{{parent.key}}/frontPage.htm">{{parent.name}}</a>
               </li>
               </ul>
           </div>
           <div style="margin:5px;">
               <h1>Children Circles</h1>
               <ul>
               <li ng-repeat="child in children">
                   <a href="<%=ar.retPath%>t/{{child.site}}/{{child.key}}/frontPage.htm">{{child.name}}</a>
               </li>
               </ul>
           </div>
       </div>
    </td>
    </tr></table>


</div>
