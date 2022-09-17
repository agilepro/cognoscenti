<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.SharePortRecord"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId   : This is the id of a workspace and here it is used to retrieve NGWorkspace.

*/

    String id      = ar.reqParam("id");
    String pageId  = ar.reqParam("pageId");
    String siteId  = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);

    JSONArray allLabels = ngw.getJSONLabels();
    SharePortRecord spr = ngw.findSharePortOrFail(id);
    JSONObject sharePort = spr.getFullJSON(ngw);
    
    long startTime = sharePort.getLong("startTime");
    long days = sharePort.getInt("days");
    long endTime = startTime + (days * 24L * 60L * 60L * 1000L);
    boolean isActive = true;
    if (sharePort.has("isActive")) {
        isActive = sharePort.getBoolean("isActive");
    }
    
%>


<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    $scope.sharePort = <%sharePort.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.nowTime = new Date().getTime();
    
    $scope.acessDocument = function (doc) {
        if (doc.attType=="URL") {
            window.open(doc.url,'_blank');
        }
        else {
            window.location = "../a/"+encodeURI(doc.name)+"?"+doc.access;
        }
    }
    
});
</script>

      
<style>
.dateColumn {
    min-width:100px;
}
tr:hover {
    background-color: #EEE;
}
</style>

  
<div ng-app="myApp" ng-controller="myCtrl">

    <div class="page-name">
        <h1 id="mainPageTitle">{{sharePort.name}}</h1>
    </div>

    <div ng-show="sharePort.isActive && sharePort.endTime>nowTime">
        <p>{{sharePort.message}}</p>
        
        <div style="margin:40px"> </div>
        
        <table class="table">
        <col width="50">
        <tr>
           <th></th>
           <th>Name</th>
           <th class="dateColumn">Updated</th>
           <th style="text-align:right">Size</th>
        </tr>
        <tr ng-repeat="rec in sharePort.docs" ng-click="acessDocument(rec)" style="cursor:pointer" title="Click to access document">
           <td ng-hide="rec.url" >
             <span class="fa fa-download"></scan></td>
           <td ng-show="rec.url" >
             <span class="fa fa-external-link"></scan></td>
           <td><b>{{rec.name}}</b> ~ {{rec.description}}</td>
           <td class="dateColumn">{{rec.modifiedtime|date}}</td>
           <td ng-show="rec.size>=0" style="text-align:right">{{rec.size|number}}</td>
           <td ng-hide="rec.size>=0" style="text-align:right;color:lightgray">Web Link</td>
        </tr>
        <tr><td></td><td></td><td></td></tr>
        </table>

        <div ng-show="sharePort.docs.length==0" class="guideVocal">
           There are no documents that match the filter criteria at this time.
        </div>
        
        <p ng-show="sharePort.days>0">
           This sharing page will be available until {{sharePort.endTime|date}}.
        </p>
    </div>
    
   <div ng-show="sharePort.isActive && sharePort.endTime<=nowTime">
   
        <div ng-show="sharePort.docs.length==0" class="guideVocal">
           This is no longer available since {{sharePort.endTime|date}}.
        </div>
   
   </div>
    
   <div ng-show="!sharePort.isActive">
   
        <div ng-show="sharePort.docs.length==0" class="guideVocal">
           This sharing page has been disabled by the user and is no longer available.
        </div>
   
   </div>
    
</div>