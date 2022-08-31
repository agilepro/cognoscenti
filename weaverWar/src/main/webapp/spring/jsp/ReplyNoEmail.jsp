<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="com.purplehillsbooks.weaver.SharePortRecord"
%><%@page import="com.purplehillsbooks.weaver.AccessControl"
%><%@page import="com.purplehillsbooks.weaver.CommentContainer"
%><%@page import="com.purplehillsbooks.weaver.AgendaItem"
%><%@page import="com.purplehillsbooks.weaver.CommentRecord"
%><%@page import="com.purplehillsbooks.weaver.EmailContext"
%><%@ include file="/spring/jsp/include.jsp"
%><%

%>

<!-- ************************ xxx/Reply.jsp ************************ -->
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Reply, No Email");

});

</script>


<div class="bodyWrapper"  style="margin:50px">


<style>
.spacey tr td {
    padding: 5px 5px;
}

</style>


<div style="max-width:800px">
    
    <div class="comment-outer comment-state-active">
      <div class="comment-inner">
        <div>It looks as though you are trying to reply to an email message
             that has not yet been sent.</div>
        <div>The Reply links should work well once the email has actually
             been sent.</div>
      </div>
    </div>

</div>
  
