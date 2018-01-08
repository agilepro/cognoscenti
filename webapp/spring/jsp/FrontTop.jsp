<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId : This is the id of a Workspace and here it is used to retrieve NGPage.

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
    if (parentIndex!=null) {
        throw new Exception("this is quite strange ... this page is not supposed to have a parent.");
    }

    JSONArray children = new JSONArray();
    for (NGPageIndex ngpi : cog.getAllContainers()) {
        if (!ngpi.isProject()) {
            continue;
        }
        if (!siteKey.equals(ngpi.wsSiteKey)) {
            continue;
        }
        if (ngpi.parentKey==null || ngpi.parentKey.length()==0) {
            JSONObject jo = new JSONObject();
            jo.put("name", ngpi.containerName);
            jo.put("key",  ngpi.containerKey);
            jo.put("site", ngpi.wsSiteKey);
            children.put(jo);
        }
    }

    UserProfile uProf = ar.getUserProfile();

%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Top Level Workspaces");
    $scope.children   = <%children.write(out,2,4);%>;
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

    <table><tr style="vertical-align:top;">
    <td style="width:350px;vertial-align:top;">
       <div class="tripleColumn leafContent">
       </div>
    </td>
    <td style="width:350px;vertial-align:top;">
       <div class="tripleColumn leafContent">
           <svg height="{{maxLength}}px" width="350px">
                <ellipse cx="179" cy="179" rx="21" ry="20" ng-click="ellipse(thisCircle)"
                    style="fill:gray;stroke:gray" ></ellipse>
               <g ng-repeat="child in children">
                   <ellipse ng-attr-cx="{{child.x+4}}" ng-attr-cy="{{child.y+4}}"  ng-click="ellipse(child)"
                       rx="60" ry="30" style="fill:gray;stroke:gray" ></ellipse>
                   <line ng-attr-x1="{{child.x+2}}" ng-attr-y1="{{child.y}}" x2="177" y2="175" style="stroke:purple;stroke-width:2" ></line>
                   <line ng-attr-x1="{{child.x-2}}" ng-attr-y1="{{child.y}}" x2="173" y2="175" style="stroke:purple;stroke-width:2" ></line>
               </g>
               <ellipse cx="175" cy="175" rx="21" ry="20"
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
    <td style="width:350px;vertial-align:top;">
       <div class="tripleColumn leafContent">
       </div>
    </td>
    </tr></table>


</div>
