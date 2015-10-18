<%@page errorPage="/spring/jsp/error.jsp"
%><%@include file="include.jsp"
%><%@page import="org.socialbiz.cog.IDRecord"
%><%@page import="org.socialbiz.cog.ConfigFile"
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

    JSONObject userInfo = uProf.getJSON();
    userInfo.put("key", uProf.getKey());
    userInfo.put("notificationPeriod", uProf.getNotificationPeriod());

    String key = uProf.getKey();
    String name = uProf.getName();
    String desc = uProf.getDescription();

    String photoSrc = ar.retPath+"assets/photoThumbnail.gif";
    if(uProf.getImage().length() > 0){
        photoSrc = ar.retPath+"users/"+uProf.getImage();
    }

    String autoLoginCookie = ar.findCookieValue("autoLoginCookie");
    String openIdCookie = ar.findCookieValue("openIdCookie");

    String thisPage = ar.getCompleteURL();
    String prefEmail = uProf.getPreferredEmail();
    if (prefEmail==null) {
        prefEmail = "-none-";
    }
    String remoteProfileURL = ar.baseURL+"apu/"+uProf.getKey()+"/user.json?lic="+uProf.getLicenseToken();

%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.userInfo = <%userInfo.write(out,2,4);%>;

    $scope.editAgent=false;
    $scope.newAgent = {};

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
});
</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Personal Settings for {{userInfo.name}}
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1" href="editUserProfile.htm?u={{userInfo.key}}" >
                        <img src="<%=ar.retPath%>assets/iconEditProfile.gif"/>
                        Update Settings</a></li>
          </span>

        </div>
    </div>

    <div style="height:10px;"></div>

        <div class="generalArea">
            <div class="generalSettings">
                <table border="0px solid red" class="popups">
                    <tr>
                        <td width="148" class="gridTableColummHeader">Name:</td>
                        <td width="39" style="width:20px;"></td>
                        <td>{{userInfo.name}}</td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>

                    <tr>
                        <td width="148" class="gridTableColummHeader">Icon:</td>
                        <td width="39" style="width:20px;"></td>
                        <td><img src="<%ar.writeHtml(photoSrc);%>" width="50" height="50"/></td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>

                    <tr>
                        <td class="gridTableColummHeader">Description:</td>
                        <td style="width:20px;"></td>
                        <td><% ar.writeHtml(desc);%></td>
                    </tr>
<% //above this is public, below this only for people logged in
if (ar.isLoggedIn()) { %>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader">Preferred Email:</td>
                        <td style="width:20px;"></td>
                        <td><%
                            ar.writeHtml(prefEmail);
                            %></td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader" valign="top">Alternate Email:</td>
                        <td style="width:20px;"></td>
                        <td valign="top">
                            <table>
                                <%
                                for (IDRecord anid : uProf.getIdList())
                                {
                                    if ((anid.isEmail()) && (!anid.getLoginId().equals(prefEmail)))
                                    {
                                    %>
                                        <tr><td><%
                                        ar.writeHtml(anid.getLoginId());
                                        %></td></tr>
                                    <%
                                    }
                                }
                                %>
                            </table>
                        </td>
                    </tr>
                    <tr><td style="height:15px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader">Last Login:</td>
                        <td style="width:20px;"></td>
                        <td><%SectionUtil.nicePrintTime(ar.w, uProf.getLastLogin(), ar.nowTime); %> as <% ar.writeHtml(uProf.getLastLoginId()); %> </td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader">Notification Period:</td>
                        <td style="width:20px;"></td>
                        <td>{{userInfo.notificationPeriod}} days</td>
                    </tr>
            <%if (viewingSelf){ %>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader">Remote URL:</td>
                        <td style="width:20px;"></td>
                        <td><a href="<%=remoteProfileURL%>"><%=remoteProfileURL%></a></td>
                    </tr>
           <% } %>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader">User Key:</td>
                        <td style="width:20px;"></td>
                        <td><% ar.writeHtml(key);%></td>
                    </tr>
            <%if (viewingSelf){ %>
                    <tr>
                        <td class="gridTableColummHeader">API Token:</td>
                        <td style="width:20px;"></td>
                        <td><% ar.writeHtml(uProf.getLicenseToken());%></td>
                    </tr>
            <% } %>
    <%} %>
                </table>
            </div>
        </div>

</div>
