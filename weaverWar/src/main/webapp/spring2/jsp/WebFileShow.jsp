<%@ page language="java" contentType="text/html;charset=UTF-8" pageEncoding="UTF-8"
%><%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.capture.CapturePage"
%><%@page import="com.purplehillsbooks.streams.NullWriter"
%><%@page import="com.purplehillsbooks.weaver.capture.WebFile"
%><%
    ar.assertLoggedIn("You need to Login to Upload a file.");
    String attachmentId = ar.reqParam("aid");
    boolean capture = "y".equals(ar.defParam("capture", "n"));
    boolean showHidden = "y".equals(ar.defParam("showHidden", "n"));
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();

    AttachmentRecord att = ngw.findAttachmentByIDOrFail(attachmentId);
    WebFile wf = att.getWebFile();
    if (capture) {
        wf.refreshFromWeb();
    }
    JSONObject wfjson = wf.getJson();
    boolean available = false;
    if (wfjson.has("sections")) {
        JSONArray sections = wfjson.getJSONArray("sections");
        available = sections.length()>0;
    }
%>

<script>
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Compressed Web File");
    $scope.attId = "<% ar.writeJS(attachmentId); %>";
    $scope.webFile = <% wfjson.write(out,2,4); %>;
    $scope.isAvailable = <%= available %>;
    $scope.originalUrl = "<% ar.writeJS(att.getURLValue()); %>";
    $scope.attName = "<% ar.writeJS(att.getNiceName()); %>";
    $scope.showHidden = false;

    $scope.articleSections  =[];
    $scope.linkSections = [];
    $scope.hiddenSections = [];
    $scope.reportError = function(data) {
        console.log("DANGER DANGER DANGER", data);
    };
    function divideSections() {
        let artList = [];
        let linkList = [];
        let hidList = [];

        for (let sec of $scope.webFile.sections) {

            console.log("CHECKING", sec);
            if (sec.group == "article") {
                artList.push(sec);
            }
            if (sec.group == "links") {
                linkList.push(sec);
            }
            if (sec.group == "hidden") {
                hidList.push(sec);
            }
        }
        $scope.articleSections  = artList;
        $scope.linkSections = linkList;
        $scope.hiddenSections = hidList;
    }
    divideSections();

    $scope.openOriginal = function() {
        window.open($scope.originalUrl, "_blank");
    }
    $scope.download = function() {
        window.location="WebFileShow.htm?aid=<%=attachmentId%>&capture=y";
    }
    $scope.sharable = function() {
        window.location="WebFilePrint.htm?aid=<%=attachmentId%>";
    }
    $scope.edit = function(art) {
        window.location="WebFileEdit.htm?aid=<%=attachmentId%>&sec="+art.originPos;
    }

    $scope.setGroup = function(sec, mode) {
        sec.group = mode;
        let secCopy = {};
        secCopy.group = mode;
        secCopy.originPos = sec.originPos;

        let wfCopy = {};
        wfCopy.sections = [];
        wfCopy.sections.push(secCopy);
        var postURL = "UpdateWebFile.json?aid="+$scope.attId;
        var postdata = angular.toJson(wfCopy);
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.webFile = data;
            divideSections();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
});
</script>


<div class="container-fluid override mb-4 mx-3 d-inline-flex">
    <span class="dropdown mt-1">
        <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
            data-bs-toggle="dropdown" aria-expanded="false">
        </button>
        <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
            <li>
                <button class="dropdown-item" onclick="window.location.reload(true)">
                    Refresh</button>
                <span class="dropdown-item" type="button" aria-labelledby="createPDF">
                    <a class="nav-link" ng-click="openOriginal()">
                        Open Original Web Page</a></span>
                <span class="dropdown-item" type="button" aria-labelledby="createPDF">
                    <a class="nav-link" ng-click="sharable()">
                        Sharable View</a></span>
            </li>
        </ul>
    </span>
    <span>
        <h1 class="d-inline page-name" id="mainPageTitle">Compressed Web File</h1>
    </span>
</div>
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

<div class="container-fluid override mx-4">
    <span class="h6 ms-3">Show Hidden <input type="checkbox" ng-model="showHidden"/></span>
    <div><br/></div>
    <div><br/></div>
    <div class="d-flex col-9">
        <div class="contentColumn">
            <div class="container-fluid">
                <div class="generalContent">
                    <div class="h4 text-secondary">{{attName}}</div>
        <div class="row" ng-repeat="art in articleSections" >
            <span style="max-width: 600px"><div ng-bind-html="art.content|wiki" class="segmentBox"></div></span>
            <span  style="max-width: 100px">§{{art.originPos}}
                <br/><button ng-click="setGroup(art, 'hidden')">hide</button>
                <br/><button ng-click="setGroup(art, 'links')">put in links</button>
                <br/><button ng-click="edit(art)">edit</button>
            </span>
        </div>
        <div class="row"  ng-repeat="art in linkSections" >
            <span style="max-width: 600px"><div ng-bind-html="art.content|wiki" class="segmentBox"></div></span>
            <span  style="max-width: 100px">§{{art.originPos}}
                <br/><button ng-click="setGroup(art, 'hidden')">hide</button>
                <br/><button ng-click="setGroup(art, 'article')">put in articles</button>
            </span>
        </div>
        <div class="row"  ng-repeat="art in hiddenSections" ng-show="showHidden">
            <span style="max-width: 600px"><div ng-bind-html="art.content|wiki" class="hiddenBox"></div></span>
            <span  style="max-width: 100px">§{{art.originPos}}
                <br/><button ng-click="setGroup(art, 'article')">put in articles</button>
                <br/><button ng-click="setGroup(art, 'links')">put in links</button>
            </span>
        </div>
    </div>

    <div ng-hide="isAvailable">
        <div class="guideVocal">
            <p>There does not seem to be a downloaded copy yet.</p>
            <p>Use <button class="btn-comment btn-raised mx-2 my-md-3 my-sm-3" ng-click="download()">Download Copy from Web</button> to see it.</p>
            <p>During download it will be converted to a text-only Web File, for the purpose of making it easier to read.
                Converting to text is not exact, because web pages are not always composed in the order that they are
                displayed on the screen.  We will search through all the various parts of the web page, and try to identify
                the most important ones, while discarding things that appear to be just part of the layout</p>
            <p>Sections that appear to be mostly links will be separated out and placed near the bottom.</p>
            <p>Some pages simply can not be converted, but studies have show we are able to handle about 99% of web pages,
                so hopefully it will work for yours.</p>
        </div>
    </div>
    <div ng-show="isAvailable">
        <div class="guideVocal">
            <p>A copy has been downloaded as shown above.</p>
            <p>You can use <button class="btn btn-secondary btn-wide btn-raised" ng-click="download()">Download Copy from Web</button> to refresh
            it from the web.</p>
            <p><b>Be Careful:</b> any changes you have made hiding and moving sections will be lost.</p>
            <p>Do this only if you want to start over with a fresh, original copy.</p>
        </div>
    </div>
</div>

</div>
<!-- end WebFileShow.jsp -->
