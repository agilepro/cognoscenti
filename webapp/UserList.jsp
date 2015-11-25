<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="java.io.File"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Properties"
%><%@page import="org.w3c.dom.Element"
%><%@page import="org.workcast.json.JSONArray"
%><%@page import="org.workcast.json.JSONObject"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to list users.");
    if (!ar.isSuperAdmin()) {
        throw new Exception("Need to be server administrator to list and edit users");
    }

    JSONArray jUsers = new JSONArray();
    UserProfile profs[] = UserManager.getAllUserProfiles();
    for (UserProfile up : profs) {
        JSONObject userObj = new JSONObject();
        String userName = up.getName();
        userObj.put("name", userName);
        userObj.put("lastLogin", up.getLastLogin());
        userObj.put("key", up.getKey());
        userObj.put("warning", up.getDisabled() || userName==null || userName.length()==0 || up.getPreferredEmail()==null);
        jUsers.put(userObj);
    }

    pageTitle = "Users";
%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" dir="ltr" ng-app="cog">
<head>
<script src="<%=ar.baseURL%>jscript/angular.min.js"></script>
<link rel="stylesheet" href="<%=ar.baseURL%>jscript/bootstrap.min.css"/>

<script>
var app = angular.module('cog', []);
app.controller('cogCtrl', function($scope) {
    $scope.pageTitle = "<% ar.writeJS(pageTitle); %>";
    $scope.users = <% jUsers.write(out, 2, 0); %>;
    $scope.filter = "";

    $scope.filteredUsers = function() {
        var retList = [];
        $scope.users.sort( function(a, b){
            return ( a.lastLogin < b.lastLogin )? 1 : -1 ;
        });
        var length = $scope.users.length;
        var count=0;
        for(var j = 0; j < length; j++) {
            var rec = $scope.users[j];
            if (count<40 && ($scope.filter=="" || rec.name.indexOf($scope.filter) > -1 || rec.key.indexOf($scope.filter) > -1)) {
                retList.push(rec);
                count++;
            }
        }
        return retList;
    }
});
</script>

<%@ include file="ngHead.jsp"%>

<title>{{pageTitle}}</title>

</head>
<body ng-controller="cogCtrl">
<%@ include file="ngTop.jsp"%>

<div class="section">
  <div class="section_title">
    <h4 class="left">List of Users</h4>
    <div class="section_date right"></div>
    <div class="clearer">&nbsp;</div>
  </div>

  <div class="section_body">
    <div id="listofpagesdiv">
    <p>Filter by <input type="text" ng-model="filter"> show 40 records, sorted by last login</p>
    <table id="pagelist" class="table">
        <thead>
            <tr>
                <th>User Name</th>
                <th>Last Login</th>
                <th>Key</th>
            </tr>
        </thead>
        <tbody>

        <tr ng-repeat="user in filteredUsers()">
            <td>{{user.name}}
                <span ng-show="warning">
                    <a href="<%=ar.retPath%>UserProfile.jsp?u={{user.key}}" title="see warnings"><img src="warning.gif"></a>
                </span>
            </td>
            <td> {{user.lastLogin| date:'yyyy-MM-dd HH:mm'}} </td>
            <td> <a href="<%=ar.retPath%>UserProfile.jsp?u={{user.key}}"
                   title="navigate to the profile for this user">{{user.key}}</a>
            </td>
        </tr>

                    </tbody>
                </table>
            </div>
        </div>
    </div>

<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>
