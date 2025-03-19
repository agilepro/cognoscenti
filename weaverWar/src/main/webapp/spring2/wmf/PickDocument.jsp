<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%
    String pageId    = ar.reqParam("pageId");
    String siteId    = ar.reqParam("siteId");
    NGWorkspace ngw  = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
   

%>

<!-- ************************ wmf/{PickMeetomg/jsp ************************ -->
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {

    $scope.sortDocs = function() {
        $scope.atts.sort( function(a,b) {
            return (b.modifiedtime - a.modifiedtime);
        });
    }
    $scope.setDocumentData = function(data) {
        $scope.atts = data.docs;
        $scope.sortDocs();
    }
    $scope.getDocumentList = function() {
        $scope.isUpdating = true;
        let postURL = "docsList.json";
        $http.get(postURL)
        .success( function(data) {
            $scope.setDocumentData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
        
    }
    $scope.getDocumentList();

});

</script>


<div>

    
    <div class="topper">
    <%=ngw.getFullName()%>
    </div>
    
    <div class="instruction  ms-3">
    Select a document:
    </div>
    
    <div ng-repeat="doc in atts" class="my-3 border border-1 border-dark rounded btn-raised">
      <div class="listItemStyle">
        <a class="fs-6 bold text-wrap text-decoration-none ms-2" href="DocView.wmf?docId={{doc.id}}">
            <span class="fa fa-file-o"></span> {{doc.name}}
        </a>
      </div>
    </div>




