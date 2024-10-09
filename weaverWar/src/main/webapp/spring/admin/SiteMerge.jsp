<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.AccessControl"
%><%@page import="com.purplehillsbooks.weaver.SiteMailGenerator"
%><%@page import="com.purplehillsbooks.weaver.mail.ChunkTemplate"
%><%@page import="java.util.HashSet"
%><%

    String siteId = ar.reqParam("siteId");
    NGBook ngb = ar.getCogInstance().getSiteByIdOrFail(siteId);
    ar.setPageAccessLevels(ngb);

    List<File> allLayouts = NGBook.getAllLayouts(ar);
    JSONArray layoutList = new JSONArray();

    String layoutName = ar.defParam("layout", "SiteIntro1.chtml");
    File layoutFile = NGBook.findSiteLayout(ar,layoutName);
    
    JSONObject allMail = ngb.getSiteDripContent(ar);

    JSONObject siteJSON = ngb.getConfigJSON();
    JSONArray projList = new JSONArray();
    for (NGPageIndex ngpi : ar.getCogInstance().getNonDelWorkspacesInSite(siteId)) {
        if (!ngpi.isWorkspace()) {
            continue;
        }
        projList.put(ngpi.getJSON4List());
    }
    siteJSON.put("workspaces", projList);
    siteJSON.put("stats", ngb.getStatsJSON(ar.getCogInstance()));
    JSONObject mergeable = new JSONObject();
    mergeable.put("site", siteJSON);
    mergeable.put("baseUrl", ar.baseURL);
    
    JSONArray pastSendings = new JSONArray();
    for (SiteMailGenerator smg : ngb.getAllSiteMail()) {
        pastSendings.put(smg.getJSON());
    }
    
    List<AddressListEntry> collector = new ArrayList<AddressListEntry>();
    NGRole prime = ngb.getPrimaryRole();
    for (AddressListEntry ale : prime.getExpandedPlayers(ngb)) {
        AddressListEntry.addIfNotPresent(collector, ale);
    }
    NGRole second = ngb.getSecondaryRole();
    for (AddressListEntry ale : second.getExpandedPlayers(ngb)) {
        AddressListEntry.addIfNotPresent(collector, ale);
    }
    JSONArray affected = new JSONArray();
    for (AddressListEntry ale : collector) {
        affected.put( ale.getJSON() );
    }
    

    %>
    <style>
    .wellstyle {
        background-color: #fff;
        padding: 19px;
        margin-bottom: 20px;
        -webkit-box-shadow: 0 8px 17px 0 rgba(0,0,0,.2),0 6px 20px 0 rgba(0,0,0,.19);
        box-shadow: 0 8px 17px 0 rgba(0,0,0,.2),0 6px 20px 0 rgba(0,0,0,.19);
        border-radius: 2px;
        border: 0;
        max-width:650px;
    }
    </style>
<script>
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    
    $scope.pastSendings = <% pastSendings.write(out,2,4);%>;
    $scope.selectedLayout  = "<% ar.writeJS(layoutName);%>";
    $scope.data = <% mergeable.write(out,2,4);%>;
    $scope.browserZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    $scope.addressees = <% affected.write(out,2,4); %>;
    $scope.allMail = <% allMail.write(out,2,4); %>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        console.log("ERROR", serverErr)
        //errorPanelHandler($scope, serverErr);
    };
    $scope.sendIt = function() {
        var site = $scope.data.site;
        var postObj = {};
        postObj.layout = $scope.selectedLayout;
        postObj.subject = "Mail about your Weaver Site: "+site.names[0];
        var postData = angular.toJson(postObj);
        var postURL = "<% ar.writeJS(ar.baseURL); %>t/"+site.key+"/$/SiteMail.json";
        console.log("POST to: ",postURL)
        $scope.showError=false;
        $http.post(postURL, postData)
        .success( function(data) {
            $scope.pastSendings.push(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }

});

</script>
<div ng-app="myApp" ng-controller="myCtrl">

    <table class="table">
        
      <tr ng-repeat="drip in allMail.list">
        <td>{{drip.name}}</td>
        <td><a href="SiteMerge.htm?site=<% ar.writeURLData(siteId); %>&layout={{drip.name}}">LINK</a></td>
        <td></td>
      </tr>
    </table>
    
    <pre>
    {{allMail.list}}
    </pre>
    <div class="form-horizontal">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu2" data-toggle="dropdown" 
                title="Choose the layout to display with">
        <span class="fa fa-diamond"></span>&nbsp;<span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
        <% for (File temName: allLayouts) { %>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              title="Opens or closes all of the agenda items for the meeting"
              href="SiteMerge.htm?site=<% ar.writeURLData(siteId); %>&layout=<% ar.writeURLData(temName.getName()); %>" >
                  <span class="fa fa-diamond"></span>&nbsp;
                  <% ar.writeHtml(conditionFileName(temName.getName())); %></a></li>
        <% } %>
        </ul>
      </span>
    <button class="btn btn-primary" ng-click="sendIt()">Send It Now</button>
    <span><b><% ar.writeHtml(layoutName); %></b></span>
    <div style="clear:both;padding:5px"></div>
    </div>
    <div class="wellstyle">
    <% ChunkTemplate.streamIt(ar.w, layoutFile,   mergeable, ar.getUserProfile().getCalendar() ); %>
    </div>

    <table class="table">
    <tr>
    <td>Owners / Executives</td>
    <td>
        <div ng-repeat="addr in addressees">{{addr.name}}</div>
    </td>
    </tr>
    </table>

    <table class="table">
    <tr ng-repeat="mail in pastSendings">
        <td>{{mail.layout}}</td>
        <td>{{mail.subject}}</td>
        <td ng-show="mail.sendDate>0">{{mail.sendDate | date:"dd-MMM-yyyy   HH:mm"}} ({{browserZone}})</td>
        <td ng-hide="mail.sendDate>0">Not Sent Yet</td>
    </tr>
    </table>
</div>
<%!
/**
* convert XxxYyyZzz.chmtl
*    into Xxx Yyy Zzz
*/
public String conditionFileName(String fileName) {
    if (!fileName.endsWith("chtml")) {
        return fileName;
    }
    StringBuilder sb = new StringBuilder();
    sb.append(fileName.charAt(0));
    for (int i=1; i<fileName.length()-6; i++) {
        char ch = fileName.charAt(i);
        if (ch>='A' && ch<='Z') {
            sb.append(' ');
        }
        sb.append(ch);
    }
    return sb.toString();
}

%>
