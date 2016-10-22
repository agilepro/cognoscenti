<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.License"
%><%@page import="org.socialbiz.cog.WorkspaceStats"
%><%@page import="org.socialbiz.cog.util.NameCounter"
%><%@ include file="/spring/jsp/include.jsp"
%><% 

    ar.assertLoggedIn("");
    String accountId = ar.reqParam("accountId");
    NGBook  ngb = ar.getCogInstance().getSiteByIdOrFail(accountId);
    JSONObject siteInfo = ngb.getConfigJSON();

    WorkspaceStats wStats = ngb.getRecentStats(ar.getCogInstance());

    JSONArray allThemes = new JSONArray();
    for(String themeName : ngb.getAllThemes(ar.getCogInstance())) {
        allThemes.put(themeName);
    }
 
%> 

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.siteInfo = <%siteInfo.write(out,2,4);%>;
    $scope.allThemes = <%allThemes.write(out,2,4);%>;
    $scope.newName = $scope.siteInfo.names[0];

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    
    $scope.removeName = function(oldName) {
        $scope.siteInfo.names = $scope.siteInfo.names.filter( function(item) {
            return (item!=oldName);
        });
    }
    $scope.addName = function(newName) {
        $scope.removeName(newName);
        $scope.siteInfo.names.splice(0, 0, newName);
    }
    
    $scope.saveSiteInfo = function() {
        if ($scope.siteInfo.names.length===0) {
            alert("Site must have at least one name at all times.  Please add a name.");
            return;
        }
        var postURL = "updateSiteInfo.json";
        var postdata = angular.toJson($scope.siteInfo);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.siteInfo = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Site Administration
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" 
                  href="roleRequest.htm">Role Requests</a></li>
              <li role="presentation"><a role="menuitem" 
                  href="SiteUsers.htm">User Migration</a></li>
            </ul>
          </span>

        </div>
    </div>


    <div class="generalContent">
         <table>
            <tr>
                <td class="gridTableColummHeader_2">New Name:</td>
                <td style="width:20px;"></td>
                <td class="form-inline">
                    <input type="text" class="form-control" ng-model="newName">
                    <button ng-click="addName(newName)" class="btn btn-primary btn-raised">Add Name</button>
                </td>
            </tr>
            <tr><td height="10px"></td></tr>
            <tr>
                <td class="gridTableColummHeader_2" valign="top">Current Names:</td>
                <td style="width:20px;"></td>
                <td>
                    <div ng-repeat="name in siteInfo.names">
                        {{name}}
                        <img src="<%=ar.retPath%>/assets/iconDelete.gif" ng-click="removeName(name)">
                    </div>
                </td>
            </tr>
            <tr><td height="5px"></td></tr>
            <tr>
                <td class="gridTableColummHeader_2" valign="top">Site Description:</td>
                <td style="width:20px;"></td>
                <td>
                    <textarea  class="form-control" rows="4" ng-model="siteInfo.description"></textarea>
                </td>
            </tr>
            <tr><td height="30px"></td></tr>
            <tr>
                <td class="gridTableColummHeader_2">Flags:</td>
                <td style="width:20px;"></td>
                <td><input type="checkbox" ng-model="siteInfo.showExperimental"> Show Experimental,  
                    <input type="checkbox" ng-model="siteInfo.allowPrivate"> Allow Private</td>
            </tr>
            <tr><td height="10px"></td></tr>
            <tr>
                <td class="gridTableColummHeader_2"></td>
                <td style="width:20px;"></td>
                <td><button class="btn btn-primary btn-raised" ng-click="saveSiteInfo()">Save Changes</button></td>
            </tr>
            <tr><td height="10px"></td></tr>
            <tr>
                <td class="gridTableColummHeader_2">Site Key:</td>
                <td style="width:20px;"></td>
                <td>{{siteInfo.key}}</td>
            </tr>
            <tr><td height="10px"></td></tr>
            <tr>
                <td class="gridTableColummHeader_2">Storage Path:</td>
                <td style="width:20px;"></td>
                <td>
                {{siteInfo.rootfolder}}
                </td>
            </tr>
            <tr>
                <td class="gridTableColummHeader_2">Streaming Link:</td>
                <td style="width:20px;"></td>
                <td><%
                    License lic = null;
                    for (License test : ngb.getLicenses()) {
                        //just find any one license that is still valid
                        if (ar.nowTime < test.getTimeout()) {
                            lic = test;
                        }
                    }
                    //ok ... since at this time there is no UI for creating licenses
                    //in order to test, we just create a license on the fly here, and
                    //also save the workspace, which is not exactly proper.
                    //TODO: clean this up
                    if (lic==null) {
                        lic = ngb.createLicense(ar.getBestUserId(), "Owners", ar.nowTime+(1000*60*60*24*365), false);
                        ngb.saveFile(ar, "Created license on the fly for testing purposes");
                    }
                    String link = ar.baseURL + "api/" + ngb.getKey() + "/$/summary.json?lic="+lic.getId();
                    ar.writeHtml(link);
                    %>
                </td>
            </tr>
        </table>
    </div>


    <div class="generalContent">
        <div class="generalHeading paddingTop">Statistics</div>
        <table class="table">
        <tr>
           <td>Number of Topics:</td>
           <td><%=wStats.numTopics%></td>
        </tr>
        <tr>
           <td>Number of Meetings:</td>
           <td><%=wStats.numMeetings%></td>
        </tr>
        <tr>
           <td>Number of Decisions:</td>
           <td><%=wStats.numDecisions%></td>
        </tr>
        <tr>
           <td>Number of Comments:</td>
           <td><%=wStats.numComments%></td>
        </tr>
        <tr>
           <td>Number of Proposals:</td>
           <td><%=wStats.numProposals%></td>
        </tr>
        <tr>
           <td>Number of Documents:</td>
           <td><%=wStats.numDocs%></td>
        </tr>
        <tr>
           <td>Size of Documents:</td>
           <td>{{<%=wStats.sizeDocuments%>|number}}</td>
        </tr>
        <tr>
           <td>Number of Old Versions:</td>
           <td>{{<%=wStats.sizeArchives%>|number}}</td>
        </tr>
        <tr>
           <td>Topics:</td>
           <td><% outputStatTable(ar, wStats.topicsPerUser, "Topics"); %></td>
        </tr>
        <tr>
           <td>Documents:</td>
           <td><% outputStatTable(ar, wStats.docsPerUser, "Documents"); %></td>
        </tr>
        <tr>
           <td>Comments:</td>
           <td><% outputStatTable(ar, wStats.commentsPerUser, "Comments"); %></td>
        </tr>
        <tr>
           <td>Meetings:</td>
           <td><% outputStatTable(ar, wStats.meetingsPerUser, "Meetings"); %></td>
        </tr>
        <tr>
           <td>Proposals:</td>
           <td><% outputStatTable(ar, wStats.proposalsPerUser, "Proposals"); %></td>
        </tr>
        <tr>
           <td>Responses:</td>
           <td><% outputStatTable(ar, wStats.responsesPerUser, "Responses"); %></td>
        </tr>
        <tr>
           <td>Unresponded:</td>
           <td><% outputStatTable(ar, wStats.unrespondedPerUser, "Unresponded"); %></td>
        </tr>
        </table>
    </div>
</div>

<%!
    private void outputStatTable(AuthRequest ar, NameCounter counter, String group) throws Exception  {
        ar.write("\n<table>");
        List<String> keys = counter.getSortedKeys();
        for (String key : keys) {
            ar.write("\n  <tr><td style=\"text-align:right;\">");
            ar.writeHtml(key);
            ar.write(" </td><td>: ");
            ar.write(counter.get(key).toString());
            ar.write("</td></tr>");
        }
        ar.write("\n</table>");
    }
%>