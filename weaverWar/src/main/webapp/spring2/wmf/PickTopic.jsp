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

    $scope.topicFilter = "";
    $scope.topics = [];

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
    
    $scope.filteredTopics = function() {
        let res = [];
        $scope.topics.forEach( function(item) {
            if (item.subject.indexOf($scope.topicFilter) >= 0 ) {
                res.push(item);
            }
        } );
        return res;
    }
});

</script>


<div>

    
    <div class="topper">
    <%=ngw.getFullName()%>
    </div>
    
    <div class="instruction ms-3">
    Filter Topics: <input ng-model="topicFilter"></input>
    </div>
    
    <div ng-repeat="topic in filteredTopics()" class="my-3 border border-1 border-dark rounded btn-raised" >
      <div class="listItemStyle">
        <a class="fs-6 bold text-wrap text-decoration-none ms-2" href="TopicView.wmf?topicId={{topic.id}}">
            <span class="fa fa-lightbulb-o"></span> {{topic.subject}}
        </a>
      </div>
    </div>
    



