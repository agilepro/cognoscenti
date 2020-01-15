<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId : This is the id of a Workspace and here it is used to retrieve NGWorkspace.

*/

    ar.assertLoggedIn("Must be logged in to see a list of meetings");

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    String siteKey = ngp.getSiteKey();
    NGBook ngb = ngp.getSite();
    Cognoscenti cog = ar.getCogInstance();

    NGPageIndex parentIndex = cog.getWSByCombinedKey(ngp.getParentKey());
    if (parentIndex != null && !siteId.equals(parentIndex.wsSiteKey)) {
        parentIndex = null;
    }
    if (parentIndex!=null) {
        throw new Exception("this is quite strange ... this page is not supposed to have a parent.");
    }

    int[] point = new int[2];
    point[0] = 180;
    point[1] = 120;
    
    JSONArray container = new JSONArray();
    List<NGPageIndex> allContainers = new ArrayList<NGPageIndex>();
    for (NGPageIndex ngpi : cog.getAllContainers()) {
        if (!ngpi.isProject()) {
            continue;
        }
        if (!siteKey.equals(ngpi.wsSiteKey)) {
            continue;
        }
        allContainers.add(ngpi);
    }
    layoutRoot(allContainers, point, container, cog);

    UserProfile uProf = ar.getUserProfile();

%>
<%!

public void layoutRoot( List<NGPageIndex> allContainers, int point[], JSONArray container, Cognoscenti cog) throws Exception  {
    for (NGPageIndex ngpi : allContainers) {
        if (ngpi.parentKey == null || ngpi.parentKey.length()==0) {
            JSONObject jo = new JSONObject();
            jo.put("name", ngpi.containerName);
            jo.put("key",  ngpi.containerKey);
            jo.put("site", ngpi.wsSiteKey);
            jo.put("x", point[0]);
            jo.put("y", point[1]);
            jo.put("parx", 50);
            jo.put("pary", 50);
            container.put(jo);
            layout(allContainers, point, ngpi.containerKey, container);
            point[1] = point[1]+70;
        }
    }
}
public void layout( List<NGPageIndex> allContainers, int point[], String parent, JSONArray container) throws Exception {
    int parx = point[0];
    int pary = point[1];
    point[0] = point[0] + 130;
    point[1] = point[1] + 70;
    for (NGPageIndex ngpi : allContainers) {
        if (ngpi.parentKey==null) {
            continue;
        }
        if (!parent.equals(ngpi.parentKey)) {
            continue;
        }
        JSONObject jo = new JSONObject();
        jo.put("name", ngpi.containerName);
        jo.put("key",  ngpi.containerKey);
        jo.put("site", ngpi.wsSiteKey);
        jo.put("x", point[0]);
        jo.put("y", point[1]);
        jo.put("parx", parx);
        jo.put("pary", pary);
        container.put(jo);
        layout(allContainers, point, ngpi.containerKey, container);
        point[1] = point[1]+70;
    }
    point[0] = point[0] - 130;
    point[1] = point[1] - 70;
}

%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Top Level Workspaces");
    $scope.children   = <%container.write(out,2,4);%>;
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
    $scope.maxLength = 800;
    $scope.maxWidth = 1200;

    $scope.layoutChildren = function() {
        console.log("laying out children");
        var len = $scope.children.length;
        if (len==0) {
            return;
        }
        var minx = 70;
        var yPos = 50;
        var pos = 0;
        while (pos < len) {
            console.log("pos", pos, len);
            $scope.children[pos].x = minx;
            $scope.children[pos].y = yPos;
            yPos += 70;
            $scope.maxLength = yPos+70;
            pos++;
        }
    }
//    $scope.layoutChildren();
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

    $scope.makePath = function() {
        return "<%=ar.retPath%>t/geojungl/executiveteam/frontPage.htm";
    }

    $scope.ellipse = function(workspace) {
        window.location = "<%=ar.retPath%>t/"+workspace.site+"/"+workspace.key+"/frontPage.htm";
    }
    $scope.topLevel = function(workspace) {
        window.location = "<%=ar.retPath%>t/"+workspace.site+"/$/frontTop.htm";
    }
  
});
</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <style>
      .tripleColumn {
          border: 1px solid white;
          border-radius:5px;
          padding:5px;
          background-color:#FFFFFF;
          margin:6px
      }
    </style>

    <div style="width:1200px;vertial-align:top;">
       <div class="tripleColumn leafContent">
           <svg height="{{maxLength}}px" width="{{maxWidth}}px">
                <ellipse cx="50" cy="50" rx="21" ry="20" ng-click="ellipse(thisCircle)"
                    style="fill:gray;stroke:gray" ></ellipse>
               <g ng-repeat="child in children">
                   <ellipse ng-attr-cx="{{child.x+4}}" ng-attr-cy="{{child.y+4}}"  ng-click="ellipse(child)"
                       rx="60" ry="30" style="fill:gray;stroke:gray" ></ellipse>
                   <line ng-attr-x1="{{child.x-100}}" ng-attr-y1="{{child.y-50}}" x2="{{child.parx}}" y2="{{child.pary}}" style="stroke:purple;stroke-width:3" ></line>
                   <line ng-attr-x1="{{child.x}}" ng-attr-y1="{{child.y}}" x2="{{child.x-100}}" y2="{{child.y-50}}" style="stroke:purple;stroke-width:3" ></line>
               </g>
               <ellipse cx="50" cy="50" rx="21" ry="20"
                    style="fill:#F0D7F7;stroke:purple;stroke-width:2;cursor:pointer" ></ellipse>
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
    </td>


</div>
