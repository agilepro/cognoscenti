<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="include.jsp"
%><%@page import="java.io.StringWriter"
%><%@page import="org.socialbiz.cog.AuthDummy"
%><%

    ar.assertLoggedIn("Must be logged in to see anything about a user");

    UserProfile uProf = (UserProfile)request.getAttribute("userProfile");
    if (uProf == null) {
        throw new NGException("nugen.exception.cant.find.user",null);
    }

    UserProfile  operatingUser =ar.getUserProfile();
    if (operatingUser==null) {
        //this should never happen, and if it does it is not the users fault
        throw new ProgramLogicError("user profile setting is null.  No one appears to be logged in.");
    }

    boolean viewingSelf = uProf.getKey().equals(operatingUser.getKey());


    JSONArray contacts = new JSONArray();
    List <AddressListEntry> existingContacts = ar.getUserPage().getExistingContacts();
    for (AddressListEntry ale : existingContacts) {
        contacts.put(ale.getJSON());
    }

    List<AddressListEntry> youMayKnowList = ar.getUserPage().getPeopleYouMayKnowList();
    JSONArray youMayKnow = new JSONArray();
    for (AddressListEntry ale : youMayKnowList) {
        youMayKnow.put(ale.getJSON());
    }


%>
<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.contacts = <%contacts.write(out,2,4);%>;
    $scope.youMayKnow = <%youMayKnow.write(out,2,4);%>;



    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };


});
</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Contacts
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="" ng-click="">Do Nothing</a></li>
            </ul>
          </span>

        </div>
    </div>


    <table class="table">
        <tr>
            <th>Name</th>
            <th>Email Id</th>
        </tr>

        <tr ng-repeat="row in contacts">
            <td>{{row.name}}</td>
            <td>{{row.uid}}</td>
        </tr>

    </table>

    <div class="generalHeading" style="height:40px">
        People You May Know
    </div>

    <table class="table">
        <tr>
            <th>Name</th>
            <th>Email Id</th>
        </tr>

        <tr ng-repeat="row in youMayKnow">
            <td>{{row.name}}</td>
            <td>{{row.uid}}</td>
        </tr>

    </table>