<%@ page language="java" contentType="text/html;charset=UTF-8" pageEncoding="UTF-8"
%><%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.capture.CapturePage"
%><%@page import="com.purplehillsbooks.streams.NullWriter"
%><%@page import="com.purplehillsbooks.weaver.capture.WebFile"
%><%
    ar.assertLoggedIn("You need to Login to Upload a file.");
    String attachmentId = ar.reqParam("att");
    String capture = ar.defParam("capture", "n");
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    
    AttachmentRecord att = ngw.findAttachmentByIDOrFail(attachmentId);
    WebFile wf = att.getWebFile();
    if ("y".equals(capture)) {
        wf.refreshFromWeb();
    }
    JSONObject wfjson = wf.getJson();
    boolean available = false;
    if (wfjson.has("articles")) {
        JSONArray articles = wfjson.getJSONArray("articles");
        available = articles.length()>0;
    }
%>

<script>
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Web Capture");
    $scope.webFile = <% wfjson.write(out,2,4); %>;
    $scope.isAvailable = <%= available %>;
    $scope.originalUrl = "<% ar.writeJS(att.getURLValue()); %>";

    $scope.openOriginal = function() {
        window.open($scope.originalUrl, "_blank");
    }
    $scope.download = function() {
        window.location="ShowWebFile.htm?att=<%=attachmentId%>&capture=y";
    }
    $scope.sharable = function() {
        window.location="WebFilePrint.htm?aid=<%=attachmentId%>";
    }
});
</script>
<style>
.cleanedWebStyle {
}
.cleanTitleBox{
    border:2px gray solid;
    border-radius:5px;
    margin:0px;
    padding:8px
}
.segmentBox{
    border:2px gray solid;
    border-radius:15px;
    margin:0px;
    padding:8px;
    max-width: 600px;
}

</style>

<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

    <div class="cleanedWebStyle">
    
        <button class="btn btn-default btn-raised" ng-click="openOriginal()">Open Original</button>
        <button class="btn btn-default btn-raised" ng-click="download()">Refresh from Web</button>
        <button class="btn btn-default btn-raised" ng-click="sharable()">Sharable View</button>
        <table class="table">
            <tr ng-repeat="art in webFile.articles" >
            
                <td style="max-width: 600px"><div ng-bind-html="art.content|wiki" class="segmentBox"></div></td>
                <td>§{{art.originPos}}<br/><button>edit</button></td>
            </tr>
            <hr/>
            <hr/>
            <tr ng-repeat="art in webFile.links" >
                <td style="max-width: 600px"><div ng-bind-html="art.content|wiki" class="segmentBox"></div></td>
            </tr>
        </table>
        
        <div ng-hide="isAvailable">
           <div class="guideVocal">
               <p>There does not seem to be a downloaded copy yet.</p>
               <p>Use <button class="btn btn-default btn-raised" ng-click="download()">Download Copy from Web</button> to see it.</p>
               <p>During download it will be converted to a text-only Web File, for the purpose of making it easier to read.
                  Converting to text is not exact, because web pages are not always composed in the order that they are 
                  displayed on the screen.  We will search through all the various parts of the web page, and try to identify
                  the most important ones, while discarding things that appear to be just part of the layout</p>
               <p>Sections that appear to be mostly links will be separated out and placed near the bottom.</p>
               <p>Some pages simply can not be converted, but studies have show we are able to handle about 99% of web pages,
                  so hopefully it will work for yours.</p>
            </div>
        </div>
        
    </div>

</div>
<!-- end ShowWebFile.jsp -->
