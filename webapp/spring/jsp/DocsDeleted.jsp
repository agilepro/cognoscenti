<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%


    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();

    JSONArray attachments = new JSONArray();

    UserProfile up = ar.getUserProfile();

    for (AttachmentRecord aDoc : ngp.getAllAttachments()) {
        if (!aDoc.isDeleted()) {
            continue; //skip all but deleted
        }
        attachments.put( aDoc.getJSON4Doc(ar, ngp) );
    }

%>


<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Deleted Documents");
    $scope.atts = <%attachments.write(out,2,4);%>;
    $scope.filter = "";

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        var exception = serverErr.exception;
        $scope.errorMsg = exception.join();
        $scope.errorTrace = exception.stack;
        $scope.showError=true;
        $scope.showTrace = false;
    };

    $scope.trimName = function(name) {
        if (name.length>34) {
            var pos = name.lastIndexOf(".");
            if (pos>30) {
                return name.substring(0,30)+".."+name.substring(pos);
            }
            return name.substring(0,34);
        }
        return name;
    }
    $scope.removeEntry = function(searchId) {
        var res = [];
        for (var i=0; i<$scope.atts; i++) {
            var rec = $scope.atts[i];
            if (searchId!=rec.id) {
                res.push(rec);
            }
        }
        //$scope.atts = res;
    }
    $scope.getRows = function() {
        var lcfilter = $scope.filter.toLowerCase();
        var res = [];
        var last = $scope.atts.length;
        for (var i=0; i<last; i++) {
            var rec = $scope.atts[i];
            if (rec.name.toLowerCase().indexOf(lcfilter)>=0) {
                res.push(rec);
            }
            else if (rec.description.toLowerCase().indexOf(lcfilter)>=0) {
                res.push(rec);
            }
        }
        return res;
    }
    $scope.undeleteDoc = function(rec) {
        rec.deleted = false;
        var postURL = "docsUpdate.json?did="+rec.id;
        var postdata = angular.toJson(rec);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.removeEntry(rec.id);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

});

</script>

<div class="content tab03" style="display:block;" ng-app="myApp" ng-controller="myCtrl">
    <div class="section_body">
        <div style="height:10px;"></div>

        <div id="ErrorPanel" style="border:2px solid red;display=none;background:LightYellow;margin:10px;" ng-show="showError" ng-cloak>
            <div class="generalSettings">
                <table>
                    <tr>
                        <td class="gridTableColummHeader">Error:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">{{errorMsg}}</td>
                    </tr>
                    <tr ng-show="showTrace">
                        <td class="gridTableColummHeader">Trace:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">{{errorTrace}}</td>
                    </tr>
                    <tr ng-hide="showTrace">
                        <td class="gridTableColummHeader">Trace:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2"><button ng-click="showTrace=true">Show The Trace</button></td>
                    </tr>
                </table>
            </div>
        </div>

        <div class="generalHeading">Deleted Documents</div>
        <div>Filter <input ng-model="filter"></div>

        <div style="height:20px;"></div>

        <table class="gridTable2" width="100%">
            <tr class="gridTableHeader">
                <td width="50px"></td>
                <td width="220px">Document Name</td>
                <td width="80px">Date</td>
                <td width="80px"></td>
                <td width="220px">Description</td>
            </tr>
            <tr ng-repeat="rec in getRows()">
                <td>
                  <div class="dropdown">
                    <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                    <span class="caret"></span></button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                      <li role="presentation">
                          <a role="menuitem" tabindex="-1" href="docinfo{{rec.id}}.htm">Access Document</a></li>
                      <li role="presentation">
                          <a role="menuitem" tabindex="-1" href="editDetails{{rec.id}}.htm">Edit Document Details</a></li>
                      <li role="presentation">
                          <a role="menuitem" tabindex="-1" href="fileVersions.htm?aid={{rec.id}}">List Versions</a></li>
                      <li role="presentation" class="divider"></li>
                      <li role="presentation">
                          <a role="menuitem" tabindex="-1" ng-click="undeleteDoc(rec)">Undelete Document</a></li>
                    </ul>
                  </div>
                </td>
                <td><b><a href="docinfo{{rec.id}}.htm" title="{{rec.name}}">{{trimName(rec.name)}}</a></b></td>
                <td>{{rec.modifiedtime|date}}</td>
                <td>
                    <a href="editDetails{{rec.id}}.htm">
                        <span ng-show="rec.deleted"><i class="fa fa-trash"></i></span>
                        <span ng-show="rec.upstream"><img src="<%=ar.retPath%>assets/images/iconUpstream.png"></span>
                        <span ng-show="rec.attType=='FILE'"><img src="<%=ar.retPath%>assets/images/iconFile.png"></span>
                        <span ng-show="rec.attType=='URL'"><img src="<%=ar.retPath%>assets/images/iconUrl.png"></span>
                    </a>
                </td>
                <td>{{rec.description}}</td>            </tr>
        </table>
    </div>
</div>




