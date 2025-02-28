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

    $scope.sortTopics = function() {
        $scope.topics.sort( function(a,b) {
            return b.modTime - a.modTime;
        });
    }
    $scope.fetchTopics = function(rec) {
        var postURL = "getTopics.json"
        var postdata = angular.toJson(rec);
        $scope.showError=false;
        $http.get(postURL, postdata)
        .success( function(data) {
            console.log("GOT: ", data);
            $scope.topics = data;
            $scope.sortTopics();
            $scope.initialFetchDone = true;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.fetchTopics();

});

</script>


<div>

    
    <div class="topper">
    <%=ngw.getFullName()%>
    </div>
    
    <div class="instruction">
    Choose a dicsussion topic from list below:
    </div>
    
    <div ng-repeat="topic in topics" style="margin:10px;" >
      <div class="listItemStyle">
        <a href="TopicView.wmf?topicId={{topic.id}}">
            <span class="fa fa-lightbulb-o"></span> {{topic.subject}}
        </a>
      </div>
    </div>
    
    
    <!-- Begin Template Footer -->
    <jsp:include page="WMFFooter.jsp" />
    <!-- End Template Footer -->
</div>



